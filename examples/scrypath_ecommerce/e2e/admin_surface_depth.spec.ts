/**
 * Admin surface-depth binding gate (SCREEN-DARK-01, Phase 134).
 *
 * Computed-style assertions pin the dark/system-dark depth contract without relying on
 * screenshot thresholds: flat-token surfaces use exact RGB, alpha-mixed surfaces use
 * luminance/relative checks, and DK-13 records an objective row-border contrast trigger.
 *
 * HOW TO RUN (manual server per playwright.config.ts — there is NO webServer):
 *   Boot the ecommerce dev lane against current source, then:
 *     cd examples/scrypath_ecommerce
 *     npm run test:e2e:admin-depth
 */
import { expect, test, type APIRequestContext, type Browser, type Locator, type Page } from "@playwright/test";
import { Buffer } from "node:buffer";
import { mkdirSync } from "node:fs";
import { join } from "node:path";

import {
  deleteSavedSearches,
  drainSearchQueue,
  getSavedSearch,
  listSavedSearches,
  openManageSavedSearches,
  pickSavedSearch,
  putSavedSearch,
  saveCurrentSearch,
  savedSearchDomId,
  seedScenario,
  waitForSearchVisible,
  type SeedScenario
} from "./helpers/e2e";
import {
  assertSystemDarkInvariants,
  gotoControlRoom,
  gotoFailedSync,
  gotoSearchHealth,
  gotoSearch,
  SCENARIO_CAPTURES,
  THEME_MODES,
  themeSlug,
  VIEWPORT_NAMES,
  VIEWPORTS,
  type ThemeMode,
  type ViewportName
} from "./helpers/theme-grid";

const GLOW_RGB = "108, 92, 231";
const DARK_SURFACE_2_RGB = "rgb(34, 40, 49)";
const COPPER_RGB = "193, 122, 62";
const ELEVATION_DELTA_FLOOR = 0.0045;
const FLAT_SURFACE_DELTA_FLOOR = 0.011;
const DK13_ROW_BORDER_TRIGGER = 1.2;
// Saved search names are limited to 120 characters; this one is rejected on rename.
const TOO_LONG_NAME = "n".repeat(121);

const SAVED_SEARCH_VIEWPORTS = [
  { width: 1440, height: 900 },
  { width: 768, height: 900 },
  { width: 390, height: 844 }
];
const SAVED_SEARCH_THEMES: ThemeMode[] = [
  { kind: "explicit", theme: "light" },
  { kind: "explicit", theme: "dark" }
];

const DARK_THEME_MODES = THEME_MODES.filter(
  (mode) => (mode.kind === "explicit" && mode.theme === "dark") || mode.kind === "system"
);

type DepthTarget = {
  id: string;
  scenario: SeedScenario;
  captureIndex: string;
  selectors: string[];
  prepare?: (page: Page) => Promise<void>;
};

async function cleanupSurfaceDepthSavedSearches(request: APIRequestContext): Promise<void> {
  await deleteSavedSearches(request, { prefix: "surface-depth-" });
}

async function newThemedPage(
  browser: Browser,
  mode: ThemeMode,
  viewport: ViewportName | { width: number; height: number }
): Promise<{ page: Page; close: () => Promise<void> }> {
  const context = await browser.newContext({
    viewport: typeof viewport === "string" ? VIEWPORTS[viewport] : viewport,
    ...(mode.kind === "system" ? { colorScheme: mode.colorScheme as "dark" } : {})
  });

  if (mode.kind === "explicit") {
    await context.addInitScript(
      ([key, value]: [string, string]) => {
        window.localStorage.setItem(key, value);
      },
      ["phx:theme", mode.theme]
    );
  }

  const page = await context.newPage();
  return { page, close: () => context.close() };
}

async function readComputedStyle(
  page: Page,
  selector: string,
  property: "backgroundColor" | "borderColor" | "boxShadow" | "color"
): Promise<string> {
  return page.evaluate(
    ([sel, prop]) => {
      const el = document.querySelector(sel);
      if (!el) throw new Error(`surface-depth probe: element not found for ${sel}`);
      return getComputedStyle(el)[prop as "backgroundColor" | "borderColor" | "boxShadow" | "color"];
    },
    [selector, property] as const
  );
}

async function readLocatorComputedStyle(
  locator: Locator,
  property: "backgroundColor" | "borderColor" | "boxShadow" | "color"
): Promise<string> {
  return locator.evaluate((el, prop) => {
    return getComputedStyle(el)[prop as "backgroundColor" | "borderColor" | "boxShadow" | "color"];
  }, property);
}

async function resolveCssColor(
  page: Page,
  declaration: string,
  property: "backgroundColor" | "borderColor" = "borderColor"
): Promise<string> {
  return page.evaluate(([cssDeclaration, prop]) => {
    const el = document.createElement("div");
    el.style.cssText = `position:absolute; left:-9999px; ${cssDeclaration}`;
    document.body.appendChild(el);
    const style = getComputedStyle(el);
    const value = style[prop];
    el.remove();
    return value;
  }, [declaration, property] as const);
}

function rgbChannels(raw: string): [number, number, number] {
  const match = raw.match(/rgba?\(\s*([0-9.]+)[,\s]+([0-9.]+)[,\s]+([0-9.]+)/);
  if (!match) throw new Error(`Expected computed rgb/rgba color, got ${raw}`);
  return [Number(match[1]), Number(match[2]), Number(match[3])];
}

function alphaChannel(raw: string): number {
  const match = raw.match(/rgba?\(\s*[0-9.]+[,\s]+[0-9.]+[,\s]+[0-9.]+(?:[,\s/]+([0-9.]+%?))?\s*\)/);
  if (!match || !match[1]) return 1;
  return match[1].endsWith("%") ? Number(match[1].slice(0, -1)) / 100 : Number(match[1]);
}

function oklchToRgb(raw: string): [number, number, number, number] {
  const match = raw.match(/oklch\(\s*([0-9.]+%?)\s+([0-9.]+)\s+(none|[0-9.]+)(?:deg)?(?:\s*\/\s*([0-9.]+%?))?\s*\)/);
  if (!match) throw new Error(`Expected computed rgb/rgba/oklch color, got ${raw}`);

  const lightness = match[1].endsWith("%") ? Number(match[1].slice(0, -1)) / 100 : Number(match[1]);
  const chroma = Number(match[2]);
  const hue = (match[3] === "none" ? 0 : Number(match[3])) * Math.PI / 180;
  const alpha = match[4] ? (match[4].endsWith("%") ? Number(match[4].slice(0, -1)) / 100 : Number(match[4])) : 1;
  const a = chroma * Math.cos(hue);
  const b = chroma * Math.sin(hue);

  return oklabChannelsToRgb(lightness, a, b, alpha);
}

function oklabToRgb(raw: string): [number, number, number, number] {
  const match = raw.match(
    /oklab\(\s*([0-9.]+%?)\s+(-?[0-9.]+)\s+(-?[0-9.]+)(?:\s*\/\s*([0-9.]+%?))?\s*\)/
  );
  if (!match) throw new Error(`Expected computed oklab color, got ${raw}`);

  const lightness = match[1].endsWith("%")
    ? Number(match[1].slice(0, -1)) / 100
    : Number(match[1]);
  const a = Number(match[2]);
  const b = Number(match[3]);
  const alpha = match[4]
    ? match[4].endsWith("%")
      ? Number(match[4].slice(0, -1)) / 100
      : Number(match[4])
    : 1;

  return oklabChannelsToRgb(lightness, a, b, alpha);
}

function oklabChannelsToRgb(
  lightness: number,
  a: number,
  b: number,
  alpha: number
): [number, number, number, number] {
  const lPrime = lightness + 0.3963377774 * a + 0.2158037573 * b;
  const mPrime = lightness - 0.1055613458 * a - 0.0638541728 * b;
  const sPrime = lightness - 0.0894841775 * a - 1.291485548 * b;
  const l = lPrime ** 3;
  const m = mPrime ** 3;
  const s = sPrime ** 3;

  const linear = [
    4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
    -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
    -0.0041960863 * l - 0.7034186147 * m + 1.707614701 * s
  ];

  const srgb = linear.map((channel) => {
    const clamped = Math.min(1, Math.max(0, channel));
    return clamped <= 0.0031308 ? 12.92 * clamped : 1.055 * (clamped ** (1 / 2.4)) - 0.055;
  });

  return [srgb[0] * 255, srgb[1] * 255, srgb[2] * 255, alpha];
}

function colorRgbaChannels(raw: string): [number, number, number, number] {
  const trimmed = raw.trim();

  if (trimmed.startsWith("oklch(")) return oklchToRgb(trimmed);
  if (trimmed.startsWith("oklab(")) return oklabToRgb(trimmed);

  return [...rgbChannels(trimmed), alphaChannel(trimmed)];
}

function colorsEquivalent(actual: string, expected: string): boolean {
  const actualChannels = colorRgbaChannels(actual);
  const expectedChannels = colorRgbaChannels(expected);

  return actualChannels.every((channel, index) =>
    Math.abs(channel - expectedChannels[index]) <= (index === 3 ? 0.005 : 1)
  );
}

function colorChannels(raw: string, backdrop?: string): [number, number, number] {
  const [r, g, b, alpha] = colorRgbaChannels(raw);

  if (alpha >= 1 || !backdrop) return [r, g, b];

  const [br, bg, bb] = colorChannels(backdrop);
  return [
    r * alpha + br * (1 - alpha),
    g * alpha + bg * (1 - alpha),
    b * alpha + bb * (1 - alpha)
  ];
}

function relativeLuminance(raw: string, backdrop?: string): number {
  const [r, g, b] = colorChannels(raw, backdrop).map((channel) => {
    const s = channel / 255;
    return s <= 0.03928 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
  });
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

function contrastRatio(a: string, b: string): number {
  const l1 = relativeLuminance(a, b);
  const l2 = relativeLuminance(b);
  const lighter = Math.max(l1, l2);
  const darker = Math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

async function darkBgFloor(page: Page): Promise<string> {
  return resolveCssColor(page, "background: var(--ops-bg)", "backgroundColor");
}

async function darkSurface2(page: Page): Promise<string> {
  return resolveCssColor(page, "background: var(--ops-surface-2)", "backgroundColor");
}

async function expectRaisedAboveFloor(page: Page, selector: string, label: string): Promise<void> {
  const floor = await darkBgFloor(page);
  const bg = await readComputedStyle(page, selector, "backgroundColor");
  expect(
    relativeLuminance(bg, floor) - relativeLuminance(floor),
    `${label} luminance must exceed --ops-bg floor by >= ${ELEVATION_DELTA_FLOOR}`
  ).toBeGreaterThanOrEqual(ELEVATION_DELTA_FLOOR);
}

async function expectFlatSurface2(page: Page, selector: string, label: string): Promise<void> {
  const floor = await darkBgFloor(page);
  const surface2 = await darkSurface2(page);
  const bg = await readComputedStyle(page, selector, "backgroundColor");
  expect(bg, `${label} uses the dark surface-2 token`).toBe(surface2);
  expect(
    relativeLuminance(bg, floor) - relativeLuminance(floor),
    `${label} luminance must exceed --ops-bg floor by >= ${FLAT_SURFACE_DELTA_FLOOR}`
  ).toBeGreaterThanOrEqual(FLAT_SURFACE_DELTA_FLOOR);
}

async function expectPrimaryHover55(page: Page, selector: string, label: string): Promise<void> {
  const target = page.locator(selector).first();
  await expect(target).toBeVisible();
  const resting = await readLocatorComputedStyle(target, "borderColor");
  await target.hover();
  await page.waitForTimeout(400);
  const hover = await readLocatorComputedStyle(target, "borderColor");
  const expected = await resolveCssColor(
    page,
    "border-color: color-mix(in oklch, var(--color-primary) 55%, transparent)"
  );

  expect(hover, `${label} hover border must resolve to primary 55%`).toBe(expected);
  if (resting !== expected) {
    expect(hover, `${label} hover border must differ from resting`).not.toBe(resting);
  }
}

async function expectNoStatusCopper(page: Page): Promise<void> {
  const copperBorder = await resolveCssColor(
    page,
    "border-color: color-mix(in oklch, var(--color-secondary) 44%, transparent)"
  );
  const copperBg = await resolveCssColor(
    page,
    "background: color-mix(in oklch, var(--color-secondary) 12%, transparent)",
    "backgroundColor"
  );
  const candidates = await page.evaluate(() => {
    const statusClassPattern =
      /\b(ops-tone-|ops-badge-(success|warning|error|partial|running|info|neutral)|ops-metric-)/;

    return Array.from(document.querySelectorAll<HTMLElement>("[class]"))
      .filter(
        (el) =>
          statusClassPattern.test(el.className) && !el.classList.contains("ops-copper-badge")
      )
      .map((el) => {
        const style = getComputedStyle(el);
        return {
          className: el.className,
          borderColor: style.borderColor,
          backgroundColor: style.backgroundColor
        };
      });
  });

  const matches = candidates
    .filter(
      (candidate) =>
        colorsEquivalent(candidate.borderColor, copperBorder) ||
        colorsEquivalent(candidate.backgroundColor, copperBg)
    )
    .map((candidate) => candidate.className);

  expect(matches, "status tone/badge classes must never compute to copper").toEqual([]);
}

async function expectSearchHealthSignalCardsMeasured(page: Page): Promise<void> {
  const card = ".ops-schema-signal-card";
  await expect(page.locator(card).first()).toBeVisible();

  const bg = await readComputedStyle(page, card, "backgroundColor");
  const shadow = await readComputedStyle(page, card, "boxShadow");
  expect(bg, "search health signal cards use the dark surface-2 depth token").toBe(DARK_SURFACE_2_RGB);
  expect(shadow, "search health signal cards must keep seated dark-panel depth").not.toBe("none");

  const signalGroup = ".ops-signal-group";
  await expect(page.locator(signalGroup).first()).toBeVisible();
  const groups = await page.locator(signalGroup).evaluateAll((elements) =>
    elements.map((element) => {
      const style = getComputedStyle(element);
      return {
        background: style.backgroundColor,
        shadow: style.boxShadow,
        borderedSides: [style.borderTopWidth, style.borderRightWidth,
          style.borderBottomWidth, style.borderLeftWidth]
          .filter((width) => parseFloat(width) > 0).length
      };
    })
  );
  for (const group of groups) {
    expect(group.background, "diagnostic groups share their schema surface").toBe("rgba(0, 0, 0, 0)");
    expect(group.shadow, "diagnostic groups do not add another elevated card").toBe("none");
    expect(group.borderedSides, "a group can have a divider, never a surrounding box").toBeLessThanOrEqual(1);
  }

  await expect(page.locator(".ops-signal-success dd").first()).toBeVisible();
}

async function expectSearchDocumentToFit(page: Page): Promise<void> {
  const widths = await page.evaluate(() => ({
    viewport: document.documentElement.clientWidth,
    document: document.documentElement.scrollWidth,
    body: document.body.scrollWidth
  }));
  expect(
    Math.max(widths.document, widths.body),
    `document width ${widths.document}px and body width ${widths.body}px must fit ${widths.viewport}px viewport`
  ).toBeLessThanOrEqual(widths.viewport);
}

async function expectSavedSearchDocumentToFit(page: Page): Promise<void> {
  const widths = await page.evaluate(() => ({
    viewport: document.documentElement.clientWidth,
    document: document.documentElement.scrollWidth,
    body: document.body.scrollWidth
  }));
  expect(
    Math.max(widths.document, widths.body),
    `Saved searches document width ${widths.document}px and body width ${widths.body}px must fit ${widths.viewport}px viewport`
  ).toBeLessThanOrEqual(widths.viewport);
}

// Saves the current Search inputs, then opens the toolbar's Saved searches menu.
async function preparePopulatedSavedSearches(page: Page): Promise<void> {
  await gotoSearch(page);
  const query = page.getByLabel("Search text");
  await query.fill("quantum");
  await expect(page.getByRole("button", { name: "Run search" })).toHaveCount(1);
  await query.press("Enter");
  await expect(page.getByRole("heading", { name: "Results", exact: true })).toBeVisible();
  const submitted = page.locator("#search-run-attribution");
  await expect(submitted).toHaveAttribute("data-mode", "single");
  await expect(submitted).toHaveAttribute("data-schemas", JSON.stringify(["ScrypathEcommerce.Catalog.Product"]));
  await expect(submitted).toHaveAttribute("data-limit", "15");
  await expect(page.locator(".ops-readable-hit").first()).toBeVisible();

  await saveCurrentSearch(page, `surface-depth-${Date.now()}`);
  await page.locator("#saved-search-picker-button").click();
  await expect(page.locator("#saved-search-menu .ops-saved-search-menu__item").first()).toBeVisible();
}

async function seedAndMaybeConfirmSearch(request: APIRequestContext, scenario: SeedScenario) {
  const seed = await seedScenario(request, scenario);
  if (scenario === "all_green" && seed.tenant_id) {
    await drainSearchQueue(request);
    await waitForSearchVisible(request, {
      tenantId: seed.tenant_id,
      query: "quantum",
      expectedName: "Quantum CyberPhone X"
    });
  }
}

function captureByIndex(scenario: SeedScenario, index: string) {
  const capture = SCENARIO_CAPTURES[scenario].find((candidate) => candidate.index === index);
  if (!capture) throw new Error(`surface-depth capture ${scenario}/${index} is not shared`);
  return capture;
}

const DEPTH_TARGETS: DepthTarget[] = [
  {
    id: "search-results",
    scenario: "all_green",
    captureIndex: "06",
    selectors: [".ops-readable-hit"]
  },
  {
    id: "search-zero-results",
    scenario: "empty",
    captureIndex: "08",
    selectors: [".ops-empty-hero"]
  },
  {
    id: "control-room-intents",
    scenario: "incident",
    captureIndex: "00",
    selectors: [".ops-verdict--hero", '[data-testid="control-room-secondary-intents"]'],
    prepare: gotoControlRoom
  },
  {
    id: "search-health-signal-cards",
    scenario: "incident",
    captureIndex: "01",
    selectors: [".ops-schema-signal-card", ".ops-signal-group", ".ops-signal-success"],
    prepare: gotoSearchHealth
  },
  {
    id: "failed-sync-notice",
    scenario: "incident",
    captureIndex: "02",
    selectors: [".ops-verdict"],
    prepare: gotoFailedSync
  },
  {
    id: "sync-drift",
    scenario: "incident",
    captureIndex: "03",
    selectors: [".ops-panel", "#sync-pipeline-status"]
  },
  {
    id: "saved-searches-manage-sheet",
    scenario: "empty",
    captureIndex: "09",
    selectors: [".ops-sheet__panel"]
  },
  {
    id: "saved-searches-menu",
    scenario: "all_green",
    captureIndex: "12",
    selectors: [".ops-saved-search-menu"],
    prepare: preparePopulatedSavedSearches
  }
];

test.use({ actionTimeout: 10_000 });

test.describe("admin surface depth — SCREEN-DARK-01", () => {
  test.describe.configure({ timeout: 120_000 });
  test.beforeEach(async ({ request }) => cleanupSurfaceDepthSavedSearches(request));
  test.afterEach(async ({ request }) => cleanupSurfaceDepthSavedSearches(request));

  for (const target of DEPTH_TARGETS) {
    for (const mode of DARK_THEME_MODES) {
      for (const viewport of VIEWPORT_NAMES) {
        test(`${target.id} skeleton (${themeSlug(mode)}, ${viewport})`, async ({ browser, request }) => {
          await seedAndMaybeConfirmSearch(request, target.scenario);

          const { page, close } = await newThemedPage(browser, mode, viewport);
          try {
            if (target.prepare) {
              await target.prepare(page);
            } else {
              await captureByIndex(target.scenario, target.captureIndex).prepare(page);
            }

            if (mode.kind === "system") {
              await assertSystemDarkInvariants(page);
            }

            for (const selector of target.selectors) {
              await expect(page.locator(selector).first()).toBeVisible();
            }

            switch (target.id) {
              case "search-results":
                await expect(page.locator(".ops-search-hit").first()).toHaveCSS("background-color", "rgba(0, 0, 0, 0)");
                await expect(page.locator(".ops-search-hit").first()).toHaveCSS("box-shadow", "none");
                break;
              case "search-zero-results":
                await expectRaisedAboveFloor(page, ".ops-empty-hero", "search zero-results empty state");
                break;
              case "control-room-intents":
                await expect(page.getByTestId("control-room-verify-change")).toBeVisible();
                await expect(page.getByTestId("control-room-explore-search")).toBeVisible();
                await expectNoStatusCopper(page);
                {
                  const heroShadow = await readComputedStyle(page, ".ops-verdict--hero", "boxShadow");
                  expect(heroShadow, "control-room verdict hero should use a dark raised shadow, not no shadow").not.toBe("none");
                  expect(heroShadow, "control-room verdict hero should not carry a copper warm halo").not.toContain(COPPER_RGB);
                }
                break;
              case "search-health-signal-cards": {
                await expectSearchHealthSignalCardsMeasured(page);
                break;
              }
              case "failed-sync-notice":
                await expectRaisedAboveFloor(page, ".ops-verdict", "failed-sync verdict surface");
                break;
              case "sync-drift": {
                await expectRaisedAboveFloor(page, ".ops-panel", "sync-drift section panel");
                // Without a prepared index, Reindexing is one quiet line and no promotion controls.
                await expect(page.locator("#index-promotion")).toHaveCount(0);
                await expect(page.locator("#reindex-idle")).toContainText("No reindex in progress.");
                await expectRaisedAboveFloor(page, "#sync-pipeline-status", "sync status notice");
                break;
              }
              case "saved-searches-manage-sheet":
                await expectRaisedAboveFloor(page, ".ops-sheet__panel", "manage saved searches sheet");
                break;
              case "saved-searches-menu":
                await expectRaisedAboveFloor(page, ".ops-saved-search-menu", "saved searches menu");
                break;
            }
          } finally {
            await close();
          }
        });
      }
    }
  }

  test("Search attribution and layout hold before and after submit across themes and widths", async ({
    browser,
    request
  }) => {
    await seedAndMaybeConfirmSearch(request, "all_green");

    const evidenceDir = process.env.PHASE176_VISUAL_EVIDENCE_DIR;
    if (evidenceDir) mkdirSync(evidenceDir, { recursive: true });

    const viewports = [
      { width: 1440, height: 900 },
      { width: 390, height: 844 },
      { width: 768, height: 900 }
    ];
    const themes: ThemeMode[] = [
      { kind: "explicit", theme: "light" },
      { kind: "explicit", theme: "dark" }
    ];

    for (const mode of themes) {
      for (const viewport of viewports) {
        const { page, close } = await newThemedPage(browser, mode, viewport);
        const captureName = `search-${themeSlug(mode)}-${viewport.width}`;

        try {
          await gotoSearch(page);
          await expectSearchDocumentToFit(page);

          if (evidenceDir) {
            await page.screenshot({
              path: join(evidenceDir, `${captureName}-before.png`),
              fullPage: true
            });
          }

          const query = page.getByLabel("Search text");
          await query.fill("quantum");
          await expect(page.getByRole("button", { name: "Run search" })).toHaveCount(1);
          await query.press("Enter");
          await expect(page.locator("#search-results-heading")).toBeVisible();
          await expect(page.locator(".ops-readable-hit").first()).toBeVisible();
          const submitted = page.locator("#search-run-attribution");
          await expect(submitted).toHaveAttribute("data-mode", "single");
          await expect(submitted).toHaveAttribute("data-schemas", JSON.stringify(["ScrypathEcommerce.Catalog.Product"]));
          await expect(page.locator("#search-run-attribution")).toHaveAttribute("data-query", "quantum");

          await query.fill("a later query edit");
          await expect(page.locator("#search-run-attribution")).toHaveAttribute("data-query", "quantum");
          await expectSearchDocumentToFit(page);
          await query.blur();
          await page.evaluate(() => window.scrollTo(0, 0));

          if (evidenceDir) {
            await page.screenshot({
              path: join(evidenceDir, `${captureName}-after.png`),
              fullPage: true
            });
          }
        } finally {
          await close();
        }
      }
    }
  });

  test("zero-hit Search save rejects collisions, saves criteria and reflows across themes and widths", async ({
    browser,
    request
  }) => {
    await seedAndMaybeConfirmSearch(request, "all_green");

    const evidenceDir = process.env.PHASE176_VISUAL_EVIDENCE_DIR;
    if (evidenceDir) mkdirSync(evidenceDir, { recursive: true });

    for (const mode of SAVED_SEARCH_THEMES) {
      for (const viewport of SAVED_SEARCH_VIEWPORTS) {
        const { page, close } = await newThemedPage(browser, mode, viewport);
        const captureName = `search-save-${themeSlug(mode)}-${viewport.width}`;

        try {
          await gotoSearch(page);
          const query = `phase176-no-hit-${Date.now()}-${viewport.width}`;
          const queryInput = page.getByLabel("Search text");
          await page.getByLabel("Results per page", { exact: true }).fill("10");
          await queryInput.fill(query);
          await queryInput.press("Enter");
          await expect(page.locator("#search-results-heading")).toBeVisible();
          await expect(page.getByText("No matching documents", { exact: true })).toBeVisible();
          await page.locator("#search-save-new").click();

          const dialog = page.getByRole("dialog", { name: "Save search" });
          const name = dialog.getByLabel("Name", { exact: true });
          await expect(dialog).toBeVisible();
          await expect(name).toBeFocused();
          await expect(dialog.getByText("Names are unique.", { exact: false })).toBeVisible();
          await expectSearchDocumentToFit(page);

          if (evidenceDir) {
            await page.screenshot({ path: join(evidenceDir, `${captureName}-dialog.png`), fullPage: true });
          }

          const occupied = (await listSavedSearches(request)).find(
            (row) => !row.name.startsWith("surface-depth-")
          );
          expect(occupied, "the seeded E2E demo should include an example saved search").toBeTruthy();
          const occupiedName = occupied!.name;

          await name.fill(occupiedName);
          await dialog.getByRole("button", { name: "Save", exact: true }).click();

          const error = page.locator("#saved-search-name-input-error");
          await expect(error).toContainText("already exists. Choose another name.");
          await expect(name).toHaveValue(occupiedName);
          await expect(name).toHaveAttribute("aria-invalid", "true");
          await expect(name).toHaveAttribute(
            "aria-describedby",
            /saved-search-name-input-hint.*saved-search-name-input-error/
          );
          await expect(name).toBeFocused();
          await expect(error).toHaveCSS("font-size", "14px");
          await expectSearchDocumentToFit(page);
          expect((await getSavedSearch(request, occupiedName))?.definition).toEqual(occupied!.definition);

          if (evidenceDir) {
            await page.screenshot({ path: join(evidenceDir, `${captureName}-collision.png`), fullPage: true });
          }

          const savedName = `surface-depth-save-${themeSlug(mode)}-${viewport.width}-${Date.now()}`;
          await name.fill(savedName);
          await dialog.getByRole("button", { name: "Save", exact: true }).click();
          await expect(dialog).toBeHidden();
          await expect(page.getByText(`Saved “${savedName}”.`, { exact: true })).toBeVisible();
          await expect(page.locator("#saved-search-status")).toContainText(`Loaded “${savedName}”`);

          const saved = (await getSavedSearch(request, savedName))!.definition as any;
          expect(saved.mode).toBe("search");
          expect(saved.schema).toBe("ScrypathEcommerce.Catalog.Product");
          expect(saved.q).toBe(query);
          expect(saved.opts.page.size).toBe(10);
          expect(JSON.stringify(saved)).not.toContain("hits");
          expect(JSON.stringify(saved)).not.toContain("result");

          const sheet = await openManageSavedSearches(page);
          await expect(sheet.locator(".ops-saved-search-row").filter({ hasText: savedName })).toBeVisible();
          await expectSearchDocumentToFit(page);
        } finally {
          await close();
        }
      }
    }
  });

  test("Saved searches load from the toolbar and keep loaded and edited states clear across themes and widths", async ({
    browser,
    request
  }) => {
    test.setTimeout(120_000);
    await seedAndMaybeConfirmSearch(request, "all_green");

    const evidenceDir = process.env.PHASE176_VISUAL_EVIDENCE_DIR;
    if (evidenceDir) mkdirSync(evidenceDir, { recursive: true });

    for (const mode of SAVED_SEARCH_THEMES) {
      for (const viewport of SAVED_SEARCH_VIEWPORTS) {
        const savedName = `surface-depth-load-${"long saved search name ".repeat(3)}${themeSlug(mode)}-${viewport.width}`;
        await putSavedSearch(request, savedName, {
          playbook_format: 1,
          mode: "search",
          schema: "ScrypathEcommerce.Catalog.Product",
          q: "quantum",
          opts: { page: { size: 12 } },
          description: `A wrapped description ${"for responsive coverage ".repeat(6)}`
        });

        const { page, close } = await newThemedPage(browser, mode, viewport);
        const captureName = `saved-searches-load-${themeSlug(mode)}-${viewport.width}`;

        try {
          await gotoSearch(page);
          await page.locator("#saved-search-picker-button").click();
          await expect(page.locator("#saved-search-picker-button")).toHaveAttribute("aria-expanded", "true");
          const menu = page.locator("#saved-search-menu");
          await expect(menu).toBeVisible();
          const menuBox = (await menu.boundingBox())!;
          expect(menuBox.x + menuBox.width, "the menu stays inside the viewport").toBeLessThanOrEqual(viewport.width);
          await expectSavedSearchDocumentToFit(page);
          if (evidenceDir) {
            await page.screenshot({ path: join(evidenceDir, `${captureName}-menu.png`), fullPage: true });
          }
          await page.keyboard.press("Escape");
          await expect(menu).toBeHidden();
          await expect(page.locator("#saved-search-picker-button")).toHaveAttribute("aria-expanded", "false");

          await pickSavedSearch(page, savedName);
          await expect(page.locator("#search_q")).toHaveValue("quantum");
          await expect(page.locator("#search_page_size")).toHaveValue("12");
          const submitted = page.locator("#search-run-attribution");
          await expect(submitted).toHaveAttribute("data-query", "quantum");
          await expect(submitted).toHaveAttribute("data-limit", "12");
          await expect(page.locator(".ops-readable-hit").first()).toBeVisible();
          await expect(page.locator("#search-save-loaded")).toHaveCount(0);
          await expectSavedSearchDocumentToFit(page);

          await page.getByLabel("Search text").fill("an edited draft");
          await expect(page.locator("#saved-search-status")).toContainText("edited");
          await expect(submitted).toBeVisible();
          await expect(submitted).toContainText("quantum");
          await expect(page.locator("#search-save-loaded")).toBeVisible();
          await expect(page.locator("#search-save-as")).toBeVisible();
          await expectSavedSearchDocumentToFit(page);

          await page.locator("#saved-search-manage-open").click();
          const sheet = page.getByRole("dialog", { name: "Manage saved searches" });
          await expect(sheet).toBeVisible();
          const loaded = sheet.locator(".ops-saved-search-row--loaded");
          await expect(loaded).toHaveCount(1);
          await expect(loaded).toContainText(savedName);
          const panel = (await sheet.locator(".ops-sheet__panel").boundingBox())!;
          expect(panel.x + panel.width, "the sheet stays inside the viewport").toBeLessThanOrEqual(viewport.width + 1);
          if (viewport.width < 640) {
            expect(panel.width, "the sheet spans narrow screens").toBeGreaterThanOrEqual(viewport.width - 1);
          }
          await expectSavedSearchDocumentToFit(page);
          if (evidenceDir) {
            await page.screenshot({ path: join(evidenceDir, `${captureName}-sheet.png`), fullPage: true });
          }
          await page.keyboard.press("Escape");
          await expect(sheet).toBeHidden();
          await expect(page.locator("#saved-search-manage-open")).toBeFocused();
        } finally {
          await close();
          await deleteSavedSearches(request, { names: [savedName] });
        }
      }
    }
  });

  test("Manage saved searches imports files directly and keeps paste errors in place", async ({
    browser,
    request
  }) => {
    await seedAndMaybeConfirmSearch(request, "all_green");

    for (const mode of SAVED_SEARCH_THEMES) {
      for (const viewport of SAVED_SEARCH_VIEWPORTS) {
        const { page, close } = await newThemedPage(browser, mode, viewport);
        const uploadedName = `surface-depth-uploaded-${"long-saved-search-name-".repeat(3)}${themeSlug(mode)}-${viewport.width}`;
        const uploadedQuery = `uploaded query ${"wrapped criteria ".repeat(8)}${viewport.width}`;

        try {
          const sheet = await openManageSavedSearches(page);
          const uploadInput = sheet.locator("input[type='file']");
          const uploadBindings = await uploadInput.evaluate((input: HTMLInputElement) => ({
            uploadRef: input.getAttribute("data-phx-upload-ref"),
            changeEvent: input.form?.getAttribute("phx-change")
          }));
          expect(uploadBindings.uploadRef).toBeTruthy();
          expect(uploadBindings.changeEvent).toBe("validate_import");
          await expect(sheet.getByRole("button", { name: "Import JSON file" })).toBeVisible();

          // Choosing a file imports it; there is no separate submit step.
          await uploadInput.setInputFiles({
            name: `${uploadedName}.json`,
            mimeType: "application/json",
            buffer: Buffer.from(
              JSON.stringify({
                playbook_format: 1,
                mode: "search",
                schema: "ScrypathEcommerce.Catalog.Product",
                q: uploadedQuery,
                opts: { page: { size: 10 } }
              })
            )
          });
          const row = sheet.locator(".ops-saved-search-row").filter({ hasText: uploadedName });
          await expect(row).toBeVisible();
          await expect(row.getByRole("button", { name: `Load ${uploadedName}` })).toBeFocused();
          expect(((await getSavedSearch(request, uploadedName))!.definition as any).q).toBe(uploadedQuery);
          await expectSavedSearchDocumentToFit(page);

          await uploadInput.setInputFiles({
            name: "surface-depth-broken.json",
            mimeType: "application/json",
            buffer: Buffer.from("{not json")
          });
          await expect(sheet.locator("#saved-search-import-error")).toContainText("isn't valid JSON");

          await sheet.getByText("Paste JSON instead", { exact: true }).click();
          const longInvalidJson = `{"q":"${"long input ".repeat(500)}"`;
          const paste = sheet.locator("#saved-search-paste-json");
          await paste.fill(longInvalidJson);
          await paste.blur();
          await expect(sheet.locator("#saved-search-paste-json-error")).toContainText("Check the JSON syntax");
          await expect(paste).toHaveAttribute("aria-invalid", "true");
          await expect(paste).toHaveValue(longInvalidJson);
          await expectSavedSearchDocumentToFit(page);
        } finally {
          await close();
          await deleteSavedSearches(request, { names: [uploadedName] });
        }
      }
    }
  });

  test("Saved search management keeps focus on visible names through LiveView patches", async ({
    browser,
    request
  }) => {
    await seedAndMaybeConfirmSearch(request, "all_green");
    const first = `surface-depth-focus-a-${"wrapping-name-".repeat(4)}${Date.now()}`;
    const second = `surface-depth-focus-b-${Date.now()}`;
    await putSavedSearch(request, first, { playbook_format: 1, mode: "search", schema: "ScrypathEcommerce.Catalog.Product", q: "a", opts: {} });
    await putSavedSearch(request, second, { playbook_format: 1, mode: "search", schema: "ScrypathEcommerce.Catalog.Product", q: "b", opts: {} });

    const { page, close } = await newThemedPage(browser, { kind: "explicit", theme: "dark" }, "mobile");
    try {
      const sheet = await openManageSavedSearches(page);
      const firstRow = sheet.locator(`#saved-search-row-${savedSearchDomId(first)}`);
      await expect(firstRow.locator(".ops-saved-search-row__name")).toHaveText(first);
      await expectSavedSearchDocumentToFit(page);

      await firstRow.getByRole("button", { name: `Rename ${first}` }).click();
      const input = sheet.locator("#saved-search-rename-input");
      await expect(input).toBeFocused();
      await input.fill(TOO_LONG_NAME);
      await sheet.getByRole("button", { name: "Rename", exact: true }).click();
      await expect(sheet.locator("#saved-search-rename-input-error")).toContainText("Enter a name of up to 120 characters.");
      await expect(input).toBeFocused();
      await input.fill(second);
      await sheet.getByRole("button", { name: "Rename", exact: true }).click();
      await expect(sheet.locator("#saved-search-rename-input-error")).toContainText("already exists");
      await expect(input).toBeFocused();
      await page.keyboard.press("Escape");
      await expect(firstRow.getByRole("button", { name: `Rename ${first}` })).toBeFocused();

      await firstRow.getByRole("button", { name: `Delete ${first}` }).click();
      await sheet.locator("#saved-search-delete-input").fill(first);
      await sheet.getByRole("button", { name: "Delete", exact: true }).click();
      await expect(firstRow).toHaveCount(0);
      await expect.poll(() => sheet.evaluate((el) => el.contains(document.activeElement))).toBe(true);
      expect(await getSavedSearch(request, first)).toBeUndefined();
      expect(await getSavedSearch(request, second)).toBeTruthy();
    } finally {
      await close();
      await deleteSavedSearches(request, { names: [first, second] });
    }
  });

  test("Loaded saved search marker has no violet glow in light", async ({ browser, request }) => {
    await seedAndMaybeConfirmSearch(request, "all_green");
    const { page, close } = await newThemedPage(browser, { kind: "explicit", theme: "light" }, "desktop");
    try {
      await preparePopulatedSavedSearches(page);
      await page.keyboard.press("Escape");
      await page.locator("#saved-search-manage-open").click();
      const glow = await readComputedStyle(page, ".ops-saved-search-row--loaded", "boxShadow");
      expect(glow, "light loaded saved search row must not carry the dark violet glow").not.toContain(GLOW_RGB);
    } finally {
      await close();
    }
  });
});
