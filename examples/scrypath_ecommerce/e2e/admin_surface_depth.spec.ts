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
import { readdirSync, unlinkSync } from "node:fs";
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
  gotoPosture,
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
const DARK_SURFACE_2_RGB = "rgb(27, 34, 48)";
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
  viewport: ViewportName
): Promise<{ page: Page; close: () => Promise<void> }> {
  const context = await browser.newContext({
    viewport: VIEWPORTS[viewport],
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
  const bg = await readComputedStyle(page, selector, "backgroundColor");
  expect(bg, `${label} flat surface token`).toBe(DARK_SURFACE_2_RGB);
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

async function expectCopperBadge(page: Page): Promise<void> {
  const badge = page.locator('[data-testid="intent-incident"] .ops-copper-badge');
  await expect(badge).toHaveCount(1);

  const expectedBorder = await resolveCssColor(
    page,
    "border-color: color-mix(in oklch, var(--color-secondary) 44%, transparent)"
  );
  const expectedBg = await resolveCssColor(
    page,
    "background: color-mix(in oklch, var(--color-secondary) 12%, transparent)",
    "backgroundColor"
  );
  const baseContent = await resolveCssColor(page, "border-color: var(--color-base-content)");

  for (const [property, expected, label] of [
    ["borderColor", expectedBorder, "copper badge border resolves to secondary tint"],
    ["backgroundColor", expectedBg, "copper badge background resolves to secondary tint"],
    ["color", baseContent, "copper badge text stays base-content"]
  ] as const) {
    await expect
      .poll(
        async () =>
          colorsEquivalent(
            await readComputedStyle(
              page,
              '[data-testid="intent-incident"] .ops-copper-badge',
              property
            ),
            expected
          ),
        { message: label }
      )
      .toBe(true);
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

async function expectPostureSignalCardsMeasured(page: Page): Promise<void> {
  const card = ".ops-schema-signal-card";
  await expect(page.locator(card).first()).toBeVisible();

  const bg = await readComputedStyle(page, card, "backgroundColor");
  const shadow = await readComputedStyle(page, card, "boxShadow");
  expect(bg, "posture signal cards use the dark surface-2 depth token").toBe(DARK_SURFACE_2_RGB);
  expect(shadow, "posture signal cards must keep seated dark-panel depth").not.toBe("none");

  const signalGroup = ".ops-signal-group";
  await expect(page.locator(signalGroup).first()).toBeVisible();
  const border = await readComputedStyle(page, signalGroup, "borderColor");
  const ratio = contrastRatio(border, DARK_SURFACE_2_RGB);
  console.info(`posture signal-group border contrast ratio: ${ratio.toFixed(3)}:1`);
  expect(
    ratio,
    `posture signal-group border ratio must stay at or above ${DK13_ROW_BORDER_TRIGGER}:1`
  ).toBeGreaterThanOrEqual(DK13_ROW_BORDER_TRIGGER);

  await expect(page.locator(".ops-signal-metrics dd").first()).toBeVisible();
}

async function preparePopulatedPlaybooks(page: Page): Promise<void> {
  await gotoSearch(page);
  await page.getByLabel("Search text").fill("quantum");
  await page.getByRole("button", { name: "Run search" }).click();
  await expect(page.getByRole("heading", { name: "Results", exact: true })).toBeVisible();

  const basename = `surface-depth-${Date.now()}.json`;
  await page.getByRole("button", { name: "Save as playbook" }).click();
  await page.getByLabel("Basename (.json)").fill(basename);
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
    id: "control-room-recommended",
    scenario: "incident",
    captureIndex: "00",
    selectors: ['[data-testid="intent-incident"]', ".ops-copper-badge"],
    prepare: gotoControlRoom
  },
  {
    id: "posture-signal-cards",
    scenario: "incident",
    captureIndex: "01",
    selectors: [".ops-schema-signal-card", ".ops-signal-group", ".ops-signal-metrics"],
    prepare: gotoPosture
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
    selectors: [".ops-panel", ".ops-preflight__card"]
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
              case "control-room-recommended":
                await expectCopperBadge(page);
                await expectNoStatusCopper(page);
                {
                  const heroShadow = await readComputedStyle(page, ".ops-verdict--hero", "boxShadow");
                  expect(heroShadow, "control-room verdict hero should use a dark raised shadow, not no shadow").not.toBe("none");
                  expect(heroShadow, "control-room verdict hero should not carry a copper warm halo").not.toContain(COPPER_RGB);
                }
                break;
              case "posture-signal-cards": {
                await expectPostureSignalCardsMeasured(page);
                break;
              }
              case "failed-sync-notice":
                await expectRaisedAboveFloor(page, ".ops-notice-surface", "failed-sync notice surface");
                break;
              case "sync-drift": {
                await expectRaisedAboveFloor(page, ".ops-panel", "sync-drift section panel");
                const baseCard = await readComputedStyle(page, ".ops-preflight__card:not(.ops-preflight__card--locked)", "backgroundColor");
                const lockedCard = await readComputedStyle(page, ".ops-preflight__card--locked", "backgroundColor");
                const floor = await darkBgFloor(page);
                expect(
                  relativeLuminance(lockedCard, floor),
                  "locked preflight card must step above base preflight card"
                ).toBeGreaterThan(relativeLuminance(baseCard, floor));
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
