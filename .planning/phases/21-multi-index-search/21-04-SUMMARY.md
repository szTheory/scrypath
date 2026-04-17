---
phase: 21-multi-index-search
plan: "04"
subsystem: docs
tags: [guides, integration]
key-files:
  created:
    - guides/multi-index-search.md
    - test/scrypath/search_many_integration_test.exs
  modified:
    - mix.exs
    - README.md
    - test/scrypath/docs_contract_test.exs
---

## Summary

Added the multi-index guide, ExDoc extras + Phoenix group entry, README wayfinding, docs contract assertions, and a gated live integration test comparing singleton `search_many/2` vs `search/3` facet envelopes.

## Self-Check: PASSED

- `mix test test/scrypath/docs_contract_test.exs`
- `mix test test/scrypath/search_many_integration_test.exs --exclude integration`

## Deviations

None.
