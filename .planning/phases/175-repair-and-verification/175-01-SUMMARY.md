---
phase: 175-repair-and-verification
plan: 01
subsystem: ops-ui
tags: [phoenix-liveview, oban, meilisearch, recovery, document-freshness]

# Dependency graph
requires:
  - phase: 174-recovery-entry-and-diagnosis
    provides: bounded recovery receipt and schema-preserving failed-work route
provides:
  - Separate receipt-derived document freshness evidence for recovery observations
  - Lifecycle-aware recovery status with retained identity and last observed snapshot
  - Selected-schema ordinary repair handoff after sync, contract, and document evidence
affects: [ops-ui, recovery, sync-drift]

# Actuals (#2632), measured from the plan diff at summary authoring time.
actuals:
  tokens: 9983
  tasks: 2
  commits: 4
plan_head_before: fcf8f41ffd134d391f375647470ac01108c6bfe9
plan_head_after: 4996eaf8eeae17643331b8d66c75290c0a735cf0

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Preserve last observed values and checked times while a same-operation refresh is loading or unavailable
    - Keep queue/backend lifecycle separate from expected-document observation state

key-files:
  created:
    - .planning/phases/175-repair-and-verification/175-01-01-red.json
    - .planning/phases/175-repair-and-verification/175-01-02-red.json
  modified:
    - scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex
    - scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs

key-decisions:
  - "Keep document freshness as its own receipt-correlated observation rather than inferring it from queue or contract status."
  - "Make refresh observational and retain the last successful snapshot until the same operation is checked again."
  - "Route ordinary repair through the existing selected-schema failed-sync path; keep index promotion advanced and separate."

patterns-established:
  - "Unknown observation errors preserve known operation identity, evidence, and the original checked time."
  - "Lifecycle copy distinguishes accepted, running, failed, canceled, and unconfirmed outcomes."

requirements-completed: [OPUX-20, OPUX-21]

# Coverage metadata
coverage:
  - id: D1
    description: "Recovery renders queue/backend, contract, and separate expected-document freshness evidence for the exact operation."
    requirement: OPUX-20
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs#verified document freshness renders the exact expected effect and index"
        status: pass
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs#recovery lifecycle states retain the receipt identity and distinguish observer errors"
        status: pass
    human_judgment: false
  - id: D2
    description: "Operators can follow a selected-schema ordinary repair path after diagnostic evidence while refresh retains the prior result."
    requirement: OPUX-21
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs#ordinary recovery follows diagnostic evidence and links to selected failed work"
        status: pass
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs#recovery refresh retains prior verification and stale results cannot replace it"
        status: pass
    human_judgment: false

# Metrics
duration: 21 min
completed: 2026-10-11
status: complete
---

# Phase 175 Plan 01: Repair and Verification Summary

**Receipt-correlated document freshness and lifecycle evidence now lead to the selected schema’s existing ordinary repair path.**

## Performance

- **Duration:** 21 min
- **Started:** 2026-10-11T11:30:01Z
- **Completed:** 2026-10-11T11:50:46Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Rendered expected-document effect and active-index evidence independently from queue and contract status, with explicit not-checked and unavailable states.
- Distinguished accepted, running, failed, canceled, verified, and unknown recovery outcomes while retaining the exact job, attempt, task UID, and last checked snapshot during refresh errors.
- Ordered the selected-schema ordinary failed-work handoff after sync, contract, and document evidence, with advanced index promotion remaining separate.

## Task Commits

Each task was committed atomically, including a validated RED test commit before implementation:

1. **Task 1 RED:** `99bf773` — failing document-freshness assertion; `RED_EVIDENCE_OK`.
2. **Task 1 GREEN:** `14d3068` — separate expected-document evidence.
3. **Task 2 RED:** `f1b0437` — refresh retention and recovery-order assertions; `RED_EVIDENCE_OK`.
4. **Task 2 GREEN:** `4996eaf` — lifecycle handling and ordinary recovery handoff.

## Files Created/Modified

- `.planning/phases/175-repair-and-verification/175-01-01-red.json` — machine-validated RED evidence for Task 1.
- `.planning/phases/175-repair-and-verification/175-01-02-red.json` — machine-validated RED evidence for Task 2.
- `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex` — observation lifecycle, snapshot retention, status copy, and recovery rendering.
- `scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs` — rendered and async regression coverage.

The private helpers `expected_document_ids/1` and `unchecked_document_observation/2` bound and represent receipt-derived document evidence. `recovery_status_copy/1` and the `document_observation_title/1`, `document_observation_kind/1`, and `document_observation_copy/1` helpers provide source-specific lifecycle copy and status treatment.

## Decisions Made

- Keep document freshness as a distinct receipt-correlated observation; queue completion and contract health alone cannot imply fresh documents.
- Keep refresh observational and preserve the previous result with its checked time until a new observation succeeds.
- Reuse the existing selected-schema failed-sync route for ordinary repair and leave index promotion in its advanced section.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserve snapshots when an async observer returns an unknown result**
- **Found during:** Task 2 (lifecycle and refresh assertions)
- **Issue:** The LiveView async result handler treated a `{status, nil, document_observation}` result as the status value, so unavailable reads could not retain the prior snapshot correctly.
- **Fix:** Added explicit handling for the nil-evidence tuple and preserved the prior status, evidence, document result, and checked time on observer errors.
- **Files modified:** `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex`
- **Verification:** Focused LiveView suite passed (21 tests); `mix verify.ops_ui` passed (256 tests).
- **Committed in:** `4996eaf` (Task 2 commit)

**Total deviations:** 1 auto-fixed (1 Rule 1 bug).
**Impact on plan:** Required for correct same-operation refresh behavior; scope stayed within the planned LiveView and its tests.

## Issues Encountered

- The first root-level `mix precommit` invocation found no such task. The project-required alias was then run from `scrypath_ops` and passed, including compile, format, and the 256-test suite.
- Compilation reported an existing type warning in `Scrypath.Sync`; the UI verification and app precommit checks passed. The optional UI suite also logs its expected fake posture-backend exit while testing observer failures.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The selected-schema diagnostics and ordinary repair handoff are covered and ready for downstream phase work.
- No new endpoint, schema, or public API was added.

---
*Phase: 175-repair-and-verification*
*Completed: 2026-10-11*

## Self-Check: PASSED

- Summary and all listed source, test, and RED evidence files exist.
- All four task commits are ancestors of the current worktree HEAD.
- Coverage metadata validates with both deliverables automatically covered.
