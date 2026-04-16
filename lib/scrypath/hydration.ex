defmodule Scrypath.Hydration do
  @moduledoc false

  import Ecto.Query

  @spec hydrate(module(), [map()], keyword()) :: {[struct()], [term()]}
  def hydrate(_schema_module, [], _opts), do: {[], []}

  def hydrate(schema_module, hits, opts) when is_list(hits) do
    repo = Keyword.fetch!(opts, :repo)
    preload = Keyword.get(opts, :preload, [])
    source_id_field = source_id_field(schema_module)
    source_ids = Enum.map(hits, &fetch_hit_id!(&1, source_id_field))

    query =
      schema_module
      |> where([record], field(record, ^source_id_field) in ^source_ids)
      |> maybe_preload(preload)

    records = repo.all(query)

    records_by_id =
      Map.new(records, fn record ->
        {Map.fetch!(record, source_id_field), record}
      end)

    Enum.reduce(source_ids, {[], []}, fn source_id, {ordered_records, missing_ids} ->
      case Map.fetch(records_by_id, source_id) do
        {:ok, record} -> {[record | ordered_records], missing_ids}
        :error -> {ordered_records, [source_id | missing_ids]}
      end
    end)
    |> then(fn {records, missing_ids} ->
      {Enum.reverse(records), Enum.reverse(missing_ids)}
    end)
  end

  defp source_id_field(schema_module) do
    if function_exported?(schema_module, :__schema__, 1) do
      case schema_module.__schema__(:primary_key) do
        [field | _] -> field
        _ -> Scrypath.document_id_field(schema_module)
      end
    else
      Scrypath.document_id_field(schema_module)
    end
  end

  defp fetch_hit_id!(hit, source_id_field) when is_map(hit) do
    cond do
      Map.has_key?(hit, source_id_field) ->
        Map.fetch!(hit, source_id_field)

      Map.has_key?(hit, Atom.to_string(source_id_field)) ->
        Map.fetch!(hit, Atom.to_string(source_id_field))

      true ->
        raise ArgumentError,
              "search hit is missing hydration id #{inspect(source_id_field)}"
    end
  end

  defp maybe_preload(query, []), do: query
  defp maybe_preload(query, preload), do: preload(query, ^preload)
end
