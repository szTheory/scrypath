---
phase: 21-multi-index-search
plan: "01"
subsystem: multi-search
tags: [multi-search, structs]
key-files:
  created:
    - lib/scrypath/multi_search_result.ex
    - lib/scrypath/multi_search_result/federation.ex
    - lib/scrypath/multi_search/entries.ex
    - test/scrypath/multi_search/entries_test.exs
  modified:
    - lib/scrypath/options.ex
---

## Summary

Implemented `%Scrypath.MultiSearchResult{}`, `%Federation{}`, and `MultiSearch.Entries.normalize/2` with cardinality rails, per-key merge semantics, and shared-only federation key rejection. Extended `@runtime_options` with federation and multi-search limits so merged opts validate through `Config.resolve!/1`.

## Self-Check: PASSED

- `mix test test/scrypath/multi_search/entries_test.exs`
- `mix compile --warnings-as-errors`

## Deviations

None.
