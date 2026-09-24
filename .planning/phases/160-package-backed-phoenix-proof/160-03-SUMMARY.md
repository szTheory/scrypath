---
phase: 160-package-backed-phoenix-proof
plan: 03
subsystem: verification
tags: [github-actions, phoenix, package, meilisearch, exact-sha]
requires:
  - phase: 160-package-backed-phoenix-proof
    provides: "Package proof command and ordered advisory CI service lane"
provides:
  - "Exact-SHA hosted package build, provenance, compile, and live-service evidence"
  - "Reconciled Phase 160 Plan 01 PKG-01 and PKG-02 acceptance"
affects: [phase-160-verification, phase-160-closeout]
actuals:
  tokens: 6530
  tasks: 1
  commits: 1
tech-stack:
  added: []
  patterns: ["Hosted acceptance is attributed by exact run head SHA, ordered step conclusions, and job logs"]
key-files:
  created:
    - .planning/phases/160-package-backed-phoenix-proof/160-03-SUMMARY.md
  modified:
    - .planning/phases/160-package-backed-phoenix-proof/160-VALIDATION.md
    - .planning/phases/160-package-backed-phoenix-proof/160-01-SUMMARY.md
key-decisions:
  - "Accepted only CI run 35998481376 after matching its head SHA and inspecting the phoenix-example job steps and logs."
  - "Recorded the named Phoenix job as passing even though unrelated jobs caused the parent workflow run to conclude failure."
requirements-completed: [PKG-01, PKG-02, PROOF-01]
coverage:
  - id: D1
    description: "The exact candidate SHA built and tagged the package artifact, resolved staged dependency provenance, and compiled the consumer."
    requirement: PKG-01
    verification:
      - kind: integration
        ref: "https://github.com/szTheory/scrypath/actions/runs/35998481376/job/107629043080 — package artifact/tag, staged dependency, and consumer compile PASS markers"
        status: pass
    human_judgment: false
  - id: D2
    description: "The package-backed Phoenix integration scenarios completed against the hosted Postgres and Meilisearch services."
    requirement: PKG-02
    verification:
      - kind: e2e
        ref: "https://github.com/szTheory/scrypath/actions/runs/35998481376/job/107629043080 — 10 tests, 0 failures, integration completion marker, no integration exclusion"
        status: pass
    human_judgment: false
  - id: D3
    description: "The path-backed proof passed before the package-backed proof on the same candidate SHA."
    requirement: PROOF-01
    verification:
      - kind: other
        ref: "gh run view 35998481376 --json headSha,jobs — exact SHA and ordered success conclusions for both named steps"
        status: pass
    human_judgment: false
duration: 18min
completed: 2026-09-24
status: complete
plan_head_before: d7b499b93d9ebcc4c84b16c316266fa524dfc61a
commits: 1
---

# Phase 160 Plan 03: Exact-SHA hosted Phoenix package proof

**The tagged package artifact, staged lock provenance, consumer compile, and all four live Phoenix integration scenarios passed on candidate SHA `d7b499b93d9ebcc4c84b16c316266fa524dfc61a`.**

## Performance

- **Duration:** 18 min
- **Started:** 2026-09-24T12:18:00Z
- **Completed:** 2026-09-24T12:36:00Z
- **Tasks:** 1
- **Files modified:** 3

## Accomplishments

- Pushed the candidate branch normally and dispatched CI run [35998481376](https://github.com/szTheory/scrypath/actions/runs/35998481376); the run head SHA exactly matched the candidate.
- Verified `phoenix-example (advisory)` job 107629043080 succeeded, with `mix verify.phoenix_example` passing before `mix verify.phoenix_example --package`.
- Inspected package logs: artifact `v0.3.10` built and tagged, staged dependencies resolved to `file:///tmp/scrypath-phoenix-package-1/artifact` at that tag, consumer compiled, and integration scenarios completed with **10 tests, 0 failures** and no integration exclusion.
- Reconciled Plan 01 and the Phase 160 validation map with the hosted proof.

## Task Commits

1. **Task 1: Obtain and record the exact-SHA hosted package proof** — `bc2bcc3` (`docs(160-03): record exact-SHA package proof`).

## Files Created/Modified

- `.planning/phases/160-package-backed-phoenix-proof/160-VALIDATION.md` — exact-SHA job and package-stage acceptance evidence.
- `.planning/phases/160-package-backed-phoenix-proof/160-01-SUMMARY.md` — Plan 01 PKG-01 and PKG-02 acceptance reconciled to the hosted run.
- `.planning/phases/160-package-backed-phoenix-proof/160-03-SUMMARY.md` — this execution record.

## Decisions Made

- The candidate SHA, individual job, ordered command steps, and package log markers are the acceptance authority. The parent CI run concluded failure because `deep-quality (advisory)`, `core (required)`, and `closeout-attestation` failed; these outcomes do not change the successful named Phoenix job evidence and were not represented as a green full run.
- The earlier local cross-phase regression invocation remains recorded as an unresolved exit-code-2 result in the Plan 01 summary. It is outside this hosted package-proof task and is not represented as passing.

## Deviations from Plan

None — the exact-SHA hosted proof and evidence updates followed the plan. `gh run view --job --log` initially could not access its local log cache in the workspace sandbox; after the parent workflow completed, the prescribed hosted verification commands passed with the permitted read-only escalation.

**Total deviations:** 0 auto-fixed. **Impact:** No scope change; the required live-service acceptance is recorded and independently checkable.

## Issues Encountered

- The parent workflow concluded failure in three other jobs: `deep-quality (advisory)`, `core (required)`, and `closeout-attestation`. The target `phoenix-example (advisory)` job and both proof steps passed. These unrelated CI failures are retained for visibility and were not changed by this plan.
- Local Postgres/Meilisearch prerequisites were unavailable, so the previous local integration attempt could not serve as evidence. Hosted services supplied the required proof.

## Next Phase Readiness

The Phase 160 live package acceptance gap is closed with exact-SHA evidence. Phase verification can consume the updated validation map and Plan 01 summary. The parent workflow's other failed jobs remain visible for the repository's broader CI follow-up.

---
*Phase: 160-package-backed-phoenix-proof*
*Completed: 2026-09-24*

## Self-Check: PASSED

- Created evidence and summary files exist: `160-VALIDATION.md`, `160-01-SUMMARY.md`, and `160-03-SUMMARY.md`.
- Task commit exists: `bc2bcc3`.
- Exact-SHA run head, ordered job steps, package stage markers, and nonzero integration test result were rechecked successfully.
