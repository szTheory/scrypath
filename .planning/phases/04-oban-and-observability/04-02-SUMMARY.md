---
phase: 04-oban-and-observability
plan: 04-02
subsystem: api
tags: [elixir, oban, ecto-multi, workers, sync, meilisearch]
requires:
  - phase: 04-oban-and-observability
    provides: shared Oban sync contract, accepted result metadata, JSON-safe payload builders
provides:
  - durable Oban enqueueing on the shared Scrypath sync/delete verbs
  - dedicated upsert and delete workers that validate persisted args before backend execution
  - narrow Ecto.Multi helpers for composing data writes with Scrypath job inserts
affects: [phase-04-oban-and-observability, phase-05-reindexing-and-operational-workflows, docs]
tech-stack:
  added: [oban]
  patterns: [shared sync verbs enqueue durable jobs, workers validate persisted args before module resolution, Ecto.Multi composition through narrow Oban helpers]
key-files:
  created:
    - lib/scrypath/oban/enqueue.ex
    - lib/scrypath/oban.ex
    - lib/scrypath/oban/upsert_worker.ex
    - lib/scrypath/oban/delete_worker.ex
    - test/scrypath/oban/enqueue_test.exs
    - test/scrypath/oban_test.exs
    - test/scrypath/oban/worker_test.exs
  modified:
    - mix.exs
    - mix.lock
    - lib/scrypath/sync.ex
    - lib/scrypath/meilisearch.ex
    - test/scrypath/sync_test.exs
key-decisions:
  - "Kept Oban on the existing Scrypath sync verbs and surfaced queue-visible job metadata without adding a second runtime sync API."
  - "Validated persisted worker args before schema/backend resolution and used `{:cancel, {:invalid_job, reason}}` for terminal payload or config problems."
patterns-established:
  - "Use `Scrypath.Oban.Enqueue` to build shared worker changesets, then dispatch either directly or through `Ecto.Multi`."
  - "Worker execution rehydrates only normalized documents or resolved ids and injects an internal `:index_name` override for backend writes."
requirements-completed: [SYNC-05]
duration: 7 min
completed: 2026-04-16
---

# Phase 4 Plan 04-02: Real Oban Sync Execution Summary

**Optional Oban dependency wiring, durable shared-verb enqueueing, validated upsert/delete workers, and a narrow `Ecto.Multi` helper now make `sync_mode: :oban` a real production path**

## Performance

- **Duration:** 7 min
- **Started:** 2026-04-16T01:54:18Z
- **Completed:** 2026-04-16T02:01:01Z
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments

- Added the optional `oban` dependency and replaced the shared-verb `:oban` stub path with durable job insertion.
- Created separate upsert and delete workers that validate persisted args, avoid source-row reloads, and classify terminal payload/config failures distinctly from retryable backend failures.
- Added a minimal `Scrypath.Oban` helper for composing Scrypath job inserts inside `Ecto.Multi` without creating a parallel sync verb family.

## Task Commits

Each task was committed atomically:

1. **Task 1: Wire `sync_mode: :oban` into durable enqueue with optional dependency handling** - `e68cefc` (`test`)
2. **Task 1: Wire `sync_mode: :oban` into durable enqueue with optional dependency handling** - `d978dbd` (`feat`)
3. **Task 2: Add the transactional helper and separate upsert/delete workers** - `842576d` (`test`)
4. **Task 2: Add the transactional helper and separate upsert/delete workers** - `118f5fd` (`feat`)

## Files Created/Modified

- `mix.exs` - Added optional Oban dependency wiring for the library.
- `mix.lock` - Locked Oban and its dependency graph for reproducible installs.
- `lib/scrypath/sync.ex` - Routed `sync_mode: :oban` through real durable enqueueing.
- `lib/scrypath/oban/enqueue.ex` - Built worker changesets and normalized inserted-job metadata for shared sync results.
- `lib/scrypath/oban.ex` - Added narrow `Ecto.Multi` enqueue helpers for upsert and delete composition.
- `lib/scrypath/oban/upsert_worker.ex` - Validated persisted args, rebuilt normalized documents, and executed backend upserts.
- `lib/scrypath/oban/delete_worker.ex` - Validated persisted args, reused resolved ids, and executed backend deletes.
- `lib/scrypath/meilisearch.ex` - Honored internal index overrides so queued worker execution writes to the intended index.
- `test/scrypath/sync_test.exs` - Locked shared-verb enqueue metadata and optional dependency expectations.
- `test/scrypath/oban/enqueue_test.exs` - Locked durable enqueue behavior and caller batch boundaries.
- `test/scrypath/oban_test.exs` - Locked the narrow transactional helper surface.
- `test/scrypath/oban/worker_test.exs` - Locked worker execution, terminal validation failures, and retryable backend failures.

## Decisions Made

- Kept queue durability on the existing `Scrypath.*` verbs and used `Scrypath.Oban` only for `Ecto.Multi` composition.
- Reused the Phase 4 payload contract and rebuilt only normalized documents or resolved ids in workers, never source rows.
- Treated invalid persisted args and config resolution failures as cancelled jobs so impossible work does not retry forever.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Preserved explicit index targeting during worker execution**
- **Found during:** Task 2 (Add the transactional helper and separate upsert/delete workers)
- **Issue:** Persisted jobs carried the resolved index name, but backend execution would otherwise recompute the index from current runtime config and could drift from the originally enqueued target.
- **Fix:** Passed an internal `:index_name` override into worker-side backend execution and taught `Scrypath.Meilisearch` to honor it.
- **Files modified:** `lib/scrypath/meilisearch.ex`, `lib/scrypath/oban/upsert_worker.ex`, `lib/scrypath/oban/delete_worker.ex`
- **Verification:** `mix test test/scrypath/sync_test.exs test/scrypath/oban/enqueue_test.exs test/scrypath/oban_test.exs test/scrypath/oban/worker_test.exs`
- **Committed in:** `118f5fd` (part of task commit)

---

**Total deviations:** 1 auto-fixed (1 missing critical)
**Impact on plan:** The deviation was required for correctness in queued execution. No public API surface was widened.

## Issues Encountered

- Oban instance selection needed to support both real named instances and test doubles. The enqueue and `Ecto.Multi` helper paths now dispatch correctly to either a fake insert module or `Oban.insert(name, ...)`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 4 can now build Telemetry around a real durable queue path instead of a placeholder acceptance result.
- Later operational phases can rely on separate worker semantics, explicit terminal job cancellation, and transaction-friendly enqueue helpers.

## Self-Check: PASSED

- Verified summary target file exists: `.planning/phases/04-oban-and-observability/04-02-SUMMARY.md`
- Verified task commits exist: `e68cefc`, `d978dbd`, `842576d`, `118f5fd`
