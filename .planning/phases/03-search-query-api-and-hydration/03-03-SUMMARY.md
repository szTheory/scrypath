---
phase: 03-search-query-api-and-hydration
plan: 03-03
subsystem: api
tags: [elixir, ecto, search, hydration]
provides:
  - stable Scrypath.SearchResult envelope
  - explicit repo-backed batch hydration
  - hit-order restoration and missing-id visibility
key-files:
  created:
    - lib/scrypath/search_result.ex
    - lib/scrypath/hydration.ex
    - test/support/queryable_post.ex
    - test/support/fake_repo.ex
    - test/scrypath/hydration_test.exs
  modified:
    - lib/scrypath/search.ex
    - test/scrypath/search_test.exs
requirements-completed: [SRCH-05, SRCH-06]
completed: 2026-04-15
---

# Phase 3 Plan 03-03: Result Envelope and Hydration Summary

**Added the stable search result contract and explicit batch hydration layer**

## Accomplishments

- Introduced `%Scrypath.SearchResult{}` so common-path searches return one stable envelope containing raw hits, hydrated records, pagination metadata, and `missing_ids`.
- Added `Scrypath.Hydration` to batch-load source rows through an explicit `repo:`, restore hit order in Elixir, and surface stale rows instead of hiding them.
- Added queryable repo fixtures and hydration tests that prove one batch query, explicit preload handling, and hit-order preservation independent of DB return order.

## Task Commits

1. `1554d93` - integrated result envelope, hydration layer, and focused hydration coverage

## Self-Check: PASSED

- Verified summary target file exists: `.planning/phases/03-search-query-api-and-hydration/03-03-SUMMARY.md`
- Verified implementation commit exists: `1554d93`
