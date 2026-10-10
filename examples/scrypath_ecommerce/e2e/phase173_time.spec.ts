import { expect, test, type Browser, type Page } from "@playwright/test";
import { mkdir } from "node:fs/promises";
import { join } from "node:path";

import { waitForLiveConnected } from "./helpers/e2e";

type Entry = { name: string; url: string };

const standaloneBase = process.env.PHASE173_STANDALONE_BASE_URL || "http://standalone_ops:4003";
const screenshotDir = process.env.PHASE173_SCREENSHOT_DIR || "test-results/phase173";
const sourceIso = "2026-10-04T13:02:05.123456-04:00";
const entries: Entry[] = [
  { name: "mounted", url: "/admin/search/phase173/health" },
  { name: "standalone", url: `${standaloneBase}/ops/phase173/health` }
];

async function visit(page: Page, entry: Entry): Promise<void> {
  await page.goto(new URL(entry.url, process.env.PLAYWRIGHT_BASE_URL || "http://web:4002").toString());
  await waitForLiveConnected(page);
  await expect(page.getByRole("heading", { name: "Search health", exact: true })).toBeVisible();
}

async function visitScenario(page: Page, entry: Entry, name: string): Promise<void> {
  const baseURL = process.env.PLAYWRIGHT_BASE_URL || "http://web:4002";
  const url = new URL(entry.url, baseURL);
  url.searchParams.set("scenario", name);
  await page.goto(url.toString());
  await waitForLiveConnected(page);
}

async function setTheme(page: Page, preference: "light" | "dark"): Promise<void> {
  await page.evaluate(
    ({ key, value }) => window.localStorage.setItem(key, value),
    { key: "phx:theme", value: preference }
  );
  await page.reload();
  await waitForLiveConnected(page);
  await expect(page.locator("html")).toHaveAttribute("data-theme-preference", preference);
}

async function assertEvidence(page: Page): Promise<void> {
  const row = page.getByTestId("posture-row").first();
  const backendTime = row.locator("time.ops-time__value").first();
  await expect(backendTime).toHaveAttribute("datetime", sourceIso);
  await expect(backendTime).toHaveText("2 days ago");

  const disclosure = row.locator("details.ops-time__details").first();
  const summary = disclosure.getByText("Exact timestamp", { exact: true });
  await summary.click();
  await expect(disclosure).toHaveAttribute("open", "");
  await expect(disclosure.locator(".ops-time__evidence-value")).toHaveText(sourceIso);
  await expect(disclosure.getByText("Oct 4, 2026 at 17:02:05 UTC", { exact: true })).toBeVisible();
  await expect(disclosure.getByText("UTC equivalent", { exact: true })).toBeVisible();
}

for (const entry of entries) {
  test(`${entry.name} operational time uses source provenance and an explicit disclosure`, async ({ page }) => {
    test.info().annotations.push({ type: "source-sha", description: process.env.SCRYPATH_SOURCE_SHA || "unknown" });
    await visit(page, entry);
    await assertEvidence(page);

    const backendGroup = page.getByRole("region", { name: /Backend task signals/ });
    const queueGroup = page.getByRole("region", { name: /Queue job signals/ });
    await expect(backendGroup.locator("time.ops-time__value")).toHaveCount(1);
    await expect(queueGroup.locator("time.ops-time__value")).toHaveAttribute(
      "datetime",
      "2026-10-05T11:12:13.456-04:00"
    );

    const originalAge = await backendGroup.locator("time.ops-time__value").innerText();
    await page.locator("#search-health-refresh").click();
    await waitForLiveConnected(page);
    await expect(backendGroup.locator("time.ops-time__value")).toHaveText(originalAge);
    await expect(backendGroup.locator("details .ops-time__evidence-value")).toHaveText(sourceIso);
  });

  test(`${entry.name} timestamp disclosure remains readable at mobile and rail boundaries`, async ({ page }) => {
    test.info().annotations.push({ type: "source-sha", description: process.env.SCRYPATH_SOURCE_SHA || "unknown" });
    await visit(page, entry);
    await mkdir(screenshotDir, { recursive: true });

    for (const theme of ["light", "dark"] as const) {
      await setTheme(page, theme);
      for (const width of [390, 1279, 1280, 1440]) {
        await page.setViewportSize({ width, height: width === 390 ? 844 : 900 });
        const row = page.getByTestId("posture-row").first();
        const disclosure = row.locator("details.ops-time__details").first();
        if (!(await disclosure.evaluate((node: HTMLDetailsElement) => node.open))) {
          await disclosure.locator("summary").click();
        }

        const geometry = await page.evaluate(() => ({
          viewport: window.innerWidth,
          document: document.documentElement.scrollWidth,
          evidence: (() => {
            const value = document.querySelector<HTMLElement>(".ops-time__evidence-value")!;
            return {
              width: value.clientWidth,
              scrollWidth: value.scrollWidth,
              overflowWrap: getComputedStyle(value).overflowWrap,
              userSelect: getComputedStyle(value).userSelect
            };
          })()
        }));

        expect(geometry.document, `${entry.name} page overflow at ${width}px`).toBeLessThanOrEqual(geometry.viewport);
        expect(geometry.evidence.scrollWidth, `${entry.name} exact ISO overflow at ${width}px`).toBeLessThanOrEqual(
          geometry.evidence.width + 1
        );
        expect(geometry.evidence.overflowWrap).toBe("anywhere");
        expect(geometry.evidence.userSelect).toBe("text");
        await expect(disclosure.locator(".ops-time__evidence-value")).toHaveText(sourceIso);

        await page.evaluate(() => window.scrollTo(0, 0));
        await page.screenshot({
          path: join(screenshotDir, `${entry.name}-${theme}-${width}.png`),
          fullPage: true
        });
      }
    }
  });

  test(`${entry.name} exact disclosure works by keyboard and touch`, async ({ browser }) => {
    const baseURL = process.env.PLAYWRIGHT_BASE_URL || "http://web:4002";
    const keyboardContext = await browser.newContext({ baseURL });
    const keyboardPage = await keyboardContext.newPage();
    await visit(keyboardPage, entry);
    const keyboardDetails = keyboardPage.getByTestId("posture-row").first().locator("details").first();
    const keyboardSummary = keyboardDetails.locator("summary");
    await keyboardSummary.focus();
    await keyboardPage.keyboard.press("Enter");
    await expect(keyboardDetails).toHaveAttribute("open", "");
    await expect(keyboardDetails.locator(".ops-time__evidence-value")).toHaveText(sourceIso);
    await keyboardContext.close();

    const touchContext = await browser.newContext({ baseURL, hasTouch: true, viewport: { width: 390, height: 844 } });
    const touchPage = await touchContext.newPage();
    await visit(touchPage, entry);
    const touchDetails = touchPage.getByTestId("posture-row").first().locator("details").first();
    const touchSummary = touchDetails.locator("summary");
    await touchSummary.scrollIntoViewIfNeeded();
    await touchSummary.tap();
    await expect(touchDetails).toHaveAttribute("open", "");
    await expect(touchDetails.locator(".ops-time__evidence-value")).toHaveText(sourceIso);
    await touchContext.close();
  });

  test(`${entry.name} distinguishes absent, invalid, unavailable, and unused timestamp evidence`, async ({ page }) => {
    await visitScenario(page, entry, "failed");
    const row = page.getByTestId("posture-row").first();

    await expect(row.locator(".ops-time__value").first()).toHaveText("No success observed");
    await expect(row.locator("details")).toHaveCount(0);

    await visitScenario(page, entry, "invalid-time");
    await expect(row.locator(".ops-time__value").first()).toHaveText("Success time not observed");
    await expect(row.locator(".ops-time__value").nth(1)).toHaveText("Success time not observed");
    await expect(row.locator("details")).toHaveCount(0);

    await visitScenario(page, entry, "queue-unused");
    const queueGroup = page.getByRole("region", { name: /Queue job signals/ });
    await expect(queueGroup).toContainText("Queue not used");
    await expect(queueGroup.locator("details")).toHaveCount(0);

    await visitScenario(page, entry, "unknown");
    await expect(row).toContainText("Search health could not be checked: :phase173_queue_unavailable");
    await expect(row).toContainText("Not observed: :phase173_queue_unavailable");
    await expect(row.locator("details")).toHaveCount(0);

    await visitScenario(page, entry, "unavailable");
    await expect(row).toContainText("Not observed: :phase173_backend_unavailable");
    await expect(row.locator("details")).toHaveCount(0);

    await visitScenario(page, entry, "refresh-failure");
    await page.locator("#search-health-refresh").click();
    await expect(row).toContainText("Search health could not be checked: :phase173_backend_unavailable");
    await expect(row).toContainText("Current observation is unavailable; this source-local evidence is retained from check");
    await expect(row.locator(".ops-time__value").first()).toHaveText("2 days ago");
    await expect(row.locator(".ops-time__evidence-value").first()).toHaveText(sourceIso);
    await expect(row).toContainText("Queue last success");
    await expect(row.locator("details")).toHaveCount(2);
  });
}
