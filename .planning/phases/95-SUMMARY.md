---
phase: 95
milestone: v1.26
subsystem: "Scrypath Core & Backend"
tags: ["facet-search", "meilisearch", "api"]
metrics:
  total_tasks: 4
  duration: "30m"
key_files:
  created:
    - lib/scrypath/facet_search_result.ex
  modified:
    - lib/scrypath.ex
    - lib/scrypath/backend.ex
    - lib/scrypath/search.ex
    - lib/scrypath/meilisearch/client.ex
    - lib/scrypath/meilisearch.ex
    - test/support/backend/fake_backend.ex
    - test/support/adapter.ex
---

# Phase 95 Summary: Facet Value Vocabulary Search

## Objective
Introduce and expose the ability to perform high-cardinality facet value searches directly against the backend provider.

## Execution Recap
- **Plan 01 (Backend & Contracts):** Introduced the `Scrypath.FacetSearchResult` struct and `@callback search_facet_values` to the `Scrypath.Backend` behavior. Updated test adapters (`FakeBackend`, `Adapter`) to satisfy the new callback. Implemented the actual `facet_search/5` execution within `Scrypath.Meilisearch.Client` and `Scrypath.Meilisearch`.
- **Plan 02 (Facade & Routing):** Implemented core routing in `Scrypath.Search.search_facet_values/4` (and bang variant) with option validations. Wrapped the core logic in `Scrypath.search_facet_values/4` and `Scrypath.search_facet_values!/4` facade functions, heavily documented with `@spec` and usage examples.

## Key Decisions
- Created a distinct `Scrypath.FacetSearchResult` struct (returning `facet_hits`, `facet_query`, and `processing_time_ms`) to clearly separate vocabulary search results from standard `Scrypath.SearchResult` document hits.
- The interface acts dynamically on `facet_query` parameters and routes through the existing Scrypath option validation pipeline to ensure safe and predictable access against Meilisearch.

## Deviations / Auto-fixed Issues
- None. Executed as planned.

## Self-Check: PASSED
- `lib/scrypath/facet_search_result.ex` created.
- Integration tests and unit tests passing.
