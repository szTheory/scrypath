# Phase 20 — Technical Research

**Phase:** 20 — Faceted Search + LiveView Guide  
**Question:** What do we need to know to PLAN this phase well?

## Meilisearch wire contract (search)

- Search POST body supports `facets` (array of attribute names), `facetFilters` (array of filter expressions for facet refinement), alongside existing `filter`, `q`, `sort`, pagination keys.
- Response includes `facetDistribution` (map of attribute → value → count) and `facetStats` (numeric attributes → `{min, max}` style aggregates). Field names are camelCase on the wire.
- Meilisearch combines restrictive `filter` with `facetFilters` conjunctively for hit selection; within a single facet field, multiple values are typically OR unless expressed otherwise — align implementation with official facet filter grammar Scrypath already uses for `filter:` (do not invent a second DSL in `facet_filter:`).

## Integration points in this repo

| Area | File / module | Extension |
|------|----------------|-----------|
| Schema metadata | `lib/scrypath/options.ex` `@schema_options`, `validate_schema_options!/1` | Add `faceting:` NimbleOptions shape; validate `attributes` list, `max_values_per_facet`, `sort_facet_values_by`. |
| Compile-time surface | `lib/scrypath/schema.ex` `__using__` | Persist normalized faceting on `@scrypath_config`; add `__scrypath__(:faceting)`; add public `Scrypath.schema_faceting/1` mirroring `schema_settings/1` pattern. |
| Cross-field rule FACET-02 | Same compile quote or `Options.validate_schema_options!` | After options validation, assert `MapSet.subset?(faceting_attrs, filterable_set)`; raise `ArgumentError` with offending attribute name. |
| FACET-10 non-goals | Compiler or runtime validator | Reject `faceting.attributes` containing `:*` or string wildcards; reject hierarchical dotted atoms in attributes list; reject raw string facet filter DSL in `facet_filter:` (only keyword form). |
| Search options | `lib/scrypath/options.ex` `@search_options` | `:facets` (list of atoms), `:facet_filter` (keyword, same field naming as `filter:`). Unknown facet → return `{:error, {:unknown_facet, attr}}` from `search/3` path (not `raise`) per FACET-03. |
| Query struct | `lib/scrypath/query.ex` | Add `facets` and `facet_filter` fields defaulted empty; `Query.new/2` reads opts. |
| Meilisearch payload | `lib/scrypath/meilisearch/query.ex` | Map `facets` → `"facets"`, translate `facet_filter` to `facetFilters` wire form; AND-combine semantics with existing `filter` translation (FACET-09). |
| Result shaping | `lib/scrypath/search.ex`, `lib/scrypath/search_result.ex` | New `Scrypath.SearchResult.Facets` struct; `SearchResult.new/4` attaches decoded `distribution`, `stats`, `declared_order` from raw JSON; keep additive (no new `@enforce_keys` on `%SearchResult{}`). |
| Settings / reindex | `lib/scrypath/meilisearch/settings.ex` | When schema declares `faceting.attributes`, derive `filterableAttributes` entries in object form with `features: ["facetSearch"]` for those attributes (FACET-07); reuse `translate_settings/1` pipeline from Phase 19 — no parallel translator. |
| Tests | `test/scrypath/search_test.exs`, `Req.Test` meilisearch tests | Fake backend asserts `Query` carries facet opts; JSON fixtures for `facetDistribution` / `facetStats` decoding; five composition tests FACET-09. |
| Guide | `guides/faceted-search-with-phoenix-liveview.md` (new) | Movies example: genre, year, rating, director; URL `handle_params`; four UI patterns per `20-UI-SPEC.md`; anti-pattern appendix 7+ entries in API | Meilisearch | UI bands. |

## Phase 19 handoff

- `Scrypath.Meilisearch.Settings.translate_settings/1` and `resolve/2` already normalize and strip meta keys — extend with facet-driven `filterableAttributes` augmentation rather than a new module (`20-CONTEXT.md` D-06).

## Documentation enforcement

- Extend `@guide_paths` in `test/scrypath/docs_contract_test.exs` with the new guide path and stable section anchors (FACET-08).
- Extend `test/support/docs/phoenix_examples_test.exs` (or equivalent) for critical HEEx + module snippets from the guide so they compile.

## Open choices (Claude's discretion per CONTEXT)

- Submodule layout for `SearchResult.Facets` vs inline in `search_result.ex`.
- Exact repeated-key vs delimiter encoding for URL params in the guide only.

## Validation Architecture

**Nyquist Dimension 8 (sampling):** Every implementation wave must leave at least one automated test that exercises the new surface (unit or `Req.Test`), not guide-only prose.

| Dimension | Strategy |
|-----------|----------|
| D1–D7 | Standard ExUnit + `mix test --exclude external_meilisearch` after each plan wave. |
| D8 | After each plan: run the plan's `<automated>` verify command; `20-VALIDATION.md` maps tasks to commands and REQ IDs. |
| Manual | ExDoc readability for the new guide — spot-check during `/gsd-verify-work`, not CI-gated. |

**Quick feedback command:** `mix test test/scrypath/search_test.exs test/scrypath/options_test.exs lib/scrypath/meilisearch/query.ex` (adjust paths as files land).  
**Full gate:** `mix test --exclude external_meilisearch` + `mix compile --warnings-as-errors`.

---

## RESEARCH COMPLETE
