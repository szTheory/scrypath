defmodule Scrypath.SearchResult do
  @moduledoc false

  alias Scrypath.Query

  @enforce_keys [:query, :hits, :records, :raw, :missing_ids, :page]
  defstruct [:query, :hits, :records, :raw, :missing_ids, :page]

  @type t :: %__MODULE__{
          query: Query.t(),
          hits: [map()],
          records: [struct()],
          raw: map(),
          missing_ids: [term()],
          page: map()
        }

  @spec new(Query.t(), map(), [struct()], [term()]) :: t()
  def new(%Query{} = query, raw, records, missing_ids) when is_map(raw) do
    %__MODULE__{
      query: query,
      hits: hits(raw),
      records: records,
      raw: raw,
      missing_ids: missing_ids,
      page: page(raw)
    }
  end

  defp hits(raw) do
    Map.get(raw, "hits") || Map.get(raw, :hits) || []
  end

  defp page(raw) do
    %{
      number: Map.get(raw, "page") || Map.get(raw, :page),
      size: Map.get(raw, "hitsPerPage") || Map.get(raw, :hitsPerPage),
      total_pages: Map.get(raw, "totalPages") || Map.get(raw, :totalPages),
      total_hits: Map.get(raw, "totalHits") || Map.get(raw, :totalHits),
      estimated_total_hits:
        Map.get(raw, "estimatedTotalHits") || Map.get(raw, :estimatedTotalHits),
      offset: Map.get(raw, "offset") || Map.get(raw, :offset),
      limit: Map.get(raw, "limit") || Map.get(raw, :limit)
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Enum.into(%{})
  end
end
