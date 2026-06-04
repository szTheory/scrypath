---
phase: 119-audit-harness-and-seed-scenarios
plan: 119
subsystem: ui
tags: [phoenix, liveview, scrypath_ops, opsui, ecommerce-demo, playwright, seed-data, screenshots]
requires:
  - phase: 118-admin-screen-ux-cleanup
    provides: Quiet ops console screen system across the 6 admin screens
provides:
  - Four named operational seed scenarios (all_green / degraded / incident / empty) in BOTH seeding paths
  - Mix task `scrypath.demo.seed --scenario <name>` (default incident, validated)
  - `/dev/e2e/seed` operational scenarios alongside the existing e2e_search_catalog lane
  - Theme×viewport×state screenshot matrix spec producing a 40-shot deterministic baseline
  - v1.33 admin-UI baseline captured to .tmp/admin-screenshots/ (overwrote stale v1.32 set)
affects: [examples/scrypath_ecommerce]
tech-stack:
  added: []
  patterns: [named operational scenarios, scenario-grouped screenshot matrix, addInitScript theme control]
key-files:
  created:
    - examples/scrypath_ecommerce/e2e/admin_screenshot_matrix.spec.ts
    - .planning/milestones/v1.33-phases/119-audit-harness-and-seed-scenarios/119-PLAN.md
    - .planning/milestones/v1.33-phases/119-audit-harness-and-seed-scenarios/119-SUMMARY.md
    - .planning/milestones/v1.33-phases/119-audit-harness-and-seed-scenarios/119-VERIFICATION.md
  modified:
    - examples/scrypath_ecommerce/lib/mix/tasks/scrypath.demo.seed.ex
    - examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/controllers/e2e_controller.ex
    - examples/scrypath_ecommerce/e2e/helpers/e2e.ts
    - examples/scrypath_ecommerce/package.json
    - examples/scrypath_ecommerce/Makefile
requirements-completed: [HARNESS-01, SEED-01]
completed: 2026-06-03
---

# Phase 119 Plan 119: Audit harness + seed-scenario coverage Summary

**The admin UI's full operational state-space is now deterministically seedable through
named scenarios in both seeding paths, and a theme×viewport×state Playwright matrix
captures a 40-shot baseline against the running dev stack — all before any pixel changes.**

## Accomplishments

- **SEED-01 (Mix task):** `scrypath.demo.seed` now accepts `--scenario all_green|degraded|incident|empty`
  (default `incident`), parameterizing the existing failed-sync + contract-drift injection
  logic. Bad scenario names are rejected with a clear message. The catalog fixtures are
  unchanged across scenarios; only sync state + injected signals differ. Added a
  `clear_product_index!` helper so the `empty` scenario truly empties the live index.
- **SEED-01 (`/dev/e2e/seed`):** the controller now handles the four operational scenarios
  alongside the original `e2e_search_catalog` lane via a guarded `seed/2` head. Failed-sync
  reason-class fixtures (verbatim error substrings) mirror the Mix task so both paths produce
  the same operational state. `reset_state!` + `prepare_indexes!` make every scenario
  reset-safe (re-applying declared settings undoes prior drift before a scenario re-decides it).
- **HARNESS-01:** new `e2e/admin_screenshot_matrix.spec.ts` captures 10 screen-states ×
  {light, dark} × {mobile 390, desktop 1440} = **40 deterministic shots**, grouped by
  scenario (incident / all_green / empty) so each scenario is seeded once. Theme is set via
  `addInitScript` on a fresh context (`localStorage["phx:theme"]`), viewport via per-context
  `viewport`. Files named `NN-screen--theme--viewport--state.png`.
- Added `npm run test:e2e:admin-matrix` and `make screenshots-matrix`.
- Booted the dev stack (host Phoenix + dockerized Meilisearch + native Postgres) and ran the
  matrix; baseline written to `test-results/admin-screenshots/` and copied to
  `.tmp/admin-screenshots/` (replacing the stale v1.32 set).

## Checks Run

- `cd examples/scrypath_ecommerce && mix compile --warnings-as-errors` — clean.
- `npx playwright test --list` — both screenshot specs parse (4 tests across 2 files).
- Root `mix verify.opsui` — green (2 doctests, 129 tests, 0 failures); nav contract OK.
- Matrix run against the live dev server — 3/3 scenario groups passed, 40 PNGs produced.
- All four Mix-task scenarios + bad-scenario rejection smoke-tested against the live DB.

## Deviations from Plan

- The matrix is built as a sibling spec (`admin_screenshot_matrix.spec.ts`) rather than
  extending `admin_screenshots.spec.ts`, keeping the original happy-path capture intact for
  comparison and leaving the matrix free to use per-context theme/viewport control.
- `waitForSearchVisible` is gated to the `all_green` scenario only: `incident`/`degraded`
  inject contract drift that drops the `tenant_id` filterable, so a tenant-filtered
  visibility probe would fail by design (products are still synced — drift is injected after
  sync). Documented inline.

## Issues Encountered

- `mix do ecto.create, ecto.migrate, scrypath.demo.seed, phx.server` did not bind the HTTP
  port: the seed task runs `app.start`, which consumes the start so the trailing
  `phx.server` never serves the endpoint. Worked around by running the seed step and then
  `mix phx.server` as a standalone command (DB already seeded). `make dev` users hit the
  same chain; noted for Phase 120+ tooling.
- Dev config sets `sandbox: true`, but the dev pool is a normal connection pool, so seeded
  data is visible in the browser (consistent with the Makefile's documented behavior) — no
  non-sandbox override was needed for the host `make dev` loop.

## User Setup Required

None.

## Next Phase Readiness

- Phase 120 (per-touchpoint audit, no code changes) can drive any of the four scenarios
  deterministically and consume the 40-shot baseline in `.tmp/admin-screenshots/`.
- The `make dev` HTTP-bind gotcha above is worth fixing if Phase 120+ wants a one-command boot.

## Self-Check: PASSED

- Both seeding paths expose the four named scenarios and were exercised live.
- The matrix produced exactly 40 correctly-named captures; spot-checked incident/all_green
  posture divergence, dark-theme application, mobile viewport, and empty/zero-result states.
- All three required static checks pass; baseline copied to `.tmp/admin-screenshots/`.
