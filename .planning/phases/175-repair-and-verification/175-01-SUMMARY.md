---
phase: 175-repair-and-verification
plan: "01"
subsystem: ops-ui
tags: [phoenix-liveview, sync-status, index-configuration, ecto-schema]
requires:
  - phase: 174-recovery-entry-and-diagnosis
    provides: allowlisted schema selection, scoped recovery links, and operator navigation
provides:
  - Rendered proof that selected-schema sync and configuration observations use the visible selection and remain read-only
  - Explicit unavailable states for removed schema context and missing or incomplete sync observations
affects: [175-02, 175-04, 175-05, 175-06]
actuals:
  tokens: 1926
  tasks: 2
  commits: 4
plan_head_before: f553bec19df10c68c67510aa7c89b54f452f0b95
plan_head_after: 175dcfba115b835340180b4ed80cd7f7412b72be
tech-stack:
  added: []
  patterns:
    - Keep missing setup and failed required reads visibly distinct from complete zero-work observations
    - Preserve independent sync and index-configuration results
key-files:
  created:
    - .planning/phases/175-repair-and-verification/deferred-items.md
  modified:
    - scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex
    - scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs
key-decisions:
  - Keep the all-schema Search health destination available when the requested schema is unavailable.
  - Treat missing backend setup and failed backend/queue reads as unavailable evidence, never as zero work.
requirements-completed: []
coverage:
  - id: D1
    description: Rendered schema selection scopes sync and configuration observations while overview navigation remains all-schema and check controls remain read-only.
    requirement: OPUX-20
    verification:
      - kind: integration
        ref: scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs#rendered selection scopes both observations without submitting a mutation
        status: pass
    human_judgment: false
  - id: D2
    description: Complete, unavailable, partial, matching, and mismatching ordinary observations retain truthful independent results and expose affected configuration dimensions.
    requirement: OPUX-20
    verification:
      - kind: integration
        ref: scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs#missing backend renders an unavailable sync observation
        status: pass
      - kind: integration
        ref: scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs#sync read failure keeps an independent configuration result
        status: pass
      - kind: integration
        ref: scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs#multiple configuration differences expose each affected dimension
        status: pass
    human_judgment: false
duration: 6 min
completed: 2026-10-10
status: complete
commits: 4
---

# Phase 175 Plan 01: Selected-Schema Sync and Configuration Summary

**The rendered Sync and drift flow preserves the selected schema, keeps ordinary checks read-only, and states when sync evidence is unavailable.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-10-10T13:08:50Z
- **Completed:** 2026-10-10T13:15:11Z
- **Tasks:** 2
- **Files modified:** 3, including execution metadata

## Accomplishments

- Proved the visible selector updates the scoped URL and rendered observations for the second allowlisted schema; both overview destinations remain unscoped and the refresh/check actions do not submit a promotion mutation.
- Kept Search health navigation available when an invalid or removed schema remains in the URL, and gave the operator a safe next step.
- Distinguished missing backend configuration and failed required reads from a complete zero-work observation; successful configuration results remain visible when sync reads fail.
- Covered one and multiple configuration differences with the affected dimensions visible in the open comparison details.

## Task Commits

1. **Task 1: RED: rendered selected-schema and stale-context assertions** — `5ae0b6a` (test)
2. **Task 1: GREEN: preserve overview route and unavailable-schema guidance** — `3ab615d` (feat)
3. **Task 2: RED: missing backend and independent-result assertions** — `3b7a229` (test)
4. **Task 2: GREEN: render incomplete sync evidence explicitly** — `175dcfb` (feat)

## Files Created/Modified

- `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex` — preserves the all-schema destination and renders actionable unavailable/incomplete sync states.
- `scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs` — adds rendered selected-schema, stale-schema, missing-backend, independent-result, and multi-difference assertions.
- `.planning/phases/175-repair-and-verification/deferred-items.md` — records an unrelated existing core compile warning for later triage.

## Decisions Made

- An invalid or removed schema does not remove the all-schema Search health route.
- Missing backend setup and failed required backend/queue reads remain unavailable evidence; neither can render as a healthy zero-work result.
- OPUX-20 remains pending until the remaining Phase 175 plans and whole-phase evidence are complete.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserve the all-schema Search health return path for unavailable schema context**
- **Found during:** Task 1
- **Issue:** The Search health handoff disappeared when a requested schema was unavailable.
- **Fix:** Render the unscoped Search health handoff regardless of selected-schema state and show the safe selector instruction.
- **Files modified:** `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex`, `scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs`
- **Verification:** Focused LiveView suite passed, 24 tests, 0 failures.
- **Committed in:** `3ab615d`

**2. [Rule 2 - Missing Critical] Report missing or incomplete sync evidence on initial load**
- **Found during:** Task 2
- **Issue:** Missing backend configuration appeared as a not-yet-available observation, and failed reads did not name the unavailable backend/queue evidence.
- **Fix:** Assign a missing-backend error on mount and render explicit unavailable/incomplete copy while keeping configuration comparison independent.
- **Files modified:** `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex`, `scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs`
- **Verification:** Focused LiveView suite passed, 27 tests, 0 failures.
- **Committed in:** `175dcfb`

**Total deviations:** 2 auto-fixed (1 Rule 1, 1 Rule 2). **Impact:** Both corrections are within OPUX-20’s selected-scope and operational-truth requirements.

## Issues Encountered

- Focused Ops test compilation emits a pre-existing type warning at `lib/scrypath/sync.ex:61`; it is outside this plan's source ownership and is recorded in `deferred-items.md`.
- The focused command used the installed Elixir 1.19.5 / OTP 28.4.1 toolchain and passed 27 tests with zero failures. `mix format --check-formatted` also passed for both owned files.

## User Setup Required

None.

## Next Phase Readiness

Ready for Plan 175-02. OPUX-20 remains pending until the remaining Phase 175 behavior and phase-level executable proof are complete.

---
*Phase: 175-repair-and-verification*
*Completed: 2026-10-10*

## Self-Check: PASSED

The summary, both plan-owned source/test files, and all four task commits are present; coverage classification reports both deliverables auto-covered with passing evidence.
