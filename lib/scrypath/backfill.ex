defmodule Scrypath.Backfill do
  @moduledoc false

  import Ecto.Query

  alias Scrypath.Options
  alias Scrypath.Projection

  @spec backfill(module(), keyword()) :: {:ok, map()} | {:error, term()}
  def backfill(schema_module, opts \\ []) do
    run(schema_module, opts)
  end

  @spec run(module(), keyword()) :: {:ok, map()} | {:error, term()}
  def run(schema_module, opts \\ []) do
    config = Options.validate_backfill_options!(opts)
    repo = Keyword.fetch!(config, :repo)
    backend = Keyword.fetch!(config, :backend)
    index = Keyword.get(config, :index_name) || backend.index_name(schema_module, config)

    query =
      (config[:query] || schema_module)
      |> order_by([record], asc: field(record, ^primary_key(schema_module)))
      |> limit(^Keyword.fetch!(config, :batch_size))

    records = repo.all(query)
    documents = Enum.map(records, &Projection.document(schema_module, &1))

    with {:ok, _result} <- upsert_documents(schema_module, documents, backend, config, index) do
      {:ok,
       %{
         index: index,
         batches: batches_for(documents),
         documents: length(documents),
         mode: Keyword.fetch!(config, :sync_mode)
       }}
    end
  end

  defp upsert_documents(_schema_module, [], _backend, _config, _index), do: {:ok, %{}}

  defp upsert_documents(schema_module, documents, backend, config, index) do
    backend.upsert_documents(schema_module, documents, Keyword.put(config, :index_name, index))
  end

  defp batches_for([]), do: 0
  defp batches_for(_documents), do: 1

  defp primary_key(schema_module) do
    case schema_module.__schema__(:primary_key) do
      [field | _rest] -> field
      [] -> Scrypath.document_id_field(schema_module)
    end
  end
end
