import { expect, type APIRequestContext } from "@playwright/test";
import { appendFile, mkdir } from "node:fs/promises";
import { dirname } from "node:path";

type SeedResult = {
  tenant_id: number;
  categories: Record<string, number>;
  products: Record<string, number>;
};

type DrainResult = {
  success: number;
  failure: number;
};

type OperatorState = {
  failed_count: number;
  first_failed_work_id: number | null;
  reason_class_counts: Record<string, number>;
  retryable: boolean;
  swap_terminal_success: boolean;
  swap_terminal_state: "completed" | "pending" | "not_started" | "unknown";
  active_index: string;
  active_index_visible: boolean;
  swap_error_class: string | null;
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
  scenario = "e2e_search_catalog"
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
    retryable: result.retryable,
    swap_terminal_success: result.swap_terminal_success,
    swap_terminal_state: result.swap_terminal_state,
    active_index_visible: result.active_index_visible,
    swap_error_class: result.swap_error_class
  });

  return result;
}

export async function waitForSwapOutcome(
  request: APIRequestContext,
  args: { tenantId: number; timeoutMs?: number }
): Promise<OperatorState> {
  const timeoutMs = args.timeoutMs ?? 20_000;

  await expect
    .poll(
      async () => {
        return await requestJson<OperatorState>(request, "/dev/e2e/operator-state", {
          params: { tenant_id: String(args.tenantId) }
        });
      },
      {
        timeout: timeoutMs,
        message: "Timed out waiting for operator swap outcome to become terminal and visible"
      }
    )
    .toMatchObject({
      swap_terminal_success: true,
      active_index_visible: true
    });

  const result = await requestJson<OperatorState>(request, "/dev/e2e/operator-state", {
    params: { tenant_id: String(args.tenantId) }
  });

  await emitEvidence("swap_outcome", {
    tenant_id: args.tenantId,
    failed_count: result.failed_count,
    retryable: result.retryable,
    swap_terminal_success: result.swap_terminal_success,
    swap_terminal_state: result.swap_terminal_state,
    active_index: result.active_index,
    active_index_visible: result.active_index_visible,
    swap_error_class: result.swap_error_class
  });

  return result;
}
