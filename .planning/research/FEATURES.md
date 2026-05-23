# Feature Landscape

**Domain:** Reusable composition, presets, scopes, and UI metadata for an Ecto-native search library
**Researched:** 2026-05-23
**Overall confidence:** HIGH for boundary and composition shape; MEDIUM for exact DX niceties because those are ecosystem-synthesized rather than standardized.

## Feature goal

`v1.22` should help real Phoenix and Ecto apps share repeated search flows without inventing a second runtime above `Scrypath.search/3`.

The composition layer should behave like this:

- normalize browser-shaped input once, then compose plain search args explicitly
- let apps freeze repeated defaults and allowed variants as reusable presets/scopes
- expose enough declared metadata for controllers and LiveViews to build honest UIs
- preserve context ownership, per-app tenant policy, related-data fan-out ownership, and recovery honesty

This matches the repo boundary and current ecosystem patterns:

- Ecto queries are intentionally composable data, not hidden runtime magic ([Ecto dynamic queries](https://hexdocs.pm/ecto/dynamic-queries.html))
- LiveView treats `handle_params/3` as the URL-state boundary, not a replacement for context orchestration ([Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html))
- Scout and Searchkick both succeed by making repeated search flows reusable, but they also show where over-magic becomes misleading, especially for async visibility and association updates ([Laravel Scout](https://laravel.com/docs/12.x/scout), [Searchkick](https://github.com/ankane/searchkick))

## Adopter jobs

Use these tags in notes:

- `JOB-1` First searchable schema
- `JOB-2` Request-edge Phoenix flow
- `JOB-3` Related-data propagation
- `JOB-4` Tenant-safe access
- `JOB-5` Recovery and rebuild honesty

## Table stakes

Features real apps will expect once the request-edge toolkit already exists.

| Feature | Why Expected | Complexity | Dependencies | Notes |
|---|---|---:|---|---|
| Named plain-data presets over the existing `QueryParams -> to_search_args -> context -> Scrypath.search/3` path | Real apps quickly repeat “same filters, sorts, facets, page defaults” across index, CSV/export, HTML, and LiveView flows | Med | existing query-toolkit contract | Presets should compile to the same plain args shape already accepted by contexts. No new runtime object model. `JOB-1`, `JOB-2`, `JOB-5` |
| Scope composition that is additive and explicit | Apps need to layer “base catalog”, “published only”, “tenant window”, “admin override”, “facet defaults” without hand-merging keywords in every controller | Med-High | preset contract; deterministic merge rules | Use right-biased merge rules per dimension, mirroring existing `search_many/2` merge discipline. Avoid hidden callback chains. `JOB-2`, `JOB-4` |
| Per-flow defaults plus caller overrides | Shared flows are only reusable if a page can start opinionated but still let the caller override page size, sort, query, or facet filters | Med | preset/scope merge semantics | This is the composition equivalent of Ecto’s composable query builders. Defaults must remain inspectable. `JOB-1`, `JOB-2` |
| Search-many-aligned entry composition | Global-search and dashboard flows need reusable per-schema presets, not just single-schema helpers | High | existing `search_many/2` semantics; per-entry validation | Composition must preserve per-schema options and failure boundaries. Do not imply cross-schema merged ranking or merged facets. `JOB-2`, `JOB-5` |
| Metadata reflection for declared filters, sorts, facets, and paging | Phoenix apps need one truth source to build forms, chips, selects, badges, and “reset filters” UIs without duplicating declarations | Med | existing schema reflection; request-edge contract | Return capability metadata, not generated UI. Include declared field names, option shape, and safe defaults. `JOB-1`, `JOB-2` |
| Visibility of active/defaulted criteria | Reusable composition becomes hard to debug if apps cannot see which defaults or scopes actually applied | Med | preset/scope runtime expansion | Expose normalized “applied search args” or equivalent debug-friendly metadata for logs/tests/docs. `JOB-2`, `JOB-5` |
| Explicit support for context-owned tenant scoping | SaaS apps need reusable search flows, but the host app must own who can see what | High | composition seam; docs | Composition can reserve a seam for tenant-safe scope injection, but must not claim authz by index prefix. Meilisearch and Typesense docs both treat scoped filtering/credentials as explicit configuration, not magic inference. `JOB-4` |
| Related-data-safe composition docs | Once presets exist, adopters will assume they solve associated-record fan-out too unless docs say otherwise | Low-Med | docs/examples | The feature is not fan-out automation. Docs must repeat that associated updates still require explicit app-owned sync/rebuild paths. Searchkick and Hibernate Search both show this line matters. `JOB-3`, `JOB-5` |
| Metadata for paging limits and facet/search capabilities | Honest UIs need to know max page behavior, facet-search support, and when a control should not render | Med | backend/schema metadata reflection | Meilisearch makes `filterableAttributes`, facet search, and `pagination.maxTotalHits` real behavioral constraints, so metadata should surface them. `JOB-2`, `JOB-5` |
| Worked real-app patterns, not just API docs | Composition only lands if the repo proves “one search box”, “catalog filter page”, and “global search dashboard” shapes end to end | High | example app; guide refresh | Required to prove reduced glue without widening scope. `JOB-1`, `JOB-2`, `JOB-3`, `JOB-4`, `JOB-5` |

## Differentiators

Features that would make `v1.22` notably stronger than a thin param-casting helper, while still staying inside the milestone guardrail.

| Feature | Value Proposition | Complexity | Notes |
|---|---|---:|---|
| Canonical “composition is data” API instead of opaque structs | Keeps Scrypath aligned with Ecto and current public boundary. Easier to diff, log, test, and feed into both `search/3` and `search_many/2` | Med | Strongest product fit for this repo. Prefer maps/keywords/plain structs only if they remain boring data containers, not behavioral query objects. |
| Introspectable preset registry per search flow | Lets apps ask “what filters/sorts/facets does this page support?” from the same declaration they execute | Med-High | Higher leverage than shipping form components. Useful for LiveView forms, JSON APIs, and admin UIs alike. |
| Per-entry composition helpers for `search_many/2` | Reusable global-search flows are a real app need and many libraries stay too single-index here | High | Should preserve declaration order, schema-local failure messages, and per-schema metadata. |
| Explicit “applied runtime contract” export for docs/tests | Gives maintainers a way to verify that presets/scopes do not silently drift from what a page claims to support | Med | Good candidate for doc contracts and example assertions. |
| Boundary-honest tenant hooks | Provide a first-class place for apps to inject tenant/account scope without Scrypath pretending to own authorization | Med-High | Valuable because B2B adopters need this today, but the library must stop short of issuing credentials or enforcing auth policy. |
| Recovery-aware composition guidance | Shows when a change is just a preset/default tweak versus when declared metadata or index settings changed enough to need backfill/reindex | Med | This is unusual and fits Scrypath’s product voice well. |

## Anti-features

Features to explicitly not build in `v1.22`.

| Anti-Feature | Why Avoid | What to Do Instead |
|---|---|---|
| Public `%Scrypath.Query{}` or new behavioral query DSL as the composition surface | Violates the current boundary and locks internal runtime structure into semver | Keep composition over the existing plain-data contract |
| Schema-generated runtime search functions from declarations | Crosses from reusable composition into framework magic and weakens context ownership | Keep contexts as the execution boundary |
| Phoenix-specific preset/controller/LiveView macros | Would collapse framework boundaries and duplicate the existing optional-helper stance | Keep Phoenix support at params/forms/URL metadata and worked examples |
| Generated UI components, form builders, or facet widgets | Too much scope for this milestone; the real leverage is metadata, not UI scaffolding | Expose metadata and provide docs/examples only |
| Automatic related-data propagation from preset declarations | Composition cannot truthfully infer all association fan-out or rebuild rules | Keep related-data propagation explicit in app code and recovery docs |
| Tenant isolation claims based on index prefixes or preset naming | Dangerous over-promise for SaaS adopters; prefixes are partitioning, not authorization | Support explicit tenant scope injection and document backend-native access controls separately |
| Cross-schema “merged relevance” facade for `search_many/2` presets | Existing runtime already warns that ranking stays per schema/index | Preserve per-entry results and merged-order honesty only |
| Hidden persistence of saved searches/playbooks in core `scrypath` | Reopens old OPSUI/product-surface sprawl | Leave persistence to host apps or future optional surfaces |
| Adapter-wide abstraction for non-Meilisearch UI capability parity | v1.22 is not the moment to promise backend-agnostic metadata semantics | Reflect what the current backend and declarations can honestly support |

## Feature dependencies

```text
Composition contract
  -> Named presets
  -> Additive scopes
  -> Deterministic merge rules
  -> Applied-runtime introspection

Metadata reflection
  -> Filters/sorts/facets/paging capability export
  -> Phoenix/JSON-friendly shapes
  -> Honest docs/examples

search_many/2 alignment
  -> Per-entry preset composition
  -> Per-schema metadata exposure
  -> Failure-boundary preservation

Tenant-safe and recovery-honest adoption
  -> Explicit tenant-scope injection seam
  -> Related-data boundary docs
  -> Rebuild/reindex guidance when declarations/settings drift
```

## MVP recommendation

Prioritize:

1. Plain-data presets plus additive scopes for single-schema flows.
2. Metadata reflection for declared filters, sorts, facets, and paging, including applied defaults.
3. `search_many/2` composition parity with per-entry presets and honest per-schema metadata.

Defer:

- UI components and Phoenix macros: wrong layer
- persisted saved searches: separate product
- automatic related-data fan-out: correctness trap
- tenant auth features beyond explicit scope injection seam: too broad for `v1.22`

## Recommended feature slices

| Slice | What ships | Why first |
|---|---|---|
| Slice 1 | Named presets, additive scopes, deterministic merge rules, applied-args introspection | Freezes the reusable core without changing runtime ownership |
| Slice 2 | Metadata reflection for filters/sorts/facets/paging and docs contract tests | Makes the composition layer useful to Phoenix and JSON consumers |
| Slice 3 | `search_many/2` composition parity and worked global-search/dashboard examples | Proves the layer scales past one schema without hiding canonical semantics |
| Slice 4 | Tenant/recovery/related-data guidance refresh | Prevents false confidence in real SaaS apps |

## Sources

- Official Ecto docs: [Dynamic queries](https://hexdocs.pm/ecto/dynamic-queries.html) and [Ecto.Query](https://hexdocs.pm/ecto/Ecto.Query.html)
- Official Phoenix docs: [Phoenix LiveView `handle_params/3`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html)
- Official Laravel docs: [Laravel Scout 12.x](https://laravel.com/docs/12.x/scout)
- Searchkick README: [ankane/searchkick](https://github.com/ankane/searchkick)
- Meilisearch Rails README: [meilisearch/meilisearch-rails](https://github.com/meilisearch/meilisearch-rails)
- Meilisearch docs/specs: [Settings](https://meilisearch.dev/docs/reference/api/settings), [Facet search](https://meilisearch.dev/docs/reference/api/facet_search), [Pagination](https://meilisearch.dev/docs/guides/front_end/pagination)
- Hibernate Search docs: [Stable reference guide](https://docs.hibernate.org/stable/search/reference/en-US/html_single/)
- Local context: `.planning/PROJECT.md`, `.planning/MILESTONE-ARC.md`, `.planning/milestone-candidates.md`, `.planning/seeds/SEED-002-composition-real-app-depth.md`, `guides/request-edge-search.md`, `guides/related-data-and-reindexing.md`, `guides/multi-index-search.md`, `guides/jtbd-and-user-flows.md`
