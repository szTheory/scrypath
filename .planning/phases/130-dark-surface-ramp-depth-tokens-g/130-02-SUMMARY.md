---
phase: 130-dark-surface-ramp-depth-tokens-g
plan: 02
subsystem: ui
tags: [css, tailwind, daisyui, dark-mode, design-tokens, ops-ui]

# Dependency graph
requires:
  - phase: 130-01
    provides: pixelmatch/pngjs devDeps + verify.opsui alias — Wave 0 prerequisites

provides:
  - "--ops-bg, --ops-surface-1, --ops-surface-2 declared in both daisyUI @plugin blocks (dark + light)"
  - "daisyUI plugin auto-emits tokens to both [data-theme=dark] and @media (prefers-color-scheme: dark) with no manual dual-selector authoring"
  - "Stable token names for downstream recipe-routing tasks (Plans 03+)"

affects:
  - 130-03-PLAN (recipe routing swaps inner token refs to --ops-surface-1/--ops-surface-2)
  - 130-04-PLAN (shadow overrides + DESIGN-TOKENS.md lockstep)
  - phase-131 (glow + copper accent layers reference surface ramp)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Token-declaration-only commit: elevation tokens in @plugin blocks are inert until recipe routing wires them"
    - "daisyUI @plugin block spreads all non-reserved custom props to both explicit [data-theme] selector and @media (prefers-color-scheme) block"

key-files:
  created: []
  modified:
    - scrypath_ops/assets/css/app.css

key-decisions:
  - "Tokens declared after --noise: 0; and before closing } of each @plugin block, as specified by D-02 and Pattern 1"
  - "Dark values: --ops-bg:#0c0f14, --ops-surface-1:#141923, --ops-surface-2:#1b2230 (D-01)"
  - "Light values: --ops-bg:#faf7f2, --ops-surface-1:#fffdf8, --ops-surface-2:#faf7f2 (D-01) — light parity preserved"

patterns-established:
  - "Elevation token declaration: add inside @plugin block (not @theme) for automatic both-path dark coverage"

requirements-completed:
  - DARKTOKEN-01

# Metrics
duration: 5min
completed: 2026-06-04
---

# Phase 130 Plan 02: Declare Elevation Tokens in Both @plugin Blocks Summary

**Three CSS elevation tokens (`--ops-bg`, `--ops-surface-1`, `--ops-surface-2`) declared inside both daisyUI `@plugin "../vendor/daisyui-theme"` blocks in `app.css`; plugin spreads them to both dark theme paths for free; light contrast counts unchanged (3 pre-existing AA fails at 3.9:1, 0 new regressions)**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-06-04
- **Completed:** 2026-06-04
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Added `--ops-bg`, `--ops-surface-1`, `--ops-surface-2` to dark `@plugin` block with values `#0c0f14`, `#141923`, `#1b2230` (D-01)
- Added `--ops-bg`, `--ops-surface-1`, `--ops-surface-2` to light `@plugin` block with values `#faf7f2`, `#fffdf8`, `#faf7f2` (D-01)
- CSS builds clean (`mix assets.build` 0 errors); Elixir test suite green (129 tests, 0 failures)
- `contrast-checker.mjs` confirms light AA count unchanged: 3 failures (all pre-existing `.ops-text-meta`/`.ops-cmdk__item-hint`/`.ops-cmdk__empty` at 3.9:1, matching Phase 128 baseline)

## Task Commits

1. **Task 1: Declare elevation tokens in both @plugin blocks** - `ffc6a88` (feat)

**Plan metadata:** (pending final commit)

## Files Created/Modified

- `scrypath_ops/assets/css/app.css` — Added 3 elevation tokens to dark @plugin block (lines 56-58) and 3 to light @plugin block (lines 94-96); 6 insertions total

## Decisions Made

- Followed plan exactly: tokens inserted after `--noise: 0;` before closing `}` of each plugin block
- No deviations needed; both blocks confirmed free of pre-existing `--ops-surface-*` declarations before editing

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The CSS build, Elixir test suite, and contrast checker all passed on first run.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Elevation tokens are stable and named; Plans 03 and 04 can now route `.ops-*` fill recipes through `--ops-surface-1` / `--ops-surface-2` (token-swap) and add dark-scoped overrides for `.ops-data-card` + `.ops-result-row` (D-05 carve-out)
- No blockers

## Self-Check

- [x] `scrypath_ops/assets/css/app.css` modified and committed at `ffc6a88`
- [x] `grep -c '\-\-ops-surface-2' app.css` returns 2 ✓
- [x] `mix test` 129/0 ✓
- [x] `mix assets.build` 0 errors ✓
- [x] contrast-checker.mjs: 3 AA fails (pre-existing), 0 new regressions ✓

## Self-Check: PASSED

---
*Phase: 130-dark-surface-ramp-depth-tokens-g*
*Completed: 2026-06-04*
