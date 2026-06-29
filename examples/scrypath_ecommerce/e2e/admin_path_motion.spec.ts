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
 *   3. Active-path trace/node glow: the merge-trace `.ops-path-trace` line-draw fires on
 *      hover only, and the active Playbook item carries `.ops-object-item-active`.
 *   4. NO LiveView patch-refire flicker (the Phase 123 A3 risk): toggling Search
 *      single↔multi mode and selecting Playbook A→B does NOT restart a running *keyframe*
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
  await expect(page.getByRole("heading", { name: "Search & federation" })).toBeVisible();
}

async function gotoPlaybooks(page: Page): Promise<void> {
  await page.goto("/admin/search/playbooks");
  await waitForLiveConnected(page);
  await expect(page.getByRole("heading", { name: "Saved playbooks" })).toBeVisible();
}

// Switch the Search playground into multi-index mode. This is a `push_patch`
// (search_live.ex handle_event "set_mode" -> push_patch mode: :multi) — the exact
// re-render that would replay an A3 mount-keyframe reveal across the results/merge region.
async function switchSearchMode(page: Page, mode: "single" | "multi"): Promise<void> {
  const label = mode === "multi" ? "Multi index" : "Single index";
  await page.getByRole("button", { name: label }).click();
}

async function runBoundedSearch(page: Page, query: string): Promise<void> {
  await page.getByLabel("Search text").fill(query);
  await page.getByRole("button", { name: "Run bounded search" }).click();
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
  // drives degraded posture so the recommended card (recommended={state in [:degraded,
  // :missing_backend]}) renders with its dual-dark glow.
  for (const theme of ALL_THEMES) {
    test(`recommended intent card: glow present + reduced-motion-neutralized (${theme})`, async ({
      browser,
      request
    }) => {
      await seedScenario(request, "incident");

      const { page, close } = await newThemedPage(browser, theme, { reducedMotion: "reduce" });
      try {
        await gotoControlRoom(page);

        // The recommended card is the incident intent (data-testid="intent-incident").
        const card = page.getByTestId("intent-incident");
        await expect(card).toBeVisible();
        await expect(card).toHaveClass(/ops-intent-card--recommended/);
        // Functional integrity under reduced motion: the "Start here" flag is present.
        await expect(card.locator(".ops-intent-card__flag")).toBeVisible();

        // Reduced-motion: the card's own transition (box-shadow/glow settle) is neutralized.
        const dur = await maxMotionDurationMs(page, '[data-testid="intent-incident"]');
        expect(dur, `recommended card motion duration under reduce (${theme})`).toBeLessThanOrEqual(0.02);

        // Dark expression present / light unchanged — the deterministic replacement for the
        // former subjective "deliberate in dark, no light regression" human read (D-02). The
        // glow is an end-state (box-shadow), so it is present even under reduced motion; it
        // just snaps in instead of fading. Token invariant first, then the element wiring.
        const token = await glowToken(page);
        const cardGlow = await glowBoxShadow(page, '[data-testid="intent-incident"]');
        if (theme === "light") {
          expect(token, "light --shadow-ops-glow must be the `none` no-op").toBe("none");
          expect(cardGlow, `recommended card must carry NO violet glow in ${theme} (light regression guard)`).not.toContain(GLOW_RGB);
        } else {
          expect(token, `${theme} --shadow-ops-glow must resolve to a real aura, not none`).not.toBe("none");
          expect(cardGlow, `recommended card must carry the violet glow in ${theme}`).toContain(GLOW_RGB);
        }

        await snap(page, `recommended-card--${theme}--reduced-motion`);
      } finally {
        await close();
      }
    });
  }

  // 2 + 3: Merge-trace .ops-path-trace line-draw (hover), evidence code blocks shimmer-OFF,
  // and the patch-refire probe across a single↔multi mode switch — dark AND light.
  for (const theme of INTERACTIVE_THEMES) {
    test(`search merge-trace: hover line-draw + shimmer-off evidence + no patch-refire (${theme})`, async ({
      browser,
      request
    }) => {
      const seed = await seedScenario(request, "all_green");
      // all_green leaves the live contract intact, so confirm the catalog is searchable
      // before driving the UI (mirrors the matrix spec's gate).
      if (seed.tenant_id) {
        await drainSearchQueue(request);
        await waitForSearchVisible(request, {
          tenantId: seed.tenant_id,
          query: "quantum",
          expectedName: "Quantum CyberPhone X"
        });
      }

      const { page, close } = await newThemedPage(browser, theme);
      try {
        await gotoSearch(page);

        // Switch to multi mode (push_patch) — the merge-trace .ops-path-trace only renders
        // in multi mode, once the multi result carries a merge projection.
        await switchSearchMode(page, "multi");
        await runBoundedSearch(page, "quantum");
        await expect(page.getByRole("heading", { name: "Results" })).toBeVisible();

        // The merge trace is the <details> disclosure carrying .ops-path-trace. Its
        // line-draw lives on ::after and fires on :hover only — never on (re)insertion.
        const trace = page.locator(".ops-path-trace").first();
        await expect(trace).toBeVisible();

        // Baseline: the path-motion anchor has NO running animation at rest (pure
        // transition, never @keyframes-on-mount). This is the pre-patch reference.
        expect(
          await runningKeyframeAnimationCount(page, ".ops-path-trace"),
          "running animations on .ops-path-trace at rest"
        ).toBe(0);

        // Evidence code blocks (search hit payloads) MUST be shimmer-off (D-04a/c): no
        // .ops-code-block--shimmer anywhere on the results page.
        await expect(page.locator(".ops-code-block--shimmer")).toHaveCount(0);

        // Hover the merge-trace affordance and assert the line-draw end state is reached
        // (::after transform settles from scaleX(0) to scaleX(1)).
        await expect
          .poll(() => pseudoScaleX(page, ".ops-path-trace", "::after"), {
            timeout: 5_000,
            message: `merge-trace ::after must rest collapsed before hover (${theme})`
          })
          .toBeLessThanOrEqual(0.01);
        await trace.hover();
        await expect
          .poll(() => pseudoScaleX(page, ".ops-path-trace", "::after"), {
            timeout: 5_000,
            message: `merge-trace ::after must draw to full scale on hover (${theme})`
          })
          .toBeGreaterThanOrEqual(0.99);

        // Patch-refire probe: toggle multi→single→multi. Each toggle is a push_patch that
        // re-renders the results/merge region. The trace anchor must not start a running
        // animation across the patch (pure transition ⇒ 0 before and after).
        await switchSearchMode(page, "single");
        await switchSearchMode(page, "multi");
        await runBoundedSearch(page, "quantum");
        await expect(page.getByRole("heading", { name: "Results" })).toBeVisible();
        await expect(page.locator(".ops-path-trace").first()).toBeVisible();
        const afterPatch = await runningKeyframeAnimationCount(page, ".ops-path-trace");
        expect(afterPatch, "running animations on .ops-path-trace after patch round-trip").toBe(0);

        await snap(page, `merge-trace-hover--${theme}`);
      } finally {
        await close();
      }
    });
  }

  // 3 + 4: Active Playbook item .ops-object-item-active moves on A→B selection with no
  // replayed reveal (patch-refire probe), dark AND light.
  for (const theme of INTERACTIVE_THEMES) {
    test(`playbooks: active-item glow moves A->B with no patch-refire (${theme})`, async ({
      browser,
      request
    }) => {
      await seedScenario(request, "all_green");

      const { page, close } = await newThemedPage(browser, theme);
      try {
        await gotoPlaybooks(page);

        // The catalog list renders selectable playbook rows; each row's "Load preview"
        // button selects that playbook (phx-click="load"), which re-renders the list with
        // the chosen row carrying .ops-object-item-active. (Use the exact "Load preview"
        // name — a substring "Load" also matches the unrelated "Reload playbooks" button.)
        // Need at least two catalog entries to move A->B.
        const loadButtons = page.getByRole("button", { name: "Load preview" });
        const count = await loadButtons.count();
        test.skip(count < 2, "needs >= 2 catalog playbooks to exercise A->B selection");

        // Select playbook A — exactly one row becomes active.
        await loadButtons.nth(0).click();
        await expect(page.locator(".ops-object-item-active")).toHaveCount(1);
        // Functional integrity: the active glow anchor is patch-safe (data-driven server
        // state class), so it carries no running animation.
        expect(
          await runningKeyframeAnimationCount(page, ".ops-object-item-active"),
          "running animations on active playbook item A"
        ).toBe(0);

        // Dark expression present / light unchanged on the active-path anchor (D-02): the
        // active-item glow carries --shadow-ops-glow only in dark/system-dark. Deterministic
        // proof of the same "no spurious glow in light" claim that was a human read. The
        // active class is present before its box-shadow transition settles, so poll the
        // computed end-state instead of sampling a single transition frame.
        await expectGlowSettled(page, ".ops-object-item-active", theme);

        await snap(page, `playbook-active-A--${theme}`);

        // Select playbook B — the active marker moves (push_patch re-render). Assert no
        // replayed reveal: still exactly one active item, and zero running animations on it.
        await loadButtons.nth(1).click();
        await expect(page.locator(".ops-object-item-active")).toHaveCount(1);
        expect(
          await runningKeyframeAnimationCount(page, ".ops-object-item-active"),
          "running animations on active playbook item after A->B patch"
        ).toBe(0);

        await snap(page, `playbook-active-B--${theme}`);
      } finally {
        await close();
      }
    });
  }
});
