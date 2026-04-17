---
phase: 20-faceted-search-liveview-guide
plan: "01"
---

## Outcome

Implemented `faceting:` on `use Scrypath` (NimbleOptions + post-validation), `__scrypath__(:faceting)`, `Scrypath.schema_faceting/1`, FACET-02 subset and FACET-10 wildcard/hierarchical rejection, and `test/support/facetable_movie.ex` with `test/scrypath/options_test.exs` coverage.

## Self-Check: PASSED

- `mix compile --warnings-as-errors`
- `mix test test/scrypath/options_test.exs test/scrypath/schema_test.exs`

## Key files

- `lib/scrypath/options.ex`
- `lib/scrypath/schema.ex`
- `lib/scrypath.ex`
- `test/support/facetable_movie.ex`
- `test/scrypath/options_test.exs`
- `test/scrypath/schema_test.exs`
