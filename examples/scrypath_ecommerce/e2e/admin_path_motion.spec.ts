/**
 * Admin motion tokens: the computed motion proof (P-12, Phase 187, SKIN-05 and A11Y-03).
 *
 * This file keeps its name because `package.json` (`test:e2e:path-motion`) and
 * `make verify-path-motion` run it by path. The path-motion vocabulary it used to prove is gone;
 * the spec now proves the rule that replaced it, in a real browser, from computed styles:
 *
 *   1. Nothing loops. `document.getAnimations()` holds no animation with `iterations === Infinity`.
 *      Finite color transitions and one-shot reveals are normal and are not counted (a loader is a
 *      literal word plus `aria-busy`, never a spinner).
 *   2. Every duration is on the brand scale. Each element, and its `::before` and `::after`, computes
 *      `transition-duration` and `animation-duration` values of 0, 80, 160 or 240 ms only (the brand's
 *      instant, quick and base tokens), so neither 600 ms (`advance`, the progress line) nor the
 *      logo animation's duration exists in ops. A failure names the offending selector path.
 *   3. The same holds after the interactions that open new surfaces: a refresh, the Save search
 *      dialog and the Manage saved searches sheet.
 *   4. Reduced motion collapses it: with `reducedMotion: "reduce"` every duration is at most 1 ms and
 *      no animation is running.
 *
 * Each check runs on the six ops screens at 390 and 1280 px in light, dark and System. A planted
 * element with an off-scale duration and an infinite animation proves the probe can fail.
 *
 * HOW TO RUN (manual server per playwright.config.ts, there is NO webServer):
 *   `make verify-path-motion` boots a disposable test stack, runs this file and tears it down.
 *   Or against a booted, seeded ops server at PLAYWRIGHT_BASE_URL (default http://127.0.0.1:4002):
 *     cd examples/scrypath_ecommerce
 *     npx playwright test e2e/admin_path_motion.spec.ts --reporter=line
 */
import { expect, test, type APIRequestContext, type Browser, type Page } from "@playwright/test";

import {
  drainSearchQueue,
  openManageSavedSearches,
  seedScenario,
  waitForLiveConnected,
  waitForSearchVisible,
  type SeedScenario
} from "./helpers/e2e";
import { assertSystemDarkInvariants, THEME_MODES, themeSlug, type ThemeMode } from "./helpers/theme-grid";

// The brand scale, in milliseconds: instant, quick and base, and zero for "no transition".
const SCALE_MS = [0, 80, 160, 240];
// Under reduced motion the global rule snaps every duration to 0.01 ms; the contract is 1 ms.
const REDUCED_MAX_MS = 1;

const VIEWPORTS = {
  mobile: { width: 390, height: 844 },
  desktop: { width: 1280, height: 900 }
} as const;
type ViewportName = keyof typeof VIEWPORTS;

type Screen = { name: string; path: string; heading: string };

const SCREENS: Screen[] = [
  { name: "Control Room", path: "/admin/search", heading: "Control Room" },
  { name: "Search health", path: "/admin/search/health", heading: "Search health" },
  { name: "Failed sync work", path: "/admin/search/failed-sync", heading: "Failed sync work" },
  { name: "Sync and index", path: "/admin/search/sync-and-index", heading: "Sync and index" },
  { name: "Search", path: "/admin/search/search", heading: "Search" },
  { name: "Help", path: "/admin/search/help", heading: "Help" }
];

type MotionScan = {
  scanned: number;
  offenders: string[];
  infinite: string[];
  running: number;
};

async function newThemedPage(
  browser: Browser,
  mode: ThemeMode,
  viewport: ViewportName,
  reducedMotion: "reduce" | "no-preference"
): Promise<{ page: Page; close: () => Promise<void> }> {
  const context = await browser.newContext({
    viewport: VIEWPORTS[viewport],
    reducedMotion,
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

// Read every element's computed durations (and those of its ::before and ::after) and every live
// animation, in the page. `reduced` swaps the scale for the reduced-motion ceiling. Offenders are
// grouped by property and value, each with the first selector path that has it and a count, so a
// failure reads as a short list of rules to fix rather than hundreds of elements.
async function scanMotion(page: Page, reduced = false): Promise<MotionScan> {
  return page.evaluate(
    ({ scale, reducedMax, reducedMode }) => {
      const toMs = (token: string): number => {
        const value = token.trim();
        return value.endsWith("ms") ? parseFloat(value) : parseFloat(value) * 1000;
      };
      const durations = (raw: string): number[] => raw.split(",").filter((part) => part.trim() !== "").map(toMs);
      const onScale = (ms: number): boolean =>
        reducedMode ? ms <= reducedMax : scale.some((allowed) => Math.abs(ms - allowed) < 0.5);

      const pathOf = (element: Element): string => {
        const parts: string[] = [];
        let node: Element | null = element;
        for (let depth = 0; node && depth < 3; depth += 1, node = node.parentElement) {
          let part = node.tagName.toLowerCase();
          if (node.id) part += `#${node.id}`;
          const classes =
            typeof node.className === "string"
              ? node.className.trim().split(/\s+/).filter(Boolean).slice(0, 3).join(".")
              : "";
          if (classes) part += `.${classes}`;
          parts.unshift(part);
        }
        return parts.join(" > ");
      };

      const groups = new Map<string, { path: string; count: number }>();
      let scanned = 0;
      for (const element of Array.from(document.querySelectorAll("*"))) {
        for (const pseudo of [null, "::before", "::after"] as const) {
          const style = getComputedStyle(element, pseudo);
          scanned += 1;
          for (const [property, raw] of [
            ["transition-duration", style.transitionDuration],
            ["animation-duration", style.animationDuration]
          ] as const) {
            if (durations(raw).every(onScale)) continue;
            const key = `${property}: ${raw}`;
            const group = groups.get(key) ?? { path: `${pathOf(element)}${pseudo ?? ""}`, count: 0 };
            group.count += 1;
            groups.set(key, group);
          }
        }
      }

      const live = document
        .getAnimations()
        .filter((animation) => animation.playState !== "finished" && animation.playState !== "idle");
      const infinite = live
        .filter((animation) => animation.effect?.getComputedTiming().iterations === Infinity)
        .map((animation) => {
          const named = animation as unknown as { animationName?: string; transitionProperty?: string };
          return `${animation.constructor.name} ${named.animationName ?? named.transitionProperty ?? ""}`.trim();
        });

      return {
        scanned,
        offenders: Array.from(groups, ([key, group]) => `${group.path} (${group.count} element(s)) ${key}`),
        infinite,
        running: live.length
      };
    },
    { scale: SCALE_MS, reducedMax: REDUCED_MAX_MS, reducedMode: reduced }
  );
}

async function expectMotionContract(page: Page, label: string, reduced = false): Promise<void> {
  if (reduced) {
    // A reduced-motion transition is 0.01 ms long, so it can still be in flight for a frame.
    await expect
      .poll(async () => (await scanMotion(page, true)).running, {
        timeout: 5_000,
        message: `${label}: nothing may keep running under reduced motion`
      })
      .toBe(0);
  }

  const scan = await scanMotion(page, reduced);
  expect(scan.scanned, `${label}: the scan must read the page`).toBeGreaterThan(100);
  expect(scan.infinite, `${label}: no animation may loop`).toEqual([]);
  expect(
    scan.offenders,
    reduced
      ? `${label}: every duration must be at most ${REDUCED_MAX_MS}ms under reduced motion`
      : `${label}: every duration must be one of ${SCALE_MS.join(", ")} ms`
  ).toEqual([]);
}

async function gotoScreen(page: Page, screen: Screen): Promise<void> {
  await page.goto(screen.path);
  await waitForLiveConnected(page);
  await expect(page.getByRole("heading", { name: screen.heading, exact: true })).toBeVisible();
}

async function seedAndConfirm(request: APIRequestContext, scenario: SeedScenario): Promise<void> {
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

// Run a search so the toolbar offers Save search, then open its dialog.
async function openSaveDialog(page: Page): Promise<void> {
  await gotoScreen(page, SCREENS[4]);
  const query = page.getByLabel("Search text");
  await query.fill("quantum");
  await query.press("Enter");
  await expect(page.getByRole("heading", { name: "Results", exact: true })).toBeVisible();
  await page.locator("#search-save-new, #search-save-as").first().click();
  await expect(page.getByRole("dialog", { name: /^Save (search|as)$/ })).toBeVisible();
}

// The three interactions that open new surfaces. `check` runs once per state.
async function exerciseInteractions(
  page: Page,
  check: (label: string) => Promise<void>
): Promise<void> {
  await gotoScreen(page, SCREENS[1]);
  const refresh = page.locator("[data-ops-refresh]").first();
  await refresh.click();
  await check("Search health while refreshing");
  await expect(refresh).toBeEnabled({ timeout: 15_000 });
  await check("Search health after refresh");

  await openSaveDialog(page);
  await check("Search with the Save search dialog open");

  await openManageSavedSearches(page);
  await check("Search with the Manage saved searches sheet open");
}

test.describe("admin motion tokens — P-12", () => {
  test.describe.configure({ timeout: 240_000 });

  for (const mode of THEME_MODES) {
    for (const viewport of Object.keys(VIEWPORTS) as ViewportName[]) {
      const slug = `${themeSlug(mode)}, ${viewport}`;

      test(`[P-12] the six screens hold the motion scale and nothing loops (${slug})`, async ({
        browser,
        request
      }) => {
        await seedAndConfirm(request, "incident");
        const { page, close } = await newThemedPage(browser, mode, viewport, "no-preference");
        try {
          for (const screen of SCREENS) {
            await gotoScreen(page, screen);
            if (mode.kind === "system") await assertSystemDarkInvariants(page);
            await expectMotionContract(page, `${screen.name} (${slug})`);
          }
        } finally {
          await close();
        }
      });

      test(`[P-12] a refresh, the Save search dialog and the Manage sheet hold the scale (${slug})`, async ({
        browser,
        request
      }) => {
        await seedAndConfirm(request, "all_green");
        const { page, close } = await newThemedPage(browser, mode, viewport, "no-preference");
        try {
          await exerciseInteractions(page, (label) => expectMotionContract(page, `${label} (${slug})`));
        } finally {
          await close();
        }
      });

      test(`[P-12] reduced motion keeps every duration under 1ms and nothing running (${slug})`, async ({
        browser,
        request
      }) => {
        await seedAndConfirm(request, "all_green");
        const { page, close } = await newThemedPage(browser, mode, viewport, "reduce");
        try {
          await expect
            .poll(() => page.evaluate(() => window.matchMedia("(prefers-reduced-motion: reduce)").matches))
            .toBe(true);
          for (const screen of SCREENS) {
            await gotoScreen(page, screen);
            await expectMotionContract(page, `${screen.name} reduced (${slug})`, true);
          }
          await exerciseInteractions(page, (label) =>
            expectMotionContract(page, `${label} reduced (${slug})`, true)
          );
        } finally {
          await close();
        }
      });
    }
  }

  test("[P-12] the probe flags a planted off-scale duration, a planted loop and a planted 600ms duration", async ({
    browser,
    request
  }) => {
    await seedAndConfirm(request, "incident");
    const { page, close } = await newThemedPage(browser, THEME_MODES[0], "desktop", "no-preference");
    try {
      await gotoScreen(page, SCREENS[0]);
      await expectMotionContract(page, "Control Room before planting");

      await page.evaluate(() => {
        const style = document.createElement("style");
        style.textContent = `
          @keyframes p12-spin { to { transform: rotate(1turn); } }
          #p12-plant-duration { transition: opacity 150ms ease; }
          #p12-plant-loop { animation: p12-spin 240ms linear infinite; }
          #p12-plant-advance { transition: opacity 600ms ease; }`;
        document.head.appendChild(style);
        for (const id of ["p12-plant-duration", "p12-plant-loop", "p12-plant-advance"]) {
          const element = document.createElement("div");
          element.id = id;
          element.textContent = id;
          document.body.appendChild(element);
        }
      });

      const scan = await scanMotion(page);
      expect(scan.infinite.join(" ")).toContain("p12-spin");
      expect(scan.offenders.join("\n")).toContain("div#p12-plant-duration");
      expect(scan.offenders.join("\n")).toContain("transition-duration: 0.15s");
      expect(scan.offenders.join("\n")).toContain("div#p12-plant-advance");
      expect(scan.offenders.join("\n")).toContain("transition-duration: 0.6s");
      // 240ms is on the scale, so the looping element is caught by its iteration count, not its length.
      expect(scan.offenders.join("\n")).not.toContain("p12-plant-loop");

      // The global reduced-motion rule beats the planted rules: every planted duration collapses to
      // 0.01ms and the planted loop runs one iteration, so the reduced contract holds again.
      await page.emulateMedia({ reducedMotion: "reduce" });
      await expectMotionContract(page, "Control Room with the planted rules under reduced motion", true);
    } finally {
      await close();
    }
  });
});
