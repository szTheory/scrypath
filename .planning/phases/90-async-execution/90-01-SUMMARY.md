---
phase: 90-async-execution
plan: 01
subsystem: sync
tags: [scrypath, related_worker, oban, error-propagation, cancellation]

# Dependency graph
requires:
  - 89-02 (sync_related execution + RelatedWorker enqueue path)
provides:
  - RelatedWorker.perform/1 that maps fan-out failures to actionable Oban outcomes
  - 4xx -> cancel, 5xx/generic -> retry, invalid args -> cancel
affects:
  - 90-02 (Error-handling test coverage)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Map domain results onto Oban worker return contract ({:cancel, _} vs {:error, _})
    - Graceful argument resolution with String.to_existing_atom + rescue ArgumentError

key-files:
  created: []
  modified:
    - lib/scrypath/sync/related_worker.ex

key-decisions:
  - HTTP 4xx is treated as permanent (cancel) and 5xx/generic as transient (retry, let Oban back off).
  - Invalid job arguments (unknown schema or fan_out) cancel the job rather than raising, so a bad enqueue never poisons the queue with crashing retries.

requirements-completed:
  - DATA-03
  - EXEC-01

# Metrics
duration: recovered session
completed: 2026-05-25
---

# Phase 90: Plan 01 Summary

**`RelatedWorker.perform/1` explicit error propagation and graceful argument resolution**

## Performance

- **Tasks:** 2
- **Files modified:** 1
- **Completed:** 2026-05-25 (recovered after a mid-execution crash; see Deviations)

## Accomplishments
- `perform/1` now resolves `schema` and `fan_out` arguments through `resolve_schema/1` and `resolve_fan_out/2`, returning `{:cancel, {:invalid_job, reason}}` for unknown schemas or fan_outs instead of crashing.
- The result of the resolve-and-sync span is pattern matched into the Oban worker contract:
  - `:ok` / `{:ok, _}` → `:ok`
  - `{:error, {:http_error, status, body}}` when `status in 400..499` → `{:cancel, "HTTP #{status}: ..."}` (permanent)
  - `{:error, reason}` → `{:error, reason}` (transient — Oban retries with backoff)

## Task Commits

1. **Tasks 1 + 2: Graceful argument resolution and robust error bubbling** — `f5ca37e` (feat)

(Recovered as a single unit after the crash; see Deviations below.)

## Files Created/Modified
- `lib/scrypath/sync/related_worker.ex` — Added `resolve_schema/1` and `resolve_fan_out/2`; rewrote `perform/1` to bubble up or cancel based on `Scrypath.Sync.sync_records/3` results.

## Decisions Made
- HTTP 4xx → permanent cancel; 5xx/generic → transient retry.
- Invalid job arguments cancel rather than raise.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Telemetry span result was mis-destructured**
- **Found during:** Recovery of the crashed execution (Plan 90-01 test verification).
- **Issue:** `perform/1` bound `{sync_result, _metadata} = Scrypath.Telemetry.span(...)`, but `Scrypath.Telemetry.span/3` returns the result **directly** (the same contract used by `Scrypath.Sync.sync_records/3` and `inline_resolve_and_sync/6`). An `{:error, reason}` result was therefore destructured into `sync_result = :error`, raising `CaseClauseError` on every failure path. The success path only passed by accident (`{:ok, map}` → `:ok`).
- **Fix:** Bind `sync_result = Scrypath.Telemetry.span(...)` directly.
- **Files modified:** `lib/scrypath/sync/related_worker.ex`
- **Verification:** All 6 tests in `test/scrypath/sync/related_worker_test.exs` pass; full suite green (493 tests, 0 failures).
- **Committed in:** `f5ca37e`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** None — the bug was the sole blocker; behavior now matches the plan's must-have truths.

## Issues Encountered
The original execution crashed during test verification; this summary documents the recovered, verified-green state.

## User Setup Required
None.

## Next Phase Readiness
The worker contract is verified by Plan 90-02's test suite. Phase 90 is complete; v1.24 is ready for Phase 91 (guides + verification).

---
*Phase: 90-async-execution*
*Completed: 2026-05-25*
