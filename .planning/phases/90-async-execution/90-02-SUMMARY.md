---
phase: 90-async-execution
plan: 02
subsystem: sync
tags: [scrypath, related_worker, oban, tests, error-propagation]

# Dependency graph
requires:
  - 90-01 (RelatedWorker error propagation implementation)
provides:
  - Test coverage asserting the retry/cancel decision matrix for RelatedWorker.perform/1
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Behaviour-backed mock backends that return shaped errors per document title to drive worker branches

key-files:
  created: []
  modified:
    - test/scrypath/sync/related_worker_test.exs

key-decisions:
  - Used an ErrorBackend whose upsert_documents/3 returns a different error per document title (400/500/generic) so each Oban outcome branch is exercised through the real sync path.

requirements-completed:
  - DATA-03
  - EXEC-01

# Metrics
duration: recovered session
completed: 2026-05-25
---

# Phase 90: Plan 02 Summary

**Error-propagation test coverage for `RelatedWorker.perform/1`**

## Performance

- **Tasks:** 2
- **Files modified:** 1
- **Completed:** 2026-05-25 (recovered after a mid-execution crash)

## Accomplishments
- Added `ErrorTarget`, `ErrorBackend`, and `ErrorSchema` test helpers that route resolved records through the real `Scrypath.Sync.sync_records/3` path and return shaped backend errors.
- Added tests asserting the full retry/cancel decision matrix:
  - 4xx http_error → `{:cancel, "HTTP 400: \"Bad Request\""}`
  - 5xx http_error → `{:error, {:http_error, 500, "Internal Server Error"}}` (retry)
  - generic error → `{:error, :some_generic_error}` (retry)
  - invalid schema / fan_out → `{:cancel, {:invalid_job, reason}}`

## Task Commits

1. **Tasks 1 + 2: Invalid-argument cancellation and retry/cancel flows** — `508a39b` (test)

(Recovered as a single unit after the crash.)

## Files Created/Modified
- `test/scrypath/sync/related_worker_test.exs` — Added 5 tests and the error-path test helpers (`ErrorTarget`, `ErrorBackend`, `ErrorSchema`).

## Decisions Made
- `ErrorBackend.upsert_documents/3` matches on the projected document title to return 400/500/generic errors, exercising each `perform/1` branch end-to-end rather than stubbing `sync_records`.

## Deviations from Plan
None for the tests themselves. The implementation bug that made these tests fail is documented in `90-01-SUMMARY.md` (telemetry span mis-destructuring, fixed in `f5ca37e`).

## Issues Encountered
The tests were authored before the crash but failed until the 90-01 bug was fixed during recovery; they now pass (6 tests, 0 failures).

## User Setup Required
None.

## Next Phase Readiness
Phase 90 is complete and verified. v1.24 ready for Phase 91.

---
*Phase: 90-async-execution*
*Completed: 2026-05-25*
