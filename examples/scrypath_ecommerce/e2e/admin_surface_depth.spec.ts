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
import { mkdirSync, readFileSync, readdirSync, unlinkSync, writeFileSync } from "node:fs";
import { join } from "node:path";

import {
  drainSearchQueue,
  seedScenario,
  waitForSearchVisible,
  type SeedScenario
} from "./helpers/e2e";
import {
  assertSystemDarkInvariants,
  gotoControlRoom,
  gotoFailedSync,
  gotoPlaybooks,
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
const COPPER_RGB = "193, 122, 62";
const ELEVATION_DELTA_FLOOR = 0.0045;
const FLAT_SURFACE_DELTA_FLOOR = 0.011;
const DK13_ROW_BORDER_TRIGGER = 1.2;
const PLAYBOOK_WORKSPACE_DIR = join(process.cwd(), "priv/playbooks");

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

function cleanupSurfaceDepthPlaybooks(): void {
  for (const name of readdirSync(PLAYBOOK_WORKSPACE_DIR)) {
    if (name.startsWith("surface-depth-") && name.endsWith(".json")) {
      unlinkSync(join(PLAYBOOK_WORKSPACE_DIR, name));
    }
  }
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

  const surface2 = await darkSurface2(page);
  const bg = await readComputedStyle(page, card, "backgroundColor");
  const shadow = await readComputedStyle(page, card, "boxShadow");
  expect(bg, "search health signal cards use the dark surface-2 depth token").toBe(surface2);
  expect(shadow, "search health signal cards must keep seated dark-panel depth").not.toBe("none");

  const signalGroup = ".ops-signal-group";
  await expect(page.locator(signalGroup).first()).toBeVisible();
  const border = await readComputedStyle(page, signalGroup, "borderColor");
  const ratio = contrastRatio(border, surface2);
  console.info(`search health signal-group border contrast ratio: ${ratio.toFixed(3)}:1`);
  expect(
    ratio,
    `search health signal-group border ratio must stay at or above ${DK13_ROW_BORDER_TRIGGER}:1`
  ).toBeGreaterThanOrEqual(DK13_ROW_BORDER_TRIGGER);

  await expect(page.locator(".ops-signal-metrics dd").first()).toBeVisible();
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

async function expectPlaybookDocumentToFit(page: Page): Promise<void> {
  const widths = await page.evaluate(() => ({
    viewport: document.documentElement.clientWidth,
    document: document.documentElement.scrollWidth,
    body: document.body.scrollWidth
  }));
  expect(
    Math.max(widths.document, widths.body),
    `Playbooks document width ${widths.document}px and body width ${widths.body}px must fit ${widths.viewport}px viewport`
  ).toBeLessThanOrEqual(widths.viewport);
}

function playbookDomId(name: string): string {
  return Buffer.from(name).toString("base64url");
}

async function preparePopulatedPlaybooks(page: Page): Promise<void> {
  await gotoSearch(page);
  const query = page.getByLabel("Search text");
  await query.fill("quantum");
  await expect(page.getByRole("button", { name: "Run search" })).toHaveCount(1);
  await query.press("Enter");
  await expect(page.getByRole("heading", { name: "Results", exact: true })).toBeVisible();
  const submitted = page.locator("#search-run-attribution");
  await expect(submitted).toContainText("Single index");
  await expect(submitted).toContainText("ScrypathEcommerce.Catalog.Product");
  await expect(submitted).toContainText("quantum");
  await expect(submitted).toContainText("Page size");
  await expect(page.getByTestId("search-outcome")).toContainText("Search completed");
  await expect(page.locator(".ops-result-row").first()).toBeVisible();
  await expect(page.getByRole("button", { name: "Run current search" })).toHaveCount(0);

  await query.fill("a later query edit");
  await expect(submitted).toContainText("quantum");
  await expect(page.getByTestId("search-submitted-query")).toHaveText("quantum");

  const basename = `surface-depth-${Date.now()}.json`;
  await page.getByRole("button", { name: "Save as playbook" }).click();
  await page.getByLabel("Filename").fill(basename);
  await page.getByRole("button", { name: "Save playbook" }).click();
  await expect(page.getByText(new RegExp(`Saved playbook ${basename.replace(".", "\\.")}`))).toBeVisible();

  await gotoPlaybooks(page);
  await expect(page.locator(".ops-object-item").first()).toBeVisible();
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
    selectors: [".ops-result-row"]
  },
  {
    id: "search-zero-results",
    scenario: "empty",
    captureIndex: "08",
    selectors: [".ops-muted-panel"]
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
    selectors: [".ops-schema-signal-card", ".ops-signal-group", ".ops-signal-metrics"],
    prepare: gotoSearchHealth
  },
  {
    id: "failed-sync-notice",
    scenario: "incident",
    captureIndex: "02",
    selectors: [".ops-notice-surface"],
    prepare: gotoFailedSync
  },
  {
    id: "sync-drift",
    scenario: "incident",
    captureIndex: "03",
    selectors: [".ops-panel", "#index-promotion"]
  },
  {
    id: "playbooks-workspace",
    scenario: "empty",
    captureIndex: "09",
    selectors: [".ops-object-item"]
  },
  {
    id: "playbooks-populated",
    scenario: "all_green",
    captureIndex: "12",
    selectors: [".ops-object-item"],
    prepare: preparePopulatedPlaybooks
  }
];

test.describe("admin surface depth — SCREEN-DARK-01", () => {
  test.describe.configure({ timeout: 120_000 });
  test.beforeEach(() => cleanupSurfaceDepthPlaybooks());
  test.afterEach(() => cleanupSurfaceDepthPlaybooks());

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
                await expectFlatSurface2(page, ".ops-result-row", "search result row");
                await expectPrimaryHover55(page, ".ops-result-row", "search result row");
                break;
              case "search-zero-results":
                await expectRaisedAboveFloor(page, ".ops-muted-panel", "search zero-results muted panel");
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
                await expectRaisedAboveFloor(page, ".ops-notice-surface", "failed-sync notice surface");
                break;
              case "sync-drift": {
                await expectRaisedAboveFloor(page, ".ops-panel", "sync-drift section panel");
                const promotion = page.locator("#index-promotion");
                await expect(promotion).not.toHaveAttribute("open", "");
                await promotion.getByText("Advanced: index promotion", { exact: true }).click();
                await expect(promotion).toHaveAttribute("open", "");
                await expect(promotion.getByRole("button", { name: "Promote target index", exact: true })).toBeDisabled();
                await expectRaisedAboveFloor(page, "#index-promotion .ops-notice-surface", "promotion eligibility notice");
                break;
              }
              case "playbooks-workspace":
                await expectPrimaryHover55(page, ".ops-object-item", "playbooks workspace object item");
                break;
              case "playbooks-populated": {
                await expectPrimaryHover55(page, ".ops-object-item", "playbook object item");
                break;
              }
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
          await expect(page.getByTestId("search-outcome")).toContainText("Search completed");
          await expect(page.locator(".ops-result-row").first()).toBeVisible();
          const submitted = page.locator("#search-run-attribution");
          await expect(submitted).toContainText("Single index");
          await expect(submitted).toContainText("ScrypathEcommerce.Catalog.Product");
          await expect(page.getByTestId("search-submitted-query")).toHaveText("quantum");

          await query.fill("a later query edit");
          await expect(page.getByTestId("search-submitted-query")).toHaveText("quantum");
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

  test("zero-hit Search capture rejects collisions, saves criteria and reflows across themes and widths", async ({
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
        const captureName = `search-capture-${themeSlug(mode)}-${viewport.width}`;

        try {
          await gotoSearch(page);
          const query = `phase176-no-hit-${Date.now()}-${viewport.width}`;
          const queryInput = page.getByLabel("Search text");
          await page.getByLabel("Page size").fill("10");
          await queryInput.fill(query);
          await queryInput.press("Enter");
          await expect(page.getByTestId("search-outcome")).toContainText("Search completed");
          await expect(page.getByText("No matching documents", { exact: true })).toBeVisible();
          await expect(page.getByRole("button", { name: "Save as playbook" })).toBeVisible();
          await page.getByRole("button", { name: "Save as playbook" }).click();

          const captureForm = page.locator("#search-capture-form");
          await expect(captureForm).toBeVisible();
          await expect(page.locator("#search-capture-json")).not.toHaveAttribute("open", "");
          await expect(
            page.getByText("Choose a new .json filename; Search capture cannot replace an existing file.")
          ).toBeVisible();
          await expectSearchDocumentToFit(page);

          if (evidenceDir) {
            await queryInput.blur();
            await page.evaluate(() => window.scrollTo(0, 0));
            await page.screenshot({
              path: join(evidenceDir, `${captureName}-form.png`),
              fullPage: true
            });
          }

          const occupiedName = readdirSync(PLAYBOOK_WORKSPACE_DIR).find(
            (name) => name.endsWith(".json") && !name.startsWith("surface-depth-")
          );
          expect(occupiedName, "the disposable E2E workspace should include a seed playbook").toBeTruthy();
          const occupiedPath = join(PLAYBOOK_WORKSPACE_DIR, occupiedName!);
          const originalBytes = readFileSync(occupiedPath);

          await page.getByLabel("Filename").fill(occupiedName!);
          await page.getByLabel("Search title").fill("A long but optional zero-hit search title for responsive coverage");
          await page.getByLabel("Description").fill("Criteria-only capture from an eligible zero-hit Search response; this description remains available after a rejected collision.");
          await page.getByRole("button", { name: "Save playbook" }).click();

          const captureError = page.getByTestId("search-capture-error");
          await expect(captureError).toContainText("That playbook name is already in use — pick another basename.");
          await expect(page.getByLabel("Filename")).toHaveValue(occupiedName!);
          await expect(page.getByLabel("Search title")).toHaveValue("A long but optional zero-hit search title for responsive coverage");
          await expect(page.getByLabel("Description")).toHaveValue("Criteria-only capture from an eligible zero-hit Search response; this description remains available after a rejected collision.");
          await expect(page.getByLabel("Filename")).toHaveAttribute("aria-invalid", "true");
          await expect(page.getByLabel("Filename")).toHaveAttribute(
            "aria-describedby",
            /capture_basename-hint.*capture_basename-error/
          );
          await expect(captureError).toHaveCSS("font-size", "14px");
          await expectSearchDocumentToFit(page);

          if (evidenceDir) {
            await page.getByLabel("Filename").blur();
            await page.evaluate(() => window.scrollTo(0, 0));
            await page.screenshot({
              path: join(evidenceDir, `${captureName}-collision.png`),
              fullPage: true
            });
          }

          expect(readFileSync(occupiedPath)).toEqual(originalBytes);

          const basename = `surface-depth-search-capture-${themeSlug(mode)}-${viewport.width}-${Date.now()}.json`;
          await page.getByLabel("Filename").fill(basename);
          await page.getByRole("button", { name: "Save playbook" }).click();
          await expect(page.getByText(`Saved playbook ${basename}.`, { exact: true })).toBeVisible();

          const saved = JSON.parse(readFileSync(join(PLAYBOOK_WORKSPACE_DIR, basename), "utf8"));
          expect(saved.mode).toBe("search");
          expect(saved.schema).toBe("ScrypathEcommerce.Catalog.Product");
          expect(saved.q).toBe(query);
          expect(saved.title).toBe("A long but optional zero-hit search title for responsive coverage");
          expect(saved.description).toContain("Criteria-only capture from an eligible zero-hit Search response");
          expect(saved.opts.page.size).toBe(10);
          expect(JSON.stringify(saved)).not.toContain("hits");
          expect(JSON.stringify(saved)).not.toContain("result");

          await gotoPlaybooks(page);
          await expect(page.locator(".ops-object-item").filter({ hasText: basename })).toBeVisible();
          await expectSearchDocumentToFit(page);
        } finally {
          await close();
        }
      }
    }
  });

  test("Playbooks keeps draft and run provenance clear across themes and widths", async ({
    browser,
    request
  }) => {
    test.setTimeout(120_000);
    await seedAndMaybeConfirmSearch(request, "all_green");

    const evidenceDir = process.env.PHASE176_VISUAL_EVIDENCE_DIR;
    if (evidenceDir) mkdirSync(evidenceDir, { recursive: true });

    const viewports = [
      { width: 1440, height: 900 },
      { width: 768, height: 900 },
      { width: 390, height: 844 }
    ];
    const themes: ThemeMode[] = [
      { kind: "explicit", theme: "light" },
      { kind: "explicit", theme: "dark" }
    ];

    for (const mode of themes) {
      for (const viewport of viewports) {
        const { page, close } = await newThemedPage(browser, mode, viewport);
        const captureName = `playbooks-${themeSlug(mode)}-${viewport.width}`;
        const basename = `surface-depth-playbooks-${themeSlug(mode)}-${viewport.width}-${Date.now()}.json`;
        const source = {
          playbook_format: 1,
          mode: "search",
          schema: "ScrypathEcommerce.Catalog.Product",
          q: "quantum",
          opts: { page: { size: 10 } },
          title: "Phase 176 provenance check",
          description: "A saved draft keeps its title and description after preview and run."
        };
        const catalogName = `surface-depth-playbooks-shortcut-${themeSlug(mode)}-${viewport.width}.json`;
        writeFileSync(join(PLAYBOOK_WORKSPACE_DIR, catalogName), `${JSON.stringify(source, null, 2)}\n`);

        try {
          await gotoPlaybooks(page);
          await expect(page.getByRole("link", { name: "Import JSON" })).toBeVisible();
          const initialRow = page.locator(".ops-object-item").filter({ hasText: catalogName });
          await expect(initialRow.getByRole("button", { name: `Run ${catalogName} without preview` })).toBeVisible();
          await expect(page.getByRole("button", { name: "Load preview" }).first()).toBeVisible();
          await expectPlaybookDocumentToFit(page);

          if (evidenceDir) {
            await page.evaluate(() => window.scrollTo(0, 0));
            await page.screenshot({ path: join(evidenceDir, `${captureName}-before.png`), fullPage: true });
          }

          await page.getByRole("link", { name: "Import JSON" }).click();
          const pasteSummary = page.locator("#playbook-import details > summary");
          if (!(await page.locator("#playbook-import details").evaluate((el) => (el as HTMLDetailsElement).open))) {
            await pasteSummary.click();
          }
          await page.locator("#playbook-paste-json").fill(JSON.stringify(source));
          await page.getByRole("button", { name: "Import from paste" }).click();

          await expect(page.locator("#playbook-draft-origin")).toContainText("Imported draft · not saved");
          await expect(page.locator("#playbook-draft-origin")).toContainText("pasted JSON");
          await expect(page.getByRole("button", { name: "Run playbook" })).toBeEnabled();
          await expect(page.getByRole("button", { name: "Save playbook to workspace" })).toBeEnabled();
          await expect(page.getByText("Saving a workspace playbook replaces a file with the same filename.")).toBeVisible();
          await expect(page.locator("#playbook-run-outcome")).toHaveCount(0);
          await expectPlaybookDocumentToFit(page);

          await page.getByLabel("Filename").fill(basename);
          await page.getByRole("button", { name: "Save playbook to workspace" }).click();
          await expect(page.getByText(`Saved ${basename}`, { exact: true })).toBeVisible();
          await expect(page.locator("#playbook-draft-origin")).toContainText(`Workspace file · ${basename}`);

          const saved = JSON.parse(readFileSync(join(PLAYBOOK_WORKSPACE_DIR, basename), "utf8"));
          expect(saved.title).toBe(source.title);
          expect(saved.description).toBe(source.description);
          expect(saved.q).toBe("quantum");
          expect(saved.opts.page.size).toBe(10);

          const row = page.locator(".ops-object-item").filter({ hasText: basename });
          await row.getByRole("button", { name: "Load preview" }).click();
          await expect(page.locator("#playbook-draft-origin")).toContainText(`Workspace file · ${basename}`);
          await page.getByRole("button", { name: "Run playbook" }).click();
          await expect(page.locator("#playbook-run-outcome")).toContainText("Playbook run completed");
          await expect(page.locator("#playbook-run-source")).toContainText(basename);
          await expect(page.locator("#playbook-run-outcome")).toContainText("ScrypathEcommerce.Catalog.Product");
          await expectPlaybookDocumentToFit(page);

          const changedDraft = { ...source, q: "changed after the run", title: "Current draft" };
          if (!(await page.locator("#playbook-import details").evaluate((el) => (el as HTMLDetailsElement).open))) {
            await pasteSummary.click();
          }
          await page.locator("#playbook-paste-json").fill(JSON.stringify(changedDraft));
          await page.getByRole("button", { name: "Import from paste" }).click();

          await expect(page.locator("#playbook-preview")).toContainText("changed after the run");
          await expect(page.locator("#playbook-run-outcome")).toContainText("Last completed run");
          await expect(page.locator("#playbook-run-outcome")).toContainText("quantum");
          await expect(page.locator("#playbook-run-outcome")).toContainText(basename);
          await expect(page.locator("#playbook-run-outcome")).not.toContainText("changed after the run");
          const handoffHref = await page.locator("#playbook-run-outcome a").getAttribute("href");
          expect(new URL(handoffHref!, "http://localhost").searchParams.get("q")).toBe("quantum");

          const stages = await page.locator(
            "#playbook-catalog-heading, #playbook-preview-heading, #playbook-run-outcome-heading, #playbook-import-heading"
          ).evaluateAll((elements) => elements.map((element) => element.id));
          expect(stages).toEqual([
            "playbook-catalog-heading",
            "playbook-preview-heading",
            "playbook-run-outcome-heading",
            "playbook-import-heading"
          ]);
          await expectPlaybookDocumentToFit(page);

          if (evidenceDir) {
            await page.locator("#playbook-paste-json").blur();
            await page.evaluate(() => window.scrollTo(0, 0));
            await page.screenshot({ path: join(evidenceDir, `${captureName}-after.png`), fullPage: true });
          }

          const shortcutRow = page.locator(".ops-object-item").filter({ hasText: catalogName });
          await shortcutRow.getByRole("button", { name: `Run ${catalogName} without preview` }).click();
          await expect(page.locator("#playbook-run-outcome")).toContainText("Playbook run completed");
          await expect(page.locator("#playbook-run-source")).toContainText(catalogName);
          await expectPlaybookDocumentToFit(page);
        } finally {
          await close();
        }
      }
    }
  });

  test("Playbooks imports files explicitly and retains a valid preview after paste errors", async ({
    browser,
    request
  }) => {
    await seedAndMaybeConfirmSearch(request, "all_green");

    const evidenceDir = process.env.PHASE176_VISUAL_EVIDENCE_DIR;
    if (evidenceDir) mkdirSync(evidenceDir, { recursive: true });

    const viewports = [
      { width: 1440, height: 900 },
      { width: 768, height: 900 },
      { width: 390, height: 844 }
    ];
    const themes: ThemeMode[] = [
      { kind: "explicit", theme: "light" },
      { kind: "explicit", theme: "dark" }
    ];

    for (const mode of themes) {
      for (const viewport of viewports) {
        const { page, close } = await newThemedPage(browser, mode, viewport);
        const captureName = `playbooks-import-${themeSlug(mode)}-${viewport.width}`;
        const uploadedName = `uploaded-${"long-playbook-name-".repeat(5)}${themeSlug(mode)}-${viewport.width}.json`;
        const uploadedQuery = `uploaded query ${"wrapped criteria ".repeat(8)}${viewport.width}`;
        const uploadedJson = JSON.stringify({
          playbook_format: 1,
          mode: "search",
          schema: "ScrypathEcommerce.Catalog.Product",
          q: uploadedQuery,
          opts: { page: { size: 10 } },
          title: "Uploaded preview"
        });

        try {
          await gotoPlaybooks(page);
          await expect(page.locator("#playbook-preview")).toHaveCount(0);
          await expectPlaybookDocumentToFit(page);

          if (evidenceDir) {
            await page.evaluate(() => window.scrollTo(0, 0));
            await page.screenshot({ path: join(evidenceDir, `${captureName}-before.png`), fullPage: true });
          }

          const uploadInput = page.locator("input[type='file']").first();
          await uploadInput.setInputFiles({
            name: uploadedName,
            mimeType: "application/json",
            buffer: Buffer.from(uploadedJson)
          });
          const uploadBindings = await uploadInput.evaluate((input: HTMLInputElement) => ({
            uploadRef: input.getAttribute("data-phx-upload-ref"),
            changeEvent: input.form?.getAttribute("phx-change"),
            submitEvent: input.form?.getAttribute("phx-submit")
          }));
          expect(uploadBindings.uploadRef).toBeTruthy();
          expect(uploadBindings.changeEvent).toBe("validate_upload");
          expect(uploadBindings.submitEvent).toBe("import_upload");

          // File selection is only preparation. The preview and run state stay empty until submit.
          await expect(page.locator("#playbook-preview")).toHaveCount(0);
          await expect(page.locator("#playbook-run-outcome")).toHaveCount(0);
          await page.getByRole("button", { name: "Import playbook JSON" }).click();
          await expect(page.locator("#playbook-draft-origin")).toContainText(uploadedName);
          await expect(page.locator("#playbook-preview")).toContainText(uploadedQuery);
          await expect(page.getByRole("button", { name: "Run playbook" })).toBeEnabled();
          await expect(page.locator("#playbook-run-outcome")).toHaveCount(0);
          await expectPlaybookDocumentToFit(page);

          const pasteSummary = page.locator("#playbook-import details > summary");
          if (!(await page.locator("#playbook-import details").evaluate((el) => (el as HTMLDetailsElement).open))) {
            await pasteSummary.click();
          }
          const longInvalidJson = `{"q":"${"long input ".repeat(500)}"`;
          await page.locator("#playbook-paste-json").fill(longInvalidJson);
          await page.getByRole("button", { name: "Import from paste" }).click();

          await expect(page.locator("#playbook-import-error")).toContainText("This file is not valid playbook JSON.");
          await expect(page.locator("#playbook-import-error")).toContainText("The previous valid preview remains selected.");
          await expect(page.locator("#playbook-paste-json")).toHaveValue(longInvalidJson);
          await expect(page.locator("#playbook-import details")).toHaveJSProperty("open", true);
          await expect(page.locator("#playbook-draft-origin")).toContainText(uploadedName);
          await expect(page.locator("#playbook-preview")).toContainText(uploadedQuery);
          await expect(page.locator("#playbook-run-outcome")).toHaveCount(0);
          await expectPlaybookDocumentToFit(page);

          await expect(page.locator("#flash-info")).toHaveCount(0);

          if (evidenceDir) {
            await page.locator("#playbook-paste-json").blur();
            await page.evaluate(() => window.scrollTo(0, 0));
            await page.screenshot({ path: join(evidenceDir, `${captureName}-after.png`), fullPage: true });
          }
        } finally {
          await close();
        }
      }
    }
  });

  test("Playbook management keeps modal focus on visible file identities through LiveView patches", async ({
    browser
  }) => {
    const stamp = Date.now().toString();
    const prefix = `000-phase176-focus-${stamp}`;
    const sourceName = `${prefix}-a-${"long-filename-".repeat(4)}.json`;
    const copyName = `${prefix}-b-copy.json`;
    const renamedName = `${prefix}-c-${"renamed-playbook-".repeat(3)}.json`;
    const createdNames = [sourceName, copyName, renamedName];
    const evidenceDir = process.env.PHASE176_VISUAL_EVIDENCE_DIR;
    if (evidenceDir) mkdirSync(evidenceDir, { recursive: true });

    try {
      const { page, close } = await newThemedPage(
        browser,
        { kind: "explicit", theme: "light" },
        { width: 390, height: 844 }
      );

      try {
        await gotoPlaybooks(page);
        const importDisclosure = page.locator("#playbook-import details");
        if (!(await importDisclosure.evaluate((el) => (el as HTMLDetailsElement).open))) {
          await importDisclosure.locator("summary").click();
        }

        const json = JSON.stringify({
          playbook_format: 1,
          mode: "search",
          schema: "ScrypathEcommerce.Catalog.Product",
          q: "modal focus contract",
          opts: {}
        });
        await page.locator("#playbook-paste-json").fill(json);
        await page.getByRole("button", { name: "Import from paste" }).click();
        await expect(page.locator("#playbook-preview")).toContainText("modal focus contract");
        await page.locator("#save_basename").fill(sourceName);
        await page.getByRole("button", { name: "Save playbook to workspace" }).click();

        const sourceId = playbookDomId(sourceName);
        const sourceManage = page.locator(`#playbook-manage-${sourceId}`);
        const sourceSummary = page.locator(`#playbook-manage-summary-${sourceId}`);
        await expect(sourceManage).toBeVisible();
        await expect(sourceManage).toHaveJSProperty("open", false);
        await expect(page.locator(`#playbook-row-${sourceId} .ops-playbook-filename`)).toHaveText(sourceName);
        await expectPlaybookDocumentToFit(page);

        await sourceSummary.click();
        await expect(sourceManage).toHaveJSProperty("open", true);
        await page.getByRole("button", { name: `Duplicate ${sourceName}` }).click();
        const duplicateDialog = page.locator("#duplicate-playbook-modal");
        await expect(duplicateDialog).toBeVisible();
        await expect(sourceManage).toHaveJSProperty("open", false);
        await expect(page.locator("#dup-to-name-input")).toBeFocused();
        expect(
          await page.locator("#playbook-import").evaluate((el) => (el as HTMLElement).inert),
          "the background import section is inert while a file dialog is open"
        ).toBe(true);

        await page.getByRole("button", { name: "Close Duplicate playbook dialog" }).click();
        await expect(duplicateDialog).toHaveCount(0);
        await expect(sourceSummary).toBeFocused();

        await sourceSummary.click();
        await page.getByRole("button", { name: `Duplicate ${sourceName}` }).click();
        const duplicateInput = page.locator("#dup-to-name-input");
        await duplicateInput.fill(sourceName);
        await expect(duplicateInput).toBeFocused();
        await page.getByRole("button", { name: "Duplicate", exact: true }).click();
        await expect(page.locator("#dup-to-name-input-error")).toContainText("already in use");
        await expect(duplicateInput).toHaveValue(sourceName);
        await expect(duplicateInput).toBeFocused();
        await expect(duplicateInput).toHaveCSS("font-size", "14px");
        await page.getByRole("button", { name: "Cancel duplicate" }).click();
        await expect(duplicateDialog).toHaveCount(0);
        await expect(sourceSummary).toBeFocused();

        await sourceSummary.click();
        await page.getByRole("button", { name: `Duplicate ${sourceName}` }).click();
        await page.locator("#dup-to-name-input").fill(copyName);
        await page.getByRole("button", { name: "Duplicate", exact: true }).click();
        await expect(duplicateDialog).toHaveCount(0);
        await expect(sourceSummary).toBeFocused();
        const copyId = playbookDomId(copyName);
        await expect(page.locator(`#playbook-row-${copyId}`)).toBeVisible();

        await sourceSummary.click();
        await page.getByRole("button", { name: `Rename ${sourceName}` }).click();
        const renameDialog = page.locator("#rename-playbook-modal");
        const renameInput = page.locator("#rename-new-name-input");
        await expect(renameDialog).toBeVisible();
        await expect(sourceManage).toHaveJSProperty("open", false);
        await expect(renameInput).toBeFocused();
        await renameInput.fill("bad/name.json");
        await expect(renameInput).toBeFocused();
        await page.getByRole("button", { name: "Rename", exact: true }).click();
        await expect(page.locator("#rename-new-name-input-error")).toContainText("basename rules");
        await expect(renameInput).toHaveValue("bad/name.json");
        await expect(renameInput).toBeFocused();

        await renameInput.fill(copyName);
        await page.getByRole("button", { name: "Rename", exact: true }).click();
        await expect(page.locator("#rename-new-name-input-error")).toContainText("already in use");
        await expect(renameInput).toHaveValue(copyName);
        await expect(renameInput).toBeFocused();

        await renameInput.fill(renamedName);
        await page.getByRole("button", { name: "Rename", exact: true }).click();
        await expect(renameDialog).toHaveCount(0);
        const renamedId = playbookDomId(renamedName);
        const renamedSummary = page.locator(`#playbook-manage-summary-${renamedId}`);
        await expect(page.locator(`#playbook-row-${renamedId}`)).toBeVisible();
        await expect(renamedSummary).toBeFocused();
        await expectPlaybookDocumentToFit(page);

        const copySummary = page.locator(`#playbook-manage-summary-${copyId}`);
        await copySummary.click();
        await page.getByRole("button", { name: `Delete ${copyName}` }).click();
        const deleteDialog = page.locator("#delete-playbook-modal");
        const deleteInput = page.locator("#delete-confirm-input");
        const deleteCancel = page.getByRole("button", { name: "Cancel delete" });
        const closeDelete = page.getByRole("button", { name: "Close Delete playbook file dialog" });
        await expect(deleteDialog).toBeVisible();
        await expect(deleteCancel).toBeFocused();
        await expect(page.locator(`#playbook-manage-${copyId}`)).toHaveJSProperty("open", false);

        await closeDelete.focus();
        await page.keyboard.press("Shift+Tab");
        await expect(page.getByRole("button", { name: "Confirm delete", exact: true })).toBeFocused();
        await page.keyboard.press("Tab");
        await expect(closeDelete).toBeFocused();
        await page.keyboard.press("Escape");
        await expect(deleteDialog).toHaveCount(0);
        await expect(copySummary).toBeFocused();

        await copySummary.click();
        await page.getByRole("button", { name: `Delete ${copyName}` }).click();
        await expect(deleteCancel).toBeFocused();
        await deleteInput.fill(`wrong-${copyName}`);
        await page.getByRole("button", { name: "Confirm delete", exact: true }).click();
        await expect(page.locator("#delete-confirm-input-error")).toContainText("match the filename exactly");
        await expect(deleteInput).toHaveValue(`wrong-${copyName}`);
        await expect(deleteInput).toBeFocused();
        await expect(page.locator(`#playbook-row-${copyId}`)).toBeVisible();

        const deleteSuccessor = await deleteDialog.getAttribute("data-ops-modal-successor");
        expect(deleteSuccessor).toMatch(/^#playbook-primary-/);
        await deleteInput.fill(copyName);
        await page.getByRole("button", { name: "Confirm delete", exact: true }).click();
        await expect(deleteDialog).toHaveCount(0);
        await expect(page.locator(deleteSuccessor!)).toBeFocused();
        await expect(page.locator(`#playbook-row-${copyId}`)).toHaveCount(0);
        await expectPlaybookDocumentToFit(page);

        if (evidenceDir) {
          await page.evaluate(() => window.scrollTo(0, 0));
          await page.screenshot({ path: join(evidenceDir, "playbook-management-light-390-after.png"), fullPage: true });
        }
      } finally {
        await close();
      }

      const themes: ThemeMode[] = [
        { kind: "explicit", theme: "light" },
        { kind: "explicit", theme: "dark" }
      ];
      const viewports = [
        { width: 1440, height: 900 },
        { width: 768, height: 900 },
        { width: 390, height: 844 }
      ];

      for (const mode of themes) {
        for (const viewport of viewports) {
          const { page, close } = await newThemedPage(browser, mode, viewport);
          const captureName = `playbook-management-${themeSlug(mode)}-${viewport.width}`;
          try {
            await gotoPlaybooks(page);
            const renamedId = playbookDomId(renamedName);
            const manage = page.locator(`#playbook-manage-${renamedId}`);
            const summary = page.locator(`#playbook-manage-summary-${renamedId}`);
            await expect(manage).toBeVisible();
            await expect(manage).toHaveJSProperty("open", false);
            await expectPlaybookDocumentToFit(page);
            if (evidenceDir) {
              await page.evaluate(() => window.scrollTo(0, 0));
              await page.screenshot({ path: join(evidenceDir, `${captureName}-before.png`), fullPage: true });
            }

            await summary.click();
            await page.getByRole("button", { name: `Rename ${renamedName}` }).click();
            const dialog = page.locator("#rename-playbook-modal");
            const input = page.locator("#rename-new-name-input");
            await expect(dialog).toBeVisible();
            await expect(manage).toHaveJSProperty("open", false);
            await expect(input).toBeFocused();
            await expectPlaybookDocumentToFit(page);

            const bounds = await page.locator("#rename-playbook-modal .modal-box").boundingBox();
            expect(bounds).not.toBeNull();
            expect(bounds!.x).toBeGreaterThanOrEqual(0);
            expect(bounds!.y).toBeGreaterThanOrEqual(0);
            expect(bounds!.x + bounds!.width).toBeLessThanOrEqual(viewport.width);
            expect(bounds!.y + bounds!.height).toBeLessThanOrEqual(viewport.height);

            await input.fill("bad/name.json");
            await page.getByRole("button", { name: "Rename", exact: true }).click();
            await expect(page.locator("#rename-new-name-input-error")).toContainText("basename rules");
            await expect(input).toHaveValue("bad/name.json");
            await expect(input).toBeFocused();
            await expect(page.locator("#rename-new-name-input-error")).toHaveCSS("font-size", "14px");
            await expectPlaybookDocumentToFit(page);
            if (evidenceDir) {
              await page.evaluate(() => window.scrollTo(0, 0));
              await page.screenshot({ path: join(evidenceDir, `${captureName}-after.png`), fullPage: true });
            }

            await page.keyboard.press("Escape");
            await expect(dialog).toHaveCount(0);
            await expect(summary).toBeFocused();
          } finally {
            await close();
          }
        }
      }
    } finally {
      const present = new Set(readdirSync(PLAYBOOK_WORKSPACE_DIR));
      for (const name of createdNames) {
        if (present.has(name)) unlinkSync(join(PLAYBOOK_WORKSPACE_DIR, name));
      }
    }
  });

  test("Playbook item has no violet glow in light", async ({ browser, request }) => {
    await seedAndMaybeConfirmSearch(request, "all_green");
    const { page, close } = await newThemedPage(browser, { kind: "explicit", theme: "light" }, "desktop");
    try {
      await preparePopulatedPlaybooks(page);
      const glow = await readComputedStyle(page, ".ops-object-item", "boxShadow");
      expect(glow, "light playbook item must not carry the dark violet glow").not.toContain(GLOW_RGB);
    } finally {
      await close();
    }
  });
});
