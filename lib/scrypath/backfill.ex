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

  defp run_batch(state, rows) do
    %{schema: schema_module, config: config, index: index, cols: cols} = state
    values = cursor_values(cols, List.last(rows))
    documents = Enum.map(rows, &Projection.document(schema_module, &1))

    with {:ok, backend_result} <-
           upsert_documents(
             schema_module,
             documents,
             Keyword.fetch!(config, :backend),
             config,
             index
           ) do
      result =
        Operations.normalize_write_result(backend_result,
          mode: Keyword.fetch!(config, :sync_mode),
          document_ids: Enum.map(documents, & &1.id),
          document_count: length(documents),
          index: index
        )

      batch_result =
        batch_result(result, index, length(documents), public_cursor(cols, values))

      run_batches(%{
        state
        | keyset: Enum.zip(cols, values),
          total: state.total + length(documents),
          acc: [batch_result | state.acc]
      })
    end
  end

  defp final_result(state) do
    %{
      index: state.index,
      batches: length(state.acc),
      documents: state.total,
      mode: Keyword.fetch!(state.config, :sync_mode),
      batch_results: Enum.reverse(state.acc)
    }
  end

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

  defp pk_columns(schema_module) do
    case schema_module.__schema__(:primary_key) do
      [] -> [Scrypath.Schema.Metadata.document_id(schema_module)]
      cols -> cols
    end
  end
end
