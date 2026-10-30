---
phase: 184-explicit-and-lean-dependency-graphs
plan: "10"
subsystem: dependencies
tags: [elixir, mix, hex, dependency-audit, ci]

requires:
  - phase: 184-09
    provides:
      - Final dependency locks and supported integration boundaries
provides:
  - Source-bound four-graph audit evidence and all ten proposal dispositions
  - Negative contracts for graph and proposal evidence completeness
  - Candidate acceptance and validation records with known gate limits
affects: [phase-184-closeout, release-readiness, future-dependency-updates]

actuals:
  tokens: 9790
  tasks: 2
  commits: 4
  plan_head_before: f1384a7323f1ac69cf813a463e479df68bc6a9bf
  plan_head_after: b5cfdfbd74d777c7ca9ac82c94c014c9bd0ac19c

tech-stack:
  added: []
  patterns:
    - Per-graph evidence records bind source, manifest, lock, toolchain, audit result, and raw receipts.
    - Completeness contracts reject missing or duplicate graph and proposal identities.

key-files:
  created:
    - .planning/phases/184-explicit-and-lean-dependency-graphs/184-ACCEPTANCE.md
    - .planning/phases/184-explicit-and-lean-dependency-graphs/184-10-SUMMARY.md
  modified:
    - .planning/phases/184-explicit-and-lean-dependency-graphs/184-ACTIONS-DISPOSITIONS.md
    - .planning/phases/184-explicit-and-lean-dependency-graphs/184-DEPENDENCY-EVIDENCE.md
    - .planning/phases/184-explicit-and-lean-dependency-graphs/184-VALIDATION.md
    - test/mix/tasks/dependency_audit_test.exs
    - test/mix/tasks/dependency_boundary_contract_test.exs

key-decisions:
  - Keep the two Ops Cloak advisories visible and unaccepted; do not add ignores or infer risk acceptance.
  - Record only the locally exercised Elixir 1.19.5 / OTP 28.5 tuple as proven until exact-source hosted matrix evidence is inspected.
  - Do not collect retained-preview evidence while its required source preflight rejects stale main provenance.

patterns-established:
  - Each graph audit stores raw output and exact manifest/lock/source identities alongside its true exit status.
  - Proposal disposition contracts require every proposal to have a unique complete evidence and revisit record.

requirements-completed: [DEP-01, DEP-02, DEP-03, DEP-04, DEP-05, DEP-06, DEP-07]

coverage:
  - id: D1
    description: Negative contract tests reject incomplete, duplicate, and mismatched graph and proposal evidence identities.
    requirement: DEP-07
    verification:
      - kind: unit
        ref: "/private/tmp/scrypath-phase184-10-20261030T072352Z/bin/mix test test/mix/tasks/dependency_audit_test.exs test/mix/tasks/dependency_boundary_contract_test.exs --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: Four graph audit outcomes and ten proposal dispositions preserve exact identities and visible residual findings.
    requirement: DEP-07
    verification:
      - kind: other
        ref: "/private/tmp/scrypath-phase184-10-20261030T072352Z/receipts/dependency-audit-final.exit"
        status: fail
      - kind: other
        ref: ".planning/phases/184-explicit-and-lean-dependency-graphs/184-ACTIONS-DISPOSITIONS.md"
        status: pass
    human_judgment: true
    rationale: "Ops still reports two unaccepted Cloak advisories; the evidence must not convert that result into accepted risk."
  - id: D3
    description: Candidate acceptance and validation records state local gate outcomes and the exact-source hosted closeout boundary.
    requirement: DEP-01
    verification:
      - kind: other
        ref: "/private/tmp/scrypath-phase184-10-20261030T072352Z/receipts/core-final.exit"
        status: fail
      - kind: other
        ref: "node scripts/ci_monitor.cjs closeout --push --branch worktree-agent-p184-10-1793344798 --sha <post-summary-commit>"
        status: unknown
    human_judgment: true
    rationale: "A required local core gate fails, and candidate hosted closeout runs only after this Summary commit; exact run status is not available at authoring time."
  - id: D4
    description: Retained-preview source and data preservation limits are recorded without claiming rendered UI review.
    requirement: DEP-04
    verification:
      - kind: other
        ref: "PLAYWRIGHT_BASE_URL=http://127.0.0.1:4002 npm run ui:preflight"
        status: fail
    human_judgment: true
    rationale: "The named UI checkout does not include origin/main, so current rendered screens and keyboard behavior could not be reviewed safely."

duration: 46min
completed: 2026-10-30
status: halted
---

# Phase 184 Plan 10: Final Graph Evidence and Candidate Closeout Summary

**Four graph audits and ten dependency proposal dispositions are source-bound, with residual Ops advisories and candidate closeout limits kept explicit.**

## Performance

- **Duration:** 46 min
- **Started:** 2026-10-30T07:23:52Z
- **Completed:** 2026-10-30T08:10:06Z
- **Tasks:** 2 processed; Task 2's hosted closeout follows this required Summary commit
- **Files modified:** 7

## Accomplishments

- Recorded final root, Phoenix, ecommerce, and ScrypathOps graph identities and raw Hex audit results at code source `6838085626174c8016e9cf57aa9af84dccab20df`; all four lockfiles remained byte-stable.
- Completed source, version, status, evidence, rationale, and revisit records for PR #65 and #68–#76 without modifying the upstream proposals.
- Added negative contract coverage for incomplete graph identities and proposal dispositions, and committed acceptance/validation records that distinguish passing proofs from unresolved gates.

## Verification Results

All local Mix commands used the selected supported Elixir 1.19.5 / OTP 28.5 toolchain through `/private/tmp/scrypath-phase184-10-20261030T072352Z/bin/mix` with independent build/dependency paths.

| Verification | Result |
| --- | --- |
| Focused dependency audit and boundary tests with warnings as errors | PASS — 34 tests, 0 failures |
| `mix verify.repository_contracts` | PASS |
| `mix verify.package` | PASS |
| `mix verify.backend` | PASS; disposable Compose services were removed |
| `mix verify.ops_ui` | PASS with isolated paths |
| `mix verify.ecommerce_mounted` | PASS with isolated Docker/Buildx state; disposable proof services were removed |
| `mix verify.compatibility` local run | PASS on 1.19.5 / OTP 28.5 only |
| `actionlint .github/workflows/ci.yml .github/workflows/workflow-security.yml` | PASS |
| Independent `mix dialyzer` | PASS — zero errors |
| Four-graph aggregate dependency audit | EXIT 1 — three graphs clean; Ops affected by two unaccepted Cloak advisories |
| `mix verify.core --exclude integration --exclude docs_contract` | FAIL — exit 8; Credo reports known `apply/3` finding in `test/mix/tasks/verify_capability_test.exs:140` |
| Named preview `npm run ui:preflight` | REFUSED — checkout does not include `origin/main` |

The core finding exists unchanged at plan base `f1384a7323f1ac69cf813a463e479df68bc6a9bf`; this plan did not modify that test file. The Ops audit findings are EEF-CVE-2026-95105 / CVE-2026-95105 and EEF-CVE-2026-94206 / CVE-2026-94206. No Hex findings were ignored or accepted. The local toolchain does not establish the 1.17/26 floor or the other hosted compatibility tuples. Full local logs and receipts remain outside the checkout at `/private/tmp/scrypath-phase184-10-20261030T072352Z/`.

The required read-only preview preflight was run against the checkout named by `.planning/UI-PREVIEW.json`, branch `ui/next`, URL `http://127.0.0.1:4002`. It refused review because `origin/main` is absent. The checkout's tracked CSS edit and untracked playbooks directory were preserved. No screenshots were collected and no independent UI review is claimed.

## Task Commits

1. **Task 1: Enforce graph and proposal evidence contracts** — `ded20101` (`test(184-10): enforce graph and proposal evidence contracts`)
2. **Task 1: Split graph evidence contract checks** — `6838085` (`refactor(184-10): split graph evidence contract checks`)
3. **Task 1: Bind audit receipts to final source** — `da64e0a7` (`docs(184-10): bind audit receipts to final source`)
4. **Task 2: Record candidate acceptance limits** — `b5cfdfbd` (`docs(184-10): record candidate acceptance limits`)

The Summary metadata commit is this file's commit; its hash is reported in the execution result.

## Files Created/Modified

- `.planning/phases/184-explicit-and-lean-dependency-graphs/184-ACTIONS-DISPOSITIONS.md` — ten proposal dispositions and revisit triggers.
- `.planning/phases/184-explicit-and-lean-dependency-graphs/184-DEPENDENCY-EVIDENCE.md` — exact graph identities and external raw audit/Dialyzer receipts.
- `.planning/phases/184-explicit-and-lean-dependency-graphs/184-ACCEPTANCE.md` — evidence status, residual findings, and delivery limits.
- `.planning/phases/184-explicit-and-lean-dependency-graphs/184-VALIDATION.md` — execution status for Plan 10 tasks; Nyquist remains false.
- `test/mix/tasks/dependency_audit_test.exs` — wrong-source evidence rejection coverage.
- `test/mix/tasks/dependency_boundary_contract_test.exs` — full graph/proposal evidence completeness and negative cases.
- `.planning/phases/184-explicit-and-lean-dependency-graphs/184-10-SUMMARY.md` — this execution record.

## Decisions Made

- The Ops Cloak findings remain visible and unaccepted; no ignore rule or risk policy was introduced.
- Local compatibility evidence is limited to Elixir 1.19.5 / OTP 28.5 until the exact-source hosted matrix is inspected.
- Preview evidence was not collected after the required preflight rejected stale source provenance.

## Deviations from Plan

None - no out-of-scope source changes or risk-acceptance decisions were made. The known verification failures and incomplete evidence are recorded below rather than represented as successful acceptance.

## Issues Encountered

- A direct `asdf exec mix` focused-test invocation did not inherit the private dependency/build paths and stopped before running ExUnit. Re-running through the plan's private Mix wrapper succeeded with 34 tests and 0 failures.
- The core verifier exits 8 on a Credo finding at `test/mix/tasks/verify_capability_test.exs:140`; that file is unchanged from the plan base and remains outside this plan's owned files.
- The final Hex audit exits 1 because the two Ops Cloak advisories remain active and unaccepted.
- The retained UI preflight refuses current review because the named checkout does not include `origin/main`; the preview was left untouched.
- Candidate hosted closeout is intentionally run only after this Summary commit. Its exact source, run identity, job outcomes, and immutable artifact digests will be stored externally. This Summary does not claim that closeout has passed.

## User Setup Required

None.

## Next Phase Readiness

Plan 184-10 is halted pending the post-summary candidate closeout and resolution/ownership of the core gate and stale-preview evidence limits. The orchestrator owns phase integration and must run terminal closeout again against the exact final `planning/v1.45-foundation-ci` HEAD after merge and phase tracking writes. Do not treat this candidate as merged or as phase completion.

---
*Phase: 184-explicit-and-lean-dependency-graphs*
*Completed: 2026-10-30*

## Self-Check: PASSED

- The plan-owned acceptance/evidence/disposition/test/validation files exist.
- Four task commits are reachable on this branch; `gsd_run check evaluation-scope --plan "184-10" --commits-only --raw` resolved all four commits on this branch.
- Focused contract verification passed with 34 tests and 0 failures.
- Known core, Hex audit, preview-preflight, and post-summary-closeout limits are explicitly recorded; this self-check does not claim final plan acceptance.
