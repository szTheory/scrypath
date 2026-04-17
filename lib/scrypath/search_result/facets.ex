defmodule Scrypath.SearchResult.Facets do
  @moduledoc """
  Facet counts and stats decoded from a Meilisearch search response.

  | Meilisearch wire key | Elixir field / notes |
  |---------------------|----------------------|
  | `facetDistribution` | `distribution` — map of facet field → list of buckets |
  | `facetStats` | `stats` — map of facet field → summary map (`min` / `max` for numerics) |
  | bucket value + count | `Scrypath.SearchResult.Facets.Bucket` — `value` and `count` |
  """

  defmodule Bucket do
    @moduledoc """
    One entry from Meilisearch `facetDistribution`: a facet **value** and its document **count**.
    """

    defstruct [:value, :count]

    @type t :: %__MODULE__{value: term(), count: integer()}
  end

  defstruct distribution: %{}, stats: %{}, declared_order: []

  @type t :: %__MODULE__{
          distribution: %{atom() => [Bucket.t()]},
          stats: %{atom() => map()},
          declared_order: [atom()]
        }
end
