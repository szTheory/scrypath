---
phase: 174-recovery-entry-and-diagnosis
plan: 02
subsystem: ui
tags: [phoenix-liveview, recovery-navigation, ecto, tdd]

# Dependency graph
requires:
  - phase: 174-recovery-entry-and-diagnosis
    provides: Plan 174-01's recovery journey entry, URL selection contract, and test fixture patterns
provides:
  - Validated URL target visible in the shared Ops shell and contextual desktop/mobile recovery links
  - Consistent target propagation across health, failed-sync, and sync-drift views and handoffs
affects: [174-03, 174-04, 174-05, 174-06, 174-07, 174-08]

# Actuals (#2632); chars/4 over the realized plan diff.
actuals:
  tokens: 4953
  tasks: 2
  commits: 4
commits: 4
plan_head_before: 6508abbe2e75b0fc92a859195e0fa7783f5d0bdf
plan_head_after: 63368d2c582b68c295bf1671a328e033019f8de2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Resolve URL selection against the live allowlist before passing it to shared navigation."
    - "Apply contextual schema queries only to recovery destinations; keep fleet ranking independent."

key-files:
  created:
    - .planning/phases/174-recovery-entry-and-diagnosis/174-02-T1-RED.json
    - .planning/phases/174-recovery-entry-and-diagnosis/174-02-T2-RED.json
  modified:
    - scrypath_ops/lib/scrypath_ops_web/live/on_mount.ex
    - scrypath_ops/lib/scrypath_ops_web/nav.ex
    - scrypath_ops/lib/scrypath_ops_web/components/layouts.ex
    - scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex
    - scrypath_ops/test/scrypath_ops_web/live/control_room_live_test.exs
    - scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs

key-decisions:
  - "The validated URL remains the sole authority for the shared recovery target; absent fleet selection stays absent."
  - "Only health, failed-sync, and sync-drift shell links inherit the recovery target; Search and Playbooks keep their route ownership."

patterns-established:
  - "The shell displays the complete canonical module name and carries the same target in desktop and mobile recovery links."
  - "Page-level row links remain scoped to their row schema, independently from fleet-level navigation context."

requirements-completed: []
coverage:
  - id: D1
    description: "The shared shell displays a validated URL-selected schema and scopes recovery navigation on Control Room, health, failed-sync, and sync-drift surfaces."
    requirement: OPUX-19
    verification:
      - kind: unit
        ref: "test/scrypath_ops_web/live/control_room_live_test.exs — selected recovery target is named in both shell navs and scopes recovery links"
        status: pass
      - kind: integration
        ref: "test/scrypath_ops_web/ops_shell_contract_test.exs — shell recovery context follows the selected schema across health, failed work, and drift"
        status: pass
    human_judgment: false
  - id: D2
    description: "Changing the selected schema updates shared recovery links while row-level and return handoffs retain their intended schema."
    requirement: OPUX-19
    verification:
      - kind: integration
        ref: "MIX_TEST_PARTITION=174_wave1 mix test test/scrypath_ops_web/ops_shell_contract_test.exs test/scrypath_ops_web/live/posture_live_test.exs test/scrypath_ops_web/live/failed_sync_live_test.exs test/scrypath_ops_web/live/sync_drift_live_test.exs — 54 tests, 0 failures"
        status: pass
    human_judgment: false

# Metrics
duration: 20m
completed: 2026-10-07
status: complete
---

# Phase 174 Plan 02: Shared Recovery Target Summary

**A live-allowlist-validated URL target now stays visible and correctly scoped across the shared recovery shell.**

## Performance

- **Duration:** 20m
- **Started:** 2026-10-07T12:30:00Z
- **Completed:** 2026-10-07T12:49:21Z
- **Tasks:** 2
- **Files modified:** 11 (including two RED evidence records)

## Accomplishments

- Added a visible canonical recovery target and contextual health, failed-sync, and sync-drift links to both desktop and mobile shell navigation.
- Passed the validated target from OnMount through Control Room, health, failed-sync, and sync-drift layouts; selector patches update the target from the URL.
- Preserved separate fleet evidence and row-level intent, including the selected schema in failed-sync and sync-drift handoffs.

## Task Commits

1. **Task 1 RED:** `00413d6` — shell recovery navigation contract failed on the missing second contextual shell link.
2. **Task 1 GREEN:** `cb4e618` — validated target drives shared shell navigation.
3. **Task 2 RED:** `ff4599e` — shared recovery context was absent on Search health.
4. **Task 2 GREEN:** `63368d2` — target propagated across health, failed-sync, and sync-drift views.

## TDD Gate Compliance

| Task | RED evidence | GREEN verification | Status |
| --- | --- | --- | --- |
| 174-02-T1 | `174-02-T1-RED.json`: `RED_EVIDENCE_OK`; intended assertion failed with 8 tests discovered | Shell contract + Control Room tests: 18 tests, 0 failures | Pass |
| 174-02-T2 | `174-02-T2-RED.json`: `RED_EVIDENCE_OK`; intended assertion failed with 1 test discovered | Shell contract + posture, failed-sync, and sync-drift tests: 54 tests, 0 failures | Pass |

No separate refactor commit was needed. The final Ops `mix precommit` passed with 2 doctests and 254 tests, 0 failures. Rendered LiveView assertions cover exact schema-bearing hrefs in desktop/mobile nav and selector patch behavior; browser history/reload evidence remains in the later Phase 174-08 scope.

## Files Created/Modified

- `on_mount.ex` and `nav.ex` — validate the current URL target and constrain target-bearing links to recovery destinations.
- `layouts.ex` and the four recovery LiveViews — display and propagate the target through the shared shell.
- `control_room_live_test.exs` and `ops_shell_contract_test.exs` — assert invalid-target safety, visible target, contextual links, selector changes, and handoff URLs.
- `174-02-T1-RED.json` and `174-02-T2-RED.json` — preserve complete failing-test evidence and semantic assessments.

## Decisions Made

- URL selection remains authoritative. The shell only receives a target after allowlist resolution; an absent fleet target stays absent, and schema-specific pages retain their existing absent-parameter default.
- Recovery shell destinations carry the validated target, while Search and Playbooks stay unscoped and row actions continue to use the clicked row's schema.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Excluded `nil` from atom-valued navigation targets**
- **Found during:** Task 1
- **Issue:** Elixir treats `nil` as an atom, so an atom-only guard could emit a `schema=nil` recovery link.
- **Fix:** Required both an atom and a non-nil value before applying contextual recovery paths.
- **Files modified:** `scrypath_ops/lib/scrypath_ops_web/nav.ex`
- **Verification:** Control Room and shell navigation tests passed, including invalid and absent target cases.
- **Committed in:** `cb4e618`

**Total deviations:** 1 auto-fixed (Rule 1). **Impact:** A correctness edge case in target validation was closed within the planned navigation seam.

## Issues Encountered

The contract test's default fake deliberately returns an error for the selected OpsPostA index, which suppresses the inspection-only handoff. The test now uses a successful empty task response and a separate index prefix so it verifies the intended rendered handoff. No production behavior changed for this fixture.

The existing core compiler type warning at `lib/scrypath/sync.ex:61` appeared during the Ops checks and was not introduced by this plan.

## User Setup Required

None.

## Deferred Issues

OPUX-19 remains pending at the requirements layer because the readiness check reported 0/1 requirements ready after this plan alone. Phase 174's remaining plans provide its broader refresh/back-navigation and safety coverage.

## Self-Check: PASSED

- Summary file exists.
- All four task commits are ancestors of the plan head recorded above.
- The two RED evidence records classify as `RED_EVIDENCE_OK`.
