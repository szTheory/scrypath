---
phase: 107-ecommerce-readiness-regression-guard
plan: 01
subsystem: testing
tags: [ecommerce, tenant_scope, readiness_probe, phoenix, mix_task]
requires:
  - phase: 106-fan-out-reflection-contract-repair
    provides: focused verification gate precedent and v1.29 repair posture
provides:
  - Tenant-preserving category readiness filter composition for `/dev/e2e/search-visible`
  - Controller-level regression proof of `%Scrypath.Query.filter` tenant/category merge
  - Focused `mix verify.phase107` deterministic verification gate
affects: [ecommerce_example, e2e_readiness, phase_verification]
tech-stack:
  added: []
  patterns: [backend-stubbed Phoenix controller regression, delegated example-app test path, focused phase verify mix task]
key-files:
  created:
    - lib/mix/tasks/verify.phase107.ex
    - test/mix/tasks/verify.phase107_test.exs
  modified:
    - examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/controllers/e2e_controller.ex
    - examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/e2e_controller_test.exs
    - mix.exs
key-decisions:
  - "Kept `/dev/e2e/search-visible` on explicit filter composition so Phase 107 proves the historical tenant/category merge bug class."
  - "Used a backend-stubbed controller test instead of browser or live-service coverage to keep the gate deterministic and service-free."
  - "Added a narrow root `mix test` delegation for e-commerce example test paths so the documented focused command runs from the repository root."
patterns-established:
  - "Example-app ExUnit paths can be delegated from root `mix test` when the test requires the example app's support modules."
  - "Phase verify tasks may run example-app tests in that app's Mix project while keeping root task self-tests in the root project."
requirements-completed: [E2E-01]
duration: 27 min
completed: 2026-05-31
---

# Phase 107 Plan 1: Ecommerce Readiness Regression Guard Summary

**The e-commerce readiness probe now preserves tenant scope while adding category filtering, with a fast service-free `mix verify.phase107` guard proving the exact query filter contract.**

## Performance

- **Duration:** 27 min
- **Started:** 2026-05-31T16:07:00Z
- **Completed:** 2026-05-31T16:34:01Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Updated `/dev/e2e/search-visible` category readiness filtering to merge `category_id` into the existing tenant filter instead of replacing it.
- Added a controller regression that stubs the Scrypath backend, captures `%Scrypath.Query{}`, and asserts the filter is exactly `[category_id: 202, tenant_id: 101]` after sorting.
- Added `mix verify.phase107` and a task self-test covering argument rejection, help discoverability, and focused test paths.
- Added narrow root `mix test` delegation for `examples/scrypath_ecommerce/test/...` so the planned controller test command works from the repository root.

## Task Commits

1. **Task 107-01-01: Lock tenant/category filter composition in the readiness probe** - `2c43f59` (fix)
2. **Task 107-01-02: Prove the readiness query keeps tenant scope with category filtering** - `b59dee7` (test)
3. **Task 107-01-03: Add focused Phase 107 verification gate** - `fae9517` (feat)

## Files Created/Modified

- `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/controllers/e2e_controller.ex` - Merges category readiness filtering into the existing tenant filter.
- `examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/e2e_controller_test.exs` - Adds backend-stubbed query capture coverage for tenant/category filter composition.
- `lib/mix/tasks/verify.phase107.ex` - Adds the focused service-free Phase 107 verification task.
- `test/mix/tasks/verify.phase107_test.exs` - Adds task argument and source-contract coverage.
- `mix.exs` - Registers `verify.phase107` in test env and delegates e-commerce example test paths into the example app.

## Decisions Made

- Preserved explicit `filter:` composition rather than switching the probe to `tenant_scope:` so the regression guard proves the known bug signature.
- Kept the proof at the Phoenix controller/backend boundary instead of expanding Playwright fixtures or live Meilisearch coverage.
- Kept CI topology unchanged; `phase105-e2e` remains advisory.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Root example-app test command could not load example support modules**
- **Found during:** Task 107-01-01 verification
- **Issue:** `mix test examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/e2e_controller_test.exs` failed from the repository root because the root Mix project could not load `ScrypathEcommerceWeb.ConnCase`.
- **Fix:** Extended the existing root test delegation pattern to delegate `examples/scrypath_ecommerce/test/...` paths into `examples/scrypath_ecommerce`, and had `verify.phase107` run the example controller test inside that app.
- **Files modified:** `mix.exs`, `lib/mix/tasks/verify.phase107.ex`
- **Verification:** `mix test examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/e2e_controller_test.exs` and `mix verify.phase107`
- **Committed in:** `fae9517`

---

**Total deviations:** 1 auto-fixed (blocking verification path)
**Impact on plan:** The fix was required to make the plan's documented root-level verification command work. It stays bounded to test delegation and does not broaden browser E2E, CI topology, or public Scrypath API surface.

## Issues Encountered

None remaining. The only issue was the root/example Mix test boundary documented as an auto-fixed deviation.

## Verification

- `mix test examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/e2e_controller_test.exs` - passed, 9 tests.
- `mix test test/mix/tasks/verify.phase107_test.exs` - passed, 3 tests.
- `mix verify.phase107` - passed, 12 total focused tests across the example app and root task self-test.
- `rg "Keyword\\.get\\(:filter, \\[\\]\\)|Keyword\\.put\\(:category_id, category_id\\)" examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/controllers/e2e_controller.ex` - passed.
- `rg "Enum\\.sort\\(filter\\) == \\[category_id: 202, tenant_id: 101\\]" examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/e2e_controller_test.exs` - passed.
- `rg "\"verify.phase107\": :test" mix.exs` - passed.
- `! rg "tenant_scope:" examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/controllers/e2e_controller.ex` - passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 107's E2E-01 regression guard is complete and reproducible with `mix verify.phase107`. The v1.29 closeout can proceed to the planning/JTBD truth refresh work without changing the advisory status of `phase105-e2e`.

## Self-Check: PASSED

- Found: `.planning/phases/107-ecommerce-readiness-regression-guard/107-01-SUMMARY.md`
- Found commits: `2c43f59`, `b59dee7`, `fae9517`
- Focused verification passed via `mix verify.phase107`.
