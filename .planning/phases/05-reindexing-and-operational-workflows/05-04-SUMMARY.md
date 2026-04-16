---
phase: 05-reindexing-and-operational-workflows
plan: 04
subsystem: api
tags: [elixir, ecto, meilisearch, reindexing, operations, docs, tdd]
requires:
  - phase: 05-02
    provides: Meilisearch index lifecycle helpers and settings application
  - phase: 05-03
    provides: explicit backfill batching and target-index-aware result metadata
provides:
  - explicit `Scrypath.reindex/2` managed rebuild workflow
  - ordered reindex orchestration with optional cutover and operator-facing result metadata
  - operator documentation for drift detection, cutover review, eventual consistency, and recovery
affects: [operator-workflows, reindexing, backfill, docs, meilisearch]
tech-stack:
  added: []
  patterns: [TDD for workflow orchestration, explicit rebuild result maps, blunt operator docs]
key-files:
  created:
    - .planning/phases/05-reindexing-and-operational-workflows/05-04-SUMMARY.md
    - lib/scrypath/reindex.ex
    - test/scrypath/reindex_test.exs
  modified:
    - lib/scrypath.ex
    - README.md
    - ARCHITECTURE.md
key-decisions:
  - "Kept managed rebuilds on `Scrypath.reindex/2` while leaving Meilisearch-native lifecycle power under `Scrypath.Meilisearch`."
  - "Hard-coded the workflow order as create target, apply settings, backfill, then optional cutover."
  - "Documented `cutover?: false` as an inspection path, not a soft cutover."
patterns-established:
  - "Managed rebuilds validate reindex options up front and return an explicit result map instead of hiding workflow state."
  - "Operator docs use the same accepted-versus-visible semantics as the sync and Oban runtime paths."
requirements-completed: [OPER-02, OPER-03, OPER-05]
duration: 19min
completed: 2026-04-16
---

# Phase 05 Plan 04: Managed Reindex Summary

**Managed reindex orchestration with ordered target rebuild steps and operator docs for drift, cutover, and recovery**

## Performance

- **Duration:** 19 min
- **Started:** 2026-04-16T12:47:00Z
- **Completed:** 2026-04-16T13:06:04Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added `Scrypath.reindex/2` and `Scrypath.Reindex` as the explicit Phase 5 managed rebuild workflow.
- Locked the workflow order with focused tests that cover optional cutover and the operator-facing result contract.
- Updated `README.md` and `ARCHITECTURE.md` with concrete drift detection, eventual consistency, cutover review, and recovery guidance.

## Task Commits

Each task was committed atomically:

1. **Task 1: Build managed reindex orchestration per OPER-02 and OPER-03** - `b82b1de` (test), `79576c5` (feat)
2. **Task 2: Document drift, backfill, cutover, and recovery semantics per OPER-05** - `b4ef80c` (docs)

## Files Created/Modified

- `lib/scrypath.ex` - exposes `Scrypath.reindex/2` on the common public API.
- `lib/scrypath/reindex.ex` - validates reindex options and runs the ordered create/settings/backfill/cutover workflow.
- `test/scrypath/reindex_test.exs` - covers ordered operation flow, disabled cutover behavior, and required result fields.
- `README.md` - explains when to backfill the live index versus rebuild a target and how to detect drift.
- `ARCHITECTURE.md` - records the fixed reindex order and the recovery semantics the runtime surface exposes.

## Decisions Made

- Kept the managed workflow under `Scrypath.*` so operators get one intentional rebuild entrypoint without widening the common backend behaviour.
- Reused the Phase 5 backfill primitive inside reindex instead of creating a separate hidden write path.
- Left old-index cleanup out of managed reindex so cutover remains observable and reversible.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The reindex implementation needed to strip internal test hooks before option validation so `validate_reindex_options!/1` remained the ground truth for public runtime options.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 5 now has a single explicit managed rebuild workflow on top of the existing backfill and Meilisearch lifecycle helpers.
- The docs now explain how operators should decide between repair backfills and full rebuilds, and what accepted work does and does not guarantee.

## Self-Check: PASSED

- Summary file created at `.planning/phases/05-reindexing-and-operational-workflows/05-04-SUMMARY.md`
- Task commits present: `b82b1de`, `79576c5`, `b4ef80c`

---
*Phase: 05-reindexing-and-operational-workflows*
*Completed: 2026-04-16*
