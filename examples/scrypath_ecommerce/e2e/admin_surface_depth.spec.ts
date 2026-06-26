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
import { expect, test, type APIRequestContext, type Browser, type Page } from "@playwright/test";

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
const ELEVATION_DELTA_FLOOR = 0.015;
const DK13_ROW_BORDER_TRIGGER = 1.2;

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

function relativeLuminance(raw: string): number {
  const [r, g, b] = rgbChannels(raw).map((channel) => {
    const s = channel / 255;
    return s <= 0.03928 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
  });
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

function contrastRatio(a: string, b: string): number {
  const l1 = relativeLuminance(a);
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
    relativeLuminance(bg) - relativeLuminance(floor),
    `${label} luminance must exceed --ops-bg floor by >= ${ELEVATION_DELTA_FLOOR}`
  ).toBeGreaterThanOrEqual(ELEVATION_DELTA_FLOOR);
}

async function expectFlatSurface2(page: Page, selector: string, label: string): Promise<void> {
  const bg = await readComputedStyle(page, selector, "backgroundColor");
  expect(bg, `${label} flat surface token`).toBe(DARK_SURFACE_2_RGB);
  await expectRaisedAboveFloor(page, selector, label);
}

async function expectPrimaryHover55(page: Page, selector: string, label: string): Promise<void> {
  const resting = await readComputedStyle(page, selector, "borderColor");
  await page.locator(selector).first().hover();
  const hover = await readComputedStyle(page, selector, "borderColor");
  const expected = await resolveCssColor(
    page,
    "border-color: color-mix(in oklch, var(--color-primary) 55%, transparent)"
  );

  expect(hover, `${label} hover border must resolve to primary 55%`).toBe(expected);
  expect(hover, `${label} hover border must differ from resting`).not.toBe(resting);
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
  const border = await readComputedStyle(page, '[data-testid="intent-incident"] .ops-copper-badge', "borderColor");
  const bg = await readComputedStyle(page, '[data-testid="intent-incident"] .ops-copper-badge', "backgroundColor");
  const text = await readComputedStyle(page, '[data-testid="intent-incident"] .ops-copper-badge', "color");
  const baseContent = await resolveCssColor(page, "border-color: var(--color-base-content)");

  expect(border, "copper badge border resolves to secondary tint").toBe(expectedBorder);
  expect(bg, "copper badge background resolves to secondary tint").toBe(expectedBg);
  expect(text, "copper badge text stays base-content").toBe(baseContent);
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
  const matches = await page.evaluate(
    ([expectedBorder, expectedBg]) => {
      const statusClassPattern = /\b(ops-tone-|ops-badge-(success|warning|error|partial|running|info|neutral)|ops-metric-)/;
      return Array.from(document.querySelectorAll<HTMLElement>("[class]"))
        .filter((el) => statusClassPattern.test(el.className) && !el.classList.contains("ops-copper-badge"))
        .filter((el) => {
          const style = getComputedStyle(el);
          return style.borderColor === expectedBorder || style.backgroundColor === expectedBg;
        })
        .map((el) => el.className);
    },
    [copperBorder, copperBg] as const
  );

  expect(matches, "status tone/badge classes must never compute to copper").toEqual([]);
}

async function expectPostureTableBorderMeasured(page: Page): Promise<number> {
  const cell = ".ops-table-scroll table tbody tr:first-child td:first-child";
  await expect(page.locator(cell)).toBeVisible();
  const border = await readComputedStyle(page, cell, "borderColor");
  const ratio = contrastRatio(border, DARK_SURFACE_2_RGB);
  console.info(`DK-13 posture row-border contrast ratio: ${ratio.toFixed(3)}:1`);

  if (ratio < DK13_ROW_BORDER_TRIGGER) {
    await expect(
      page.locator(".ops-posture-table"),
      `DK-13 row-border ratio ${ratio.toFixed(3)}:1 is below ${DK13_ROW_BORDER_TRIGGER}:1, so the leaf-scoped override must be present`
    ).toHaveCount(1);
    const boostedBorder = await readComputedStyle(page, ".ops-posture-table tbody tr:first-child td:first-child", "borderColor");
    expect(contrastRatio(boostedBorder, DARK_SURFACE_2_RGB)).toBeGreaterThanOrEqual(ratio);
  }

  return ratio;
}

async function preparePopulatedPlaybooks(page: Page): Promise<void> {
  await gotoSearch(page);
  await page.getByLabel("Search text").fill("quantum");
  await page.getByRole("button", { name: "Run bounded search" }).click();
  await expect(page.getByRole("heading", { name: "Results" })).toBeVisible();

  const basename = `surface-depth-${Date.now()}.json`;
  await page.getByLabel("Basename (.json)").fill(basename);
  await page.getByRole("button", { name: "Save search as playbook" }).click();
  await expect(page.getByText(new RegExp(`Saved playbook ${basename.replace(".", "\\.")}`))).toBeVisible();

  await gotoPlaybooks(page);
  await expect(page.locator(".ops-object-item").first()).toBeVisible();

  const loadPreview = page.getByRole("button", { name: "Load preview" }).first();
  await loadPreview.click();
  await expect(page.locator(".ops-object-item-active")).toHaveCount(1);
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
    id: "posture-table",
    scenario: "incident",
    captureIndex: "01",
    selectors: [".ops-table-scroll table", ".ops-verdict--hero"],
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
    selectors: [".ops-muted-panel", ".ops-preflight__card"]
  },
  {
    id: "playbooks-empty-workspace",
    scenario: "empty",
    captureIndex: "09",
    selectors: [".ops-empty-state"]
  },
  {
    id: "playbooks-populated",
    scenario: "all_green",
    captureIndex: "12",
    selectors: [".ops-object-item", ".ops-object-item-active"],
    prepare: preparePopulatedPlaybooks
  }
];

test.describe("admin surface depth — SCREEN-DARK-01", () => {
  test.describe.configure({ timeout: 120_000 });

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
                break;
              case "posture-table": {
                const heroShadow = await readComputedStyle(page, ".ops-verdict--hero", "boxShadow");
                expect(heroShadow, "posture verdict hero should use a dark raised shadow, not no shadow").not.toBe("none");
                expect(heroShadow, "posture verdict hero should not carry a copper warm halo").not.toContain(COPPER_RGB);
                await expectPostureTableBorderMeasured(page);
                break;
              }
              case "failed-sync-notice":
                await expectRaisedAboveFloor(page, ".ops-notice-surface", "failed-sync notice surface");
                break;
              case "sync-drift": {
                await expectRaisedAboveFloor(page, ".ops-muted-panel", "sync-drift muted panel");
                const baseCard = await readComputedStyle(page, ".ops-preflight__card:not(.ops-preflight__card--locked)", "backgroundColor");
                const lockedCard = await readComputedStyle(page, ".ops-preflight__card--locked", "backgroundColor");
                expect(
                  relativeLuminance(lockedCard),
                  "locked preflight card must step above base preflight card"
                ).toBeGreaterThan(relativeLuminance(baseCard));
                break;
              }
              case "playbooks-empty-workspace":
                await expectRaisedAboveFloor(page, ".ops-empty-state", "playbooks empty workspace state");
                break;
              case "playbooks-populated": {
                await expectFlatSurface2(page, ".ops-data-card", "playbooks populated data card");
                await expectPrimaryHover55(page, ".ops-object-item", "playbook object item");
                const glow = await readComputedStyle(page, ".ops-object-item-active", "boxShadow");
                expect(glow, "dark/system-dark active playbook item must carry violet glow").toContain(GLOW_RGB);
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

  test("active Playbook item has no violet glow in light", async ({ browser, request }) => {
    await seedAndMaybeConfirmSearch(request, "all_green");
    const { page, close } = await newThemedPage(browser, { kind: "explicit", theme: "light" }, "desktop");
    try {
      await preparePopulatedPlaybooks(page);
      const glow = await readComputedStyle(page, ".ops-object-item-active", "boxShadow");
      expect(glow, "light active playbook item must not carry the dark violet glow").not.toContain(GLOW_RGB);
    } finally {
      await close();
    }
  });
});
