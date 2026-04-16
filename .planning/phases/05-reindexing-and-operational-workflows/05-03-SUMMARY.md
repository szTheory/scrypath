---
phase: 05-reindexing-and-operational-workflows
plan: 03
subsystem: api
tags: [elixir, ecto, backfill, meilisearch, reindexing, tdd]
requires:
  - phase: 05-01
    provides: validated backfill options and schema settings reflection
  - phase: 05-02
    provides: Meilisearch-native index lifecycle helpers and target-index naming
provides:
  - explicit `Scrypath.backfill/2` bulk indexing entrypoint
  - deterministic primary-key cursor batching for bounded repo-driven backfills
  - per-batch result metadata with target index visibility for rebuild workflows
affects: [05-04, backfill, reindexing, operator-workflows]
tech-stack:
  added: []
  patterns: [repo-driven cursor batching, explicit manual backfill result envelopes]
key-files:
  created:
    - .planning/phases/05-reindexing-and-operational-workflows/05-03-SUMMARY.md
    - lib/scrypath/backfill.ex
    - test/scrypath/backfill_test.exs
  modified:
    - lib/scrypath.ex
key-decisions:
  - "Kept the public backfill verb on Scrypath while delegating the implementation to a dedicated Scrypath.Backfill module."
  - "Used primary-key cursor batching with `where > last_seen_id` instead of offset pagination so page edges stay stable."
  - "Returned explicit `batch_results` metadata so reindex orchestration can see target index and batch progress without pretending backfill is atomic."
patterns-established:
  - "Bulk backfill reads through the repo in explicit bounded queries and projects every record through Scrypath.Projection before backend writes."
  - "Target index overrides flow through every backend upsert via `index_name` instead of being recomputed inside the loop."
requirements-completed: [OPER-01]
duration: 3min
completed: 2026-04-16
---

# Phase 05 Plan 03: Backfill Summary

**Explicit `Scrypath.backfill/2` with repo-driven primary-key batching and target-index-aware result metadata**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-16T08:59:03-04:00
- **Completed:** 2026-04-16T09:01:20-04:00
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `Scrypath.backfill/2` and `Scrypath.Backfill` as the explicit public/manual bulk indexing path for existing rows.
- Implemented deterministic bounded batching over repo queries using primary-key ordering plus cursor progression instead of offset paging.
- Returned explicit cumulative and per-batch metadata, including target index visibility, for future reindex orchestration.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create the public backfill entrypoint and result contract per OPER-01** - `333a262` (test), `d555f74` (feat)
2. **Task 2: Implement deterministic repo-driven batching and backend writes per OPER-01** - `6815480` (test), `9b2bbff` (feat)

## Files Created/Modified

- `lib/scrypath.ex` - exposes `Scrypath.backfill/2` on the common public API.
- `lib/scrypath/backfill.ex` - validates runtime options, builds deterministic repo queries, and loops through bounded batches.
- `test/scrypath/backfill_test.exs` - covers result contract, scoped queries, exact batch boundaries, and target-index override behavior.

## Decisions Made

- Kept backfill synchronous and manual in v1 so the operator workflow stays explicit and batch-oriented.
- Cleared caller-supplied `order_by` and `limit` clauses inside the batching query so Scrypath can enforce deterministic primary-key pagination.
- Included `batch_results` in the return map to surface non-atomic workflow progress directly to callers.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Initial Task 1 implementation defaulted to the validator-produced `query: nil` value instead of the schema queryable. Fixed during the same task before the feature commit.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 5 now has the explicit backfill primitive that managed reindex orchestration can call into a live or rebuild target index.
- The next plan can focus on target index creation, settings application, cutover, and operator-facing recovery semantics on top of this batch contract.

## Self-Check: PASSED

- Summary file created at `.planning/phases/05-reindexing-and-operational-workflows/05-03-SUMMARY.md`
- Task commits present: `333a262`, `d555f74`, `6815480`, `9b2bbff`

---
*Phase: 05-reindexing-and-operational-workflows*
*Completed: 2026-04-16*
