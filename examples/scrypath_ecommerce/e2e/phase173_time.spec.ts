import { expect, test } from "@playwright/test";
import { waitForLiveConnected } from "./helpers/e2e";

const sourceIso = "2026-10-04T13:02:05.123456-04:00";
const standalone = process.env.PHASE173_STANDALONE_BASE_URL || "http://standalone_ops:4003";
const entries = [
  { name: "mounted", url: "/admin/search/phase173/health" },
  { name: "standalone", url: `${standalone}/ops/phase173/health` }
];
async function visit(page, entry, scenario = "healthy") {
  const url = new URL(entry.url, process.env.PLAYWRIGHT_BASE_URL || "http://web:4002");
  url.searchParams.set("scenario", scenario);
  await page.goto(url.toString());
  await waitForLiveConnected(page);
}
for (const entry of entries) {
  test(`${entry.name} displays the selected zone while preserving exact source provenance`, async ({ page }) => {
    await visit(page, entry);
    const time = page.locator(`[data-ops-timestamp-copy='${sourceIso}']`);
    await expect(time.locator("time")).toHaveAttribute("datetime", sourceIso);
    await expect(time).toContainText("UTC");
    const text = await time.innerText();
    await page.locator("#search-health-refresh").click();
    await expect(time).toHaveText(text);
    await expect(time).toHaveAttribute("data-ops-timestamp-copy", sourceIso);
    await expect(page.locator("details.ops-time__details")).toHaveCount(0);
  });

  test(`${entry.name} timestamps and exact copy controls reflow across mobile and rail boundaries`, async ({ page }) => {
    await visit(page, entry);
    for (const theme of ["light", "dark"]) {
      await page.getByRole("button", { name: `Use ${theme} theme`, exact: true }).click();
      for (const width of [320, 390, 1279, 1280, 1440]) {
        await page.setViewportSize({ width, height: 900 });
        const stamp = page.locator(`[data-ops-timestamp-copy='${sourceIso}']`);
        await expect(stamp).toBeVisible();
        const bounds = await stamp.boundingBox();
        expect(bounds?.height).toBeGreaterThanOrEqual(24);
        expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBeLessThanOrEqual(width);
        await expect(page.getByRole("combobox", { name: "Time zone" })).toBeVisible();
      }
    }
  });

  test(`${entry.name} local conversion uses browser timezone and DST and survives reload`, async ({ browser }) => {
    const context = await browser.newContext({ timezoneId: "America/New_York", baseURL: process.env.PLAYWRIGHT_BASE_URL || "http://web:4002" });
    const page = await context.newPage();
    await visit(page, entry);
    await page.getByRole("combobox", { name: "Time zone" }).selectOption("local");
    const stamp = page.locator(`[data-ops-timestamp-copy='${sourceIso}']`);
    await expect(stamp).toContainText("EDT");
    await expect(stamp).toContainText(/1:02:05|13:02:05/);
    await page.reload();
    await waitForLiveConnected(page);
    await expect(page.getByRole("combobox", { name: "Time zone" })).toHaveValue("local");
    await expect(stamp).toContainText("EDT");
    // Browser Intl handles historical seasonal offsets, not a fixed UTC offset.
    await stamp.locator("time").evaluate(node => node.setAttribute("datetime", "2026-01-04T17:02:05Z"));
    await page.getByRole("combobox", { name: "Time zone" }).selectOption("utc");
    await page.getByRole("combobox", { name: "Time zone" }).selectOption("local");
    await expect(stamp).toContainText("EST");
    await expect(stamp).toContainText(/12:02:05/);
    await context.close();
  });

  test(`${entry.name} absent invalid unavailable and unused observations never become timestamps`, async ({ page }) => {
    await visit(page, entry, "failed");
    await expect(page.getByTestId("posture-row").first()).toContainText("No completed task in available history");
    await visit(page, entry, "invalid-time");
    await expect(page.getByText("Completion time unavailable", { exact: true })).toHaveCount(2);
    await expect(page.getByTestId("posture-row").locator("[data-ops-timestamp-copy]")).toHaveCount(0);
    await visit(page, entry, "queue-unused");
    await expect(page.getByRole("region", { name: /Queue job signals/ })).toContainText("Queue not used");
    for (const scenario of ["unknown", "unavailable"]) {
      await visit(page, entry, scenario);
      await expect(page.getByTestId("posture-row").first()).toContainText("No successful observation recorded.");
      await expect(page.getByTestId("posture-row").locator("[data-ops-timestamp-copy]")).toHaveCount(0);
    }
    await visit(page, entry, "refresh-failure");
    await page.locator("#search-health-refresh").click();
    const retained = page.getByTestId("posture-row").first();
    await expect(retained).toContainText("source-local evidence is retained");
    await expect(retained.locator(`[data-ops-timestamp-copy='${sourceIso}']`)).toHaveCount(1);
  });
}
