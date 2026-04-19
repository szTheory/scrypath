---
phase: 035-sync-guide-lifecycle-parity
plan: 01
subsystem: docs
tags: [sync-modes, readme, contract-test, adoption]

requires: []
provides:
  - Canonical Operator lifecycle subsection in sync modes guide
  - README authority precision (guide wins; lifecycle ties to guide)
  - Docs contract locks for shared lifecycle string
affects: []

tech-stack:
  added: []
  patterns:
    - "Operator lifecycle chain documented once in guide; README references it"

key-files:
  created: []
  modified:
    - guides/sync-modes-and-visibility.md
    - README.md
    - test/scrypath/docs_contract_test.exs

key-decisions:
  - "Inserted ## Operator lifecycle between The Contract and per-mode sections (insert-only, no table rewrites)"
  - "Used literal String.contains? / assert_contains_all substrings for lifecycle string (no regex over |)"

patterns-established:
  - "README defers semantics to sync guide on disagreement; lifecycle monospace line aligned to guide heading"

requirements-completed: [ADPT-02, ADPT-03]

duration: 30min
completed: 2026-04-19
---

# Phase 35 plan 01 — Sync guide lifecycle parity

**README and the sync modes guide now share one documented operator lifecycle chain, with the guide as semantic authority.**

## Performance

- **Tasks:** 3
- **Files modified:** 3

## Task Commits

1. **Task 1: sync guide — Operator lifecycle subsection** — `60caa78` (docs)
2. **Task 2: README — precision lines** — `13b1652` (docs)
3. **Task 3: docs_contract_test — lifecycle parity locks** — `a1706b8` (test)

## Self-Check: PASSED

- `mix test test/scrypath/docs_contract_test.exs` — 32 tests, 0 failures
