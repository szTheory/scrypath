# Phase 37 — Pattern map

Analogs in-repo for new work (file → role → pattern source).

| Planned / touched file | Role | Closest analog |
|------------------------|------|----------------|
| `lib/scrypath/facets/disjunctive.ex` (new) | Pure merge + `@moduledoc` honesty | `lib/scrypath/search_result/facets.ex` — wire-to-struct docs; `lib/scrypath/meilisearch/federated_decode.ex` — merging facet maps from multi-response |
| `test/scrypath/facets/disjunctive_test.exs` (new) | Unit tests for merge | `test/scrypath/meilisearch/query_test.exs` — table-driven payload assertions |
| `lib/scrypath.ex` | Optional thin `defdelegate` / public wrapper | `lib/scrypath.ex` — existing `search_many/2` delegations |
| `guides/faceted-search-with-phoenix-liveview.md` | Narrative + `##` section | Same file — `## Hierarchical facets` block (Phase 36) for heading + appendix discipline |
| `test/scrypath/docs_contract_test.exs` | Stable substrings | Phase 36 tests: `faceted LiveView guide documents hierarchical facets` |
| `lib/mix/tasks/verify.phase37.ex` (new) | Focused verify | `lib/mix/tasks/verify.phase36.ex` — `@focused_tests` list + `run_test!/2` |

**Excerpt — federated facet map read** (`lib/scrypath/meilisearch/federated_decode.ex`):

- Reads `"facetDistribution"` per sub-response when assembling multi-index results — **pattern**: defensive `Map.get/2` on string vs atom keys; Phase 37 merge helper should accept the same key shapes as Meilisearch JSON (string keys in distribution maps).

**Excerpt — OR-within-field encoding** (`lib/scrypath/meilisearch/query.ex` L30–53):

- List of values under one `facet_filter` key → nested list in `facetFilters` → OR within field; multiple keys → AND across fields.

---

## PATTERN MAPPING COMPLETE
