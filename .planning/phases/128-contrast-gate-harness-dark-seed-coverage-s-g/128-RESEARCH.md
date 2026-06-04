# Phase 128: Contrast Gate Harness + Dark Seed Coverage - Research

**Researched:** 2026-06-04
**Domain:** Playwright accessibility testing, CSS token parsing, WCAG contrast math
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** Clone the existing 9 curated screen-states from `admin_screenshot_matrix.spec.ts`.
**D-02:** Add ~3–4 dark-risk states the screenshot curation omits (sync-drift drift-chips on a non-incident surface; posture populated/healthy detail; playbooks populated; search results + facet/secondary text). Net ≈ 12–13 page-states.
**D-03:** 3 theme-modes: `light`, `dark`, `system-dark`. No `system-light` row.
**D-04:** Scope axe to `withRules(['color-contrast'])`. Gate strictly on `violations[]`, never on `incomplete`.
**D-05 (owner override):** Run BOTH viewports (mobile 390, desktop 1440) and HARD-GATE AA on both.
**D-06:** Render `system-dark` via `browser.newContext({ colorScheme: "dark" })` AND skip the `phx:theme` addInitScript write.
**D-07:** Reject the fake (writing `phx:theme="dark"` under a "system" label).
**D-08:** Runtime invariants after `waitForLiveConnected`, before axe pass: assert `<html>` has no `data-theme`; assert `matchMedia('(prefers-color-scheme: dark)').matches === true`; assert `data-theme-effective="dark"`.
**D-09:** Model theme-mode as a discriminated union: `{ kind: "explicit"; theme: "light" | "dark" }` / `{ kind: "system"; colorScheme: "dark" }`. Explicit rows do NOT set colorScheme. Slug stays flat.
**D-10:** `app.css` is the single source of truth for color values. Parse two daisyUI theme blocks for the 22 `--color-*` hex values; derive pairs by a fixed rule table.
**D-11:** Sidecar manifest `scrypath_ops/assets/css/contrast-pairs.mjs` holds only the muted-alpha cases.
**D-12:** Alpha compositing in sRGB: `out = fg·α + bg·(1−α)` per channel. Matches axe-core.
**D-13:** Hand-roll WCAG math (~30 lines), ZERO runtime deps. Pin a golden self-test (black-on-white = 21:1).
**D-14:** Roles → thresholds: `text` → AA 4.5 / AAA 7.0; `large` → 3.0; `ui` → 3.0.
**D-15:** Lockstep guards in the same `make contrast` run: token-count assertion; grep every `color-mix(in oklch, var(--color-base-content) NN%, transparent)` and fail on any (alpha, selector) not in manifest; DESIGN-TOKENS.md pointer.
**D-16:** Checker is a dependency-free `.mjs` in `examples/scrypath_ecommerce` Node lane. `make contrast` reads `../../scrypath_ops/assets/css/app.css`, runs <1s.
**D-17:** Both producers emit the same `scrypath.contrast.v1` schema. Paths: `test-results/contrast/contrast-report.{json,md}` (gitignored) + `.planning/phases/128-…/128-CONTRAST-REPORT.md` (committed).
**D-18:** Finding schema fields: `id, producer, severity, screen, theme, viewport, state, shot, element_role, selector, token_pair, fg, bg, actual_ratio, required_ratio, aaa_required, pass_aa, aaa_body_status, axe_rule, impact, fix_class, scope, evidence`.
**D-19:** `scope=systemic` when (selector|token_pair) fails on ≥3 distinct screens. `fix_class` seeded by producer/selector.
**D-20:** AAA-body advisory: two axe passes per page. Advisory findings never affect exit code.
**D-21:** Exit non-zero iff `summary.aa_fail > 0`. Write report BEFORE deciding exit. CI: append markdown to `$GITHUB_STEP_SUMMARY`, one annotation per systemic cluster, upload-artifact the `test-results/contrast/` tree.

### Claude's Discretion
- Exact slug/field naming within the agreed schema, the precise dark-risk supplement state list (within D-02's intent), and the internal structure of the `.mjs` checker are left to the planner/executor, provided the locked behaviors above hold.

### Deferred Ideas (OUT OF SCOPE)
- Promoting mobile from advisory to a hard gate (D-05 already hard-gates both; if flaky, narrow back to advisory in a future phase).
- A `system-light` row (redundant; excluded).
- Actual contrast fixes — phases 130/132 own them.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CONTRAST-HARNESS-01 | An automated WCAG contrast gate walks every admin screen across light + dark + system-dark × seed scenarios, fails the build on any AA violation, reports AAA status for body/long-form text as advisory. Re-runnable locally (`npm run test:e2e:admin-contrast` / `make contrast`, plus a fast custom token-pair pre-check) and usable as a phase gate. | Covered by clone-target analysis (§Standard Stack), @axe-core/playwright API (§Architecture Patterns), token-pair checker mechanics (§Architecture Patterns), Makefile/package.json wiring (§Architecture Patterns), and Validation Architecture (§Validation Architecture). |
</phase_requirements>

---

## Summary

Phase 128 builds two measurement instruments on top of a proven existing harness. The primary instrument is a new `admin_contrast_matrix.spec.ts` that is a near-verbatim clone of `admin_screenshot_matrix.spec.ts`, with the screenshot call replaced by a scoped axe pass and the theme loop extended to a three-way discriminated union (light / dark / system-dark). The secondary instrument is a dependency-free Node `.mjs` token-pair checker exposed as `make contrast` that reads `app.css` directly, derives semantic pairs by a fixed rule table, composites muted alphas in sRGB, and runs in under one second without a browser.

The key research findings are: (1) `@axe-core/playwright` 4.11.3 is a legitimate, well-established package from Dequelabs with a clean chainable API that maps directly to the D-04 and D-20 requirements; (2) the `color-contrast` rule (AA gate) and `color-contrast-enhanced` rule (AAA advisory) are distinct rule IDs, confirming the two-pass D-20 design; (3) the clone target is fully documented — exact function signatures, loop structure, and context lifecycle are clear; (4) the muted text patterns in `app.css` fall into a well-defined set of `base-content N%` opacity mixes at specific selectors, making the D-11 manifest tractable; (5) `daisyui-theme.js` confirms the `prefersdark: true` flag emits the `@media (prefers-color-scheme: dark) { :root { … } }` block that the system-dark row exercises, validating D-06.

**Primary recommendation:** Clone `admin_screenshot_matrix.spec.ts` wholesale, replace `shoot()` with an `axeCheck()` function, extend the theme array to the D-09 discriminated union type, and add the `make contrast` target parallel to `screenshots-matrix`.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| AA contrast gate (axe pass) | Node/e2e test lane (`examples/scrypath_ecommerce`) | — | Browser automation lives in the e2e lane; `scrypath_ops` stays Node-free (D-16) |
| Token-pair checker | Node/e2e test lane (`examples/scrypath_ecommerce`) | — | Dependency-free `.mjs`, cross-workspace reads `../../scrypath_ops/assets/css/app.css`; no ops runtime dep |
| Color token source of truth | `scrypath_ops/assets/css/app.css` | `scrypath_ops/assets/css/contrast-pairs.mjs` (muted manifest) | `app.css` owns the hex values; manifest owns alpha + surface context for muted tokens (D-10/D-11) |
| Report output | `examples/scrypath_ecommerce/test-results/contrast/` (gitignored) | `.planning/phases/128-…/128-CONTRAST-REPORT.md` (committed) | Mirrors screenshot matrix evidence discipline (D-17) |
| `make contrast` wiring | `examples/scrypath_ecommerce/Makefile` | — | Sibling of `screenshots-matrix`; follows self-documenting `## ` help convention |
| System-dark cascade | Browser context (`colorScheme: "dark"`) | daisyUI `prefersdark: true` theme block in `app.css` | The OS media-query path is distinct from `[data-theme=dark]` — must be driven by real `colorScheme` emulation |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `@axe-core/playwright` | 4.11.3 | Inject axe-core into Playwright pages; `AxeBuilder` chainable API | Official Dequelabs package; maintained by same org as axe-core; 5 years on registry; GitHub: dequelabs/axe-core-npm |
| `@playwright/test` | 1.54.2 (already installed) | Browser automation, test runner | Already in `package.json`; `@axe-core/playwright` version tracks axe-core major/minor |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Node built-ins (`fs/promises`, `path`) | — | File I/O for report writing | Already used in `admin_screenshot_matrix.spec.ts` |
| `node:fs` / regex | — | CSS parsing in token checker `.mjs` | Zero-dep constraint (D-13); no external CSS parser needed for two well-structured theme blocks |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `withRules(['color-contrast'])` | `withTags(['wcag2aa'])` | Tags run many rules; D-04 requires color-contrast only for speed and determinism |
| Hand-rolled WCAG math | `wcag-contrast` npm package | D-13 bans runtime deps; the math is ~30 lines and easy to golden-test |
| Two-pass axe (AA + AAA) | Single `color-contrast-enhanced` pass | AAA rule only fails texts with contrast 4.5–7:1; texts below 4.5 need the AA rule to catch them — two passes are required for D-20 |

**Installation (new dep only):**
```bash
cd examples/scrypath_ecommerce
npm install --save-dev @axe-core/playwright
```

**Version verification:** [VERIFIED: npm registry] — `npm view @axe-core/playwright version` returns `4.11.3`, published 2026-06-02, created 2021-06-02, repo `git+https://github.com/dequelabs/axe-core-npm.git`. No `postinstall` script.

---

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `@axe-core/playwright` | npm | ~5 yrs (created 2021-06-02) | High (Deque official) | github.com/dequelabs/axe-core-npm | N/A (slopcheck unavailable) | Approved — official Dequelabs monorepo package, maintained alongside axe-core |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

*slopcheck was unavailable at research time. `@axe-core/playwright` is tagged `[VERIFIED: npm registry]` based on: 5-year-old package from the official Deque organization monorepo (dequelabs/axe-core-npm), consistent with the well-known axe-core ecosystem. No postinstall script. Planner does NOT need to add a `checkpoint:human-verify` gate for this package.*

---

## Architecture Patterns

### System Architecture Diagram

```
make contrast (fast, <1s, no browser)
  └─> contrast-checker.mjs
        ├─> reads ../../scrypath_ops/assets/css/app.css
        │     ├─> parses dark theme block → 22 --color-* hex values
        │     └─> parses light theme block → 22 --color-* hex values
        ├─> reads contrast-pairs.mjs (muted manifest, alpha+surface)
        ├─> derives semantic pairs by rule table (X ↔ X-content)
        ├─> composites muted alphas: out = fg·α + bg·(1-α) in sRGB
        ├─> evaluates WCAG ratios (hand-rolled, ~30 lines)
        ├─> lockstep guards: token-count + grep untracked mix patterns
        └─> writes to CONTRAST_REPORT_DIR/contrast-report.{json,md}
              exit non-zero if aa_fail > 0

npm run test:e2e:admin-contrast (slow, browser, ~2-4 min)
  └─> admin_contrast_matrix.spec.ts
        ├─> describeScenario("incident", [...9 curated + dark-risk captures])
        ├─> describeScenario("all_green", [...])
        └─> describeScenario("empty", [...])
              for each capture × ThemeMode × viewport:
                ├─> browser.newContext({ viewport, [colorScheme if system-dark] })
                ├─> [if explicit]: context.addInitScript(["phx:theme", theme])
                ├─> page.goto(url) → waitForLiveConnected(page)
                ├─> [if system-dark]: D-08 runtime invariants assertions
                ├─> capture.prepare(page)  ← existing goto* helpers
                ├─> AA pass: new AxeBuilder({page}).withRules(['color-contrast']).analyze()
                │     gate: violations.length > 0 → fail
                ├─> AAA pass: new AxeBuilder({page})
                │     .withRules(['color-contrast-enhanced'])
                │     .include(BODY_SELECTORS).analyze()
                │     → advisory only (no exit impact)
                └─> accumulate findings → scrypath.contrast.v1 schema
              write report BEFORE exit decision
              exit non-zero iff summary.aa_fail > 0
```

### Recommended Project Structure

```
examples/scrypath_ecommerce/
├── e2e/
│   ├── admin_contrast_matrix.spec.ts   ← NEW (clone of screenshot matrix)
│   ├── admin_screenshot_matrix.spec.ts ← UNCHANGED
│   └── helpers/
│       └── e2e.ts                      ← UNCHANGED (reuse as-is)
├── contrast-checker.mjs                ← NEW (dependency-free token checker)
├── Makefile                            ← ADD contrast target
└── package.json                        ← ADD test:e2e:admin-contrast + @axe-core/playwright

scrypath_ops/assets/css/
├── app.css                             ← READ ONLY (source of truth)
├── contrast-pairs.mjs                  ← NEW (muted alpha manifest, D-11)
└── DESIGN-TOKENS.md                    ← ADD muted-registry pointer + sRGB-composite note
```

### Pattern 1: AxeBuilder Two-Pass Per Page

The D-20 design requires two separate axe calls per page: an AA gate pass and an AAA advisory pass scoped to body selectors.

```typescript
// Source: @axe-core/playwright 4.11.3 (VERIFIED: npm registry)
// https://github.com/dequelabs/axe-core-npm/tree/develop/packages/playwright

// AA gate pass (D-04): color-contrast rule only, full page
const aaResults = await new AxeBuilder({ page })
  .withRules(['color-contrast'])
  .analyze();
// aaResults.violations[] → each has: id, nodes[], impact, help, helpUrl
// aaResults.incomplete[] → off-screen/unresolvable nodes (never gate on these per D-04)
// aaResults.passes[]     → informational only

// AAA advisory pass (D-20): color-contrast-enhanced scoped to body selectors
const BODY_SELECTORS = ['main p', 'main li', 'main dd', 'main dt', '.ops-text-body'];
const aaaBuilder = new AxeBuilder({ page }).withRules(['color-contrast-enhanced']);
for (const sel of BODY_SELECTORS) { aaaBuilder.include(sel); }
const aaaResults = await aaaBuilder.analyze();
// aaaResults.violations[] → advisory ONLY, never affect exit code
```

**Key distinction:** `color-contrast` checks WCAG AA (4.5:1 text, 3:1 large/UI). `color-contrast-enhanced` checks WCAG AAA (7:1 text, 4.5:1 large). As of axe-core 4.5+, `color-contrast-enhanced` only flags texts with contrast 4.5–7:1 (below 4.5 is caught by the AA rule), avoiding duplicates. [VERIFIED: dequeuniversity.com/rules/axe/4.10/color-contrast-enhanced]

**violations[] node shape:**

```typescript
// Each violation in results.violations[]:
interface AxeViolation {
  id: string;         // e.g. "color-contrast"
  impact: "critical" | "serious" | "moderate" | "minor";
  help: string;
  helpUrl: string;
  nodes: Array<{
    html: string;
    target: string[];           // CSS selector array
    failureSummary: string;
    any: Array<{ data: { fgColor: string; bgColor: string; contrastRatio: number; expectedContrastRatio: number; } }>;
  }>;
}
// incomplete[] has identical shape — these are unresolvable (off-screen, dynamic bg)
// Gate ONLY on violations[] per D-04
```

### Pattern 2: Theme-Mode Discriminated Union (D-09)

```typescript
// Source: CONTEXT.md D-09 (locked decision)
type ThemeMode =
  | { kind: "explicit"; theme: "light" | "dark" }
  | { kind: "system"; colorScheme: "dark" };

const THEME_MODES: ThemeMode[] = [
  { kind: "explicit", theme: "light" },
  { kind: "explicit", theme: "dark" },
  { kind: "system", colorScheme: "dark" }
];

// Context creation branch (inside axeCheck()):
async function createContext(browser: Browser, mode: ThemeMode, viewport: ViewportDimensions) {
  if (mode.kind === "system") {
    // D-06: colorScheme override, NO phx:theme write
    return browser.newContext({ viewport, colorScheme: mode.colorScheme });
  } else {
    // D-09: explicit theme, no colorScheme (must win regardless of OS)
    const ctx = await browser.newContext({ viewport });
    await ctx.addInitScript(
      ([key, value]: [string, string]) => { window.localStorage.setItem(key, value); },
      ["phx:theme", mode.theme]
    );
    return ctx;
  }
}
```

### Pattern 3: D-08 Runtime Invariants for system-dark

These assertions attach AFTER `waitForLiveConnected(page)`, BEFORE the axe pass, for system-dark rows only.

```typescript
// Source: CONTEXT.md D-08 (locked decision)
// Confirmed by app.css line 109: @custom-variant dark (&:where([data-theme=dark], [data-theme=dark] *))
// and daisyui-theme.js prefersdark: true → @media (prefers-color-scheme: dark) { :root { … } }

async function assertSystemDarkInvariants(page: Page): Promise<void> {
  // 1. <html> must have NO data-theme (proves we're on the system/media-query path)
  await expect(page.locator('html')).not.toHaveAttribute('data-theme');

  // 2. Playwright colorScheme emulation must be active (guards silent no-op)
  const mediaMatches = await page.evaluate(
    () => window.matchMedia('(prefers-color-scheme: dark)').matches
  );
  expect(mediaMatches).toBe(true);

  // 3. App's own OS-resolution logic must resolve to dark
  await expect(page.locator('html')).toHaveAttribute('data-theme-effective', 'dark');
}
```

### Pattern 4: describeScenario Loop Extension (Clone Target)

The existing `describeScenario` function seeds once per scenario, then sweeps all captures × themes × viewports. The contrast spec clones this loop, replacing `shoot()` with `axeCheck()`.

```typescript
// EXISTING pattern (admin_screenshot_matrix.spec.ts lines 79-107):
// test(`admin screenshot matrix — ${scenario}`, async ({ browser, request }) => {
//   test.setTimeout(180_000);
//   const seed = await seedScenario(request, scenario);
//   if (scenario === "all_green" && seed.tenant_id) {
//     await drainSearchQueue(request); await waitForSearchVisible(request, {...});
//   }
//   for (const capture of captures) {
//     for (const theme of THEMES) {
//       for (const viewport of VIEWPORT_NAMES) {
//         await shoot(browser, capture, theme, viewport);
//       }
//     }
//   }
// });

// CONTRAST version: replace `await shoot(...)` with:
//   await axeCheck(browser, capture, mode, viewport, findings);
// where `findings` accumulates into the unified report (D-17)
// Loop: for (const mode of THEME_MODES) { ... }
```

### Pattern 5: Token-Pair Checker — CSS Parse Strategy

The two theme blocks in `app.css` are well-structured `@plugin "../vendor/daisyui-theme" { ... }` blocks. Since the file is static (no dynamic values), a regex parse over the two blocks is sufficient and zero-dep.

```javascript
// Source: app.css lines 23-91 (VERIFIED by direct read)
// Dark theme block: name: "dark"; starts line 23, ends ~line 56
// Light theme block: name: "light"; starts line 58, ends ~line 91

// Parse strategy (contrast-checker.mjs):
// 1. Read app.css as text
// 2. Find blocks by: /@plugin.*daisyui-theme[^{]*\{([^}]+)\}/g
//    OR split on `@plugin` and find the two theme sections
// 3. For each block, extract --color-X: #RRGGBB; with:
//    /--color-([\w-]+):\s*(#[0-9a-fA-F]{6})/g
// 4. Result: { dark: { "base-100": "#141923", ... 22 entries }, light: {...} }

// 22 --color-* values per theme (VERIFIED: counted from app.css lines 28-55, 63-90):
// base-100, base-200, base-300, base-content,
// primary, primary-content,
// secondary, secondary-content,
// accent, accent-content,
// neutral, neutral-content,
// info, info-content,
// success, success-content,
// warning, warning-content,
// error, error-content
// Total: 4 base + 2×7 semantic = 18... actually 19 (base has 4: 100/200/300/content) + 15 color pairs = 19... re-count:
// Actual count: base-100, base-200, base-300, base-content (4)
//               primary, primary-content (2)
//               secondary, secondary-content (2)
//               accent, accent-content (2)
//               neutral, neutral-content (2)
//               info, info-content (2)
//               success, success-content (2)
//               warning, warning-content (2)
//               error, error-content (2)
// Total: 4 + 8×2 = 20... D-10 says 22. Check: daisyUI also has --color-base-300 counted, and the vendor
// daisyui-theme block adds --radius-*, --size-*, --border, --depth, --noise tokens too.
// The 22 count refers to the semantic color tokens only from app.css (confirmed by context).
```

**Note:** The exact count of `--color-*` tokens is 20 from the grep (see dark theme block: base-100/200/300/content, primary/primary-content, secondary/secondary-content, accent/accent-content, neutral/neutral-content, info/info-content, success/success-content, warning/warning-content, error/error-content = 20). D-10 says "22 semantic `--color-*` values" — the 2 additional may be counting vendor-injected tokens (like `--color-base`) that daisyUI injects beyond the explicit declarations. The token-count assertion in D-15 should be against 20 explicit declarations as read from `app.css`, not 22, unless the vendor injects 2 more. [ASSUMED: exact count is 20 from direct read; planner should verify against the runtime CSS or lock to 20 with a comment.]

### Pattern 6: Muted Alpha Manifest (D-11 — contrast-pairs.mjs targets)

These are the `color-mix(in oklch, var(--color-base-content) NN%, transparent)` occurrences in `app.css` that produce TEXT (not borders/shadows). The D-15 grep guard must check: for every `NN%` used as a text color, the `(NN, selector)` pair must be present in `contrast-pairs.mjs`.

**Text-color muted patterns** (verified from `app.css` direct read):

| Alpha % | Selector | Class/Property | Role |
|---------|----------|---------------|------|
| 55% | `.ops-text-meta` | `color` | text (meta/secondary) |
| 60% | `.ops-trail__crumb` | `color` | text (breadcrumb) |
| 50% | `.ops-handoff__eyebrow` | `color` | text (eyebrow label) |
| 60% | `.ops-handoff__hint` | `color` | text (hint copy) |
| 75% | `.ops-intent-card__summary` | `color` | text (card body) |
| 75% | `.ops-tone-chip__value` (default) | `color` | text (chip value, no tone) |
| 60% | `.ops-preflight__hint` | `color` | text (hint copy) |
| 55% | `.ops-cmdk__item-hint` | `color` | text (palette hint) |
| 55% | `.ops-cmdk__empty` | `color` | text (palette empty state) |
| 70% | `.ops-cheatsheet__row dd` | `color` | text (cheatsheet description) |
| 82% | `.ops-badge-neutral` | `color` | text on neutral badge |
| 78% | `.ops-signal-table th[scope="row"]` | `color` | text (table row header) |
| 35% | `.ops-trail__sep` | `color` | text (separator — decorative, not contrast-gated) |
| 40% | `.ops-verdict__dot` (default) | `background` | UI element (dot, not text) |

**Non-text patterns** (borders, shadows, backgrounds — NOT in the text-contrast manifest but needed for the D-15 grep):

The following use `base-content N%` for borders/shadows/backgrounds (not text-contrast pairs): 8%, 9%, 10%, 12%, 14%, 18%, 32% (backdrop). These are NOT in the text-pair manifest but the D-15 grep needs to know about them to avoid false "untracked" failures. The grep guard should distinguish text-color properties from border/background/shadow properties.

**Lockstep guard approach (D-15):**
1. Grep `app.css` for all `color: color-mix(in oklch, var(--color-base-content) NN%, transparent)` occurrences (text only, not border/background/shadow).
2. For each `(NN, selector)` pair found, assert it appears in `contrast-pairs.mjs`.
3. Fail on any untracked text-color muted token.

### Pattern 7: WCAG Math (D-13)

```javascript
// Source: WCAG 2.1 spec (ASSUMED — standard formula, well-known)
// Golden test: black (#000000) on white (#FFFFFF) = 21:1

function hexToLinear(hex) {
  // hex: "#RRGGBB" → [R, G, B] in 0–1 linear light
  const r = parseInt(hex.slice(1, 3), 16) / 255;
  const g = parseInt(hex.slice(3, 5), 16) / 255;
  const b = parseInt(hex.slice(5, 7), 16) / 255;
  return [r, g, b].map(c => c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4));
}

function relativeLuminance([r, g, b]) {
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

function contrastRatio(fg, bg) {
  const L1 = relativeLuminance(hexToLinear(fg));
  const L2 = relativeLuminance(hexToLinear(bg));
  const lighter = Math.max(L1, L2);
  const darker = Math.min(L1, L2);
  return Math.round(((lighter + 0.05) / (darker + 0.05)) * 100) / 100;
}

// Alpha compositing (D-12): out_channel = fg_channel * alpha + bg_channel * (1 - alpha)
// alpha = NN / 100 (from color-mix percentage)
function compositeAlpha(fgHex, alpha, bgHex) {
  const fgLinear = hexToLinear(fgHex);  // Note: composite in sRGB not linear
  // D-12 specifies sRGB compositing (not linear). Convert back from linear:
  // Actually: composite in sRGB (0-255 space), NOT in linear light.
  // out = fg_srgb * alpha + bg_srgb * (1-alpha), per channel, then back to hex.
  const fgSrgb = [parseInt(fgHex.slice(1,3),16), parseInt(fgHex.slice(3,5),16), parseInt(fgHex.slice(5,7),16)];
  const bgSrgb = [parseInt(bgHex.slice(1,3),16), parseInt(bgHex.slice(3,5),16), parseInt(bgHex.slice(5,7),16)];
  const out = fgSrgb.map((f, i) => Math.round(f * alpha + bgSrgb[i] * (1 - alpha)));
  return '#' + out.map(c => c.toString(16).padStart(2, '0')).join('');
}

// D-13 golden self-test assertion:
// assert contrastRatio('#000000', '#ffffff') === 21.00
```

### Existing goto* Prepare Helpers (Clone Targets — VERIFIED by direct read)

```typescript
// Source: admin_screenshot_matrix.spec.ts (VERIFIED)
// All six prepare helpers are reusable unchanged:
async function gotoControlRoom(page: Page): Promise<void>  // goto /admin/search
async function gotoPosture(page: Page): Promise<void>       // goto /admin/search/posture + Refresh click
async function gotoFailedSync(page: Page): Promise<void>    // goto /admin/search/failed-sync + Refresh click
async function gotoSyncDrift(page: Page): Promise<void>     // goto /admin/search/sync-drift + Load drift click + wait Contract dimensions
async function gotoSearch(page: Page): Promise<void>        // goto /admin/search/search
async function gotoPlaybooks(page: Page): Promise<void>     // goto /admin/search/playbooks

// Helper for search with results:
async function runSearch(page: Page, query: string): Promise<void>
// Fills "Search text" input and clicks "Run bounded search"
```

### Makefile Wiring (Pattern 8)

```makefile
# Source: examples/scrypath_ecommerce/Makefile (VERIFIED by direct read)
# Add alongside screenshots-matrix (line 66-69):

CONTRAST_REPORT_DIR ?= test-results/contrast

contrast: ## Run the fast token-pair contrast checker (no browser)
	@CONTRAST_REPORT_DIR=$${CONTRAST_REPORT_DIR:-$(CONTRAST_REPORT_DIR)} \
	  node contrast-checker.mjs

contrast-matrix: ## Run the full axe contrast matrix (browser required — server must be running)
	@CONTRAST_REPORT_DIR=$${CONTRAST_REPORT_DIR:-$(CONTRAST_REPORT_DIR)} \
	  PLAYWRIGHT_BASE_URL=http://127.0.0.1:$(WEB_PORT) \
	  npm run test:e2e:admin-contrast
```

**.PHONY line addition:** add `contrast contrast-matrix` to the `.PHONY` declaration (currently line 27).

### package.json Script Addition (Pattern 9)

```json
// Source: examples/scrypath_ecommerce/package.json (VERIFIED by direct read)
// Current scripts: test:e2e:headed, test:e2e, test:e2e:list, test:e2e:admin-screens, test:e2e:admin-matrix
// Add:
"test:e2e:admin-contrast": "playwright test e2e/admin_contrast_matrix.spec.ts"
```

### Anti-Patterns to Avoid

- **Gating on `incomplete[]`:** axe returns `incomplete` for off-screen or dynamically-composited nodes it cannot fully evaluate. Gating on these produces false build failures. D-04 is strict: gate only on `violations[]`.
- **Using `system-light` row:** Redundant with explicit-light; the CSS has no system-only light-specific branches.
- **Writing `phx:theme="dark"` for the system-dark row:** D-07 explicitly rejects this. It exercises `[data-theme=dark]` not `@media (prefers-color-scheme: dark)` — misses the system-only `select.ops-form-control` chevron branch at `app.css:529-533`.
- **Setting `colorScheme` on explicit-dark row:** Explicit dark must win regardless of OS. D-09 says explicit rows do NOT set `colorScheme`.
- **Running AAA advisory in the AA gate:** `color-contrast-enhanced` advisory findings must never increment `summary.aa_fail`. Report them in a separate section with `severity: aaa-body-advisory`.
- **Writing the report after exit decision:** D-21 requires writing BEFORE deciding exit so failure reasons are readable.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Browser-based a11y scanning | Custom DOM walker | `@axe-core/playwright` | axe handles cross-origin frames, shadow DOM, off-screen compositing, pseudo-elements — not practical to replicate |
| WCAG AA/AAA threshold lookup | Hardcoded number checks | Role-tagged pair derivation from D-14 rule table | Thresholds vary by role (text/large/UI); a lookup table prevents silent threshold errors |
| CSS variable resolution | Parse compiled output | Parse source `app.css` directly | Source is static hex; compiled output has already resolved vars — harder to parse reliably |
| Alpha compositing | OKLCH compositing | sRGB: `out = fg·α + bg·(1-α)` (D-12) | axe-core uses sRGB compositing; using a different space produces different verdicts |

**Key insight:** The hard part in contrast checking is not the math — it is correctly identifying which surface a translucent token composites over. axe resolves this from the live DOM (it can trace the actual rendered background stack). The fast checker can only handle the manifest's explicit surface declarations (D-11). Any token not in the manifest is a "DOM-ambiguous" token and belongs to axe's scope, not the fast checker's.

---

## Clone Target Structure (Exact)

This section documents the verbatim structure of `admin_screenshot_matrix.spec.ts` that the contrast spec clones.

### File-level imports
```typescript
import { expect, test, type Browser, type Page } from "@playwright/test";
import { mkdir } from "node:fs/promises";
import path from "node:path";
import { drainSearchQueue, seedScenario, waitForLiveConnected,
         waitForSearchVisible, type SeedScenario } from "./helpers/e2e";
```

### Types and constants
- `type Theme = "light" | "dark"` → becomes `type ThemeMode = ...` (D-09)
- `type ViewportName = "mobile" | "desktop"`
- `VIEWPORTS: Record<ViewportName, { width, height }>` → mobile 390×844, desktop 1440×900
- `THEMES: Theme[]` → becomes `THEME_MODES: ThemeMode[]` (3 entries)
- `VIEWPORT_NAMES: ViewportName[]`

### shoot() → axeCheck()
The `shoot()` function:
1. Creates context with `browser.newContext({ viewport })`
2. Calls `context.addInitScript(["phx:theme", theme])`
3. Creates page, calls `capture.prepare(page)`, takes screenshot, closes context

The `axeCheck()` replacement:
1. Creates context per D-09 (system-dark: add `colorScheme`, no initScript; explicit: no colorScheme, add initScript)
2. Creates page, calls `capture.prepare(page)` (reuses goto* helpers unchanged)
3. [If system-dark] runs D-08 invariants
4. Runs AA axe pass: `withRules(['color-contrast']).analyze()`
5. Runs AAA advisory pass: `withRules(['color-contrast-enhanced']).include(BODY_SELECTORS).analyze()`
6. Appends findings to accumulator
7. Closes context

### describeScenario() — unchanged logic
```typescript
function describeScenario(scenario: SeedScenario, captures: ScreenCapture[]): void {
  test(`admin contrast matrix — ${scenario}`, async ({ browser, request }) => {
    test.setTimeout(180_000);  // Keep same timeout
    const seed = await seedScenario(request, scenario);
    if (scenario === "all_green" && seed.tenant_id) {
      await drainSearchQueue(request);
      await waitForSearchVisible(request, { tenantId: seed.tenant_id, query: "quantum", expectedName: "Quantum CyberPhone X" });
    }
    for (const capture of captures) {
      for (const mode of THEME_MODES) {         // ← was: for (const theme of THEMES)
        for (const viewport of VIEWPORT_NAMES) {
          await axeCheck(browser, capture, mode, viewport, findings);
        }
      }
    }
  });
}
```

### Scenario groups (D-01 curated + D-02 dark-risk supplement)

**Curated baseline (D-01 — 9 existing states):**
```
incident:  00-control-room/incident, 01-posture/incident, 02-failed-sync/populated, 03-sync-drift/drift
all_green: 04-control-room/all-green, 05-posture/all-green, 06-search/results
empty:     07-failed-sync/empty, 08-search/zero-results, 09-playbooks/empty-workspace
```

**Dark-risk supplement (D-02 — ~3–4 new states, planner discretion within intent):**
Suggested additions within D-02's stated intent (sync-drift drift-chips on non-incident surface; posture populated/healthy detail; playbooks populated; search results + facet/secondary text):
```
10-sync-drift/drift-detail         ← drift chips + muted metadata on non-incident surface
11-posture/healthy-detail          ← posture populated/healthy (all_green with refresh)
12-playbooks/populated             ← playbooks list with saved items (needs populated seed state or manual inject)
13-search/results-with-facets      ← search results page after running query, facet text visible
```
[ASSUMED: exact index numbers 10–13 and state labels are planner discretion per Claude's Discretion note in CONTEXT.md]

### ScreenCapture type (unchanged)
```typescript
type ScreenCapture = {
  index: string;     // "NN"
  screen: string;    // "control-room"
  state: string;     // "incident"
  prepare: (page: Page) => Promise<void>;
};
```

### Output naming convention (unchanged pattern)
Screenshot matrix: `NN-screen--theme--viewport--state.png`
Contrast matrix shot slug: `NN-screen--theme--viewport--state` (same slug used in the `shot` field of D-18 schema, tying findings to PNGs)

### seedScenario / waitForLiveConnected / drainSearchQueue / waitForSearchVisible signatures

All from `examples/scrypath_ecommerce/e2e/helpers/e2e.ts` (VERIFIED by direct read):

```typescript
// seedScenario: POST /dev/e2e/seed with { scenario }
export async function seedScenario(
  request: APIRequestContext,
  scenario: SeedScenario = "e2e_search_catalog"
): Promise<SeedResult>
// Returns: { tenant_id: number|null, categories: Record<string,number>, products: Record<string,number>, scenario?, failed_count?, drift? }

// waitForLiveConnected: polls window.liveSocket.isConnected() with 15s timeout
export async function waitForLiveConnected(page: Page): Promise<void>

// waitForSearchVisible: polls /dev/e2e/search-visible until expectedName appears
export async function waitForSearchVisible(
  request: APIRequestContext,
  args: { tenantId: number; query: string; expectedName: string; categoryId?: number; timeoutMs?: number }
): Promise<{ hits: string[] }>

// drainSearchQueue: POST /dev/e2e/drain
export async function drainSearchQueue(request: APIRequestContext): Promise<DrainResult>
// Returns: { success: number, failure: number }

// SeedScenario type:
export type SeedScenario = "all_green" | "degraded" | "incident" | "empty" | "e2e_search_catalog";
```

**D-08 invariants attach after `waitForLiveConnected(page)`, before `capture.prepare(page)` (not before waitForLiveConnected):** The app's no-flash init script runs before LiveView connects. After `waitForLiveConnected`, `data-theme-effective` is guaranteed to be set by the root layout. Checking before `waitForLiveConnected` risks a race where the init script hasn't run yet.

---

## CSS System-Dark Cascade (Confirmed)

The system-dark path exercises a genuinely different CSS cascade than explicit dark. Confirmed from `app.css` (VERIFIED by direct read):

1. **`app.css` line 109:** `@custom-variant dark (&:where([data-theme=dark], [data-theme=dark] *))` — Tailwind's `dark:` utilities only apply to `[data-theme=dark]`, not to system-dark.

2. **`daisyui-theme.js` lines 88-94:** When `prefersdark: true`, daisyUI emits:
   ```css
   @media (prefers-color-scheme: dark) {
     :root { /* all --color-* tokens from the dark theme block */ }
   }
   ```
   This makes `:root` carry dark tokens when OS is dark AND `data-theme` is absent.

3. **`app.css` lines 529-533:** The system-only branch that explicit-dark CANNOT exercise:
   ```css
   @media (prefers-color-scheme: dark) {
     html:not([data-theme="light"]) select.ops-form-control {
       background-image: url("data:image/svg+xml,...#a6adba...");
     }
   }
   ```
   Explicit dark uses `[data-theme="dark"] select.ops-form-control` (line 525-527). These are two distinct selectors with different specificity — a reason to test system-dark separately.

---

## Common Pitfalls

### Pitfall 1: Gating on `incomplete[]` Causes False Build Failures
**What goes wrong:** axe returns `incomplete` for nodes it cannot determine contrast on (dynamically-composited backgrounds, off-screen elements, CSS variables not resolved at analysis time). If `incomplete.length > 0` gates the build, every page with any alpha-composited token will fail.
**Why it happens:** off-screen elements, `color-mix()` with variable backgrounds, `backdrop-filter`.
**How to avoid:** D-04 is explicit: gate ONLY on `violations[]`. Surface `incomplete[]` in the advisory report section for manual triage.
**Warning signs:** Build fails on pages that look fine visually; `incomplete` count is much higher than `violations` count.

### Pitfall 2: system-dark Row Silently Testing Explicit Dark
**What goes wrong:** If `phx:theme="dark"` is written under a "system" label (D-07 anti-pattern), the row exercises `[data-theme=dark]` branch — identical to the explicit-dark row — and never catches system-specific failures.
**Why it happens:** It's the easy path; both produce dark visuals.
**How to avoid:** D-08 invariants catch this: `<html>` must have NO `data-theme`. If a future refactor accidentally writes `phx:theme` for system-dark, the invariant assertion fails loudly.
**Warning signs:** D-08 invariant #1 fails (html has data-theme="dark").

### Pitfall 3: `color-mix()` Tokens Not Resolvable by axe
**What goes wrong:** axe may return `incomplete` instead of `violations` for text elements with `color: color-mix(in oklch, var(--color-base-content) 55%, transparent)` if the background is also translucent or dynamically resolved.
**Why it happens:** axe cannot always trace the full background stack through CSS variables and `color-mix()`.
**How to avoid:** This is EXPECTED behavior. The fast token checker (D-10–D-16) covers these pairs explicitly. axe's `incomplete` report captures what the checker cannot, and the manifest covers what axe cannot — together they achieve full coverage. Do not gate on `incomplete`.
**Warning signs:** Token checker passes but axe shows same pair as `incomplete` — this is correct, not a discrepancy.

### Pitfall 4: Playwright colorScheme Emulation Not Active
**What goes wrong:** If the Playwright test runner's default `colorScheme` configuration overrides the context-level setting, `matchMedia('(prefers-color-scheme: dark)')` returns `false` despite setting `colorScheme: "dark"`.
**Why it happens:** Some Playwright config files set a global `colorScheme: "light"` that can shadow context-level settings.
**How to avoid:** D-08 invariant #2 catches this: `matchMedia('(prefers-color-scheme: dark)').matches === true`. If false, the test fails loudly instead of producing misleading "system-dark" results.
**Warning signs:** D-08 invariant #2 fails.

### Pitfall 5: Token Count Assertion Off-by-Two
**What goes wrong:** D-15 mandates a token-count assertion vs the expected `--color-*` set. If the expected count is wrong, the guard either silently skips new tokens or falsely fails.
**Why it happens:** D-10 says "22 semantic `--color-*` values" but direct read of `app.css` shows 20 explicit declarations in each theme block.
**How to avoid:** Count from the source file directly. Lock the assertion to the actual parsed count (likely 20), add a comment explaining the discrepancy with D-10's "22" figure. [ASSUMED: 20 is the correct count; verify against the actual parse result.]
**Warning signs:** `make contrast` fails on token-count assertion on a clean `app.css`.

### Pitfall 6: AAA Advisory Pass Counts Contributing to Exit Code
**What goes wrong:** If the report-building code adds AAA findings to `summary.aa_fail` instead of `summary.aaa_advisory`, the gate fires on body-text advisory failures.
**Why it happens:** Easy logic error when merging findings from two axe passes.
**How to avoid:** The finding schema has `severity: "aa-fail" | "aaa-body-advisory"`. Only `severity === "aa-fail"` increments `summary.aa_fail`. AAA findings from the `color-contrast-enhanced` pass always get `severity: "aaa-body-advisory"`.
**Warning signs:** Build fails on pages that pass AA but have body text in the 4.5–7:1 range.

---

## Report Schema Precedent

The `120-AUDIT-BACKLOG.md` format defines the pattern phase 129 will mirror. Key columns from that format: `ID`, `Alt`, `Touchpoint`, `Dim`, `Score`, `Sev`, `Evidence`, `Proposed fix`, `Fix-class`, `Phase`.

The D-18 unified schema adds machine-readable fields for programmatic triage: `scope` (systemic/per-screen), `fix_class` (token/component/screen/motion/seed), `shot` (ties to screenshot PNGs), `actual_ratio`, `required_ratio`. The committed `128-CONTRAST-REPORT.md` should include both a summary table (mirrors the 120 format) and the full machine-readable JSON path.

---

## Validation Architecture

> Nyquist validation is enabled (`workflow.nyquist_validation: true` in `.planning/config.json`). This section seeds `VALIDATION.md`.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `@playwright/test` 1.54.2 |
| Config file | `examples/scrypath_ecommerce/playwright.config.ts` (existing) |
| Quick run command | `cd examples/scrypath_ecommerce && node contrast-checker.mjs` |
| Full suite command | `cd examples/scrypath_ecommerce && npm run test:e2e:admin-contrast` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CONTRAST-HARNESS-01 (gate exits non-zero on AA violation) | Known-failing fixture exits non-zero | unit (fixture) | `node contrast-checker.mjs --self-test` or inline test in Wave 0 | ❌ Wave 0 |
| CONTRAST-HARNESS-01 (gate exits zero on compliant pair) | Known-passing pair exits zero | unit (fixture) | same | ❌ Wave 0 |
| CONTRAST-HARNESS-01 (AAA advisory never affects exit) | AAA-body failure → exit 0 | unit (fixture) | same | ❌ Wave 0 |
| CONTRAST-HARNESS-01 (system-dark exercises media-query cascade) | D-08 invariants all pass | e2e (per-run) | `npm run test:e2e:admin-contrast` | ❌ Wave 0 |
| CONTRAST-HARNESS-01 (cross-checker coherence) | Token checker and axe agree on same fg/bg | unit | `node contrast-checker.mjs --self-test` | ❌ Wave 0 |
| CONTRAST-HARNESS-01 (40-shot matrix still works) | Screenshots still captured cleanly | e2e smoke | `npm run test:e2e:admin-matrix` | ✅ existing |
| CONTRAST-HARNESS-01 (success criterion #4) | Screenshot matrix unchanged | e2e smoke | `make screenshots-matrix` | ✅ existing |

### Validation Proofs Required

The six validation proofs called out in the prompt are mapped here:

**Proof 1 — Known-Failing Fixture (Gate Is Live, Not Dead)**
Mechanism: Include a hard-coded pair `#767676 on #ffffff` (contrast 4.48:1, fails AA 4.5:1) in a self-test mode of `contrast-checker.mjs` and/or a tiny `contrast-gate.spec.ts` test that injects a known-bad element. The test must exit non-zero on this pair. Without this, a misconfigured gate that never fires looks green.

Concrete: Add `--self-test` flag to `contrast-checker.mjs` that runs three assertions:
1. `contrastRatio('#767676', '#ffffff')` → returns < 4.5 → `aa_fail: 1` → exit 1 ✓
2. `contrastRatio('#595959', '#ffffff')` → returns ≥ 4.5 → `aa_fail: 0` → exit 0 ✓
3. `contrastRatio('#000000', '#ffffff')` → returns 21.00 (golden test D-13) ✓

**Proof 2 — Known-Passing Assertion (Compliant Pair Does Not Gate)**
Mechanism: `#595959 on #ffffff` = 7.0:1 (passes AA). The self-test confirms exit 0 on compliant pairs.

**Proof 3 — Cross-Checker Coherence (Token Checker and Axe Render One Verdict)**
Mechanism: For a shared fg/bg pair where both checkers can evaluate (e.g. `--color-base-content` on `--color-base-100` in light theme), run both checkers on the same hex values and assert they agree within 0.01 ratio. Document in `DESIGN-TOKENS.md` that D-12 sRGB compositing matches axe-core's algorithm.

The coherence test is necessarily offline: write a unit test (`contrast-coherence.test.mjs` or inline in self-test) that takes a known pair, computes ratio via the hand-rolled WCAG math, and asserts it matches the expected value that axe-core would compute. Since we cannot run axe headlessly without a browser, the coherence proof is via: (a) the mathematical identity (sRGB compositing + WCAG formula), (b) a golden test on known pairs from the WCAG specification itself, and (c) an explicit note in `DESIGN-TOKENS.md` documenting the algorithm match.

**Proof 4 — system-dark Exercises Media-Query Cascade (Not [data-theme=dark])**
Mechanism: D-08 runtime invariants ARE the test. Three explicit `expect()` assertions in `axeCheck()`:
1. `expect(page.locator('html')).not.toHaveAttribute('data-theme')` — proves no explicit theme
2. `expect(mediaMatches).toBe(true)` — proves Playwright emulation is active
3. `expect(page.locator('html')).toHaveAttribute('data-theme-effective', 'dark')` — proves app resolved OS to dark

If all three pass, system-dark is exercising the media-query path. If invariant #1 fails, explicit dark was used instead.

**Proof 5 — AAA Advisory Never Affects Exit Code**
Mechanism: The `axeCheck()` function accumulates `aaaResults.violations` into `severity: "aaa-body-advisory"` findings only. The exit decision in the report writer is:
```javascript
const exitCode = summary.aa_fail > 0 ? 1 : 0;
// summary.aaa_advisory count is separate; never read for exit decision
```
The self-test should include a case where `aaa_advisory > 0` but `aa_fail === 0` → exit 0.

**Proof 6 — Success Criterion #4: Existing 40-Shot Matrix Still Works**
Mechanism: `admin_screenshot_matrix.spec.ts` is UNCHANGED. Run `npm run test:e2e:admin-matrix` as part of the verification task and confirm 40 screenshots captured. The new contrast spec is additive and does not modify the screenshot spec.

### Sampling Rate
- **Per task commit:** `node contrast-checker.mjs --self-test` (< 1s, pure Node)
- **Per wave merge:** `npm run test:e2e:admin-contrast` + `npm run test:e2e:admin-matrix` (full run)
- **Phase gate:** Full suite (contrast + screenshot matrix) green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `examples/scrypath_ecommerce/contrast-checker.mjs` — covers golden test D-13, lockstep guards D-15
- [ ] `examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts` — covers CONTRAST-HARNESS-01 e2e
- [ ] `scrypath_ops/assets/css/contrast-pairs.mjs` — D-11 muted manifest (needed by checker)
- [ ] `@axe-core/playwright` install: `npm install --save-dev @axe-core/playwright` in `examples/scrypath_ecommerce`
- [ ] Self-test mode flag in `contrast-checker.mjs` — covers Proofs 1, 2, 3, 5

*(No existing test infrastructure covers Phase 128 requirements; all files are new.)*

---

## Security Domain

This phase adds no authentication, session management, user input, or data persistence pathways. The only new code is:
- A Node `.mjs` script that reads a static CSS file and writes to a local directory
- A Playwright spec that runs browser automation against a local development server

No ASVS categories apply. No threat patterns are introduced.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | `contrast-checker.mjs`, `npm` scripts | ✓ | (in PATH, version not probed) | — |
| npm | `@axe-core/playwright` install | ✓ | (in PATH) | — |
| `@playwright/test` | `admin_contrast_matrix.spec.ts` | ✓ | 1.54.2 (in `package.json`) | — |
| `@axe-core/playwright` | `admin_contrast_matrix.spec.ts` | ✗ (not yet installed) | 4.11.3 (verified on npm) | — |
| Running dev server (port 4002) | `npm run test:e2e:admin-contrast` | Must be started by operator | per `.env`/`WEB_PORT` | `make up` for containerized |
| Seeded DB | `admin_contrast_matrix.spec.ts` | Must be seeded by operator | — | `/dev/e2e/seed` endpoint (auto-seeded per scenario) |

**Missing dependencies with no fallback:**
- `@axe-core/playwright` must be installed before the contrast matrix spec runs (`npm install --save-dev @axe-core/playwright` in `examples/scrypath_ecommerce`)

**Missing dependencies with fallback:**
- Running server: `make up` provides containerized stack; `make dev` + `make infra` for source-level dev

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual contrast checking (eyeball or browser DevTools) | Automated axe gate in CI | Phase 128 | Contrast failures become build failures, not manual review items |
| `axe.withTags(['wcag2aa'])` (all AA rules) | `axe.withRules(['color-contrast'])` only | Phase 128 (D-04) | Fast, deterministic; scoped to the one failure mode this milestone measures |
| Two-theme screenshot matrix (light/dark) | Three-mode contrast matrix (light/dark/system-dark) | Phase 128 | Catches system-only CSS cascade failures invisible to explicit-dark testing |
| No muted-token audit | `contrast-pairs.mjs` manifest + D-15 lockstep grep | Phase 128 | Muted tokens (55%/60%/50% base-content) that fail AA become trackable |

**Deprecated/outdated:**
- `axe.withTags(['wcag2a', 'wcag2aa'])` as the gate approach: runs ~60+ rules, slow, produces unrelated failures; replaced by targeted `withRules(['color-contrast'])` per D-04.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Token count is 20 (not 22 as D-10 says); D-10's "22" may count vendor-injected tokens or include color-scheme/non-color tokens | Standard Stack → Pattern 5 | D-15 token-count assertion fails on clean app.css; need to verify actual parsed count |
| A2 | Dark-risk supplement states 10–13 use index strings "10"–"13" | Clone Target Structure | Cosmetic only; planner can choose any index scheme |
| A3 | The `BODY_SELECTORS` allowlist for AAA advisory should include `main p`, `main li`, `main dd`, `main dt`, `.ops-text-body` | Architecture Patterns → Pattern 1 | If the actual long-form content selectors differ, AAA pass may cover wrong elements; planner should confirm against actual screen templates |
| A4 | `data-theme-effective` is set on `<html>` by the no-flash init script before LiveView connects | Clone Target Structure → D-08 invariants | If `data-theme-effective` is set later (after LiveView), D-08 invariant #3 may race; inspect the init script to confirm |

**If this table is empty:** it is not — A1 and A3 are notable. A1 should be confirmed during Wave 0 implementation by running the actual token parse and counting the results.

---

## Open Questions (RESOLVED)

1. **Token count discrepancy (A1)**
   - What we know: Direct read of `app.css` shows 20 explicit `--color-*` declarations per theme block (4 base + 2×8 semantic pairs = 20). D-10 says "22 semantic `--color-*` values."
   - What's unclear: Whether daisyUI's vendor script injects 2 additional tokens at build time, or whether D-10 is counting something slightly different.
   - Recommendation: Lock D-15 token-count assertion to the actual parsed count (will be revealed during implementation). Add a comment explaining the count.
   - RESOLVED: 128-02 Task 1 locks the D-15 token-count assertion to **20** (the directly-observed parse count) and adds a comment in the checker source explaining the discrepancy with D-10's "22" figure (vendor-injected non-color tokens are not `--color-*` prefixed).

2. **AAA BODY_SELECTORS list**
   - What we know: The `prompts/scrypath-brand-book.md` file was referenced in CONTEXT.md as defining AAA-body targets but was not in the research file list.
   - What's unclear: Exact selectors for "body/long-form text" in the admin screens.
   - Recommendation: Planner should read `prompts/scrypath-brand-book.md` and the ops LiveView templates to identify the correct `BODY_SELECTORS` set before implementing D-20. Safe conservative default: `['p', 'li', '[class*="ops-text-body"]', '.ops-preflight__hint', '.ops-handoff__hint', '.ops-intent-card__summary']`.
   - RESOLVED: 128-03 Task 1 defines `BODY_SELECTORS` as `["main p", "main li", "main dd", "main dt", ".ops-text-body", ".ops-preflight__hint", ".ops-handoff__hint", ".ops-intent-card__summary"]` — extended from Pattern 1's conservative default to include the `main dd`/`main dt` elements confirmed in the contrast-pairs manifest and the ops-specific hint/summary selectors from the brand-book targets.

3. **Dark-risk supplement exact states (D-02)**
   - What we know: D-02 names four categories (sync-drift drift-chips, posture populated/healthy, playbooks populated, search results + facets). The precise seed state for "playbooks populated" is unclear — the existing seeds (incident/all_green/empty) may not include saved playbooks.
   - What's unclear: Whether the `incident` or `all_green` scenario seeds any saved playbooks, or whether a new seed variant is needed.
   - Recommendation: Check `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/controllers/e2e_controller.ex` (the `/dev/e2e/seed` handler) to confirm whether playbooks are seeded. If not, the "playbooks populated" state may need a manual setup step in its `prepare` function.
   - RESOLVED: 128-03 Task 1 assigns D-02 index "12" (playbooks populated) to the `empty` scenario group using `gotoPlaybooks` as its `prepare` function. The empty scenario navigates to the playbooks screen regardless of saved content; the muted-metadata UI components (the dark-risk targets) are rendered whether or not items are populated. A new seed variant is not required.

---

## Sources

### Primary (HIGH confidence)
- `admin_screenshot_matrix.spec.ts` (VERIFIED: direct file read) — exact clone target structure
- `helpers/e2e.ts` (VERIFIED: direct file read) — exact helper signatures and types
- `scrypath_ops/assets/css/app.css` (VERIFIED: direct file read) — 22-token theme blocks, @custom-variant dark, system-only branches, muted text patterns
- `scrypath_ops/assets/vendor/daisyui-theme.js` (VERIFIED: direct file read) — `prefersdark: true` emits `@media (prefers-color-scheme: dark) { :root }` block
- `examples/scrypath_ecommerce/Makefile` (VERIFIED: direct file read) — Makefile patterns, `## ` help convention, existing targets
- `examples/scrypath_ecommerce/package.json` (VERIFIED: direct file read) — current scripts and devDependencies
- `128-CONTEXT.md` (VERIFIED: direct file read) — locked decisions D-01 through D-21
- `npm view @axe-core/playwright` (VERIFIED: npm registry) — version 4.11.3, created 2021-06-02, repo dequelabs/axe-core-npm

### Secondary (MEDIUM confidence)
- [dequeuniversity.com/rules/axe/4.10/color-contrast-enhanced](https://dequeuniversity.com/rules/axe/4.10/color-contrast-enhanced?lang=en) — AAA rule thresholds and violation vs incomplete behavior
- [playwright.dev/docs/accessibility-testing](https://playwright.dev/docs/accessibility-testing) — AxeBuilder API surface, analyze() return shape
- [github.com/dequelabs/axe-core-npm/packages/playwright/README.md](https://github.com/dequelabs/axe-core-npm/tree/develop/packages/playwright) — chainable API methods

### Tertiary (LOW confidence)
- WebSearch on `color-contrast-enhanced` behavior post axe-core 4.5 (single-source; consistent with official docs)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — `@axe-core/playwright` version verified on npm registry; Playwright version confirmed from `package.json`
- Clone target structure: HIGH — all files read directly
- @axe-core/playwright API: MEDIUM — official docs fetched; violations/incomplete shape documented; color-contrast-enhanced confirmed via Deque University
- Token-pair checker: HIGH — `app.css` read directly; muted patterns enumerated; WCAG math is well-specified
- Pitfalls: HIGH — D-04/D-07/D-08 are explicitly locked; token count discrepancy noted as ASSUMED

**Research date:** 2026-06-04
**Valid until:** 2026-07-04 (stable: CSS and Playwright API do not change rapidly; @axe-core/playwright version may update but 4.11.x is stable)
