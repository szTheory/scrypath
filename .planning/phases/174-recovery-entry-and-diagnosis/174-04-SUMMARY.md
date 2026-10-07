---
phase: 174-recovery-entry-and-diagnosis
plan: 04
subsystem: ui
tags: [phoenix-liveview, ecto, operations-ui, elixir, tdd]
requires:
  - phase: 174-recovery-entry-and-diagnosis
    provides: approved UI contract and posture/navigation foundations from plans 01–03
provides:
  - Evidence-bounded Control Room summary with one schema-contextual Search health entry.
  - Source-local Posture Live records with stable schema-bound actions through worst-first reorder.
affects: [174-05, 174-06, 174-08, ops-ui, posture]
actuals:
  tokens: 6206
  tasks: 2
  commits: 6
plan_head_before: a3014929bd726e4eaf8140da6885af733cd73f52
plan_head_after: 029aa144e58721f34aa628f40c793e4f2cb42cc2
tech-stack:
  added: []
  patterns:
    - "Observed row-level failures remain separate from the selected recovery target."
    - "Schema-derived record and action IDs keep LiveView identity attached through worst-first reorder."
key-files:
  created:
    - .planning/phases/174-recovery-entry-and-diagnosis/174-04-T1-RED.json
    - .planning/phases/174-recovery-entry-and-diagnosis/174-04-T1-refresh-RED.json
    - .planning/phases/174-recovery-entry-and-diagnosis/174-04-T2-RED.json
  modified:
    - scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex
    - scrypath_ops/test/scrypath_ops_web/live/control_room_live_test.exs
    - scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex
    - scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs
    - scrypath_ops/assets/css/app.css
    - .planning/phases/174-recovery-entry-and-diagnosis/deferred-items.md
key-decisions:
  - "Use the bounded Posture summary rows for affected scope while preserving the URL-selected recovery target independently."
  - "Refresh runtime Scrypath options on each Control Room observation and carry the previous summary for source evidence retention."
  - "Keep existing Posture classification and ranking; stable schema-derived action IDs preserve record identity without changing severity."
requirements-completed: []
coverage:
  - id: D1
    description: "Control Room names the current affected scope, preserves a separate selected target, and reports unavailable source reason and retained success time."
    requirement: OPUX-16
    verification:
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops_web/live/control_room_live_test.exs#healthy Control Room presents one evidence-bounded Search health entry"
        status: pass
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops_web/live/control_room_live_test.exs#degraded scope stays separate from the selected recovery target"
        status: pass
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops_web/live/control_room_live_test.exs#refresh names unavailable evidence and keeps the previous successful observation"
        status: pass
    human_judgment: false
  - id: D2
    description: "Posture Live records retain source-local evidence and schema-specific action identity through worst-first reordering."
    requirement: OPUX-17
    verification:
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs#schema action identity stays with its record when refresh changes worst-first order"
        status: pass
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Rendered geometry, overflow, theme and browser focus behavior at the approved widths."
    verification: []
    human_judgment: false
    rationale: "Automated Plan08 owns live-browser geometry and focus proof; this is pending execution, not human review."
duration: 24min
completed: 2026-10-07
status: complete
commits: 6
---

# Phase 174 Plan 04: Recovery Entry and Diagnosis Summary

**Control Room now leads with observed affected schemas and one read-only health review, while Search health keeps source facts and actions attached to each schema.**

## Performance

- **Duration:** about 24 minutes
- **Started:** 2026-10-07T13:10:00Z (estimated; executor start was not separately timestamped)
- **Completed:** 2026-10-07T13:33:48Z
- **Tasks:** 2
- **Files modified:** 9 plan-diff files, including RED evidence and deferred-item tracking

## Accomplishments

- Control Room refresh now reads current runtime options and carries the prior observation forward. It lists affected allowlisted schemas with source-specific causes, prior success time when retained, and an observation-bounded zero state. The selected recovery target remains independently named; the single CTA reads “Review Search health.”
- Search health keeps the existing source calculations and worst-first classification, removes duplicate per-row badges, and assigns each schema’s failed-sync action a stable schema-derived DOM ID and schema-specific href. Backend and Queue evidence remains within each record; source groups stack until the available desktop width is sufficient.
- RED evidence was classified before implementation for all TDD task behavior. Task 1 used separate RED commits for the single review entry/scope and refresh-retention assertions; Task 2’s RED test exercised record reorder and failed specifically because the schema-derived action ID was absent.

## Task Commits

1. **Task 1 RED: evidence-bounded Control Room entry** — `33afdfb` (`test`)
2. **Task 1 RED: refresh retention** — `d6edf40` (`test`)
3. **Task 1 GREEN: Control Room recovery entry** — `b6a464d` (`feat`)
4. **Task 2 RED: Posture Live action identity** — `b1f838a` (`test`)
5. **Task 2 GREEN: Posture Live record actions** — `09ad490` (`feat`)
6. **Deferred full-suite finding** — `029aa14` (`docs`)

The summary is committed separately; tracking updates follow in their own commit.

## TDD Gate Compliance

- **Task 1 RED:** `174-04-T1-RED.json` and `174-04-T1-refresh-RED.json` each pass `check tdd-red-evidence` as `RED_EVIDENCE_OK`. The first failed on the missing “Review Search health” entry; the second failed on the absent unavailable-backend evidence after refresh. Test/evidence commits preceded source edits.
- **Task 1 GREEN:** Control Room LiveView suite passed, 11 tests, 0 failures.
- **Task 2 RED:** `174-04-T2-RED.json` passes `check tdd-red-evidence` as `RED_EVIDENCE_OK`. Its target test executed the reorder and failed on the missing schema-bound action ID. Test/evidence commit preceded source edits.
- **Task 2 GREEN:** Posture LiveView suite passed, 15 tests, 0 failures. No refactor-only commit was needed.

## Files Created/Modified

- `scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex` — refresh retention, affected scope, source reason/time and single review entry.
- `scrypath_ops/test/scrypath_ops_web/live/control_room_live_test.exs` — scoped CTA, degraded scope and retained refresh coverage.
- `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex` — stable schema-specific action IDs and simpler source-local record presentation.
- `scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs` — reorder identity coverage and source-local count assertion.
- `scrypath_ops/assets/css/app.css` — long-scope wrapping and responsive source-group breakpoint.
- `.planning/phases/174-recovery-entry-and-diagnosis/174-04-T*-RED.json` — unchanged TAP evidence and classifier records.
- `.planning/phases/174-recovery-entry-and-diagnosis/deferred-items.md` — preserves the prior warning and records an unrelated Ops precommit failure.

## Verification

- Control Room focused LiveView suite: **11 tests, 0 failures**.
- Posture Live focused LiveView suite: **15 tests, 0 failures**.
- Isolated SyncDrift failure case: **1 test, 0 failures**.
- `make -C examples/scrypath_ecommerce contrast`: **PASS**, 0 AA failures (35 AAA advisories).
- Ops `mix precommit`: compile/format and test execution reached completion, but **2 doctests and 263 tests reported 1 unrelated failure**. `SyncDriftLiveTest`’s linked Agent exits with its test process, then its `on_exit` callback tries to stop that already-dead PID. The test passes alone. This is recorded in `deferred-items.md`; no unrelated SyncDrift source was changed.
- The existing compiler type warning in `lib/scrypath/sync.ex:61` remains unchanged and is also recorded in the deferred ledger.
- Actual rendered width, overflow, theme and browser focus proof remains assigned to Plan08. The static comparison pages were not treated as production proof.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Refresh stale runtime options in Control Room**
- **Found during:** Task 1
- **Issue:** Refresh reused mount-time options, so a changed runtime client was not observed and the retention test stayed on the old result.
- **Fix:** Resolve `ScrypathOps.Schemas.scrypath_opts/0` for every refresh and retain the prior posture summary for evidence continuity.
- **Files modified:** `scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex`
- **Verification:** Control Room refresh failure test passed with the source reason and prior success timestamp.
- **Committed in:** `b6a464d`

**2. [Rule 3 - Blocking test fixture] Preserve the existing A-only timeout fixture**
- **Found during:** Task 2
- **Issue:** Extending the fake backend to fail either schema also made the existing timeout fixture delay both schemas, causing an unrelated prior assertion to fail.
- **Fix:** Limit the delay behavior to OpsPostA while retaining the new independent OpsPostB failure toggle.
- **Files modified:** `scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs`
- **Verification:** Posture Live suite passed, including the existing per-schema timeout retention test.
- **Committed in:** `09ad490`

**Total deviations:** 2 auto-fixed. **Impact:** Both corrections were needed to verify this plan’s refresh and reorder behaviors without altering severity calculations.

## Issues Encountered

The full Ops precommit test suite has a repeatable unrelated Agent teardown failure, while the named failing test passes in isolation. It remains deferred to the Sync and drift test owner.

## User Setup Required

None.

## Next Phase Readiness

Plans 05/06 can build on the evidence-bounded Control Room and source-local Search health records. Plan08 must still verify actual layout and focus behavior in the browser at its approved viewport matrix. The honest Plan03 TDD/history limitation in `174-EXECUTION-LIMITS.md` remains unchanged; no commit history was rewritten and this plan’s distinct RED/GREEN sequence does not retroactively alter it.

---
*Phase: 174-recovery-entry-and-diagnosis*
*Completed: 2026-10-07*

## Self-Check: PASSED

All three RED evidence files exist and validate; the six plan commits are ancestors of the current HEAD. The stub scan found no task-introduced placeholders. Its sole match was the pre-existing CSS comment describing the skeleton placeholder utility.

## Parent readiness reconciliation

Actual requirements.ready-ids174-04PLAN OPUX-16,OPUX-17 reportsready=[] andblocked=[OPUX-16,OPUX-17]; plans06/08 still declare theseIDs and have no summaries. Parent restores their requirement tracking toPending. Local04behavior is implemented and tested, while automated browser geometry/theme/focus remains08; human_judgment isfalse. No manual maintainer verification or simulated approval gates phasecompletion. The repeated SyncDrift test-cleanup race is being repaired by parent under ExUnit supervision and full-suite evidence will be recorded separately. Earlier04full-suite failures remain historical, not relabeled as green.

## Parent full-suite cleanup resolution

Parent replaced the SyncDrift fixture’s bare linked Agent and racing manual stop with ExUnit supervision. Actual compile exited0 and full Ops precommit passed263 tests plus2doctests,0failures (17.9s test runtime). See174-MIDWAVE3-CHECK.md and its retained native log; the earlier04full-suite failures above remain accurate historical results. Automated browser proof remains08; the layout is not awaiting human verification.
