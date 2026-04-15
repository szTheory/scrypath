defmodule Scrypath.Projection do
  @moduledoc """
  Document projection for schemas declared with `use Scrypath`.

  `Scrypath.Projection.document/2` projects the declared `fields: [...]` by default.
  When a schema exports `search_document/1`, that hook takes precedence and the
  document source becomes `:custom`.

  Association-derived data requires explicit preload work before projection. Scrypath
  does not reach through unloaded associations or infer extra queries on behalf of the
  caller.
  """

  alias Scrypath.Document

  @spec document(module(), struct() | map()) :: Document.t()
  def document(schema_module, source_record) do
    if function_exported?(schema_module, :search_document, 1) do
      build_custom_document(schema_module, source_record)
    else
      build_field_document(schema_module, source_record)
    end
  end

  @spec document_source(module()) :: :custom | :fields
  def document_source(schema_module) do
    if function_exported?(schema_module, :search_document, 1), do: :custom, else: :fields
  end

  defp build_custom_document(schema_module, source_record) do
    projected =
      source_record
      |> schema_module.search_document()
      |> ensure_projection_map!()

    id_field = schema_module.__scrypath__(:document_id)

    {id, data} =
      case Map.pop(projected, :id) do
        {nil, projected_without_id} ->
          case Map.pop(projected_without_id, "id") do
            {nil, projected_without_string_id} ->
              {fetch_field!(source_record, id_field), projected_without_string_id}

            {projected_id, projected_without_string_id} ->
              {projected_id, projected_without_string_id}
          end

        {projected_id, projected_without_id} ->
          {projected_id, projected_without_id}
      end

    %Document{id: id, data: data, source: :custom}
  end

  defp build_field_document(schema_module, source_record) do
    fields = schema_module.__scrypath__(:fields)
    id_field = schema_module.__scrypath__(:document_id)

    data =
      Map.new(fields, fn field ->
        {field, fetch_field!(source_record, field)}
      end)

    %Document{id: fetch_field!(source_record, id_field), data: data, source: :fields}
  end

  defp ensure_projection_map!(projection) when is_map(projection), do: projection

  defp ensure_projection_map!(_projection) do
    raise ArgumentError, "search_document/1 must return a map"
  end

  defp fetch_field!(source_record, field) when is_map(source_record) do
    cond do
      Map.has_key?(source_record, field) ->
        Map.fetch!(source_record, field)

      Map.has_key?(source_record, Atom.to_string(field)) ->
        Map.fetch!(source_record, Atom.to_string(field))

      true ->
        raise ArgumentError, "missing projected field #{inspect(field)} in source record"
    end
  end
end
