/**
 * Admin surface-depth binding gate (SCREEN-DARK-01, Phase 134 Plan 01).
 *
 * This Wave 0 harness proves the dark/system-dark theme grid, seeded target screens,
 * and populated Playbooks setup before Plan 02 lands the CSS changes and replaces the
 * TODO placeholders with computed-style depth assertions.
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
  gotoPlaybooks,
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
  property: "backgroundColor" | "borderColor" | "boxShadow"
): Promise<string> {
  return page.evaluate(
    ([sel, prop]) => {
      const el = document.querySelector(sel);
      if (!el) throw new Error(`surface-depth probe: element not found for ${sel}`);
      return getComputedStyle(el)[prop as "backgroundColor" | "borderColor" | "boxShadow"];
    },
    [selector, property] as const
  );
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

test.describe("admin surface depth — SCREEN-DARK-01 Wave 0", () => {
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
              // TODO(Phase 134 Plan 02): replace this structure probe with the
              // SCREEN-DARK-01 computed-style depth assertions for each surface.
              await readComputedStyle(page, selector, "backgroundColor");
            }

            if (target.id === "playbooks-populated") {
              const glow = await readComputedStyle(page, ".ops-object-item-active", "boxShadow");
              // TODO(Phase 134 Plan 02): assert dark/system-dark active glow contains GLOW_RGB.
              expect(typeof glow).toBe("string");
              expect(GLOW_RGB).toBe("108, 92, 231");
            }
          } finally {
            await close();
          }
        });
      }
    }
  }
});
