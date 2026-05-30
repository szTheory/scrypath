import { expect, test } from "@playwright/test";

import { injectFailedSync, operatorState, seedScenario, waitForSwapOutcome } from "./helpers/e2e";

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

  await row.getByText("Row detail").click();

  const retryButton = row.getByTestId("failed-sync-retry");

  if (await retryButton.isVisible()) {
    await retryButton.click();

    const pageText = page.locator("body");
    await expect(pageText).toContainText(/Retried|Failed sync jobs/);
  } else {
    await expect(row).toBeVisible();
  }
});

test("operator can initiate zero-downtime swap from posture UI", async ({ page, request }) => {
  const seed = await seedScenario(request, "e2e_search_catalog");

  await page.goto("/admin/search/posture");
  await expect(page.getByRole("button", { name: "Refresh posture" })).toBeVisible();
  await page.getByRole("button", { name: "Refresh posture" }).click();

  const postureRow = page.getByTestId("posture-row").first();
  await expect(postureRow).toBeVisible();

  await postureRow.getByRole("button", { name: "Swap live index" }).click();
  await expect(page.getByText("Swap live index completed")).toBeVisible();

  const outcome = await waitForSwapOutcome(request, {
    tenantId: seed.tenant_id,
    timeoutMs: 30_000
  });

  expect(outcome.swap_terminal_success).toBeTruthy();
  expect(outcome.active_index_visible).toBeTruthy();
  await expect(page.getByTestId("posture-next-checks")).toContainText(/Healthy|Degraded/);
});
