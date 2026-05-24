---
phase: 85-real-app-proof-and-drift-gates
plan: 02
subsystem: verification
tags: [mix, exunit, docs, contracts, verification]
requires: []
provides:
  - focused phase85 verify task
  - bounded docs-contract coverage for canonical guide authority and non-goals
  - preferred env wiring for the new verification lane
affects: [phase-85, verification, docs]
tech-stack:
  added: []
  patterns: [focused phase verify task, structural docs contracts]
key-files:
  created: [lib/mix/tasks/verify.phase85.ex]
  modified: [test/scrypath/docs_contract_test.exs, mix.exs]
key-decisions:
  - "Kept verify.phase85 phase-local: minimal runtime seams, docs contracts, and docs build only."
  - "Extended docs contracts with structural authority and non-goal checks rather than snapshotting guide prose."
patterns-established:
  - "Every public story slice gets an explicit verify task wired through mix preferred_envs."
requirements-completed: [VRFY-01, DOC-01, DOC-02]
duration: 1 session
completed: 2026-05-23
---

# Phase 85 Plan 02: Real-App Proof And Drift Gates Summary

**Phase 85 now has a focused maintainer gate for public-story drift**

## Accomplishments

- Added `mix verify.phase85` to run `composition`, `metadata`, `composition_many`, and docs-contract tests plus the docs build.
- Extended `Scrypath.DocsContractTest` to pin canonical-guide discoverability, guide ordering, proof-guide role boundaries, and Phase 85 non-goals.
- Registered `verify.phase85` in `mix.exs` preferred envs so maintainers can run the gate directly.

## Files Created/Modified

- `lib/mix/tasks/verify.phase85.ex` - Focused Phase 85 verification task.
- `test/scrypath/docs_contract_test.exs` - Canonical-guide and non-goal drift assertions.
- `mix.exs` - `verify.phase85` preferred env wiring.

## Verification

- `mix test test/scrypath/docs_contract_test.exs`
- `mix help verify.phase85`

## Task Commits

No commits were created during this execution run.

## Issues Encountered

- `mix help verify.phase85` did not see the new task before the project recompiled. After recompilation, the task resolved normally and the full phase gate ran green.

## Next Phase Readiness

The phase now has a focused proof lane, so the final docs alignment can close against one concrete maintainer command.

---
*Phase: 85-real-app-proof-and-drift-gates*
*Completed: 2026-05-23*
