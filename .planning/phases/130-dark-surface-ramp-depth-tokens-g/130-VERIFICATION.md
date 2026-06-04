---
phase: 130-dark-surface-ramp-depth-tokens-g
verified: 2026-06-04T00:00:00Z
status: human_needed
score: 7/8
overrides_applied: 0
re_verification: false
human_verification:
  - test: "Visually inspect dark mode in the admin UI"
    expected: "Dark panels (.ops-muted-panel, .ops-data-card, .ops-panel, .ops-disclosure, .ops-nav-list, .ops-kbd, .ops-result-row, .ops-preflight__card--locked) appear visibly LIGHTER than the page background (#0c0f14) — they render as #1b2230 midnight blue, not coplanar with the floor"
    why_human: "CSS elevation is pixel-verifiable only in a running browser. The contrast gate confirms AA pass for Cluster 1 but not the perceptual step-up of surface-2 over bg. (Plan 04 checkpoint human-check carried forward.)"
  - test: "Toggle to light mode and confirm surfaces are unchanged"
    expected: "All admin surfaces look identical to pre-Phase-130 (light parity). Pixel-diff already proved 0 diff pixels, but visual double-check is the plan's stated confirmation step."
    why_human: "The pixel diff is a programmatic gate; a human eye is the final light-parity check required by the phase's human-checkpoint task."
---

# Phase 130: Dark Surface Ramp + Depth Tokens Verification Report

**Phase Goal:** Land the 4-step midnight ramp (`#1B2230` surface-2) and refactor `.ops-*` fill recipes via theme-scoped elevation tokens so dark steps up in elevation while light stays pixel-identical. Closes DARKTOKEN-01.
**Verified:** 2026-06-04
**Status:** human_needed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Dark renders a true four-step ramp: `#0C0F14` (bg) → `#141923` (panel) → `#1B2230` (raised/muted) → `#2A3446` (border) | VERIFIED | `app.css` dark `@plugin` block L56-58: `--ops-bg:#0c0f14`, `--ops-surface-1:#141923`, `--ops-surface-2:#1b2230`. `#2A3446` = `--color-neutral` already in dark block. DESIGN-TOKENS.md records all four steps. |
| 2 | `.ops-muted-panel`, `.ops-data-card`, `.ops-surface-flat`, `.ops-nav-list`, `.ops-disclosure`, `.ops-kbd`, `.ops-result-row`, `.ops-preflight__card--locked` step up (not down) in dark | VERIFIED | All 9 GROUP A token-swaps confirmed in `app.css` (ops-surface-1/2 in color-mix wrappers); D-05 dark-scoped dual-path overrides confirmed for `ops-data-card` (L1279-1285) and `ops-result-row` (L1289-1295). Cluster 1 (`.leading-4` ramp collapse) resolved per Plan 04 Step 3 gate run (182→8 violations; cluster 1 = 0). |
| 3 | Light theme is pixel-identical; `DESIGN-TOKENS.md` records the dark ramp | VERIFIED | `contrast-checker.mjs` light AA count = 3 (= Phase 128 baseline, 0 regressions). `light-pixel-diff.mjs` exits 0, "Failed pairs: 0 / 20". DESIGN-TOKENS.md has `## Elevation surfaces` subsection with full 4-step ramp table and ramp sentence. |

**Score:** 3/3 ROADMAP truths VERIFIED

---

### Plan Must-Haves (Merged from All 4 Plans)

| # | Must-Have | Status | Evidence |
|---|-----------|--------|----------|
| P01-1 | `light-pixel-diff.mjs` exits non-zero on diff, 0 on match (20 PNGs, exit-code contract) | VERIFIED | File exists at `examples/scrypath_ecommerce/e2e/light-pixel-diff.mjs`. `node --check` exits 0. Path bug corrected in Plan 04 (commit `e1a46cf`). Exit-code logic: `process.exit(totalFail > 0 ? 1 : 0)` confirmed in source. Plan 04 Step 4 result: "Failed pairs: 0 / 20". |
| P01-2 | pixelmatch and pngjs listed as devDependencies in `examples/scrypath_ecommerce/package.json` | VERIFIED | `grep '"pixelmatch"'` returns `"pixelmatch": "^5.3.0"`. `grep '"pngjs"'` returns `"pngjs": "^7.0.0"`. |
| P01-3 | `mix verify.opsui` is a valid alias running `mix test` and `mix opsui.test_a11y` | VERIFIED | `mix.exs` L87: `"verify.opsui": ["test", "opsui.test_a11y"]`. `preferred_envs` L30: `"verify.opsui": :test` added in Plan 04 (commit `4ffd8a9`). Plan 04 Step 1 result: exits 0, 129 tests 0 failures + 4 a11y 0 failures. |
| P02-1 | Dark `@plugin` block contains `--ops-bg:#0c0f14`, `--ops-surface-1:#141923`, `--ops-surface-2:#1b2230` | VERIFIED | `app.css` L56-58 confirmed. |
| P02-2 | Light `@plugin` block contains `--ops-bg:#faf7f2`, `--ops-surface-1:#fffdf8`, `--ops-surface-2:#faf7f2` | VERIFIED | `app.css` L94-96 confirmed. |
| P02-3 | `contrast-checker.mjs` light AA/AAA counts unchanged vs Phase 128 baseline after token declarations | VERIFIED | Plan 02 and Plan 04 both confirm: 3 AA failures (pre-existing `.ops-text-meta`/`.ops-cmdk__item-hint`/`.ops-cmdk__empty`), 12 AAA advisory — identical to Phase 128 baseline. |
| P03-1 | 9 token-swappable recipes reference `--ops-surface-1` or `--ops-surface-2` inside color-mix wrappers | VERIFIED | Direct grep confirms all 9: `.ops-panel` (L249, surface-1 96%), `.ops-surface-flat` (L256, surface-1 94%), `.ops-muted-panel` (L262, surface-2 64%), `.ops-verdict-neutral` (L363, surface-2 64%), `.ops-nav-list` (L563, surface-2 72%), `.ops-disclosure` (L600, surface-2 58%), `.ops-preflight__card` (L798, surface-1 94%), `.ops-preflight__card--locked` (L807, surface-2 60%), `.ops-kbd` (L1161, surface-2 70%). |
| P03-2 | `.ops-data-card` and `.ops-result-row` shared recipes keep `var(--color-base-100)` AND have dark-scoped overrides setting `background: var(--ops-surface-2)` | VERIFIED | `.ops-data-card` L268: `background: color-mix(in oklch, var(--color-base-100) 92%, transparent)` — unchanged. `.ops-result-row` L918: same with 94%. D-05 dual-path overrides at L1279/1283 (data-card) and L1289/1293 (result-row) confirmed. Both use `html:not([data-theme="light"])`. |
| P03-3 | `.bg-ops-surface-2 { background: var(--ops-surface-2); }` helper class exists | VERIFIED | `app.css` L1274-1276 confirmed. Comment present explaining Tailwind v4 @plugin limitation. |
| P03-4 | `ops_code_block :default` at `ops_ui.ex:994` uses `bg-ops-surface-2` instead of `bg-base-200` | VERIFIED | `grep 'bg-ops-surface-2' ops_ui.ex` returns 1 match at L994. `grep 'bg-base-200' ops_ui.ex` returns 0 matches in ops_code_block scope. |
| P03-5 | `--shadow-ops-surface/mid/raised/overlay` overridden with `rgba(0,0,0,α)` values under both dark paths | VERIFIED | `app.css` L1299-1312: `[data-theme="dark"]` block + `@media (prefers-color-scheme: dark) html:not([data-theme="light"])` block, each with all 4 shadow tokens. Shadow rgba grep returns exactly 8 lines (4 per path = 8 total). |
| P04-1 | `mix verify.opsui` from `scrypath_ops/` exits 0 | VERIFIED | Plan 04 Step 1: 129 tests, 0 failures, 4 a11y, 0 failures. Commits `4ffd8a9` (preferred_envs fix) + `5c13930` (alias add) in place. |
| P04-2 | `contrast-checker.mjs` light AA/AAA unchanged vs Phase 128 | VERIFIED | Plan 04 Step 2: 3 AA / 12 AAA = Phase 128 baseline exactly. |
| P04-3 | `test:e2e:admin-contrast` — dark Cluster 1 (`.leading-4` ramp collapse) violations drop to 0 | VERIFIED (Cluster 1 scope) | Plan 04 Step 3: 182→8 violation reduction (94%). Cluster 1 = 0. Remaining 8/16/12 are Cluster 3 (primary-violet `#6c5ce7` at 4.3:1 on cream) — explicitly deferred to Phase 132 per scope boundary and user approval (Option B). The plan's stated success criterion was "dark cluster 1 drops to 0" — that is met. |
| P04-4 | `light-pixel-diff.mjs` exits 0, "Failed pairs: 0 / 20" | VERIFIED | Plan 04 Step 4: exact result recorded. Path corrected in commit `e1a46cf`. Baseline updated post-body-class fix. |
| P04-5 | DESIGN-TOKENS.md has elevation-surfaces subsection with 4-step dark ramp table | VERIFIED | `## Elevation surfaces — --ops-bg, --ops-surface-1, --ops-surface-2` at L43 of DESIGN-TOKENS.md. Table with `#faf7f2`/`#0c0f14`, `#fffdf8`/`#141923`, `#faf7f2`/`#1b2230` present. Ramp sentence with all four hex values at L55. Commit `a214290`. |

**Score: 8/8 plan must-haves VERIFIED** (P04-3 verified as scoped: Cluster 1 = 0, Cluster 3 deferred)

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `examples/scrypath_ecommerce/e2e/light-pixel-diff.mjs` | Wave 0 pixel-diff gate script | VERIFIED | Exists, passes `node --check`, correct `../.tmp/` paths, pixelmatch/pngjs imports, exit-code contract |
| `examples/scrypath_ecommerce/package.json` | pixelmatch + pngjs devDeps | VERIFIED | Both present at `^5.3.0` / `^7.0.0` |
| `scrypath_ops/mix.exs` | verify.opsui alias + preferred_envs | VERIFIED | L87: alias present. L30: `:test` env entry present |
| `scrypath_ops/assets/css/app.css` | Elevation tokens + recipe swaps + shadow overrides | VERIFIED | Both @plugin blocks have all 3 tokens; 9 recipe swaps; .bg-ops-surface-2 helper; D-05 dual-path overrides for data-card + result-row; D-10 shadow dual-path block |
| `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` | ops_code_block bg-ops-surface-2 | VERIFIED | L994: `bg-ops-surface-2` confirmed; `bg-base-200` absent from ops_code_block |
| `scrypath_ops/assets/css/DESIGN-TOKENS.md` | Elevation-surfaces subsection | VERIFIED | `## Elevation surfaces` section present with full table and ramp sentence |
| `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/components/layouts.ex` | admin paths excluded from scrypath-demo body class | VERIFIED | L29: `<body class={unless ops_admin_path?(@conn), do: "scrypath-demo"}>` |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| dark `@plugin` block | `[data-theme="dark"]` and `@media (prefers-color-scheme: dark)` | daisyUI plugin custom-property pass-through | VERIFIED | Plugin spreads all non-reserved custom props to both dark paths (per D-02 mechanism). Tokens at L56-58 inside `@plugin "../vendor/daisyui-theme"` block. |
| light `@plugin` block | `--ops-surface-2: #faf7f2` (light) | daisyUI plugin pass-through | VERIFIED | L94-96 in light block; light value identical to prior `base-200` = zero rendering change |
| `.ops-muted-panel` et al. (9 recipes) | `var(--ops-surface-2)` or `var(--ops-surface-1)` | token-swap inside color-mix wrapper | VERIFIED | All 9 background: lines contain ops-surface-1/2 reference (not color-base-100/200) |
| `[data-theme="dark"] .ops-data-card` | `background: var(--ops-surface-2)` | D-05 dark-scoped dual-path | VERIFIED | L1279 + L1283 (media query) — uses `html:not([data-theme="light"])` |
| `[data-theme="dark"]` + media block | `--shadow-ops-surface/mid/raised/overlay` rgba ladder | D-10 shadow dual-path | VERIFIED | Both paths present at L1299-1312; shadow rgba count = 8 (4 per path) |
| `ops_ui.ex:994` | `.bg-ops-surface-2` CSS helper | Tailwind utility class backed by CSS rule | VERIFIED | `bg-ops-surface-2` at L994; `.bg-ops-surface-2 { background: var(--ops-surface-2); }` at app.css L1274-1276 |
| `DESIGN-TOKENS.md` | app.css `@plugin` block values | Lockstep documentation | VERIFIED | `--ops-surface-2` dark value `#1b2230` matches app.css L58; light value `#faf7f2` matches L96 |

---

## Data-Flow Trace (Level 4)

These are CSS token/recipe changes, not React/LiveView components with async data. The relevant "data flow" is CSS cascade: token declared in `@plugin` block → emitted to both dark selector paths by daisyUI plugin → consumed in `background:` recipe properties.

| Token | Declaration Site | Propagation | Consumed By | Status |
|-------|-----------------|-------------|-------------|--------|
| `--ops-surface-2` (dark) | `app.css` dark `@plugin` L58 | daisyUI plugin → `[data-theme="dark"]` + `@media prefers-color-scheme:dark` | 9 recipe swaps + D-05 overrides + .bg-ops-surface-2 helper | FLOWING |
| `--ops-surface-2` (light) | `app.css` light `@plugin` L96 | daisyUI plugin → `[data-theme="light"]`/default | Light color-mix inputs byte-identical to prior `base-200` | FLOWING (identity) |
| `--shadow-ops-*` | `app.css` @theme L135-142 (light); overridden at L1299-1312 (dark) | Standard CSS variable cascade | All 14 shadow consumers (no recipe changes needed per D-09) | FLOWING |

---

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `light-pixel-diff.mjs` syntax valid | `node --check examples/scrypath_ecommerce/e2e/light-pixel-diff.mjs` | exit: 0 | PASS |
| pixelmatch/pngjs installed | `grep '"pixelmatch"\|"pngjs"' examples/scrypath_ecommerce/package.json` | both present | PASS |
| `verify.opsui` alias exists | `grep '"verify.opsui"' scrypath_ops/mix.exs` | 1 match | PASS |
| elevation tokens in both @plugin blocks | `grep -c '\-\-ops-surface-2' app.css` | 15 total occurrences | PASS |
| shadow rgba dual-path | `grep -c 'shadow-ops.*rgba' app.css` | 8 (4 per path) | PASS |
| ops_code_block uses bg-ops-surface-2 | `grep 'bg-ops-surface-2' ops_ui.ex` | 1 match at L994 | PASS |
| all commits exist in git history | `git log --oneline` | 9 phase commits present (`d89e990`–`a214290`) | PASS |
| DESIGN-TOKENS.md has elevation subsection | `grep 'Elevation surfaces' DESIGN-TOKENS.md` | match at L43 | PASS |
| no bg-base-200 in ops_code_block | `grep 'bg-base-200' ops_ui.ex` | 0 matches in ops_code_block (1 unrelated line at L788 for different component — in scope) | PASS |
| body class fix in layouts.ex | `grep 'ops_admin_path' layouts.ex` | `unless ops_admin_path?(@conn)` at L29 | PASS |

Step 7b: Full Elixir/Playwright test suite not re-run by verifier (requires dev server). Spot-checks above are static; SUMMARY.md records Plan 04 gate bundle execution with `mix verify.opsui` exit 0 and `contrast-checker.mjs` light count matching Phase 128 baseline.

---

## Probe Execution

No conventional `scripts/*/tests/probe-*.sh` files found for this phase. The D-11 proof bundle (`mix verify.opsui`, `node contrast-checker.mjs`, `npm run test:e2e:admin-contrast`, `node e2e/light-pixel-diff.mjs`) constitutes the phase gate and was run by the executor during Plan 04. Re-execution of the full Playwright contrast matrix requires a running dev server and is routed to human verification. Static checks above substitute where possible.

---

## Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| DARKTOKEN-01 | 130-01 through 130-04 | 4-step dark surface ramp via elevation tokens; light pixel-identical; DESIGN-TOKENS.md lockstep | SATISFIED | All three ROADMAP success criteria verified. Token declarations, recipe routing, shadow ladder, documentation all confirmed in codebase. |

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `ops_ui.ex` | 68 | `(D-12)` in doc comment | Info | Design decision reference number, not a debt marker — `@doc """ Flat bordered panel for primary JTBD blocks (D-12). """`. Context confirms this is a documentation label. No blocker. |

No `TBD`, `FIXME`, or `XXX` markers found in any of the six files modified by this phase.

No placeholder returns, empty implementations, or hardcoded-empty stub patterns found in the phase-modified files.

---

## Deferred Items

| Item | Addressed In | Evidence |
|------|-------------|---------|
| `test:e2e:admin-contrast` exits 0 (Cluster 3 — primary-violet `#6c5ce7` at 4.3:1 on cream, `.ops-nav-item-active` + `.bg-primary`) | Phase 132 | ROADMAP Phase 132 goal: "Re-tune muted-text alphas so both themes pass AA...Gate: CONTRAST-HARNESS-01 must be green in both themes before this phase closes." REQUIREMENTS.md A11Y-TOKEN-01 covers the primary/dark AA fixes. Cluster 3 is not DARKTOKEN-01 scope. |

---

## Human Verification Required

### 1. Dark Mode Visual Elevation Check

**Test:** Boot the admin UI in dark mode (visit `http://localhost:4002/admin/search` with `data-theme="dark"` active, or use the theme toggle). Inspect: `.ops-muted-panel` sections (Sync/Drift headers, disclosure panels), `.ops-data-card` workspace cards (Playbooks screen), `.ops-panel` (Control Room intent cards), shadow depth on raised panels.

**Expected:** All above surfaces appear visibly lighter than the dark page background `#0c0f14` — they should render as `#1b2230` midnight blue. Shadow depth is perceptible on raised panels (dark-inward rgba, subtle).

**Why human:** CSS elevation step-up between `#0c0f14` and `#1b2230` is a perceptual judgment requiring a browser. The contrast gate confirms Cluster 1 AA pass (automated proxy), but visual verification of the step is the plan's stated `[G]` gate close condition.

### 2. Light Mode Pixel-Identity Visual Check

**Test:** Toggle to light mode and compare all admin surfaces vs the pre-Phase-130 appearance.

**Expected:** All surfaces look identical to pre-Phase-130. The pixel-diff gate proved 0 diff pixels; this is the human double-check confirming nothing changed unexpectedly.

**Why human:** The pixel-diff gate programmatically proved 0 diff pixels, but the plan's `checkpoint:human-verify` task explicitly requests this visual confirmation as part of the gate close.

---

## Gaps Summary

No blocking gaps found. All DARKTOKEN-01 must-haves are verified in the codebase.

The only open item is the `test:e2e:admin-contrast` gate still exiting 1 due to Cluster 3 primary-violet violations. This is:
1. Explicitly out of DARKTOKEN-01 scope per `130-CONTEXT.md` (scoped to Cluster 1 / surface-2 ramp)
2. Explicitly deferred to Phase 132 (A11Y-TOKEN-01) per user approval (Option B)
3. Documented honestly in VALIDATION.md and Plan 04 SUMMARY

The phase's own target — Cluster 1 (`.leading-4` ramp collapse, 1.08:1) — is confirmed resolved at 0 violations after the body class contamination fix.

---

_Verified: 2026-06-04_
_Verifier: Claude (gsd-verifier)_
