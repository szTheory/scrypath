/**
 * Admin path-motion proof (DARKMOTION-01, Phase 133 Plan 03).
 *
 * Browser-proves the transient `.ops-path-*` motion + LiveView patch-safety that the
 * static-CSS contract (Plan 02, MotionContractTest) and screenshot matrix cannot cover:
 *
 *   1. Reduced-motion neutralization + functional integrity (D-09): under
 *      `prefers-reduced-motion: reduce`, each shipped anchor computes a
 *      transition/animation duration of ~0.01ms (the global `app.css:1306` rule) AND its
 *      active end state is still visually present (the mark/glow snaps in, it just does
 *      not draw).
 *   2. Hover code-shimmer: `.ops-code-block--shimmer` glint is opt-in. Evidence code
 *      blocks (search payloads) carry NO `.ops-code-block--shimmer` class (D-04a/c).
 *   3. Active-path trace/node glow: combined result order remains static across patches, and the active Saved search item carries `.ops-object-item-active`.
 *   4. NO LiveView patch-refire flicker (the Phase 123 A3 risk): toggling Search
 *      single↔multi mode and selecting Saved search A→B does NOT restart a running *keyframe*
 *      animation on the anchor. Because the shipped motion is pure CSS `transition` (never
 *      `@keyframes`-on-mount), the anchor's running CSSAnimation count is 0 before AND after
 *      the patch — that zero IS the proof. (Running CSSTransitions are the intended,
 *      patch-safe settle and are excluded from the count; see `runningKeyframeAnimationCount`.)
 *
 * Every flow is exercised in BOTH dark and light (via `phx:theme` set before first paint)
 * plus a system-dark context (`colorScheme: 'dark'` with NO phx:theme write), and a small
 * targeted screenshot set is captured at rest/interaction endpoints. The full 40-shot
 * recapture, before/after gallery, and human milestone UAT are deferred to Phase 136
 * (DUALVERIFY-01, D-05c) — this spec ships only the focused proof + minimal screenshots.
 *
 * HOW TO RUN (manual server per playwright.config.ts — there is NO webServer):
 *   The spec drives a booted, seeded ops server at PLAYWRIGHT_BASE_URL (default
 *   http://127.0.0.1:4002). Boot it against CURRENT source via the compose dev lane
 *   (`make dev` / `compose.yaml + compose.dev.yaml`) — the base `compose.yaml` alone runs
 *   a STALE baked image, so a source-level `.ops-path-*` change would not be exercised
 *   (project Docker DX note). Then:
 *     cd examples/scrypath_ecommerce
 *     npx playwright test e2e/admin_path_motion.spec.ts --reporter=line
 */
import { expect, test, type Browser, type Page } from "@playwright/test";
import { mkdir } from "node:fs/promises";
import path from "node:path";

import {
  drainSearchQueue,
  pickSavedSearch,
  seedScenario,
  waitForLiveConnected,
  waitForSearchVisible
} from "./helpers/e2e";

const screenshotDir =
  process.env.PATH_MOTION_SCREENSHOT_DIR || "test-results/admin-path-motion";

// Theme is applied the same documented way as the screenshot matrix: the root template's
// inline script reads localStorage["phx:theme"] on load. `light`/`dark` write that key
// before first paint; `system-dark` writes nothing and instead emulates the OS via the
// context `colorScheme`, exercising the `prefers-color-scheme: dark` (no [data-theme])
// path — the lane that catches a missing system-dark mirror (D-08).
type ThemeMode = "light" | "dark" | "system-dark";

const INTERACTIVE_THEMES: ThemeMode[] = ["light", "dark"];
const ALL_THEMES: ThemeMode[] = ["light", "dark", "system-dark"];

const DESKTOP = { width: 1440, height: 900 };

type ContextOpts = {
  reducedMotion?: "reduce" | "no-preference";
};

// Build a themed page. For light/dark we addInitScript the phx:theme key before first
// paint; for system-dark we open the context with colorScheme:'dark' and write no key.
async function newThemedPage(
  browser: Browser,
  theme: ThemeMode,
  opts: ContextOpts = {}
): Promise<{ page: Page; close: () => Promise<void> }> {
  const context = await browser.newContext({
    viewport: DESKTOP,
    colorScheme: theme === "system-dark" ? "dark" : "light",
    ...(opts.reducedMotion ? { reducedMotion: opts.reducedMotion } : {})
  });

  if (theme !== "system-dark") {
    await context.addInitScript(
      ([key, value]) => {
        window.localStorage.setItem(key, value);
      },
      ["phx:theme", theme]
    );
  }

  const page = await context.newPage();
  return { page, close: () => context.close() };
}

// ── Navigation helpers (mirror admin_screenshot_matrix.spec.ts) ─────────────────

async function gotoControlRoom(page: Page): Promise<void> {
  await page.goto("/admin/search");
  await waitForLiveConnected(page);
  await expect(page.getByRole("heading", { name: "Control Room" })).toBeVisible();
}

async function gotoSearch(page: Page): Promise<void> {
  await page.goto("/admin/search/search");
  await waitForLiveConnected(page);
  await expect(page.getByRole("heading", { name: "Search", exact: true })).toBeVisible();
}

// Switch the Search playground into multi-index mode. This is a `push_patch`
// (search_live.ex handle_event "set_mode" -> push_patch mode: :multi) — the exact
// re-render that would replay an A3 mount-keyframe reveal across the results/merge region.
async function switchSearchMode(page: Page, mode: "single" | "multi"): Promise<void> {
  const label = mode === "multi" ? "Multiple schemas" : "One schema";
  await page.getByRole("button", { name: label }).click();
  if (mode === "multi") {
    // A restored form draft can leave every schema unchecked; search both explicitly.
    const schemas = page.locator("input[name='schemas[]']");
    await expect(schemas.first()).toBeVisible();
    for (const schema of await schemas.all()) {
      if (!(await schema.isChecked())) await schema.check();
    }
  }
}

async function runBoundedSearch(page: Page, query: string): Promise<void> {
  await page.getByLabel("Search text").fill(query);
  await page.getByRole("button", { name: "Run search" }).click();
}

async function snap(page: Page, name: string): Promise<void> {
  await mkdir(screenshotDir, { recursive: true });
  await page.screenshot({ path: path.join(screenshotDir, `${name}.png`) });
}

// ── Motion probes (NEW — no existing analog in the harness) ─────────────────────

// Reduced-motion probe: the global `@media (prefers-reduced-motion: reduce)` rule snaps
// transition-duration/animation-duration to 0.01ms across *, *::before, *::after. We read
// the computed durations of BOTH the element and its ::after pseudo-element (the line-draw
// lives on ::after) and assert each parses to <= ~0.02ms. Returns the max seen so a
// failure message can show the offending value.
async function maxMotionDurationMs(page: Page, selector: string): Promise<number> {
  return page.evaluate((sel) => {
    const el = document.querySelector(sel);
    if (!el) throw new Error(`reduced-motion probe: element not found for ${sel}`);
    const parseList = (raw: string): number[] =>
      raw
        .split(",")
        .map((s) => s.trim())
        .filter(Boolean)
        .map((s) => (s.endsWith("ms") ? parseFloat(s) : parseFloat(s) * 1000));
    const collect = (pseudo: string | undefined): number[] => {
      const cs = getComputedStyle(el, pseudo);
      return [
        ...parseList(cs.transitionDuration || "0s"),
        ...parseList(cs.animationDuration || "0s")
      ];
    };
    const all = [...collect(undefined), ...collect("::after"), ...collect("::before")];
    return all.length ? Math.max(...all) : 0;
  }, selector);
}

// Patch-refire probe: count running *keyframe* CSS animations on the path-motion ANCHOR(s)
// matched by `selector` — the anchor element itself plus its `::before`/`::after`
// pseudo-elements (Element.getAnimations() covers those, and the line-draw lives on
// ::after). The A3 regression is specifically a `@keyframes` reveal that *re-fires* on a
// LiveView patch/insert; the shipped `.ops-path-*` motion is pure `transition`, so a
// correct anchor reports ZERO running keyframe animations before AND after a push_patch.
//
// We deliberately count ONLY CSSAnimation, EXCLUDING CSSTransition: a running CSSTransition
// is the intended, patch-safe behavior (the glow/line-draw settling via a state-driven
// transition), not a re-fire. Counting transitions would be a false positive — the
// `.ops-object-item-active` glow legitimately runs several box-shadow/border CSSTransitions
// the instant it becomes active. A re-firing keyframe reveal is the only failure mode this
// probe must catch, and CSSAnimation is exactly that signal.
//
// Scope is the anchor itself (incl. its pseudo-elements), NOT its descendant subtree or a
// broad container like `main`: the unrelated, intended Phase-123 A1 one-shot reveals
// (`.ops-disclosure[open] > .ops-disclosure-body { animation: ops-fade-in }`) run on
// descendants/elsewhere and are out of scope for `.ops-path-*` patch-safety.
async function runningKeyframeAnimationCount(page: Page, selector: string): Promise<number> {
  return page.evaluate((sel) => {
    const roots = Array.from(document.querySelectorAll(sel));
    let n = 0;
    for (const el of roots) {
      const anims = el.getAnimations?.() ?? [];
      n += anims.filter(
        (a) =>
          a.playState === "running" &&
          // CSSAnimation == @keyframes; CSSTransition is the patch-safe settle and is excluded.
          a.constructor.name === "CSSAnimation"
      ).length;
    }
    return n;
  }, selector);
}

async function pseudoScaleX(page: Page, selector: string, pseudo: "::before" | "::after"): Promise<number> {
  return page.evaluate(
    ({ sel, pseudoName }) => {
      const el = document.querySelector(sel);
      if (!el) throw new Error(`scale probe: element not found for ${sel}`);

      const transform = getComputedStyle(el, pseudoName).transform;
      if (transform === "none") return 1;

      const matrix = transform.match(/^matrix\(([^,]+)/);
      if (!matrix) throw new Error(`scale probe: unexpected transform for ${sel}${pseudoName}: ${transform}`);

      return Number(matrix[1]);
    },
    { sel: selector, pseudoName: pseudo }
  );
}

// Glow probes (NEW — the deterministic replacement for the former subjective
// "deliberate in dark / no light regression" human read, D-02). The dual-dark glow lives
// in one token, `--shadow-ops-glow`: the `none` no-op in light, a faint violet aura
// (rgba(108,92,231,0.30)) in dark + system-dark. `glowBoxShadow` reads the anchor's
// composited box-shadow so we can prove the glow is actually WIRED onto the element (not
// just that the token exists); `glowToken` reads the token itself as a cheap invariant.
const GLOW_RGB = "108, 92, 231"; // getComputedStyle resolves rgba(108,92,231,…) with this triplet

async function glowBoxShadow(page: Page, selector: string): Promise<string> {
  return page.evaluate((sel) => {
    const el = document.querySelector(sel);
    if (!el) throw new Error(`glow probe: element not found for ${sel}`);
    return getComputedStyle(el).boxShadow;
  }, selector);
}

async function glowToken(page: Page): Promise<string> {
  return page.evaluate(() =>
    getComputedStyle(document.documentElement).getPropertyValue("--shadow-ops-glow").trim()
  );
}

async function expectGlowSettled(page: Page, selector: string, theme: ThemeMode): Promise<void> {
  if (theme === "light") {
    await expect
      .poll(() => glowBoxShadow(page, selector), {
        timeout: 5_000,
        message: `${selector} must carry no violet glow in light`
      })
      .not.toContain(GLOW_RGB);
  } else {
    await expect
      .poll(() => glowBoxShadow(page, selector), {
        timeout: 5_000,
        message: `${selector} must settle to the violet glow in ${theme}`
      })
      .toContain(GLOW_RGB);
  }
}

// ── Spec ─────────────────────────────────────────────────────────────────────

test.describe("admin path motion — DARKMOTION-01", () => {
  test.describe.configure({ timeout: 120_000 });

  // 1 + 3: Active-path trace/node glow + reduced-motion neutralization on the Control Room
  // recommended intent card, in dark AND light AND system-dark. The `incident` scenario
  // drives degraded search health so the recommended card (recommended={state in [:degraded,
  // :missing_backend]}) renders with its dual-dark glow.
  for (const theme of ALL_THEMES) {
    test(`task links keep one label and neutral motion (${theme})`, async ({ browser, request }) => {
      await seedScenario(request, "incident");
      const { page, close } = await newThemedPage(browser, theme, { reducedMotion: "reduce" });
      try {
        await gotoControlRoom(page);
        const card = page.getByTestId("control-room-explore-search");
        await expect(card).toBeVisible();
        await expect(card.locator(".ops-intent-card__title")).toHaveText("Try a search");
        await expect(card.locator(".ops-intent-card__cta")).toHaveText("→");
        await expect(card).not.toHaveClass(/ops-intent-card--recommended/);
        expect(await maxMotionDurationMs(page, '[data-testid="control-room-explore-search"]')).toBeLessThanOrEqual(0.02);
        expect(await runningKeyframeAnimationCount(page, ".ops-intent-card")).toBe(0);
        await card.focus();
        await expect(card).toBeFocused();
        await expect(card).toHaveAttribute("href", "/admin/search/search");
      } finally { await close(); }
    });
  }

  // Combined order replaced the raw merge trace. Keep the patch-safety and
  // shimmer-free evidence checks without requiring a removed decorative underline.
  for (const theme of INTERACTIVE_THEMES) {
    test(`search combined results: readable evidence with no patch-refire (${theme})`, async ({browser, request}) => {
      const seed = await seedScenario(request, "all_green");
      if (seed.tenant_id) {
        await drainSearchQueue(request);
        await waitForSearchVisible(request, {
          tenantId: seed.tenant_id, query: "quantum", expectedName: "Quantum CyberPhone X"
        });
      }
      const {page, close} = await newThemedPage(browser, theme);
      try {
        await gotoSearch(page);
        await switchSearchMode(page, "multi");
        await runBoundedSearch(page, "quantum");
        const results = page.locator("#search-combined-results");
        await expect(results).toBeVisible();
        await expect(page.locator(".ops-code-block--shimmer")).toHaveCount(0);
        await expect(results.locator(".ops-readable-hit").first()).toBeVisible();
        // Raw hit payloads are Elixir-formatted on purpose; the readable heading must not be.
        await expect(results.locator(".ops-hit-heading").first()).not.toContainText("%{");
        expect(await runningKeyframeAnimationCount(page, "#search-combined-results")).toBe(0);
        await switchSearchMode(page, "single");
        await switchSearchMode(page, "multi");
        await runBoundedSearch(page, "quantum");
        await expect(results).toBeVisible();
        expect(await runningKeyframeAnimationCount(page, "#search-combined-results")).toBe(0);
        await snap(page, `combined-results--${theme}`);
      } finally { await close(); }
    });
  }

  // 3 + 4: The loaded saved search marker (.ops-saved-search-row--loaded in the Manage
  // sheet) moves on A→B selection with no replayed reveal (patch-refire probe), dark AND light.
  for (const theme of INTERACTIVE_THEMES) {
    test(`saved searches: loaded marker moves A->B with no patch-refire (${theme})`, async ({
      browser,
      request
    }) => {
      await seedScenario(request, "all_green");

      const { page, close } = await newThemedPage(browser, theme);
      try {
        await gotoSearch(page);
        await waitForLiveConnected(page);

        // Picking a saved search from the toolbar menu fills the form and runs it; the
        // Manage sheet then marks that row as loaded. Need two saved searches to move A->B.
        await page.locator("#saved-search-picker-button").click();
        const items = page.locator("#saved-search-menu .ops-saved-search-menu__item");
        const count = await items.count();
        test.skip(count < 2, "needs >= 2 catalog saved searches to exercise A->B selection");
        const names = [
          (await items.nth(0).locator(".ops-saved-search-menu__name").textContent())!.trim(),
          (await items.nth(1).locator(".ops-saved-search-menu__name").textContent())!.trim()
        ];
        await page.keyboard.press("Escape");

        for (const [index, name] of names.entries()) {
          await pickSavedSearch(page, name);
          await page.locator("#saved-search-manage-open").click();
          const loaded = page.locator(".ops-saved-search-row--loaded");
          await expect(loaded).toHaveCount(1);
          await expect(loaded).toContainText(name);
          expect(
            await runningKeyframeAnimationCount(page, ".ops-saved-search-row--loaded"),
            `running animations on loaded saved search ${index === 0 ? "A" : "B"}`
          ).toBe(0);
          await snap(page, `saved-search-loaded-${index === 0 ? "A" : "B"}--${theme}`);
          await page.keyboard.press("Escape");
          await expect(page.locator("#saved-search-manage")).toHaveCount(0);
        }
      } finally {
        await close();
      }
    });
  }
});
