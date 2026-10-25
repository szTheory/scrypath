---
phase: 175-repair-and-verification
plan: 02
subsystem: ops-ui
tags: [phoenix-liveview, meilisearch, promotion, task-observation, document-freshness]

# Dependency graph
requires:
  - phase: 174-recovery-entry-and-diagnosis
    provides: bounded recovery receipts and selected-schema operation identity
  - phase: 175-repair-and-verification
    provides: plan 01 recovery lifecycle and document-freshness observations
provides:
  - Promotion completion requires matching terminal task and fresh selected index/contract evidence
  - Applicable prepared-target document effects are checked on the resolved active index
  - Refresh observes the retained task UID asynchronously without resubmitting a swap
affects: [ops-ui, sync-drift, promotion, recovery]

# Actuals (#2632), measured from the realized plan diff (25,483 characters / 4).
actuals:
  tokens: 6371
  tasks: 2
  commits: 4
  commits: 4
plan_head_before: 8b00f2580ac5057618343a14461ccc545439d692
plan_head_after: 3575d1413863fe6a1754246d6b3906f0cb7922ad

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Treat task completion and post-swap index/document proof as separate observations
    - Correlate asynchronous task refresh by both context generation and retained UID

key-files:
  created:
    - .planning/phases/175-repair-and-verification/175-02-01-red.json
    - .planning/phases/175-repair-and-verification/175-02-02-red.json
  modified:
    - scrypath_ops/lib/scrypath_ops/document_observation.ex
    - scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex
    - scrypath_ops/test/scrypath_ops/document_observation_test.exs
    - scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs

key-decisions:
  - "A successful swap task alone stays unknown until fresh selected live-index and contract evidence matches the accepted promotion identity."
  - "Expected document effects are checked only when authoritative prepared-target evidence applies; otherwise the UI reports not checked."
  - "Refresh reads the retained task UID asynchronously and never submits another swap."

requirements-completed: [OPUX-21, OPUX-22]

coverage:
  - id: D1
    description: "Promotion completion requires matching task identity and fresh live-index, contract, and applicable document-effect evidence."
    requirement: OPUX-21
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs#a successful swap task without fresh index evidence is not promotion completion"
        status: pass
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops/document_observation_test.exs#checks prepared effects against the explicitly resolved active index"
        status: pass
      - kind: integration
        ref: "mix test test/scrypath_ops/document_observation_test.exs test/scrypath_ops_web/live/sync_drift_live_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Operators can refresh the same promotion task and current server authorization without triggering a second swap."
    requirement: OPUX-22
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs#mounted promotion refresh reads the retained UID once without swapping again"
        status: pass
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs#swap live blocks impersonation before any refresh"
        status: pass
      - kind: integration
        ref: "mix verify.ops_ui"
        status: pass
    human_judgment: false

# Metrics
duration: 18 min
completed: 2026-10-11
status: complete
---

# Phase 175 Plan 02: Repair and Verification Summary

**Promotion success now requires fresh selected-index evidence, and refresh rechecks the retained task without submitting another swap.**

## Performance

- **Duration:** 18 min
- **Started:** 2026-10-11T12:04:17Z
- **Completed:** 2026-10-11T12:22:26Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Tied promotion completion to the accepted task UID and schema/live/target identity, then required fresh selected live-index and contract evidence.
- Added active-index verification for an applicable prepared-target document effect; absent authoritative identity remains explicitly not checked.
- Added asynchronous same-UID refresh with generation checks, distinct task failure/cancellation states, and no swap resubmission.

## Task Commits

Each task was committed atomically:

1. **Task 1: Prove promotion effect after its exact terminal task** - `f9f590a` (test), `64b0bf2` (feat)
2. **Task 2: Refresh the retained task and enforce current promotion gates** - `a9197ab` (test), `3575d14` (feat)

## Files Created/Modified

- `.planning/phases/175-repair-and-verification/175-02-01-red.json` - machine-validated RED evidence for the completion boundary regression.
- `.planning/phases/175-repair-and-verification/175-02-02-red.json` - machine-validated RED evidence for same-UID refresh.
- `scrypath_ops/lib/scrypath_ops/document_observation.ex` - checks expected prepared effects against the resolved active index.
- `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex` - proves post-swap effects and refreshes the retained task asynchronously.
- `scrypath_ops/test/scrypath_ops/document_observation_test.exs` - covers active-index effect reads and mismatches.
- `scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs` - covers exact task/evidence lifecycle and mounted refresh behavior.

## Decisions Made

- Kept task status separate from post-swap evidence so terminal success cannot stand in for a verified live-index change.
- Reused the existing Ops-side Meilisearch client and task normalization seam; no public Scrypath API was added.
- Kept missing expected document identity visible as not checked instead of inferring freshness.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

- ExUnit output is not accepted by the RED evidence classifier. A temporary TAP formatter produced the unchanged test report for both RED checks and was removed before the implementation commit.
- The first root `mix verify.ops_ui` invocation found root dependencies unavailable. After fetching the lockfile-pinned dependencies with `mix deps.get`, the canonical root gate passed.
- Verification emitted the existing Dialyzer warning at `lib/scrypath/sync.ex:61`; it is outside this plan’s changed files.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 175 plan 02 is complete. The phase’s remaining plan can build on the exact-task and evidence boundaries established here.

---
*Phase: 175-repair-and-verification*
*Completed: 2026-10-11*

## Self-Check: PASSED

- All six plan output files exist.
- All four task commits are ancestors of the current plan HEAD.
- The measured plan range contains four commits before this summary commit.
