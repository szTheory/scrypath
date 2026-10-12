---
phase: 175-repair-and-verification
plan: 04
subsystem: ops-ui
tags: [phoenix-liveview, meilisearch, promotion, document-observation]
requires:
  - phase: 175-02
    provides: guarded index promotion and correlated task observation
provides:
  - Applicable prepared-target document failures remain unconfirmed through promotion.
  - Same-task refresh preserves receipt and selected schema/index identity without another swap.
  - Promotion copy distinguishes a succeeded swap from a failed document observation and keeps no-effect freshness explicitly unchecked.
affects: [sync-drift, promotion, operator-recovery]
actuals:
  tokens: 13283
  tasks: 2
  commits: 11
plan_head_before: 819f2546def312a7e1f84c145da3cc7a09590448
tech-stack:
  added: []
  patterns:
    - Resolve receipt correlation and expected-effect availability before claiming document freshness.
    - Keep remote task outcome distinct from post-task observation outcome in status copy.
key-files:
  created:
    - .planning/phases/175-repair-and-verification/175-04-01-red.json
    - .planning/phases/175-repair-and-verification/175-04-02-red.json
    - .planning/phases/175-repair-and-verification/175-04-02-copy-clarity-red.json
  modified:
    - scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex
    - scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs
key-decisions:
  - "A matching receipt with an applicable expected effect makes every non-verified active-index observation a blocker for completed promotion."
  - "No applicable authoritative effect remains an explicit not-checked result and does not imply document freshness."
  - "Same-task refresh is observational and must not repeat the swap mutation."
patterns-established:
  - "Render document-observation reasons beside the retained task ID; suppress broader generic failure copy when the exact observation is available."
requirements-completed: [OPUX-21, OPUX-22]
coverage:
  - id: D1
    description: An applicable expected document effect cannot be reported complete when its source is unavailable, its active-index read is unavailable, or its observed document mismatches.
    requirement: OPUX-21
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs#correlated prepared-target document mismatch; correlated receipt with unavailable expected-effect source; unavailable expected-document read"
        status: pass
    human_judgment: false
  - id: D2
    description: A swap that succeeded remotely but whose expected-document observation is unavailable stays unconfirmed with its precise reason and retained task/receipt identity; same-task refresh never resubmits the swap.
    requirement: OPUX-22
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs#an unavailable expected-document read keeps a succeeded swap unconfirmed across refreshes"
        status: pass
      - kind: automated_ui
        ref: "Render assertions verify document-specific copy without contradictory generic failure text."
        status: pass
    human_judgment: false
  - id: D3
    description: With no applicable authoritative effect, promotion retains an explicit not-checked document-freshness disclosure.
    requirement: OPUX-21
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs#promotion without an applicable receipt says document freshness was not checked"
        status: pass
    human_judgment: false
duration: 24m
completed: 2026-10-11
status: complete
---

# Phase 175 Plan 04 Summary

**Promotion now stays unconfirmed when an applicable post-swap document effect cannot be verified, while the result preserves the exact task and observation reason.**

## Performance

- **Duration:** 24 min
- **Started:** 2026-10-11T11:02:48-04:00
- **Completed:** 2026-10-11T11:27:02-04:00
- **Tasks:** 2
- **Implementation files modified:** 2

## Accomplishments

- Reproduced and fixed the path where a correlated prepared-target receipt had an unavailable expected-effect source, allowing promotion to be marked complete.
- Propagated every non-verified applicable expected-document observation—including mismatch and unavailable active-index reads—to an unconfirmed promotion result.
- Rendered the succeeded remote swap separately from its unconfirmed document observation, preserved the reason and same-task refresh, and removed a contradictory generic live-index/contract sentence.
- Kept the no-applicable-effect control explicitly “not checked” without claiming observed freshness.
- Confirmed refresh reads task UID `991` twice and makes zero additional swap calls.
- Cleared stale evidence on a failed retained-task refresh and rendered its sanitized read reason with explicit same-task/no-resubmit guidance.

## Task Commits

1. **Task 1 RED:** `94f412c` — correlated receipt with unavailable expected-effect source; `RED_EVIDENCE_OK`.
2. **Task 1 GREEN:** `194cf68` — keep unavailable applicable evidence unconfirmed.
3. **Task 2 RED:** `a972ddd` — unavailable active-index read, no-effect control, and same-task refresh assertions; `RED_EVIDENCE_OK`.
4. **Task 2 GREEN:** `663b9b7` — distinguish succeeded swap from failed document observation.
5. **UI review follow-up RED:** `fa7d2bf` — reject contradictory generic failure copy; `RED_EVIDENCE_OK`.
6. **UI review follow-up GREEN:** `bcfa1d6` — suppress the generic sentence when exact document-observation evidence is rendered.
7. **Review follow-up RED:** `2d657c9` — clear stale verified evidence after a failed same-task refresh; `RED_EVIDENCE_OK`.
8. **Review follow-up GREEN:** `b65effa` — clear old promotion observation state as refresh begins and fails.
9. **UI review follow-up RED:** `1ee0e59` — require a sanitized task-read reason and explicit same-task/no-resubmit guidance; `RED_EVIDENCE_OK`.
10. **UI review follow-up GREEN:** `fdaf9b8` — render the read reason and recovery instruction while suppressing unrelated live-index failure copy.

**Plan metadata:** `819f254` — add the verified-gap closure plan.

## Files Created/Modified

- `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex` — propagate failed applicable observations and render stage-specific promotion copy.
- `scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs` — exercise correlated mismatch, unavailable source/read, explicit no-effect control, rendered reason, and same-task no-resubmit behavior.
- `.planning/phases/175-repair-and-verification/175-04-01-red.json` — classifier-approved RED record for unavailable expected-effect source.
- `.planning/phases/175-repair-and-verification/175-04-02-red.json` — classifier-approved RED record for the second task's unavailable read and control coverage.
- `.planning/phases/175-repair-and-verification/175-04-02-copy-clarity-red.json` — classifier-approved RED record for removing contradictory failure copy.
- `.planning/phases/175-repair-and-verification/175-04-03-stale-refresh-red.json` — classifier-approved RED record for hiding stale verified evidence while refresh is pending and after task-read failure.
- `.planning/phases/175-repair-and-verification/175-04-04-task-read-copy-red.json` — classifier-approved RED record for rendering a safe task-read reason and same-task recovery guidance.

## Decisions Made

- Receipt schema, target index, endpoint, generation, task UID, and applicable expected effect remain the correlation boundary. An applicable effect that cannot be verified must not reach `:completed`.
- Absence of an applicable authoritative effect preserves existing completion semantics only alongside an explicit not-checked disclosure.
- A refresh re-observes the stored task and evidence; it does not reissue the swap.
- Failed task reads clear the prior observation and expose only a bounded diagnostic category, followed by explicit guidance to inspect that same task without submitting another operation.

## Deviations from Plan

The planned mismatch regression already passed before implementation, showing that the mismatch path was already blocked. The failing path was a matching receipt whose expected-effect source returned `:source_unavailable`; that valid RED case exposed the same broad error-conversion defect. The mismatch case remains as a passing control, and the correction now propagates all non-verified applicable observations.

The Phase 175 UI review found that the first copy change left a broader generic failure sentence next to the more precise expected-document reason. A separate RED/GREEN pair removed that contradiction. This stays within the plan's two files and acceptance criteria.

No dependency, public API, authorization path, or swap mutation behavior changed.

## TDD Gate Compliance

- `175-04-01`: RED `94f412c` → GREEN `194cf68`; the unchanged TAP evidence was accepted by `gsd_run check tdd-red-evidence` as `RED_EVIDENCE_OK`.
- `175-04-02`: RED `a972ddd` → GREEN `663b9b7`; the unavailable-read and no-applicable-effect cases passed.
- UI review follow-up: RED `fa7d2bf` → GREEN `bcfa1d6`; the contradictory-copy assertion passed after the render condition was narrowed.
- Stale-refresh review follow-up: RED `2d657c9` → GREEN `b65effa`; classifier accepted the regression as `RED_EVIDENCE_OK`.
- Task-read copy follow-up: RED `1ee0e59` → GREEN `fdaf9b8`; classifier accepted the regression as `RED_EVIDENCE_OK`.

## Verification

- `mix format --check-formatted` — passed.
- Focused LiveView and document-observation suites — 44 tests, 0 failures on the final source.
- `mix precommit` — 266 tests + 2 doctests, 0 failures on the final source.
- `mix verify.ops_ui` — 266 tests + 2 doctests, 0 failures; Hex used an isolated cache under `/private/tmp` because the default `/Users/jon/.hex/cache.ets` is not writable in this worktree.
- Correlated mismatch, unavailable-source, unavailable-read, and no-applicable-effect gap probes — all passed.
- Failed same-task refresh regression — passes; task-read exits show the sanitized `task_observation_exit` reason and explicit “inspect this same task; do not submit another operation” guidance.
- Disposable mounted operator browser lane — 4/4 passed on `fdaf9b8`.
- Security mitigation audit — 12/12 threats closed, `threats_open: 0`.
- UI review — 23/24; the sole note is that the Sync and drift route was unavailable for updated-state screenshots, not an observed layout defect. The exact-source mounted lane passed.
- Cross-phase regression — bounded root Ops gate passed 266 tests + 2 doctests.

## Issues Encountered

The existing test suite can log a `posture_backend_exit` teardown message and LiveView's `start_async` warning while still exiting successfully. The final focused and full suite runs each passed; the unrelated `Scrypath.Sync.sync_related/3` Dialyzer warning is also unchanged.

## User Setup Required

None.

## Next Phase Readiness

Phase 175's verified promotion gap is closed. The approved Phase 176 Search and Playbooks plans are ready to execute after the phase-level goal verifier passes.

---
*Phase: 175-repair-and-verification*
*Completed: 2026-10-11*
