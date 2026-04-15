defmodule Scrypath.Sync do
  @moduledoc false

  alias Scrypath.Config
  alias Scrypath.Projection

  @spec sync_record(module(), struct() | map(), keyword()) :: {:ok, term()} | {:error, term()}
  def sync_record(schema_module, record, opts \\ []) do
    sync_records(schema_module, [record], opts)
  end

  @spec sync_records(module(), [struct() | map()], keyword()) :: {:ok, term()} | {:error, term()}
  def sync_records(schema_module, records, opts \\ []) when is_list(records) do
    config = Config.resolve!(opts)
    documents = Enum.map(records, &Projection.document(schema_module, &1))

    dispatch_upsert(schema_module, documents, config)
  end

  @spec delete_record(module(), struct() | map(), keyword()) :: {:ok, term()} | {:error, term()}
  def delete_record(schema_module, record, opts \\ []) do
    schema_module
    |> resolve_record_document_id(record)
    |> List.wrap()
    |> then(&delete_documents(schema_module, &1, opts))
  end

  @spec delete_document(module(), term(), keyword()) :: {:ok, term()} | {:error, term()}
  def delete_document(schema_module, document_id, opts \\ []) do
    delete_documents(schema_module, [document_id], opts)
  end

  @spec delete_documents(module(), [term()], keyword()) :: {:ok, term()} | {:error, term()}
  def delete_documents(schema_module, document_ids, opts \\ []) when is_list(document_ids) do
    config = Config.resolve!(opts)
    dispatch_delete(schema_module, document_ids, config)
  end

  defp dispatch_upsert(schema_module, documents, config) do
    backend = Config.fetch_backend!(config)

    case Keyword.fetch!(config, :sync_mode) do
      :inline -> backend.upsert_documents(schema_module, documents, config)
      :manual -> backend.upsert_documents(schema_module, documents, config)
      :oban -> backend.upsert_documents(schema_module, documents, config)
    end
  end

  defp dispatch_delete(schema_module, document_ids, config) do
    backend = Config.fetch_backend!(config)

    case Keyword.fetch!(config, :sync_mode) do
      :inline -> backend.delete_documents(schema_module, document_ids, config)
      :manual -> backend.delete_documents(schema_module, document_ids, config)
      :oban -> backend.delete_documents(schema_module, document_ids, config)
    end
  end

  defp resolve_record_document_id(schema_module, source_record) when is_map(source_record) do
    document_id_field = schema_module.__scrypath__(:document_id)

    cond do
      Map.has_key?(source_record, document_id_field) ->
        Map.fetch!(source_record, document_id_field)

      Map.has_key?(source_record, Atom.to_string(document_id_field)) ->
        Map.fetch!(source_record, Atom.to_string(document_id_field))

      true ->
        raise ArgumentError, "missing delete identity #{inspect(document_id_field)} in source record"
    end
  end
end
