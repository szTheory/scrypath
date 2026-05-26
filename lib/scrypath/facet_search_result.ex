defmodule Scrypath.FacetSearchResult do
  @moduledoc false

  alias Scrypath.SearchResult.Facets.Bucket

  @enforce_keys [:facet_query, :hits, :raw]
  defstruct [:facet_query, :hits, :raw]

  @type t :: %__MODULE__{
          facet_query: String.t() | nil,
          hits: [Bucket.t()],
          raw: map()
        }

  @spec new(map()) :: t()
  def new(raw) when is_map(raw) do
    %__MODULE__{
      facet_query: facet_query(raw),
      hits: hits(raw),
      raw: raw
    }
  end

  defp facet_query(raw) do
    Map.get(raw, "facetQuery") || Map.get(raw, :facetQuery)
  end

  defp hits(raw) do
    hits_list = Map.get(raw, "facetHits") || Map.get(raw, :facetHits) || []
    
    Enum.map(hits_list, fn hit ->
      %Bucket{
        value: Map.get(hit, "value") || Map.get(hit, :value),
        count: decode_count(Map.get(hit, "count") || Map.get(hit, :count))
      }
    end)
  end

  defp decode_count(n) when is_integer(n), do: n
  defp decode_count(n) when is_float(n), do: trunc(n)
  defp decode_count(_), do: 0
end
