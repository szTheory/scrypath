import { expect, test, type Browser, type Page } from "@playwright/test";
import { mkdir } from "node:fs/promises";
import { join } from "node:path";

import { waitForLiveConnected } from "./helpers/e2e";

type Entry = {
  name: string;
  url: string;
  mountPath: string;
  schema: string;
  index: string;
};

const standaloneBase = process.env.PHASE173_STANDALONE_BASE_URL || "http://standalone_ops:4003";
const screenshotDir = process.env.PHASE173_SCREENSHOT_DIR || "test-results/phase173";
const entries: Entry[] = [
  {
    name: "mounted",
    url: "/admin/search/phase173/health",
    mountPath: "/admin/search",
    schema: "ScrypathEcommerce.Catalog.Product",
    index: "phase173_product"
  },
  {
    name: "standalone",
    url: `${standaloneBase}/ops/phase173/health`,
    mountPath: "/ops/phase173",
    schema: "ScrypathOps.Phase173FixtureSchema",
    index: "phase173_phase173_fixture_schema"
  }
];

const modes = [
  { name: "light", preference: "light", colorScheme: "light" as const },
  { name: "dark", preference: "dark", colorScheme: "dark" as const },
  { name: "system", preference: "system", colorScheme: "dark" as const }
];

async function setStoredPreference(page: Page, preference: string): Promise<void> {
  await page.evaluate(
    ({ key, value }) => {
      if (value === "system") window.localStorage.removeItem(key);
      else window.localStorage.setItem(key, value);
    },
    { key: "phx:theme", value: preference }
  );
}

async function expectTheme(page: Page, preference: string, effective: "light" | "dark"): Promise<void> {
  await expect(page.locator("html")).toHaveAttribute("data-theme-preference", preference);
  await expect(page.locator("html")).toHaveAttribute("data-theme-effective", effective);

  if (preference === "system") {
    await expect(page.locator("html")).not.toHaveAttribute("data-theme");
  } else {
    await expect(page.locator("html")).toHaveAttribute("data-theme", preference);
  }

  const selected = page.locator('#theme-toggle [data-theme-selected="true"]');
  await expect(selected).toHaveCount(1);
  await expect(selected).toHaveAttribute("aria-pressed", "true");
  await expect(page.locator('#theme-toggle [aria-pressed="false"]')).toHaveCount(2);

  const selectedDimensions = await selected.evaluate((button) => ({
    minHeight: parseFloat(getComputedStyle(button).minHeight),
    minWidth: parseFloat(getComputedStyle(button).minWidth),
    height: button.getBoundingClientRect().height,
    width: button.getBoundingClientRect().width
  }));
  expect(selectedDimensions.minHeight).toBeGreaterThanOrEqual(44);
  expect(selectedDimensions.minWidth).toBeGreaterThanOrEqual(44);
  expect(selectedDimensions.height).toBeGreaterThanOrEqual(44);
  expect(selectedDimensions.width).toBeGreaterThanOrEqual(44);
  await expect
    .poll(() => selected.evaluate((button) => getComputedStyle(button).backgroundColor))
    .not.toBe("rgba(0, 0, 0, 0)");
  await expect
    .poll(() => page.locator("html").evaluate((element) => getComputedStyle(element).getPropertyValue("--ops-selection").trim()))
    .not.toBe("");
}

async function visitEntry(
  page: Page,
  entry: Entry,
  preference = "system",
  storageAvailable = true
): Promise<void> {
  const bundlePath = "/assets/js/app.js";
  const bundleResponse = page.waitForResponse((response) => new URL(response.url()).pathname === bundlePath);
  await page.goto(entry.url);
  expect((await bundleResponse).ok(), `${entry.name} application bundle must load successfully`).toBe(true);
  await waitForLiveConnected(page);
  if (storageAvailable) await setStoredPreference(page, preference);
  await page.reload();
  await waitForLiveConnected(page);
  await expect(page.getByRole("heading", { name: "Search health", exact: true })).toBeVisible();
}

async function expectSourceRow(page: Page, entry: Entry): Promise<void> {
  const row = page.getByTestId("posture-row").first();
  await expect(row).toBeVisible();
  await expect(row).toContainText(entry.schema);
  await expect(row).toContainText(entry.index);
}

async function captureShell(page: Page, entry: Entry, theme: string, width: number): Promise<void> {
  await page.setViewportSize({ width, height: width === 390 ? 844 : 900 });
  await expect(page.locator("#theme-toggle")).toBeVisible();
  await expect(page.locator("#theme-toggle button")).toHaveCount(3);
  await expect(page.locator("#theme-toggle button span")).toHaveText(["System", "Light", "Dark"]);

  const geometry = await page.evaluate(() => ({
    viewportWidth: window.innerWidth,
    documentWidth: document.documentElement.scrollWidth,
    shellBackgroundImage: getComputedStyle(document.querySelector(".ops-shell") as HTMLElement).backgroundImage
  }));
  expect(geometry.documentWidth, `${entry.name} shell must not overflow at ${width}px`).toBeLessThanOrEqual(
    geometry.viewportWidth
  );
  expect(geometry.shellBackgroundImage).toBe("none");

  const cssHrefs = await page.locator('link[rel="stylesheet"]').evaluateAll((links) =>
    links.map((link) => (link as HTMLLinkElement).href)
  );
  const jsSources = await page.locator('script[src*="/assets/js/app.js"]').evaluateAll((scripts) =>
    scripts.map((script) => (script as HTMLScriptElement).src)
  );

  if (entry.name === "mounted") {
    // The host owns the mounted LiveSocket and hook bundle; Ops contributes its mounted CSS.
    expect(cssHrefs.some((href) => new URL(href).pathname === "/assets/css/app.css")).toBe(true);
    expect(cssHrefs.some((href) => href.includes(`${entry.mountPath}/assets/css/app.css`))).toBe(true);
    expect(jsSources.some((src) => new URL(src).pathname === "/assets/js/app.js")).toBe(true);
  } else {
    expect(cssHrefs.some((href) => new URL(href).pathname === "/assets/css/app.css")).toBe(true);
    expect(jsSources.some((src) => new URL(src).pathname === "/assets/js/app.js")).toBe(true);
  }

  await mkdir(screenshotDir, { recursive: true });
  await page.evaluate(() => window.scrollTo(0, 0));
  await page.screenshot({
    path: join(screenshotDir, `${entry.name}-${theme}-${width}.png`),
    fullPage: true
  });
}

async function makeStorageUnavailable(browser: Browser): Promise<{ page: Page; close: () => Promise<void> }> {
  const context = await browser.newContext();
  await context.addInitScript(() => {
    Object.defineProperty(window, "localStorage", {
      configurable: true,
      get() {
        throw new DOMException("Storage denied by test", "SecurityError");
      }
    });
  });
  return { page: await context.newPage(), close: () => context.close() };
}

async function makeStorageMethodThrowing(
  browser: Browser,
  method: "getItem" | "setItem" | "removeItem"
): Promise<{ page: Page; close: () => Promise<void> }> {
  const context = await browser.newContext();
  await context.addInitScript((storageMethod) => {
    if (location.origin === "null") return;

    Object.defineProperty(Storage.prototype, storageMethod, {
      configurable: true,
      value() {
        throw new DOMException("Storage method denied by test", "SecurityError");
      }
    });
  }, method);
  return { page: await context.newPage(), close: () => context.close() };
}

for (const entry of entries) {
  for (const mode of modes) {
    test(`${entry.name} shell renders ${mode.name} preference and neutral floor`, async ({ page }) => {
      test.info().annotations.push({ type: "source-sha", description: process.env.SCRYPATH_SOURCE_SHA || "unknown" });
      await page.emulateMedia({ colorScheme: mode.colorScheme });
      await visitEntry(page, entry, mode.preference);
      await expectTheme(page, mode.preference, mode.colorScheme);
      await expectSourceRow(page, entry);

      const expectedFloor = mode.colorScheme === "dark" ? "rgb(17, 20, 25)" : "rgb(247, 246, 243)";
      await expect
        .poll(() => page.locator(".ops-shell").evaluate((element) => getComputedStyle(element).backgroundColor))
        .toBe(expectedFloor);

      await captureShell(page, entry, mode.name, 1440);
      await captureShell(page, entry, mode.name, 390);
      for (const width of [1279, 1280]) {
        await page.setViewportSize({ width, height: 900 });
        const documentWidth = await page.evaluate(() => document.documentElement.scrollWidth);
        expect(documentWidth, `${entry.name} rail boundary at ${width}px`).toBeLessThanOrEqual(width);
      }
    });
  }

  test(`${entry.name} selection follows preference through pointer, keyboard, OS change, reload, and navigation`, async ({ page }) => {
    await page.emulateMedia({ colorScheme: "dark" });
    await visitEntry(page, entry, "system");
    await expectTheme(page, "system", "dark");

    await page.getByRole("button", { name: "Use light theme" }).click();
    await expectTheme(page, "light", "light");

    const darkButton = page.getByRole("button", { name: "Use dark theme" });
    await darkButton.focus();
    await page.keyboard.press("Space");
    await expectTheme(page, "dark", "dark");

    const systemButton = page.getByRole("button", { name: "Use system theme" });
    await systemButton.focus();
    await page.keyboard.press("Enter");
    await expectTheme(page, "system", "dark");

    await page.emulateMedia({ colorScheme: "light" });
    await expectTheme(page, "system", "light");
    await page.emulateMedia({ colorScheme: "dark" });
    await expectTheme(page, "system", "dark");

    await page.reload();
    await waitForLiveConnected(page);
    await expectTheme(page, "system", "dark");

    const nextPath = entry.name === "mounted" ? "/admin/search/health" : "/ops/health";
    const origin = new URL(entry.url, process.env.PLAYWRIGHT_BASE_URL || "http://web:4002").origin;
    await page.goto(`${origin}${nextPath}`);
    await waitForLiveConnected(page);
    await expectTheme(page, "system", "dark");
  });

  test(`${entry.name} preference synchronizes between tabs and recovers from denied storage`, async ({ browser }) => {
    const context = await browser.newContext({ colorScheme: "dark" });
    const first = await context.newPage();
    await visitEntry(first, entry, "system");
    const second = await context.newPage();
    await second.goto(entry.url);
    await waitForLiveConnected(second);
    await expectTheme(second, "system", "dark");

    await first.getByRole("button", { name: "Use light theme" }).click();
    await expectTheme(second, "light", "light");
    await first.evaluate(() => window.localStorage.clear());
    await expectTheme(second, "system", "dark");
    await context.close();

    const unavailable = await makeStorageUnavailable(browser);
    try {
      await unavailable.page.emulateMedia({ colorScheme: "dark" });
      await visitEntry(unavailable.page, entry, "system", false);
      await expectTheme(unavailable.page, "system", "dark");
      await unavailable.page.getByRole("button", { name: "Use light theme" }).click();
      await expectTheme(unavailable.page, "light", "light");
      await unavailable.page.getByRole("button", { name: "Use system theme" }).click();
      await expectTheme(unavailable.page, "system", "dark");
    } finally {
      await unavailable.close();
    }
  });

  test(`${entry.name} theme remains usable when storage methods throw`, async ({ browser }) => {
    for (const method of ["getItem", "setItem", "removeItem"] as const) {
      const unavailable = await makeStorageMethodThrowing(browser, method);
      const pageErrors: string[] = [];
      unavailable.page.on("pageerror", (error) => pageErrors.push(error.message));

      try {
        await unavailable.page.emulateMedia({ colorScheme: "dark" });
        await unavailable.page.goto(entry.url);
        await waitForLiveConnected(unavailable.page);
        await expectTheme(unavailable.page, "system", "dark");

        await unavailable.page.getByRole("button", { name: "Use light theme" }).click();
        await expectTheme(unavailable.page, "light", "light");
        await unavailable.page.getByRole("button", { name: "Use system theme" }).click();
        await expectTheme(unavailable.page, "system", "dark");
        expect(pageErrors, `${entry.name} storage.${method} must not abort theme setup`).toEqual([]);
      } finally {
        await unavailable.close();
      }
    }
  });
}

test("mounted Ops applies the stored theme before its deferred host bundle runs", async ({ browser }) => {
  const context = await browser.newContext({ colorScheme: "light" });
  const page = await context.newPage();
  await page.addInitScript(() => {
    if (location.origin !== "null") window.localStorage.setItem("phx:theme", "dark");
  });

  let releaseBundle = () => {};
  const bundlePaused = new Promise<void>((resolve) => {
    releaseBundle = resolve;
  });
  await page.route("**/assets/js/app.js*", async (route) => {
    await bundlePaused;
    await route.continue();
  });

  try {
    const navigation = page.goto(entries[0].url);
    await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
    await expect
      .poll(() => page.locator(".ops-shell").evaluate((element) => getComputedStyle(element).backgroundColor))
      .toBe("rgb(17, 20, 25)");

    releaseBundle();
    await navigation;
    await waitForLiveConnected(page);
    await expectTheme(page, "dark", "dark");
  } finally {
    releaseBundle();
    await context.close();
  }
});

test("mounted and standalone fixture routes keep their shell usable through errors and long content", async ({ page, browser }) => {
  const entry = entries[0];
  await page.route("**/scrypath-wordmark*.svg", (route) => route.abort());
  await visitEntry(page, entry);
  await page.setViewportSize({ width: 390, height: 844 });
  const openNavigation = page.getByRole("button", { name: "Open navigation" });
  const drawer = page.getByRole("dialog", { name: "Scrypath navigation" });
  await openNavigation.click();
  await expect(openNavigation).toHaveAttribute("aria-expanded", "true");
  await expect(drawer).toHaveClass(/is-open/);
  await expect(drawer.locator("[data-ops-nav-panel]")).toBeInViewport();
  await expect(drawer.getByRole("link", { name: "Scrypath home" })).toBeVisible();
  await expectSourceRow(page, entry);

  const scenario = page.getByTestId("phase173-fixture-scenario");
  await scenario.selectOption("partial");
  await expect(page.getByTestId("posture-row")).toHaveCount(2);
  await expect(page.getByTestId("posture-row").filter({ hasText: "fetch error" })).toHaveCount(1);

  await scenario.selectOption("long");
  await expect(page.getByTestId("posture-row")).toHaveCount(2);

  const navLink = page.locator("[data-ops-nav-link]:visible").first();
  await expect(navLink).toBeVisible();
  await navLink.evaluate((element) => {
    element.textContent = "Search operations navigation label ".repeat(4).trim();
  });
  expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBeLessThanOrEqual(390);

  await page.keyboard.press("Escape");
  await expect(openNavigation).toHaveAttribute("aria-expanded", "false");
  await page.evaluate(() =>
    (window as Window & { liveSocket: { disconnect: () => void } }).liveSocket.disconnect()
  );
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-(?:disconnected|client-error)/, { timeout: 10_000 });
  await expect(page.getByRole("heading", { name: "Search health", exact: true })).toBeVisible();
  await expect(page.getByRole("button", { name: "Use system theme" })).toBeVisible();
  await page.evaluate(() => (window as Window & { liveSocket: { connect: () => void } }).liveSocket.connect());
  await waitForLiveConnected(page);

  const other = await browser.newPage({ colorScheme: "dark" });
  try {
    const standalone = entries[1];
    await visitEntry(other, standalone);
    await expectSourceRow(other, standalone);
    await other.setViewportSize({ width: 390, height: 844 });
    const openNavigation = other.getByRole("button", { name: "Open navigation" });
    const drawer = other.getByRole("dialog", { name: "Scrypath navigation" });
    await openNavigation.click();
    await expect(openNavigation).toHaveAttribute("aria-expanded", "true");
    await expect(drawer).toHaveClass(/is-open/);
    await expect(drawer.locator("[data-ops-nav-panel]")).toBeInViewport();
    await expect(drawer.getByRole("link", { name: "Scrypath home" })).toBeVisible();
  } finally {
    await other.close();
  }
});
