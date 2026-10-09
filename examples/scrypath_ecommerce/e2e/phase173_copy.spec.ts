import { expandHealthDetails } from "./helpers/operator-ui";
import { expect, test, type Browser, type Locator } from "@playwright/test";
import { mkdirSync } from "node:fs";
import { join } from "node:path";

const ENTRYPOINTS = [
  { name: "mounted", url: "/admin/search/phase173/health", row: "posture-ScrypathEcommerce.Catalog.Product" },
  {
    name: "standalone",
    url: process.env.PHASE173_OPS_BASE_URL ?? "http://ops:4003/ops/phase173/health",
    row: "posture-ScrypathOps.Test.OpsPostA"
  }
] as const;

const SOURCE_ISO = "2026-10-04T13:02:05.123456-04:00";

async function openPage(browser: Browser, width: number, theme: "light" | "dark") {
  const context = await browser.newContext({
    viewport: { width, height: 1000 },
    hasTouch: true,
    colorScheme: theme
  });
  await context.addInitScript((value) => {
    localStorage.setItem("phx:theme", value);
    const testWindow = window as typeof window & {
      __phase173ClipboardWrites: string[];
      __phase173ResolveClipboardWrite: (() => void) | null;
    };
    testWindow.__phase173ClipboardWrites = [];
    testWindow.__phase173ResolveClipboardWrite = null;
    Object.defineProperty(navigator, "clipboard", {
      configurable: true,
      value: {
        writeText(text: string) {
          testWindow.__phase173ClipboardWrites.push(text);
          return new Promise<void>((resolve) => {
            testWindow.__phase173ResolveClipboardWrite = resolve;
          });
        }
      }
    });
  }, theme);
  const page = await context.newPage();
  return { context, page };
}


async function textAppearance(locator: Locator) {
  return locator.evaluate((element) => {
    const canvas = document.createElement("canvas");
    canvas.width = canvas.height = 1;
    const context = canvas.getContext("2d")!;
    const rgba = (color: string) => {
      context.clearRect(0, 0, 1, 1);
      context.fillStyle = color;
      context.fillRect(0, 0, 1, 1);
      return Array.from(context.getImageData(0, 0, 1, 1).data);
    };
    const over = (foreground: number[], background: number[]) =>
      foreground.slice(0, 3).map((channel, i) => channel * foreground[3] / 255 + background[i] * (1 - foreground[3] / 255));
    const ancestors: Element[] = [];
    for (let node: Element | null = element; node; node = node.parentElement) ancestors.unshift(node);
    let background = [255, 255, 255];
    for (const node of ancestors) background = over(rgba(getComputedStyle(node).backgroundColor), background);
    const style = getComputedStyle(element);
    const foreground = over(rgba(style.color), background);
    const luminance = (color: number[]) => color.map((channel) => {
      const value = channel / 255;
      return value <= 0.04045 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4;
    }).reduce((sum, channel, i) => sum + channel * [0.2126, 0.7152, 0.0722][i], 0);
    const a = luminance(foreground), b = luminance(background);
    return {
      contrast: (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05),
      font: style.fontFamily,
      height: element.getBoundingClientRect().height,
      size: style.fontSize
    };
  });
}

for (const entrypoint of ENTRYPOINTS) {
  test(`${entrypoint.name} copies one exact operational timestamp after clipboard resolution`, async ({ browser }) => {
    test.setTimeout(90_000);
    const captureDir = join(process.cwd(), "test-results", "phase173-copy-captures");
    mkdirSync(captureDir, { recursive: true });

    for (const width of [390, 1440]) {
      for (const theme of ["light", "dark"] as const) {
        const { context, page } = await openPage(browser, width, theme);
        await page.goto(entrypoint.url);
        await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
        await expandHealthDetails(page);
        const row = page.locator(`[id="${entrypoint.row}"]`);
        await expect(row).toBeVisible();
        const time = row.locator(".ops-signal-group").first().locator(".ops-time").first();
        await expect(time.locator(".ops-time__exact")).toHaveText(SOURCE_ISO);

        const copy = time.getByRole("button", { name: "Copy timestamp", exact: true });
        await expect(copy).toBeVisible();
        await expect(copy).toHaveText("2 days ago");
        await copy.click();
        await expect.poll(() => page.evaluate(() =>
          (window as typeof window & { __phase173ClipboardWrites: string[] }).__phase173ClipboardWrites
        )).toEqual([SOURCE_ISO]);

        const feedback = time.locator("[data-ops-time-feedback-text]");
        await expect(feedback).not.toContainText("Timestamp copied");
        await page.evaluate(() =>
          (window as typeof window & { __phase173ResolveClipboardWrite: (() => void) | null })
            .__phase173ResolveClipboardWrite?.()
        );
        await expect(feedback).toHaveText("Timestamp copied");
        expect(await time.locator("[data-ops-time-feedback]").evaluate(el => getComputedStyle(el).position)).toBe("fixed");
        await expect(time.locator("time.ops-time__value")).toHaveText("2 days ago");

        await page.evaluate(() => window.scrollTo(0, 0));
        await page.screenshot({
          path: join(captureDir, `phase173-copy-${entrypoint.name}-${width}-${theme}-success.png`),
          fullPage: true
        });
        await context.close();
      }
    }
  });

  test(`${entrypoint.name} copy text and feedback meet composed contrast and action targets`, async ({ browser }) => {
    test.setTimeout(90_000);
    for (const width of [390, 1440]) {
      for (const theme of ["light", "dark"] as const) {
        for (const preference of [theme, "system"]) {
          const { context, page } = await openPage(browser, width, theme);
          await page.addInitScript((value) => localStorage.setItem("phx:theme", value), preference);
          await page.emulateMedia({ reducedMotion: "reduce" });
          await page.goto(entrypoint.url);
          await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
          await expandHealthDetails(page);
          const time = page.locator(`[id="${entrypoint.row}"] .ops-signal-group`).first().locator(".ops-time").first();
          const copy = time.getByRole("button", { name: "Copy timestamp", exact: true });
          const appearance = await textAppearance(copy);
          expect(appearance.contrast, `${preference}/${theme} composed copy text contrast`).toBeGreaterThanOrEqual(4.5);
          expect(appearance.font).not.toMatch(/mono|courier/i);
          expect(appearance.size).toBe("14px");
          expect(appearance.height).toBeGreaterThanOrEqual(40);
          await copy.click();
          await page.evaluate(() => (window as typeof window & { __phase173ResolveClipboardWrite: (() => void) | null }).__phase173ResolveClipboardWrite?.());
          const feedback = time.locator("[data-ops-time-feedback-text]");
          await expect(feedback).toHaveText("Timestamp copied");
          const success = await textAppearance(feedback);
          expect(success.contrast, `${preference}/${theme} composed success text contrast`).toBeGreaterThanOrEqual(4.5);
          expect(success.font).not.toMatch(/mono|courier/i);
          await page.evaluate(() => Object.defineProperty(navigator, "clipboard", {
            configurable: true, value: { writeText: () => Promise.reject(new Error("denied")) }
          }));
          await copy.click();
          await expect(feedback).toHaveText("Could not copy timestamp. Select and copy the exact value.");
          const failure = await textAppearance(feedback);
          expect(failure.contrast, `${preference}/${theme} composed failure text contrast`).toBeGreaterThanOrEqual(4.5);
          const dismiss = time.getByRole("button", { name: "Dismiss copy message" });
          expect((await textAppearance(dismiss)).height).toBeGreaterThanOrEqual(40);
          await context.close();
        }
      }
    }
  });

  test(`${entrypoint.name} keeps the latest clipboard outcome when writes settle out of order`, async ({ browser }) => {
    const { context, page } = await openPage(browser, 390, "light");
    await page.goto(entrypoint.url);
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
    await expandHealthDetails(page);
    const time = page.locator(`[id="${entrypoint.row}"] .ops-signal-group`).first().locator(".ops-time").first();
    const copy = time.getByRole("button", { name: "Copy timestamp", exact: true });
    const feedback = time.locator("[data-ops-time-feedback-text]");
    await page.evaluate(() => {
      const testWindow = window as typeof window & {
        __phase173QueuedWrites: Array<{ resolve: () => void; reject: (error: Error) => void }>;
      };
      testWindow.__phase173QueuedWrites = [];
      Object.defineProperty(navigator, "clipboard", {
        configurable: true,
        value: {
          writeText() {
            return new Promise<void>((resolve, reject) => {
              testWindow.__phase173QueuedWrites.push({ resolve, reject });
            });
          }
        }
      });
    });

    await copy.click();
    await expect.poll(() => page.evaluate(() =>
      (window as typeof window & { __phase173QueuedWrites: unknown[] }).__phase173QueuedWrites.length
    )).toBe(1);
    await copy.click();
    await expect.poll(() => page.evaluate(() =>
      (window as typeof window & { __phase173QueuedWrites: unknown[] }).__phase173QueuedWrites.length
    )).toBe(2);
    await page.evaluate(() =>
      (window as typeof window & {
        __phase173QueuedWrites: Array<{ resolve: () => void; reject: (error: Error) => void }>;
      }).__phase173QueuedWrites[1].reject(new Error("denied"))
    );
    await expect(feedback).toHaveText("Could not copy timestamp. Select and copy the exact value.");
    await expect(time.locator("details")).toHaveAttribute("open", "");

    await page.evaluate(() =>
      (window as typeof window & {
        __phase173QueuedWrites: Array<{ resolve: () => void; reject: (error: Error) => void }>;
      }).__phase173QueuedWrites[0].resolve()
    );
    await expect(feedback).toHaveText("Could not copy timestamp. Select and copy the exact value.");
    await expect(time.locator("details")).toHaveAttribute("open", "");
    await context.close();
  });

  test(`${entrypoint.name} keeps rejected and unavailable clipboard feedback persistent and selectable`, async ({ browser }) => {
    const { context, page } = await openPage(browser, 390, "light");
    await page.goto(entrypoint.url);
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
    await expandHealthDetails(page);
    await page.clock.install();
    const time = page.locator(`[id="${entrypoint.row}"] .ops-signal-group`).first().locator(".ops-time").first();
    const copy = time.getByRole("button", { name: "Copy timestamp", exact: true });
    const feedback = time.locator("[data-ops-time-feedback-text]");
    await page.evaluate(() => {
      let readTextCalls = 0;
      Object.defineProperty(navigator, "clipboard", {
        configurable: true,
        value: {
          writeText() { return Promise.reject(new Error("denied")); },
          readText() { readTextCalls += 1; throw new Error("clipboard reads are forbidden"); }
        }
      });
      Object.defineProperty(window, "__phase173ClipboardReadCount", { get: () => readTextCalls });
    });

    await copy.click();
    await expect(feedback).toHaveText("Could not copy timestamp. Select and copy the exact value.");
    await expect(time.locator("details")).toHaveAttribute("open", "");
    const exact = time.locator("code.ops-time__exact");
    await expect(exact).toHaveText(SOURCE_ISO);
    await expect(exact).toHaveCSS("user-select", "text");
    await expect(time.locator("[data-ops-time-feedback-dismiss]")).toBeVisible();
    await page.clock.runFor(10_000);
    await expect(feedback).toHaveText("Could not copy timestamp. Select and copy the exact value.");

    await page.evaluate(() => Object.defineProperty(navigator, "clipboard", { configurable: true, value: undefined }));
    await copy.click();
    await expect(feedback).toHaveText("Could not copy timestamp. Select and copy the exact value.");
    await expect(time.locator("details")).toHaveAttribute("open", "");
    await expect.poll(() => page.evaluate(() =>
      (window as typeof window & { __phase173ClipboardReadCount: number }).__phase173ClipboardReadCount
    )).toBe(0);

    await time.getByRole("button", { name: "Dismiss copy message" }).click();
    await expect(feedback).toBeEmpty();
    await expect(time.locator("[data-ops-time-feedback-dismiss]")).toBeHidden();
    await context.close();
  });

  test(`${entrypoint.name} supports keyboard and touch and restarts the four-second success timer`, async ({ browser }) => {
    const { context, page } = await openPage(browser, 390, "light");
    await page.goto(entrypoint.url);
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
    await expandHealthDetails(page);
    await page.clock.install();
    const time = page.locator(`[id="${entrypoint.row}"] .ops-signal-group`).first().locator(".ops-time").first();
    const copy = time.getByRole("button", { name: "Copy timestamp", exact: true });
    const feedback = time.locator("[data-ops-time-feedback-text]");

    await copy.focus();
    await page.keyboard.press("Enter");
    await expect.poll(() => page.evaluate(() =>
      (window as typeof window & { __phase173ClipboardWrites: string[] }).__phase173ClipboardWrites
    )).toEqual([SOURCE_ISO]);
    await page.evaluate(() =>
      (window as typeof window & { __phase173ResolveClipboardWrite: (() => void) | null })
        .__phase173ResolveClipboardWrite?.()
    );
    await expect(feedback).toHaveText("Timestamp copied");
    await expect(copy).toBeFocused();
    await page.clock.runFor(3000);

    await page.locator(`#theme-toggle [data-phx-theme="dark"]`).click();
    await expect(page.locator("html")).toHaveAttribute("data-theme-effective", "dark");
    const box = await copy.boundingBox();
    expect(box).not.toBeNull();
    await page.touchscreen.tap(box!.x + box!.width / 2, box!.y + box!.height / 2);
    await expect.poll(() => page.evaluate(() =>
      (window as typeof window & { __phase173ClipboardWrites: string[] }).__phase173ClipboardWrites
    )).toEqual([SOURCE_ISO, SOURCE_ISO]);
    await page.evaluate(() =>
      (window as typeof window & { __phase173ResolveClipboardWrite: (() => void) | null })
        .__phase173ResolveClipboardWrite?.()
    );
    await expect(feedback).toHaveText("Timestamp copied");
    await page.clock.runFor(1500);
    await expect(feedback).toHaveText("Timestamp copied");
    await page.clock.runFor(2500);
    await expect(feedback).toBeEmpty();
    await expect(time.locator("time.ops-time__value")).toHaveText("2 days ago");

    const dimensions = await page.evaluate(() => ({
      viewport: document.documentElement.clientWidth,
      document: document.documentElement.scrollWidth
    }));
    expect(dimensions.document).toBeLessThanOrEqual(dimensions.viewport);
    await page.locator(`#theme-toggle [data-phx-theme="light"]`).click();
    await expect(page.locator("html")).toHaveAttribute("data-theme-effective", "light");
    await context.close();
  });

  test(`${entrypoint.name} omits copy for Checked, missing, invalid, and unobserved timestamps`, async ({ browser }) => {
    const { context, page } = await openPage(browser, 390, "light");
    await page.goto(entrypoint.url);
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
    await expandHealthDetails(page);
    await expect(page.locator("#search-health-refresh").locator("..").locator(".ops-time__copy")).toHaveCount(0);
    await context.close();

    for (const scenario of ["source-error", "no-success", "missing-time", "manual"] as const) {
      const { context: scenarioContext, page: scenarioPage } = await openPage(browser, 390, "light");
      const separator = entrypoint.url.includes("?") ? "&" : "?";
      await scenarioPage.goto(`${entrypoint.url}${separator}scenario=${scenario}`);
      await expect(scenarioPage.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
      await expandHealthDetails(scenarioPage);
      const row = scenarioPage.locator(`[id="${entrypoint.row}"]`);
      await expect(row).toBeVisible();
      const backendTime = row.locator(".ops-signal-group").first().locator(".ops-time").first();

      if (scenario !== "manual") await expect(backendTime.locator(".ops-time__copy")).toHaveCount(0);
      else await expect(row.locator("[aria-label^='Queue job health'] .ops-time__copy")).toHaveCount(0);

      await scenarioContext.close();
    }
  });

  test(`${entrypoint.name} retains copy and snapshot age after a failed refresh server patch`, async ({ browser }) => {
    const { context, page } = await openPage(browser, 390, "light");
    await page.goto(entrypoint.url);
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
    await expandHealthDetails(page);
    const row = page.locator(`[id="${entrypoint.row}"]`);
    const refresh = page.getByRole("button", { name: "Refresh search health" });
    const checked = page.locator("#search-health-refresh").locator("..");
    const initialTime = row.locator(".ops-signal-group").first().locator(".ops-time").first();
    await expect(initialTime.locator("time.ops-time__value")).toHaveText("2 days ago");
    await refresh.click();
    await expect(initialTime.locator("time.ops-time__value")).toHaveText("2 days ago");

    await refresh.evaluate((button) => button.setAttribute("phx-value-scenario", "source-error"));
    await refresh.click();
    await expect(row).toContainText("fetch error: :fixture_unavailable");
    await expect(row).toContainText("last success retained from the previous check");
    const retained = row.locator(".ops-time").first();
    await expect(retained.locator("time.ops-time__value")).toHaveText("2 days ago");
    await expect(retained.locator(".ops-time__exact")).toHaveText(SOURCE_ISO);
    await expect(retained.locator(".ops-time__copy")).toBeVisible();
    await expect(checked.locator("time")).toHaveAttribute("datetime", "2026-10-07T17:18:42.318Z");

    await retained.getByRole("button", { name: "Copy timestamp" }).click();
    await expect.poll(() => page.evaluate(() =>
      (window as typeof window & { __phase173ClipboardWrites: string[] }).__phase173ClipboardWrites
    )).toEqual([SOURCE_ISO]);
    await page.evaluate(() =>
      (window as typeof window & { __phase173ResolveClipboardWrite: (() => void) | null })
        .__phase173ResolveClipboardWrite?.()
    );
    await expect(retained.locator("[data-ops-time-feedback-text]")).toHaveText("Timestamp copied");
    await context.close();
  });
}
