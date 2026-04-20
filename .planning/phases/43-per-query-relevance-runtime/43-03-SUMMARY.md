---
phase: 43-per-query-relevance-runtime
plan: 03
subsystem: infra
tags: [verify, ci, exdoc, docs_contract]

requires: []
provides:
  - mix verify.phase43 thin composer registered in mix.exs preferred_envs
  - docs_contract_test @verify_phase43 pin + CI quality step + CONTRIBUTING guidance
  - Public @doc for :per_query on Scrypath.search/3 and search_many/2

key-files:
  created:
    - lib/mix/tasks/verify.phase43.ex
  modified:
    - mix.exs
    - test/scrypath/docs_contract_test.exs
    - .github/workflows/ci.yml
    - CONTRIBUTING.md
    - lib/scrypath.ex

key-decisions:
  - "Reuse phase 41 Mix.Task pattern; @shortdoc includes literal Per-query for grep hygiene"

requirements-completed:
  - TUNE-PQ-02
  - TUNE-PQ-03

duration: 15min
completed: 2026-04-20
---

# Phase 43 Plan 03 Summary

**Added `mix verify.phase43` as the focused PR gate for per-query runtime + doc contracts**, wired it into **CI** and **CONTRIBUTING**, and **documented `:per_query`** on the public `Scrypath.search/3` and `Scrypath.search_many/2` entry points.

## Task Commits

1. **Task 1 (43-03-01): Mix.Tasks.Verify.Phase43 thin composer** — `4467849` (feat)
2. **Task 2 (43-03-02): docs_contract pins + CI + CONTRIBUTING** — `5fbcbc3` (chore)
3. **Task 3 (43-03-03): Public @doc for :per_query** — `b574b2c` (docs)

## Self-Check: PASSED

- `mix verify.phase43` exits 0.
- `! grep -q HEX_API_KEY lib/mix/tasks/verify.phase43.ex` exits true (no secret literals).
