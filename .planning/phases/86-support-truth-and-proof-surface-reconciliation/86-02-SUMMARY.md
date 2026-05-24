---
phase: 86-support-truth-and-proof-surface-reconciliation
plan: 02
subsystem: maintainer-proof
tags: [mix-task, tests, docs, readiness]
requires: [TRUTH-01]
provides:
  - truthful verify.adopter fast path backed by real tests
  - task-help assertions for fast/live contract drift
  - aligned maintainer and example-runbook wording for the live proof path
affects: [phase-86, mix-task, docs, tests]
tech-stack:
  added: []
  patterns: [narrow fast contract, orchestration-only live mode, bounded task-help assertions]
key-files:
  created: [test/scrypath/readiness_contract_test.exs]
  modified: [test/mix/tasks/verify_adopter_test.exs, CONTRIBUTING.md, examples/phoenix_meilisearch/README.md]
key-decisions:
  - "Kept `mix verify.adopter` as the existing seam and repaired it with a dedicated narrow readiness-contract test instead of widening the fast path into the broader docs-contract suite."
  - "Locked the task help text into tests so the advertised fast/live contract cannot silently drift away from the actual file targets and live prerequisites."
patterns-established:
  - "Fast maintainer proof runs a real support/readiness seam plus task-level regression coverage, while live proof stays explicit and service-backed."
requirements-completed: [TRUTH-02]
duration: 1 session
completed: 2026-05-24
---

# Phase 86 Plan 02: Support Truth And Proof Surface Reconciliation Summary

**`mix verify.adopter` now proves a real fast contract instead of passing by accident**

## Accomplishments

- Added `test/scrypath/readiness_contract_test.exs` to assert the support guide exists, short docs point to it, `mix help verify.adopter` matches the actual fast/live contract, and maintainer docs stay aligned with the example runbook.
- Extended `test/mix/tasks/verify_adopter_test.exs` so task-level regressions fail if the fast target list or help text drifts away from the real contract.
- Tightened CONTRIBUTING and the Phoenix example README around the canonical `mix verify.adopter` / `mix verify.adopter --live` command family and the `phoenix-example-integration` CI path.

## Files Created/Modified

- `test/scrypath/readiness_contract_test.exs` - New narrow support/readiness proof seam.
- `test/mix/tasks/verify_adopter_test.exs` - Added fast-target and help-text drift assertions.
- `CONTRIBUTING.md` - Explicit maintainer proof-command family and CI-path wording.
- `examples/phoenix_meilisearch/README.md` - Root-task live-proof handoff aligned to CI sequence.

## Verification

- `mix test test/scrypath/readiness_contract_test.exs`
- `mix test test/mix/tasks/verify_adopter_test.exs`
- `mix verify.adopter`

## Task Commits

No commits were created during this execution run.

## Issues Encountered

- The first readiness-test run failed because CONTRIBUTING described the live path without the literal `mix verify.adopter --live` string. The wording was tightened and the suite then passed.

## Next Phase Readiness

The maintainer proof contract is now branch-tip true and ready for broader docs/planning drift guards.

---
*Phase: 86-support-truth-and-proof-surface-reconciliation*
*Completed: 2026-05-24*
