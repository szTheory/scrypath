---
phase: 105-hermetic-e2e-pipeline
plan: 01
subsystem: testing
tags: [playwright, phoenix, oban, meilisearch, e2e]
requires:
  - phase: 104-search-integration-operations-proof
    provides: deterministic fixture + storefront/operator surfaces
provides:
  - Example-local Playwright scaffold with listable harness spec
  - Dev/test-only E2E harness JSON endpoints for seed/drain/readiness flows
  - Shared Playwright helper module with bounded polling and endpoint-aware errors
  - Local `mix e2e.prepare` alias for explicit DB setup
affects: [105-02, 105-03, 105-04, ci-e2e-lane]
tech-stack:
  added: [@playwright/test]
  patterns: [deterministic readiness polling, dev/test-only harness endpoints]
key-files:
  created:
    - examples/scrypath_ecommerce/package.json
    - examples/scrypath_ecommerce/package-lock.json
    - examples/scrypath_ecommerce/playwright.config.ts
    - examples/scrypath_ecommerce/e2e/harness.spec.ts
    - examples/scrypath_ecommerce/e2e/helpers/e2e.ts
  modified:
    - examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/controllers/e2e_controller.ex
    - examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/router.ex
    - examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/e2e_controller_test.exs
    - examples/scrypath_ecommerce/mix.exs
key-decisions:
  - "Kept Playwright as browser runner only (no webServer lifecycle ownership)."
  - "Seed contract standardized on scenario_e2e_search_catalog deterministic names/ids."
  - "Readiness helpers use bounded polling via expect.poll, never fixed sleeps."
patterns-established:
  - "E2E helper errors include endpoint path + response body for fast triage."
requirements-completed: [E2E-01, E2E-02]
duration: 38m
completed: 2026-05-30
---

# Phase 105 Plan 01: Hermetic E2E Harness Foundation Summary

**Playwright harness scaffolded in the example app with deterministic dev/test E2E contracts and bounded readiness helpers.**

## Performance

- **Duration:** 38 min
- **Started:** 2026-05-30T22:36:00Z
- **Completed:** 2026-05-30T23:14:00Z
- **Tasks:** 4
- **Files modified:** 9

## Accomplishments
- Added example-local Node Playwright manifest/config and a discoverable harness smoke spec.
- Extended `/dev/e2e` JSON harness endpoints for seed, drain, search visibility, category rename, failure injection, and operator state.
- Added reusable Playwright helper functions for deterministic backend-driven readiness and diagnostics.
- Added `mix e2e.prepare` alias for explicit DB preparation without crossing lifecycle boundaries.

## Task Commits

1. **Task 1: Add Example-Local Playwright Manifest and Config** - `07f774d` (feat)
2. **Task 2: Extend Dev/Test E2E Harness Endpoints** - `406e3a9` (feat)
3. **Task 3: Add Shared Playwright Harness Helpers** - `c00fe95` (feat)
4. **Task 4: Add Local Mix Alias for Explicit E2E Preparation** - `f36afa2` (chore)

## Files Created/Modified
- `examples/scrypath_ecommerce/package.json` - Playwright package/scripts.
- `examples/scrypath_ecommerce/package-lock.json` - npm lockfile for hermetic install.
- `examples/scrypath_ecommerce/playwright.config.ts` - Chromium-only config with baseURL and no webServer ownership.
- `examples/scrypath_ecommerce/e2e/harness.spec.ts` - minimal discoverable smoke test.
- `examples/scrypath_ecommerce/e2e/helpers/e2e.ts` - shared API helper layer for seed/drain/poll/mutate/probe operations.
- `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/controllers/e2e_controller.ex` - dev/test harness controller contracts.
- `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/router.ex` - guarded `/dev/e2e/*` routes.
- `examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/e2e_controller_test.exs` - contract tests for seed/drain responses.
- `examples/scrypath_ecommerce/mix.exs` - `e2e.prepare` alias.

## Decisions Made
- Used `scenario_e2e_search_catalog` as canonical seed contract to align with deterministic storefront assertions.
- Kept `/dev/e2e/*` surface inside existing `if Mix.env() in [:dev, :test]` boundary (threat mitigation T-105-01).
- Implemented bounded polling with `expect.poll` and explicit timeout messages for readiness (threat mitigation T-105-03).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Removed nonexistent assets setup task from `e2e.prepare`**
- **Found during:** Task 4
- **Issue:** `mix e2e.prepare` failed because `assets.setup` task is not defined in `examples/scrypath_ecommerce`.
- **Fix:** Reduced alias to required DB lifecycle steps: `ecto.create --quiet` and `ecto.migrate --quiet`.
- **Files modified:** `examples/scrypath_ecommerce/mix.exs`
- **Verification:** `cd examples/scrypath_ecommerce && mix e2e.prepare` exits 0
- **Committed in:** `f36afa2`

---

**Total deviations:** 1 auto-fixed (Rule 3)
**Impact on plan:** No scope change; unblocked required verification using supported project tasks.

## Issues Encountered
- None beyond the auto-fixed missing `assets.setup` task.

## User Setup Required
None - no external service configuration required for this plan slice.

## Next Phase Readiness
- Harness endpoints and helper contract are ready for feature specs in follow-on plans.
- Playwright suite can be listed deterministically in CI/local before richer browser flows land.

## Self-Check: PASSED
- Found `.planning/phases/105-hermetic-e2e-pipeline/105-01-SUMMARY.md`.
- Found task commits `07f774d`, `406e3a9`, `c00fe95`, `f36afa2` in git history.
