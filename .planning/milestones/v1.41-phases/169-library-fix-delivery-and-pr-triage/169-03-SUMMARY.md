---
phase: 169-library-fix-delivery-and-pr-triage
plan: "03"
subsystem: testing
tags: [meilisearch, ecto, sqlite, bounded-backfill, integration-test]

requires:
  - phase: 169-01
    provides: corrected implementation candidate at the selected public-main base
provides:
  - Root service proof for read-only mismatch reporting and explicit-ID manual repair
  - Empty-scope no-op and fixed-scope repeatability boundaries
affects: [169-04, DELIV-02]

actuals:
  tokens: 4494
  tasks: 2
  commits: 2
  plan_head_before: 2089bd8ea27a793985669e15b7a00a5eb6074562

tech-stack:
  added: []
  patterns:
    - "Prove repair scope with an explicit Ecto ID predicate; batch_size only controls batching."
    - "Correlate the returned Meilisearch task to its index, terminal success, and the same raw search oracle."

key-files:
  created: []
  modified:
    - test/scrypath/live_operator_verification_test.exs

key-decisions:
  - "Treat the source/search mismatch as a known fixture condition; reconcile_sync observes task/index state but does not claim database-omission discovery."
  - "Keep the existing sanitized SCRYPATH_PHASE166_REPAIR receipt marker for downstream evidence consumers."
  - "Record only fixed-scope repeatability and empty-scope behavior; make no concurrency, retry-order, or exactly-once claim."

patterns-established:
  - "Calibrate the telemetry request observer with a setup write before asserting report-only no-mutation behavior."
  - "Keep source-only and already-visible controls in the source and raw-result assertions."

requirements-completed: [DELIV-02]
coverage:
  - id: D1
    description: "Known missing document is repaired only from its explicit selected-ID query after no-action inspection, and the successful task becomes visible in the same raw search."
    requirement: DELIV-02
    verification:
      - kind: integration
        ref: "test/scrypath/live_operator_verification_test.exs#bounded manual repair restores the selected raw document; SCRYPATH_INTEGRATION=1 mix test ... --only bounded_repair"
        status: pass
      - kind: integration
        ref: "mix verify.backend on candidate 1189dd6c010e0e1cbb395134c1abd16b4a8248a4"
        status: pass
    human_judgment: false
  - id: D2
    description: "Repeating the fixed ID scope produces a distinct successful task, while an empty selected-ID query submits no task or mutation and preserves the controls."
    requirement: DELIV-02
    verification:
      - kind: integration
        ref: "test/scrypath/live_operator_verification_test.exs#empty selected-ID repair submits no task and preserves raw controls; SCRYPATH_INTEGRATION=1 mix test ... --only bounded_repair_empty"
        status: pass
      - kind: integration
        ref: "mix verify.backend on candidate 1189dd6c010e0e1cbb395134c1abd16b4a8248a4"
        status: pass
    human_judgment: false

duration: "not measured"
completed: 2026-09-29
status: complete
---

# Phase 169 Plan 03: Bounded Manual Repair Summary

**Bounded manual repair now proves no-write inspection, selected-ID scope, successful task visibility, fixed-scope repeatability, and an empty-scope no-op against Meilisearch 1.15.**

## Performance

- **Duration:** Not measured.
- **Completed:** 2026-09-29.
- **Tasks:** 2.
- **Files modified:** 1.

## Accomplishments

- Carried the established bounded repair scenario into the clean Plan 01 candidate while retaining its existing live-operator tests.
- Proved the known target remained in SQLite after its indexed document was deleted; report-only reconciliation observed the task history without mutation or task-snapshot changes.
- Backfilled through an explicit `post.id in ^selected_ids` Ecto predicate, awaited the exact returned task for the expected index, then asserted the target ID and projection with source-only and already-visible controls in the same raw search.
- Preserved the distinct successful task on one repeat of the same fixed scope and proved an empty selected-ID scope creates zero batches, no task, and no Meilisearch request.

## Task Commits

1. **Task 1: Trace one selected document from known mismatch to visible repair** — `28963a951f6d788490ac4b6f9efaae71d4430d3b` (`test(169-03): trace bounded live repair`).
2. **Task 2: Preserve empty-scope and fixed-scope repeat boundaries** — `1189dd6c010e0e1cbb395134c1abd16b4a8248a4` (`test(169-03): preserve empty repair boundary`).

Both implementation commits are on candidate branch `worktree-agent-phase169-p03-candidate`. The candidate is based on `2089bd8ea27a793985669e15b7a00a5eb6074562`, and its final source SHA is `1189dd6c010e0e1cbb395134c1abd16b4a8248a4`.

## Verification and Receipts

- `SCRYPATH_INTEGRATION=1 mix test test/scrypath/live_operator_verification_test.exs --only bounded_repair --trace` — 1 test, 0 failures; repeated after the tracer task as required.
- `SCRYPATH_INTEGRATION=1 mix test test/scrypath/live_operator_verification_test.exs --only bounded_repair_empty --trace` — 1 test, 0 failures.
- `SCRYPATH_INTEGRATION=1 mix verify.backend` — exit 0. The live operator module ran 4 tests with 0 failures; the other backend integration modules also passed and the live gate did not skip.
- `mix format --check-formatted test/scrypath/live_operator_verification_test.exs` and `git diff --check` passed.
- Service tuple: task-owned `getmeili/meilisearch:v1.15`, reporting package version `1.15.2`; source database: SQLite `IntegrationRepo`; configuration was supplied through `SCRYPATH_MEILISEARCH_URL` and `SCRYPATH_INTEGRATION`.
- The final-source backend run emitted the preserved `SCRYPATH_PHASE166_REPAIR` receipt for index `scrypath-op-16066_queryable_post`: selected ID `166000020`; first/repeat tasks `94`/`95`, both `succeeded`; source-only ID `166000021`; visible control ID `166000022`; report observation 3 reads and 0 mutations. Raw target projection matched the expected ID, title, and body.
- The empty-scope test independently passed with `documents: 0`, `batches: 0`, no task result, no observed request, and unchanged source/raw controls.
- The plan-owned Meilisearch service was stopped after verification. No other service resources were touched.

## Decisions and Claim Limits

- `reconcile_sync/2` is asserted against the fixture's known source/search mismatch. The test does not claim the report discovers missing database rows.
- `batch_size: 1` is retained only for batch sizing; the explicit Ecto ID predicate is the repair boundary.
- This is one fixed-scope repeat and one empty-scope no-op. It does not claim concurrency, arbitrary retry ordering, or exactly-once semantics.

## Deviations from Plan

None — the planned proof and resource isolation were completed as specified.

## Issues Encountered

The fresh candidate worktree did not have fetched Mix dependencies. Locked dependencies were fetched with task-local Hex/Mix caches; the lockfile remained unchanged and the named integration tests and backend gate then passed.

## Next Phase Readiness

Plan 04 can join this root service proof with the Phoenix proof. The task evidence is bound to candidate SHA `1189dd6c010e0e1cbb395134c1abd16b4a8248a4`; the proof remains local integration evidence and makes no hosted delivery or package-publication claim.

## Self-Check: PASSED

- Both named scenarios and the service-backed backend gate passed on the candidate tree committed as `1189dd6c010e0e1cbb395134c1abd16b4a8248a4`.
- Candidate commits `28963a9` and `1189dd6` exist; only the plan-owned test file changed in the candidate.
- The task-owned Meilisearch service was stopped after verification.

---
*Phase: 169-library-fix-delivery-and-pr-triage*
*Plan: 03 — bounded manual repair proof*
