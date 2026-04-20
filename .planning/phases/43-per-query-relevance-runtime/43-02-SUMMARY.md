---
phase: 43-per-query-relevance-runtime
plan: 02
subsystem: search
tags: [search_many, per_query, merge]

requires: []
provides:
  - D-11 per_query inner Map.merge in MultiSearch.Entries.normalize_one/2
  - Sequential-path regression tests for shared-only, entry-only, and combined merge

key-files:
  created: []
  modified:
    - lib/scrypath/multi_search/entries.ex
    - test/scrypath/search_many_test.exs

key-decisions:
  - "Keyword.keyword?/1 checked in function body (not guard) for per_query list normalization"

requirements-completed:
  - TUNE-PQ-01
  - TUNE-PQ-02

duration: 12min
completed: 2026-04-20
---

# Phase 43 Plan 02 Summary

**Implemented `:per_query` shallow inner merge for `search_many/2` normalization** so shared and per-entry Plane B maps compose with entry bias on overlapping keys, and **locked the behavior** with sequential-backend query capture tests.

## Task Commits

1. **Task 1 (43-02-01): Inner Map.merge for :per_query in Entries.normalize** — `cf0bf48` (feat)
2. **Task 2 (43-02-02): search_many tests for :per_query merge matrix** — `313cb9e` (test)

## Self-Check: PASSED

- `mix test test/scrypath/search_many_test.exs` exits 0.
