---
phase: 45-posture-failure-triage
plan: "03"
subsystem: opsui
tags: [phoenix, liveview, scrypath]

requires: []
provides:
  - Failed sync triage LiveView over FailedSyncWorkInspection
affects: []

tech-stack:
  added: []
  patterns:
    - Rollups always from inspection.counts, not sliced entries

key-files:
  created:
    - scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs
  modified:
    - scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex

key-decisions:
  - "Schema select for multi-schema allowlists"
  - "Compact mode hides rollup strip only; counts remain in assigns"

patterns-established:
  - "reason_class_counts: true default path for failed sync view"

requirements-completed: [OPSUI-02]

duration: 0
completed: 2026-04-21
---

# Phase 45 plan 03 summary

Failed sync LiveView calls `Scrypath.failed_sync_work/2` with `reason_class_counts: true`, renders rollups from `counts`, read-only row details with guide pointers, and excludes any recovery actions.

## Self-Check: PASSED

- No `retry_sync_work` substring in LiveView module.
- `mix test test/scrypath_ops_web/live/failed_sync_live_test.exs` green.
