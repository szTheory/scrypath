defmodule Scrypath.SearchResult do
  @moduledoc false

  alias Scrypath.Query
  alias Scrypath.SearchResult.Facets
  alias Scrypath.SearchResult.Facets.Bucket

  @enforce_keys [:query, :hits, :records, :raw, :missing_ids, :page]
  defstruct [:query, :hits, :records, :raw, :missing_ids, :page, :facets]

  @type t :: %__MODULE__{
          query: Query.t(),
          hits: [map()],
          records: [struct()],
          raw: map(),
          missing_ids: [term()],
          page: map(),
          facets: Facets.t()
        }

  @spec new(Query.t(), map(), [struct()], [term()]) :: t()
  def new(%Query{} = query, raw, records, missing_ids) when is_map(raw) do
    %__MODULE__{
      query: query,
      hits: hits(raw),
      records: records,
      raw: raw,
      missing_ids: missing_ids,
      page: page(raw),
      facets: decode_facets(query, raw)
    }
  end

  defp decode_facets(%Query{facets: []}, _raw), do: %Facets{}

  defp decode_facets(%Query{facets: order} = query, raw) when is_list(order) do
    dist_raw = Map.get(raw, "facetDistribution") || Map.get(raw, :facetDistribution) || %{}
    stats_raw = Map.get(raw, "facetStats") || Map.get(raw, :facetStats) || %{}

    distribution =
      Map.new(order, fn field ->
        key = Atom.to_string(field)
        inner = Map.get(dist_raw, key) || Map.get(dist_raw, field) || %{}
        {field, decode_distribution_buckets(inner)}
      end)

    stats =
      Map.new(order, fn field ->
        key = Atom.to_string(field)
        inner = Map.get(stats_raw, key) || Map.get(stats_raw, field) || %{}
        {field, decode_stats_map(inner)}
      end)

    %Facets{distribution: distribution, stats: stats, declared_order: query.facets}
  end

  defp decode_distribution_buckets(map) when is_map(map) do
    map
    |> Enum.sort_by(fn {k, _} -> to_string(k) end)
    |> Enum.map(fn {value, count} ->
      %Bucket{value: value, count: decode_count(count)}
    end)
  end

  defp decode_distribution_buckets(_), do: []

  defp decode_stats_map(map) when is_map(map) do
    map
    |> Enum.map(fn
      {"min", v} -> {:min, decode_number(v)}
      {"max", v} -> {:max, decode_number(v)}
      {:min, v} -> {:min, decode_number(v)}
      {:max, v} -> {:max, decode_number(v)}
      {k, v} -> {normalize_stat_key(k), v}
    end)
    |> Enum.into(%{})
  end

  defp decode_stats_map(_), do: %{}

  defp normalize_stat_key(k) when is_atom(k), do: k
  defp normalize_stat_key(k) when is_binary(k), do: String.to_atom(k)

  defp decode_count(n) when is_integer(n), do: n
  defp decode_count(n) when is_float(n), do: trunc(n)
  defp decode_count(_), do: 0

  defp decode_number(n) when is_number(n), do: n
  defp decode_number(_), do: nil

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
