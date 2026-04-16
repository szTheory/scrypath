---
phase: 03-search-query-api-and-hydration
plan: 03-01
subsystem: api
tags: [elixir, ecto, search, validation, query]
provides:
  - common Scrypath.search/3 and search!/3 entrypoints
  - normalized Scrypath.Query contract
  - schema-driven validation for filter, sort, and page inputs
key-files:
  created:
    - lib/scrypath/query.ex
  modified:
    - lib/scrypath.ex
    - lib/scrypath/search.ex
    - lib/scrypath/options.ex
    - test/scrypath/search_test.exs
    - test/support/fake_backend.ex
requirements-completed: [SRCH-01, SRCH-02, SRCH-03, SRCH-04]
completed: 2026-04-15
---

# Phase 3 Plan 03-01: Query Contract Summary

**Added the common search facade, normalized query struct, and schema-backed option validation**

## Accomplishments

- Added `Scrypath.search/3` and `Scrypath.search!/3` as the public Phase 3 entrypoints.
- Normalized common-path search input into `%Scrypath.Query{}` before backend dispatch.
- Validated `filter:`, `sort:`, and `page:` against declared schema metadata and rejected unsupported boolean composition.

## Task Commits

1. `092a3be` - failing facade contract tests
2. `89cf8a4` - common search facade and initial query contract
3. `3dca05e` - failing search option validation tests
4. `f9ee492` - validated common search options against schema metadata

## Notes

- The public query DSL stays small and Elixir-shaped: text plus structured `filter:`, `sort:`, and `page:`.
- Backend-native filter strings remain out of bounds for the common API.

## Self-Check: PASSED

- Verified summary target file exists: `.planning/phases/03-search-query-api-and-hydration/03-01-SUMMARY.md`
- Verified task commits exist: `092a3be`, `89cf8a4`, `3dca05e`, `f9ee492`
