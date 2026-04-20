defmodule Scrypath.Meilisearch.FederatedDecode do
  @moduledoc """
  Decodes federated `/multi-search` responses into per-index raw maps suitable
  for building the public search result structs returned from `Scrypath.search/3`.

  Federated responses carry a flat `hits` list tagged with `_federation.indexUid`
  and optional `facetsByIndex` keyed by index UID. This module never calls
  `String.to_atom/1` on remote keys.
  """

  @doc """
  Returns `{:ok, [{schema, raw_map}]}` aligned to `indexed_schemas` declaration order.

  `indexed_schemas` is `[{schema_module, index_uid_string}, ...]`.
  """
  @spec per_schema_maps(map(), [{module(), String.t()}]) ::
          {:ok, [{module(), map()}]} | {:error, term()}
  def per_schema_maps(response, indexed_schemas)
      when is_map(response) and is_list(indexed_schemas) do
    case Map.get(response, "results") || Map.get(response, :results) do
      results when is_list(results) ->
        decode_results_array(results, indexed_schemas)

      _ ->
        decode_federated(response, indexed_schemas)
    end
  end

  defp decode_results_array(results, indexed_schemas) do
    if length(results) != length(indexed_schemas) do
      {:error, {:federated_decode, :results_length_mismatch}}
    else
      {:ok,
       Enum.zip_with(indexed_schemas, results, fn {schema, _uid}, body -> {schema, body} end)}
    end
  end

  defp decode_federated(response, indexed_schemas) do
    hits = Map.get(response, "hits") || Map.get(response, :hits) || []

    facets_by_index =
      Map.get(response, "facetsByIndex") || Map.get(response, :facetsByIndex) || %{}

    hits_by_uid = group_hits_by_federation_uid(hits)
    facets_norm = facets_by_uid_string(facets_by_index)

    Enum.reduce_while(indexed_schemas, {:ok, []}, fn {schema, uid}, {:ok, acc} ->
      {:cont,
       {:ok,
        acc ++ [federated_raw_for_schema(schema, uid, hits_by_uid, facets_norm, facets_by_index)]}}
    end)
  end

  defp group_hits_by_federation_uid(hits) do
    Enum.group_by(hits, fn hit ->
      fed = Map.get(hit, "_federation") || Map.get(hit, :_federation) || %{}
      Map.get(fed, "indexUid") || Map.get(fed, :indexUid)
    end)
  end

  defp federated_raw_for_schema(schema, uid, hits_by_uid, facets_norm, facets_by_index) do
    uid_s = to_string(uid)
    uid_hits = Map.get(hits_by_uid, uid_s) || Map.get(hits_by_uid, uid) || []

    facet_entry =
      Map.get(facets_norm, uid_s) || Map.get(facets_by_index, uid_s) || %{}

    dist =
      Map.get(facet_entry, "facetDistribution") ||
        Map.get(facet_entry, :facetDistribution) ||
        %{}

    stats =
      Map.get(facet_entry, "facetStats") || Map.get(facet_entry, :facetStats) || %{}

    raw = %{
      "hits" => Enum.map(uid_hits, &strip_federation/1),
      "facetDistribution" => dist,
      "facetStats" => stats
    }

    {schema, raw}
  end

  defp facets_by_uid_string(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end

  defp strip_federation(hit) when is_map(hit) do
    hit
    |> Map.delete("_federation")
    |> Map.delete(:_federation)
  end

  defp strip_federation(hit), do: hit
end
