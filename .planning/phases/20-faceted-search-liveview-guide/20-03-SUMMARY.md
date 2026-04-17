---
phase: 20-faceted-search-liveview-guide
plan: "03"
---

## Outcome

Extended `Scrypath.Meilisearch.Settings.resolve/2` to merge facet-derived `filterableAttributes` entries (`features: ["facetSearch"]`) with explicit-schema precedence; added FACET settings + `verify_applied/3` tests.

## Self-Check: PASSED

- `mix test test/scrypath/meilisearch/settings_test.exs`

## Key files

- `lib/scrypath/meilisearch/settings.ex`
- `test/scrypath/meilisearch/settings_test.exs`
