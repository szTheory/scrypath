---
phase: 08-reliability-and-contract-hardening
plan: 01
subsystem: search
tags: [meilisearch, task-contracts, sync, testing]
requires: []
provides:
  - strict Meilisearch enqueue and poll task normalization
  - explicit invalid task payload error tuples
  - deterministic malformed-payload contract coverage
affects: [reindex, sync, telemetry]
tech-stack:
  added: []
  patterns: [strict tuple-returning task normalization, normalized task status atoms]
key-files:
  created: [.planning/phases/08-reliability-and-contract-hardening/08-01-SUMMARY.md]
  modified:
    - lib/scrypath/meilisearch.ex
    - lib/scrypath/meilisearch/tasks.ex
    - lib/scrypath/meilisearch/settings.ex
    - lib/scrypath/meilisearch/index_management.ex
    - test/scrypath/meilisearch/tasks_test.exs
    - test/scrypath/meilisearch_test.exs
    - test/scrypath/sync_test.exs
key-decisions:
  - "Normalized task status now collapses queued to enqueued and only emits the public atom set."
  - "Malformed initial and polled task payloads return {:invalid_task_payload, ...} instead of leaking through as success."
patterns-established:
  - "Meilisearch task-bearing helpers normalize client payloads through Scrypath.Meilisearch.normalize_task/2 before returning success."
  - "Shared sync/manual expectations assert normalized task status atoms instead of raw backend strings."
requirements-completed: [HARD-01, HARD-03]
duration: 16min
completed: 2026-04-16
---

# Phase 08: Reliability and Contract Hardening Summary

**Strict Meilisearch task normalization now rejects malformed enqueue and poll payloads while locking the shared sync contract to explicit status atoms**

## Performance

- **Duration:** 16 min
- **Started:** 2026-04-16T17:40:00Z
- **Completed:** 2026-04-16T17:56:26Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Hardened the Meilisearch enqueue and poll seams so malformed payloads return explicit `{:invalid_task_payload, ...}` tuples with stage metadata.
- Removed the permissive unknown-status fallback from inline task waiting and preserved the existing failed, cancelled, and timeout families.
- Added deterministic contract coverage for malformed initial payloads, unknown poll statuses, missing task ids, transport propagation, and normalized manual sync expectations.

## Task Commits

Each task was committed atomically:

1. **Task 1: Harden enqueue and poll task normalization per D-01 through D-05** - `8db7129` (fix)
2. **Task 2: Expand deterministic task contract tests for malformed payload and transport cases per D-11 through D-14** - `67e49d5` (test)

## Files Created/Modified
- `lib/scrypath/meilisearch.ex` - Shared strict task normalization with stage-aware invalid payload metadata.
- `lib/scrypath/meilisearch/tasks.ex` - Inline wait path now enforces the same contract for initial and polled tasks.
- `lib/scrypath/meilisearch/settings.ex` - Settings task responses now unwrap normalized tasks before returning success.
- `lib/scrypath/meilisearch/index_management.ex` - Reindex task responses now use the strict normalization boundary.
- `test/scrypath/meilisearch/tasks_test.exs` - Covers malformed initial/poll payloads, missing ids, transport errors, and preserved terminal tuples.
- `test/scrypath/meilisearch_test.exs` - Updates backend helper expectations to the normalized task contract.
- `test/scrypath/sync_test.exs` - Updates manual sync expectations to the normalized `:enqueued` task status.

## Decisions Made
- Reused `Scrypath.Meilisearch.normalize_task/2` as the single normalization seam so enqueue, poll, settings, and index-management paths cannot drift.
- Kept malformed payload details low-cardinality and inspectable with `stage`, normalized `task_uid`, and keyword `problems`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Propagated strict normalization through other Meilisearch task-bearing helpers**
- **Found during:** Task 1 (Harden enqueue and poll task normalization per D-01 through D-05)
- **Issue:** `apply_settings/3`, `create_index/3`, and `swap_indexes/2` would have returned `task: {:ok, task}` tuples or leaked malformed payloads as success after the core seam changed.
- **Fix:** Updated `lib/scrypath/meilisearch/settings.ex` and `lib/scrypath/meilisearch/index_management.ex` to unwrap normalized tasks before building success maps.
- **Files modified:** `lib/scrypath/meilisearch/settings.ex`, `lib/scrypath/meilisearch/index_management.ex`
- **Verification:** `mix test test/scrypath/meilisearch_test.exs --trace`
- **Committed in:** `8db7129`

**2. [Rule 2 - Missing Critical] Updated downstream tests to the normalized public task-status contract**
- **Found during:** Task 2 (Expand deterministic task contract tests for malformed payload and transport cases per D-11 through D-14)
- **Issue:** Existing sync and Meilisearch tests still asserted raw `"enqueued"` strings or old helper shapes after the stricter normalization landed.
- **Fix:** Updated shared sync and Meilisearch tests to assert normalized atom statuses and the unwrapped task maps.
- **Files modified:** `test/scrypath/meilisearch_test.exs`, `test/scrypath/sync_test.exs`
- **Verification:** `mix test test/scrypath/meilisearch/tasks_test.exs test/scrypath/sync_test.exs test/scrypath/meilisearch_test.exs --trace`
- **Committed in:** `67e49d5`

---

**Total deviations:** 2 auto-fixed (2 missing-critical correctness fixes)
**Impact on plan:** All deviations were required to keep the stricter contract coherent across existing Meilisearch task entrypoints and shared tests. No API widening.

## Issues Encountered
The plan’s baked-in `mix test ... -x` commands are not valid on the current Mix version in this repo. Verification was run with `--trace` instead.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
The shared Meilisearch task contract is now strict and test-locked, so Phase 08-02 can define empty-batch no-op behavior on top of a stable sync result surface.

## Self-Check: PASSED

---
*Phase: 08-reliability-and-contract-hardening*
*Completed: 2026-04-16*
