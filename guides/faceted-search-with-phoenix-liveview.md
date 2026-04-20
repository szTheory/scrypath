# Faceted search with Phoenix LiveView

This guide walks through a **movies-shaped** example (genre, year, rating, director) that stays on the **common `Scrypath.search/3` path** with `facets:`, `facet_filter:`, and URL-friendly `handle_params/3`. The patterns mirror the library’s own contract tests so prose and code stay aligned as APIs evolve.

## Overview

Faceted search combines full-text search with **facet distributions** (counts per attribute value) and optional **facet filters** that narrow results. Scrypath keeps the contract explicit:

- Declarations live on the schema (`faceting:` aligned with `filterable:`).
- Runtime options on `Scrypath.search/3` include `:facets` and `:facet_filter`.
- Meilisearch wire keys (`facetDistribution`, `facetStats`) decode into `%Scrypath.SearchResult.Facets{}`.

LiveView owns **assigns, loading, and URL state**. Your **context** still owns repo access, hydration options, and the call to `Scrypath.search/3`.

## Prerequisites

- Read `guides/relevance-tuning.md` for how schema `settings:` maps into Meilisearch index settings before you tune ranking alongside facets.
- A running Meilisearch is **not** required to follow the patterns — tests in the library use `FakeBackend` and `Req.Test`-style fixtures for deterministic bodies.

## Declare facets on the schema

Use the same movie shape as the tests: `filterable:` must be a superset of `faceting.attributes:`.

```elixir
defmodule MyApp.Movies.Movie do
  use Ecto.Schema
  use Scrypath,
    fields: [:title, :genre, :year, :rating, :director],
    filterable: [:genre, :year, :rating, :director],
    faceting: [
      attributes: [:genre, :year, :rating, :director],
      max_values_per_facet: 100
    ]

  schema "movies" do
    field :title, :string
    field :genre, :string
    field :year, :integer
    field :rating, :float
    field :director, :string
  end
end
```

If you request a facet not listed in `faceting.attributes`, `Scrypath.search/3` returns `{:error, {:unknown_facet, attr}}`. The user-facing dev copy for that situation is: **That attribute is not declared on this schema's `faceting:` list.**

## Hierarchical facets

Meilisearch represents hierarchical menus as **multiple filterable facet attributes** rather than a nested JSON tree under one key. A common pattern uses **dotted paths** such as `"categories.lvl0"` and `"categories.lvl1"` that align with **flat** `facetDistribution` maps per attribute in search responses.

**Opt-in:** set `nested_facet_paths: true` under `faceting:` before declaring dotted atoms such as `:"categories.lvl0"` in `faceting.attributes`. Schemas that omit this flag keep the same flat-only behavior as earlier releases.

**Sugar:** optional `hierarchy: [base: :categories, depth: 2]` expands into `:"categories.lvl0"` and `:"categories.lvl1"` style names so you list the base field once; expanded names still must appear in `filterable:`.

**Counts and filters:** drilling down typically applies filters **AND between facet attributes** (conjunctive across the per-level fields) while values within one attribute stay **disjunctive** when you pass a list to `facet_filter:` for that field.

**Wire shape:** `facetDistribution` returns one map per declared attribute string key, not a nested hierarchy object. Keys in `result.facets.distribution` use the **same atoms** you pass to `facets:` and declare under `faceting.attributes`.

**Wildcards remain mistakes:** declaring `:*` or dotted names outside the supported single-dot **`lvlN`** suffix pattern still fails fast at compile time.

## Disjunctive facet counts

Facet UX often combines **OR within the same facet field** (for example two genres) with **AND across different facet fields** (for example genre OR plus a specific year). `Scrypath.Meilisearch.Query` already encodes that filter shape; this section is about **`facetDistribution`** counts.

A **single search** response always intersects facet refinements with the hit set. Bucket counts therefore reflect what Meilisearch computed **after** every active facet filter — not “unrefined OR-group” counts from that response alone.

Operators who want disjunctive bucket counts follow Meilisearch’s **multi-search** recipe: keep the tightened main query for hits, issue auxiliary searches that drop each disjunctive group’s refinements for that group’s distribution (often `limit: 0`), then merge raw `facetDistribution` maps with `Scrypath.Facets.Disjunctive.merge_distributions/2` before decoding into `%Scrypath.SearchResult.Facets{}`.

Reference scenario **Genre OR + year AND on the movies catalog**: pass two genre values under one `facet_filter:` key (OR inside `genre`) and one year value under `year` (AND against the genre group). Hits and counts both narrow on the conjunctive document set until you add auxiliary queries for disjunctive count UX.

| Query role | What `facetDistribution` answers |
|------------|-----------------------------------|
| Main search with all filters | Counts on the narrowed catalog (honest **single search** semantics). |
| Auxiliary per-field queries | Counts as if that facet group were relaxed, for merging via **multi-search**. |

## Primary path: `handle_params` + URL sync

**Recommended:** normalize query + facet params in `handle_params/3`, then call your context with a keyword list that mirrors what you will pass to `Scrypath.search/3`.

```elixir
def handle_params(params, _uri, socket) do
  q = Map.get(params, "q", "")
  genres = parse_genres(params["genre"])
  years = parse_int_list(params["year"])

  facet_filter =
    []
    |> maybe_put(:genre, genres)
    |> maybe_put(:year, years)

  {:noreply, run_search(socket, q, facet_filter)}
end
```

Use `push_patch/2` or `<.link navigate={~p"/movies?#{params}"}>` so refresh and deep links restore the same facet state. Example URLs in this guide use fictional hosts such as `https://example.com` only.

## Sidebar checklist (genre + director)

Render facet buckets from `result.facets.distribution` (not raw Meilisearch JSON in templates). Checkbox groups map cleanly to **disjunctive within field** semantics for `facet_filter:`:

```elixir
example_facet_filter = [genre: ["Horror", "Sci-Fi"]]
```

**Layer:** UI checklist rows use `gap-2` (8px) vertical rhythm between rows for consistent spacing.

## Chip row (active filters)

Active `facet_filter` entries should render as removable chips between the search rail and the results list. Each chip exposes `aria-label` **Remove {facet name}: {value}** (for example **Remove genre: Horror**).

Primary CTA copy is locked as **Search catalog** — it submits the text query and applies the current facet state to `Scrypath.search/3`.

## Numeric range (rating)

Use `result.facets.stats` for numeric min/max labels when present, then issue range filters with the common filter operators:

```elixir
Scrypath.search(MyApp.Movies.Movie, "space",
  backend: MyApp.SearchBackend,
  facets: [:rating],
  facet_filter: [rating: [gte: 3.0, lte: 5.0]]
)
```

## Search-within-facet (director list)

For long director lists, add a **text input that filters rows client-side** (LiveView assign only). This does **not** call the Meilisearch facet-search API (deferred on the roadmap); it is **assign-filter only** for v1.3.

## Loading and errors

While `Scrypath.search/3` is in flight, show **Searching…** on the primary CTA (disabled) and `aria-busy="true"` on the results region.

On `{:error, reason}`, show **Search could not complete.** with `inspect(reason)` in monospace, then **Retry search** and **Remove the filter you added last** as actions.

Empty results use:

- Heading: **No movies match these filters**
- Body: **Try removing one filter or shortening your search. Bucket counts update as you change filters.**

Destructive reset copy: **Clear all filters** with confirmation **Reset genre, year, rating, and director?** — confirm **Reset filters**, cancel **Keep filters**.

## Progressive disclosure: `handle_event` only

You can prototype with `handle_event/3` alone for classroom demos. Add an explicit disclaimer: **bookmarking and refresh will not restore facet state** until you move the same parameters through `handle_params/3`.

## Anti-pattern appendix

Single index; bands are **API**, **Meilisearch**, then **UI**. Each entry lists **Layer → mistake → consequence → why → do instead**.

### API

#### API — Wildcard facet attributes

**Layer:** API  
**The mistake:** Declaring `:*` in `faceting.attributes`, or dotted atoms without `nested_facet_paths: true`, or dotted shapes that do not follow the single-dot **`lvlN`** suffix pattern.  
**User-visible consequence:** Compile error or confusing `ArgumentError` instead of a searchable index.  
**Why:** Wildcards stay unsupported. Dotted Meilisearch-style hierarchical paths require the explicit opt-in and the documented `lvlN` suffix shape so facet atoms and index settings stay predictable.  
**Do instead:** List explicit flat atoms, or follow **Hierarchical facets** above with `nested_facet_paths: true` and supported `lvlN` paths that are also `filterable:`.  
**See also:** Schema section above.

#### API — Facet filter as raw string

**Layer:** API  
**The mistake:** Passing a Meilisearch filter string into `facet_filter:`.  
**User-visible consequence:** Validation rejects the call or you bypass Scrypath’s field checks.  
**Why:** The common path only accepts keyword-shaped filters so keys can be checked against `faceting.attributes`.  
**Do instead:** Use keyword lists and structured range maps; only bypass the common `Scrypath.search/3` contract when you intentionally issue raw Meilisearch HTTP requests yourself.  
**See also:** `Scrypath.search/3` docs.

#### API — Unknown facet atom

**Layer:** API  
**The mistake:** Adding `:studio` to `:facets` without declaring it on the schema.  
**User-visible consequence:** `{:error, {:unknown_facet, :studio}}` from `Scrypath.search/3`.  
**Why:** Facets must be declared explicitly on the schema so Scrypath can validate requests against `faceting.attributes`.  
**Do instead:** Extend `faceting: [attributes: ...]` and managed settings before requesting the facet.

### Meilisearch

#### Meilisearch — Ignoring AND between `filter` and `facetFilters`

**Layer:** Meilisearch  
**The mistake:** Assuming `filter` replaces `facetFilters` in the JSON body.  
**User-visible consequence:** Results still narrowed by a facet you thought you cleared.  
**Why:** Meilisearch ANDs `filter` and `facetFilters` together.  
**Do instead:** Clear both layers when resetting UI state; consult `Scrypath.Meilisearch.Query` payload helpers.

#### Meilisearch — Expecting facet-search hits from `facets:`

**Layer:** Meilisearch  
**The mistake:** Treating `facetDistribution` as a second search hit list.  
**User-visible consequence:** UI shows counts but no “facet value documents”.  
**Why:** Distribution is counts per bucket, not nested documents.  
**Do instead:** Keep document hits in `result.hits` and counts in `result.facets`.

#### Meilisearch — Counts ignore my OR group

**Layer:** Meilisearch  
**The mistake:** Expecting one response’s `facetDistribution` to show counts **as if** an OR-selected facet group were ignored for counting purposes.  
**User-visible consequence:** Operators think Scrypath “lost” their OR semantics when bucket numbers shrink with refinements.  
**Why:** Meilisearch intersects counts with the same filtered hit set the UI already narrowed.  
**Do instead:** Reread **Disjunctive facet counts** above and implement the documented **multi-search** merge path when you need disjunctive count UX.

### UI

#### UI — Mutating URL only in `handle_event`

**Layer:** UI  
**The mistake:** Patching assigns without syncing the browser URL.  
**User-visible consequence:** Shared links miss facet state.  
**Why:** Deep links are a first-class expectation for faceted catalog UX.  
**Do instead:** Mirror params in `handle_params/3` and `push_patch/2`.

#### UI — Hiding loading state on slow networks

**Layer:** UI  
**The mistake:** Leaving buttons enabled while a search is in flight.  
**User-visible consequence:** Double submits and conflicting results.  
**Why:** Operators cannot tell whether a slow facet toggle applied.  
**Do instead:** Disable **Search catalog** and mark the results region `aria-busy="true"` until the tuple returns.

#### UI — Silent unknown facet failures

**Layer:** UI  
**The mistake:** Dropping `{:error, {:unknown_facet, _}}` on the floor.  
**User-visible consequence:** Empty panes with no explanation.  
**Why:** The `{:error, {:unknown_facet, _}}` tuple is the signal that a facet was requested without a matching `faceting:` declaration.  
**Do instead:** Surface **That attribute is not declared on this schema's `faceting:` list.** beside the control that triggered the request.

---

## Fixture cross-reference

The compile-checked fixture `Scrypath.TestSupport.Docs.PhoenixExampleCase.FacetedBrowseLive` mirrors the `handle_params` flow without importing your application code—useful when extending library tests that keep this guide and ExDoc snippets in sync.

## See also

- `guides/phoenix-liveview.md` — context boundary for LiveView.
- `Scrypath.search/3`, `Scrypath.schema_faceting/1`, and `Scrypath.Meilisearch.Query.to_payload/1` in ExDoc for the exact option keys and wire mapping.
