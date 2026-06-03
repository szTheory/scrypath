# Phase 125 Verification (RECOVER-01)

**Date:** 2026-06-03
**Commit:** `e1b9330`
**Branch:** `gsd/v1.33-admin-ui-insane-polish`

## Gate results

| Gate | Result |
|------|--------|
| `mix verify.opsui` (129-baseline, nav-contract) | **GREEN** — 2 doctests, 129 tests, 0 failures; "Nav contract OK" |
| `cd scrypath_ops && mix test` | **GREEN** — 129/0 (two sync-drift assertions updated for the deferred :run_drift read) |
| `cd examples/scrypath_ecommerce && mix compile --warnings-as-errors` | **CLEAN** |
| Boot + 40-shot matrix, both themes | **GREEN** — 3 scenario groups (incident/all_green/empty) passed → 40 shots |

## Stack + matrix

- Meilisearch up via running infra (`/health` 200); ecommerce dev server booted on :4002 with a
  non-sandbox DB (ecto.create/migrate/`scrypath.demo.seed` separate from `phx.server`); `scrypath_ops`
  `mix assets.build` run before boot.
- Full `admin_screenshot_matrix.spec.ts` re-captured (40 shots) into `test-results/admin-screenshots-v125`,
  then copied over the running baseline at `.tmp/admin-screenshots/`.
- One stale spec assertion fixed: the Sync/Drift heading was renamed to "Sync and drift" in Phase 124;
  the matrix spec still asserted "Sync & Drift". Updated (not a regression from this phase).

## B1 / B6 visual confirmation

- **B1 (Posture mobile 390):** `01-posture--light--mobile--incident.png` — the per-schema table shows the
  "Worst-first. Swipe the table sideways…" hint, sits in a horizontally scrollable container with the
  scroll-shadow edge cue, and the degraded/error schemas are ordered to the top. **Confirmed.**
- **B6 (Sync/Drift width):** `03-sync-drift--light--desktop--drift.png` — the screen now renders at the
  wide `max-w-7xl` column; the 4-step preflight is a full-width row and the drift dimensions render in a
  multi-column grid. **Confirmed.**

## ops_loading wired

- Sync/Drift contract-drift read (S3) — skeleton paints before the result swaps in.
