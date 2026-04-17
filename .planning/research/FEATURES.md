# Feature Research — v1.3 Search Power That Phoenix Teams Reach For

**Domain:** Ecto-native Meilisearch indexing library for Phoenix SaaS apps (persona 2, growth-stage)
**Researched:** 2026-04-17
**Confidence:** HIGH

## Scope Reminder

This document covers **only** the v1.3 target features:

1. Faceted search (declarative `faceting`, validated facet filters, facet distribution + stats on `SearchResult`, Phoenix LiveView guide)
2. Relevance tuning (synonyms, typo tolerance, ranking rules, distinct, stop words)
3. Multi-index search (`Scrypath.search_many/2`)
4. Operator polish (richer `FailedWork.t()`, drift recovery guide)
5. Release and tooling debt retirement (Node 20 deprecation, v1.2 VALIDATION.md closure)

v1.0–v1.2 features are already shipped and are **not** re-researched here — they show up only as dependencies the new features must preserve.

The locked non-goals (no second public backend, no vector/hybrid/semantic, no breaking change to v1.2 public contracts, no dashboard product surface) are treated as hard constraints. Every candidate feature below is checked against them explicitly under the "scope creep to avoid" column.

## Reference Library Calibration

The "table stakes" line is calibrated against what Searchkick, Laravel Scout, and Typesense ship as their first-backend-complete search surface, because v1.3 is the deliberate equivalent inflection point for Scrypath.

- **Searchkick** ships aggregations (smart facets scoped to filters by default), synonyms, stemming/typo, per-query boost/weights, and multi-model search. That is the "Rails user expects this" baseline.
- **Laravel Scout + Meilisearch driver** exposes facets through a callback escape hatch and ranking/synonyms through driver configuration. Scout itself stays deliberately thin, which matches Scrypath's posture of "owned APIs, backend-native escape hatch".
- **Typesense** documents range facets, hierarchical facets, and multi-search as first-class features — which clarifies which facet variants Phoenix users will ask for even if they are on Meilisearch.
- **Meilisearch's own `facetDistribution` + `facetStats` pair** defines the native shape (counts for categorical, min/max for numeric); any "faceted search that feels complete" on a Meilisearch-first library must surface both.

The practical read: for v1.3 table stakes, the bar is "what a Searchkick-fluent Phoenix dev reaches for in the first week after install", not "everything Algolia's faceting doc describes".

## Feature Landscape

### Table Stakes — Faceted Search

Features a growth-stage Phoenix SaaS will immediately try to use. Missing these means "Scrypath doesn't really do facets yet".

| Feature | Why Expected | Complexity | Depends On | Scope Creep To Avoid |
|---------|--------------|------------|------------|-----------------------|
| Declarative `faceting:` schema field (list of facet attributes) | Matches `filterable:` / `sortable:` ergonomic pattern in `use Scrypath`; operators want facets as metadata, not runtime config | LOW | `Scrypath.Options.validate_schema_options!/1`, `Scrypath.Schema.__scrypath__/1` reflection keys | Do not introduce a second per-schema macro — extend the existing NimbleOptions schema |
| Declared facet attributes auto-added to Meilisearch `filterableAttributes` on reindex | Meilisearch will not facet an attribute that is not filterable; forgetting this is the #1 facet gotcha | LOW | `Scrypath.Meilisearch.Settings.resolve/2`, existing reindex `create target → apply settings → backfill → cutover` ordering | Do not silently mutate the live index — settings must flow through the managed reindex path |
| `facets: [...]` option on `Scrypath.search/3` | Meilisearch requires an explicit per-query `facets` list; reference libraries (Searchkick `aggs`, Scout driver callback) accept the same at the call site | LOW | `Scrypath.Query` struct, `Scrypath.Meilisearch.Query.to_payload/1`, `Scrypath.Options.validate_search_options!/2` | Do not auto-request all declared facets every query — that bloats response payloads |
| `facet_distribution` on `Scrypath.SearchResult{}` | Direct Meilisearch response field; users need category → count to render filter UIs | LOW | `Scrypath.SearchResult.new/4`, existing `raw` passthrough | — |
| `facet_stats` on `Scrypath.SearchResult{}` | Meilisearch returns min/max for numeric facets; needed for range sliders and numeric UIs | LOW | Same as above | — |
| Facet filters validated through the existing common-path filter validator (extending `filterable` to accept faceted attributes) | Users expect `Scrypath.search(Post, "q", filter: [tag: "elixir"], facets: [:tag])` to work without escaping into backend-native strings | MEDIUM | `Scrypath.Options.validate_filter_entry!/2`, `Scrypath.Meilisearch.Query.translate_filter/1` | Do not expose a raw Meilisearch filter-DSL string as first-class input — that creates a second filter grammar |
| Counts consistent under active filters (smart-facet default) | Searchkick's default; Meilisearch already computes distribution against filtered result set; users expect "size: M (23)" to drop as they narrow — not stay frozen | LOW | Matches Meilisearch default behavior; just needs docs, not code | Do not build a disjunctive-facet workaround until a concrete adopter asks (see Backlog) |
| Phoenix LiveView guide ("faceted search that stays consistent across mounts, patches, and refreshes") | Persona 2 is shipping Phoenix; facets without a LiveView story are half-shipped | LOW | Existing `guides/phoenix-liveview.md` style and tone | Do not ship a LiveView component library — guide only |

**Minimum definition of "feels complete" for v1.3 faceting:** declarative facet attributes + facet distribution + facet stats + facet filters that reuse the existing filter validator + LiveView guide. That is strictly tighter than Algolia/Typesense parity and strictly wider than "pass facets through raw".

### Differentiators — Faceted Search

| Feature | Value Proposition | Complexity | Depends On | Scope Creep To Avoid |
|---------|-------------------|------------|------------|-----------------------|
| Scrypath-owned `FacetResult{}` struct | Stable Scrypath type across any future backend (preserves internal adapter seam); prevents `result.raw["facetDistribution"]` stringly-typed access from leaking into user code | LOW | `Scrypath.SearchResult` | Do not make the struct so rich it implies public multi-backend parity |
| Declarative numeric range facets (`faceting: [rating: :numeric]` → expose min/max and a sensible "suggested buckets" helper) | Meilisearch only gives min/max; a thin Scrypath helper that buckets from min/max into UI-ready ranges is a concrete DX win over raw `facet_stats` | MEDIUM | Facet distribution + stats plumbing above | Do not invent custom bucketing grammar — keep it one helper function |
| Operator-visible facet drift (schema declares `faceting`, live index missing it → `Scrypath.reconcile_sync/2` flags it) | Ties new feature into v1.2 operator surface so "I declared a facet and it's not working" becomes a known reconcile signal instead of a silent miss | MEDIUM | `Scrypath.Operator.Reconcile`, `Scrypath.Meilisearch.Settings.resolve/2` | Do not auto-heal — reconcile stays report-first |

### Anti-Features — Faceted Search

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Hierarchical/nested facet grammar (`category.>cat.sub`) as first-class declaration | Algolia/Typesense docs make it sound standard | Meilisearch does not ship a first-class hierarchical facet operator — it is convention over a flat `level0`/`level1`/`level2` field layout. Baking in a Scrypath-specific grammar would trap us with a second-facet grammar when/if Meilisearch adds one | Document the `category.lvl0` convention in the LiveView guide. Users who need it keep the convention in projection. Revisit after adopter signal. |
| Disjunctive facets (counts for a facet unaffected by that same facet's active filters) | Amazon-style "you have other sizes available" UIs | Meilisearch does not have native disjunctive facet counts at the single-query level; faking it requires per-facet re-queries which distort the query count. Users will think Scrypath is the slow thing | Document the tradeoff; leave as "run a second query explicitly when you need this" until there is a clear Meilisearch story |
| Implicit facet auto-declaration ("anything you filter on is automatically a facet") | Looks friendlier than declaring both | Conflates two distinct indexing cost decisions; forces operators into accidental index bloat; reverses the "no hidden runtime behavior" posture that the existing `filterable`/`sortable` contract committed to | Keep `faceting:` explicit; document that facets must be declared just like `filterable:` |
| Free-text `filter: "raw meilisearch string"` input on the common path | Power users asking for escape hatch | v1.2 locked the common-path filter validator as the stable public contract. Accepting raw backend-native strings would reopen a grammar boundary we intentionally closed | Point users at `Scrypath.Meilisearch.*` namespace for the actual escape hatch |

### Table Stakes — Relevance Tuning

| Feature | Why Expected | Complexity | Depends On | Scope Creep To Avoid |
|---------|--------------|------------|------------|-----------------------|
| Declarative `settings:` keys for `synonyms`, `typo_tolerance`, `stop_words` | Searchkick/Scout expose all three from day one; these are "turn on search that isn't frustrating" table stakes | LOW | Existing `Scrypath.Options.validate_settings/1` (already accepts a plain map), `Scrypath.Meilisearch.Settings.resolve/2` | Do not invent a richer DSL — pass through the Meilisearch-native map shape |
| Declarative `settings:` keys for `ranking_rules` and `distinct_attribute` | Ranking rules are the "why are Exact matches buried under popularity?" knob; distinct attribute is the classic "stop showing six variants of the same product" knob | LOW | Same as above | Do not default a custom ranking — ship Meilisearch's default (`words, typo, proximity, attribute, sort, exactness`) and document how to override |
| All five settings applied through the managed reindex path (not inline hot-patch of live index) | Silent settings drift on the live index is the #1 "my facets stopped working" class of bug. Settings + reindex must be one atomic flow | MEDIUM | Existing `create target → apply settings → backfill → cutover` ordering in `Scrypath.reindex/2`, `cutover?: false` safety valve | Do not add a `Scrypath.apply_settings!/2` shortcut that bypasses reindex — that is exactly what the v1.2 architecture warned against |
| Settings visible in `Scrypath.reconcile_sync/2` output when target index ≠ declared settings | Operators need drift legibility for settings, not just document counts | MEDIUM | `Scrypath.Operator.Reconcile` | Do not auto-trigger a rebuild on mismatch — reconcile stays report-first |
| Backfill preservation — declared settings on a schema do not force a full rebuild if the live index is already at the same settings | Silent "settings change" forcing reindex on every deploy is the Searchkick pain Phoenix devs remember | MEDIUM | Settings diff detection in reindex flow | Do not ship "automatic settings diff and heal" — detect only, still require explicit `Scrypath.reindex/2` |

**Minimum definition of "feels complete" for v1.3 relevance tuning:** all five settings (synonyms, typo tolerance, ranking rules, distinct, stop words) declarable on the schema, applied through the managed reindex pipeline, visible to reconcile, with a drift story. Only two of the five is not defensible — synonyms and typo tolerance alone would leave users immediately hitting ranking questions and the "duplicate variant" bug.

### Differentiators — Relevance Tuning

| Feature | Value Proposition | Complexity | Depends On | Scope Creep To Avoid |
|---------|-------------------|------------|------------|-----------------------|
| Per-environment setting overrides via runtime config (e.g. weaker typo tolerance in tests) | Removes the "CI-only search flake" class of bug. Searchkick-style DX win | LOW | `Scrypath.Config.resolve!/1` already treats runtime opts as canonical | Do not invent a second settings path — runtime override, declared default |
| Telemetry span on `settings_applied` in reindex result (already present as a boolean) upgraded to carry a setting-level diff | Makes "why did reindex take 40 minutes this time" legible during deploys | MEDIUM | `[:scrypath, :meilisearch, :task_wait, ...]` span family, existing reindex result shape | Do not add a new top-level telemetry namespace |

### Anti-Features — Relevance Tuning

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Auto-synonym generation from user query logs | "Smart" and familiar from commercial search | Requires a query-log pipeline Scrypath does not have and should not own; also drifts into analytics territory that PROJECT.md explicitly defers | Out of scope. Revisit only if Meilisearch ships a native primitive |
| Dynamic per-request ranking rule overrides on the common `Scrypath.search/3` path | Users think they want "boost recent posts just for this search" | Blurs the line between index-level settings and query-level behavior; invites arbitrary expression grammar on the common path | Point users at `Scrypath.Meilisearch.*` namespace for backend-native power |
| Stemming/lemmatization knobs beyond what Meilisearch natively exposes | Searchkick has stemming language options | Meilisearch handles this internally and does not expose it as tunable settings; surfacing a knob that does nothing is worse than omitting it | Document Meilisearch's native language handling in the relevance-tuning guide |
| Vector/hybrid ranking | Currently hot; every search library is adding it | Explicitly listed as an Out-of-Scope non-goal for v1.3 (`PROJECT.md`). Adding even a toe-hold here invites scope creep | Hard no for v1.3; revisit in a future milestone after adoption pressure |

### Table Stakes — Multi-Index Search

| Feature | Why Expected | Complexity | Depends On | Scope Creep To Avoid |
|---------|--------------|------------|------------|-----------------------|
| `Scrypath.search_many(schemas_with_opts, shared_opts)` entry point | Global-search across "posts + comments + users" is the canonical v1.3 UX lift for Phoenix SaaS — users reach for it the moment they have >1 indexed schema | MEDIUM | `Scrypath.search/3`, `Scrypath.Query.new/2`, `Scrypath.Options.validate_search_options!/2` | Do not invent a third option-validation path — build it on top of per-schema validation |
| Per-schema validation preserved (each sub-query validated against its own `filterable` / `sortable` / `faceting`) | Persona 2 will write `search_many([{Post, filter: [status: :published]}, {Comment, filter: [approved?: true]}], "q")` — validation cannot silently widen to a union | MEDIUM | Same as above; call into the existing per-schema validator once per sub-query | Do not pre-merge option lists across schemas — that collapses the per-schema contract |
| Backend federation through Meilisearch's native `/multi-search` endpoint | Meilisearch 1.10+ ships native federated search; round-trip coalescing is real. Sequential `search/3` calls would be observably slower | MEDIUM | `Scrypath.Meilisearch.Client` (extend), new backend behavior callback if warranted | Do not introduce a second backend behavior — extend `Scrypath.Meilisearch.*` as the namespaced escape hatch, keep the internal seam private |
| Hydration preserved per-schema (each schema's hits hydrate into that schema's records through its own repo/preload) | Multi-index without per-schema hydration is raw JSON; Phoenix users will ask "why does this not return structs?" | MEDIUM | `Scrypath.Hydration.hydrate/3`, existing `SearchResult` shape | Do not force a single flat list — see next row |
| Results grouped per schema (shape: `%{MyApp.Blog.Post => %SearchResult{...}, MyApp.Blog.Comment => %SearchResult{...}}`) | Preserves per-schema `missing_ids`, `page`, `hits` legibility; matches how the native federated response encodes provenance; matches how LiveView code actually renders "posts section, comments section" | MEDIUM | `Scrypath.SearchResult`, the `_federation.indexUid` field from Meilisearch's federated response | Do not expose a flat `[hit | hit | hit]` list as the primary shape — see Anti-Features |

**Minimum definition of "feels complete" for v1.3 multi-index:** `Scrypath.search_many/2` that preserves per-schema validation and per-schema hydration and returns a per-schema grouped result map. Anything thinner is "call `search/3` in a loop yourself" and does not earn a new verb on `Scrypath.*`.

**Grouped vs flat — the explicit recommendation:** grouped per-schema is the right primary return shape for Scrypath specifically, because:

1. `missing_ids` and `page` metadata are per-index concepts; a flat list loses them.
2. Hydration is repo-per-schema; a flat list forces runtime type-dispatching.
3. Phoenix LiveView rendering is almost always "section per type" — the grouped shape is what renders.
4. A flat helper can always be derived from the grouped shape in user code; the reverse is not true without re-tagging every hit.

Meilisearch's native federated mode returns a flat list with `_federation.indexUid`. Scrypath should consume that native shape internally (it is the whole point of using the `/multi-search` endpoint) but present a grouped shape to users. The flat native shape can remain accessible under the `Scrypath.Meilisearch.*` escape hatch for users who need it.

### Differentiators — Multi-Index Search

| Feature | Value Proposition | Complexity | Depends On | Scope Creep To Avoid |
|---------|-------------------|------------|------------|-----------------------|
| Mixed sync-mode tolerance (`search_many` works cleanly even if one schema is `:oban`-synced and another is `:inline`) | v1.2 committed to three sync modes as first-class; multi-index that only works under one mode would break that contract | LOW | v1.2 sync-mode contract (search is read-side only; sync mode only affects write path) | — |
| `%{schema => SearchResult}` layout that preserves the v1.0 explicit-hydration contract per schema | Users keep one mental model across `search/3` and `search_many/2` — no new hydration semantics to learn | LOW | `Scrypath.Hydration` | Do not introduce a cross-schema `preload:` — per-schema only |
| Scrypath-owned failure envelope when one sub-query errors (other sub-queries still return results, failed one returns `{:error, reason}` inside the map) | Partial-failure legibility matches Scrypath's existing "operational honesty" posture | MEDIUM | Error normalization in `Scrypath.Meilisearch` transport layer | Do not silently swallow individual failures — honest partial results |

### Anti-Features — Multi-Index Search

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Flat `[hit, hit, hit]` as the primary return shape | Feels "simpler" at first glance; matches Meilisearch's native federated response | Loses per-schema `missing_ids` and `page`; forces runtime type dispatch during hydration; Phoenix rendering almost always wants grouping anyway; you cannot derive grouping from flat without re-tagging | Grouped map as primary; flat accessor available via raw access or backend-native namespace |
| Cross-index relevance/score merging knobs (custom federation weights per schema) | Algolia-style "federated with weighted ranking" | Meilisearch exposes this natively; adding a second Scrypath knob on top duplicates and diverges. Falls into the "backend-native power" bucket that should live under `Scrypath.Meilisearch.*` | Expose Meilisearch's native federation options through the backend-native namespace only |
| Shared filter/sort across all sub-queries at the top level | Looks DRY | Each schema has its own `filterable`/`sortable` list; a shared filter would either silently ignore fields for some schemas or raise inconsistently. Breaks per-schema validation | Users write per-schema options explicitly; document the small boilerplate as intentional |
| Implicit global search ("search all Scrypath-registered schemas") | Familiar from some SaaS UIs | Scrypath has no global schema registry; building one introduces a hidden runtime concept that violates the "explicit orchestration" posture | Require an explicit schema list — it is the one unavoidable keystroke |

### Table Stakes — Operator Polish

These are tightly scoped extensions to the v1.2 operator surface, not a new operator product.

| Feature | Why Expected | Complexity | Depends On | Scope Creep To Avoid |
|---------|--------------|------------|------------|-----------------------|
| `FailedWork.t()` gains `attempt_count` | Already available on Oban job state and Meilisearch task payload; operators need it to tell "flakey" from "genuinely broken" | LOW | `Scrypath.Operator.FailedWork`, `Scrypath.Oban.Inspect` | — |
| `FailedWork.t()` gains `error_reason_class` (stable atom like `:transport_timeout`, `:validation_error`, `:backend_rejected`, `:unknown`) | `reason` is currently a free-text string; operators cannot group or count failures by class. Phoenix SaaS operators want "30 retries failed the same way" visibility | MEDIUM | Failure classification in `Scrypath.Operator.FailedWork.from_backend_task/3` and `from_queue_job/3` | Do not promise exhaustive taxonomy — start with the 3-4 classes we can classify reliably today, keep `:unknown` as an honest default |
| `FailedWork.t()` gains `last_attempt_at` | Already parsed into `failed_at`; rename/semantic-split so operators know "last time we tried" vs "originally failed" | LOW | Same as above | Retain `failed_at` as an alias for one release cycle if needed to avoid a v1.2 break |
| End-to-end drift recovery guide that chains sync_status → failed_sync_work → retry_sync_work → reconcile_sync → backfill/reindex | v1.2 shipped the APIs but not the runbook. The "what do I actually do when search is wrong in production at 3am" narrative was deferred | LOW | All four v1.2 operator APIs, existing `guides/sync-modes-and-visibility.md` tone | Do not ship a second operator surface — guide only, no new APIs |

**Minimum definition of "feels complete" for v1.3 operator polish:** `FailedWork.t()` gets the three new fields and one end-to-end recovery guide exists. Nothing else. Anything beyond that belongs to v1.4's deferred "deeper drift/schema-diff operator tooling".

### Differentiators — Operator Polish

| Feature | Value Proposition | Complexity | Depends On | Scope Creep To Avoid |
|---------|-------------------|------------|------------|-----------------------|
| Failure-class rollup on `Scrypath.failed_sync_work/2` (returns `%{count_by_class: %{...}, entries: [...]}`) | Operators read the rollup before diving into individual entries — classic "failed-work triage" UX | LOW | `FailedWork.error_reason_class` | Do not introduce a separate summary API — fold into existing return shape |

### Anti-Features — Operator Polish

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Rich failure taxonomy with 20+ error classes | Feels "professional" | We do not have the corpus to classify reliably; wrong classes are worse than `:unknown`; `PROJECT.md` explicitly says "narrow operator polish, not surface expansion" | Ship 3-4 honest classes plus `:unknown`; expand after adoption signal |
| Auto-retry-on-specific-class behavior ("automatically retry `:transport_timeout` up to N times") | Feels like progress | v1.2 explicitly chose report-first, no auto-heal; auto-retry on class reopens that design question | Leave retry explicit via `Scrypath.retry_sync_work/2`; class is a hint, not a trigger |
| Dashboard for failed work | Familiar from commercial search-ops tools | Listed as an explicit non-goal in the milestone context ("no dashboard product surface") | Mix tasks and guides remain the operator surface |

### Table Stakes — Release And Tooling Debt Retirement

This category is small by design — it is finishing housekeeping, not shipping new capability.

| Feature | Why Expected | Complexity | Depends On |
|---------|--------------|------------|------------|
| GitHub Actions upgraded past Node 20 deprecation | CI hygiene; annotations noise during every run erodes trust in the green checkmark | LOW | `.github/workflows/*` |
| Missing `VALIDATION.md` for v1.2 phases 13, 14, 15 | Closes milestone-close audit debt identified in `v1.2-MILESTONE-AUDIT.md`; future milestone closes cleanly | LOW | v1.2 phase artifacts |

### Anti-Features — Release And Tooling Debt Retirement

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| "Modernize the whole CI stack while we're in there" | Tempting once you open the workflow files | Scope creep that competes with v1.3's actual goal; CI rework deserves its own milestone if it deserves one at all | Scope strictly to the deprecated actions; log anything else in Backlog |
| Retroactive documentation rewrites of v1.0/v1.1 phases | "Now that we know more" | Rewriting archived milestone artifacts erodes the milestone-archive contract | Only write the three missing VALIDATION.md files; do not touch already-complete artifacts |

## Feature Dependencies

```
[Declarative faceting:]
    └──requires──> [Scrypath.Options schema extension]
    └──requires──> [Scrypath.Schema.__scrypath__(:faceting) reflection key]

[Facet filters on common path]
    └──requires──> [Existing filter validator extension]
    └──requires──> [Meilisearch.Query.translate_filter/1 preserving array-of-arrays OR-within-AND semantics]

[Declarative settings (synonyms/typo/ranking/distinct/stop)]
    └──requires──> [Existing validate_settings (already accepts plain map)]
    └──requires──> [Managed reindex pipeline, applied only through that path]

[SearchResult.facet_distribution + facet_stats]
    └──requires──> [SearchResult.new/4 signature extension]

[Scrypath.search_many/2]
    └──requires──> [Per-schema option validation reused]
    └──requires──> [Per-schema hydration preserved]
    └──requires──> [Meilisearch /multi-search endpoint wiring]

[FailedWork.attempt_count / error_reason_class / last_attempt_at]
    └──requires──> [Scrypath.Operator.FailedWork struct extension]
    └──requires──> [Oban job inspect + Meilisearch task payload parsing]

[Drift recovery guide]
    └──requires──> [All v1.2 operator APIs already shipped]
    └──requires──> [New FailedWork fields above, for the recovery narrative to be honest]

[Reconcile flags setting drift / facet drift]
    └──requires──> [Declarative faceting declared]
    └──requires──> [Declarative settings declared]
    └──requires──> [Scrypath.Operator.Reconcile extension]

[Release/tooling debt]
    (independent — can ship in parallel)
```

### Dependency Notes

- **Facet filters extend the existing filter validator, they do not replace it.** The current validator (`Scrypath.Options.validate_filter_entry!/2`) already rejects `:or`/`:and`/`:not` boolean composition. Facet filters need the same field-is-declared gate, plus a decision on whether to finally allow OR-within-a-single-field for the common `[tag: ["elixir", "phoenix"]]` UX. That decision is contained and backward-compatible (widening, not narrowing).
- **Settings + reindex is one atomic workflow.** The v1.2 architecture fixes the order `create target → apply settings → backfill → cutover` on purpose. Any new setting declared on the schema must flow through this path. A `Scrypath.apply_settings/2` shortcut is the temptation to resist.
- **`search_many/2` is a thin federation layer over the existing search path.** It must not fork a new validation path, a new hydration path, or a new result struct. Per-schema `SearchResult{}` values in a map is the right layout.
- **Operator polish is additive on the existing struct.** Adding fields to `Scrypath.Operator.FailedWork` is backward-compatible. A rename of `failed_at` → `last_attempt_at` is the one risk; use an alias for one release if needed.
- **Reconcile extensions are optional polish.** If time pressure hits, ship the declarative facets and settings first; reconcile flagging drift for those is a nice-to-have within v1.3, not a table stake.

## MVP Definition — v1.3

### Ship With v1.3 (table stakes across all five categories)

- [x] Declarative `faceting:` schema field
- [x] Auto-addition of faceted attributes to `filterableAttributes` via managed reindex
- [x] `facets: [...]` option on `Scrypath.search/3`
- [x] `facet_distribution` and `facet_stats` on `%Scrypath.SearchResult{}`
- [x] Facet filters validated through the existing common-path validator
- [x] Phoenix LiveView faceted search guide
- [x] Declarative settings for `synonyms`, `typo_tolerance`, `ranking_rules`, `distinct_attribute`, `stop_words`
- [x] All five settings applied only through the managed reindex pipeline
- [x] `Scrypath.search_many/2` with per-schema validation, per-schema hydration, grouped-by-schema result map
- [x] `FailedWork.t()` gains `attempt_count`, `error_reason_class`, `last_attempt_at`
- [x] End-to-end drift recovery guide
- [x] GitHub Actions Node 20 deprecation cleanup
- [x] VALIDATION.md for v1.2 phases 13/14/15

### Strong Candidates For v1.3 (differentiators, ship if capacity allows)

- [ ] Scrypath-owned `FacetResult{}` struct wrapping distribution + stats
- [ ] Declarative numeric range facets with a "suggested buckets" helper
- [ ] Reconcile flags setting drift and facet drift
- [ ] Failure-class rollup on `Scrypath.failed_sync_work/2`
- [ ] Partial-failure envelope for `search_many/2`

### Defer To v1.4+ (explicit backlog items — not v1.3 decisions)

- [ ] Hierarchical facet grammar — wait for adopter pressure and/or native Meilisearch primitive
- [ ] Disjunctive facet counts — wait for Meilisearch roadmap or adopter pressure
- [ ] Per-query ranking overrides — keep under `Scrypath.Meilisearch.*` escape hatch until the common-path demand is proven
- [ ] Deeper drift/schema-diff operator tooling — explicitly deferred by `PROJECT.md` to v1.4
- [ ] Second public backend — blocked by non-goal; backlog only
- [ ] Vector/hybrid/semantic search — blocked by non-goal; backlog only
- [ ] Dashboard product surface — blocked by non-goal; backlog only

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Declarative `faceting:` + facet distribution + facet stats + facet filters | HIGH | LOW–MEDIUM | P1 |
| Phoenix LiveView faceted search guide | HIGH | LOW | P1 |
| Declarative settings (synonyms, typo, ranking, distinct, stop_words) via reindex pipeline | HIGH | MEDIUM | P1 |
| `Scrypath.search_many/2` grouped-by-schema with per-schema validation + hydration | HIGH | MEDIUM | P1 |
| `FailedWork.t()` richer fields (attempt_count, error_reason_class, last_attempt_at) | MEDIUM | LOW–MEDIUM | P1 |
| End-to-end drift recovery guide | MEDIUM | LOW | P1 |
| GitHub Actions Node 20 + v1.2 VALIDATION.md closure | MEDIUM | LOW | P1 |
| Scrypath-owned `FacetResult{}` struct | MEDIUM | LOW | P2 |
| Reconcile flags facet/settings drift | MEDIUM | MEDIUM | P2 |
| Failure-class rollup | MEDIUM | LOW | P2 |
| Numeric range facet helper | LOW–MEDIUM | MEDIUM | P2 |
| Per-env setting overrides via runtime config | LOW | LOW | P2 |
| Hierarchical facet grammar | LOW | HIGH | P3 (backlog) |
| Disjunctive facet counts | LOW | HIGH | P3 (backlog) |
| Per-query ranking overrides on common path | LOW | HIGH | P3 (backlog) |

**Priority key:**
- P1: v1.3 table stakes — milestone fails without these
- P2: v1.3 differentiators — ship if capacity; milestone still ships without
- P3: Deferred to v1.4+ — recorded so scope creep pressure meets an answer

## Competitor Feature Analysis

| Feature | Searchkick (ES) | Laravel Scout + Meilisearch | Typesense | Scrypath v1.3 (proposed) |
|---------|-----------------|-----------------------------|-----------|--------------------------|
| Declarative facets | Implicit via `aggs:` at query-time | Callback-based, no declaration | Per-collection facet fields | Declarative `faceting:` at schema level (most explicit of the four) |
| Facet counts under filters | Smart aggs default (scoped to filters) | Whatever Meilisearch returns | Scoped to filter default | Scoped to filter default (matches Meilisearch + Searchkick) |
| Facet stats (min/max) | Via `stats` aggs | Raw Meilisearch response | Explicit in facet response | First-class `facet_stats` on `SearchResult` |
| Hierarchical facets | Convention-based | Convention-based | Explicit `facet_return_parent` | Convention-based (deferred) |
| Range facets | Range aggs | Raw Meilisearch | Explicit range facet grammar | `facet_stats` + optional helper (deferred) |
| Synonyms | Declared on model | Config-level | Per-collection | Declared via `settings:` on schema |
| Typo tolerance | Declared on model | Config-level | Per-query + per-collection | Declared via `settings:` on schema |
| Ranking rules | Weights / boost at query time | Meilisearch-native | Per-collection | Declared via `settings:` (index-level only for v1.3) |
| Distinct | `unscope`, `distinct` | Meilisearch-native | Explicit | Declared via `settings:` |
| Stop words | Declared on model | Config-level | Per-collection | Declared via `settings:` |
| Multi-index search | Multi-model `Searchkick.search` | Collection-per-model | `multi_search` endpoint | `Scrypath.search_many/2` grouped by schema |
| Multi-index return shape | Flat, mixed | Per-collection | Per-collection | Grouped by schema (primary); flat accessible via backend-native namespace |
| Failure inspection | Limited (ES-native) | None as first-class | None as first-class | Rich `FailedWork.t()` (inherited from v1.2, extended in v1.3) |
| Dashboard product | None (lib only) | None (lib only) | None (lib only) | None (explicit non-goal) |

The takeaway: Scrypath's declarative-first posture (facets, settings) is legitimately more explicit than all three reference libraries, and its operator surface is strictly richer. That is the Core Value ("feels native to Ecto", "doesn't hide operational realities") showing up as product differentiation. v1.3 should lean into it.

## Scope Creep Risks — Explicit Non-Goal Check

| Tempting v1.3 Addition | Which Non-Goal It Violates | Verdict |
|------------------------|----------------------------|---------|
| Second backend adapter (Typesense, Elasticsearch) | "No second public backend" | Hard no. Keep internal seam internal. |
| Vector/hybrid/semantic search hook | "No vector/hybrid/semantic search" | Hard no. Even a `settings[:embedders]` pass-through invites scope creep. |
| Hot-patch settings on the live index | "No breaking changes to v1.2 public contracts" (reindex ordering is the public contract) | Hard no. Settings flow through reindex only. |
| Web dashboard for operator APIs | "No dashboard product surface" | Hard no. Mix tasks + guides remain the operator surface. |
| Raw Meilisearch filter-DSL string as first-class `filter:` input | "No breaking changes to v1.2 public contracts" (filter validator is public) | Hard no. Remains under `Scrypath.Meilisearch.*`. |
| Public `Scrypath.Backend` behavior extension | "No breaking changes to v1.2 public contracts" (internal seam is internal) | Hard no. Extend the backend internally; do not widen the public surface. |
| Auto-heal reconcile actions | v1.2 design decision (report-first) | Hard no within v1.3. |

## Sources

- Meilisearch faceted search reference — [Search with facets](https://www.meilisearch.com/docs/learn/filtering_and_sorting/search_with_facet_filters), [Return stats for numerical facets (discussion #117)](https://github.com/orgs/meilisearch/discussions/117), [Guide to hierarchical faceted search](https://www.meilisearch.com/blog/nested-hierarchical-facets-guide), [Meilisearch roadmap — facet count on disjunctive filters](https://roadmap.meilisearch.com/c/73-keep-facet-count-on-disjunctive-filters)
- Meilisearch multi-search reference — [Performing federated search](https://www.meilisearch.com/docs/learn/multi_search/performing_federated_search), [Multi-search API specification](https://specs.meilisearch.dev/specifications/text/0192-multi-search-api.html), [Multi-Index Search discussion #489](https://github.com/orgs/meilisearch/discussions/489), [Meilisearch 1.10 release notes](https://www.meilisearch.com/blog/meilisearch-1-10)
- Meilisearch settings reference — [Settings API](https://www.meilisearch.com/docs/reference/api/settings), [Typo Tolerance spec](https://specs.meilisearch.dev/specifications/text/0117-typo-tolerance-setting-api.html), [Settings API spec](https://specs.meilisearch.dev/specifications/text/0123-settings-api.html)
- Reference libraries — [Searchkick (ankane/searchkick) README](https://github.com/ankane/searchkick), [Searchkick aggregations (GoRails)](https://gorails.com/forum/facets-with-searchkick), [Laravel Scout 12.x](https://laravel.com/docs/12.x/scout), [Laravel Scout Meilisearch integration](https://meilisearch.com/docs/guides/laravel_scout), [Typesense search API](https://typesense.org/docs/30.1/api/search.html)
- Project-internal sources — `.planning/PROJECT.md`, `.planning/milestones/v1.2-ROADMAP.md`, `README.md`, `ARCHITECTURE.md`, `guides/sync-modes-and-visibility.md`, `lib/scrypath/search.ex`, `lib/scrypath/search_result.ex`, `lib/scrypath/meilisearch/query.ex`, `lib/scrypath/meilisearch/settings.ex`, `lib/scrypath/operator/failed_work.ex`, `lib/scrypath/options.ex`, `lib/scrypath/schema.ex`, `lib/scrypath/query.ex`

---
*Feature research for: Scrypath v1.3 search-power milestone*
*Researched: 2026-04-17*
