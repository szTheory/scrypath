---
phase: 72-sigra-sensitive-action-wiring-in-opsui-liveviews
plan: 01
subsystem: ui
tags: [elixir, phoenix-liveview, sigra, opsui, gating, testing]

# Dependency graph
requires:
  - phase: 71-sigra-integration-foundation
    provides: Sigra integration modules, operator context contract, audit prefix taxonomy, and gate semantics
provides:
  - Sigra-gated confirm_delete handler in PlaybookLive
  - Sigra-gated retry handler in FailedSyncLive
  - LiveView regression coverage for stale-sudo redirects and in-place refresh behavior
affects: [phase-73-sigra-adopter-proof, scrypath_ops LiveView operator actions]

# Tech tracking
tech-stack:
  added: []
  patterns: [Sigra gate wrapper normalization, in-place LiveView refresh, test-only Oban.Job stub]

key-files:
  created: [.planning/phases/72-sigra-sensitive-action-wiring-in-opsui-liveviews/72-01-SUMMARY.md]
  modified:
    - scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex
    - scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs
    - scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs

key-decisions:
  - "Wrap only confirm_delete and retry in Gating.gate_sensitive_action/3; leave playbook run/run_now async and ungated."
  - "Preserve local UI state after successful delete/retry by refreshing the current slice in place instead of remounting."
  - "Strip operator-only inspection options before retrying and use a test-only Oban.Job stub so the queue retry path can be exercised without a real Oban dependency."

patterns-established:
  - "Pattern 1: Gate-sensitive LiveView handlers should normalize socket/tuple replies from the gate helper before returning {:noreply, socket}."
  - "Pattern 2: Retry actions should refresh the current inspection in place and leave page-local toggles such as compact_mode untouched."
  - "Pattern 3: Sigra stale-sudo tests can assert return_to-only redirects directly against the handler contract when a mounted LiveView would terminate on navigation."

requirements-completed: [SIGRA-06]

# Metrics
duration: 6m 12s
completed: 2026-04-26
---

# Phase 72: Sigra sensitive-action wiring in OPSUI LiveViews Summary

**Sigra-gated delete and retry wiring for OPSUI LiveViews, with in-place refresh semantics and regression coverage**

## Performance

- **Duration:** 6m 12s
- **Started:** 2026-04-26T21:37:10Z
- **Completed:** 2026-04-26T21:43:22Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- `PlaybookLive.confirm_delete` now routes through `Gating.gate_sensitive_action/3` while `run` and `run_now` stay on the existing async path.
- `FailedSyncLive.retry` now routes through the same gate, retries with runtime-only Scrypath options, and refreshes the inspection in place on success.
- The phase is covered by regressions for stale-sudo return-to redirects, delete cleanup, retry state preservation, and the unaffected playbook run flows.

## Task Commits

Each task was committed atomically:

1. **Task 1: Gate playbook delete without touching playbook run paths** - `6147e2f` (`fix`)
2. **Task 2: Add failed-sync retry and gate it with in-place refresh** - `8b3948b` (`fix`)

## Files Created/Modified
- [.planning/phases/72-sigra-sensitive-action-wiring-in-opsui-liveviews/72-01-SUMMARY.md](/Users/jon/projects/scrypath/.planning/phases/72-sigra-sensitive-action-wiring-in-opsui-liveviews/72-01-SUMMARY.md) - Phase summary and bookkeeping
- [scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex](/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex) - Sigra-gated delete handler with existing run/run_now behavior preserved
- [scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex](/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex) - Sigra-gated retry handler and in-place refresh logic
- [scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs](/Users/jon/projects/scrypath/scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs) - Stale-sudo redirect and delete-cleanup regressions
- [scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs](/Users/jon/projects/scrypath/scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs) - Retry gating, local-state preservation, and test-only Oban stub

## Decisions Made
- Keep the gate surface narrow: only `confirm_delete` and `retry` are wrapped in this phase.
- Preserve the existing playbook async lifecycle untouched so `run` and `run_now` remain ungated.
- Use runtime-only options for retry and a minimal test-only `Oban.Job` stub so the queue retry path can be verified without expanding production dependencies.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Retry initially forwarded operator-only inspection options into `Scrypath.retry_sync_work/2`**
- **Found during:** Task 2
- **Issue:** `oban_inspector`, `meilisearch_tasks`, and `oban_jobs` are operator-only inspection keys, not runtime retry options.
- **Fix:** Dropped operator-only keys with `ScrypathOps.Schemas.runtime_opts/1` before calling the retry engine.
- **Files modified:** [scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex](/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex)
- **Verification:** `mix test test/scrypath_ops_web/live/failed_sync_live_test.exs`
- **Committed in:** `8b3948b`

**2. [Rule 3 - Blocking] Failed-sync retry tests needed an Oban.Job stub in a workspace without the Oban package**
- **Found during:** Task 2
- **Issue:** The retry helper builds an `Oban.Job` changeset before insert; without a loaded `Oban.Job` module the test process failed before the LiveView assertion.
- **Fix:** Added a test-only top-level `Oban.Job` module in the failed-sync LiveView test file that returns a minimal changeset compatible with `apply_changes/1`.
- **Files modified:** [scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs](/Users/jon/projects/scrypath/scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs)
- **Verification:** `mix test test/scrypath_ops_web/live/failed_sync_live_test.exs`
- **Committed in:** `8b3948b`

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** No scope creep. Both fixes were required to make the planned retry path verifiable in this workspace.

## Issues Encountered
- LiveView push-navigate terminates the mounted test process on stale-sudo redirect, so the redirect regression for the gate was asserted against the handler contract directly instead of by reading LiveView process state after navigation.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- The phase 72 handler contract is stable: sensitive mutations are gated, the non-sensitive playbook execution paths are unchanged, and the local refresh behavior is regression-covered.
- Phase 73 can build on these handler contracts to document Sigra wiring and ship the worked example without revisiting the OPSUI action wiring.

---
*Phase: 72-sigra-sensitive-action-wiring-in-opsui-liveviews*
*Completed: 2026-04-26*

## Self-Check: PASSED

- Found summary file at `.planning/phases/72-sigra-sensitive-action-wiring-in-opsui-liveviews/72-01-SUMMARY.md`
- Found task commit `6147e2f`
- Found task commit `8b3948b`
