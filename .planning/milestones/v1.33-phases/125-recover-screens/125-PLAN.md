# Phase 125 Plan: Recover screens polish (RECOVER-01)

**Phase:** 125-recover-screens
**Requirement:** RECOVER-01
**Branch:** `gsd/v1.33-admin-ui-insane-polish`
**Source backlog:** `.planning/milestones/v1.33-phases/120-per-touchpoint-audit/120-AUDIT-BACKLOG.md`

## Goal
Bring the three densest, least-iterated Recover data screens (Posture, Failed Sync, Sync/Drift)
to a consistent standard — responsive at 390px, full state coverage, clear scan path, brand
expression — with the Sync/Drift preflight wizard + drift chips getting the most depth.

## Backlog items mapped to 125
- **B1 (blocker)** — Posture 11-col table overflows mobile with no scroll cue.
- **B6 (blocker)** — Sync/Drift renders at narrow `:default` width while every other screen is `:wide`.
- **S3 (structural)** — Sync/Drift contract-drift "Run now" → result swap is instantaneous, no pending feedback.
- **P22** — Failed Sync stacked `ops_code_block` uses raw `mt-2`.
- **P25** — inline `<code>` (not `ops_inline_code`) on Failed Sync + Sync/Drift.
- Failed Sync explainer cards: collapse by default for returning operators, expanded on first/empty.
- State coverage across all three (empty/loading/populated/partial/error) using the seed scenarios.

## Approach (presentation + minimal, finding-driven behavior)
- B1: add a `sm:hidden` "Worst-first. Swipe the table sideways…" hint; default-sort the per-schema
  rows worst-first (`posture_rows_worst_first/1` + `posture_row_rank/1`). The `ops_table` scroll-shadow
  affordance (shipped 122) carries the rest. Worst-first is the one allowed minimal behavior change.
- B6: add `ops_main_width={:wide}` to Sync/Drift `Layouts.app`.
- S3: wire `ops_loading` — `load_drift` sets `:drift_loading` and `send(self(), :run_drift)`; the
  bounded read runs in `handle_info(:run_drift, …)`. Event name unchanged; skeleton paints first.
- P22: wrap the two stacked code blocks in `space-y-ops-2`, drop `mt-2`.
- P25: route inline `<code>` to `<.ops_inline_code>`.
- Failed Sync: `ops_disclosure` gains an `open` attr; Triage-guidance opens when the queue is empty
  (the first/quiet state), collapses when there are jobs to triage.

## Verification gate
1. `mix verify.opsui` green.
2. `cd scrypath_ops && mix test` green (update the two sync-drift assertions the S3 change touches).
3. `cd examples/scrypath_ecommerce && mix compile --warnings-as-errors` clean.
4. Boot + re-shoot the 40-shot matrix in both themes; confirm B1 (Posture mobile 390) + B6 (Sync/Drift width).
