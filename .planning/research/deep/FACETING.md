# Deep Research: Faceted Search for Scrypath v1.3

**Domain:** Ecto-native Meilisearch-first Elixir library (`scrypath 0.3.0` on Hex) — v1.3 Phase 20 Faceted Search design
**Researched:** 2026-04-17
**Confidence:** HIGH (grounded in direct module reads at HEAD + cross-library survey of Searchkick, Laravel Scout+Meilisearch, Typesense, algoliasearch-rails, Chewy, and Meilisearch's own specs)
**Scope:** Deep, opinionated design for faceted search — one recommendation per question, with tradeoff analysis.

---

## Executive Recommendation

Scrypath v1.3 faceted search ships as **schema-declarative-primary with runtime-kwarg-narrow**: a compile-time `faceting: [attributes: [...]]` schema key (reflected via `__scrypath__(:faceting)`, validated to require membership in `filterable:`) combined with three narrow runtime kwargs on `Scrypath.search/3` — `facets: [:genre, :year]` to request distribution, `facet_filter: [genre: ["fiction", "horror"]]` to filter (OR within a key, AND across keys, no boolean escape hatch), and automatic passthrough of Meilisearch-computed `facet_stats` for numeric attributes. The return shape is a Scrypath-owned sub-struct `%Scrypath.SearchResult.Facets{distribution: %{atom() => [%Bucket{value, count}]}, stats: %{atom() => %{min, max}}, declared_order: [...]}` added outside `@enforce_keys` on `%SearchResult{}`. Active-filter counts follow Meilisearch's native behavior (counts refined by active filters) — users who need disjunctive behavior get a guide-level recipe using multiple `Scrypath.search_many/2` requests, not a new API. The Phoenix LiveView guide ships a worked "movies by genre × year × rating" example with a sidebar-checkbox UI, URL-synced filters, and a numeric-range slider driven by `facet_stats`. Translation to Meilisearch's array-of-arrays filter syntax is confined to `Scrypath.Meilisearch.Query`. This gives Scrypath the most explicit declarative DX of the surveyed libraries (beating Searchkick's runtime-only `aggs`, Scout's callback-only shape, and Typesense's looser `facet: true` per-field flag) while refusing to reopen the filter-grammar boundary that v1.2 deliberately closed.

---

## Reference Library Survey

| Library | What They Did Right | What They Did Wrong | Lesson for Scrypath |
|---------|---------------------|---------------------|----------------------|
| **Searchkick** (Ruby/Rails, ES/OpenSearch) | Runtime `aggs` API is composable and chainable; default behavior applies active filters to aggregations (smart aggs) — matches what users actually want; supports range/date-histogram/custom-where at the aggregation level. | Deprecated `facets` without migration guide; legacy code paths kept different semantics (facets didn't apply where; aggs do) — source of a well-known gotcha. No compile-time declaration at all — aggs are runtime-only, so you can aggregate on any field and discover-at-runtime whether it works. | Take the **smart-aggs default** (active-filter-refined counts) and take the **runtime `facets:` kwarg**. REJECT the runtime-only declaration — Scrypath's declarative posture is stronger. Explicit migration: never ship two near-synonymous names (facets vs aggregations); pick one word and hold it. |
| **algoliasearch-rails** (Ruby, Algolia) | `attributesForFaceting [:company, :zip_code]` is **declarative inside the model block** — exactly the pattern Scrypath already uses for `filterable:` / `sortable:`. Search returns `hits.facets["company"]` — a predictable shape. Supports separate `search_for_facet_values` for facet-value autocomplete. | String-keyed facet response map (`hits.facets["company"]`) leaks JSON shape into Ruby code — users pattern-match on strings forever. Ranked-order knobs (`searchable(:field)`, `filterOnly(:field)`) pile up inside the DSL block and become hard to read. `facets: '*'` wildcard encourages fetching every declared facet per request — bloats payload. | STEAL the **declarative-in-schema-block** pattern. REJECT the string-keyed return shape (Scrypath uses atom keys). REJECT the `facets: '*'` wildcard — per-request explicit facet list prevents payload bloat. |
| **Typesense** (JSON schema, Typesense server) | `facet: true` per-field in collection schema is admirably explicit. `facet_query` supports facet-value search. Returns structured `facet_counts` with `field_name` + `counts: [{value, count, highlighted}]` — preserves ordering, easy to iterate. Range facets (`facet_by: "price(0..10, 10..100)"`) are first-class. | `facet_by` at query-time is **also** required alongside the schema declaration — two places to remember. Issue #534: users confused by `facet_by` accepting auto-inferred fields inconsistently. Issue #1412: parentheses in field names break the grammar — string-embedded DSL pain. Issue #538: multi-value arrays in a single document need workarounds. | STEAL the **array-of-buckets-with-ordering** return shape (Scrypath ships `[%Bucket{value, count}]` not a `%{value => count}` map). REJECT the **two-place declaration** — Scrypath declares once in the schema, requests per-query. Numeric ranges defer to v1.4 (see Question 6 / Non-Goal Tripwires). |
| **Laravel Scout + Meilisearch driver** (PHP) | Deliberately thin. Escape-hatch callback: `Book::search('q', fn(Indexes $m, $q, $opts) => ...)`. Matches Scrypath's "backend-native under `Scrypath.Meilisearch.*`" posture at a philosophical level. | NO first-class faceting — users drop into a callback with a raw Meilisearch client. Means every team reinvents the facet response shape; means validation is bypassed; means filter/facet_filter/sort get mixed up in one opaque closure. | The thinness is aspirational, not to emulate. Scout teams that ship facets end up writing their own wrapper library — proving the market wants the exact thing Scrypath is building. Scrypath ships the wrapper Scout refused to ship. |
| **Chewy** (Ruby, Elasticsearch) | Declarative `agg` method in index definition lets you define named aggregations reusable across queries. Composable `.aggs({ avg_rating: { avg: { field: 'rating' } } })` chaining. | DSL-heavy to the point of cognitive overhead — named aggregations with nested ES DSL in every model; users end up writing aggregation-specific code for what should be straightforward category counts. The expressivity is a footgun for the 90% case. | AVOID named-aggregation DSL — it's over-engineered for the category-counts case that 90% of growth-stage Phoenix SaaS actually want. Scrypath's surface stays: declare the attribute, request counts, get them back. |
| **Meilisearch Elixir client** (`meilisearch-elixir`) | Thin HTTP wrapper; doesn't pretend to be an ORM integration; respects backend-native JSON shape. | Pure transport — no schema contract, no Ecto integration, no hydration. That's the **gap** Scrypath exists to fill. | Scrypath is the missing layer on top of a transport library. Don't duplicate what the transport client does. |
| **react-instantsearch** (UI) | Mental-model-clear widgets: `RefinementList` (checkbox list, disjunctive-or-conjunctive), `RangeSlider` (numeric), `HierarchicalMenu` (tree), `CurrentRefinements` (chip row), `ClearRefinements`. Well-understood `operator: 'or' \| 'and'` toggle. | `operator: 'or'` disjunctive facet counts **require multiple queries under the hood** (see Algolia docs — the engine computes them client-framework-side, not backend-side). This is the same tradeoff Meilisearch explicitly flagged in Discussion #187: disjunctive counts are a multi-query pattern. | The LiveView guide ships **RefinementList + RangeSlider + CurrentRefinements + ClearRefinements** as the four core patterns. Disjunctive counts are taught as "run a second query to get the 'other values' distribution" — honest about the tradeoff, not a new API. |

**Cross-lib verdict:** the strongest declarative faceting pattern is algoliasearch-rails's `attributesForFaceting` (schema-level declaration, atom-listable) combined with Typesense's structured-buckets-with-ordering return shape, with Searchkick's smart-aggs-default (active-filter-refined counts) as the runtime default. Scrypath wins by combining all three while staying Ecto-idiomatic — atom keys, sub-struct returns, compile-time validated membership in `filterable:`.

---

## Design Decisions

### Question 1 — Declaration Site and Shape

**Options considered:**

1. **Schema-only** declaration (`faceting: [...]` in `use Scrypath`), runtime `search/3` takes only `facets: [...]` to **select which of the declared** to return.
2. **Runtime-only** declaration (like Searchkick `aggs`), facets passed per-query with no schema contract.
3. **Both** — declare shape at schema level AND allow runtime override for ad-hoc fields.

**Tradeoffs:**
- Schema-only matches Scrypath's existing `filterable:` / `sortable:` / `settings:` pattern one-for-one. Makes facets a **metadata-reflected** concept, which is the pattern `__scrypath__/1` is built for. Compile-time errors when a facet attribute isn't `filterable`. Zero runtime-discovery footguns.
- Runtime-only (Searchkick) gains ad-hoc flexibility but trades away compile-time guarantees and the ability to auto-derive `filterableAttributes` settings. Forces every facet request to re-specify field-level config (max_values, sort_order). Heavy at the call site.
- Both is seductive but is the Typesense trap (schema says `facet: true` AND query says `facet_by: field_name`): users forget one or the other. Scrypath's DSL pattern is strict: declare once, request by atom key.

**Chosen shape:**

```elixir
defmodule MyApp.Media.Movie do
  use Scrypath,
    fields: [:id, :title, :genre, :year, :rating, :director],
    filterable: [:genre, :year, :rating, :director],
    sortable: [:year, :rating],
    faceting: [
      attributes: [:genre, :year, :rating, :director],
      max_values_per_facet: 100,
      sort_facet_values_by: %{genre: :count, "*" => :alpha}
    ]
end
```

Runtime selection via narrow kwarg:

```elixir
Scrypath.search(Movie, "heist",
  facets: [:genre, :year],                       # which declared facets to return
  facet_filter: [genre: ["drama"]],              # which facet filters to apply
  filter: [rating: [gte: 7.0]]                   # existing Ecto-shaped filter, unchanged
)
```

**Why:** Declarative-in-schema is idiomatic Elixir/Ecto (Ecto's own `schema "..." do ... end` block is the exact pattern). Reflection via `__scrypath__(:faceting)` follows the established v1.0+ contract. Runtime `facets:` as a narrow selector (subset of declared) is the smallest runtime surface that covers the "one request fetches counts for some of the declared facets" case without reopening shape decisions per call.

**Reference lib that does it best:** **algoliasearch-rails** — `attributesForFaceting [:company, :zip_code]` inside the `algoliasearch do ... end` block is the exact pattern Scrypath's `faceting:` in `use Scrypath` mirrors.

**Reference lib that does it worst:** **Typesense** — requires `facet: true` in schema AND `facet_by: "field"` at query time, with inconsistent auto-inference (GitHub issue #534). Two places to remember for every facet.

**Recommendation: schema-declarative-primary, with a narrow runtime `facets: [...]` selector kwarg that MUST be a subset of declared. Runtime-only facets are NOT permitted on the common path — users wanting ad-hoc faceting drop into `Scrypath.Meilisearch.*`.**

**Constrains v1.3 phase plan:** Phase 20 plan must extend `@schema_options` in `lib/scrypath/options.ex` with a `faceting:` key (NimbleOptions `:keyword_list` with nested `attributes: :list_of_atoms`, `max_values_per_facet: :pos_integer`, `sort_facet_values_by: :map`), add `__scrypath__(:faceting)` clause in `lib/scrypath/schema.ex`, and add `schema_faceting/1` helper on `Scrypath`. Subset validation lives in `validate_search_options!/2`.

---

### Question 2 — Facet Filter Grammar

**Options considered:**

1. **Disjunctive within field** (`facet_filter: [genre: ["fiction", "horror"]]` → OR within `genre`, AND across fields).
2. **Single-value only** (`facet_filter: [genre: "fiction"]` — forces multiple queries for multi-select).
3. **Full boolean expression tree** (`facet_filter: {:or, [genre: "fiction"], {:and, [year: 2024, rating: [gte: 7]]}}`).
4. **Meilisearch-native string DSL** (`"genre = 'fiction' AND year > 2020"`).

**Tradeoffs:**
- **Disjunctive-within-field** is the UX pattern every facet UI expects. RefinementList widgets in every instantsearch ecosystem assume OR-within-field. Meilisearch's array-of-arrays filter syntax (`[["genre = fiction", "genre = horror"], ["year = 2024"]]`) maps cleanly: inner array = OR, outer array = AND. This is the **minimum widening** that unlocks the common facet UX.
- **Single-value only** forces N-queries-per-multi-select. Scrypath becomes the slow thing. Rejected.
- **Full boolean expression tree** reopens the filter-grammar boundary v1.2 deliberately closed. Creates a second grammar to maintain, a second validator, a second set of failure modes. The common-path filter validator already rejects `:or`/`:and`/`:not` composition (`options.ex:462-464`) for this exact reason. Rejected.
- **Raw Meilisearch string DSL** leaks backend-native syntax onto the common path, violating the `Scrypath.Meilisearch.*` escape-hatch contract. Rejected — remains available under the namespaced escape hatch.

**Chosen grammar:**

```elixir
facet_filter: [
  genre: ["fiction", "horror"],      # OR within genre
  year: [2024, 2025],                # OR within year
  rating: [gte: 7.0]                 # numeric range reuses filter operator keyword list
]
# Meaning: (genre=fiction OR genre=horror) AND (year=2024 OR year=2025) AND (rating >= 7.0)
```

Single value is shorthand: `facet_filter: [genre: "fiction"]` ≡ `facet_filter: [genre: ["fiction"]]`.

**Validation rules:**
1. Keys must appear in `schema.__scrypath__(:faceting).attributes`.
2. Values are either `[value]` (single), `[v1, v2, ...]` (OR list), or `[operator: operand]` keyword list (numeric range, reusing the existing `:eq | :gt | :gte | :lt | :lte` allowlist from `options.ex:480`).
3. **Explicitly rejected:** `:or`/`:and`/`:not` top-level composition (`[or: [...]]`), raw Meilisearch strings, nested keyword lists across different fields.
4. `facet_filter:` and `filter:` are **composable** — they AND together at the Meilisearch payload level. Rationale: `filter:` stays as the narrow common filter (existing contract preserved); `facet_filter:` is the new sibling that handles disjunctive multi-select. Users can use both.

**Why:** This is exactly the grammar Searchkick's `smart_aggs` produces under the hood, what InstantSearch RefinementList-with-`operator: 'or'` produces, and what Meilisearch's array-of-arrays accepts. Narrow enough to not reopen boolean composition; wide enough to cover every single-field multi-select facet UI.

**How the reference libs grammar their facet filters:**
- **Searchkick**: `where: { genre: ["fiction", "horror"] }` → array value means OR-within-field. Identical semantics to chosen grammar.
- **algoliasearch-rails / InstantSearch**: `facetFilters: [["genre:fiction", "genre:horror"], ["year:2024"]]` — array-of-arrays, OR/AND pattern. Identical semantics.
- **Typesense**: `filter_by: "genre:=[fiction,horror] && year:=2024"` — inline DSL string. Where it hurt: field names with spaces/parentheses break (issue #1412); users have to escape values manually; code reading across filter/facet_filter is confusing.
- **Laravel Scout + Meilisearch**: users drop into a callback and write raw Meilisearch filter strings — every team reinvents the shape, validation is bypassed. Hurt point: every Scout+Meilisearch tutorial teaches Meilisearch filter DSL as if it were Laravel DSL.

**Reference lib that does it best:** **Searchkick** — `where: { field: [values] }` is atom-key-array-value, Ruby-idiomatic, narrow, no boolean composition needed for facet UIs.

**Reference lib that does it worst:** **Typesense** — inline DSL string (`filter_by: "genre:=[foo,bar] && year:>2020"`) suffers from every string-embedded DSL pain: escape bugs, whitespace bugs, auto-complete hostility, type-check hostility.

**Recommendation: disjunctive-within-field, AND across fields, NO boolean composition on the common path. Sibling kwarg `facet_filter:` with its own validator — do NOT widen `filter:`. Raw Meilisearch filter strings remain under `Scrypath.Meilisearch.*`.**

**Constrains v1.3 phase plan:** Phase 20 plan must add `facet_filter` to `@search_options` in `lib/scrypath/options.ex` with a new `validate_search_facet_filter/1` private validator that (a) accepts keyword list, (b) normalizes single-value to list-of-one, (c) delegates numeric range operators to the existing `validate_filter_value!` allowlist, and (d) delegates field-is-declared check against `__scrypath__(:faceting).attributes` (not `__scrypath__(:filterable)` — declaration-strictness guarantees `attributes ⊆ filterable`). Translation to Meilisearch array-of-arrays lives in a new private `translate_facet_filter/1` in `lib/scrypath/meilisearch/query.ex`, composed INTO the existing `translate_filter/1` output via array concatenation at the `[filter: [...]]` payload key.

---

### Question 3 — Facet Distribution Return Shape

**Options considered:**

1. **Meilisearch-raw flat map** (`%{"genre" => %{"fiction" => 42, "horror" => 13}}`).
2. **Nested per-facet with stats** (`%{genre: %{values: [...], stats: %{}}}`).
3. **Ordered list preserving declaration order** (`[{:genre, [...]}, {:year, [...]}]`).
4. **Sub-struct with ordered buckets + stats** (`%SearchResult.Facets{distribution: %{atom => [%Bucket{value, count}]}, stats: %{atom => %{min, max}}, declared_order: [:genre, :year]}`).

**Tradeoffs:**
- **Raw flat map (option 1):** Zero translation work; string-keyed. Kills pattern-matching ergonomics (`result.facets["genre"]["fiction"]` — strings forever). Leaks Meilisearch's field-rename history onto the public contract (see PITFALLS P7). Rejected.
- **Nested-with-stats map (option 2):** Atom-keyed, separates distribution from stats. But unordered (maps have no insertion order in Elixir), and rendering in LiveView almost always wants ordering — either declaration order or count-descending. Users end up `|> Enum.sort_by(...)` every render.
- **Ordered list of tuples (option 3):** Preserves declaration order, iteration-friendly. But loses direct lookup by field (`.facets.genre` becomes `Enum.find(.facets, fn {:genre, _} -> true end)`). Hostile to pattern matching.
- **Sub-struct with maps + ordered list (option 4):** Best of all worlds. Atom-keyed maps for pattern matching. Ordered list for iteration. Sub-struct insulates from Meilisearch field-rename history. `%Bucket{value, count}` gives LiveView templates a typed struct to iterate.

**Chosen shape:**

```elixir
defmodule Scrypath.SearchResult.Facets do
  @moduledoc """
  Faceted-search distribution and stats for a `Scrypath.SearchResult{}`.

  - `distribution` — map of declared facet atom to ordered list of `%Bucket{}`.
    Buckets are sorted according to the schema's `sort_facet_values_by` setting
    (defaulting to count-descending) and truncated to `max_values_per_facet`.
  - `stats` — map of declared numeric facet atom to `%{min: number, max: number}`.
    Present only for numeric facets with at least one matching hit.
  - `declared_order` — list of atoms matching the schema's declaration order,
    for LiveView templates that iterate in a stable order.
  """
  @enforce_keys [:distribution, :stats, :declared_order]
  defstruct [:distribution, :stats, :declared_order]

  @type t :: %__MODULE__{
          distribution: %{atom() => [Scrypath.SearchResult.Facets.Bucket.t()]},
          stats: %{atom() => %{min: number(), max: number()}},
          declared_order: [atom()]
        }
end

defmodule Scrypath.SearchResult.Facets.Bucket do
  @enforce_keys [:value, :count]
  defstruct [:value, :count]

  @type t :: %__MODULE__{value: String.t() | number() | boolean(), count: non_neg_integer()}
end
```

Integrated into `SearchResult`:

```elixir
@enforce_keys [:query, :hits, :records, :raw, :missing_ids, :page]
defstruct [:query, :hits, :records, :raw, :missing_ids, :page, facets: nil]
# facets: %Scrypath.SearchResult.Facets{} | nil (nil when caller did not request facets)
```

**LiveView template ergonomics:**

```heex
<%= for facet <- @search.facets.declared_order do %>
  <section class="facet" id={"facet-#{facet}"}>
    <h4><%= humanize(facet) %></h4>
    <ul>
      <%= for %Bucket{value: value, count: count} <- @search.facets.distribution[facet] do %>
        <li>
          <label>
            <input type="checkbox" name={"filter[#{facet}][]"} value={value}
                   checked={value in Map.get(@active_filters, facet, [])} />
            <%= value %> <span class="count">(<%= count %>)</span>
          </label>
        </li>
      <% end %>
    </ul>
  </section>
<% end %>
```

Iteration order preserved (declared_order). Pattern matching clean. Atom keys throughout.

**How consumers actually USE facet distributions (observed from surveyed UI libs + InstantSearch docs):**
1. **Counts under active filters** (refined counts) — "X matches now that I've selected genre=fiction and year=2024". Renders as "(count)" next to each checkbox. THIS IS THE DEFAULT.
2. **Top-N ordered by count-desc for categorical facets** — "Top 10 genres" in a collapsible sidebar. `max_values_per_facet: 100` in schema + client-side top-N slice.
3. **Full alphabetical list for dense facets** — "All directors" with a search-within-facet box. Requires `sort_facet_values_by: %{"*" => :alpha}`.
4. **Range affordance from stats** — "Rating between [slider: min-max]" driven by `stats.rating.min` / `stats.rating.max`. Numeric-only.

All four are covered by the chosen shape. `distribution` handles (1), (2), (3); `stats` handles (4); `declared_order` handles stable-iteration in templates.

**Reference lib that does it best:** **Typesense** — returns `facet_counts: [{field_name: "genre", counts: [{value, count, highlighted}], stats: {...}}]` — structured, ordered, typed per field. Scrypath's shape is this pattern expressed in Elixir-idiomatic structs with atom keys.

**Reference lib that does it worst:** **algoliasearch-rails** — string-keyed `hits.facets["company"]` leaks JSON into Ruby. Pattern matching is painful forever.

**Recommendation: ship the `%Scrypath.SearchResult.Facets{}` sub-struct with `%Bucket{}` ordered-list values, atom keys, separate `stats` map, and `declared_order` list. NOT a flat map. NOT a plain keyword list.**

**Constrains v1.3 phase plan:** Phase 20 plan creates two new modules — `lib/scrypath/search_result/facets.ex` and `lib/scrypath/search_result/facets/bucket.ex`. `SearchResult.new/4` gains a private `facets(raw, query)` helper mirroring the existing `page(raw)` pattern that (a) returns `nil` when `query.facets == []`, (b) extracts `facetDistribution` and `facetStats` from `raw`, (c) atomizes keys against the declared list (NEVER against arbitrary response keys — prevents atom-exhaustion attack), (d) sorts and truncates buckets per schema `sort_facet_values_by` / `max_values_per_facet`, (e) builds `declared_order` from the intersection of requested `facets:` and declared `faceting.attributes` preserving declared order.

---

### Question 4 — Active vs Refined Facet Counts

**Options considered:**

1. **Refined counts** (counts computed against the filter-narrowed result set) — Meilisearch's native behavior when you pass `facets: [...]` alongside `filter: [...]`.
2. **Unrefined / disjunctive counts** (counts for a given facet computed against the unfiltered-FOR-THAT-FACET result set, so "other values" remain visible as users narrow).
3. **Both, via per-facet opt-in** (`facet_filter: [genre: {"fiction", unrefined: true}]`).

**Tradeoffs:**
- **Refined (default)** is Meilisearch-native, what Searchkick's `smart_aggs` defaults to, what the majority of e-commerce and content-discovery UIs ship. Counts collapse as users narrow. "(42)" next to "horror" reflects reality. Truthful.
- **Unrefined (Amazon-style)** keeps "other values available" visible: selecting `genre=fiction` still shows `horror (13)` next to its checkbox, telling the user "13 other results await if you switch". Requires **one extra query per disjunctive facet** (per Meilisearch Discussion #187 — there is no single-query native disjunctive count). Per-facet re-query cost scales linearly with number of disjunctive facets selected. Algolia computes these **client-side in InstantSearch** by issuing multiple queries — it is not a backend primitive.
- **Both via opt-in** is a maintenance trap: two semantics in one kwarg, doubled validation, doubled test surface, unclear when each applies. Rejected — FEATURES.md already lists disjunctive counts as a deferred anti-feature.

**What Phoenix/Ecto devs idiomatically expect:**
- Phoenix devs who came from Searchkick: refined counts by default (matches `smart_aggs` default since 2015).
- Phoenix devs who came from Algolia/InstantSearch: aware that RefinementList's `operator: 'or'` does multi-query disjunctive behind the scenes; accept that this is a client-framework concern, not a backend kwarg.
- Phoenix devs who came from raw Meilisearch: already see refined counts in their Kibana-equivalent; flagging unrefined as the default would surprise them.

Refined is the idiomatic expectation. Unrefined is a specialized product UX (Amazon-scale comparison shopping) that is NOT what growth-stage Phoenix SaaS needs out of the box.

**Chosen behavior:**

Scrypath v1.3 ships **refined counts only**. `facet_filter:` narrows the result set; `facets: [...]` returns counts against that narrowed set. This is Meilisearch-native — zero server-side complexity beyond what Meilisearch already provides.

For teams that need unrefined/disjunctive behavior, the LiveView guide ships a recipe using `Scrypath.search_many/2` (Phase 21 / D in the roadmap):

```elixir
# Recipe pattern in guide — teams opt into multi-query for disjunctive behavior
Scrypath.search_many([
  {Movie, text: q, facet_filter: [genre: @selected_genres, year: @selected_years],
                   facets: [:rating, :director]},          # refined counts for other facets
  {Movie, text: q, facet_filter: [year: @selected_years],  # drop genre filter
                   facets: [:genre]},                      # unrefined counts for genre
  {Movie, text: q, facet_filter: [genre: @selected_genres],# drop year filter
                   facets: [:year]}                        # unrefined counts for year
])
```

This is **honest about the cost** (3 queries), **reuses existing APIs** (no new kwargs), and **matches Algolia InstantSearch's under-the-hood pattern**.

**Reference lib that does it best:** **Searchkick** — `smart_aggs` default is refined; users opt out with `smart_aggs(false)` per-query. Clean mental model.

**Reference lib that does it worst:** **Algolia InstantSearch** — `operator: 'or'` in RefinementList silently fires multiple backend queries; users don't realize until their Algolia bill explodes or p95 regresses. The hidden-multi-query cost is the footgun.

**Recommendation: ship refined-counts-only in v1.3. Unrefined-counts behavior is a LiveView guide recipe using `Scrypath.search_many/2`, NOT a new kwarg.**

**Constrains v1.3 phase plan:** Phase 20 plan does NOT add an `unrefined:` kwarg to `facet_filter:` or `facets:`. The LiveView guide (Phase 20 deliverable) includes a "Showing other values available" recipe section using `Scrypath.search_many/2` (which lands in Phase D of the roadmap — ensure phase ordering puts Phase D before or at the LiveView guide draft, or defer that recipe to a v1.3 guide patch after D lands).

---

### Question 5 — Compile-Time Validation Depth

**Options considered:**

1. **Strict**: every attribute in `faceting.attributes` MUST also appear in `filterable:`. Compile error otherwise.
2. **Auto-expand**: declaring a field in `faceting.attributes` automatically adds it to the derived `filterableAttributes` Meilisearch setting without requiring explicit `filterable:` declaration.
3. **Permissive**: accept any atom; let Meilisearch reject at query time if not filterable.

**Tradeoffs:**
- **Strict (option 1):** Explicit. Users see the relationship (facet implies filterable) once in the error message and keep it forever. Matches Typesense's per-field explicit declaration (`facet: true` requires the field exist in schema). Matches algoliasearch-rails's compile-time validation that `attributesForFaceting` refers to declared attributes.
- **Auto-expand (option 2):** Convenient but conflates two cost decisions: "is this filterable" (affects index size + query planner) vs "is this a facet" (affects response payload size + distribution compute). PITFALLS P10 and FEATURES anti-features both warn against this — it hides the cost of adding `filterableAttributes` to Meilisearch's internal structure. Rejected.
- **Permissive (option 3):** Meilisearch-runtime-error feels embarrassingly late. Would require every CI to hit Meilisearch to catch typos. Rejected.

**How reference libs enforce this:**
- **Typesense:** strict — field must have `facet: true` in collection schema; attempting to `facet_by` on a non-faceted field returns HTTP 400. Enforced server-side, caught at query time, not compile time.
- **algoliasearch-rails:** loose — `attributesForFaceting` accepts any attribute name string; Algolia server rejects at indexing time if unknown. Users catch via failed indexing jobs, not compile.
- **Searchkick:** no declaration — fully runtime; `aggs(:any_field)` attempts aggregation; ES returns error if field wasn't indexed.
- **Chewy:** field must be declared in index type; reasonably strict.

Scrypath can do **strictly better than any of them** by enforcing at `use Scrypath` compile time. `filterable:` is already required for `filter:` to work; making `faceting.attributes ⊆ filterable` is a two-line MapSet subset check in `validate_schema_options!/1`.

**Chosen rule:**

```elixir
# In Scrypath.Options.validate_schema_options!/1 post-validate step:
defp validate_faceting_attributes_are_filterable!(opts) do
  faceting = Keyword.get(opts, :faceting, []) |> Keyword.get(:attributes, [])
  filterable = Keyword.get(opts, :filterable, [])

  case Enum.reject(faceting, &(&1 in filterable)) do
    [] -> opts
    missing ->
      raise ArgumentError,
        "faceting.attributes #{inspect(missing)} must also appear in filterable: #{inspect(filterable)}. " <>
        "Meilisearch requires facet attributes to be filterable. Add them to filterable: or remove from faceting.attributes."
  end
end
```

Runs at **compile time** (`use Scrypath` triggers `validate_schema_options!/1`). Error message is Elixir-idiomatic (names both lists, says what to do).

**Why strict and not auto-expand:** v1.2 locked the principle "no hidden runtime behavior" (ARCHITECTURE.md, README Public Surface section). Auto-expanding violates it — declaring a facet silently mutates what gets sent as `filterableAttributes`. Strict check makes the relationship explicit once, forever.

**Reference lib that does it best:** **Typesense** — per-field `facet: true` in schema is the strictest available; Scrypath goes one better by catching at compile time rather than first query.

**Reference lib that does it worst:** **Searchkick** — no declaration at all; typos discoverable only via ES error on query. Footgun for every new team member.

**Recommendation: STRICT compile-time rule — `faceting.attributes ⊆ filterable` or compile error. Do NOT auto-expand.**

**Constrains v1.3 phase plan:** Phase 20 plan adds `validate_faceting_attributes_are_filterable!/1` to `Scrypath.Options` as a post-NimbleOptions-validation step, called from `validate_schema_options!/1`. This affects `lib/scrypath/options.ex` only. Test: compile a fixture schema with `faceting: [attributes: [:genre]]` and `filterable: []` — it must raise `ArgumentError` with a specific message.

---

### Question 6 — Phoenix LiveView Guide Shape

**Worked example domain:** Movies by genre × year × rating. This domain is chosen because:
- It has **one categorical facet** (`genre` — ~20 values, checkbox list), **one ordered categorical facet** (`year` — could be checkbox or dropdown), and **one numeric facet** (`rating` — range slider using `facet_stats`). Covers all three facet UI patterns in one example.
- It's **instantly familiar** — every Phoenix dev has rented a movie. No domain-knowledge-tax.
- It maps cleanly to an Ecto schema with 5 fields. No association gymnastics.

**Smallest full app shape:**

```elixir
defmodule Demo.Media.Movie do
  use Ecto.Schema

  use Scrypath,
    fields: [:id, :title, :genre, :year, :rating, :director],
    filterable: [:genre, :year, :rating, :director],
    sortable: [:year, :rating, :title],
    faceting: [
      attributes: [:genre, :year, :rating, :director],
      max_values_per_facet: 50,
      sort_facet_values_by: %{"*" => :count}
    ]

  schema "movies" do
    field :title, :string
    field :genre, :string
    field :year, :integer
    field :rating, :float
    field :director, :string
    timestamps()
  end
end
```

**UI patterns the guide shows (as the canonical four):**

1. **Sidebar checkbox list (RefinementList)** — for `genre` and `director`. Each checkbox shows `"<value> (<count>)"`. Active selections are checked; URL-synced via `push_patch/2`.
2. **Year chip row** — for `year`. Top-N (e.g., 10) years as chips, clickable to toggle. Chip shows `"<year> ×"` when selected, `"<year> (<count>)"` when not.
3. **Numeric range slider** — for `rating`. Min/max bounds come from `result.facets.stats.rating` (`{min: 1.0, max: 10.0}`). User-selected range becomes `facet_filter: [rating: [gte: lo, lte: hi]]`.
4. **Current refinements chip row** (CurrentRefinements) — above the result list, shows every active `facet_filter:` as a removable chip. Removing a chip pushes a URL without that filter.

**URL-sync shape (the thing users actually care about):**

```
/movies?q=heist&genre[]=drama&genre[]=thriller&year[]=2024&rating_min=7.5
```

LiveView's `handle_params/3` parses this into the kwarg shape Scrypath expects:

```elixir
def handle_params(params, _uri, socket) do
  opts = build_search_opts(params)
  {:ok, result} = Demo.Media.search_movies(params["q"] || "", opts)

  {:noreply,
   socket
   |> assign(:result, result)
   |> assign(:active_filters, parse_active_filters(params))
   |> assign(:query, params["q"] || "")}
end

defp build_search_opts(params) do
  facet_filter =
    []
    |> maybe_add(:genre, params["genre"])
    |> maybe_add(:year, params["year"] |> cast_year_list())
    |> maybe_add_range(:rating, params["rating_min"], params["rating_max"])

  [facets: [:genre, :year, :rating, :director], facet_filter: facet_filter]
end
```

Context module owns repo + Scrypath orchestration (unchanged pattern from existing `guides/phoenix-liveview.md`):

```elixir
defmodule Demo.Media do
  alias Demo.{Media.Movie, Repo}

  def search_movies(query, opts \\ []) do
    Scrypath.search(Movie, query,
      Keyword.merge([backend: Scrypath.Meilisearch, repo: Repo], opts)
    )
  end
end
```

**Anti-patterns the guide explicitly names and warns against:**

| Anti-Pattern | Why It's Wrong | What to Do Instead |
|---|---|---|
| Hierarchical menu for `genre > subgenre` | Meilisearch does not ship a first-class hierarchical facet primitive. The `category.lvl0 / lvl1 / lvl2` projection convention works, but is not a Scrypath-native feature. Guide shows it as a convention, not a DSL. | Project hierarchy as flat `level_0`/`level_1` fields; declare each as a facet; render with indentation in the template. |
| Infinite "show more" with facet refetching | Refetching on "show more" fires an extra query per click, even though `max_values_per_facet: 100` would have returned enough. Users think Scrypath is slow. | Request enough buckets up front via `max_values_per_facet`; slice client-side for "top N / show all" behavior. |
| Auto-apply on every checkbox click without debouncing | Fires N queries as the user clicks through a list; p95 regresses visibly under load. | `phx-change` with a 100ms debounce OR "Apply" button for multi-select panels. |
| Syncing filter state to LiveView assigns WITHOUT URL | Refreshing the page loses the user's filter state. Silent feature regression. | Every filter change goes through `push_patch/2` so the URL is the source of truth; `handle_params/3` restores state on remount. |
| Showing active-filter chips that can't be removed | Dead-end UX; users think they're stuck. | CurrentRefinements chip row with `×` remove icon per chip; clicking issues `push_patch/2` with that filter dropped. |
| Disjunctive counts via a new kwarg | Locks Scrypath into a semantics tax forever. See Question 4. | Run `Scrypath.search_many/2` with N+1 queries as the opt-in pattern for "other values available". |
| Pretending `sync_mode: :inline` after facet filter change makes the index up-to-date | Conflates search read-side with sync write-side. Facet filtering reads existing state; it doesn't change sync guarantees. | Facet state changes don't interact with sync — reiterate the existing "accepted != visible" wording. |

**Reference lib that does it best (for UI patterns):** **react-instantsearch** — the RefinementList + RangeSlider + CurrentRefinements + ClearRefinements widget set is the clearest mental model. The LiveView guide names these four patterns in those terms so cross-framework users recognize them instantly.

**Reference lib that does it worst:** **Laravel Scout docs** — no guidance at all; drops users into a callback and leaves them to figure it out. Symptomatic of Scout's deliberate thinness, but anti-DX for the 90% case.

**Recommendation: the LiveView guide ships a worked "movies by genre × year × rating" example showing the four canonical UI patterns (sidebar checkboxes, chip row, range slider, current-refinements chip row), URL-synced via `push_patch/2`, context-module-owned orchestration, and an explicit anti-patterns section naming the seven anti-patterns above.**

**Constrains v1.3 phase plan:** Phase 20 plan includes a `guides/phoenix-liveview-faceted-search.md` deliverable (or extended section in `guides/phoenix-liveview.md`) with the movies example, runnable `heex` snippets, URL-sync shape, and anti-patterns table. `Demo.Media.Movie` schema lives as a documented snippet only — the guide doesn't ship a full example app directory (keep it a focused guide, not a demo app). If the roadmapper wants a runnable demo, it's a separate v1.4-era artifact.

---

### Question 7 — Facet Stats (Numeric Min/Max/Avg)

**Options considered:**

1. **Default-on**: Meilisearch automatically returns `facetStats` for any numeric field in `facets: [...]`; Scrypath surfaces them on `result.facets.stats` without asking.
2. **Opt-in via kwarg**: `facet_stats: [:rating]` explicitly requests stats for a subset.
3. **Project only when asked at declaration time**: `faceting: [attributes: [rating: :numeric]]` tags numeric facets; only those get stats.

**Tradeoffs:**
- **Default-on (option 1):** Meilisearch already computes and returns `facetStats` whenever you request a facet on a numeric field — **no extra server compute, no extra payload cost beyond a few bytes per numeric facet**. The work is done regardless of whether Scrypath exposes it. Not exposing it means users have to reach into `raw` to get what Meilisearch already sent. DX cost of opt-in: users discover `facet_stats` exists only after reading docs.
- **Opt-in via kwarg (option 2):** Explicit but redundant — Meilisearch doesn't offer a "don't send stats" flag. Adding a Scrypath-side `facet_stats: [...]` kwarg that filters the already-returned stats is busywork without payload savings.
- **Project only when asked at declaration time (option 3):** Forces users to tag fields as `:numeric` at the schema DSL level. Adds a second kind of facet (categorical vs numeric). Adds cognitive overhead. Rejected — Meilisearch already types at the field level.

**Meilisearch behavior (verified via [Discussion #117](https://github.com/orgs/meilisearch/discussions/117) and [Issue #4677](https://github.com/meilisearch/meilisearch/issues/4677)):**
- `facetStats` auto-appears for numeric fields whenever `facets: [...]` is requested.
- Only numeric values contribute (string "21" is ignored).
- If no hits have numeric values for a given facet, that facet's stats entry is absent.
- Only `min` and `max` are returned — **no `avg`, no percentiles, no histograms** (verified against specs).

Scrypath **cannot offer `avg` / percentiles** without additional queries (they're not in the native response). So the surface is exactly `%{atom => %{min: number, max: number}}`.

**Chosen behavior:**

**Default-on.** Whenever a caller passes `facets: [...]` and any of those facets is a numeric field, Scrypath populates `result.facets.stats` with `%{facet_atom => %{min: number, max: number}}` entries. No new kwarg. No opt-in. The data is already in the response.

Type inference for numeric: read the Ecto schema's field type. `:integer`, `:float`, `:decimal`, `:utc_datetime_usec` (castable to numeric) get stats entries if Meilisearch returns them. `:string`, `:boolean`, `Ecto.Enum` do not. This is done lazily — `SearchResult.new/4` reads `facetStats` keys from raw response and atomizes them against `schema.__scrypath__(:faceting).attributes`, not against arbitrary response keys (atom-exhaustion safety).

**DX win:** users who want a range slider get `result.facets.stats.rating` without a second API call or a second kwarg. Example:

```heex
<% stats = @result.facets.stats[:rating] %>
<%= if stats do %>
  <input type="range" name="rating_min" min={stats.min} max={stats.max}
         value={@active_filters[:rating][:gte] || stats.min} step="0.1" />
  <input type="range" name="rating_max" min={stats.min} max={stats.max}
         value={@active_filters[:rating][:lte] || stats.max} step="0.1" />
<% end %>
```

**Known gotcha to document:** Meilisearch Issue #4677 reports that `distinctAttribute` interacts with `facetStats` (and `facetDistribution`) — stats can be computed pre-dedup and then counts feel inconsistent. The relevance-tuning guide (Phase B) will document this where `distinct_attribute:` lives; the faceting guide cross-references.

**Reference lib that does it best:** **Typesense** — returns stats inline in `facet_counts[].stats` for numeric fields by default. Scrypath's default-on matches this.

**Reference lib that does it worst:** **Searchkick** — requires explicit `stats` aggregation request (`aggs: { rating: { stats: {} } }`). Redundant cognitive load for what ES already computes.

**Recommendation: default-on. Populate `result.facets.stats` automatically for numeric facets in the requested `facets:` list. NO opt-in kwarg. NO declaration-time `:numeric` tag.**

**Constrains v1.3 phase plan:** Phase 20 plan's `facets/2` helper in `SearchResult` reads both `facetDistribution` and `facetStats` from raw Meilisearch response. Atomize stats keys strictly against `schema.__scrypath__(:faceting).attributes`. Guide-level cross-reference to Phase B's `distinct_attribute:` interaction with facetStats.

---

### Question 8 — Coherence Check with Other v1.3 Categories

#### Interaction with relevance tuning (Phase B / 18)

**Synergy:**
- Relevance tuning extends `settings:` schema key with structured subkeys (`synonyms`, `typo_tolerance`, `ranking_rules`, `distinct_attribute`, `stop_words`). Facets extend `filterable:` (compile-time subset check) and add `faceting:` as a parallel first-class key. Both are schema-level metadata, both flow through `__scrypath__/1`, both apply via the managed reindex pipeline. **Same architectural pattern, different keys.**
- The snake_case → camelCase translation layer added in Phase 18 (`Scrypath.Meilisearch.Settings.translate_settings/1`) is the exact pattern Phase 20 extends: `Scrypath.Meilisearch.Query.translate_facet_filter/1` and `translate_facets/1` live in the same namespace, follow the same contract (Scrypath atom-keyed input → Meilisearch JSON output), use the same `format_value/1` for leaf values.

**Collision risk:**
- `distinct_attribute:` (Phase 18 relevance) affects `facetStats` and `facetDistribution` accuracy (Meilisearch Issue #4677). The faceting guide MUST cross-reference distinct's impact on facet counts, and the relevance-tuning guide MUST cross-reference the same. Failing to document this link = silent user confusion when counts don't match filtered hit totals.
- If a user declares both `faceting: [attributes: [:genre]]` and `settings: [distinct_attribute: :series_id]`, counts for `genre` are computed **before** dedup by `series_id`, then dedup runs, leaving hit count lower than `sum(counts)`. Document as a known interaction, not a bug.

**Phase ordering implication:** Phase B (relevance) before Phase C (faceting) — SUMMARY.md's recommended order is correct. Faceting reuses the translation pattern Phase B establishes.

#### Interaction with multi-index search (Phase D / 20 in roadmap)

**Synergy:**
- `%Scrypath.SearchResult.Facets{}` is a per-schema concept; `search_many/2` returns `%{schema => %SearchResult{}}` grouped. Each schema's `%SearchResult{}` carries its own `.facets` field populated against that schema's declared `faceting.attributes`. **Zero multi-index-specific facet logic needed.**
- Meilisearch's `/multi-search` response includes per-query `facetDistribution` / `facetStats` in each sub-response. Scrypath's per-schema `SearchResult.new/4` handles extraction identically to single-query search. No new code path.

**Collision risk:**
- `/multi-search` `federation` mode supports `mergeFacets: true` to combine facets across sibling indexes. This is Meilisearch-native power that lives **under `Scrypath.Meilisearch.*`**, NOT on the common `search_many/2` surface. Exposing `mergeFacets` as a common-path kwarg would open the cross-schema-joined-facet semantics question (what does it mean to merge `MyApp.Post.genre` with `MyApp.Comment.tag`?) — ambiguous, schema-shape-dependent, not what users actually want. **Non-goal tripwire: do NOT expose `mergeFacets` on `Scrypath.search_many/2`. Users who need it drop into `Scrypath.Meilisearch.*`.**

**Phase ordering implication:** Phase D (multi-index) after Phase C (faceting). Phase D's per-schema result shape inherits Phase C's facets sub-struct with zero extra work.

#### Interaction with operator polish (Phase E / 21 — FailedWork enrichment)

**Synergy:** None — operator polish is orthogonal. FailedWork extension doesn't touch search read paths.

**Cross-reference in drift-recovery guide:**
- Reconcile flags **setting drift** (declared `settings:` vs. live index) and **facet drift** (declared `faceting:` vs. live `filterableAttributes`). Phase E's drift-recovery guide cross-references both.
- The drift recovery narrative includes a step: "if you declared a new `faceting:` attribute and facet queries return errors like `'attribute X is not filterable'`, run `Scrypath.reconcile_sync/2` — it will flag the drift — then `Scrypath.reindex/2` to apply."

**Coherence verdict:** **no architectural collisions, strong pattern reuse from Phase B, zero new complexity in Phase D, clean cross-reference in Phase E.** The four categories compose.

---

## Phoenix LiveView Guide — Worked Example Outline

**File:** `guides/phoenix-liveview-faceted-search.md` (or appended section in `guides/phoenix-liveview.md`)

**Voice:** Match existing `guides/phoenix-liveview.md` — concise, opinionated, context-boundary-explicit, no emojis, honest about tradeoffs.

**Structure (sections, in order):**

1. **What This Shows** — "Faceted movie search with genre checkboxes, year chips, rating range slider, URL-synced filters, and honest refined-count behavior."
2. **The Schema** — `Demo.Media.Movie` snippet with `faceting: [...]` declaration.
3. **The Context Module** — `Demo.Media.search_movies/2` wrapping `Scrypath.search/3` with `facets: [:genre, :year, :rating, :director]` as the default.
4. **The LiveView (`Demo.MediaWeb.MovieLive.Index`)** —
   - `mount/3` sets empty defaults.
   - `handle_params/3` parses URL params into `facet_filter:` shape, calls context, assigns `@result`, `@active_filters`, `@query`.
   - `handle_event("toggle_facet", ...)` / `handle_event("set_range", ...)` compute new params map, call `push_patch(socket, to: ~p"/movies?#{new_params}")`.
5. **The Template (`index.html.heex`)** — sidebar with RefinementList per facet, chip row for current refinements, result list, pagination.
6. **URL-Sync Shape** — canonical param shape: `?q=...&genre[]=drama&genre[]=thriller&year[]=2024&rating_min=7.5&rating_max=10`.
7. **Showing "Other Values Available" (Disjunctive Recipe)** — `Scrypath.search_many/2` pattern for teams who need it. Honest about the 3-query cost. Marked as "v1.3 advanced pattern".
8. **Anti-Patterns to Avoid** — the seven anti-patterns named in Question 6.
9. **Cross-References** — link to relevance-tuning guide for `distinct_attribute` interaction, operator mix tasks guide for drift detection, sync-modes guide for the read-vs-write distinction.

**Plain-English acceptance of the guide (for the downstream plan researcher):**

- A reader who has never used faceted search before can copy the schema + context + LiveView snippets verbatim and end up with a working movie-search UI.
- Every UI pattern named (checkboxes, chips, range slider, current refinements) has a runnable `heex` snippet in the guide.
- The disjunctive-recipe section is marked optional and explains the tradeoff in two sentences.
- The anti-patterns section calls out at least the seven listed in Question 6.
- The guide does NOT introduce any new Scrypath verb; every code example uses already-shipped `Scrypath.*` or `Phoenix.*` functions.

---

## Coherence With Other v1.3 Categories

**Relevance tuning (Phase B):** Facets and relevance tuning are parallel declarative-metadata extensions. Translation-layer pattern (snake_case Scrypath → camelCase Meilisearch) is established in Phase B and reused in Phase C. Known cross-impact: `distinct_attribute:` changes `facetDistribution` and `facetStats` — documented in both guides.

**Multi-index search (Phase D):** `search_many/2` returns `%{schema => %SearchResult{}}` grouped; each `SearchResult{}` carries its own `%Facets{}`. Zero multi-index-specific facet code. **Non-goal tripwire:** do NOT expose Meilisearch's `mergeFacets: true` federation mode on the common path — users who need cross-schema merged facets drop into `Scrypath.Meilisearch.*`.

**Operator polish (Phase E):** Orthogonal at the API level. Drift-recovery guide cross-references `reconcile_sync/2` flagging setting and facet drift. `Scrypath.reconcile_sync/2` extension to flag facet drift is a Phase 20 differentiator (P2 in FEATURES.md), not a Phase E concern.

**Release/tooling debt (Phase A + F):** No interaction beyond the release-parity gate ensuring `lib/scrypath/search_result/facets.ex` and `lib/scrypath/search_result/facets/bucket.ex` are on disk AND in the tarball AND in the published package.

**Phase-ordering constraint:** Phase 20 (faceting) depends on Phase 18 (relevance tuning) to establish the translation-layer pattern. Faceting may depend on Phase D (multi-index) for the disjunctive-recipe section of the LiveView guide; if Phase D slips, that section is deferred to a v1.3.1 guide patch.

---

## Non-Goal Tripwires

Things that would look like "natural extension" of faceting but violate locked non-goals:

| Tempting Addition | Why It Looks Natural | Why It's a Non-Goal | Disposition |
|---|---|---|---|
| Meilisearch `mergeFacets: true` federation mode on `search_many/2` | Logically, multi-index faceting should merge | Requires cross-schema field semantics to mean anything; non-goal "no breaking common-path widening" | Hard no on common path. Available under `Scrypath.Meilisearch.*` only. |
| Hierarchical facet DSL (`faceting: [attributes: [category: :hierarchical]]`) | Algolia/Typesense ship it | Meilisearch doesn't ship first-class hierarchical; baking in a Scrypath grammar traps us. FEATURES.md anti-feature list already flags this. | Hard no. Guide shows `level_0`/`level_1` projection convention instead. |
| Disjunctive facet counts as a new kwarg (`facets: [genre: :disjunctive]`) | Product teams ask for Amazon-style "other sizes available" | Multi-query pattern that Meilisearch doesn't natively support; baking it in as a kwarg hides the N-query cost. Question 4 analysis. | Hard no. Guide recipe using `search_many/2` is the opt-in. |
| Vector/hybrid facets tied to semantic-similarity buckets | Meilisearch 1.16+ ships multimodal embeddings | PROJECT.md non-goal: "no vector/hybrid/semantic search". | Hard no. Not v1.3, not v1.4 without adopter signal. |
| Facet-based dashboard surface (`mix scrypath.facets <schema>` enumerating distribution) | Operator polish makes it feel natural | PROJECT.md non-goal: "no dashboard product surface". | Hard no. Mix tasks stay thin delegates. |
| Second backend hook via `faceting:` (per-backend facet config) | Multi-backend seam is internal | PROJECT.md non-goal: "no second public backend". Adding per-backend facet shape widens it. | Hard no. Internal seam only. |
| Raw Meilisearch `facet_filter:` string (`facet_filter: "genre = 'fiction'"`) | Power users want the escape hatch | v1.2 locked the common-path filter grammar. Accepting raw strings reopens it. | Hard no on common path. Available under `Scrypath.Meilisearch.search/3`. |
| Auto-derive `faceting:` from `filterable:` (make every filterable field a facet by default) | One less keystroke | Conflates indexing cost decisions (PITFALLS P10). Silent response-payload bloat. | Hard no. Explicit declaration required. |
| Exposing `facetDistribution`/`facetStats` as camelCase top-level keys on `SearchResult` | "Easier" passthrough | Leaks backend-native shape; breaks on Meilisearch rename (`nbHits` precedent). PITFALLS P7. | Hard no. Sub-struct with atom keys; raw remains the escape hatch via `.raw`. |
| `Scrypath.apply_faceting!/2` hot-patch to live index | Nice operator ergonomics | Triggers Meilisearch internal rebuild; causes silent search downtime. PITFALLS P5 + P10. | Hard no. Facets flow through `Scrypath.reindex/2` only. |

---

## Proposed REQ-IDs

Each REQ has 2–4 acceptance criteria (AC-N). Downstream plan researcher should derive PLAN.md work items from these.

### FACET-01 — Declarative `faceting:` schema key

**Requirement:** `use Scrypath` accepts a `faceting:` key with `attributes: [atom()]`, `max_values_per_facet: pos_integer()`, and `sort_facet_values_by: %{atom() | binary() => :count | :alpha}` subkeys. Metadata is reflected through `__scrypath__(:faceting)` and the public helper `Scrypath.schema_faceting/1`.

- **AC-01a:** `use Scrypath, fields: [...], filterable: [:genre], faceting: [attributes: [:genre]]` compiles successfully and `Module.__scrypath__(:faceting)` returns a map matching the declaration.
- **AC-01b:** `faceting:` is validated through NimbleOptions in `Scrypath.Options.validate_schema_options!/1`; unknown subkeys raise `ArgumentError` at compile time.
- **AC-01c:** `Scrypath.schema_faceting/1` public helper mirrors `Scrypath.schema_filterable/1` and returns the normalized faceting map.
- **AC-01d:** When `faceting:` is omitted from `use Scrypath`, `__scrypath__(:faceting)` returns the default `%{attributes: [], max_values_per_facet: nil, sort_facet_values_by: %{}}`.

### FACET-02 — Compile-time enforcement: `faceting.attributes ⊆ filterable`

**Requirement:** Every atom in `faceting.attributes` must appear in `filterable:`. Violation raises `ArgumentError` at compile time with an Elixir-idiomatic message naming both lists.

- **AC-02a:** Compiling a schema with `faceting: [attributes: [:genre]]` and `filterable: [:year]` raises `ArgumentError` with message `"faceting.attributes [:genre] must also appear in filterable: [:year]..."`.
- **AC-02b:** Compiling a schema with `faceting: [attributes: [:genre, :year]]` and `filterable: [:genre, :year, :rating]` succeeds (faceting is a proper subset of filterable).
- **AC-02c:** The error message names the specific missing atoms and tells the user to either add to `filterable:` or remove from `faceting.attributes`.

### FACET-03 — `facets:` runtime kwarg on `Scrypath.search/3`

**Requirement:** `Scrypath.search/3` accepts `facets: [atom()]` — the list of declared facets to return distribution for. Must be a subset of `schema.__scrypath__(:faceting).attributes`; validation error otherwise.

- **AC-03a:** `Scrypath.search(Movie, "q", facets: [:genre, :year])` validates, and unknown facet atoms raise `ArgumentError` naming the undeclared atom.
- **AC-03b:** `Scrypath.search(Movie, "q")` (no `facets:`) results in `result.facets == nil` — Scrypath does not fetch facet data by default.
- **AC-03c:** `facets: :all` or `facets: "*"` is explicitly NOT supported — the validator rejects non-list values. (Prevents payload bloat from wildcard requests.)

### FACET-04 — `facet_filter:` runtime kwarg with disjunctive-within-field grammar

**Requirement:** `Scrypath.search/3` accepts `facet_filter: keyword()` where each key is a declared facet atom and each value is either a single value, a list-of-values (OR within field), or a range-operator keyword list reusing the existing `:eq | :gt | :gte | :lt | :lte` allowlist. AND across fields. NO boolean composition (`:or`, `:and`, `:not` at top level) — raises on attempt. NO raw Meilisearch strings on the common path.

- **AC-04a:** `facet_filter: [genre: ["fiction", "horror"]]` translates to Meilisearch payload `[["genre = \"fiction\"", "genre = \"horror\""]]`.
- **AC-04b:** `facet_filter: [genre: "fiction", year: [2024, 2025]]` translates to `[["genre = \"fiction\""], ["year = 2024", "year = 2025"]]`.
- **AC-04c:** `facet_filter: [rating: [gte: 7.0, lte: 9.5]]` translates to `[["rating >= 7.0", "rating <= 9.5"]]`.
- **AC-04d:** `facet_filter: [or: [...]]` raises `ArgumentError` with message "boolean composition is not supported in facet_filter" (mirroring existing `filter:` grammar rule).

### FACET-05 — `%Scrypath.SearchResult.Facets{}` sub-struct

**Requirement:** `%Scrypath.SearchResult{}` gains a `facets:` field (defaulted `nil`, NOT in `@enforce_keys`) carrying a `%Scrypath.SearchResult.Facets{}` sub-struct with `distribution`, `stats`, and `declared_order` fields. `Scrypath.SearchResult.Facets.Bucket` struct is the list-element type in `distribution`.

- **AC-05a:** `Scrypath.search(Movie, "q", facets: [:genre])` returns `%SearchResult{facets: %Facets{distribution: %{genre: [%Bucket{value: "drama", count: 42}, ...]}, stats: %{}, declared_order: [:genre]}}`.
- **AC-05b:** Bucket order within `distribution[:genre]` follows `sort_facet_values_by[:genre]` (or the `"*"` fallback); truncated to `max_values_per_facet`.
- **AC-05c:** Compiling a module that constructs `%SearchResult{...}` with only the 0.3.0 enforce keys still succeeds — `facets` is optional with default `nil`.
- **AC-05d:** `result.facets == nil` when `facets:` was not requested in the call (no implicit facet distribution computation).

### FACET-06 — Numeric facet stats default-on

**Requirement:** When `facets: [...]` includes a numeric field, `result.facets.stats` is populated with `%{facet_atom => %{min: number, max: number}}` without a separate opt-in kwarg. Only numeric fields with at least one matching numeric hit populate stats.

- **AC-06a:** `Scrypath.search(Movie, "q", facets: [:rating])` returns `result.facets.stats == %{rating: %{min: 1.0, max: 10.0}}` when hits exist.
- **AC-06b:** When no hits have numeric values for a requested facet (string-only), `result.facets.stats` excludes that key — stats is a partial map, not a nil-value map.
- **AC-06c:** `stats` keys are atomized strictly against `schema.__scrypath__(:faceting).attributes` — response keys not in the declared list are ignored (atom-exhaustion safety).

### FACET-07 — Auto-derivation of `filterableAttributes` from `faceting.attributes` via managed reindex

**Requirement:** `Scrypath.Meilisearch.Settings.resolve/2` appends every atom in `faceting.attributes` to the derived `filterableAttributes` Meilisearch setting. Settings are applied through the existing `create target → apply settings → backfill → cutover` reindex pipeline; NO public verb outside `Scrypath.Meilisearch.*` mutates settings on a live index.

- **AC-07a:** For a schema with `filterable: [:status]` and `faceting: [attributes: [:genre]]`, the resolved settings map passed to Meilisearch `PATCH /settings` contains `filterableAttributes: ["status", "genre"]` (deduplicated, order-stable).
- **AC-07b:** `Scrypath.reindex(Movie, ...)` successfully applies the derived `filterableAttributes` to the target index before backfill.
- **AC-07c:** No new public function on `Scrypath.*` mutates settings — verified by `mix xref graph` or a doctest enumerating public settings-mutation entry points (expected: only `Scrypath.reindex/2`).

### FACET-08 — Phoenix LiveView faceted-search guide

**Requirement:** `guides/phoenix-liveview-faceted-search.md` (or extended section in `guides/phoenix-liveview.md`) ships with a worked "movies by genre × year × rating" example demonstrating four canonical UI patterns and naming at least seven anti-patterns.

- **AC-08a:** Guide contains runnable schema/context/LiveView/template snippets for the movies example; snippets compile against the shipped Scrypath API without modification.
- **AC-08b:** Guide shows the four canonical UI patterns: sidebar checkbox RefinementList, chip row, range slider driven by `facet_stats`, current-refinements chip row.
- **AC-08c:** Guide names at least seven anti-patterns (hierarchical DSL, infinite show-more, undebounced auto-apply, assigns-without-URL, unremovable chips, disjunctive-as-kwarg, sync-read-vs-write confusion) with "do this instead" guidance.
- **AC-08d:** Guide cross-references the relevance-tuning guide for `distinct_attribute` interaction and the sync-modes guide for the read-vs-write distinction.

### FACET-09 — Facet-aware filter composition (`filter:` + `facet_filter:` AND together)

**Requirement:** When both `filter:` (existing common-path kwarg) and `facet_filter:` (new) are provided, the resulting Meilisearch payload is the AND-composition of both. Neither kwarg is silently ignored.

- **AC-09a:** `Scrypath.search(Movie, "q", filter: [status: "published"], facet_filter: [genre: ["drama"]])` produces Meilisearch `filter: [["status = \"published\""], ["genre = \"drama\""]]`.
- **AC-09b:** `filter:` grammar (existing v1.0 contract) is unchanged — no new operators, no widened composition.
- **AC-09c:** An integration test with a live Meilisearch confirms both filter conditions narrow the hit set.

### FACET-10 — Non-goal enforcement: no wildcard, no raw strings, no hierarchical DSL

**Requirement:** The v1.3 public facet API explicitly rejects wildcard facet selection (`facets: :all | "*"`), raw Meilisearch filter strings on the common path, and a `:hierarchical` facet type. Violations raise `ArgumentError` at option-validation time.

- **AC-10a:** `Scrypath.search(Movie, "q", facets: :all)` raises `ArgumentError`.
- **AC-10b:** `Scrypath.search(Movie, "q", facet_filter: "genre = 'drama'")` raises `ArgumentError` with message pointing at `Scrypath.Meilisearch.*` for escape hatch.
- **AC-10c:** `use Scrypath, faceting: [attributes: [{:genre, :hierarchical}]]` raises `ArgumentError` at compile time.
- **AC-10d:** A non-goals-check script (`grep` over library source for forbidden tokens like `mergeFacets`, `:hierarchical` in public-surface modules) returns empty in CI.

---

## Sources

### Primary (HIGH confidence — direct docs / specs / module reads)

- Meilisearch search with facets reference — [Search with facets](https://www.meilisearch.com/docs/learn/filtering_and_sorting/search_with_facet_filters) and [Search API specification](https://specs.meilisearch.dev/specifications/text/0118-search-api.html) — confirmed array-of-arrays filter syntax, `facetDistribution` and `facetStats` response shape.
- Meilisearch Discussion #117 — [Return stats for numerical facets](https://github.com/orgs/meilisearch/discussions/117) — confirmed automatic numeric facet stats behavior.
- Meilisearch Discussion #187 — [Disjunctive Facets Distribution](https://github.com/orgs/meilisearch/discussions/187) — confirmed disjunctive counts require multi-query pattern, not a server primitive.
- Meilisearch Issue #4677 — [distinctAttribute affects facetStats/facetDistribution](https://github.com/meilisearch/meilisearch/issues/4677) — confirmed interaction gotcha.
- Meilisearch Faceting Settings API — [Faceting Setting API spec](https://specs.meilisearch.dev/specifications/text/157-faceting-setting-api.html) — confirmed `maxValuesPerFacet`, `sortFacetValuesBy` shape.
- `/Users/jon/projects/scrypath/lib/scrypath/options.ex` — current `@schema_options`, `@search_options`, `validate_filter_entry!/2` narrow-filter contract.
- `/Users/jon/projects/scrypath/lib/scrypath/schema.ex` — current `__scrypath__/1` reflection pattern.
- `/Users/jon/projects/scrypath/lib/scrypath/search_result.ex` — current `@enforce_keys` and `page/1` helper pattern.
- `/Users/jon/projects/scrypath/lib/scrypath/meilisearch/query.ex` — current `to_payload/1` / `translate_filter/1` extension point.
- `/Users/jon/projects/scrypath/guides/phoenix-liveview.md` — current LiveView guide voice.
- `/Users/jon/projects/scrypath/README.md` and `/Users/jon/projects/scrypath/ARCHITECTURE.md` — current public-surface contract.
- `.planning/research/{STACK,FEATURES,ARCHITECTURE,PITFALLS,SUMMARY}.md` — v1.3 upstream research.
- `.planning/PROJECT.md` — v1.3 non-goals and milestone scope.

### Secondary (MEDIUM confidence — reference-library behavior survey)

- Searchkick README and aggregations docs — [ankane/searchkick](https://github.com/ankane/searchkick) — confirmed `smart_aggs` default and deprecation trajectory.
- algoliasearch-rails README — [algolia/algoliasearch-rails](https://github.com/algolia/algoliasearch-rails) — confirmed `attributesForFaceting` declarative pattern and `hits.facets` return shape.
- Typesense search API reference — [Typesense search docs](https://typesense.org/docs/30.1/api/search.html) — confirmed per-field `facet: true` requirement and `facet_by` query-time syntax.
- Typesense Issues #534, #538, #909, #1412 — confirmed known footguns in facet declaration / multi-value / parenthesis-in-field-name.
- Laravel Scout 12.x docs — [Scout Meilisearch](https://laravel.com/docs/12.x/scout) and [Meilisearch Laravel Scout guide](https://www.meilisearch.com/docs/guides/laravel_scout) — confirmed callback-based facet escape pattern.
- Chewy aggregations docs (RubyDoc) — [chewy Query#aggs](https://www.rubydoc.info/gems/chewy/5.0.0/Chewy/Query) — confirmed DSL-heavy aggregation pattern.
- Algolia InstantSearch RefinementList docs — [RefinementList widget](https://www.algolia.com/doc/api-reference/widgets/refinement-list/react) and [disjunctive vs conjunctive Q&A](https://support.algolia.com/hc/en-us/articles/11923043923217-How-can-I-configure-my-facet-attribute-as-conjunctive-AND-disjunctive-OR) — confirmed `operator: 'or' | 'and'` client-side multi-query pattern.

### Tertiary (LOW confidence — extrapolated developer intuition)

- Phoenix-dev-coming-from-Searchkick vs Algolia vs raw-Meilisearch expectation profiles (Question 4) — extrapolated from community-forum reads and general DX intuition; not survey-data.
- Anti-patterns list (Question 6) — composite of observed patterns in open-source LiveView search apps and known-gotcha discussions; no single authoritative source.

---

*Deep research for: Scrypath v1.3 Phase 20 Faceted Search*
*Researched: 2026-04-17*
*Ready for roadmapper + plan researcher consumption: yes*
