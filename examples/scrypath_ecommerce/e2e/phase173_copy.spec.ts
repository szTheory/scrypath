import { expect, test, type Browser, type Page } from "@playwright/test";
import { mkdir } from "node:fs/promises";
import { join } from "node:path";

import { waitForLiveConnected } from "./helpers/e2e";

type Entry = { name: string; url: string };
type Outcome = "resolve" | "reject";

const sourceIso = "2026-10-04T13:02:05.123456-04:00";
const standaloneBase = process.env.PHASE173_STANDALONE_BASE_URL || "http://standalone_ops:4003";
const screenshotDir = process.env.PHASE173_SCREENSHOT_DIR || "test-results/phase173";
const entries: Entry[] = [
  { name: "mounted", url: "/admin/search/phase173/health" },
  { name: "standalone", url: `${standaloneBase}/ops/phase173/health` }
];

async function visit(page: Page, entry: Entry, scenario = "healthy"): Promise<void> {
  const url = new URL(entry.url, process.env.PLAYWRIGHT_BASE_URL || "http://web:4002");
  url.searchParams.set("scenario", scenario);
  await page.goto(url.toString());
  await waitForLiveConnected(page);
  await expect(page.getByRole("heading", { name: "Search health", exact: true })).toBeVisible();
}

async function installDeferredClipboard(page: Page): Promise<void> {
  await page.evaluate(() => {
    const state = { calls: [] as Array<{ text: string; active: boolean }>, pending: [] as Array<{
      resolve: () => void;
      reject: () => void;
    }> };
    Object.defineProperty(window, "__phase173Clipboard", { configurable: true, value: state });
    Object.defineProperty(navigator, "clipboard", {
      configurable: true,
      value: {
        writeText(text: string) {
          state.calls.push({ text, active: navigator.userActivation.isActive });
          return new Promise<void>((resolve, reject) => state.pending.push({ resolve, reject }));
        }
      }
    });
  });
}

async function clipboardCallCount(page: Page): Promise<number> {
  return page.evaluate(() => (window as any).__phase173Clipboard.calls.length as number);
}

async function clipboardCall(page: Page, index = 0): Promise<{ text: string; active: boolean }> {
  return page.evaluate((callIndex) => (window as any).__phase173Clipboard.calls[callIndex], index);
}

async function settleClipboard(page: Page, index: number, outcome: Outcome): Promise<void> {
  await page.evaluate(({ callIndex, result }) => {
    const pending = (window as any).__phase173Clipboard.pending[callIndex];
    if (result === "resolve") pending.resolve();
    else pending.reject(new DOMException("Clipboard write denied", "NotAllowedError"));
  }, { callIndex: index, result: outcome });
}

async function copyButton(page: Page) {
  return page.getByRole("button", { name: "Copy timestamp", exact: true }).first();
}

function copyMessage(page: Page) {
  return page.locator("[data-ops-timestamp-message]").first();
}

for (const entry of entries) {
  test(`${entry.name} copies the exact ISO only after the user-activated write resolves`, async ({ page }) => {
    test.info().annotations.push({ type: "source-sha", description: process.env.SCRYPATH_SOURCE_SHA || "unknown" });
    await visit(page, entry);
    await installDeferredClipboard(page);

    const button = await copyButton(page);
    const age = await page.getByTestId("posture-row").first().locator("time.ops-time__value").first().innerText();
    await button.click();
    await expect.poll(() => clipboardCallCount(page)).toBe(1);
    expect(await clipboardCall(page)).toEqual({ text: sourceIso, active: true });
    const feedback = page.locator("[data-ops-timestamp-feedback]").first();
    const message = copyMessage(page);
    await expect(feedback).toBeHidden();

    await settleClipboard(page, 0, "resolve");
    await expect(message).toHaveText("Timestamp copied");
    await expect(button).toBeFocused();
    await expect(page.getByTestId("posture-row").first().locator("time.ops-time__value").first()).toHaveText(age);

    await page.locator("#search-health-refresh").click();
    await waitForLiveConnected(page);
    await expect(page.getByTestId("posture-row").first().locator("time.ops-time__value").first()).toHaveText(age);
    await expect(page.getByTestId("posture-row").first().locator(".ops-time__evidence-value").first()).toHaveText(sourceIso);
  });

  test(`${entry.name} rejection and unavailable clipboard expose persistent selectable evidence`, async ({ page }) => {
    test.info().annotations.push({ type: "source-sha", description: process.env.SCRYPATH_SOURCE_SHA || "unknown" });
    await page.clock.install({ time: new Date("2026-10-06T17:18:42.318Z") });
    await visit(page, entry);
    await installDeferredClipboard(page);
    const button = await copyButton(page);
    const feedback = page.locator("[data-ops-timestamp-feedback]").first();
    const message = copyMessage(page);

    await button.click();
    await expect.poll(() => clipboardCallCount(page)).toBe(1);
    await settleClipboard(page, 0, "resolve");
    await expect(message).toHaveText("Timestamp copied");

    await button.click();
    await expect.poll(() => clipboardCallCount(page)).toBe(2);
    await settleClipboard(page, 1, "reject");
    await expect(message).toHaveText("Could not copy timestamp. Select and copy the exact value.");
    const disclosure = page.getByTestId("posture-row").first().locator("details.ops-time__details").first();
    await expect(disclosure).toHaveAttribute("open", "");
    await expect(disclosure.locator(".ops-time__evidence-value")).toHaveText(sourceIso);
    await expect(disclosure.locator(".ops-time__evidence-value")).toHaveCSS("user-select", "text");

    await page.clock.fastForward(10_000);
    await expect(feedback).toBeVisible();
    const dismiss = feedback.getByRole("button", { name: "Dismiss copy message" });
    await dismiss.click();
    await expect(feedback).toBeHidden();
    await expect(button).toBeFocused();

    await page.evaluate(() => Object.defineProperty(navigator, "clipboard", { configurable: true, value: {} }));
    await button.click();
    await expect(message).toHaveText("Could not copy timestamp. Select and copy the exact value.");
    await expect(disclosure).toHaveAttribute("open", "");
    await page.clock.fastForward(10_000);
    await expect(feedback).toBeVisible();
  });

  test(`${entry.name} repeated success restarts one four-second message and reflows in both themes`, async ({ page }) => {
    test.info().annotations.push({ type: "source-sha", description: process.env.SCRYPATH_SOURCE_SHA || "unknown" });
    await page.clock.install({ time: new Date("2026-10-06T17:18:42.318Z") });
    await visit(page, entry);
    await installDeferredClipboard(page);
    const button = await copyButton(page);
    const feedback = page.locator("[data-ops-timestamp-feedback]").first();
    const message = copyMessage(page);

    await button.click();
    await expect.poll(() => clipboardCallCount(page)).toBe(1);
    await settleClipboard(page, 0, "resolve");
    await expect(message).toHaveText("Timestamp copied");
    await page.clock.fastForward(3_000);

    await button.click();
    await expect.poll(() => clipboardCallCount(page)).toBe(2);
    await settleClipboard(page, 1, "resolve");
    await expect(message).toHaveText("Timestamp copied");
    await page.clock.fastForward(2_000);
    await expect(feedback).toBeVisible();
    await page.clock.fastForward(2_000);
    await expect(feedback).toBeHidden();

    await mkdir(screenshotDir, { recursive: true });
    for (const theme of ["light", "dark"] as const) {
      await page.evaluate((preference) => window.localStorage.setItem("phx:theme", preference), theme);
      await page.reload();
      await waitForLiveConnected(page);
      await installDeferredClipboard(page);
      const themedButton = await copyButton(page);
      await themedButton.click();
      await expect.poll(() => clipboardCallCount(page)).toBe(1);
      await settleClipboard(page, 0, "resolve");
      await expect(copyMessage(page)).toHaveText("Timestamp copied");
      for (const width of [390, 1440]) {
        await page.setViewportSize({ width, height: width === 390 ? 844 : 900 });
        await expect(await copyButton(page)).toBeVisible();
        const disclosure = page.getByTestId("posture-row").first().locator("details.ops-time__details").first();
        if (!(await disclosure.evaluate((node: HTMLDetailsElement) => node.open))) {
          await disclosure.locator("summary").click();
        }
        await expect(disclosure.locator(".ops-time__evidence-value")).toHaveText(sourceIso);
        const geometry = await page.evaluate(() => ({
          viewport: window.innerWidth,
          document: document.documentElement.scrollWidth,
          exact: (() => {
            const value = document.querySelector<HTMLElement>(".ops-time__evidence-value")!;
            return { width: value.clientWidth, scrollWidth: value.scrollWidth, userSelect: getComputedStyle(value).userSelect };
          })(),
          button: (() => {
            const node = document.querySelector<HTMLElement>(".ops-time__copy");
            return {
              height: node?.getBoundingClientRect().height ?? 0,
              fontSize: node ? getComputedStyle(node).fontSize : "missing",
              fontWeight: node ? getComputedStyle(node).fontWeight : "missing"
            };
          })(),
          ageFontSize: (() => {
            const node = document.querySelector<HTMLElement>(".ops-time--operational .ops-time__value");
            return node ? getComputedStyle(node).fontSize : "missing";
          })()
        }));
        expect(geometry.document).toBeLessThanOrEqual(geometry.viewport);
        expect(geometry.exact.scrollWidth).toBeLessThanOrEqual(geometry.exact.width + 1);
        expect(geometry.exact.userSelect).toBe("text");
        expect(geometry.button.height).toBeGreaterThanOrEqual(40);
        expect(geometry.button.fontSize).toBe("14px");
        expect(geometry.button.fontWeight).toBe("600");
        expect(geometry.ageFontSize).toBe("14px");
        await page.evaluate(() => window.scrollTo(0, 0));
        await page.screenshot({ path: join(screenshotDir, `${entry.name}-copy-${theme}-${width}.png`), fullPage: true });
      }
    }
  });

  test(`${entry.name} only offers copying for validated last-success values and retains failed-refresh age`, async ({ page }) => {
    test.info().annotations.push({ type: "source-sha", description: process.env.SCRYPATH_SOURCE_SHA || "unknown" });
    await visit(page, entry, "failed");
    const backend = page.getByRole("region", { name: /Backend task signals/ });
    await expect(backend.getByRole("button", { name: "Copy timestamp" })).toHaveCount(0);

    await visit(page, entry, "invalid-time");
    await expect(page.locator("[data-ops-timestamp-copy]")).toHaveCount(0);
    await expect(page.getByText("Success time not observed")).toHaveCount(2);

    await visit(page, entry, "queue-unused");
    await expect(page.getByRole("region", { name: /Queue job signals/ }).getByRole("button", { name: "Copy timestamp" })).toHaveCount(0);
    const button = await copyButton(page);
    await expect(button).toBeVisible();
    const age = await page.getByTestId("posture-row").first().locator("time.ops-time__value").first().innerText();
    await page.locator("#search-health-refresh").click();
    await waitForLiveConnected(page);
    await expect(page.getByTestId("posture-row").first().locator("time.ops-time__value").first()).toHaveText(age);
    await expect(await copyButton(page)).toHaveAttribute("data-ops-timestamp-copy", sourceIso);
  });

  test(`${entry.name} copy action works with keyboard and touch`, async ({ page, browser }) => {
    test.info().annotations.push({ type: "source-sha", description: process.env.SCRYPATH_SOURCE_SHA || "unknown" });
    await visit(page, entry);
    await installDeferredClipboard(page);
    const button = await copyButton(page);
    await button.focus();
    await page.keyboard.press("Enter");
    await expect.poll(() => clipboardCallCount(page)).toBe(1);
    expect(await clipboardCall(page)).toEqual({ text: sourceIso, active: true });
    await settleClipboard(page, 0, "resolve");
    await expect(copyMessage(page)).toHaveText("Timestamp copied");
    await expect(button).toBeFocused();

    const touchContext = await browser.newContext({ hasTouch: true, viewport: { width: 390, height: 844 } });
    const touchPage = await touchContext.newPage();
    await visit(touchPage, entry);
    await installDeferredClipboard(touchPage);
    const touchButton = await copyButton(touchPage);
    await touchButton.scrollIntoViewIfNeeded();
    await touchButton.tap();
    await expect.poll(() => clipboardCallCount(touchPage)).toBe(1);
    expect(await clipboardCall(touchPage)).toEqual({ text: sourceIso, active: true });
    await settleClipboard(touchPage, 0, "resolve");
    await expect(copyMessage(touchPage)).toHaveText("Timestamp copied");
    await touchContext.close();
  });
}
