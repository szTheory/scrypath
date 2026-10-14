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
async function installClipboard(page) {
  await page.evaluate(() => {
    (window as any).copyState = { calls: [], pending: [] };
    Object.defineProperty(navigator, "clipboard", { configurable: true, value: {
      writeText(text) {
        (window as any).copyState.calls.push({ text, active: navigator.userActivation.isActive });
        return new Promise((resolve, reject) => (window as any).copyState.pending.push({ resolve, reject }));
      }
    } });
  });
}
async function settle(page, index, success = true) {
  await page.evaluate(({ index, success }) => {
    const pending = (window as any).copyState.pending[index];
    success ? pending.resolve() : pending.reject(new Error("Denied"));
  }, { index, success });
}
const stamp = page => page.locator(`[data-ops-timestamp-copy='${sourceIso}']`);
const container = page => stamp(page).locator("..");
const message = page => container(page).locator("[data-ops-timestamp-message]");
const calls = page => page.evaluate(() => (window as any).copyState.calls);

for (const entry of entries) {
  test(`${entry.name} acknowledges copying only after a user-activated exact-value write resolves`, async ({ page }) => {
    await visit(page, entry); await installClipboard(page);
    await stamp(page).click();
    await expect.poll(() => calls(page)).toEqual([{ text: sourceIso, active: true }]);
    await expect(message(page)).toBeEmpty();
    await settle(page, 0);
    await expect(message(page)).toHaveText("Timestamp copied");
    await expect(stamp(page)).toBeFocused();
    await expect(stamp(page)).toHaveCSS("text-decoration-line", "none");
  });
  test(`${entry.name} failed or unavailable clipboard exposes selectable exact evidence and persistent feedback`, async ({ page }) => {
    await page.clock.install();
    await visit(page, entry); await installClipboard(page);
    await stamp(page).click();
    await expect.poll(async () => (await calls(page)).length).toBe(1);
    await settle(page, 0, false);
    await expect(message(page)).toContainText("Could not copy");
    const fallback = container(page).locator("[data-ops-time-fallback]");
    await expect(fallback).toHaveText(sourceIso); await expect(fallback).toBeVisible();
    await page.clock.fastForward(10_000); await expect(message(page)).toBeVisible();
    await container(page).getByRole("button", { name: "Dismiss copy message" }).click();
    await expect(stamp(page)).toBeFocused(); await expect(fallback).toBeHidden();
    await page.evaluate(() => Object.defineProperty(navigator, "clipboard", { configurable: true, value: {} }));
    await stamp(page).click(); await expect(message(page)).toContainText("Could not copy");
    await expect(fallback).toBeVisible();
  });
  test(`${entry.name} repeated success restarts one four-second feedback timer`, async ({ page }) => {
    await page.clock.install(); await visit(page, entry); await installClipboard(page);
    for (const attempt of [0, 1]) {
      await stamp(page).click();
      await expect.poll(async () => (await calls(page)).length).toBe(attempt + 1);
      await settle(page, attempt); await expect(message(page)).toHaveText("Timestamp copied");
      await page.clock.fastForward(attempt === 0 ? 3000 : 2000);
    }
    await expect(message(page)).toBeVisible();
    await page.clock.fastForward(2000); await expect(message(page)).toBeHidden();
  });
  test(`${entry.name} keyboard and touch copy the same source and retain focus`, async ({ page, browser }) => {
    await visit(page, entry); await installClipboard(page);
    await stamp(page).focus(); await page.keyboard.press("Enter");
    await expect.poll(async () => (await calls(page)).length).toBe(1);
    await settle(page, 0); await expect(stamp(page)).toBeFocused();
    const context = await browser.newContext({ hasTouch: true, viewport: { width: 390, height: 844 } });
    const touch = await context.newPage(); await visit(touch, entry); await installClipboard(touch);
    await stamp(touch).tap(); await expect.poll(() => calls(touch)).toEqual([{ text: sourceIso, active: true }]);
    await settle(touch, 0); await expect(message(touch)).toHaveText("Timestamp copied");
    await context.close();
  });
  test(`${entry.name} missing observations cannot be copied and refresh retains original precision`, async ({ page }) => {
    await visit(page, entry, "invalid-time");
    await expect(page.getByTestId("posture-row").locator("[data-ops-timestamp-copy]")).toHaveCount(0);
    await visit(page, entry, "refresh-failure");
    await page.locator("#search-health-refresh").click();
    await expect(stamp(page)).toHaveAttribute("data-ops-timestamp-copy", sourceIso);
    await installClipboard(page); await stamp(page).click();
    await expect.poll(() => calls(page)).toEqual([{ text: sourceIso, active: true }]);
  });
}
