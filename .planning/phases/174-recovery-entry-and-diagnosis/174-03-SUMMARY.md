---
phase: 174-recovery-entry-and-diagnosis
plan: 03
subsystem: ops-recovery-safety
tags: [phoenix-liveview, sigra, recovery-observation, tdd]
requires:
  - phase: 174-recovery-entry-and-diagnosis
    provides: Plan 174-02's validated selected-schema navigation and handoff contract
provides:
  - Local sudo return paths preserve only the current canonical allowlisted schema
  - Sync Drift recovery callbacks discard outcomes after their selected target is removed
affects: [174-04, 174-05, 174-06, 174-07, 174-08]
actuals:
  tokens: 6525
  tasks: 2
  commits: 3
commits: 3
plan_head_before: 95882472f4aced1a6301284a808ee4be13a4f443
plan_head_after: 830e83d0fad84f3e8948703aea711f76f8bd2c60
tech-stack:
  added: []
  patterns:
    - "Construct return_to from a local path and append only a schema that resolves against the live allowlist."
    - "Apply recovery observer results only when generation, handle, and the current selected schema all still match."
key-files:
  created:
    - .planning/phases/174-recovery-entry-and-diagnosis/174-03-T1-RED.json
    - .planning/phases/174-recovery-entry-and-diagnosis/174-03-T2-RED.json
  modified:
    - scrypath_ops/lib/scrypath_ops/integrations/sigra/gating.ex
    - scrypath_ops/test/scrypath_ops/integrations/sigra/gating_test.exs
    - scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs
    - scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex
    - scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs
key-decisions:
  - "A sudo interruption keeps only a local return path and the canonical schema that is still allowlisted; arbitrary query data is not forwarded."
  - "A matching recovery generation and opaque handle are insufficient after allowlist removal; callback completion must revalidate the selected schema."
requirements-completed: []
coverage:
  - id: D1
    description: "Stale sudo return preserves the current validated schema on a local path and does not replay the interrupted retry."
    requirement: OPUX-18
    verification:
      - kind: unit
        ref: "gating_test.exs — validated canonical schema, excluded hostile query, invalid/removed selection, and cross-host return path"
        status: pass
      - kind: integration
        ref: "failed_sync_live_test.exs — stale sudo return retains OpsPostA and inserts no retry job"
        status: pass
      - kind: integration
        ref: "gating_test.exs + failed_sync_live_test.exs — 20 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D2
    description: "Removed targets and old recovery callbacks cannot leave A's status/evidence visible or transfer it to another schema."
    requirement: OPUX-19
    verification:
      - kind: unit
        ref: "sync_drift_live_test.exs — previous-generation observer is ignored and removed-schema success/exit clear the target"
        status: pass
      - kind: integration
        ref: "gating_test.exs, failed_sync_live_test.exs, sync_drift_live_test.exs — 39 tests, 0 failures"
        status: pass
    human_judgment: false
duration: 14m
completed: 2026-10-07
status: complete
---

# Phase 174 Plan 03: Safe Return and Current-Target Recovery Summary

**Sudo return preserves only the currently allowed schema, and removed targets cannot retain stale asynchronous recovery evidence.**

## Performance

- **Duration:** 14m
- **Started:** 2026-10-07T12:52:00Z
- **Completed:** 2026-10-07T13:06:25Z
- **Tasks:** 2
- **Files modified:** 7 (including two RED evidence records)

## Accomplishments

- Built stale-sudo return paths from a safe local route and added only the canonical schema after resolving it against the current allowlist. The host URI's arbitrary query is not carried into the return path.
- Preserved the existing host-owned sudo policy and prevented the interrupted retry from executing during return; the regression test confirms no replacement job was inserted.
- Revalidated the selected schema before applying either successful or failed Sync Drift recovery callbacks. If the selected schema was removed while observation was pending, the screen becomes unavailable and clears its handle, status, evidence, and loading state.
- Kept existing generation checks, confirmation invalidation, and accepted-versus-observed state behavior intact.

## Task Commits

1. **Task 1:** `3b515ea` — preserve validated schema through sudo return.
2. **Task 2 RED:** `699968d` — add removed-schema success and observer-exit regressions with classifier-validated TAP evidence.
3. **Task 2 GREEN:** `830e83d` — reject recovery results for removed schemas.

## TDD Test Evidence

| Task | RED evidence | GREEN verification | Status |
| --- | --- | --- | --- |
| 174-03-T1 | `174-03-T1-RED.json`: `RED_EVIDENCE_OK`; the intended return-path assertion failed in a 20-test TAP run, with the cross-host boundary also failing as expected | Gating and FailedSync LiveView tests: 20 tests, 0 failures | Pass |
| 174-03-T2 | `174-03-T2-RED.json`: `RED_EVIDENCE_OK`; both removed-target callback assertions failed in a 19-test TAP run because OpsPostA remained selected | Gating, FailedSync, and Sync Drift tests: 39 tests, 0 failures | Pass |

No separate refactor was needed. Full Ops `mix precommit` passed with 2 doctests and 259 tests, 0 failures. The existing compiler type warning at `lib/scrypath/sync.ex:61` remained unchanged. Browser navigation and host-authorization proof remain in the later browser plan; these LiveView results do not simulate host login or approval.

## Decisions Made

- The safe local return path is the only navigation input; schema identity is appended only after live allowlist validation.
- Recovery callback eligibility includes current selected-schema validation in addition to generation and opaque-handle equality.

## Deviations from Plan

None — plan executed as written.

## Deferred Issues

OPUX-18 and OPUX-19 are not yet ready to mark complete; the repository readiness check reports 0/2 ready because the remaining Phase 174 plans provide the broader required coverage.

## Self-Check: PASSED

- Summary and both RED evidence files exist.
- All three task commits are ancestors of `plan_head_after`.
- Both RED records return `RED_EVIDENCE_OK`.

## TDD commit-history boundary

Parent reconciliation confirms T1's real failing TAP report/classifier and later passing tests, but its RED test/evidence and implementation were committed together in3b515ea. T1 has no separate pre-implementation RED commit. Therefore the table above describes executed failing/passing test evidence, not a complete separate RED→GREEN Git sequence for T1. T2 has distinct699968d RED and830e83d GREEN commits. History is preserved without rewriting or fabricated retroactive RED. Global workflow.tdd_mode remains false; this process limitation is retained for the phase review, while required behavior is backed by runnable tests. Summary and tracking were also combined in66f0d89 rather than separately committed; that closeout ordering limitation remains disclosed. Future executors receive an explicit separate RED and separate SUMMARY-before-tracking commit requirement.
