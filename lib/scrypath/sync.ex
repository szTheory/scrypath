defmodule Scrypath.Sync do
  @moduledoc false

  alias Scrypath.Chunks
  alias Scrypath.Config
  alias Scrypath.Identity
  alias Scrypath.Meilisearch.Operations, as: MeilisearchOperations
  alias Scrypath.Meilisearch.Tasks
  alias Scrypath.Oban.Enqueue
  alias Scrypath.Operations
  alias Scrypath.Operations.Result
  alias Scrypath.Operations.Task, as: OperationTask
  alias Scrypath.Projection
  alias Scrypath.Sync.RelatedEnqueue
  alias Scrypath.Telemetry

  @spec sync_record(module(), struct() | map(), keyword()) :: {:ok, term()} | {:error, term()}
  def sync_record(schema_module, record, opts \\ []) do
    sync_records(schema_module, [record], opts)
  end

  @spec sync_records(module(), [struct() | map()], keyword()) :: {:ok, term()} | {:error, term()}
  def sync_records(schema_module, records, opts \\ []) when is_list(records) do
    config = Config.resolve!(opts)

    metadata =
      Telemetry.common_metadata(schema_module, config,
        document_count: distinct_record_count(schema_module, records)
      )

    Telemetry.span([:scrypath, :sync, :upsert], metadata, fn ->
      result =
        case records do
          [] -> noop_result(config)
          _records -> dispatch_upsert(schema_module, records, config)
        end

      {result, Telemetry.stop_metadata(result)}
    end)
  end

  @spec sync_related(module(), struct() | [struct()], keyword()) ::
          {:ok, term()} | {:error, term()}
  def sync_related(schema_module, records, opts \\ []) do
    fan_out_key =
      Keyword.get(opts, :fan_out) ||
        raise ArgumentError, "opts[:fan_out] is required"

    fan_outs = Scrypath.Schema.Metadata.fan_outs(schema_module)

    fan_out_config =
      Keyword.get(fan_outs, fan_out_key) ||
        raise ArgumentError,
              "fan_out #{inspect(fan_out_key)} is not configured on #{inspect(schema_module)}"

    config = Config.resolve!(opts)

    # No triggers means nothing to resolve: never call the resolver with an empty list.
    case List.wrap(records) do
      [] ->
        noop_result(config)

      _triggers ->
        do_sync_related(schema_module, records, fan_out_key, fan_out_config, config, opts)
    end
  end

  defp do_sync_related(schema_module, records, fan_out_key, fan_out_config, config, opts) do
    case Keyword.fetch!(config, :sync_mode) do
      :oban ->
        config
        |> Config.ensure_oban_ready!()
        |> then(&RelatedEnqueue.enqueue(schema_module, records, fan_out_key, &1))
        |> decorate_result(config)

      _other ->
        inline_resolve_and_sync(
          schema_module,
          records,
          fan_out_key,
          fan_out_config,
          config,
          opts
        )
    end
  end

  defp inline_resolve_and_sync(
         schema_module,
         records,
         fan_out_key,
         fan_out_config,
         config,
         opts
       ) do
    records_list = List.wrap(records)

    metadata =
      Telemetry.common_metadata(schema_module, config,
        fan_out: fan_out_key,
        document_count: length(records_list)
      )

    Telemetry.span([:scrypath, :sync, :related, :resolve], metadata, fn ->
      target_module = Keyword.fetch!(fan_out_config, :target)
      {mod, fun, mfa_args} = Keyword.fetch!(fan_out_config, :resolver)

      resolved_records = apply(mod, fun, [records_list] ++ mfa_args)

      result = sync_records(target_module, resolved_records, opts)

      {result, Telemetry.stop_metadata(result)}
    end)
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

    metadata =
      Telemetry.common_metadata(schema_module, config,
        document_count: Chunks.distinct_count(document_ids)
      )

    Telemetry.span([:scrypath, :sync, :delete], metadata, fn ->
      result =
        case document_ids do
          [] -> noop_result(config)
          _document_ids -> dispatch_delete(schema_module, document_ids, config)
        end

      {result, Telemetry.stop_metadata(result)}
    end)
  end

  # The span start reports the same deduped count as the stop metadata and the result:
  # dispatch dedupes records by document id before chunking. A record whose id cannot be
  # read falls back to the raw length here; dispatch then raises inside the span, so the
  # failure is still reported as the span's exception.
  defp distinct_record_count(schema_module, records) do
    records
    |> Enum.uniq_by(&Chunks.id_key(Identity.document_id(schema_module, &1)))
    |> length()
  rescue
    _error -> length(records)
  end

  # Oban jobs carry document ids and load current records when they run, so only
  # inline and manual sync project documents here.
  defp dispatch_upsert(schema_module, records, config) do
    case Keyword.fetch!(config, :sync_mode) do
      :oban ->
        document_ids = Identity.document_ids(schema_module, records)

        config
        |> Config.ensure_oban_ready!()
        |> then(&Enqueue.enqueue_upsert(schema_module, document_ids, &1))
        |> decorate_result(config)

      _other ->
        records
        |> Enum.map(&Projection.document(schema_module, &1))
        |> Chunks.by_id(& &1.id)
        |> Chunks.reduce_ok(fn documents ->
          backend_upsert_documents(schema_module, documents, config)
          |> normalize_write_result(documents, config)
          |> maybe_wait_for_task(config)
          |> tag_chunk(documents)
        end)
        |> combine_chunks(config)
    end
  end

  # Each chunk waits on its own backend task inside the per-chunk pipeline, so a failed
  # chunk task halts the reducer before the next chunk is sent.
  defp tag_chunk({:ok, result}, items), do: {:ok, {item_ids(items), result}}
  defp tag_chunk(other, _items), do: other

  # One chunk keeps today's exact result (including any backend map keys) plus a
  # one-element `tasks`. Two or more chunks build the result fresh so no single chunk's
  # backend_result claims to cover the whole call.
  defp combine_chunks({:ok, [{_ids, %Result{} = result}]}, config) do
    decorate_result({:ok, %Result{result | tasks: List.wrap(result.task)}}, config)
  end

  defp combine_chunks({:ok, [{_ids, result}]}, config), do: decorate_result({:ok, result}, config)

  defp combine_chunks({:ok, [_first, _second | _rest] = chunks}, config) do
    {_ids, last} = List.last(chunks)
    last_result = chunk_result(last)
    tasks = Enum.flat_map(chunks, fn {_ids, result} -> List.wrap(chunk_result(result).task) end)

    result =
      Result.new(
        mode: Keyword.fetch!(config, :sync_mode),
        status: result_status(config),
        document_ids: Enum.flat_map(chunks, fn {ids, result} -> chunk_ids(ids, result) end),
        document_count:
          Enum.reduce(chunks, 0, fn {ids, result}, sum -> sum + chunk_count(ids, result) end),
        task: last_result.task,
        tasks: tasks,
        metadata: maybe_put(%{}, :index, Map.get(last_result.metadata, :index))
      )

    decorate_result({:ok, result}, config)
  end

  defp combine_chunks({:error, _reason} = error, _config), do: error

  # A backend may answer `{:ok, non_map}` (the test fake returns an id list); that chunk
  # counts as a chunk with no task.
  defp chunk_result(%Result{} = result), do: result
  defp chunk_result(_other), do: %Result{mode: nil, status: nil}

  defp chunk_ids(_ids, %Result{document_ids: [_ | _] = document_ids}), do: document_ids
  defp chunk_ids(ids, _result), do: ids

  defp chunk_count(_ids, %Result{document_count: count}) when count > 0, do: count
  defp chunk_count(ids, _result), do: length(ids)

  defp dispatch_delete(schema_module, document_ids, config) do
    case Keyword.fetch!(config, :sync_mode) do
      :oban ->
        config
        |> Config.ensure_oban_ready!()
        |> then(&Enqueue.enqueue_delete(schema_module, document_ids, &1))
        |> decorate_result(config)

      _other ->
        document_ids
        |> Chunks.ids()
        |> Chunks.reduce_ok(fn ids ->
          backend_delete_documents(schema_module, ids, config)
          |> normalize_write_result(ids, config)
          |> maybe_wait_for_task(config)
          |> tag_chunk(ids)
        end)
        |> combine_chunks(config)
    end
  end

  defp maybe_wait_for_task({:ok, %Result{task: %OperationTask{} = task} = result}, config) do
    case Keyword.fetch!(config, :sync_mode) do
      :inline when task.source == :meilisearch ->
        case Tasks.wait_for_task(task, config) do
          {:ok, waited_task} -> {:ok, %{result | task: waited_task}}
          {:error, reason} -> {:error, public_wait_error(reason)}
        end

      :inline ->
        {:ok, result}

      :manual ->
        {:ok, result}

      :oban ->
        {:ok, result}
    end
  end

  defp maybe_wait_for_task(result, _config), do: result

  defp backend_upsert_documents(schema_module, documents, config) do
    case Config.fetch_backend!(config) do
      Scrypath.Meilisearch ->
        MeilisearchOperations.upsert_documents(schema_module, documents, config)

      backend ->
        backend.upsert_documents(schema_module, documents, config)
    end
  end

  defp backend_delete_documents(schema_module, document_ids, config) do
    case Config.fetch_backend!(config) do
      Scrypath.Meilisearch ->
        MeilisearchOperations.delete_documents(schema_module, document_ids, config)

      backend ->
        backend.delete_documents(schema_module, document_ids, config)
    end
  end

  defp decorate_result({:ok, %Result{} = result}, config) do
    result =
      %Result{
        result
        | mode: Keyword.fetch!(config, :sync_mode),
          status: result_status(config)
      }

    {:ok, public_result(result)}
  end

  defp decorate_result(result, _config), do: result

  defp noop_result(config) do
    {:ok,
     Result.new(
       mode: Keyword.fetch!(config, :sync_mode),
       status: :noop,
       document_ids: [],
       document_count: 0
     )}
  end

  defp result_status(config) do
    case Keyword.fetch!(config, :sync_mode) do
      :inline -> :completed
      :manual -> :accepted
      :oban -> :accepted
    end
  end

  defp public_result(%Result{} = result) do
    result.metadata
    |> Map.get(:backend_result, %{})
    |> Map.merge(%{
      mode: result.mode,
      status: result.status,
      document_ids: result.document_ids,
      document_count: result.document_count
    })
    |> maybe_put(:index, Map.get(result.metadata, :index))
    |> maybe_put(:oban, Map.get(result.metadata, :oban))
    |> maybe_put_operation_reference(result.task)
    |> Map.put(:tasks, Enum.map(result.tasks, &public_task/1))
  end

  defp public_task(%OperationTask{kind: :backend_task} = task), do: public_backend_task(task)
  defp public_task(%OperationTask{kind: :queue_job} = task), do: public_job(task)
  defp public_task(%OperationTask{} = task), do: OperationTask.to_public_sync(task)

  defp maybe_put_operation_reference(result, %OperationTask{kind: :backend_task} = task) do
    Map.put(result, :task, public_backend_task(task))
  end

  defp maybe_put_operation_reference(result, %OperationTask{kind: :queue_job} = task) do
    Map.put(result, :job, public_job(task))
  end

  defp maybe_put_operation_reference(result, _task), do: result

  defp public_wait_error({reason, %OperationTask{} = task}) do
    {reason, public_backend_task(task)}
  end

  defp public_wait_error(reason), do: reason

  defp public_backend_task(%OperationTask{} = task) do
    %{
      uid: task.id,
      status: task.state,
      index_uid: Map.get(task.reference, :index_uid),
      type: Map.get(task.metadata, :type),
      raw: task.raw
    }
  end

  defp public_job(%OperationTask{} = task) do
    %{
      id: task.id,
      worker: Map.get(task.reference, :worker),
      queue: Map.get(task.reference, :queue),
      state: Map.get(task.metadata, :oban_state),
      conflict?: Map.get(task.metadata, :conflict?, false)
    }
    |> maybe_put(:attempt, job_raw_value(task, :attempt))
    |> maybe_put(:max_attempts, job_raw_value(task, :max_attempts))
  end

  defp job_raw_value(%OperationTask{raw: raw}, key) when is_map(raw), do: Map.get(raw, key)
  defp job_raw_value(_task, _key), do: nil

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp normalize_write_result({:ok, result}, items, config) when is_map(result) do
    {:ok,
     Operations.normalize_write_result(result,
       mode: Keyword.fetch!(config, :sync_mode),
       document_ids: item_ids(items),
       document_count: length(items)
     )}
  end

  defp normalize_write_result(result, _items, _config), do: result

  defp item_ids([%Scrypath.Document{} | _rest] = documents), do: Enum.map(documents, & &1.id)
  defp item_ids(document_ids), do: document_ids
end
