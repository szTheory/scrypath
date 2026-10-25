defmodule Scrypath.Backfill do
  @moduledoc false

  import Ecto.Query

  alias Scrypath.Chunks
  alias Scrypath.Loader
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
    cols = pk_columns(schema_module)

    run_batches(%{
      base_query: base_query(config, schema_module, cols),
      schema: schema_module,
      cols: cols,
      batch_size: Keyword.fetch!(config, :batch_size),
      config: config,
      index: index,
      repo: Keyword.fetch!(config, :repo),
      keyset: nil,
      total: 0,
      removed: 0,
      omitted: 0,
      fresh_target?: Keyword.fetch!(config, :_scrypath_fresh_target),
      acc: []
    })
  end

  defp run_batches(state) do
    rows =
      state.base_query
      |> keyset_after(state.keyset)
      |> limit(^state.batch_size)
      |> state.repo.all()
      |> dedupe_rows(state.cols)

    case rows do
      [] -> {:ok, final_result(state)}
      rows -> run_batch(state, rows)
    end
  end

  # The cursor always comes from the scoped rows, never from the loader output,
  # so a batch whose records were all omitted still advances paging.
  defp run_batch(state, rows) do
    %{schema: schema_module, config: config, index: index, cols: cols} = state
    values = cursor_values(cols, List.last(rows))

    with {:ok, records, omitted} <- Loader.prepare_records(schema_module, rows, config),
         documents = Enum.map(records, &Projection.document(schema_module, &1)),
         removals = if(state.fresh_target?, do: [], else: omitted),
         {:ok, upsert} <- write(:upsert, schema_module, documents, config, index),
         {:ok, delete} <- write(:delete, schema_module, removals, config, index) do
      batch_result =
        %{
          index: result_index(List.last(upsert), index),
          documents: length(documents),
          removed: length(removals),
          last_primary_key: public_cursor(cols, values),
          task: task_of(List.last(upsert)),
          tasks: upsert |> Enum.map(&task_of/1) |> Enum.reject(&is_nil/1),
          delete_task: task_of(List.last(delete))
        }
        |> maybe_drop_nil(:task)
        |> maybe_drop_nil(:delete_task)

      run_batches(%{
        state
        | keyset: Enum.zip(cols, values),
          total: state.total + length(documents),
          removed: state.removed + length(removals),
          omitted: state.omitted + length(omitted),
          acc: [batch_result | state.acc]
      })
    end
  end

  defp final_result(state) do
    result = %{
      index: state.index,
      batches: length(state.acc),
      documents: state.total,
      removed: state.removed,
      mode: Keyword.fetch!(state.config, :sync_mode),
      batch_results: Enum.reverse(state.acc)
    }

    # A fresh reindex target holds none of the omitted ids, so they are only
    # counted; a live index has them removed and reports them as removed.
    if state.fresh_target?, do: Map.put(result, :omitted, state.omitted), else: result
  end

  # Empty lists are never sent to the backend; a skipped write has no chunk results.
  # `:batch_size` only sets the page size: each page is written in chunks of at most
  # `Chunks.max_ids/0` documents (or ids), and the first failed chunk halts the backfill.
  # Chunks keep the page's primary-key order (rows are already deduped by key), so no
  # Chunks.by_id/ids re-sort is applied here.
  defp write(_kind, _schema_module, [], _config, _index), do: {:ok, []}

  defp write(:upsert, schema_module, documents, config, index) do
    documents
    |> Enum.chunk_every(Chunks.max_ids())
    |> Chunks.reduce_ok(fn chunk ->
      with {:ok, backend_result} <-
             upsert_documents(schema_module, chunk, backend(config), config, index) do
        {:ok, normalize(backend_result, Enum.map(chunk, & &1.id), config, index)}
      end
    end)
  end

  defp write(:delete, schema_module, ids, config, index) do
    ids
    |> Enum.chunk_every(Chunks.max_ids())
    |> Chunks.reduce_ok(fn chunk ->
      with {:ok, backend_result} <-
             delete_documents(schema_module, chunk, backend(config), config, index) do
        {:ok, normalize(backend_result, chunk, config, index)}
      end
    end)
  end

  defp normalize(backend_result, ids, config, index) do
    Operations.normalize_write_result(backend_result,
      mode: Keyword.fetch!(config, :sync_mode),
      document_ids: ids,
      document_count: length(ids),
      index: index
    )
  end

  defp backend(config), do: Keyword.fetch!(config, :backend)

  defp result_index(%Result{} = result, index), do: Map.get(result.metadata, :index) || index
  defp result_index(nil, index), do: index

  defp task_of(%Result{task: task}), do: public_task(task)
  defp task_of(nil), do: nil

  # The caller's :query decides which rows are in scope (where/join); paging,
  # projection and preloading stay owned by backfill.
  defp base_query(config, schema_module, cols) do
    (config[:query] || schema_module)
    |> exclude(:order_by)
    |> exclude(:limit)
    |> exclude(:offset)
    |> exclude(:select)
    |> exclude(:preload)
    |> exclude_nil_document_ids(schema_module, cols)
    |> order_by(^Enum.map(cols, &{:asc, &1}))
  end

  # Without an Ecto primary key, paging falls back to the document id column,
  # which the database does not guarantee to be non-nil.
  defp exclude_nil_document_ids(query, schema_module, [col]) do
    case schema_module.__schema__(:primary_key) do
      [] -> where(query, [r], not is_nil(field(r, ^col)))
      _cols -> query
    end
  end

  defp exclude_nil_document_ids(query, _schema_module, _cols), do: query

  # A fanned-out caller join can repeat a row; keep the first occurrence so
  # database order (and therefore the last row) is unchanged.
  defp dedupe_rows(rows, cols) do
    Enum.uniq_by(rows, fn row -> Enum.map(cols, &Map.fetch!(row, &1)) end)
  end

  # The paging cursor is the key of the last row the database returned, in
  # primary-key column order. Keys are never sorted in Elixir; ORDER BY decides.
  defp cursor_values(cols, last_row) do
    Enum.map(cols, fn col ->
      case Map.fetch!(last_row, col) do
        nil ->
          raise ArgumentError,
                "backfill cursor column #{inspect(col)} is nil on the last row of a batch; " <>
                  "columns used for backfill paging must not be nil"

        value ->
          value
      end
    end)
  end

  # Single-column keys keep a scalar cursor; composite keys report a keyword
  # list in primary-key order (the `Ecto.primary_key/1` shape).
  defp public_cursor([_single], [value]), do: value
  defp public_cursor(cols, values), do: Enum.zip(cols, values)

  # The single seam for "rows after this key". Values are always pinned params
  # against schema-typed fields, so Ecto casts them by the field type.
  defp keyset_after(query, nil), do: query
  defp keyset_after(query, pairs), do: where(query, ^keyset_predicate(pairs))

  defp keyset_predicate([{col, value}]), do: dynamic([r], field(r, ^col) > ^value)

  defp keyset_predicate([{col, value} | _rest] = pairs),
    do: dynamic([r], field(r, ^col) >= ^value and ^expand(pairs))

  defp expand([{col, value}]), do: dynamic([r], field(r, ^col) > ^value)

  defp expand([{col, value} | rest]),
    do: dynamic([r], field(r, ^col) > ^value or (field(r, ^col) == ^value and ^expand(rest)))

  defp upsert_documents(schema_module, documents, backend, config, index) do
    config = Keyword.put(config, :index_name, index)

    case backend do
      Scrypath.Meilisearch ->
        MeilisearchOperations.upsert_documents(schema_module, documents, config)

      _other ->
        backend.upsert_documents(schema_module, documents, config)
    end
  end

  defp delete_documents(schema_module, ids, backend, config, index) do
    config = Keyword.put(config, :index_name, index)

    case backend do
      Scrypath.Meilisearch ->
        MeilisearchOperations.delete_documents(schema_module, ids, config)

      _other ->
        backend.delete_documents(schema_module, ids, config)
    end
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

  defp pk_columns(schema_module) do
    case schema_module.__schema__(:primary_key) do
      [] -> [Scrypath.Schema.Metadata.document_id(schema_module)]
      cols -> cols
    end
  end
end
