defmodule Scrypath.Backfill do
  @moduledoc false

  import Ecto.Query

  alias Scrypath.Meilisearch.Operations, as: MeilisearchOperations
  alias Scrypath.Options
  alias Scrypath.Operations
  alias Scrypath.Operations.Result
  alias Scrypath.Operations.Task
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
               upsert_documents(
                 schema_module,
                 documents,
                 Keyword.fetch!(config, :backend),
                 config,
                 index
               ),
             result <-
               Operations.normalize_write_result(backend_result,
                 mode: Keyword.fetch!(config, :sync_mode),
                 document_ids: Enum.map(documents, & &1.id),
                 document_count: length(documents),
                 index: index
               ) do
          batch_result =
            batch_result(
              result,
              index,
              length(documents),
              last_primary_key
            )

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
    config = Keyword.put(config, :index_name, index)

    case backend do
      Scrypath.Meilisearch ->
        MeilisearchOperations.upsert_documents(schema_module, documents, config)

      _other ->
        backend.upsert_documents(schema_module, documents, config)
    end
  end

  defp batch_result(%Result{} = result, index, documents, last_primary_key) do
    %{
      index: Map.get(result.metadata, :index, index),
      documents: documents,
      last_primary_key: last_primary_key,
      task: public_task(result.task)
    }
    |> maybe_drop_nil(:task)
  end

  defp public_task(%Task{} = task) do
    %{
      uid: task.id,
      status: task.state,
      index_uid: Map.get(task.reference, :index_uid),
      type: Map.get(task.metadata, :type),
      raw: task.raw
    }
  end

  defp public_task(_task), do: nil

  defp maybe_drop_nil(map, key) do
    case Map.get(map, key) do
      nil -> Map.delete(map, key)
      _value -> map
    end
  end

  defp last_primary_key([]), do: nil

  defp last_primary_key([%{last_primary_key: last_primary_key} | _rest]) do
    last_primary_key
  end

  defp primary_key(schema_module) do
    case schema_module.__schema__(:primary_key) do
      [field | _rest] -> field
      [] -> Scrypath.Schema.Metadata.document_id(schema_module)
    end
  end
end
