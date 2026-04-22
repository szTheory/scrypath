---
phase: 65-playbook-run-lifecycle-opsui
plan: "02"
subsystem: ui
tags: [elixir, phoenix_live_view, scrypath_ops, async, playbooks]
requires:
  - phase: 65-playbook-run-lifecycle-opsui
    provides: run failure enrichment and doc resolver payloads for PlaybookLive
provides:
  - async playbook execution lifecycle with explicit idle/running/ok/error assigns
  - shared scheduling path for preview Run and catalog Run now
  - deterministic LiveView coverage for async completion and superseded runs
affects: [phase-65-plan-03, opsui-playbook-run-lifecycle, opsui-run-catalog]
tech-stack:
  added: []
  patterns: [named start_async run pipeline, run_id-gated async result application]
key-files:
  created: []
  modified:
    - scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex
    - scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs
    - scrypath_ops/test/support/search_playground_stub_adapter.ex
key-decisions:
  - "Use a single @playbook_run_async_key and schedule_playbook_run/1 helper so preview Run and catalog Run now cannot drift."
  - "Auto-cancel and reset running work on load/import actions by bumping run_id, leaving stale async exits ignored instead of surfacing confusing duplicate outcomes."
patterns-established:
  - "PlaybookLive keeps run lifecycle in run_ui and applies async outcomes only when the active run_id still matches."
  - "Async LiveView tests use render_async/1, and slow-path cancellation coverage relies on a test-only stub adapter variant instead of sleeps in the LiveView."
requirements-completed: [OPS3-01]
duration: 4min
completed: 2026-04-22
---

# Phase 65 Plan 02: Async run lifecycle and catalog entry Summary

**PlaybookLive now runs saved playbooks through a shared async pipeline with run_id gating, timeout/cancel handling, and catalog Run now parity**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-22T18:52:45Z
- **Completed:** 2026-04-22T18:56:37Z
- **Tasks:** 1
- **Files modified:** 3

## Accomplishments
- Replaced synchronous `Runner.run_validated/3` execution in `PlaybookLive` with `start_async` / `handle_async`, explicit `run_ui` state, timeout messages, and cancel support.
- Added catalog `run_now` so workspace/example entries load, validate, preview, and run through the same scheduling function as preview `Run`.
- Updated LiveView tests for async completion and added deterministic supersede coverage with a slow test-only stub adapter mode.

## Task Commits

Each task was committed atomically:

1. **Task 1: Async run lifecycle and catalog entry** - `a033d72` (feat)

## Files Created/Modified
- `scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex` - Adds `run_ui`, async run scheduling, timeout/cancel handling, and catalog `run_now`.
- `scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` - Switches run assertions to `render_async/1` and covers `run_now` plus superseded runs.
- `scrypath_ops/test/support/search_playground_stub_adapter.ex` - Adds a slow test-only variant for deterministic async cancellation/supersede coverage.

## Decisions Made
- Kept `run_ui` as a plain assign map instead of introducing a dedicated struct so the LiveView state machine stays explicit and local to the UI.
- Chose the recommended auto-cancel-and-reset policy for load/import changes while a run is active, which avoids concurrent run ambiguity in one LiveView session.
- Normalized cancelled and timed-out async exits into explicit operator-facing atoms so later UI enrichment can build on stable reasons.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added a delayed stub adapter mode for async cancellation tests**
- **Found during:** Task 1 (Async run lifecycle and catalog entry)
- **Issue:** The existing stub adapter completed too quickly to prove cancellation and superseded-load behavior deterministically in `LiveViewTest`.
- **Fix:** Added a `:slow_ok` test-only variant in `SearchPlaygroundStubAdapter` and used it in the LiveView test covering superseded runs.
- **Files modified:** `scrypath_ops/test/support/search_playground_stub_adapter.ex`, `scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs`
- **Verification:** `cd scrypath_ops && mix test test/scrypath_ops_web/live/playbook_live_test.exs`
- **Committed in:** `a033d72` (part of task commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The deviation stayed inside test support and was required to verify the planned async lifecycle honestly. No product scope changed.

## Issues Encountered
None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- `PlaybookLive` now preserves raw `run_error` reasons alongside explicit lifecycle state, ready for Plan 03 failure-surface enrichment.
- Shared scheduling is in one helper, so Plan 03 can improve the run panel without needing to reconcile separate catalog and preview execution paths.

## Self-Check: PASSED
