---
phase: 166-host-tenant-and-repair-evidence
plan: "02"
subsystem: testing
tags: [ecto, sqlite, meilisearch, backfill, telemetry]

# Dependency graph
requires: []
provides:
  - "Live read-only report evidence for a known source/search mismatch."
  - "Selected-ID manual backfill evidence through exact task success and raw search visibility."
  - "One fixed-source repeat and an empty-selection no-op check."
affects: [166-03, readiness-evidence]

# Actuals
actuals:
  tokens: 4495
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Observe Meilisearch request-start events with a process-local correlation reference."
    - "Compare complete task snapshots and raw search controls around report and repair boundaries."

key-files:
  created: []
  modified:
    - test/scrypath/live_operator_verification_test.exs

key-decisions:
  - "Treat the missing source/search row as a known fixture precondition; reconcile evidence proves read-only behavior, not mismatch discovery."
  - "Constrain repair with an explicit Ecto ID predicate; batch_size limits individual batches only."
  - "Require every returned task to succeed on the selected index before repeating the same raw search oracle."

requirements-completed: [REPAIR-01, REPAIR-02]

coverage:
  - id: D1
    description: "A known missing raw document is reported without backend mutations, then restored by an explicit ID-scoped repair whose exact task succeeds and whose source/search controls remain correct."
    requirement: REPAIR-01
    verification:
      - kind: integration
        ref: "test/scrypath/live_operator_verification_test.exs#bounded manual repair restores the selected raw document"
        status: pass
      - kind: integration
        ref: "mix test test/scrypath/live_operator_verification_test.exs --only bounded_repair --trace"
        status: pass
    human_judgment: false
  - id: D2
    description: "The same fixed ID repair succeeds once more with a new task UID, while an empty selected-ID query submits no task and preserves raw controls."
    requirement: REPAIR-02
    verification:
      - kind: integration
        ref: "test/scrypath/live_operator_verification_test.exs#bounded manual repair restores the selected raw document"
        status: pass
      - kind: integration
        ref: "test/scrypath/live_operator_verification_test.exs#empty selected-ID repair submits no task and preserves raw controls"
        status: pass
      - kind: unit
        ref: "mix test test/scrypath/backfill_test.exs test/scrypath/operator/reconcile_test.exs test/scrypath/meilisearch/tasks_test.exs"
        status: pass
    human_judgment: false

# Metrics
duration: 14min
completed: 2026-09-27
status: complete
---

# Phase 166 Plan 02: Bounded Manual Repair Evidence Summary

**A selected source row was restored through a successful Meilisearch task, and the same raw search returned its projected value while controls held.**

## Performance

- **Duration:** 14 min
- **Started:** 2026-09-27T12:44:34Z
- **Completed:** 2026-09-27T12:58:00Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Established a source-backed/raw-search mismatch with source-only and already-visible controls.
- Observed the no-action reconcile request path, verified it made GET requests and no mutation requests, and confirmed complete task snapshots were unchanged.
- Repaired only the selected ID through public manual backfill; correlated each returned task UID to terminal success on the live index and verified the same raw search returned the expected projection.
- Repeated the fixed selected-ID scope with a distinct successful task and proved an empty selected-ID query submitted no task and preserved raw controls.

## Task Commits

1. **Task 1: Trace one known missing document through report, selected backfill, exact task and raw search** - `19d4df5` (test)
2. **Task 2: Expand the bounded repair oracle to one repeat, empty scope and fail-closed evidence** - `27d28ab` (test)

## Files Created/Modified

- `test/scrypath/live_operator_verification_test.exs` - Adds calibrated request observation, report task snapshots, ID-bounded repair and task assertions, raw search controls, one repeat, and an empty-scope no-op test.

## Decisions Made

- Kept the mismatch as a known test precondition; the report is not represented as source-row discovery.
- Used an explicit `where id in selected_ids` predicate as the total repair bound; `batch_size: 1` only defines batch size.
- Kept completion evidence separate across task UID, terminal state, index, and the repeated public raw-search result.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

None.

## User Setup Required

None - the test uses the existing local Meilisearch integration service and SQLite fixture repository.

## Test Results

- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 SCRYPATH_INTEGRATION=1 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix test test/scrypath/live_operator_verification_test.exs --only bounded_repair --trace` — 1 test, 0 failures.
- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 SCRYPATH_INTEGRATION=1 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix test test/scrypath/live_operator_verification_test.exs --only bounded_repair_empty --trace` — 1 test, 0 failures.
- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix test test/scrypath/backfill_test.exs test/scrypath/operator/reconcile_test.exs test/scrypath/meilisearch/tasks_test.exs` — 24 tests, 0 failures.
- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 SCRYPATH_INTEGRATION=1 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix test test/scrypath/live_operator_verification_test.exs --trace` — 4 tests, 0 failures.
- Formatter check on the modified test and `git diff --check` — passed.

The live repair receipt used SQLite `IntegrationRepo` and the local Meilisearch v1.15 service. The final full-module receipt reported index `scrypath-op-259_queryable_post`, selected ID `166000040`, repair task UIDs `119` and `120` both `succeeded`, three report reads, zero mutation requests, and 849 ms elapsed. The test data and IDs are synthetic. This evidence covers one root manual-repair workflow and one fixed-scope repeat; it does not establish Oban replay, exactly-once execution, concurrent ordering, full reindex recovery, package behavior, or a general latency guarantee.

## Next Phase Readiness

Plan 03 can combine this root repair receipt with the host path/package receipts and assess C-09 historical delete-receipt freshness. Readiness is not decided by this plan.

---
*Phase: 166-host-tenant-and-repair-evidence*
*Completed: 2026-09-27*

## Self-Check: PASSED

- Confirmed the modified test file exists and both Plan 02 task commits are present in git history.
- Re-ran the plan-level live integration and unit contract commands; all tests passed.
