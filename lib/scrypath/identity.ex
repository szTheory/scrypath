defmodule Scrypath.Identity do
  @moduledoc false

  @spec document_id(module(), struct() | map()) :: term()
  def document_id(schema_module, source_record) do
    if supports_custom_document_id?(schema_module) do
      schema_module.search_document_id(source_record)
    else
      default_document_id(schema_module, source_record)
    end
  end

  @spec document_ids(module(), [struct() | map()]) :: [term()]
  def document_ids(schema_module, source_records) when is_list(source_records) do
    Enum.map(source_records, &document_id(schema_module, &1))
  end

  @spec supports_custom_document_id?(module()) :: boolean()
  def supports_custom_document_id?(schema_module) do
    function_exported?(schema_module, :search_document_id, 1)
  end

  defp default_document_id(schema_module, source_record) when is_map(source_record) do
    document_id_field = schema_module.__scrypath__(:document_id)

    cond do
      Map.has_key?(source_record, document_id_field) ->
        Map.fetch!(source_record, document_id_field)

      Map.has_key?(source_record, Atom.to_string(document_id_field)) ->
        Map.fetch!(source_record, Atom.to_string(document_id_field))

      true ->
        raise ArgumentError,
              "missing document id #{inspect(document_id_field)} in source record"
    end
  end
end
