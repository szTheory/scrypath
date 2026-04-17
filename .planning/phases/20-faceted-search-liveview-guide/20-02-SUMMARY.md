---
phase: 20-faceted-search-liveview-guide
plan: "02"
---

## Outcome

Added `:facets` / `:facet_filter` search options, non-raising `Options.validate_search_options/2`, `Query` + `Meilisearch.Query` payload support (`facets`, `facetFilters`), `%SearchResult.Facets{}` decoding, `FakeBackend` facet wire stubs, and `test/scrypath/meilisearch/query_test.exs` for FACET-09 matrix.

## Self-Check: PASSED

- `mix test test/scrypath/search_test.exs test/scrypath/meilisearch/query_test.exs`

## Key files

- `lib/scrypath/options.ex`
- `lib/scrypath/search.ex`
- `lib/scrypath/query.ex`
- `lib/scrypath/meilisearch/query.ex`
- `lib/scrypath/search_result.ex`
- `lib/scrypath/search_result/facets.ex`
- `test/support/fake_backend.ex`
- `test/scrypath/meilisearch/query_test.exs`
- `test/scrypath/search_test.exs`
- `test/scrypath/backend_test.exs`
