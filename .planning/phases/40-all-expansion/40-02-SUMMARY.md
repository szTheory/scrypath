---
phase: 40-all-expansion
plan: 02
subsystem: testing
tags: [search_many, ExUnit, FED-02]

requires:
  - phase: 40-01
    provides: AllExpansion and search_many wiring
provides:
  - Unit tests for AllExpansion.expand/2
  - search_many integration tests for :all happy path and max_schemas rail
affects: [41]

tech-stack:
  added: []
  patterns:
    - "Prefer global_schemas in shared_opts over Application.put_env in tests"

key-files:
  created:
    - test/scrypath/multi_search/all_expansion_test.exs
  modified:
    - test/scrypath/search_many_test.exs

key-decisions:
  - "Doc anchors global_schemas: and scrypath_global_search_schemas live in search_many/2 moduledoc for future contract tests."

patterns-established: []

requirements-completed: [FED-02]

duration: 15min
completed: 2026-04-20
---

# Phase 40: `:all` expansion — Plan 02 Summary

**ExUnit locks FED-02: AllExpansion edge cases in isolation and search_many end-to-end with FakeBackend, including post-expansion `max_schemas` cardinality.**

## Task Commits

1. **Task 1–3: unit + integration + doc anchors** — `d66edb8` (feat)

## Verification

- `mix test test/scrypath/multi_search/all_expansion_test.exs test/scrypath/search_many_test.exs` — PASS
- Full `mix test` — PASS

## Self-Check: PASSED
