---
phase: 134-under-iterated-surface-polish-dual-theme-s
plan: 01
subsystem: testing
tags: [playwright, exunit, opsui, dark-theme, surface-depth]

requires:
  - phase: 133
    provides: path-motion browser proof and dark glow probe precedent
provides:
  - Admin surface-depth Playwright harness skeleton for SCREEN-DARK-01
  - Shared importable theme grid and scenario capture helpers
  - ExUnit surface-depth token value tripwire
affects: [phase-134-plan-02, admin-e2e, opsui-static-contracts]

tech-stack:
  added: []
  patterns:
    - Shared Playwright theme grid helper consumed by multiple specs
    - Static CSS value contracts as ExUnit tests under scrypath_ops/test

key-files:
  created:
    - examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts
    - examples/scrypath_ecommerce/e2e/helpers/theme-grid.ts
    - scrypath_ops/test/scrypath_ops_web/surface_depth_token_contract_test.exs
  modified:
    - examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts
    - examples/scrypath_ecommerce/package.json

key-decisions:
  - "Extracted theme modes, viewports, system-dark invariant, nav helpers, and scenario captures into helpers/theme-grid.ts so both Playwright specs share one source."
  - "Kept Plan 01 harness-only: no app CSS, component, JS hook, keyframe, LiveView, STATE.md, or ROADMAP.md edits."

patterns-established:
  - "Depth specs import theme/scenario grid symbols from helpers/theme-grid.ts instead of redefining them."
  - "Surface token value locks live in a sibling ExUnit contract test, not the token orphan checker."

requirements-completed: [SCREEN-DARK-01]

duration: 5min
completed: 2026-06-26
status: complete
---

# Phase 134 Plan 01: Surface Depth Harness Summary

**Dark/system-dark surface-depth verification harness with shared Playwright theme grid and static token tripwire**

## Performance

- **Duration:** 5 min
- **Started:** 2026-06-26T01:45:06Z
- **Completed:** 2026-06-26T01:50:10Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added `admin_surface_depth.spec.ts` with the `{explicit-dark, system-dark} x {mobile 390, desktop 1440}` grid and populated-Playbooks setup.
- Extracted shared theme/grid/nav/scenario symbols to `e2e/helpers/theme-grid.ts`; `admin_contrast_matrix.spec.ts` now imports the same source.
- Added `test:e2e:admin-depth` and a new ExUnit token contract pinning `--ops-surface-2` plus raised-surface token references.

## Task Commits

1. **Task 1: Author admin surface-depth binding gate** - `e7ea70c` (test)
2. **Task 2: Author surface-depth token tripwire** - `fcead2f` (test)

## Files Created/Modified

- `examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts` - New Playwright depth harness skeleton with dark/system-dark viewport grid and populated Playbooks seed path.
- `examples/scrypath_ecommerce/e2e/helpers/theme-grid.ts` - Shared importable theme modes, viewports, system-dark invariant, nav helpers, and scenario capture map.
- `examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts` - Behavior-preserving refactor to consume `helpers/theme-grid.ts`.
- `examples/scrypath_ecommerce/package.json` - Added `test:e2e:admin-depth`.
- `scrypath_ops/test/scrypath_ops_web/surface_depth_token_contract_test.exs` - New static CSS value tripwire.

## Verification Results

- `cd examples/scrypath_ecommerce && npx tsc --noEmit -p . 2>&1 | head -40` - **Blocked by local dependency state**: package does not have TypeScript installed, and `npx` reported "This is not the tsc command you are looking for". No install was performed.
- `node -e "const p=require('./package.json'); ..."` - **PASS**: `script OK: playwright test e2e/admin_surface_depth.spec.ts`.
- Shared theme-grid grep - **PASS**: `shared theme-grid OK`.
- Divergent-copy grep for depth spec - **PASS**: no local `THEME_MODES`, `VIEWPORTS`, or `assertSystemDarkInvariants` definitions.
- `npx playwright test e2e/admin_surface_depth.spec.ts --list` - **PASS**: 20 tests listed.
- `npx playwright test e2e/admin_contrast_matrix.spec.ts --list` - **PASS**: 3 tests listed.
- `npx playwright test e2e/admin_surface_depth.spec.ts --reporter=line` - **Environment blocked**: 20 failures, all at `POST http://127.0.0.1:4002/dev/e2e/seed` with `ECONNREFUSED`; no local browser server was listening.
- `npx playwright test e2e/admin_contrast_matrix.spec.ts --reporter=line` - **Environment blocked**: 3 failures, all at `POST http://127.0.0.1:4002/dev/e2e/seed` with `ECONNREFUSED`; this confirms the refactored spec loads but cannot run without the server.
- `cd scrypath_ops && mix test test/scrypath_ops_web/surface_depth_token_contract_test.exs` - **PASS**: 3 tests, 0 failures.
- Harness-only diff check for `app.css`, `ops_ui.ex`, and LiveView files - **PASS**: no diffs.

## Decisions Made

Used extraction to `helpers/theme-grid.ts` instead of in-place exports from `admin_contrast_matrix.spec.ts`. This avoids importing from a Playwright spec file and keeps both specs consuming test infrastructure rather than one spec depending on another spec's top-level test registration.

## Deviations from Plan

None - plan executed within the allowed extract-and-import route.

## Issues Encountered

- `npx tsc --noEmit -p .` cannot run because TypeScript is not installed in `examples/scrypath_ecommerce`. Per package-install safety rules, no dependency was added.
- Browser execution requires a booted local server at `127.0.0.1:4002`; it was unavailable, so Playwright runtime checks failed with `ECONNREFUSED`.

## Known Stubs

- `examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts` contains intentional `TODO(Phase 134 Plan 02)` computed-style assertion placeholders. Plan 01's objective is the runnable skeleton, shared grid, and populated seed path; Plan 02 replaces these placeholders once CSS changes land.

## Threat Flags

None. The new Playwright spec uses the existing local e2e helper base URL and `/dev/e2e/seed` path; no app endpoint, auth surface, remote target, or data-handling surface was added.

## User Setup Required

None for committed artifacts. To run browser specs locally, boot the existing ecommerce/ops dev server on `127.0.0.1:4002` first.

## Next Phase Readiness

Plan 02 can now fill in the depth assertions against `admin_surface_depth.spec.ts` and append the hover-border token tripwire to the new ExUnit contract once the CSS selector exists.

## Self-Check: PASSED

- Created files exist: `admin_surface_depth.spec.ts`, `helpers/theme-grid.ts`, and `surface_depth_token_contract_test.exs`.
- Task commits exist: `e7ea70c`, `fcead2f`.
- No tracked application CSS/component/LiveView files were modified.

---
*Phase: 134-under-iterated-surface-polish-dual-theme-s*
*Completed: 2026-06-26*
