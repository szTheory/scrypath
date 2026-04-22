---
phase: 53-contributor-opsui-verify-spine
plan: "03"
subsystem: testing
tags: [exunit, docs-contract, ci, opsui]

requires:
  - plan: "01"
    provides: Stable strings in verify.opsui module source
  - plan: "02"
    provides: README mentions mix verify.opsui
provides:
  - Docs-contract coverage for README, CONTRIBUTING scrypath-ops row vs ci.yml, and verify.opsui orchestration markers
affects: []

tech-stack:
  added: []
  patterns:
    - "Phase 51-style ordered? checks on CONTRIBUTING tail and CI job window"

key-files:
  created: []
  modified:
    - test/scrypath/docs_contract_test.exs

key-decisions:
  - "Split CONTRIBUTING on the table spine `` `scrypath-ops-path-check` / `scrypath-ops` `` for a stable row tail"

patterns-established: []

requirements-completed:
  - VRFY-03
  - VRFY-04

duration: 20min
completed: 2026-04-22
---

# Phase 53 — Plan 03

**Doc-contract tests now lock README + CONTRIBUTING + ci.yml ordering for the scrypath-ops path and grep key orchestration markers in verify.opsui.**

## Performance

- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Added `@verify_opsui` module attribute and three Phase 53 tests mirroring the phoenix-example-integration pattern.

## Task Commits

1. **docs_contract_test — OPSUI verify spine contracts** — (see git log)

## Files Created/Modified

- `test/scrypath/docs_contract_test.exs`

## Decisions Made

- Used `"\n  scrypath-ops:\n"` as the CI split anchor to scope assertions to the `scrypath-ops` job block.

## Deviations from Plan

None.

## Issues Encountered

None.

## Self-Check: PASSED

- `mix test test/scrypath/docs_contract_test.exs` and `mix format --check-formatted` pass.

---
*Phase: 53-contributor-opsui-verify-spine*
