// Focused screenshots of the Phase-1 operator-UI work (Control Room + design-token /
// IA polish), captured against an already-seeded DEV server (mix scrypath.demo.seed) so
// the operator signals are real. No reseeding here — we want the demo's expressive state.
//
//   PLAYWRIGHT_BASE_URL=http://127.0.0.1:4011 \
//   ADMIN_SCREENSHOT_DIR=/tmp/admin-screenshots/iter1 \
//   npx playwright test e2e/phase1_screens.spec.ts --project=chromium
import { test, type Page, type TestInfo } from "@playwright/test";
import { mkdir } from "node:fs/promises";
import path from "node:path";

const screenshotDir = process.env.ADMIN_SCREENSHOT_DIR || "test-results/admin-screenshots";

async function capture(page: Page, testInfo: TestInfo, name: string): Promise<void> {
  await mkdir(screenshotDir, { recursive: true });
  const filePath = path.join(screenshotDir, `${name}.png`);
  await page.screenshot({ path: filePath, fullPage: true });
  await testInfo.attach(name, { path: filePath, contentType: "image/png" });
}

test("control room", async ({ page }, testInfo) => {
  await page.goto("/admin/search");
  await page.getByRole("heading", { name: "Control Room" }).waitFor();
  await page.waitForTimeout(300);
  await capture(page, testInfo, "01-control-room");
});

test("posture", async ({ page }, testInfo) => {
  await page.goto("/admin/search/posture");
  await page.getByRole("heading", { name: "Posture", exact: true }).waitFor();
  await page.waitForTimeout(300);
  await capture(page, testInfo, "02-posture");
});

test("failed sync (collapsed + expanded evidence)", async ({ page }, testInfo) => {
  await page.goto("/admin/search/failed-sync");
  await page.getByRole("heading", { name: "Failed sync work" }).waitFor();
  await page.waitForTimeout(300);
  await capture(page, testInfo, "03-failed-sync");
  // Expand the first evidence disclosure to show the new chevron affordance + rhythm.
  const firstSummary = page.locator("summary", { hasText: "View evidence" }).first();
  if (await firstSummary.count()) {
    await firstSummary.click();
    await page.waitForTimeout(300);
    await capture(page, testInfo, "04-failed-sync-evidence");
  }
});

test("sync drift (loaded)", async ({ page }, testInfo) => {
  await page.goto("/admin/search/sync-drift");
  await page.getByRole("heading", { name: "Sync and drift", exact: true }).waitFor();
  await page.waitForTimeout(300);
  const loadBtn = page.getByRole("button", { name: /contract drift/i }).first();
  if (await loadBtn.count()) {
    await loadBtn.click();
    await page.waitForTimeout(800);
  }
  await capture(page, testInfo, "05-sync-drift");
});

test("search", async ({ page }, testInfo) => {
  await page.goto("/admin/search/search");
  await page.getByRole("heading", { name: "Search & federation" }).waitFor();
  await page.waitForTimeout(300);
  await capture(page, testInfo, "06-search");
});

test("playbooks", async ({ page }, testInfo) => {
  await page.goto("/admin/search/playbooks");
  await page.getByRole("heading", { name: "Saved playbooks" }).waitFor();
  await page.waitForTimeout(300);
  await capture(page, testInfo, "07-playbooks");
});
