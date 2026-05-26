# Phase 95: API Contract and Execution - Architectural Discussion

## 1. Goal Overview
Implement `Scrypath.search_facet_values/4` to wrap Meilisearch's `/facet-search` endpoint. This gives developers a native, idiomatic Elixir interface for querying high-cardinality facets (e.g., for type-ahead filters) without parsing raw JSON.

## 2. API Signature & Flow
The primary entry point will be added to `Scrypath`:
```elixir
@doc """
Searches for facet values within a specific facet. Useful for building type-ahead facet filters.
"""
@spec search_facet_values(module(), atom() | String.t(), String.t(), keyword()) :: {:ok, Scrypath.FacetSearchResult.t()} | {:error, term()}
def search_facet_values(schema_module, facet_name, search_string, opts \\ []) do
  Scrypath.Search.search_facet_values(schema_module, facet_name, search_string, opts)
end

@spec search_facet_values!(module(), atom() | String.t(), String.t(), keyword()) :: Scrypath.FacetSearchResult.t()
def search_facet_values!(schema_module, facet_name, search_string, opts \\ [])
```

### Delegation
`Scrypath.Search` handles option merging, schema resolution, and telemetry, similar to `Scrypath.Search.search_within_facet/4` but routing to a new backend callback.

## 3. Backend Architecture (Gray Areas & Tradeoffs)
**Gray Area:** Does `Scrypath.Backend` need a new callback, or do we overload `search/3`?
**Recommendation:** Add a specific callback to `Scrypath.Backend`. 
Overloading `search/3` with a magical `%FacetQuery{}` struct violates the principle of least surprise and breaks backend separation of concerns (a backend like `Scrypath.Backend.Meilisearch` clearly maps `/search` to `search/3` and `/facet-search` to `search_facet_values/5`).

```elixir
@callback search_facet_values(module(), String.t(), String.t(), keyword(), keyword()) :: {:ok, map()} | {:error, term()}
```

### Meilisearch Adapter (`Scrypath.Backend.Meilisearch`)
`Scrypath.Meilisearch.Client` will introduce:
```elixir
def facet_search(index_name, facet_name, facet_query, opts, config)
```
Sending the payload:
```json
{
  "facetName": "genre",
  "facetQuery": "sci",
  ... (other opts like q, filter, matchingStrategy translated via existing `build_opts`)
}
```

## 4. Response Parsing
**Recommendation:** Introduce `Scrypath.FacetSearchResult`.
Returning a raw map forces developers to know Meilisearch's shape (`%{"facetHits" => ...}`). Returning a struct is idiomatic to Elixir/Scrypath.

```elixir
defmodule Scrypath.FacetSearchResult do
  @moduledoc "Result of a facet value search"
  alias Scrypath.SearchResult.Facets.Bucket

  @type t :: %__MODULE__{
    facet_query: String.t(),
    hits: [Bucket.t()],
    raw: map()
  }
  @enforce_keys [:facet_query, :hits, :raw]
  defstruct [:facet_query, :hits, :raw]
  
  def new(raw) do
    # decodes raw["facetHits"] into a list of %Bucket{} structs
  end
end
```
Using the existing `%Scrypath.SearchResult.Facets.Bucket{}` struct ensures consistency with regular facet distributions.

## 5. Developer Ergonomics & UI/UX
By returning `hits: [%Bucket{value: "Sci-Fi", count: 12}]`, a LiveView developer can seamlessly map this over a `<datalist>` or custom dropdown. They won't need to dig into the payload or remember if the key was `facetHits` or `hits`.

## 6. Verification and Mocking
We must add this new callback to `Scrypath.TestSupport.FakeBackend` and `ScrypathOps.SearchPlayground.Adapter` so that downstream apps upgrading to Scrypath v1.26 don't experience broken tests when their mock backend lacks the callback.

## Conclusion
This approach guarantees a clean, type-safe API for developers while cleanly mapping onto Meilisearch's existing endpoints, without bleeding HTTP concepts into the caller. We can proceed with implementation on these lines.