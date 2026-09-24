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
  - "Revalidated hosted package acceptance on corrected candidate 7931271abe53e83261d85a22077176f75898eb81 in CI run 36000999039."
  - "Required gates and closeout attestation passed; advisory deep-quality still reports Mint 1.9.3 security advisories."
requirements-completed: [PKG-01, PKG-02, PROOF-01]
coverage:
  - id: D1
    description: "The exact candidate SHA built and tagged the package artifact, resolved staged dependency provenance, and compiled the consumer."
    requirement: PKG-01
    verification:
      - kind: integration
        ref: "https://github.com/szTheory/scrypath/actions/runs/36000999039/job/107637337872 — package artifact/tag, staged dependency, and consumer compile PASS markers"
        status: pass
    human_judgment: false
  - id: D2
    description: "The package-backed Phoenix integration scenarios completed against the hosted Postgres and Meilisearch services."
    requirement: PKG-02
    verification:
      - kind: e2e
        ref: "https://github.com/szTheory/scrypath/actions/runs/36000999039/job/107637337872 — 10 tests, 0 failures, integration completion marker, no integration exclusion"
        status: pass
    human_judgment: false
  - id: D3
    description: "The path-backed proof passed before the package-backed proof on the same candidate SHA."
    requirement: PROOF-01
    verification:
      - kind: other
        ref: "gh run view 36000999039 --json headSha,jobs — exact SHA and ordered success conclusions for both named steps"
        status: pass
    human_judgment: false
duration: 18min
completed: 2026-09-24
status: complete
plan_head_before: 7931271abe53e83261d85a22077176f75898eb81
commits: 1
---

# Phase 160 Plan 03: Exact-SHA hosted Phoenix package proof

**The tagged package artifact, staged lock provenance, consumer compile, and all four live Phoenix integration scenarios passed on corrected candidate SHA `7931271abe53e83261d85a22077176f75898eb81`.**

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
- After the initial candidate exposed a Credo `reraise` requirement, corrected package setup error propagation, reviewed the fix with no findings, and reran CI on the corrected candidate SHA.
- The corrected exact-SHA run passed all required jobs, the Phoenix path-then-package proof, ecommerce mounted proof, E2E advisory proof, and closeout attestation.

## Task Commits

1. **Task 1: Obtain and record the exact-SHA hosted package proof** — `bc2bcc3` (`docs(160-03): record exact-SHA package proof`).

## Files Created/Modified

- `.planning/phases/160-package-backed-phoenix-proof/160-VALIDATION.md` — exact-SHA job and package-stage acceptance evidence.
- `.planning/phases/160-package-backed-phoenix-proof/160-01-SUMMARY.md` — Plan 01 PKG-01 and PKG-02 acceptance reconciled to the hosted run.
- `.planning/phases/160-package-backed-phoenix-proof/160-03-SUMMARY.md` — this execution record.

## Decisions Made

- The candidate SHA, individual job, ordered command steps, and package log markers are the acceptance authority. Initial run 35998481376 is superseded for final evidence because the later `reraise` code correction changed the source candidate. Corrected run 36000999039 is the final evidence source: overall conclusion success, with required jobs and closeout attestation green. Its advisory deep-quality job fails at `mix hex.audit` on three Mint 1.9.3 advisories (two medium, one high), which remains a separate dependency follow-up.
- The earlier local cross-phase regression invocation remains recorded as an unresolved exit-code-2 result in the Plan 01 summary. It is outside this hosted package-proof task and is not represented as passing.

## Deviations from Plan

None — the exact-SHA hosted proof and evidence updates followed the plan. `gh run view --job --log` initially could not access its local log cache in the workspace sandbox; after the parent workflow completed, the prescribed hosted verification commands passed with the permitted read-only escalation.

**Total deviations:** 0 auto-fixed. **Impact:** No scope change; the required live-service acceptance is recorded and independently checkable.

## Issues Encountered

- Initial candidate CI run 35998481376 exposed the required core Credo issue (`raise` inside rescue); this was fixed in commit `29bf460`, reviewed cleanly, and validated on the exact corrected SHA by run 36000999039. Advisory deep-quality continues to fail on Mint 1.9.3 OSV/GHSA advisories, while the workflow's required gates and closeout attestation pass.
- Local Postgres/Meilisearch prerequisites were unavailable, so the previous local integration attempt could not serve as evidence. Hosted services supplied the required proof.

## Next Phase Readiness

The Phase 160 live package acceptance gap is closed with exact-SHA evidence. Phase verification can consume the updated validation map and summaries. The Mint advisories remain visible for dependency maintenance follow-up.

---
*Phase: 160-package-backed-phoenix-proof*
*Completed: 2026-09-24*

## Self-Check: PASSED

- Created evidence and summary files exist: `160-VALIDATION.md`, `160-01-SUMMARY.md`, and `160-03-SUMMARY.md`.
- Task commit exists: `bc2bcc3`.
- Exact-SHA run head, ordered job steps, package stage markers, and nonzero integration test result were rechecked successfully.
