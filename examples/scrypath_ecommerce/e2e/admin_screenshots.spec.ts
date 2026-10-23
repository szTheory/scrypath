import { expect, test, type Page, type TestInfo } from "@playwright/test";
import { mkdir } from "node:fs/promises";
import path from "node:path";

import {
  deleteSavedSearches,
  drainSearchQueue,
  injectFailedSync,
  openManageSavedSearches,
  putSavedSearch,
  seedScenario,
  waitForLiveConnected,
  waitForSearchVisible
} from "./helpers/e2e";

const screenshotDir = process.env.ADMIN_SCREENSHOT_DIR || "test-results/admin-screenshots";

async function capture(page: Page, testInfo: TestInfo, name: string): Promise<void> {
  await mkdir(screenshotDir, { recursive: true });
  const filePath = path.join(screenshotDir, `${name}.png`);
  await page.evaluate(() => window.scrollTo(0, 0));
  await page.screenshot({ path: filePath, fullPage: true });
  await testInfo.attach(name, { path: filePath, contentType: "image/png" });
}

test("captures canonical ScrypathOps admin UI states", async ({ page, request }, testInfo) => {
  const seed = await seedScenario(request, "all_green");
  await drainSearchQueue(request);
  await waitForSearchVisible(request, {
    tenantId: seed.tenant_id,
    query: "quantum",
    expectedName: "Quantum CyberPhone X"
  });

  await injectFailedSync(request, {
    tenantId: seed.tenant_id,
    scenarioKey: `admin-screenshot-${Date.now()}`
  });

  await page.goto("/admin/search");
  await expect(page.getByRole("heading", { name: "Control Room" })).toBeVisible();
  await capture(page, testInfo, "00-control-room");

  await page.goto("/admin/search/health");
  await waitForLiveConnected(page);
  await page.locator("[data-ops-refresh]").click();
  await expect(page.getByRole("heading", { name: "Search health", exact: true })).toBeVisible();
  await capture(page, testInfo, "01-search-health");

  await page.goto("/admin/search/failed-sync");
  await waitForLiveConnected(page);
  await page.getByRole("button", { name: "Refresh failed sync work" }).click();
  await expect(page.getByRole("heading", { name: "Failed sync work", exact: true })).toBeVisible();
  const failedRow = page.getByTestId("failed-sync-row").first();
  await expect(failedRow).toBeVisible();
  await expect(failedRow.getByText(/unknown_module.*NotARealBackend/)).toBeVisible();
  await failedRow.getByText("More details", { exact: true }).click();
  await expect(failedRow.locator("details")).toHaveAttribute("open", "");
  await expect(failedRow.locator("details dl")).toBeVisible();
  await capture(page, testInfo, "02-failed-sync-expanded");

  await page.goto("/admin/search/sync-and-index");
  await waitForLiveConnected(page);
  await expect(page.getByRole("heading", { name: "Sync and index" })).toBeVisible();
  await page.getByRole("button", { name: "Refresh sync and index settings" }).click();
  await expect(page.getByText(/Meilisearch settings (match|differ)/|/Meilisearch settings (match|differ)/).first()).toBeVisible();
  await capture(page, testInfo, "03-sync-drift-loaded");

  await page.goto("/admin/search/search");
  await waitForLiveConnected(page);
  await expect(page.getByRole("heading", { name: "Search", exact: true })).toBeVisible();
  await page.getByLabel("Search text").fill("quantum");
  await page.getByRole("button", { name: "Run search" }).click();
  await expect(page.getByRole("heading", { name: "Results", exact: true })).toBeVisible();
  await capture(page, testInfo, "04-search-single-results");

  await page.getByRole("button", { name: "Multiple schemas" }).click();
  const firstSchema = page.locator("input[name='schemas[]']").first();
  if (!(await firstSchema.isChecked())) {
    await firstSchema.check();
  }
  await page.getByRole("button", { name: "Run search" }).click();
  await expect(page.locator("details.ops-combined-order")).toBeVisible();
  await capture(page, testInfo, "05-search-multi-results");

  const savedName = `screenshot-quantum-${Date.now()}`;
  await putSavedSearch(request, savedName, {
    playbook_format: 1,
    mode: "search",
    schema: "ScrypathEcommerce.Catalog.Product",
    q: "quantum",
    opts: { page: { size: 10 } }
  });
  try {
    const sheet = await openManageSavedSearches(page);
    await expect(sheet.getByText(savedName, { exact: true })).toBeVisible();
    await capture(page, testInfo, "06-saved-search-manage");

    await sheet.getByRole("button", { name: `Load ${savedName}` }).click();
    await expect(page.locator("#saved-search-status")).toContainText(`Loaded “${savedName}”`);
    await expect(page.locator("#search-results-heading")).toBeVisible();
    await capture(page, testInfo, "07-saved-search-run-result");
  } finally {
    await deleteSavedSearches(request, { names: [savedName] });
  }
});
