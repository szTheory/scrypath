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
**The mistake:** Declaring `:*` or hierarchical dotted atoms in `faceting.attributes`.  
**User-visible consequence:** Compile error or confusing `ArgumentError` instead of a searchable index.  
**Why:** Wildcards and hierarchical dotted names are rejected at the schema layer so facet-related atoms and Meilisearch settings stay predictable.  
**Do instead:** List explicit atoms that are already `filterable:`.  
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
