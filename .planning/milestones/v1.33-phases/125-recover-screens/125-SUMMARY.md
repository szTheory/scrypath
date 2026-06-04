---
phase: 125-recover-screens
plan: 125
subsystem: ui
tags: [phoenix, liveview, scrypath_ops, opsui, recover, responsive, loading, ecommerce-demo]
requires:
  - phase: 120-per-touchpoint-audit
    provides: Ranked backlog (B1, B6, S3, P22, P25 mapped to 125)
  - phase: 122-design-system-components
    provides: ops_loading primitive, ops-table-scroll affordance, ops-preflight tablet step
provides:
  - Posture per-schema table is usable at 390px (worst-first default sort + mobile swipe hint over the scroll affordance)
  - Sync/Drift renders ops_main_width={:wide} like every other screen — full-width preflight wizard + drift tables
  - Contract-drift read shows an ops_loading skeleton (deferred via :run_drift, event model unchanged)
  - Failed Sync triage-guidance disclosure opens on the empty/quiet state, collapses for a returning operator
affects: [scrypath_ops, examples/scrypath_ecommerce]
tech-stack:
  added: []
  patterns: [worst-first default sort, deferred-read loading state, finding-driven minimal behavior change]
key-files:
  created:
    - .planning/milestones/v1.33-phases/125-recover-screens/125-PLAN.md
    - .planning/milestones/v1.33-phases/125-recover-screens/125-SUMMARY.md
    - .planning/milestones/v1.33-phases/125-recover-screens/125-VERIFICATION.md
  modified:
    - scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex
    - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
    - scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs
    - examples/scrypath_ecommerce/e2e/admin_screenshot_matrix.spec.ts
requirements-completed: [RECOVER-01]
completed: 2026-06-03
commit: e1b9330
---

# Phase 125 Plan 125: Recover screens polish Summary

**The three densest Recover screens now read consistently across the state range and down to 390px:
the Posture table sorts worst-first with a mobile scroll cue, Sync/Drift gets the full `:wide` showcase
width with a real loading state on the contract-drift read, and Failed Sync surfaces its triage guidance
exactly when an operator needs it. No dispatch path, route, or mount changed.**

## Accomplishments

### B1 — Posture 11-col table at mobile (RECOVER-01)
- Default-sort the per-schema rows **worst-first** (`posture_rows_worst_first/1` + `posture_row_rank/1`):
  fetch error → backend failures → queue not observed / queue failures/retrying → clean; ties break
  alphabetically. A red schema now lands at the top of the scan path.
- Added a `sm:hidden` cue — "Worst-first. Swipe the table sideways to see every signal column." — over the
  `ops-table-scroll` shadow affordance that shipped in 122. Visually confirmed at 390px.

### B6 — Sync/Drift width (RECOVER-01)
- Added `ops_main_width={:wide}` to the Sync/Drift `Layouts.app`. The screen now matches every other
  screen's `max-w-7xl` column; the 4-step preflight wizard and declared-vs-live drift tables/chips get the
  full-width layout the screen was designed for. Visually confirmed on `03-sync-drift--*--desktop--drift`.

### S3 — Sync/Drift contract-drift loading
- `load_drift` sets `:drift_loading` and `send(self(), :run_drift)`; the bounded backend read runs in
  `handle_info(:run_drift, …)`, so the `ops_loading` skeleton paints before the result swaps in. The button
  gains `phx-disable-with`. Event name and read path are unchanged.

### Failed Sync states + rhythm
- Triage-guidance `ops_disclosure` now `open={@inspection.counts.total == 0}` — expanded on the empty/quiet
  first-visit state, collapsed for a returning operator with jobs to triage. (`ops_disclosure` gained an `open` attr.)
- Stacked evidence code blocks use `space-y-ops-2` instead of raw `mt-2` (P22).
- Inline `<code>` routed to `ops_inline_code` on Failed Sync + Sync/Drift (P25).

## No-contract-break
The only behavior change is the worst-first default ordering (a finding requirement) and the
deferred-read loading flag (the loading-state finding requires it). External event names, the search/drift
dispatch, routes, and mounts are untouched.

## Deferred
- P19 (preflight `sm:` 2-col tablet step), P20 (signal-table scroll), and the `ops-table-scroll` affordance
  itself all shipped in 121/122; nothing to add here. P31 (Posture "Refreshed" timestamp tile wrap) left as-is
  — the tile sizes fine at the captured widths; revisit only if 127 shell work surfaces a wrap.
