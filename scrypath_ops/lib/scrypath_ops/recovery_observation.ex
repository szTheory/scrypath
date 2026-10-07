defmodule ScrypathOps.RecoveryObservation do
  @moduledoc """
  Private, bounded correlation of an accepted retry with its own Meilisearch task.

  Telemetry is used only to identify which task belongs to a worker process. A
  verified outcome still requires fresh authoritative queue, task, and document
  reads by the recovery screens.
  """

  use GenServer

  @handler_id {__MODULE__, :telemetry}
  @worker_names ["Scrypath.Oban.UpsertWorker", "Scrypath.Oban.DeleteWorker"]
  @max_entries 1_024
  @ttl_ms :timer.minutes(10)
  @process_key {__MODULE__, :worker_context}

  @type host_context :: map()
  @type receipt :: map()

  def start_link(opts \\ []) do
    name_opts =
      case Keyword.fetch(opts, :name) do
        {:ok, nil} -> []
        {:ok, name} -> [name: name]
        :error -> [name: __MODULE__]
      end

    GenServer.start_link(__MODULE__, opts, name_opts)
  end

  @doc "Registers accepted work and returns an opaque handle scoped to the supplied host context."
  def register(server \\ __MODULE__, host_context, receipt) do
    GenServer.call(server, {:register, host_context, receipt})
  end

  @doc "Returns a sanitized receipt only when the handle matches its original server context."
  def lookup(server \\ __MODULE__, host_context, handle) do
    GenServer.call(server, {:lookup, host_context, handle})
  end

  @doc "Returns the receipt with identity-only task telemetry attached when it was captured."
  def observe(server \\ __MODULE__, host_context, handle) do
    GenServer.call(server, {:observe, host_context, handle})
  end

  @doc "Invalidates one receipt and any task evidence attached to it."
  def invalidate(server \\ __MODULE__, handle) do
    GenServer.call(server, {:invalidate, handle})
  end

  @doc false
  def handle_event(event, _measurements, metadata, config) do
    try do
      server = Map.get(config, :server, __MODULE__)

      case event do
        [:oban, :job, :start] ->
          capture_job_start(metadata, server)

        [:oban, :job, kind] when kind in [:stop, :exception] ->
          capture_job_end(metadata)

        [:scrypath, :meilisearch, :task_wait, :start] ->
          capture_task_start(metadata)

        [:scrypath, :meilisearch, :task_wait, :stop] ->
          capture_task_stop(metadata, server)

        [:scrypath, :meilisearch, :task_wait, :exception] ->
          capture_task_exception(metadata, server)

        _ ->
          :ok
      end

      :ok
    rescue
      _ -> :ok
    catch
      _, _ -> :ok
    end
  end

  @impl true
  def init(opts) do
    state = %{
      observations: %{},
      recent: %{},
      max_entries: Keyword.get(opts, :max_entries, @max_entries),
      ttl_ms: Keyword.get(opts, :ttl_ms, @ttl_ms),
      attach?: Keyword.get(opts, :attach, true)
    }

    if state.attach? do
      _ = :telemetry.detach(@handler_id)

      :ok =
        :telemetry.attach_many(
          @handler_id,
          [
            [:oban, :job, :start],
            [:oban, :job, :stop],
            [:oban, :job, :exception],
            [:scrypath, :meilisearch, :task_wait, :start],
            [:scrypath, :meilisearch, :task_wait, :stop],
            [:scrypath, :meilisearch, :task_wait, :exception]
          ],
          &__MODULE__.handle_event/4,
          %{server: self()}
        )
    end

    {:ok, state}
  end

  @impl true
  def handle_call({:register, host_context, receipt}, _from, state) do
    now = now_ms()
    {recent, observations} = prune(state.recent, state.observations, now, state.ttl_ms)

    handle = :crypto.strong_rand_bytes(24) |> Base.url_encode64(padding: false)
    identity = receipt_identity(receipt)
    task = Map.get(recent, identity)

    sanitized =
      receipt
      |> Map.take([
        :id,
        :replacement_job,
        :job_id,
        :attempt,
        :operation,
        :schema,
        :index,
        :backend,
        :source_failure,
        :accepted_result,
        :task_uid,
        :endpoint,
        :instance,
        :repo,
        :prefix,
        :node,
        :generation,
        :document_digest,
        :created_at
      ])
      |> Map.put(:source_failure, failure_reference(Map.get(receipt, :source_failure)))
      |> Map.put(:accepted_result, accepted_reference(Map.get(receipt, :accepted_result)))
      |> Map.put(:endpoint, endpoint_value(Map.get(receipt, :endpoint)))
      |> Map.put(:handle, handle)
      |> Map.put(:context, context_digest(host_context))
      |> Map.put(:state, :accepted)
      |> Map.put(:verified, false)
      |> Map.put(:task_uid, (task && task.task_uid) || Map.get(receipt, :task_uid))
      |> Map.put(:telemetry_status, task && task.status)
      |> Map.put(:checked_at, task && task.captured_at)

    entry = %{
      receipt: sanitized,
      context: context_digest(host_context),
      identity: identity,
      inserted_at: now
    }

    observations =
      observations
      |> supersede_source_failure(sanitized.source_failure, context_digest(host_context))
      |> Map.put(handle, entry)
      |> trim(state.max_entries)

    {:reply, {:ok, handle}, %{state | observations: observations, recent: recent}}
  end

  def handle_call({:lookup, host_context, handle}, _from, state) do
    {recent, observations} = prune(state.recent, state.observations, now_ms(), state.ttl_ms)
    state = %{state | recent: recent, observations: observations}
    {:reply, visible_receipt(state, host_context, handle), state}
  end

  def handle_call({:observe, host_context, handle}, _from, state) do
    {recent, observations} = prune(state.recent, state.observations, now_ms(), state.ttl_ms)
    state = %{state | recent: recent, observations: observations}

    case visible_entry(state, host_context, handle) do
      nil ->
        {:reply, :unknown, state}

      %{receipt: receipt, identity: identity} ->
        task = Map.get(state.recent, identity)

        enriched =
          receipt
          |> Map.put(:task_uid, (task && task.task_uid) || Map.get(receipt, :task_uid))
          |> Map.put(
            :telemetry_status,
            (task && task.status) || Map.get(receipt, :telemetry_status)
          )
          |> Map.put(:checked_at, (task && task.captured_at) || Map.get(receipt, :checked_at))
          |> Map.put(:state, observation_state(task && task.status))
          |> Map.put(:verified, false)

        {:reply, enriched, state}
    end
  end

  def handle_call({:invalidate, handle}, _from, state) do
    {:reply, :ok, %{state | observations: Map.delete(state.observations, handle)}}
  end

  @impl true
  def handle_info({:task_evidence, identity, task_uid, status}, state) do
    now = now_ms()
    {recent, observations} = prune(state.recent, state.observations, now, state.ttl_ms)

    evidence = %{
      task_uid: task_uid,
      status: status,
      captured_at: DateTime.utc_now(),
      inserted_at: now
    }

    recent = Map.put(recent, identity, evidence) |> trim(state.max_entries)
    observations = supersede_older_attempts(observations, identity)
    {:noreply, %{state | recent: recent, observations: observations}}
  end

  def handle_info({:job_started, identity}, state) do
    observations = supersede_older_attempts(state.observations, identity)
    recent = remove_older_attempt_evidence(state.recent, identity)
    {:noreply, %{state | observations: observations, recent: recent}}
  end

  def handle_info({:job_ended, identity}, state) do
    observations =
      Map.new(state.observations, fn {handle, entry} ->
        if same_job?(entry.identity, identity) and entry.identity.attempt <= identity.attempt do
          {handle, %{entry | receipt: Map.put(entry.receipt, :telemetry_status, nil)}}
        else
          {handle, entry}
        end
      end)

    {:noreply, %{state | observations: observations}}
  end

  def handle_info(_message, state), do: {:noreply, state}

  defp capture_job_start(metadata, server) do
    job = Map.get(metadata, :job, metadata)
    worker = normalize_worker(field(job, :worker))

    if worker in @worker_names do
      args = field(job, :args) || %{}
      backend = arg(args, "backend")
      operation = operation_for(worker)
      conf = field(metadata, :conf) || field(job, :conf)
      endpoint = endpoint_identity(args, conf)

      if backend == "Elixir.Scrypath.Meilisearch" and operation do
        identity = %{
          id: field(job, :id),
          attempt: field(job, :attempt),
          operation: operation,
          schema: arg(args, "schema"),
          index: arg(args, "index"),
          endpoint: endpoint,
          instance: conf_field(conf, :name),
          repo: conf_field(conf, :repo),
          prefix: conf_field(conf, :prefix) || field(metadata, :prefix) || field(job, :prefix),
          node: node()
        }

        Process.put(@process_key, %{server: server, identity: identity, recent_status: nil})
        send(server, {:job_started, identity})
      else
        Process.delete(@process_key)
      end
    else
      Process.delete(@process_key)
    end

    :ok
  end

  defp capture_task_start(metadata) do
    case Process.get(@process_key) do
      %{server: collector} = context ->
        if is_integer(field(metadata, :task_uid)) do
          Process.put(
            @process_key,
            Map.put(context, :active_task_uid, field(metadata, :task_uid))
          )

          Process.put({@process_key, :server}, collector)
        end

      _ ->
        :ok
    end
  end

  defp capture_task_stop(metadata, server) do
    case Process.get(@process_key) do
      %{identity: identity, server: collector} = context ->
        task_uid = field(metadata, :task_uid) || Map.get(context, :active_task_uid)
        status = normalize_status(field(metadata, :final_status))

        if is_integer(task_uid) do
          send(collector || server, {:task_evidence, identity, task_uid, status})
        end

        Process.put(@process_key, Map.delete(context, :active_task_uid))

      _ ->
        :ok
    end
  end

  defp capture_task_exception(metadata, server) do
    case Process.get(@process_key) do
      %{identity: identity, server: collector} = context ->
        task_uid = field(metadata, :task_uid) || Map.get(context, :active_task_uid)

        if is_integer(task_uid) do
          send(collector || server, {:task_evidence, identity, task_uid, :unknown})
        end

        Process.put(@process_key, Map.delete(context, :active_task_uid))

      _ ->
        :ok
    end
  end

  defp capture_job_end(metadata) do
    job = Map.get(metadata, :job, metadata)

    case Process.get(@process_key) do
      %{identity: identity, server: collector} ->
        if identity.id == field(job, :id) and identity.attempt == field(job, :attempt) do
          Process.delete(@process_key)
          Process.delete({@process_key, :server})
          send(collector, {:job_ended, identity})
        end

      _ ->
        :ok
    end
  end

  defp visible_receipt(state, host_context, handle) do
    case visible_entry(state, host_context, handle) do
      nil -> :unknown
      %{receipt: receipt} -> receipt
    end
  end

  defp visible_entry(state, host_context, handle) when is_binary(handle) do
    expected_context = context_digest(host_context)

    case Map.get(state.observations, handle) do
      %{context: ^expected_context} = entry -> entry
      _ -> nil
    end
  end

  defp visible_entry(_state, _host_context, _handle), do: nil

  defp receipt_identity(receipt) do
    %{
      id:
        Map.get(receipt, :replacement_job) || Map.get(receipt, :job_id) || Map.get(receipt, :id),
      attempt: Map.get(receipt, :attempt, 0),
      operation: Map.get(receipt, :operation),
      schema: Map.get(receipt, :schema),
      index: Map.get(receipt, :index),
      endpoint: endpoint_value(Map.get(receipt, :endpoint)),
      instance: Map.get(receipt, :instance),
      repo: Map.get(receipt, :repo),
      prefix: Map.get(receipt, :prefix),
      node: Map.get(receipt, :node, node())
    }
  end

  defp context_digest(context) do
    context
    |> Map.take([:host, :org, :schema, :generation])
    |> :erlang.term_to_binary()
    |> then(&:crypto.hash(:sha256, &1))
  end

  defp endpoint_identity(args, conf) do
    configured = arg(args, "meilisearch_url")

    value =
      if is_binary(configured) do
        configured
      else
        try do
          Scrypath.Config.resolve!(repo: conf_field(conf, :repo))
          |> Keyword.get(:meilisearch_url)
        rescue
          _ -> nil
        end
      end

    endpoint_value(value)
  end

  defp endpoint_value(value) when is_binary(value) do
    case URI.parse(value) do
      %URI{scheme: scheme, host: host, port: port, path: path} when is_binary(host) ->
        %{
          scheme: scheme,
          host: String.downcase(host),
          port: port,
          path: String.trim_trailing(path || "", "/")
        }

      _ ->
        nil
    end
  end

  defp endpoint_value(_), do: nil

  defp observation_state(:succeeded), do: :accepted
  defp observation_state(status) when status in [:processing, :enqueued], do: :running
  defp observation_state(:failed), do: :failed
  defp observation_state(:cancelled), do: :failed
  defp observation_state(_), do: :accepted

  defp normalize_status(value)
       when value in [:succeeded, :processing, :enqueued, :failed, :cancelled], do: value

  defp normalize_status("succeeded"), do: :succeeded
  defp normalize_status("processing"), do: :processing
  defp normalize_status("enqueued"), do: :enqueued
  defp normalize_status("failed"), do: :failed
  defp normalize_status("cancelled"), do: :cancelled
  defp normalize_status("canceled"), do: :cancelled
  defp normalize_status(_), do: :unknown

  defp prune(recent, observations, now, ttl_ms) do
    {Map.reject(recent, fn {_key, item} -> now - item.inserted_at > ttl_ms end),
     Map.reject(observations, fn {_key, item} -> now - item.inserted_at > ttl_ms end)}
  end

  defp trim(map, max_entries) when map_size(map) <= max_entries, do: map

  defp trim(map, max_entries) do
    map
    |> Enum.sort_by(fn {_key, value} -> value.inserted_at end, :desc)
    |> Enum.take(max_entries)
    |> Map.new()
  end

  defp supersede_older_attempts(observations, identity) do
    Map.new(observations, fn {handle, entry} ->
      if same_job?(entry.identity, identity) and entry.identity.attempt < identity.attempt do
        {handle,
         %{
           entry
           | receipt: entry.receipt |> Map.put(:task_uid, nil) |> Map.put(:telemetry_status, nil)
         }}
      else
        {handle, entry}
      end
    end)
  end

  defp remove_older_attempt_evidence(recent, identity) do
    Map.reject(recent, fn {prior, _evidence} ->
      same_job?(prior, identity) and prior.attempt < identity.attempt
    end)
  end

  defp supersede_source_failure(observations, source_failure, context) do
    source_id = field(source_failure, :id)

    if is_nil(source_id) do
      observations
    else
      Map.reject(observations, fn {_handle, entry} ->
        entry.context == context and field(entry.receipt.source_failure, :id) == source_id and
          field(entry.receipt.source_failure, :source) == field(source_failure, :source)
      end)
    end
  end

  defp failure_reference(%{} = source) do
    source
    |> Map.take([
      :source,
      :id,
      :task_uid,
      :index,
      :operation,
      "source",
      "id",
      "task_uid",
      "index",
      "operation"
    ])
  end

  defp failure_reference(source) when is_integer(source) or is_binary(source), do: source
  defp failure_reference(_), do: nil

  defp accepted_reference(%{} = accepted) do
    %{job_id: field(accepted, :id) || field(accepted, :job_id)}
  end

  defp accepted_reference(accepted) when is_integer(accepted) or is_binary(accepted),
    do: %{job_id: accepted}

  defp accepted_reference(_), do: nil

  defp same_job?(left, right),
    do:
      left.id == right.id and left.instance == right.instance and left.repo == right.repo and
        left.prefix == right.prefix

  defp field(map, key) when is_map(map), do: Map.get(map, key)
  defp field(_, _), do: nil
  defp conf_field(map, key), do: field(map, key)

  defp arg(map, key) when is_map(map),
    do: Map.get(map, key) || Map.get(map, String.to_existing_atom(key))

  defp arg(_, _), do: nil

  defp normalize_worker(worker) when is_binary(worker), do: String.trim_leading(worker, "Elixir.")
  defp normalize_worker(_), do: nil

  defp operation_for("Scrypath.Oban.UpsertWorker"), do: :upsert
  defp operation_for("Scrypath.Oban.DeleteWorker"), do: :delete
  defp operation_for(_), do: nil

  defp now_ms, do: System.monotonic_time(:millisecond)
end
