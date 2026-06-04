# Phase 119 Plan: Audit harness + seed-scenario coverage

**Status:** Complete
**Requirements:** HARNESS-01, SEED-01

## Goal

Make the admin UI's full state-space deterministically seedable and
screenshot-capturable BEFORE any visual changes. Foundational — no pixel/CSS changes
in this phase.

## Tasks

### SEED-01 — named operational scenarios (both seeding paths)

- Add 4 named scenarios parameterizing the EXISTING injection logic (catalog fixtures
  unchanged):
  - `all_green` — catalog synced; no failed-sync, no drift → Posture healthy, verdict trusts search.
  - `degraded` — catalog synced; contract drift only → Posture partial/warning, verdict degraded.
  - `incident` (default) — all 5 failed-sync reason classes + drift → Posture red, can't-fully-trust.
  - `empty` — no synced products / no operational signal → every empty state.
- Mix task (`scrypath.demo.seed`): accept `--scenario <name>` (default `incident`); validate input.
- `/dev/e2e/seed`: accept the 4 operational scenarios alongside the existing
  `e2e_search_catalog`; idempotent/reset-safe; preserve verbatim reason-class error substrings.
- TS helper (`e2e/helpers/e2e.ts`): type `seedScenario` over the named scenarios.

### HARNESS-01 — capture matrix

- New spec `e2e/admin_screenshot_matrix.spec.ts`: cross-product of 6 screens ×
  {light, dark} × {mobile 390px, desktop 1440px}, each in the operational state that
  best exercises it; target ~32–40 deterministic captures.
- Theme via `addInitScript` setting `localStorage["phx:theme"]`; viewport via per-context
  `viewport`.
- Write to `test-results/admin-screenshots/`; copy the baseline into
  `.tmp/admin-screenshots/`. Files named `NN-screen--theme--viewport--state.png`.

## Verification

- `cd examples/scrypath_ecommerce && mix compile --warnings-as-errors` clean.
- Playwright specs parse (`npx playwright test --list`).
- Root `mix verify.opsui` stays green (OPSUI contract gate).
- Boot the dev stack and actually run the matrix to produce the baseline.
