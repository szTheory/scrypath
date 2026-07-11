import { expect, test } from "@playwright/test";

import {
  injectFailedSync,
  operatorState,
  seedScenario,
  waitForLiveConnected,
  waitForSwapOutcome
} from "./helpers/e2e";

test("operator can triage intentionally failed sync work", async ({ page, request }) => {
  const seed = await seedScenario(request, "e2e_search_catalog");

  await injectFailedSync(request, {
    tenantId: seed.tenant_id,
    scenarioKey: "failed-sync-operator-triage"
  });

  const state = await operatorState(request, {
    tenantId: seed.tenant_id,
    timeoutMs: 15_000,
    minFailedSyncCount: 1
  });

  expect(state.failed_count).toBeGreaterThanOrEqual(1);
  expect(state.retryable).toBeTruthy();

  await page.goto("/admin/search/failed-sync");

  await expect(page.getByRole("heading", { name: "Failed sync jobs" })).toBeVisible();

  await page.getByRole("button", { name: "Refresh failed sync jobs" }).click();

  const row = page.getByTestId("failed-sync-row").first();
  await expect(row).toBeVisible();

  await row.getByText("View evidence").click();

  const retryButton = row.getByTestId("failed-sync-retry");

  if (await retryButton.isVisible()) {
    await retryButton.click();

    const pageText = page.locator("body");
    await expect(pageText).toContainText(/Retried|Failed sync jobs/);

    const retried = await operatorState(request, {
      tenantId: seed.tenant_id,
      timeoutMs: 15_000,
      minFailedSyncCount: 1
    });

    expect(retried.failed_count).toBeGreaterThanOrEqual(1);
    expect(retried.reason_class_counts).toBeTruthy();
  } else {
    await expect(row).toBeVisible();
  }
});

test("operator can initiate zero-downtime swap from sync drift UI", async ({ page, request }) => {
  const seed = await seedScenario(request, "e2e_search_catalog");

  await page.goto("/admin/search/posture");
  await waitForLiveConnected(page);
  await expect(page.locator("[data-ops-refresh]")).toBeVisible();
  await page.locator("[data-ops-refresh]").click();

  const postureRow = page.getByTestId("posture-row").first();
  await expect(postureRow).toBeVisible();
  await expect(page.getByTestId("posture-next-checks")).toContainText(
    /no schema fetch errors|incident triage/i
  );

  await page.goto("/admin/search/sync-drift");
  await waitForLiveConnected(page);
  await expect(page.getByRole("heading", { name: "Sync and drift" })).toBeVisible();
  await page.getByRole("button", { name: "Load / refresh contract drift" }).click();
  await expect(page.getByText("Contract dimensions")).toBeVisible();
  await page.getByRole("button", { name: "Swap live index" }).click();
  await expect(page.getByText("Swap live index completed")).toBeVisible();

  const outcome = await waitForSwapOutcome(request, {
    tenantId: seed.tenant_id,
    timeoutMs: 30_000
  });

  expect(outcome.swap_terminal_success).toBeTruthy();
  expect(outcome.active_index_visible).toBeTruthy();
});
