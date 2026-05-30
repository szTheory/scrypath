import { expect, type APIRequestContext } from "@playwright/test";

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
  pending: number;
  failed: number;
  queue_failed: number;
  failed_sync_count: number;
};

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
  return await requestJson<SeedResult>(request, "/dev/e2e/seed", {
    method: "POST",
    data: { scenario }
  });
}

export async function drainSearchQueue(request: APIRequestContext): Promise<DrainResult> {
  return await requestJson<DrainResult>(request, "/dev/e2e/drain", {
    method: "POST",
    data: {}
  });
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

  return await requestJson<{ hits: string[] }>(request, "/dev/e2e/search-visible", {
    params: {
      tenant_id: String(args.tenantId),
      query: args.query,
      ...(args.categoryId ? { category_id: String(args.categoryId) } : {})
    }
  });
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

  return (await response.json()) as { category_id: number; name: string; queued_related_sync: boolean };
}

export async function injectFailedSync(
  request: APIRequestContext,
  args: { tenantId: number }
): Promise<{ job_id: number; queue: string }> {
  return await requestJson<{ job_id: number; queue: string }>(request, "/dev/e2e/inject-failed-sync", {
    method: "POST",
    data: {
      tenant_id: args.tenantId
    }
  });
}

export async function operatorState(
  request: APIRequestContext,
  args: { tenantId: number; timeoutMs?: number; minFailedSyncCount?: number }
): Promise<OperatorState> {
  if (args.minFailedSyncCount) {
    await expect
      .poll(
        async () => {
          const result = await requestJson<OperatorState>(request, "/dev/e2e/operator-state", {
            params: { tenant_id: String(args.tenantId) }
          });

          return result.failed_sync_count;
        },
        {
          timeout: args.timeoutMs ?? 15_000,
          message: `Timed out waiting for /dev/e2e/operator-state failed_sync_count >= ${args.minFailedSyncCount}`
        }
      )
      .toBeGreaterThanOrEqual(args.minFailedSyncCount);
  }

  return await requestJson<OperatorState>(request, "/dev/e2e/operator-state", {
    params: { tenant_id: String(args.tenantId) }
  });
}
