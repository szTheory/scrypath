defmodule Scrypath.Meilisearch.FederatedDecode do
  @moduledoc """
  Decodes federated `/multi-search` responses into per-index raw maps suitable
  for building the public search result structs returned from `Scrypath.search/3`.

  Federated responses carry a flat `hits` list tagged with `_federation.indexUid`
  and optional `facetsByIndex` keyed by index UID. This module never calls
  `String.to_atom/1` on remote keys.
  """

  @doc """
  Returns global merge order for a **flat** federated `hits` stream.

  Each element is `{schema_module, id}` where `id` is the primary key value from
  the hit map (`"id"` first, else the schema's configured `document_id` as a string
  key). Declaration order in `indexed_schemas` is only used to resolve index UIDs
  to modules; **hit list order is preserved** from `response`.
  """
  @spec merge_hit_order(map(), [{module(), String.t()}]) ::
          {:ok, [{module(), term()}]} | {:error, term()}
  def merge_hit_order(response, indexed_schemas)
      when is_map(response) and is_list(indexed_schemas) do
    case Map.get(response, "results") || Map.get(response, :results) do
      results when is_list(results) ->
        {:error, {:federated_decode, :not_flat_federated}}

      _ ->
        hits = Map.get(response, "hits") || Map.get(response, :hits) || []
        uid_to_schema = Map.new(indexed_schemas, fn {s, uid} -> {to_string(uid), s} end)
        walk_merge_hits(hits, uid_to_schema, [])
    end
  end

  defp walk_merge_hits([], _uid_to_schema, acc), do: {:ok, Enum.reverse(acc)}

  defp walk_merge_hits([hit | rest], uid_to_schema, acc) when is_map(hit) do
    case merge_hit_step(hit, uid_to_schema) do
      {:ok, pair} -> walk_merge_hits(rest, uid_to_schema, [pair | acc])
      {:error, _} = err -> err
    end
  end

  defp walk_merge_hits([_ | rest], uid_to_schema, acc),
    do: walk_merge_hits(rest, uid_to_schema, acc)

  defp merge_hit_step(hit, uid_to_schema) do
    with {:ok, uid} <- federation_uid(hit),
         {:ok, schema} <- schema_for_uid(uid_to_schema, uid),
         {:ok, id} <- primary_id_from_hit(hit, schema) do
      {:ok, {schema, id}}
    end
  end

  defp federation_uid(hit) do
    fed = Map.get(hit, "_federation") || Map.get(hit, :_federation) || %{}
    uid = Map.get(fed, "indexUid") || Map.get(fed, :indexUid)

    if uid in [nil, ""],
      do: {:error, {:federated_decode, :missing_federation_tag}},
      else: {:ok, to_string(uid)}
  end

  defp schema_for_uid(uid_to_schema, uid) do
    case Map.fetch(uid_to_schema, uid) do
      {:ok, schema} -> {:ok, schema}
      :error -> {:error, {:federated_decode, {:unknown_index_uid, uid}}}
    end
  end

  defp primary_id_from_hit(hit, schema) do
    case Map.fetch(hit, "id") do
      {:ok, id} -> {:ok, id}
      :error -> document_id_fallback(hit, schema)
    end
  end

  defp document_id_fallback(hit, schema) do
    key = schema |> Scrypath.Schema.Metadata.document_id() |> Atom.to_string()

    case Map.fetch(hit, key) do
      {:ok, id} -> {:ok, id}
      :error -> {:error, {:federated_decode, {:missing_id, schema, key}}}
    end
  end

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
