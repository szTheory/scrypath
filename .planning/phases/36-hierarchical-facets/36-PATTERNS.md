# Phase 36 — Pattern map (analog code)

## Canonical PLAN / task shape

| Analog | Use for |
|--------|---------|
| `.planning/phases/20-faceted-search-liveview-guide/20-01-PLAN.md` | `faceting:` NimbleOptions, `validate_faceting_rules!/1`, compile tests via `Code.compile_string/1`, `test/support/facetable_movie.ex` |
| `.planning/phases/20-faceted-search-liveview-guide/20-02-PLAN.md` through `20-04` | Settings merge, search/HTTP, guide + contract tests |

## Implementation anchors

| Role | File | Pattern |
|------|------|---------|
| Schema option validation | `lib/scrypath/options.ex` | `validate_schema_faceting/1`, `validate_faceting_rules!/1`, post-NimbleOptions hooks |
| Settings projection | `lib/scrypath/meilisearch/settings.ex` | `merge_faceting_filterable_attributes/2`, `facet_filterable_object/1` |
| Drift | `lib/scrypath/operator/index_contract_drift.ex` | `compare_faceting/2`, `faceting_declared_wire/1`, `faceting_applied_wire/1` |
| Result decode | `lib/scrypath/search_result.ex` | `decode_facets/2` — order from `query.facets`, string keys from atoms |
| Facet struct | `lib/scrypath/search_result/facets.ex` | `%Facets{}` fields unchanged |
| Doc contracts | `test/scrypath/docs_contract_test.exs` | `@guide_paths`, `assert_contains_all/2`, hygiene regex tests |

## Data flow

`use Scrypath` **faceting** keyword → persisted on schema → `Scrypath.schema_faceting/1` → settings merge projects filterable facet objects → search request includes `facets` list as strings → response `facetDistribution` → `SearchResult.decode_facets/2` → `%Facets{}.distribution` keyed by **same atoms** as declared/requested.
