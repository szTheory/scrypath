---
phase: 21-multi-index-search
plan: "02"
subsystem: meilisearch
tags: [multi-search, backend]
key-files:
  created:
    - lib/scrypath/meilisearch/federated_decode.ex
    - test/scrypath/meilisearch/client_multi_search_test.exs
  modified:
    - lib/scrypath/backend.ex
    - lib/scrypath/meilisearch/client.ex
    - lib/scrypath/meilisearch.ex
    - test/support/fake_backend.ex
---

## Summary

Added optional `Backend.search_many/2`, `Client.multi_search/2`, `Meilisearch.search_many/2` posting `/multi-search` with a federation object (no `mergeFacets`), `FederatedDecode.per_schema_maps/2`, and `FakeBackend.search_many/2` for federated-shaped stubs.

## Self-Check: PASSED

- `mix test test/scrypath/meilisearch/client_multi_search_test.exs`
- `mix compile --warnings-as-errors`
- `grep -r mergeFacets lib/scrypath/meilisearch` → no matches

## Deviations

- Optional callback arity is **2** (`paired_queries, config`) to match Elixir behaviour conventions (plan text said `/3` in places).
