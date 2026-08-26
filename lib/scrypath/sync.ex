defmodule Scrypath.Sync do
  @moduledoc false

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
    documents = Enum.map(records, &Projection.document(schema_module, &1))

    metadata =
      Telemetry.common_metadata(schema_module, config, document_count: length(documents))

    Telemetry.span([:scrypath, :sync, :upsert], metadata, fn ->
      result =
        case documents do
          [] -> noop_result(config)
          _documents -> dispatch_upsert(schema_module, documents, config)
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
      Telemetry.common_metadata(schema_module, config, document_count: length(document_ids))

    Telemetry.span([:scrypath, :sync, :delete], metadata, fn ->
      result =
        case document_ids do
          [] -> noop_result(config)
          _document_ids -> dispatch_delete(schema_module, document_ids, config)
        end

      {result, Telemetry.stop_metadata(result)}
    end)
  end

  defp dispatch_upsert(schema_module, documents, config) do
    case Keyword.fetch!(config, :sync_mode) do
      :oban ->
        config
        |> Config.ensure_oban_ready!()
        |> then(&Enqueue.enqueue_upsert(schema_module, documents, &1))
        |> decorate_result(config)

      _other ->
        backend_upsert_documents(schema_module, documents, config)
        |> normalize_write_result(documents, config)
        |> maybe_wait_for_task(config)
        |> decorate_result(config)
    end
  end

  defp dispatch_delete(schema_module, document_ids, config) do
    case Keyword.fetch!(config, :sync_mode) do
      :oban ->
        config
        |> Config.ensure_oban_ready!()
        |> then(&Enqueue.enqueue_delete(schema_module, document_ids, &1))
        |> decorate_result(config)

      _other ->
        backend_delete_documents(schema_module, document_ids, config)
        |> normalize_write_result(document_ids, config)
        |> maybe_wait_for_task(config)
        |> decorate_result(config)
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
  end

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
      state: Map.get(task.metadata, :oban_state)
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
