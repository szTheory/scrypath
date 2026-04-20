---
phase: 41-federation-docs-contracts
plan: 01
subsystem: testing
tags: [mix, verify, docs_contract, ci]

requires: []
provides:
  - mix verify.phase41 thin verify task targeting docs_contract_test.exs
  - quality CI step for federation doc regressions
affects: [federation-docs, FED-03]

tech-stack:
  added: []
  patterns: [Mix.Tasks.Verify.Phase* thin composer]

key-files:
  created:
    - lib/mix/tasks/verify.phase41.ex
  modified:
    - mix.exs
    - test/scrypath/docs_contract_test.exs
    - .github/workflows/ci.yml
    - CONTRIBUTING.md

key-decisions:
  - "Preferred env registration uses Mix.Project cli/0 (preferred_envs), matching existing verify.phase* tasks."

patterns-established:
  - "Phase 41 doc slice: app.start, no args, focused docs_contract_test.exs only."

requirements-completed: [FED-03]

duration: 15min
completed: 2026-04-20
---

# Phase 41 Plan 01 Summary

**Shipped `mix verify.phase41` as the fast PR gate for federation-facing docs and doc contracts, wired through CI and CONTRIBUTING.**

## Performance

- **Tasks:** 5
- **Files modified:** 5 paths

## Task Commits

1. **Task 1: Mix.Tasks.Verify.Phase41** — `881c536`
2. **Task 2: Register verify.phase41** — `328b827`
3. **Task 3: Doc contract reads verify.phase41** — `977a24b`
4. **Task 4: CI quality step** — `1f48e81`
5. **Task 5: CONTRIBUTING** — `f62db20`

## Verification

- `mix compile --warnings-as-errors` — PASS
- `mix verify.phase41` — PASS
- `grep -RIn 'verify.phase41' mix.exs lib/mix/tasks/verify.phase41.ex test/scrypath/docs_contract_test.exs .github/workflows/ci.yml CONTRIBUTING.md` — lists expected locations

## Self-Check: PASSED
