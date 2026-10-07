---
phase: 174-recovery-entry-and-diagnosis
plan: 01
subsystem: ui
tags: [phoenix-liveview, ecto, schema-selection, recovery, tdd]

requires:
  - phase: 173-shared-visual-foundation-and-operational-time
    provides: Shared Ops navigation, status, and recovery handoff patterns
provides:
  - Selected-schema recovery target through Control Room, Search health, and Failed sync work
  - Source-qualified internal identities for colliding failed-work IDs and generation-guarded retry events
  - Explicit unavailable/setup behavior and selection-bound receipt invalidation
affects: [174-02, 174-03, recovery-entry, failed-sync]

actuals:
  tokens: 8691
  tasks: 2
  commits: 5
  plan_head_before: b9f11292983c30ca76e1ea84f950d03b3138c9cd
  plan_head_after: 4225f0722e5c822fb4eda1763d4fbc37718c5d02

tech-stack:
  added: []
  patterns:
    - Canonical allowlist resolution separates recovery target from fleet ranking
    - Source-colliding failed-work IDs use source/schema-qualified internal keys

key-files:
  created:
    - .planning/phases/174-recovery-entry-and-diagnosis/174-01-T1-RED.json
    - .planning/phases/174-recovery-entry-and-diagnosis/174-01-T2-RED.json
    - .planning/phases/174-recovery-entry-and-diagnosis/deferred-items.md
  modified:
    - scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex
    - scrypath_ops/test/scrypath_ops_web/live/recovery_journey_live_test.exs
    - scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs

key-decisions:
  - "The canonical allowlisted schema query owns recovery targeting; fleet severity order remains independent evidence."
  - "Retry row identity includes schema and source when numeric IDs collide, and rendered retry events carry the inspection generation."

patterns-established:
  - "Recovery entry: carry the explicit selected schema in each rendered handoff; never infer it from the worst fleet row."
  - "Failed work: preserve public core IDs while qualifying internal UI identity only when source IDs collide."

requirements-completed: []
coverage:
  - id: D1
    description: "An allowed selected schema remains the recovery target across Control Room, Search health, and the rendered failed-work retry/status handoff."
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/recovery_journey_live_test.exs#selected A stays the recovery target while worse B is listed first"
        status: pass
    human_judgment: false
  - id: D2
    description: "Unavailable and empty selections do not produce another schema's recovery action; target changes clear receipts and reject old-generation retry events."
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/recovery_journey_live_test.exs#explicit unavailable and empty schema selections never become a recovery target"
        status: pass
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/recovery_journey_live_test.exs#selection changes invalidate receipts, confirmations, and inspected evidence"
        status: pass
    human_judgment: false
  - id: D3
    description: "A backend task and queue job sharing a numeric ID remain distinct LiveView rows and the queue retry acts on the queue source."
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/recovery_journey_live_test.exs#retry identifies the queue row when a backend task has the same numeric id"
        status: pass
    human_judgment: false

duration: 19min
completed: 2026-10-07
status: complete
---

# Phase 174 Plan 01: Recovery Entry and Diagnosis Summary

**A selected-schema recovery path now survives fleet diagnosis, safe retry, and status handoff, including unavailable targets and colliding backend/queue IDs.**

## Performance

- **Duration:** 19 min
- **Started:** 2026-10-07T11:59:45Z
- **Completed:** 2026-10-07T12:18:54Z
- **Tasks:** 2
- **Files modified or created:** 8

## Accomplishments

- Kept selected schema A as the recovery target through Control Room and Search health while B retained its worse fleet evidence; rendered A-scoped failed-work and Sync and drift handoffs.
- Exercised the existing retry gate and verified accepted replacement work retains the original failure without claiming terminal recovery.
- Rejected blank, hostile, unallowlisted, and removed explicit targets; represented an empty allowlist as setup state; cleared target-bound state and rejected stale retry generations after selection changes.
- Resolved duplicate LiveView IDs and ambiguous retry selection when a backend task and queue job shared numeric ID 501, without changing public core IDs.

## Task Commits

1. **Task 1: Prove selected A through diagnosis, supported retry and status handoff** — `0ad3e6a` (RED), `3b9d4d6` (GREEN; source SHA `3b9d4d663436b2787ae041e839a8a1a7416b5e2e`).
2. **Task 2: Guard explicit unavailable target and changed-target journey state** — `a9a200c` (RED), `fb62ff4` (GREEN; source SHA `fb62ff44289b603ea865249e2d611c4b8b196899`).
3. **Task 2 verification follow-up:** `4225f07` adds a visible assertion for stale-generation rejection.

The plan commit count of 5 is measured from `plan_head_before` to `plan_head_after`; the planning metadata commit is recorded separately after this summary.

**Plan metadata:** `e906400` (complete plan summary and state), `aad9c4f` (persist generated state sidecar).

## Files Created/Modified

- `scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex` — selected recovery target and scoped Search health entry.
- `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex` — selected target and scoped failed-work links alongside fleet-ranked evidence.
- `scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex` — source/schema-aware internal row identity and generation-guarded retries.
- `scrypath_ops/test/scrypath_ops_web/live/recovery_journey_live_test.exs` — rendered selected-target, collision, unavailable-target, and stale-selection contracts.
- `scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs` — aligned delete-row assertion with source-specific queue copy.
- `.planning/phases/174-recovery-entry-and-diagnosis/174-01-T1-RED.json` and `174-01-T2-RED.json` — freshly executed and classified TDD RED evidence.
- `.planning/phases/174-recovery-entry-and-diagnosis/deferred-items.md` — unrelated pre-existing core Dialyzer warning.

## Decisions Made

- Canonical allowlist resolution owns the recovery target; fleet ranking remains independent and does not select the recovery schema.
- Public core row IDs stay numeric. Internal identity uses schema/source qualification when different sources collide, and retry events carry the inspection generation to reject stale actions.

## TDD Gate Compliance

- **T1 RED:** `174-01-T1-RED.json` records the target test failing on the missing selected-schema recovery target; `gsd-tools check tdd-red-evidence` returned `RED_EVIDENCE_OK` with one failing target test.
- **T1 GREEN:** recovery journey passed 1/1 after implementation.
- **T2 RED:** `174-01-T2-RED.json` records the duplicate `failed-detail-501` LiveView ID for backend task and queue job 501; the evidence checker returned `RED_EVIDENCE_OK` with one failing target test.
- **T2 GREEN:** journey passed 4/4, FailedSyncLive passed 12/12, and PostureLive passed 14/14. All three test modules were run separately because two define the same fixture module `Oban.Job` and cannot be compiled together in one Mix invocation.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected the new rendered journey assertions while building the tracer**
- **Found during:** Task 1
- **Issue:** Multiple rendered rows made a broad selector ambiguous, the UI's list order differed from internal source order, and HTML-escaped query separators obscured the rendered handoff query.
- **Fix:** Scoped assertions to rendered row content/order and decoded the rendered query string before inspecting it.
- **Files modified:** `scrypath_ops/test/scrypath_ops_web/live/recovery_journey_live_test.exs`
- **Verification:** The focused journey passed 1/1 after the correction.
- **Committed in:** `3b9d4d6`.

**2. [Rule 1 - Bug] Distinguished same-number backend tasks and queue jobs in the Ops UI**
- **Found during:** Task 2
- **Issue:** Numeric-only row lookup and disclosure IDs collided, so LiveView rejected the page and retry lookup could select the wrong source.
- **Fix:** Qualified internal row identity with schema/source on collision and attached the inspection generation to retry events; public core IDs remain unchanged.
- **Files modified:** `scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex`, `scrypath_ops/test/scrypath_ops_web/live/recovery_journey_live_test.exs`
- **Verification:** The collision journey passed and accepted the queue retry for the correct row.
- **Committed in:** `fb62ff4`.

**3. [Rule 1 - Bug] Updated the existing queue-label assertion to the selected source-specific copy**
- **Found during:** Task 2 verification
- **Issue:** The existing test expected generic “Failed job” copy while the planned UI contract identifies queue rows as “Queue job.”
- **Fix:** Updated the assertion to check the source-specific queue label.
- **Files modified:** `scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs`
- **Verification:** FailedSyncLive passed 12/12.
- **Committed in:** `fb62ff4`.

---

**Total deviations:** 3 auto-fixed (Rule 1)
**Impact on plan:** Correctness gaps and test contracts discovered in the selected-schema journey were closed within the existing Ops UI; no public API or dependency changes.

## Issues Encountered

- The existing `lib/scrypath/sync.ex:61` Dialyzer incompatible-types warning appeared during test bootstrap. It predates this plan's source changes, so it was recorded in `deferred-items.md` and left untouched.
- Running the three LiveView test modules in one `mix test` invocation failed because two define the same fixture module `Oban.Job`; running each module independently passed all focused checks.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

The selected-schema recovery entry and diagnosis path is in place for the remaining Phase 174 plans. OPUX-16–19 remain unmarked at this plan boundary because `requirements.ready-ids` reports all four as blocked pending the other plans in Phase 174; no phase-wide requirement completion is claimed here. No browser or exact-source hosted proof is claimed by this plan; the automated server-rendered journey passed and final browser proof remains with Phase 174-08.

---
*Phase: 174-recovery-entry-and-diagnosis*
*Completed: 2026-10-07*

## Self-Check: PASSED

- Summary, RED evidence, deferred-items record, implementation files, and journey tests exist.
- All five task commits are ancestors of the current plan branch.
- Stub scan found no TODO/FIXME/placeholder patterns or empty-value UI stubs in plan-changed source and test files.
