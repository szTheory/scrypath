---
phase: 130-dark-surface-ramp-depth-tokens-g
plan: 03
subsystem: ui
tags: [css, tailwind, daisyui, dark-mode, design-tokens, ops-ui, shadow-tokens]

# Dependency graph
requires:
  - phase: 130-02
    provides: "--ops-surface-1, --ops-surface-2 declared in both @plugin blocks — prerequisite for token-swap recipes"

provides:
  - "9 shared token-swap recipes routing through --ops-surface-1/--ops-surface-2 inside preserved color-mix wrappers"
  - ".bg-ops-surface-2 CSS helper class enabling bg-ops-surface-2 Tailwind utility"
  - "D-05 dark-scoped dual-path overrides for .ops-data-card and .ops-result-row"
  - "D-10 --shadow-ops-* dual-path dark overrides with rgba(0,0,0,α) ladder"
  - "ops_code_block :default using bg-ops-surface-2 instead of bg-base-200"

affects:
  - 130-04-PLAN (DESIGN-TOKENS.md lockstep documentation + Wave 3 final verification)
  - phase-131 (glow + copper accent layers built on surface ramp)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "GROUP A token-swap: change only inner var() inside color-mix wrapper; wrapper + alpha preserved verbatim"
    - "GROUP B D-05 dark-scoped override: raw var(--ops-surface-2) without color-mix, dual-path [data-theme=dark] + @media(prefers-color-scheme:dark) html:not([data-theme=light])"
    - "D-10 shadow override: hand-authored dual-path for @theme tokens (not @plugin keys); cascades to all 14 shadow consumers"
    - ".bg-ops-surface-2 CSS helper bridges @plugin token to Tailwind utility class (v4 cannot auto-generate bg-* for @plugin tokens)"

key-files:
  created: []
  modified:
    - scrypath_ops/assets/css/app.css
    - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex

key-decisions:
  - "9 token-swaps applied inside existing color-mix wrappers; alpha percentages left byte-identical"
  - ".ops-data-card (base-100 92%) and .ops-result-row (base-100 94%) shared recipes left unchanged; D-05 dark-scoped overrides add surface-2 lift in dark only"
  - "D-10 shadow overrides placed at end of file (not inside @plugin block) per anti-pattern guidance"
  - ".bg-ops-surface-2 helper placed at end of file with comment explaining Tailwind v4 limitation"
  - "Pre-existing bg-base-200/70 at ops_ui.ex L788 is a different component/class — not in scope; only ops_code_block :default was changed"

patterns-established:
  - "D-05 carve-out pattern: leave shared recipe unchanged when token-swap would move light value; add dark-scoped dual-path override for lift"

requirements-completed:
  - DARKTOKEN-01

# Metrics
duration: 10min
completed: 2026-06-04
---

# Phase 130 Plan 03: Recipe Routing Layer — Token-Swaps, Helper, Overrides, and Shadow Ladder Summary

**9 shared-recipe inner tokens swapped to --ops-surface-1/--ops-surface-2 inside preserved color-mix wrappers; .bg-ops-surface-2 helper + D-05 dark-scoped overrides for data-card/result-row; D-10 shadow dual-path rgba ladder; ops_code_block :default rereouted to bg-ops-surface-2 — light byte-identical, mix test 129/0**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-06-04
- **Completed:** 2026-06-04
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

### Task 1: GROUP A token-swaps + GROUP B helper+overrides (app.css)

GROUP A — 9 recipe token-swaps (inner token only; color-mix wrapper + alpha preserved):
- `.ops-panel` L249: base-100 96% → ops-surface-1 96%
- `.ops-surface-flat` L256: base-100 94% → ops-surface-1 94%
- `.ops-muted-panel` L262: base-200 64% → ops-surface-2 64%
- `.ops-verdict-neutral` L363: base-200 64% → ops-surface-2 64%
- `.ops-nav-list` L563: base-200 72% → ops-surface-2 72%
- `.ops-disclosure` L600: base-200 58% → ops-surface-2 58%
- `.ops-preflight__card` L798: base-100 94% → ops-surface-1 94%
- `.ops-preflight__card--locked` L807: base-200 60% → ops-surface-2 60%
- `.ops-kbd` L1161: base-200 70% → ops-surface-2 70%

GROUP B-1 — `.bg-ops-surface-2 { background: var(--ops-surface-2); }` helper class added (end of file) for Tailwind v4 @plugin token gap

GROUP B-2 — D-05 dark-scoped dual-path overrides added for:
- `.ops-data-card` (shared recipe base-100 92% unchanged)
- `.ops-result-row` (shared recipe base-100 94% unchanged)
Both use `html:not([data-theme="light"])` in media query counterpart

### Task 2: D-10 shadow dual-path override + ops_code_block DK-09

- D-10 shadow override block added at end of app.css with both paths:
  - `[data-theme="dark"]` block + `@media(prefers-color-scheme:dark) html:not([data-theme="light"])` block
  - Four tokens: surface 0.40, mid 0.45, raised 0.50, overlay 0.55 rgba ladder
  - Cascades to all 14 shadow consumers (zero recipe-level edits needed)
- ops_code_block `:default` changed: `bg-base-200` → `bg-ops-surface-2` (ops_ui.ex L994)
  - L995 (`bg-base-100`) and L996 (`bg-base-100/70`) untouched
  - Light pixel-identical: surface-2 light = #faf7f2 = prior base-200 light value

## Task Commits

1. **Task 1: GROUP A token-swaps + GROUP B helper+overrides in app.css** - `d4b7faf` (feat)
2. **Task 2: D-10 shadow dual-path override + ops_code_block DK-09 reroute** - `0958736` (feat)

## Files Created/Modified

- `scrypath_ops/assets/css/app.css` — 9 token-swaps + .bg-ops-surface-2 helper + D-05 dual-path overrides for data-card/result-row + D-10 shadow dual-path override; 52 net insertions
- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` — ops_code_block :default bg-base-200 → bg-ops-surface-2 (1 line)

## Decisions Made

- All 9 token-swaps applied by targeted Edit (each recipe uniquely identified by its class selector context)
- Added GROUP B and D-10 overrides at end of file (after the theme-toggle rules) for logical grouping
- D-05 carve-out applied to .ops-data-card and .ops-result-row only (not the 9 token-swap candidates)
- The pre-existing `bg-base-200/70` reference at ops_ui.ex L788 (a different component) was left untouched — out of scope

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The CSS build, Elixir test suite (129/0), and contrast checker (3 AA fails — same pre-existing baseline as Phase 128) all passed on first run for both tasks.

## Verification Results

- `grep 'ops-surface-2' app.css | wc -l` → 15 (2 @plugin declarations + 6 recipe swaps + .bg-ops-surface-2 helper + 6 dark-scoped overrides for data-card/result-row)
- `grep 'ops-surface-1' app.css` → 5 (2 @plugin + 3 recipe swaps: panel/surface-flat/preflight-card)
- `grep 'shadow-ops-surface.*rgba' app.css` → 2 (one per dark path)
- `grep 'shadow-ops-overlay.*rgba' app.css` → 2
- `grep 'bg-ops-surface-2' ops_ui.ex` → 1 match at L994
- `.ops-data-card` shared recipe still uses `var(--color-base-100) 92%` — confirmed
- `.ops-result-row` shared recipe still uses `var(--color-base-100) 94%` — confirmed
- `mix tailwind scrypath_ops` → Done in 77ms (0 errors)
- `mix test` → 129 tests, 0 failures
- `contrast-checker.mjs` → 3 AA failures (pre-existing: .ops-text-meta, .ops-cmdk__item-hint, .ops-cmdk__empty at 3.9:1 in light — matches Phase 128 baseline exactly)

## Known Stubs

None.

## Threat Flags

None — all changes are dark-scoped CSS overrides or inner-token swaps; no new network endpoints, auth paths, or schema changes.

## Self-Check

- [x] `scrypath_ops/assets/css/app.css` modified and committed at `d4b7faf` and `0958736`
- [x] `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` modified and committed at `0958736`
- [x] 9 GROUP A token-swaps confirmed via grep
- [x] .bg-ops-surface-2 helper exists at L1274
- [x] D-05 dual-path overrides for data-card + result-row use html:not([data-theme="light"])
- [x] D-10 shadow dual-path has exactly 2 matches for shadow-ops-surface.*rgba
- [x] Shadow overrides NOT inside @plugin block
- [x] ops_code_block :default uses bg-ops-surface-2 (1 match), bg-base-200 no longer present in ops_code_block
- [x] mix test 129/0
- [x] mix tailwind exits 0
- [x] contrast-checker 3 AA fails (pre-existing, unchanged from Phase 128 baseline)

## Self-Check: PASSED

---
*Phase: 130-dark-surface-ramp-depth-tokens-g*
*Completed: 2026-06-04*
