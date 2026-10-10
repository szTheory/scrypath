import { expect, type APIRequestContext, type Page } from "@playwright/test";
import { appendFile, mkdir } from "node:fs/promises";
import { dirname } from "node:path";

/**
 * Wait until the page's LiveView socket is connected before driving interactive
 * (phx-change / phx-click) controls. On a fresh navigation the first interaction can
 * otherwise fire before the socket reconnects — the event is dropped and the search /
 * drift load never runs. The host app exposes `window.liveSocket` (assets/js/app.js).
 */
export async function waitForLiveConnected(page: Page): Promise<void> {
  await page.waitForFunction(
    () => {
      const ls = (window as unknown as { liveSocket?: { isConnected?: () => boolean } }).liveSocket;
      return Boolean(ls && typeof ls.isConnected === "function" && ls.isConnected());
    },
    undefined,
    { timeout: 15_000 }
  );

  await expect(page.locator("[data-phx-main]")).toHaveClass(/\bphx-connected\b/, {
    timeout: 15_000
  });
}

type SeedResult = {
  tenant_id: number | null;
  categories: Record<string, number>;
  products: Record<string, number>;
  scenario?: string;
  failed_count?: number;
  drift?: boolean;
};

/**
 * Named operational scenarios understood by /dev/e2e/seed (SEED-01). Each drives the
 * operator UI into a deterministic health state for the screenshot/audit harness:
 *   all_green — catalog synced, no failed sync, no drift (verdict trusts search)
 *   degraded  — catalog synced, drift only (verdict degraded)
 *   incident  — catalog synced, all failed-sync reason classes + drift (can't-fully-trust)
 *   empty     — no synced products / signals (every empty state)
 * `e2e_search_catalog` remains the original deterministic search/tenant-guard lane.
 */
export type SeedScenario =
  | "all_green"
  | "degraded"
  | "incident"
  | "empty"
  | "e2e_search_catalog";

type DrainResult = {
  success: number;
  failure: number;
};

type OperatorState = {
  failed_count: number;
  first_failed_work_id: number | null;
  reason_class_counts: Record<string, number>;
  retryable: boolean;
};

export type RecoveryFixture = {
  marker: string;
  schema: string;
  index: string;
  original_job_id: number;
  original_attempt: number;
  document_id: number;
  expected_sku: string;
  task_baseline: number;
};

export type RecoveryEvidence = {
  marker: string;
  schema: string;
  index: string;
  original_job_id: number;
  original_attempt: number;
  accepted_job_id: number;
  accepted_attempt: number;
  task_uid: number;
  task_status: string;
  task_type: string;
  task_index: string;
  document_id: number;
  expected_sku: string;
  active_document: boolean;
};

export type DeleteRecoveryFixture = {
  marker: string;
  schema: string;
  index: string;
  original_job_id: number;
  original_attempt: number;
  document_id: number;
  expected_name: string;
};

export type DeleteRecoveryEvidence = {
  marker: string;
  accepted_job_id: number;
  accepted_attempt: number;
  task_uid: number;
  task_status: string;
  task_type: string;
  task_index: string;
  document_id: number;
  active_document_absent: boolean;
};

export type SwapFixture = {
  marker: string;
  schema: string;
  live_index: string;
  target_index: string;
  document_id: number;
  expected_name: string;
  task_baseline: number;
};

export type SwapEvidence = {
  marker: string;
  task_uid: number;
  task_status: string;
  task_type: string;
  live_index: string;
  target_index: string;
  swapped_pair: string[];
  document_id: number;
  expected_name: string;
  active_document: boolean;
};

type EvidencePayload = Record<string, unknown>;

async function emitEvidence(operation: string, payload: EvidencePayload): Promise<void> {
  const evidencePath = process.env.PHASE105_EVIDENCE_PATH;
  if (!evidencePath) return;

  const entry = {
    ts_utc: new Date().toISOString(),
    operation,
    ...payload
  };

  await mkdir(dirname(evidencePath), { recursive: true });
  await appendFile(evidencePath, `${JSON.stringify(entry)}\n`);
}

async function requestJson<T>(
  request: APIRequestContext,
  path: string,
  options?: { method?: "GET" | "POST"; data?: unknown; params?: Record<string, string> }
): Promise<T> {
  const response = await request.fetch(path, {
    method: options?.method ?? "GET",
    data: options?.data,
    params: options?.params
  });

  if (!response.ok()) {
    const body = await response.text();
    throw new Error(`[e2e] request failed for ${path}: HTTP ${response.status()} body=${body}`);
  }

  return (await response.json()) as T;
}

export async function seedScenario(
  request: APIRequestContext,
  scenario: SeedScenario = "e2e_search_catalog"
): Promise<SeedResult> {
  const result = await requestJson<SeedResult>(request, "/dev/e2e/seed", {
    method: "POST",
    data: { scenario }
  });

  await emitEvidence("seed", {
    scenario,
    tenant_id: result.tenant_id,
    category_keys: Object.keys(result.categories),
    product_keys: Object.keys(result.products)
  });

  return result;
}

export async function drainSearchQueue(request: APIRequestContext): Promise<DrainResult> {
  const result = await requestJson<DrainResult>(request, "/dev/e2e/drain", {
    method: "POST",
    data: {}
  });

  await emitEvidence("drain", {
    success: result.success,
    failure: result.failure
  });

  return result;
}

export async function waitForSearchVisible(
  request: APIRequestContext,
  args: {
    tenantId: number;
    query: string;
    expectedName: string;
    categoryId?: number;
    timeoutMs?: number;
  }
): Promise<{ hits: string[] }> {
  const timeoutMs = args.timeoutMs ?? 15_000;

  await expect
    .poll(
      async () => {
        const result = await requestJson<{ hits: string[] }>(request, "/dev/e2e/search-visible", {
          params: {
            tenant_id: String(args.tenantId),
            query: args.query,
            ...(args.categoryId ? { category_id: String(args.categoryId) } : {})
          }
        });

        return result.hits;
      },
      {
        timeout: timeoutMs,
        message: `Timed out waiting for /dev/e2e/search-visible query=${args.query} to include ${args.expectedName}`
      }
    )
    .toContain(args.expectedName);

  const result = await requestJson<{ hits: string[] }>(request, "/dev/e2e/search-visible", {
    params: {
      tenant_id: String(args.tenantId),
      query: args.query,
      ...(args.categoryId ? { category_id: String(args.categoryId) } : {})
    }
  });

  await emitEvidence("search_visible", {
    tenant_id: args.tenantId,
    query: args.query,
    category_id: args.categoryId ?? null,
    expected_name: args.expectedName,
    hit_count: result.hits.length,
    first_hits: result.hits.slice(0, 5)
  });

  return result;
}

export async function renameCategory(
  request: APIRequestContext,
  args: { tenantId: number; categoryId: number; name: string }
): Promise<{ category_id: number; name: string; queued_related_sync: boolean }> {
  const response = await request.fetch("/dev/e2e/category-name", {
    method: "POST",
    data: {
      tenant_id: args.tenantId,
      category_id: args.categoryId,
      name: args.name
    }
  });

  if (!response.ok()) {
    const body = await response.text();
    throw new Error(
      `[e2e] category rename failed tenant_id=${args.tenantId} category_id=${args.categoryId} name=${args.name}: HTTP ${response.status()} body=${body}`
    );
  }

  const result = (await response.json()) as {
    category_id: number;
    name: string;
    queued_related_sync: boolean;
  };

  await emitEvidence("rename_category", {
    tenant_id: args.tenantId,
    category_id: args.categoryId,
    name: args.name,
    queued_related_sync: result.queued_related_sync
  });

  return result;
}

export async function deleteProduct(
  request: APIRequestContext,
  args: { tenantId: number; productId: number }
): Promise<{ product_id: number; deleted: boolean; queued_delete_sync: boolean }> {
  const result = await requestJson<{ product_id: number; deleted: boolean; queued_delete_sync: boolean }>(
    request,
    "/dev/e2e/product-delete",
    {
      method: "POST",
      data: {
        tenant_id: args.tenantId,
        product_id: args.productId
      }
    }
  );

  await emitEvidence("delete_product", {
    tenant_id: args.tenantId,
    product_id: args.productId,
    deleted: result.deleted,
    queued_delete_sync: result.queued_delete_sync
  });

  return result;
}

export async function waitForSearchHidden(
  request: APIRequestContext,
  args: {
    tenantId: number;
    query: string;
    hiddenName: string;
    timeoutMs?: number;
  }
): Promise<{ hits: string[] }> {
  const timeoutMs = args.timeoutMs ?? 15_000;

  await expect
    .poll(
      async () => {
        const result = await requestJson<{ hits: string[] }>(request, "/dev/e2e/search-visible", {
          params: {
            tenant_id: String(args.tenantId),
            query: args.query
          }
        });

        return result.hits;
      },
      {
        timeout: timeoutMs,
        message: `Timed out waiting for /dev/e2e/search-visible query=${args.query} to remove ${args.hiddenName}`
      }
    )
    .not.toContain(args.hiddenName);

  const result = await requestJson<{ hits: string[] }>(request, "/dev/e2e/search-visible", {
    params: {
      tenant_id: String(args.tenantId),
      query: args.query
    }
  });

  await emitEvidence("search_hidden", {
    tenant_id: args.tenantId,
    query: args.query,
    hidden_name: args.hiddenName,
    hit_count: result.hits.length,
    first_hits: result.hits.slice(0, 5)
  });

  return result;
}

export async function injectFailedSync(
  request: APIRequestContext,
  args: { tenantId: number; scenarioKey?: string }
): Promise<{ failed_work_id: number; schema: string; state: string; reason_class: string }> {
  const result = await requestJson<{ failed_work_id: number; schema: string; state: string; reason_class: string }>(
    request,
    "/dev/e2e/inject-failed-sync",
    {
      method: "POST",
      data: {
        tenant_id: args.tenantId,
        ...(args.scenarioKey ? { scenario_key: args.scenarioKey } : {})
      }
    }
  );

  await emitEvidence("inject_failed_sync", {
    tenant_id: args.tenantId,
    scenario_key: args.scenarioKey ?? null,
    failed_work_id: result.failed_work_id,
    schema: result.schema,
    state: result.state,
    reason_class: result.reason_class
  });

  return result;
}

export async function operatorState(
  request: APIRequestContext,
  args: { tenantId: number; timeoutMs?: number; minFailedSyncCount?: number }
): Promise<OperatorState> {
  if (args.minFailedSyncCount !== undefined) {
    await expect
      .poll(
        async () => {
          const result = await requestJson<OperatorState>(request, "/dev/e2e/operator-state", {
            params: { tenant_id: String(args.tenantId) }
          });

          return result.failed_count;
        },
        {
          timeout: args.timeoutMs ?? 15_000,
          message: `Timed out waiting for /dev/e2e/operator-state failed_count >= ${args.minFailedSyncCount}`
        }
      )
      .toBeGreaterThanOrEqual(args.minFailedSyncCount);
  }

  const result = await requestJson<OperatorState>(request, "/dev/e2e/operator-state", {
    params: { tenant_id: String(args.tenantId) }
  });

  await emitEvidence("operator_state", {
    tenant_id: args.tenantId,
    min_failed_sync_count: args.minFailedSyncCount ?? null,
    failed_count: result.failed_count,
    first_failed_work_id: result.first_failed_work_id,
    retryable: result.retryable
  });

  return result;
}

export async function prepareRecoveryFixture(
  request: APIRequestContext,
  args: { tenantId: number; marker: string }
): Promise<RecoveryFixture> {
  return requestJson<RecoveryFixture>(request, "/dev/e2e/recovery-fixture", {
    method: "POST",
    data: { tenant_id: args.tenantId, marker: args.marker }
  });
}

export async function prepareDeleteRecoveryFixture(
  request: APIRequestContext,
  args: { tenantId: number; marker: string }
): Promise<DeleteRecoveryFixture> {
  return requestJson<DeleteRecoveryFixture>(request, "/dev/e2e/delete-recovery-fixture", {
    method: "POST",
    data: { tenant_id: args.tenantId, marker: args.marker }
  });
}

export async function probeDeleteRecoveryEvidence(
  request: APIRequestContext,
  args: { marker: string; originalJobId: number; acceptedJobId: number; handle: string; generation: number; taskUid: number; index: string; documentId: number }
): Promise<DeleteRecoveryEvidence> {
  return requestJson<DeleteRecoveryEvidence>(request, "/dev/e2e/delete-recovery-probe", {
    params: {
      marker: args.marker,
      original_job_id: String(args.originalJobId),
      accepted_job_id: String(args.acceptedJobId),
      handle: args.handle,
      generation: String(args.generation),
      task_uid: String(args.taskUid),
      index: args.index,
      document_id: String(args.documentId)
    }
  });
}

export async function waitForRecoveryEvidence(
  request: APIRequestContext,
  args: {
    marker: string;
    acceptedJobId: number;
    handle: string;
    generation: number;
    taskUid: number;
    documentId: number;
    timeoutMs?: number;
  }
): Promise<RecoveryEvidence> {
  let evidence: RecoveryEvidence | undefined;
  await expect.poll(async () => {
    const response = await request.fetch("/dev/e2e/recovery-probe", {
      params: {
        marker: args.marker,
        accepted_job_id: String(args.acceptedJobId),
        handle: args.handle,
        generation: String(args.generation),
        task_uid: String(args.taskUid),
        document_id: String(args.documentId)
      }
    });
    if (!response.ok()) return false;
    evidence = (await response.json()) as RecoveryEvidence;
    return evidence.active_document && evidence.task_status === "succeeded";
  }, { timeout: args.timeoutMs ?? 30_000, message: "Timed out waiting for exact recovery task and active document evidence" }).toBeTruthy();
  if (!evidence) throw new Error("[e2e] recovery probe returned no evidence");
  return evidence;
}

export async function prepareSwapFixture(
  request: APIRequestContext,
  args: { tenantId: number; marker: string }
): Promise<SwapFixture> {
  return requestJson<SwapFixture>(request, "/dev/e2e/swap-fixture", {
    method: "POST",
    data: { tenant_id: args.tenantId, marker: args.marker }
  });
}

export async function probeSwapEvidence(
  request: APIRequestContext,
  args: { marker: string; taskUid: number; liveIndex: string; targetIndex: string; taskBaseline: number; documentId: number }
): Promise<SwapEvidence> {
  return requestJson<SwapEvidence>(request, "/dev/e2e/swap-probe", {
    params: {
      marker: args.marker,
      task_uid: String(args.taskUid),
      live_index: args.liveIndex,
      target_index: args.targetIndex,
      task_baseline: String(args.taskBaseline),
      document_id: String(args.documentId)
    }
  });
}
