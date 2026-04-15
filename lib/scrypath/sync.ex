defmodule Scrypath.Sync do
  @moduledoc false

  alias Scrypath.Config
  alias Scrypath.Identity
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
    |> Identity.document_id(record)
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
end
