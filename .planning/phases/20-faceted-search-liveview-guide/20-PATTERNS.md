# Phase 20 — Pattern Map

Analogs in-repo for files Phase 20 will create or extend.

## 1. `lib/scrypath/options.ex`

**Role:** NimbleOptions for schema and search; single place for new `:faceting` schema key and `:facets` / `:facet_filter` search keys.

**Analog:** Phase 19 added `settings_merge`, nested `validate_settings/1` — extend `@schema_options` and `@search_options` the same way.

**Excerpt:** `@schema_options` begins ~L4; `validate_schema_options!/1` escapes config for `Scrypath.Schema`.

## 2. `lib/scrypath/schema.ex`

**Role:** `__scrypath__/1` dispatch; add `:faceting` clause alongside `:filterable`.

**Analog:** Existing `def __scrypath__(:filterable)` — mirror for `:faceting` with same `raise` pattern for unknown keys.

## 3. `lib/scrypath/query.ex` + `lib/scrypath/meilisearch/query.ex`

**Role:** Normalize search intent → Meilisearch JSON.

**Analog:** `Query.new/2` + `Meilisearch.Query.to_payload/1` for `filter` / `sort` / `page` — add `facets` and `facetFilters` with same `maybe_put/3` style.

## 4. `lib/scrypath/search.ex` + `lib/scrypath/search_result.ex`

**Role:** `SearchResult.new/4` builds public result from raw backend map.

**Analog:** `page/1` private in `SearchResult` — add `facets_from_raw/1` → `%Scrypath.SearchResult.Facets{}`.

## 5. `lib/scrypath/meilisearch/settings.ex`

**Role:** `translate_settings/1` maps canonical atoms to Meilisearch wire.

**Analog:** Phase 19 `filterable_attributes` translation — extend to inject object-form entries + `features: ["facetSearch"]` for facet-declared attributes.

## 6. `test/support/searchable_post.ex` + `test/scrypath/search_test.exs`

**Role:** Fixture schema and fake-backend assertions.

**Analog:** `SearchablePost` uses `use Scrypath` — add `faceting:` to a dedicated test module (e.g. `FacetableMovie`) to avoid breaking all existing `SearchablePost` tests until facets are optional.

## 7. `test/scrypath/docs_contract_test.exs`

**Role:** `@guide_paths` list + `assert_contains_all`.

**Analog:** `guides/relevance-tuning.md` entries from Phase 19 — add new guide path and required substrings.

## 8. `test/support/docs/phoenix_examples_test.exs`

**Role:** Compile-check HEEx from guides.

**Analog:** Existing `guides/phoenix-liveview.md` fixture pattern — add faceted guide snippets.

## 9. `guides/phoenix-liveview.md`

**Tone analog:** Context vs LiveView boundary, `handle_params` — faceted guide should cross-link and match voice.

## 10. `.planning/phases/20-faceted-search-liveview-guide/20-UI-SPEC.md`

**Role:** Locked copy, layout, four patterns — guide must satisfy verbatim where specified.
