import { expect, test, type Page, type TestInfo } from "@playwright/test";
import { mkdir } from "node:fs/promises";
import path from "node:path";

import { drainSearchQueue, injectFailedSync, seedScenario, waitForSearchVisible } from "./helpers/e2e";

const screenshotDir = process.env.ADMIN_SCREENSHOT_DIR || "test-results/admin-screenshots";

async function capture(page: Page, testInfo: TestInfo, name: string): Promise<void> {
  await mkdir(screenshotDir, { recursive: true });
  const filePath = path.join(screenshotDir, `${name}.png`);
  await page.screenshot({ path: filePath, fullPage: true });
  await testInfo.attach(name, { path: filePath, contentType: "image/png" });
}

test("captures canonical ScrypathOps admin UI states", async ({ page, request }, testInfo) => {
  const seed = await seedScenario(request, "e2e_search_catalog");
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

  await page.goto("/admin/search/posture");
  await page.getByRole("button", { name: "Refresh posture" }).click();
  await expect(page.getByRole("heading", { name: "Posture" })).toBeVisible();
  await capture(page, testInfo, "01-posture-health");

  await page.goto("/admin/search/failed-sync");
  await page.getByRole("button", { name: "Refresh failed sync jobs" }).click();
  await expect(page.getByRole("heading", { name: "Failed sync jobs" })).toBeVisible();
  const failedRow = page.getByTestId("failed-sync-row").first();
  await expect(failedRow).toBeVisible();
  await failedRow.locator("summary").click();
  await expect(failedRow.locator("details")).toHaveAttribute("open", "");
  await expect(failedRow.getByText("queue job failed")).toBeVisible();
  await failedRow.locator("details").evaluate((el) => el.setAttribute("open", ""));
  await page.waitForTimeout(200);
  await capture(page, testInfo, "02-failed-sync-expanded");

  await page.getByRole("button", { name: "Hide reason rollups" }).click();
  await capture(page, testInfo, "03-failed-sync-compact");

  await page.goto("/admin/search/sync-drift");
  await expect(page.getByRole("heading", { name: "Sync & Drift" })).toBeVisible();
  await page.waitForTimeout(500);
  await page.getByRole("button", { name: "Load / refresh contract drift" }).click();
  await expect(page.getByText("Contract dimensions")).toBeVisible();
  await capture(page, testInfo, "04-sync-drift-loaded");

  await page.goto("/admin/search/search");
  await expect(page.getByRole("heading", { name: "Search & federation" })).toBeVisible();
  await page.getByLabel("Search text").fill("quantum");
  await page.getByRole("button", { name: "Run bounded search" }).click();
  await expect(page.getByRole("heading", { name: "Results" })).toBeVisible();
  await capture(page, testInfo, "05-search-single-results");

  await page.getByRole("button", { name: "Multi index" }).click();
  const firstSchema = page.locator("input[name='schemas[]']").first();
  if (!(await firstSchema.isChecked())) {
    await firstSchema.check();
  }
  await page.getByRole("button", { name: "Run bounded search" }).click();
  await expect(page.getByText("Federation summary")).toBeVisible();
  await capture(page, testInfo, "06-search-multi-results");

  await page.goto("/admin/search/playbooks");
  await expect(page.getByRole("heading", { name: "Saved playbooks" })).toBeVisible();
  await page.getByText("Or paste JSON").click();
  await page.locator("textarea[name='json']").fill(
    JSON.stringify({
      playbook_format: 1,
      mode: "search",
      schema: "ScrypathEcommerce.Catalog.Product",
      q: "quantum",
      opts: { page: { size: 10 } }
    })
  );
  await page.getByRole("button", { name: "Import from paste" }).click();
  await expect(page.getByTestId("playbook-preview-marker")).toBeVisible();
  await capture(page, testInfo, "07-playbook-preview");

  await page.getByRole("button", { name: "Run saved playbook" }).click();
  await expect(page.getByText("Playbook run completed", { exact: true })).toBeVisible();
  await capture(page, testInfo, "08-playbook-run-result");
});
