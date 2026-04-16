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
    backend = Keyword.fetch!(config, :backend)
    index = Keyword.get(config, :index_name) || backend.index_name(schema_module, config)
    primary_key = primary_key(schema_module)
    batch_size = Keyword.fetch!(config, :batch_size)

    config
    |> base_query(schema_module, primary_key)
    |> run_batches(schema_module, primary_key, batch_size, config, index, 0, [])
  end

  defp run_batches(base_query, schema_module, primary_key, batch_size, config, index, total, acc) do
    repo = Keyword.fetch!(config, :repo)
    cursor = last_primary_key(acc)

    records =
      base_query
      |> batch_query(primary_key, cursor, batch_size)
      |> repo.all()

    case records do
      [] ->
        {:ok,
         %{
           index: index,
           batches: length(acc),
           documents: total,
           mode: Keyword.fetch!(config, :sync_mode),
           batch_results: Enum.reverse(acc)
         }}

      _records ->
        documents = Enum.map(records, &Projection.document(schema_module, &1))
        last_primary_key = Map.fetch!(List.last(records), primary_key)

        with {:ok, backend_result} <-
               upsert_documents(schema_module, documents, Keyword.fetch!(config, :backend), config, index) do
          batch_result = %{
            index: Map.get(backend_result, :index, index),
            documents: length(documents),
            last_primary_key: last_primary_key
          }

          run_batches(
            base_query,
            schema_module,
            primary_key,
            batch_size,
            config,
            index,
            total + length(documents),
            [batch_result | acc]
          )
        end
    end
  end

  defp base_query(config, schema_module, primary_key) do
    (config[:query] || schema_module)
    |> exclude(:order_by)
    |> exclude(:limit)
    |> order_by([record], asc: field(record, ^primary_key))
  end

  defp batch_query(query, _primary_key, nil, batch_size) do
    query
    |> limit(^batch_size)
  end

  defp batch_query(query, primary_key, cursor, batch_size) do
    query
    |> where([record], field(record, ^primary_key) > ^cursor)
    |> limit(^batch_size)
  end

  defp upsert_documents(schema_module, documents, backend, config, index) do
    backend.upsert_documents(schema_module, documents, Keyword.put(config, :index_name, index))
  end

  defp last_primary_key([]), do: nil

  defp last_primary_key([%{last_primary_key: last_primary_key} | _rest]) do
    last_primary_key
  end

  defp primary_key(schema_module) do
    case schema_module.__schema__(:primary_key) do
      [field | _rest] -> field
      [] -> Scrypath.document_id_field(schema_module)
    end
  end
end
