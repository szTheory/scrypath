defmodule ScrypathOpsWeb.SyncDriftLive do
  @moduledoc """
  Read-only sync and index contract drift using `Scrypath.reconcile_sync/2` and
  `Scrypath.index_contract_drift/2`.

  On mount, **reconcile** loads automatically (without `include_index_contract_drift`).
  **Index contract drift** loads only after the explicit control.
  """

  use ScrypathOpsWeb, :live_view

  alias ScrypathOps.Integrations.Sigra.Gating
  alias ScrypathOps.OperatorSelection
  alias ScrypathOps.PromotionEligibility
  alias ScrypathOps.RecoveryObservation
  alias Scrypath.Meilisearch.Tasks
  alias Scrypath.Operations.Task, as: OperationTask

  @promotion_observation_timeout 20_000
  @promotion_observation_input_assigns [
    :__changed__,
    :flash,
    :selected_schema,
    :scrypath_opts,
    :context_generation,
    :reconcile_result,
    :reconcile_loaded_at,
    :reconcile_generation,
    :reconcile_error,
    :drift_result,
    :drift_loaded_at,
    :drift_generation,
    :drift_error,
    :drift_loading,
    :promotion_identity,
    :promotion_status,
    :promotion_document_observation,
    :promotion_observation_error,
    :recovery_handle,
    :recovery_origin_generation,
    :operator_context,
    :current_scope
  ]
  @promotion_observation_assigns [
    :reconcile_result,
    :reconcile_loaded_at,
    :reconcile_generation,
    :reconcile_error,
    :drift_result,
    :drift_loaded_at,
    :drift_generation,
    :drift_error,
    :promotion_status,
    :promotion_document_observation,
    :promotion_observation_error
  ]

  @impl true
  def mount(_params, _session, socket) do
    allowlist = ScrypathOps.Schemas.allowlist()
    scrypath_opts = ScrypathOps.Schemas.scrypath_opts()

    socket =
      socket
      |> assign(:page_title, "Sync and drift")
      |> assign(:schema_allowlist, allowlist)
      |> assign(:scrypath_opts, scrypath_opts)
      |> assign(:selected_schema, nil)
      |> assign(:selection_error, nil)
      |> assign(:context_generation, 0)
      |> assign(:reconcile_result, nil)
      |> assign(:reconcile_loaded_at, nil)
      |> assign(:reconcile_generation, nil)
      |> assign(:reconcile_error, nil)
      |> assign(:drift_result, nil)
      |> assign(:drift_loaded_at, nil)
      |> assign(:drift_generation, nil)
      |> assign(:drift_error, nil)
      |> assign(:drift_loading, false)
      |> assign(:recovery_handle, nil)
      |> assign(:recovery_origin_generation, nil)
      |> assign(:recovery_status, nil)
      |> assign(:recovery_evidence, nil)
      |> assign(:recovery_document_observation, nil)
      |> assign(:recovery_observation_error, nil)
      |> assign(:recovery_checked_at, nil)
      |> assign(:recovery_loading, false)
      |> assign(:promotion_task_id, nil)
      |> assign(:promotion_status, nil)
      |> assign(:promotion_loading, false)
      |> assign(:promotion_identity, nil)
      |> assign(:promotion_document_observation, nil)
      |> assign(:promotion_observation_error, nil)
      |> assign(:promotion_task_read_error, nil)
      |> assign(:confirm_swap?, false)
      |> assign(:promotion_eligibility, {:blocked, :reconcile_not_current})

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    allowlist = ScrypathOps.Schemas.allowlist()
    resolution = OperatorSelection.resolve(params, allowlist)

    selected =
      case resolution do
        {:ok, module} -> module
        _ -> nil
      end

    error =
      case resolution do
        :setup -> :no_schemas
        :unavailable -> :unavailable
        _ -> nil
      end

    changed? =
      selected != socket.assigns.selected_schema or error != socket.assigns.selection_error

    socket =
      socket
      |> assign(:schema_allowlist, allowlist)
      |> assign(:selected_schema, selected)
      |> assign(:selection_error, error)
      |> maybe_advance_generation(changed?)

    socket =
      if selected do
        socket
        |> load_reconcile_on_mount()
        |> maybe_start_recovery(
          Map.get(params, "recovery"),
          Map.get(params, "recovery_generation")
        )
      else
        socket
        |> clear_context_results()
        |> assign(:drift_error, error)
      end

    {:noreply, socket}
  end

  defp load_reconcile_on_mount(socket) do
    case {socket.assigns.selected_schema,
          Keyword.has_key?(socket.assigns.scrypath_opts, :backend)} do
      {nil, _} ->
        socket

      {_mod, false} ->
        socket

      {mod, true} ->
        opts = socket.assigns.scrypath_opts

        case Scrypath.reconcile_sync(mod, opts) do
          {:ok, rep} ->
            socket
            |> assign(:reconcile_result, rep)
            |> assign(:reconcile_loaded_at, DateTime.utc_now())
            |> assign(:reconcile_generation, socket.assigns.context_generation)
            |> assign(:reconcile_error, nil)
            |> refresh_promotion_eligibility()

          {:error, reason} ->
            socket
            |> assign(:reconcile_result, nil)
            |> assign(:reconcile_loaded_at, nil)
            |> assign(:reconcile_generation, nil)
            |> assign(:reconcile_error, reason)
            |> refresh_promotion_eligibility()
            |> put_flash(:error, "Reconcile failed: #{inspect(reason)}")
        end
    end
  end

  @impl true
  def handle_event("refresh_reconcile", _params, socket) do
    if current_selection?(socket) do
      socket = refresh_reconcile(socket)

      socket =
        if is_nil(socket.assigns.reconcile_error),
          do: put_flash(socket, :info, "Sync and queue status refreshed."),
          else: socket

      {:noreply, socket}
    else
      {:noreply, unavailable(socket)}
    end
  end

  def handle_event("refresh_promotion_checks", _params, socket) do
    if current_selection?(socket) do
      socket = socket |> refresh_reconcile() |> refresh_drift() |> refresh_promotion_eligibility()

      socket =
        case socket.assigns.promotion_task_id do
          task_id when not is_nil(task_id) -> start_promotion_refresh(socket, task_id)
          _ -> socket
        end

      {:noreply, socket}
    else
      {:noreply, unavailable(socket)}
    end
  end

  def handle_event("refresh_recovery_status", _params, socket) do
    case Map.get(socket.assigns, :recovery_handle) do
      handle when is_binary(handle) ->
        if current_selection?(socket) do
          {:noreply, start_recovery_observation(socket, handle)}
        else
          {:noreply, unavailable(socket)}
        end

      _ ->
        {:noreply,
         socket
         |> assign(:recovery_observation_error, :receipt_unavailable)
         |> assign(:recovery_loading, false)}
    end
  end

  def handle_event("load_drift", _params, socket) do
    # Two-step so the loading skeleton paints before the bounded backend read runs.
    # The contract-drift call is fast but synchronous; deferring it to handle_info/2
    # lets LiveView push the `:drift_loading` frame first. Event name unchanged.
    if current_selection?(socket) do
      send(self(), {:run_drift, socket.assigns.context_generation})

      {:noreply,
       socket
       |> assign(:drift_loading, true)
       |> assign(:promotion_eligibility, {:blocked, :check_in_progress})}
    else
      {:noreply, unavailable(socket)}
    end
  end

  def handle_event("select_schema", %{"schema" => mod_str}, socket) do
    case OperatorSelection.resolve(%{"schema" => mod_str}, ScrypathOps.Schemas.allowlist()) do
      {:ok, mod} ->
        {:noreply,
         push_patch(socket,
           to: OperatorSelection.path(socket.assigns.mount_path, "sync-drift", mod)
         )}

      _ ->
        {:noreply, unavailable(socket)}
    end
  end

  def handle_event(
        "swap_live",
        _params,
        %{assigns: %{confirm_swap?: true, promotion_loading: false}} = socket
      ) do
    socket = assign(socket, :confirm_swap?, false)
    {:noreply, if(current_selection?(socket), do: swap_live(socket), else: unavailable(socket))}
  end

  def handle_event("swap_live", _params, socket), do: {:noreply, socket}

  def handle_event("confirm_swap_live", _params, socket) do
    if not socket.assigns.promotion_loading and socket.assigns.promotion_eligibility == :eligible and
         current_selection?(socket) do
      {:noreply, assign(socket, :confirm_swap?, true)}
    else
      {:noreply,
       put_flash(
         socket,
         :error,
         "Index promotion blocked: #{promotion_eligibility_copy(socket.assigns.promotion_eligibility)}"
       )}
    end
  end

  def handle_event("cancel_swap_live", _params, socket) do
    {:noreply, assign(socket, :confirm_swap?, false)}
  end

  @impl true
  def handle_info({:run_drift, generation}, socket) do
    if generation == socket.assigns.context_generation and current_selection?(socket) do
      {:noreply, refresh_drift(socket)}
    else
      {:noreply, assign(socket, :drift_loading, false)}
    end
  end

  @impl true
  def handle_async(
        {:recovery_observation, _generation, _handle},
        {:ok, {generation, handle, result}},
        socket
      ) do
    if generation == socket.assigns.context_generation and
         handle == socket.assigns.recovery_handle do
      {status, evidence} =
        case result do
          {status, %{} = evidence, document_observation} ->
            {status, Map.put(evidence, :document_observation, document_observation)}

          {status, nil, document_observation} ->
            {status, %{document_observation: document_observation}}

          {status, %{} = evidence} ->
            {status, evidence}

          status ->
            {status, nil}
        end

      document_observation =
        if is_map(evidence), do: Map.get(evidence, :document_observation), else: nil

      evidence =
        if is_map(evidence), do: Map.delete(evidence, :document_observation), else: evidence

      observation_error =
        case document_observation do
          %{state: :not_checked, reason: reason} -> reason
          %{state: :unknown, reason: reason} -> reason
          _ -> nil
        end

      {status, evidence, document_observation} =
        if observation_error do
          {
            socket.assigns.recovery_status || status,
            socket.assigns.recovery_evidence || evidence,
            socket.assigns.recovery_document_observation || document_observation
          }
        else
          {status, evidence, document_observation}
        end

      {:noreply,
       socket
       |> assign(:recovery_status, status)
       |> assign(:recovery_evidence, evidence)
       |> assign(:recovery_document_observation, document_observation)
       |> assign(:recovery_observation_error, observation_error)
       |> then(fn socket ->
         if observation_error,
           do: socket,
           else: assign(socket, :recovery_checked_at, DateTime.utc_now())
       end)
       |> assign(:recovery_loading, false)}
    else
      {:noreply, socket}
    end
  end

  def handle_async({:recovery_observation, generation, handle}, {:exit, _reason}, socket) do
    if generation == socket.assigns.context_generation and
         handle == socket.assigns.recovery_handle do
      {:noreply,
       socket
       |> assign(:recovery_observation_error, :observer_exit)
       |> assign(:recovery_loading, false)}
    else
      {:noreply, socket}
    end
  end

  def handle_async(
        {:promotion_swap, _generation, _task_id},
        {:ok, {generation, task_id, result}},
        socket
      ) do
    if generation == socket.assigns.context_generation and
         task_id == socket.assigns.promotion_task_id do
      socket =
        socket
        |> assign(:promotion_loading, false)
        |> assign(:promotion_task_read_error, nil)

      case result do
        {:ok, %{id: ^task_id, state: :succeeded}} ->
          socket
          |> assign(:promotion_status, :unknown)
          |> start_promotion_effect_observation(generation, task_id)

        {:ok, _unexpected_task} ->
          assign(socket, :promotion_status, :unknown)

        {:error, {:timeout, _task}} ->
          assign(socket, :promotion_status, :timed_out)

        {:error, {:task_failed, %OperationTask{id: ^task_id, state: :failed} = task}} ->
          assign(socket, :promotion_status, {:failed, {:task_failed, task}})

        {:error, {:cancelled, %OperationTask{id: ^task_id, state: :cancelled} = task}} ->
          assign(socket, :promotion_status, {:failed, {:cancelled, task}})

        {:error, _observation_error} ->
          assign(socket, :promotion_status, :unknown)
      end
      |> invalidate_recovery_claim()
      |> refresh_promotion_eligibility()
      |> then(&{:noreply, &1})
    else
      {:noreply, socket}
    end
  end

  def handle_async(
        {:promotion_effects, _generation, _task_id},
        {:ok, {generation, task_id, observed_assigns}},
        socket
      ) do
    if generation == socket.assigns.context_generation and
         task_id == socket.assigns.promotion_task_id do
      socket
      |> assign(Map.put(observed_assigns, :promotion_loading, false))
      |> refresh_promotion_eligibility()
      |> then(&{:noreply, &1})
    else
      {:noreply, socket}
    end
  end

  def handle_async({:promotion_effects, generation, task_id}, {:exit, _reason}, socket) do
    if generation == socket.assigns.context_generation and
         task_id == socket.assigns.promotion_task_id do
      {:noreply,
       socket
       |> promotion_observation_failed(:observer_exit)
       |> assign(:promotion_loading, false)
       |> refresh_promotion_eligibility()}
    else
      {:noreply, socket}
    end
  end

  def handle_async({:promotion_swap, generation, task_id}, {:exit, _reason}, socket) do
    if generation == socket.assigns.context_generation and
         task_id == socket.assigns.promotion_task_id do
      {:noreply,
       socket
       |> assign(:promotion_loading, false)
       |> assign(:promotion_status, :unknown)}
    else
      {:noreply, socket}
    end
  end

  def handle_async(
        {:promotion_refresh, _generation, _task_id},
        {:ok, {generation, task_id, result}},
        socket
      ) do
    if generation == socket.assigns.context_generation and
         task_id == socket.assigns.promotion_task_id do
      socket =
        socket
        |> assign(:promotion_loading, false)
        |> assign(:promotion_task_read_error, nil)

      case result do
        {:ok, %OperationTask{id: ^task_id, state: :succeeded}} ->
          socket
          |> assign(:promotion_status, :unknown)
          |> start_promotion_effect_observation(generation, task_id)

        {:ok, %OperationTask{id: ^task_id, state: :failed} = task} ->
          assign(socket, :promotion_status, {:failed, {:task_failed, task}})

        {:ok, %OperationTask{id: ^task_id, state: :cancelled} = task} ->
          assign(socket, :promotion_status, {:failed, {:cancelled, task}})

        {:ok, %OperationTask{id: ^task_id, state: state}}
        when state in [:enqueued, :processing] ->
          assign(socket, :promotion_status, :accepted)

        {:error, reason} ->
          preserve_promotion_failure(socket, promotion_task_read_error(reason))

        _error_or_mismatched_task ->
          preserve_promotion_failure(socket, :task_unavailable)
      end
      |> invalidate_recovery_claim()
      |> refresh_promotion_eligibility()
      |> then(&{:noreply, &1})
    else
      {:noreply, socket}
    end
  end

  def handle_async({:promotion_refresh, generation, task_id}, {:exit, _reason}, socket) do
    if generation == socket.assigns.context_generation and
         task_id == socket.assigns.promotion_task_id do
      {:noreply, preserve_promotion_failure(socket, :task_observation_exit)}
    else
      {:noreply, socket}
    end
  end

  defp module_flat_name(mod) when is_atom(mod), do: OperatorSelection.canonical(mod)

  defp recovery_status_label(nil), do: "Not checked"
  defp recovery_status_label(:accepted), do: "Retry accepted"
  defp recovery_status_label(:running), do: "Retry running"

  defp recovery_status_label(:queue_only_completed),
    do: "Queue job completed; backend evidence pending"

  defp recovery_status_label(:verified), do: "Recovery verified"
  defp recovery_status_label(:failed), do: "Recovery failed"
  defp recovery_status_label(:cancelled), do: "Recovery canceled"
  defp recovery_status_label(_), do: "Recovery outcome could not be checked"

  defp recovery_status_kind(:verified), do: :success
  defp recovery_status_kind(:failed), do: :error
  defp recovery_status_kind(:cancelled), do: :error

  defp recovery_status_kind(status) when status in [:accepted, :running, :queue_only_completed],
    do: :warning

  defp recovery_status_kind(_), do: :neutral

  defp recovery_status_copy(:accepted),
    do:
      "The queue accepted this retry; refresh to observe this same job. Refresh never resubmits work."

  defp recovery_status_copy(:running),
    do: "This retry is still running; refresh to observe the same job, attempt, and task."

  defp recovery_status_copy(:queue_only_completed),
    do: "The queue job completed, but backend and document evidence are not confirmed."

  defp recovery_status_copy(:verified),
    do: "The exact retry task and its expected active-index effect were observed."

  defp recovery_status_copy(:failed),
    do: "The exact retry job or backend task failed. Review its result before retrying."

  defp recovery_status_copy(:cancelled),
    do: "The exact retry job or backend task was canceled. Review its result before retrying."

  defp recovery_status_copy(:unknown),
    do:
      "This operation's outcome could not be checked. Refresh this same operation; do not submit another retry."

  defp recovery_status_copy(_),
    do:
      "No recovery result has been checked yet. Review failed sync work to start an eligible retry."

  defp document_observation_title(nil), do: "Not checked"
  defp document_observation_title(%{state: :not_checked}), do: "Not checked"
  defp document_observation_title(%{state: :verified}), do: "Expected documents observed"
  defp document_observation_title(%{state: :running}), do: "Document task is still running"
  defp document_observation_title(%{state: :failed}), do: "Document task failed"
  defp document_observation_title(%{state: :cancelled}), do: "Document task was canceled"
  defp document_observation_title(_), do: "Could not check document freshness"

  defp document_observation_kind(%{state: :verified}), do: :success
  defp document_observation_kind(%{state: :failed}), do: :error
  defp document_observation_kind(%{state: :cancelled}), do: :error
  defp document_observation_kind(%{state: :running}), do: :warning
  defp document_observation_kind(_), do: :info

  defp document_observation_copy(nil),
    do: "Expected-document evidence has not been checked for this recovery."

  defp document_observation_copy(%{state: :not_checked, reason: reason}),
    do:
      "Expected-document evidence is unavailable (#{inspect(reason)}); check the selected recovery receipt."

  defp document_observation_copy(%{state: :verified, operation: :upsert}),
    do: "The expected upsert effect was observed in the active index."

  defp document_observation_copy(%{state: :verified, operation: :delete}),
    do: "The expected delete effect was observed in the active index."

  defp document_observation_copy(%{state: :running}),
    do: "The exact backend task is still running; refresh recovery status to check again."

  defp document_observation_copy(%{state: :failed}),
    do: "The exact backend task failed; inspect its task result before retrying."

  defp document_observation_copy(%{state: :cancelled}),
    do: "The exact backend task was canceled; inspect its task result before retrying."

  defp document_observation_copy(%{reason: reason}),
    do:
      "Document freshness could not be checked (#{inspect(reason)}); refresh recovery status to check again."

  defp document_observation_copy(_),
    do: "Document freshness has not been confirmed; refresh recovery status to check again."

  defp maybe_advance_generation(socket, true) do
    socket
    |> update(:context_generation, &(&1 + 1))
    |> clear_context_results()
  end

  defp maybe_advance_generation(socket, false), do: socket

  defp clear_context_results(socket) do
    socket
    |> assign(:reconcile_result, nil)
    |> assign(:reconcile_loaded_at, nil)
    |> assign(:reconcile_generation, nil)
    |> assign(:reconcile_error, nil)
    |> assign(:drift_result, nil)
    |> assign(:drift_loaded_at, nil)
    |> assign(:drift_generation, nil)
    |> assign(:drift_error, nil)
    |> assign(:drift_loading, false)
    |> assign(:recovery_handle, nil)
    |> assign(:recovery_origin_generation, nil)
    |> assign(:recovery_status, nil)
    |> assign(:recovery_evidence, nil)
    |> assign(:recovery_document_observation, nil)
    |> assign(:recovery_observation_error, nil)
    |> assign(:recovery_checked_at, nil)
    |> assign(:recovery_loading, false)
    |> assign(:promotion_task_id, nil)
    |> assign(:promotion_status, nil)
    |> assign(:promotion_loading, false)
    |> assign(:promotion_identity, nil)
    |> assign(:promotion_document_observation, nil)
    |> assign(:promotion_observation_error, nil)
    |> assign(:promotion_task_read_error, nil)
    |> assign(:confirm_swap?, false)
    |> assign(:promotion_eligibility, {:blocked, :reconcile_not_current})
  end

  defp maybe_start_recovery(socket, handle, origin)
       when is_binary(handle) and byte_size(handle) in 1..128 and is_binary(origin) and
              byte_size(origin) <= 20 do
    case Integer.parse(origin) do
      {generation, ""} when generation >= 0 ->
        socket
        |> assign(:recovery_origin_generation, generation)
        |> start_recovery_observation(handle)

      _ ->
        clear_recovery_handoff(socket)
    end
  end

  defp maybe_start_recovery(socket, _, _), do: clear_recovery_handoff(socket)

  defp clear_recovery_handoff(socket) do
    socket
    |> assign(:recovery_handle, nil)
    |> assign(:recovery_origin_generation, nil)
    |> assign(:recovery_status, nil)
    |> assign(:recovery_evidence, nil)
    |> assign(:recovery_document_observation, nil)
    |> assign(:recovery_observation_error, nil)
    |> assign(:recovery_checked_at, nil)
    |> assign(:recovery_loading, false)
  end

  defp start_recovery_observation(socket, handle) do
    generation = socket.assigns.context_generation
    schema = socket.assigns.selected_schema
    operator_opts = socket.assigns.scrypath_opts
    opts = ScrypathOps.Schemas.runtime_opts(operator_opts)
    context = recovery_host_context(socket, schema)

    socket =
      if socket.assigns.recovery_handle == handle do
        socket
      else
        socket
        |> assign(:recovery_status, nil)
        |> assign(:recovery_evidence, nil)
        |> assign(:recovery_document_observation, nil)
        |> assign(:recovery_observation_error, nil)
        |> assign(:recovery_checked_at, nil)
      end

    socket =
      socket
      |> assign(:recovery_handle, handle)
      |> assign(:recovery_loading, true)
      |> assign(:recovery_observation_error, nil)

    start_async(socket, {:recovery_observation, generation, handle}, fn ->
      result = observe_recovery(context, handle, schema, opts, operator_opts)
      {generation, handle, result}
    end)
  end

  defp observe_recovery(context, handle, schema, opts, operator_opts) do
    task =
      Task.async(fn -> observe_recovery_now(context, handle, schema, opts, operator_opts) end)

    case Task.yield(task, 10_000) do
      {:ok, result} ->
        result

      nil ->
        Task.shutdown(task, :brutal_kill)
        {:unknown, nil, unchecked_document_observation(%{}, :observation_timeout)}
    end
  rescue
    _ -> {:unknown, nil, unchecked_document_observation(%{}, :observation_error)}
  end

  defp observe_recovery_now(context, handle, schema, opts, operator_opts) do
    with true <- schema in ScrypathOps.Schemas.allowlist(),
         receipt when is_map(receipt) <- RecoveryObservation.observe(context, handle),
         true <- receipt.generation == context.generation,
         true <- current_runtime_matches?(receipt, opts),
         {:ok, expected_index} <- active_index(schema, opts),
         true <- receipt.index == expected_index,
         {:ok, job} <- read_recovery_job(receipt),
         {:ok, queue_state} <- validate_recovery_job(job, receipt) do
      status =
        case queue_state do
          :failed ->
            :failed

          :cancelled ->
            :cancelled

          :running ->
            :running

          :completed when is_nil(receipt.task_uid) ->
            :queue_only_completed

          _ when is_integer(receipt.task_uid) ->
            verify_task_and_documents(receipt.task_uid, receipt, schema, opts, operator_opts)

          _ ->
            :accepted
        end

      evidence = Map.take(receipt, [:replacement_job, :attempt, :task_uid, :index])

      case status do
        {document_status, document_observation} when is_map(document_observation) ->
          {document_status, evidence, document_observation}

        _ ->
          {status, evidence, nil}
      end
    else
      false -> {:unknown, nil, unchecked_document_observation(%{}, :identity_mismatch)}
      :unknown -> {:unknown, nil, unchecked_document_observation(%{}, :receipt_unavailable)}
      {:error, :job_running} -> :running
      {:error, :queue_only_completed} -> :queue_only_completed
      {:error, reason} -> {:unknown, nil, unchecked_document_observation(%{}, reason)}
      _ -> {:unknown, nil, unchecked_document_observation(%{}, :observation_unavailable)}
    end
  end

  defp current_runtime_matches?(receipt, opts) do
    config = Scrypath.Config.resolve!(opts)
    instance = Keyword.get(config, :oban)

    with true <- is_atom(instance),
         true <- receipt.instance == instance,
         true <- receipt.node == node(),
         {:ok, oban_config} <- oban_config(instance),
         true <- receipt.repo == Map.get(oban_config, :repo),
         true <- receipt.prefix == Map.get(oban_config, :prefix),
         true <- receipt.endpoint == endpoint_identity(Keyword.get(config, :meilisearch_url)) do
      true
    else
      _ -> false
    end
  rescue
    _ -> false
  end

  defp oban_config(instance) do
    cond do
      function_exported?(instance, :config, 0) and Code.ensure_loaded?(instance) ->
        config = apply(instance, :config, [])
        if is_map(config), do: {:ok, config}, else: {:error, :invalid_oban_config}

      Code.ensure_loaded?(Oban) and function_exported?(Oban, :config, 1) ->
        config = apply(Oban, :config, [instance])
        if is_map(config), do: {:ok, config}, else: {:error, :invalid_oban_config}

      true ->
        {:error, :oban_unavailable}
    end
  rescue
    _ -> {:error, :oban_unavailable}
  end

  defp endpoint_identity(url) when is_binary(url) do
    case URI.parse(url) do
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

  defp endpoint_identity(_), do: nil

  defp verify_task_and_documents(task_uid, receipt, schema, opts, operator_opts) do
    with {:ok, task} <- read_recovery_task(task_uid, opts),
         :ok <- validate_recovery_task(task, receipt, task_uid) do
      task_status = Map.get(task, "status") || Map.get(task, :status)

      if to_string(task_status) in ["canceled", "cancelled"] do
        {:cancelled,
         %{
           state: :cancelled,
           reason: :task_cancelled,
           checked_at: DateTime.utc_now(),
           operation: receipt.operation,
           index: receipt.index,
           expected_ids: nil
         }}
      else
        with {:ok, expected} <- read_expected_effects(schema, receipt, operator_opts),
             {:ok, observation} <-
               ScrypathOps.DocumentObservation.check(
                 Map.merge(receipt, expected),
                 task,
                 Keyword.put(
                   opts,
                   :document_id_field,
                   Scrypath.Schema.Metadata.document_id(schema)
                 )
               ) do
          {observation.state,
           observation
           |> Map.put(:operation, expected.operation)
           |> Map.put(:index, receipt.index)
           |> Map.put(:expected_ids, expected_document_ids(expected))}
        else
          {:error, reason} -> {:unknown, unchecked_document_observation(receipt, reason)}
        end
      end
    else
      {:error, :job_running} -> {:running, nil}
      {:error, :queue_only_completed} -> {:queue_only_completed, nil}
      {:error, :job_failed} -> {:failed, nil}
      {:error, :job_cancelled} -> {:cancelled, nil}
      {:error, reason} -> {:unknown, unchecked_document_observation(receipt, reason)}
      _ -> {:unknown, unchecked_document_observation(receipt, :observation_unavailable)}
    end
  rescue
    _ -> {:unknown, unchecked_document_observation(receipt, :observation_error)}
  end

  defp expected_document_ids(%{operation: operation, expected: expected})
       when operation in [:upsert, :delete] and is_list(expected) and length(expected) <= 50 do
    ids =
      Enum.map(expected, fn
        %{id: id} -> id
        %{"id" => id} -> id
        id when operation == :delete -> id
        _ -> nil
      end)

    with true <- Enum.all?(ids, &(is_binary(&1) or is_integer(&1))),
         {:ok, encoded} <- Jason.encode(expected),
         true <- byte_size(encoded) <= 65_536 do
      ids
    else
      _ -> nil
    end
  end

  defp expected_document_ids(_), do: nil

  defp unchecked_document_observation(receipt, reason) do
    %{
      state: :not_checked,
      reason: reason,
      checked_at: nil,
      operation: Map.get(receipt, :operation),
      index: Map.get(receipt, :index),
      expected_ids: nil
    }
  end

  defp recovery_host_context(socket, schema) do
    operator_context = Map.get(socket.assigns, :operator_context)
    scope = Map.get(socket.assigns, :current_scope, %{})
    org = field(operator_context, :active_org_id) || get_in(scope, [:active_organization, :id])

    %{
      host: (socket.host_uri && socket.host_uri.host) || "unknown",
      org: org && to_string(org),
      schema: OperatorSelection.canonical(schema),
      generation: socket.assigns.recovery_origin_generation
    }
  end

  defp active_index(schema, opts) do
    try do
      {:ok, Scrypath.Meilisearch.index_name(schema, opts)}
    rescue
      _ -> {:error, :index_unavailable}
    end
  end

  defp read_recovery_job(receipt) do
    # The runtime identity check binds this repo and prefix to the current Oban instance.
    repo = receipt.repo
    job_id = receipt.replacement_job

    if is_atom(repo) and is_integer(job_id) and Code.ensure_loaded?(Oban.Job) and
         Code.ensure_loaded?(repo) and
         function_exported?(repo, :get, 3) do
      case apply(repo, :get, [Oban.Job, job_id, [prefix: receipt.prefix]]) do
        job when is_map(job) and is_struct(job, Oban.Job) -> {:ok, job}
        _ -> {:error, :job_unavailable}
      end
    else
      {:error, :job_unavailable}
    end
  end

  defp validate_recovery_job(job, receipt) do
    args = job.args || %{}
    schema = Map.get(args, "schema") || Map.get(args, :schema)
    index = Map.get(args, "index") || Map.get(args, :index)
    backend = Map.get(args, "backend") || Map.get(args, :backend)

    expected_worker =
      if receipt.operation == :delete,
        do: "Scrypath.Oban.DeleteWorker",
        else: "Scrypath.Oban.UpsertWorker"

    state = to_string(job.state)

    cond do
      job.id != receipt.replacement_job ->
        {:error, :job_id_mismatch}

      job.attempt != receipt.attempt ->
        {:error, :attempt_mismatch}

      job.worker not in [expected_worker, "Elixir." <> expected_worker] ->
        {:error, :worker_mismatch}

      schema != receipt.schema ->
        {:error, :schema_mismatch}

      index != receipt.index ->
        {:error, :index_mismatch}

      backend not in ["Elixir.Scrypath.Meilisearch", "Scrypath.Meilisearch"] ->
        {:error, :backend_mismatch}

      state in ["available", "scheduled", "retryable"] ->
        {:ok, :accepted}

      state == "executing" ->
        {:ok, :running}

      state == "completed" ->
        {:ok, :completed}

      state in ["discarded", "cancelled", "canceled"] ->
        {:ok, if(state == "discarded", do: :failed, else: :cancelled)}

      true ->
        {:error, :job_not_verifiable}
    end
  end

  defp read_recovery_task(uid, opts) do
    client = Keyword.get(opts, :meilisearch_client) || Scrypath.Meilisearch.Client

    if function_exported?(client, :task, 2) do
      case apply(client, :task, [uid, opts]) do
        {:ok, task} when is_map(task) -> {:ok, task}
        _ -> {:error, :task_unavailable}
      end
    else
      {:error, :task_unavailable}
    end
  end

  defp validate_recovery_task(task, receipt, uid) do
    task_uid = Map.get(task, "uid") || Map.get(task, :uid) || Map.get(task, "taskUid")
    index = Map.get(task, "indexUid") || Map.get(task, :indexUid)
    type = Map.get(task, "type") || Map.get(task, :type)

    expected_type =
      if receipt.operation == :delete, do: "documentDeletion", else: "documentAdditionOrUpdate"

    cond do
      to_string(task_uid) != to_string(uid) -> {:error, :task_uid_mismatch}
      index != receipt.index -> {:error, :task_index_mismatch}
      type != expected_type -> {:error, :task_type_mismatch}
      true -> :ok
    end
  end

  defp read_expected_effects(schema, receipt, opts) do
    source_id = get_in(receipt, [:source_failure, :id])

    with {:ok, rows} when is_list(rows) <- Scrypath.failed_sync_work(schema, opts),
         row when not is_nil(row) <- Enum.find(rows, &(to_string(&1.id) == to_string(source_id))),
         recovery when not is_nil(recovery) <- Scrypath.Operator.FailedWork.recovery_action(row),
         payload when is_map(payload) <- get_in(recovery.reference, [:payload]) do
      if receipt.operation == :delete do
        ids = Map.get(payload, "document_ids") || Map.get(payload, :document_ids)

        if is_list(ids),
          do: {:ok, %{operation: :delete, expected: ids}},
          else: {:error, :missing_ids}
      else
        docs = Map.get(payload, "documents") || Map.get(payload, :documents)

        if is_list(docs),
          do: {:ok, %{operation: :upsert, expected: docs}},
          else: {:error, :missing_documents}
      end
    else
      _ -> {:error, :source_unavailable}
    end
  rescue
    _ -> {:error, :source_unavailable}
  end

  defp field(map, key) when is_map(map), do: Map.get(map, key)
  defp field(_, _), do: nil

  defp current_selection?(socket) do
    case OperatorSelection.resolve(
           %{"schema" => OperatorSelection.canonical(socket.assigns.selected_schema)},
           ScrypathOps.Schemas.allowlist()
         ) do
      {:ok, selected} -> selected == socket.assigns.selected_schema
      _ -> false
    end
  end

  defp unavailable(socket) do
    socket
    |> assign(:selected_schema, nil)
    |> assign(:selection_error, :unavailable)
    |> update(:context_generation, &(&1 + 1))
    |> clear_context_results()
    |> assign(:drift_error, :unavailable)
  end

  defp refresh_reconcile(socket) do
    mod = socket.assigns.selected_schema
    opts = socket.assigns.scrypath_opts

    if mod && Keyword.has_key?(opts, :backend) do
      case Scrypath.reconcile_sync(mod, opts) do
        {:ok, rep} ->
          socket
          |> assign(:reconcile_result, rep)
          |> assign(:reconcile_loaded_at, DateTime.utc_now())
          |> assign(:reconcile_generation, socket.assigns.context_generation)
          |> assign(:reconcile_error, nil)
          |> refresh_promotion_eligibility()

        {:error, reason} ->
          socket
          |> assign(:reconcile_error, reason)
          |> refresh_promotion_eligibility()
          |> put_flash(:error, "Reconcile failed: #{inspect(reason)}")
      end
    else
      socket
      |> assign(:reconcile_error, :missing_backend)
      |> refresh_promotion_eligibility()
      |> put_flash(:error, "Select a schema and configure Scrypath runtime.")
    end
  end

  defp refresh_drift(socket) do
    mod = socket.assigns.selected_schema
    opts = socket.assigns.scrypath_opts

    socket = assign(socket, :drift_loading, false)

    if mod && Keyword.has_key?(opts, :backend) do
      case Scrypath.index_contract_drift(mod, ScrypathOps.Schemas.runtime_opts(opts)) do
        {:ok, rep} ->
          socket
          |> assign(:drift_result, rep)
          |> assign(:drift_loaded_at, DateTime.utc_now())
          |> assign(:drift_generation, socket.assigns.context_generation)
          |> assign(:drift_error, nil)
          |> refresh_promotion_eligibility()

        {:error, reason} ->
          socket
          |> assign(:drift_error, reason)
          |> refresh_promotion_eligibility()
      end
    else
      socket
      |> assign(:drift_error, :missing_backend)
      |> refresh_promotion_eligibility()
    end
  end

  defp swap_live(socket) do
    Gating.gate_sensitive_action(socket, :swap_live, fn ->
      socket = fetch_promotion_prerequisites(socket)

      case socket.assigns.promotion_eligibility do
        :eligible ->
          mod = socket.assigns.selected_schema
          opts = ScrypathOps.Schemas.runtime_opts(socket.assigns.scrypath_opts)

          case Scrypath.Meilisearch.swap_indexes(mod, opts) do
            {:ok, %{task: task}} ->
              task_id = Map.fetch!(task, :uid)
              generation = socket.assigns.context_generation
              identity = current_promotion_identity(socket)

              socket
              |> assign(:promotion_task_id, task_id)
              |> assign(:promotion_status, :accepted)
              |> assign(:promotion_loading, true)
              |> assign(:promotion_identity, identity)
              |> assign(:promotion_document_observation, nil)
              |> assign(:promotion_observation_error, nil)
              |> assign(:promotion_task_read_error, nil)
              |> start_async({:promotion_swap, generation, task_id}, fn ->
                result = Tasks.wait_for_task(task, task_wait_opts(opts))
                {generation, task_id, result}
              end)

            {:error, reason} ->
              put_flash(socket, :error, "Index swap was not accepted: #{inspect(reason)}")
          end

        {:blocked, reason} ->
          put_flash(socket, :error, "Index promotion blocked: #{promotion_reason(reason)}")
      end
    end)
  end

  defp start_promotion_refresh(socket, task_id) do
    generation = socket.assigns.context_generation
    opts = ScrypathOps.Schemas.runtime_opts(socket.assigns.scrypath_opts)

    socket
    |> assign(:promotion_loading, true)
    |> assign(:promotion_status, :unknown)
    |> assign(:promotion_document_observation, nil)
    |> assign(:promotion_observation_error, nil)
    |> assign(:promotion_task_read_error, nil)
    |> start_async({:promotion_refresh, generation, task_id}, fn ->
      {generation, task_id, read_promotion_task(task_id, opts)}
    end)
  end

  defp read_promotion_task(task_id, opts) do
    client = Keyword.get(opts, :meilisearch_client) || Scrypath.Meilisearch.Client

    with {:ok, payload} <- client.task(task_id, opts),
         {:ok, normalized} <- Scrypath.Meilisearch.normalize_task(payload, :poll),
         true <- normalized.uid == task_id,
         true <- normalized.type == "indexSwap" do
      {:ok, Scrypath.Operations.task_from_backend(normalized, source: :meilisearch)}
    else
      false -> {:error, :task_identity_mismatch}
      {:error, _reason} = error -> error
      _other -> {:error, :task_unavailable}
    end
  rescue
    _error -> {:error, :task_unavailable}
  end

  defp promotion_task_read_error(:task_identity_mismatch), do: :task_identity_mismatch
  defp promotion_task_read_error(:task_unavailable), do: :task_unavailable
  defp promotion_task_read_error(_reason), do: :task_read_failed

  defp preserve_promotion_failure(socket, reason) do
    status =
      case socket.assigns.promotion_status do
        {:failed, _reason} = failed -> failed
        _status -> :unknown
      end

    socket
    |> assign(:promotion_status, status)
    |> assign(:promotion_loading, false)
    |> assign(:promotion_document_observation, nil)
    |> assign(:promotion_observation_error, nil)
    |> assign(:promotion_task_read_error, reason)
  end

  defp fetch_promotion_prerequisites(socket) do
    mod = socket.assigns.selected_schema
    operator_opts = socket.assigns.scrypath_opts
    opts = ScrypathOps.Schemas.runtime_opts(operator_opts)

    if (mod && mod in ScrypathOps.Schemas.allowlist()) and
         Keyword.get(opts, :backend) == Scrypath.Meilisearch do
      reconcile = Scrypath.reconcile_sync(mod, operator_opts)
      drift = Scrypath.index_contract_drift(mod, opts)

      socket =
        case reconcile do
          {:ok, rep} ->
            socket
            |> assign(:reconcile_result, rep)
            |> assign(:reconcile_generation, socket.assigns.context_generation)
            |> assign(:reconcile_error, nil)

          {:error, reason} ->
            socket
            |> assign(:reconcile_result, nil)
            |> assign(:reconcile_generation, nil)
            |> assign(:reconcile_error, reason)
        end

      socket =
        case drift do
          {:ok, rep} ->
            socket
            |> assign(:drift_result, rep)
            |> assign(:drift_generation, socket.assigns.context_generation)
            |> assign(:drift_error, nil)

          {:error, reason} ->
            socket
            |> assign(:drift_result, nil)
            |> assign(:drift_generation, nil)
            |> assign(:drift_error, reason)
        end

      refresh_promotion_eligibility(socket)
    else
      socket
      |> assign(:promotion_eligibility, {:blocked, :schema_not_allowed})
    end
  end

  defp refresh_promotion_eligibility(socket) do
    result = PromotionEligibility.evaluate(promotion_context(socket))
    assign(socket, :promotion_eligibility, result)
  end

  defp current_promotion_identity(socket) do
    reconcile = socket.assigns.reconcile_result || %{}
    reindex = Map.get(reconcile, :reindex, %{})

    %{
      schema: socket.assigns.selected_schema,
      generation: socket.assigns.context_generation,
      live_index: Map.get(reindex, :live_index),
      target_index: Map.get(reindex, :target_index)
    }
  end

  defp observe_promotion_effects(socket) do
    socket = socket |> load_reconcile_on_mount() |> refresh_drift()
    identity = socket.assigns.promotion_identity
    generation = socket.assigns.context_generation

    with %{schema: schema, generation: ^generation, live_index: live, target_index: target} <-
           identity,
         true <- current_selection?(socket) and schema == socket.assigns.selected_schema,
         true <-
           is_binary(live) and live != "" and is_binary(target) and target != "" and
             live != target,
         true <- fresh_promotion_contract?(socket, identity),
         {:ok, document_observation} <- observe_prepared_target_documents(socket, identity) do
      socket
      |> assign(:promotion_status, :completed)
      |> assign(:promotion_document_observation, document_observation)
      |> assign(:promotion_observation_error, nil)
    else
      {:error, reason} ->
        socket
        |> assign(:promotion_status, :unknown)
        |> assign(:promotion_document_observation, %{state: :unknown, reason: reason})
        |> assign(:promotion_observation_error, reason)

      _ ->
        socket
        |> assign(:promotion_status, :unknown)
        |> assign(:promotion_document_observation, %{
          state: :not_checked,
          reason: :index_or_contract_unavailable
        })
        |> assign(:promotion_observation_error, :index_or_contract_unavailable)
    end
  rescue
    _ ->
      socket
      |> assign(:promotion_status, :unknown)
      |> assign(:promotion_document_observation, %{
        state: :not_checked,
        reason: :observation_error
      })
      |> assign(:promotion_observation_error, :observation_error)
  end

  defp start_promotion_effect_observation(socket, generation, task_id) do
    observation_assigns = Map.take(socket.assigns, @promotion_observation_input_assigns)

    observation_private =
      socket.private
      |> Map.take([:live_temp])
      |> Map.put_new(:live_temp, %{})

    observation_host_uri = socket.host_uri

    socket
    |> assign(:promotion_loading, true)
    |> assign(:promotion_document_observation, nil)
    |> assign(:promotion_observation_error, nil)
    |> assign(:promotion_task_read_error, nil)
    |> start_async({:promotion_effects, generation, task_id}, fn ->
      observation_socket = %Phoenix.LiveView.Socket{
        assigns: observation_assigns,
        private: observation_private,
        host_uri: observation_host_uri
      }

      task = Task.async(fn -> observe_promotion_effects(observation_socket) end)

      observed_socket =
        case Task.yield(task, @promotion_observation_timeout) do
          {:ok, result} ->
            result

          {:exit, _reason} ->
            promotion_observation_failed(observation_socket, :observation_error)

          nil ->
            Task.shutdown(task, :brutal_kill)
            promotion_observation_failed(observation_socket, :observation_timeout)
        end

      {generation, task_id, Map.take(observed_socket.assigns, @promotion_observation_assigns)}
    end)
  end

  defp promotion_observation_failed(socket, reason) do
    socket
    |> assign(:promotion_status, :unknown)
    |> assign(:promotion_document_observation, %{state: :unknown, reason: reason})
    |> assign(:promotion_observation_error, reason)
  end

  defp fresh_promotion_contract?(socket, identity) do
    generation = socket.assigns.context_generation
    reconcile = socket.assigns.reconcile_result
    drift = socket.assigns.drift_result
    reindex = if is_map(reconcile), do: Map.get(reconcile, :reindex, %{}), else: %{}

    is_nil(socket.assigns.reconcile_error) and is_nil(socket.assigns.drift_error) and
      socket.assigns.reconcile_generation == generation and
      socket.assigns.drift_generation == generation and is_map(reconcile) and is_map(drift) and
      Map.get(reconcile, :schema) == identity.schema and
      Map.get(drift, :schema) == identity.schema and
      Map.get(reconcile, :index) ==
        Scrypath.Meilisearch.index_name(identity.schema, socket.assigns.scrypath_opts) and
      Map.get(reconcile, :index) == Map.get(drift, :index) and
      Map.get(reindex, :live_index) == identity.live_index and
      Map.get(reindex, :target_index) == identity.target_index and
      drift_mismatch_count(drift) == 0
  rescue
    _ -> false
  end

  defp observe_prepared_target_documents(socket, identity) do
    case socket.assigns.recovery_handle do
      handle when is_binary(handle) ->
        context = recovery_host_context(socket, identity.schema)

        with receipt when is_map(receipt) <- RecoveryObservation.lookup(context, handle),
             true <- Map.get(receipt, :schema) == OperatorSelection.canonical(identity.schema),
             true <- Map.get(receipt, :index) == identity.target_index,
             true <-
               Map.get(receipt, :endpoint) ==
                 endpoint_identity(Keyword.get(socket.assigns.scrypath_opts, :meilisearch_url)) do
          case read_expected_effects(identity.schema, receipt, socket.assigns.scrypath_opts) do
            {:ok, expected} ->
              case ScrypathOps.DocumentObservation.check_effects(
                     expected.operation,
                     identity.live_index,
                     expected.expected,
                     ScrypathOps.Schemas.runtime_opts(socket.assigns.scrypath_opts)
                     |> Keyword.put(
                       :document_id_field,
                       Scrypath.Schema.Metadata.document_id(identity.schema)
                     )
                   ) do
                {:ok, %{state: :verified} = observation} ->
                  {:ok, observation}

                {:ok, observation} ->
                  {:error,
                   {:prepared_target_effect_unconfirmed, observation.state, observation.reason}}

                {:error, reason} ->
                  {:error, {:prepared_target_effect_unconfirmed, :unknown, reason}}
              end

            {:error, reason} ->
              {:error, {:prepared_target_effect_unconfirmed, :unknown, reason}}
          end
        else
          _ -> {:ok, %{state: :not_checked, reason: :no_applicable_prepared_target_effect}}
        end

      _ ->
        {:ok, %{state: :not_checked, reason: :no_authoritative_prepared_target_effect}}
    end
  end

  defp promotion_context(socket) do
    %{
      schema: socket.assigns.selected_schema,
      allowlist: ScrypathOps.Schemas.allowlist(),
      backend: Keyword.get(socket.assigns.scrypath_opts, :backend),
      opts: ScrypathOps.Schemas.runtime_opts(socket.assigns.scrypath_opts),
      generation: socket.assigns.context_generation,
      reconcile_generation: socket.assigns.reconcile_generation,
      drift_generation: socket.assigns.drift_generation,
      reconcile_loading: false,
      drift_loading: socket.assigns.drift_loading,
      reconcile_error: socket.assigns.reconcile_error,
      drift_error: socket.assigns.drift_error,
      reconcile: socket.assigns.reconcile_result,
      drift: socket.assigns.drift_result
    }
  end

  defp promotion_reason(:schema_not_allowed), do: "select an available schema"
  defp promotion_reason(:unsupported_backend), do: "Meilisearch is unavailable"
  defp promotion_reason(:reconcile_failed), do: "refresh sync and queue status"
  defp promotion_reason(:contract_failed), do: "refresh the index contract check"
  defp promotion_reason(:reconcile_not_current), do: "refresh sync and queue status"
  defp promotion_reason(:contract_not_current), do: "run the index contract check"
  defp promotion_reason(:check_in_progress), do: "wait for the current check"
  defp promotion_reason(:context_mismatch), do: "refresh checks for this schema and index"
  defp promotion_reason(:indexes_not_distinct), do: "confirm live and target indexes differ"
  defp promotion_reason(:target_unobserved), do: "observe the prepared target index first"
  defp promotion_reason(:backend_work_pending), do: "wait for backend tasks to finish"
  defp promotion_reason(:queue_work_pending), do: "wait for queued work to finish"
  defp promotion_reason(:reindex_pending), do: "wait for reindex work to finish"
  defp promotion_reason(:cutover_pending), do: "wait for the current cutover to finish"
  defp promotion_reason(:failed_work), do: "resolve failed sync work first"
  defp promotion_reason(:contract_mismatch), do: "resolve contract differences first"
  defp promotion_reason(_), do: "refresh current checks"

  defp promotion_eligibility_title(:eligible), do: "Ready for promotion"
  defp promotion_eligibility_title({:blocked, _}), do: "Promotion unavailable"
  defp promotion_eligibility_title(_), do: "Promotion unavailable"

  defp promotion_eligibility_copy(:eligible),
    do: "Current checks are clear for this schema and index pair."

  defp promotion_eligibility_copy({:blocked, reason}),
    do: "Promotion is blocked: #{promotion_reason(reason)}."

  defp promotion_eligibility_copy(_), do: "Refresh current checks before promotion."

  defp promotion_index(nil, _key), do: "unknown"

  defp promotion_index(reconcile, key),
    do: inspect(reconcile |> Map.get(:reindex, %{}) |> Map.get(key) || "unknown")

  defp promotion_status_kind(:accepted), do: :warning
  defp promotion_status_kind(:completed), do: :success
  defp promotion_status_kind({:failed, _}), do: :error
  defp promotion_status_kind(:timed_out), do: :warning
  defp promotion_status_kind(:unknown), do: :warning
  defp promotion_status_kind(_), do: :neutral

  defp promotion_status_title(:accepted), do: "Index swap accepted"
  defp promotion_status_title(:completed), do: "Index swap completed"
  defp promotion_status_title({:failed, {:cancelled, _}}), do: "Index swap canceled"
  defp promotion_status_title({:failed, _}), do: "Index swap failed"
  defp promotion_status_title(:timed_out), do: "Index swap outcome unconfirmed"
  defp promotion_status_title(:unknown), do: "Index swap outcome unconfirmed"
  defp promotion_status_title(_), do: "Index swap status"

  defp promotion_status_role({:failed, _}), do: "alert"
  defp promotion_status_role(_), do: "status"

  defp promotion_document_copy(%{state: :verified}),
    do: "The prepared target's expected document effect was observed in the selected live index."

  defp promotion_document_copy(%{state: :not_checked, reason: reason}),
    do:
      "Expected document freshness was not checked (#{inspect(reason)}). No authoritative target effect was available."

  defp promotion_document_copy(%{reason: reason}),
    do:
      "Expected document freshness could not be confirmed (#{inspect(reason)}). Refresh checks to inspect this same task."

  defp promotion_document_copy(_),
    do: "Expected document freshness has not been checked for this promotion."

  defp task_wait_opts(opts) do
    opts
    |> Keyword.put_new(:inline_poll_interval, 50)
    |> Keyword.put_new(:inline_timeout, 15_000)
  end

  defp invalidate_recovery_claim(socket) do
    socket
    |> assign(:recovery_status, :unknown)
    |> assign(:recovery_evidence, nil)
    |> assign(:recovery_checked_at, nil)
    |> assign(:recovery_loading, false)
  end

  defp reconcile_signal_label(signal) do
    signal
    |> to_string()
    |> String.trim_leading(":")
    |> String.replace("_", " ")
  end

  defp drift_dimension_label(key) do
    key
    |> to_string()
    |> String.replace("_", " ")
  end

  defp drift_dimension_rows(%{dimensions: dimensions}) when is_map(dimensions) do
    dimensions
    |> Enum.map(fn {key, dimension} ->
      {drift_dimension_label(key), Map.get(dimension, :match, false)}
    end)
    |> Enum.sort_by(fn {label, match?} -> {match?, label} end)
  end

  defp drift_dimension_rows(_), do: []

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      mount_path={@mount_path}
      flash={@flash}
      shell={@shell}
      page_title={@page_title}
      ops_main_width={:wide}
    >
      <.ops_page_header
        title="Sync and drift"
        subtitle="Check sync status and compare the schema contract with its live index."
      />

      <.ops_trail current={:sync_drift} class="mt-4" />

      <div class="mt-ops-4">
        <.form for={%{}} id="sync-drift-schema-form" phx-change="select_schema">
          <.ops_schema_select
            id="sync-schema-select"
            schemas={@schema_allowlist}
            selected={@selected_schema}
          />
        </.form>
      </div>

      <.ops_empty_state :if={@selection_error == :no_schemas} title="No schemas configured">
        Add allowlisted schemas before loading sync or drift observations.
      </.ops_empty_state>

      <.ops_status
        :if={@selection_error == :unavailable}
        kind={:error}
        title="That schema is unavailable"
        role="alert"
        neutral
      >
        Select an allowlisted schema to continue.
      </.ops_status>

      <.ops_section
        id="sync-reconcile-heading"
        title="Sync and queue status"
        subtitle="Check current backend tasks and queued work for this schema."
        prominent_title
      >
        <:actions>
          <.ops_refresh_control
            id="sync-drift-refresh"
            checked_at={@reconcile_loaded_at}
            phx-click="refresh_reconcile"
            label="Refresh sync and queue status"
            aria_label="Refresh sync and queue status"
            disabled={!@selected_schema}
          />
        </:actions>

        <.ops_signal_table :if={@reconcile_result}>
          <thead>
            <tr>
              <th scope="col">Signal</th>
              <th scope="col">Value</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <th scope="row" class="align-top">Index</th>
              <td>
                <.ops_inline_code>{@reconcile_result.index}</.ops_inline_code>
              </td>
            </tr>
            <tr>
              <th scope="row" class="align-top">Mode</th>
              <td>{reconcile_signal_label(@reconcile_result.mode)}</td>
            </tr>
            <tr>
              <th scope="row" class="align-top">Drift signals</th>
              <td>
                <div class="flex flex-wrap gap-1">
                  <.ops_badge
                    :for={signal <- @reconcile_result.drift_signals}
                    kind={:neutral}
                  >
                    {reconcile_signal_label(signal)}
                  </.ops_badge>
                </div>
              </td>
            </tr>
          </tbody>
        </.ops_signal_table>

        <p
          :if={@reconcile_result == nil && @selected_schema}
          class="text-ops-body text-base-content/70"
        >
          Sync status is not available yet. Refresh sync status to check again.
        </p>
        <.ops_status
          :if={@reconcile_error}
          kind={:error}
          title="Sync and queue status could not be checked"
          role="alert"
          neutral
        >
          Reason: {inspect(@reconcile_error)}. Any displayed values retain their last checked time; refresh to check again.
        </.ops_status>
      </.ops_section>

      <.ops_section
        id="sync-drift-heading"
        title="Index contract"
        subtitle="Compare the selected schema contract with its live index."
        meta={if @drift_loaded_at, do: "last loaded #{format_dt(@drift_loaded_at)}"}
        class="mt-6"
      >
        <:actions>
          <.ops_button
            phx-click="load_drift"
            phx-disable-with="Checking…"
            disabled={@drift_loading || !@selected_schema}
          >
            {if @drift_result, do: "Refresh contract check", else: "Check index contract"}
          </.ops_button>
        </:actions>

        <div
          :if={@drift_loading}
          class="space-y-3"
          role="status"
          aria-label="Loading contract drift"
        >
          <p class="text-ops-body text-base-content/70">
            Comparing the declared contract against the live index…
          </p>
          <.ops_loading lines={4} label="Loading contract drift" />
        </div>

        <.ops_status
          :if={@drift_loading && @drift_result}
          kind={:info}
          title="Checking index contract"
          role="status"
          neutral
        >
          The last contract result remains visible with its checked time while this check runs.
        </.ops_status>

        <.ops_status
          :if={!@drift_loading || is_nil(@drift_result)}
          kind={drift_status_kind(@drift_result, @drift_error)}
          title={drift_status_title(@drift_result, @drift_error)}
          role={if @drift_error, do: "alert"}
          neutral
        >
          {drift_status_copy(@drift_result, @drift_error)}
        </.ops_status>

        <.ops_signal_table :if={@drift_result}>
          <thead>
            <tr>
              <th scope="col">Field</th>
              <th scope="col">Value</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <th scope="row" class="align-top">Summary</th>
              <td>Index contract snapshot</td>
            </tr>
            <tr>
              <th scope="row" class="align-top">Version · index</th>
              <td class="font-mono text-ops-sm tabular-nums">
                version {@drift_result.version} · index {@drift_result.index}
              </td>
            </tr>
            <tr>
              <th scope="row" class="align-top">Dimension mismatches</th>
              <td class="font-mono text-ops-sm tabular-nums">
                {drift_mismatch_count(@drift_result)} of {map_size(@drift_result.dimensions)}
              </td>
            </tr>
          </tbody>
        </.ops_signal_table>
        <.ops_data_card
          :if={@drift_result}
          title="Contract dimensions"
          class="mt-3"
        >
          <div class="grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
            <.ops_tone_chip
              :for={{label, match?} <- drift_dimension_rows(@drift_result)}
              kind={if match?, do: :success, else: :warning}
              label={label}
              value={if match?, do: "matches", else: "differs"}
            />
          </div>
        </.ops_data_card>
      </.ops_section>

      <.ops_section
        :if={@selected_schema}
        id="document-freshness"
        class="mt-6"
        title="Document freshness"
        subtitle="Check the expected effect for the exact recovery task in this schema's active index."
        meta={
          if @recovery_document_observation && @recovery_document_observation.checked_at,
            do: "checked #{format_dt(@recovery_document_observation.checked_at)}"
        }
      >
        <p :if={@recovery_loading} role="status" aria-label="Checking document freshness">
          Checking the expected effect for this same recovery operation. Any previous result remains available with its checked time.
        </p>
        <.ops_status
          id="document-freshness-result"
          kind={document_observation_kind(@recovery_document_observation)}
          title={document_observation_title(@recovery_document_observation)}
          role="status"
          neutral
        >
          {document_observation_copy(@recovery_document_observation)}
        </.ops_status>
        <div :if={@recovery_document_observation} class="mt-2 space-y-1 text-ops-body">
          <p :if={@recovery_document_observation.operation}>
            Expected effect: {@recovery_document_observation.operation}
          </p>
          <p :if={@recovery_document_observation.index}>
            Active index:
            <.ops_inline_code>{@recovery_document_observation.index}</.ops_inline_code>
          </p>
          <p :if={is_list(@recovery_document_observation.expected_ids)}>
            Expected document identities:
            <span :for={id <- @recovery_document_observation.expected_ids} class="break-all">
              <.ops_inline_code>{id}</.ops_inline_code>
            </span>
          </p>
        </div>
      </.ops_section>

      <.ops_section
        :if={@selected_schema}
        id="ordinary-recovery"
        class="mt-6"
        title="Ordinary recovery"
        subtitle="Review the selected schema's failed work and use its existing eligible retry action."
        meta={if @recovery_checked_at, do: "last checked #{format_dt(@recovery_checked_at)}"}
      >
        <:actions>
          <.link
            navigate={OperatorSelection.path(@mount_path, "failed-sync", @selected_schema)}
            class="link link-primary"
          >
            Review failed sync work
          </.link>
          <.ops_button
            :if={@recovery_handle}
            phx-click="refresh_recovery_status"
            phx-disable-with="Checking…"
            disabled={@recovery_loading || !@selected_schema}
          >
            Refresh recovery status
          </.ops_button>
        </:actions>
        <p class="text-ops-body text-base-content/75">
          Retry failed work there. Refresh recovery status observes the accepted operation and never resubmits it.
        </p>
        <div :if={@recovery_handle} id="recovery-observation" class="mt-3 space-y-2">
          <p :if={@recovery_loading} role="status" aria-label="Checking recovery status">
            Checking this same recovery operation. The last observed result remains visible until this check finishes.
          </p>
          <.ops_status
            kind={recovery_status_kind(@recovery_status)}
            title={
              if @recovery_observation_error,
                do: "Recovery refresh could not be checked",
                else: recovery_status_label(@recovery_status)
            }
            role={if @recovery_observation_error, do: "alert", else: "status"}
            neutral
          >
            {recovery_status_copy(@recovery_status)}
            <span :if={@recovery_observation_error}>
              Check detail: {inspect(@recovery_observation_error)}.
            </span>
          </.ops_status>
          <p
            :if={@recovery_evidence}
            class="text-ops-body break-all"
            data-testid="recovery-evidence"
          >
            Schema:
            <.ops_inline_code>{module_flat_name(@selected_schema)}</.ops_inline_code>
            · Queue job {@recovery_evidence.replacement_job} · attempt {@recovery_evidence.attempt}
            <span :if={@recovery_evidence.task_uid}>
              · Meilisearch task {@recovery_evidence.task_uid}
            </span>
            · Active index
            <.ops_inline_code>{@recovery_evidence.index}</.ops_inline_code>
          </p>
        </div>
      </.ops_section>

      <details
        :if={@selected_schema}
        id="index-promotion"
        class="ops-panel mt-6"
        open={@promotion_status != nil}
      >
        <summary
          id="index-promotion-summary"
          class="cursor-pointer p-4 font-semibold"
        >
          Advanced: index promotion
        </summary>
        <div class="space-y-3 px-4 pb-4">
          <p class="text-ops-body text-base-content/75">
            Promotion changes the live alias for <.ops_inline_code>{module_flat_name(@selected_schema)}</.ops_inline_code>.
          </p>
          <.ops_status
            kind={if @promotion_eligibility == :eligible, do: :success, else: :warning}
            title={promotion_eligibility_title(@promotion_eligibility)}
            neutral
          >
            {promotion_eligibility_copy(@promotion_eligibility)}
          </.ops_status>
          <.ops_button
            phx-click="confirm_swap_live"
            disabled={@promotion_eligibility != :eligible || @promotion_loading}
          >
            Promote target index
          </.ops_button>
          <.ops_status
            :if={@promotion_status}
            id="promotion-status-result"
            kind={promotion_status_kind(@promotion_status)}
            title={promotion_status_title(@promotion_status)}
            role={promotion_status_role(@promotion_status)}
            neutral
          >
            <span :if={@promotion_task_id}>
              Task
              <.ops_inline_code>{@promotion_task_id}</.ops_inline_code>
            </span>
            <span :if={@promotion_status == :accepted}>
              The backend accepted this swap. Waiting for its terminal result.
            </span>
            <span :if={@promotion_status == :completed}>Index swap completed.</span>
            <span :if={@promotion_status == :unknown && @promotion_loading}>
              Checking the retained swap task and current index evidence.
            </span>
            <span :if={
              @promotion_status == :unknown && !@promotion_loading &&
                is_map(@promotion_document_observation)
            }>
              The swap task succeeded, but its expected-document observation could not be confirmed.
            </span>
            <span :if={
              @promotion_status == :unknown &&
                !@promotion_loading &&
                !is_map(@promotion_document_observation) && @promotion_task_read_error
            }>
              The retained task result could not be confirmed ({Atom.to_string(
                @promotion_task_read_error
              )}). Refresh to inspect this same task; do not submit another operation.
            </span>
            <span :if={
              @promotion_status in [:timed_out, :unknown] &&
                !@promotion_loading &&
                is_nil(@promotion_task_read_error) &&
                !is_map(@promotion_document_observation)
            }>
              The task result could not be confirmed. Refresh checks to inspect current index state.
            </span>
            <span :if={match?({:failed, {:cancelled, _}}, @promotion_status)}>
              The swap task was canceled. Refresh checks to inspect current index state.
            </span>
            <span :if={
              match?({:failed, _}, @promotion_status) &&
                !match?({:failed, {:cancelled, _}}, @promotion_status)
            }>
              The swap task failed. Refresh checks to inspect current index state.
            </span>
            <p
              :if={
                (@promotion_status == :completed ||
                   (@promotion_status == :unknown && is_map(@promotion_document_observation))) &&
                  !@promotion_loading
              }
              class="break-words"
            >
              Expected document effect: {promotion_document_copy(@promotion_document_observation)}
            </p>
            <p
              :if={
                @promotion_status == :unknown && !@promotion_loading &&
                  @promotion_observation_error &&
                  is_nil(@promotion_task_read_error) &&
                  !is_map(@promotion_document_observation)
              }
              class="break-words"
            >
              The selected live-index or contract effect could not be confirmed ({inspect(
                @promotion_observation_error
              )}).
            </p>
          </.ops_status>
          <.ops_button
            :if={@promotion_status && (@promotion_status != :accepted || !@promotion_loading)}
            phx-click="refresh_promotion_checks"
            size={:sm}
          >
            Refresh checks
          </.ops_button>
        </div>
      </details>

      <.ops_handoff>
        <:step
          navigate={@mount_path}
          hint="After checking sync —"
        >
          Return to Control Room
        </:step>
        <:step
          :if={@selected_schema}
          navigate={OperatorSelection.path(@mount_path, "health", @selected_schema)}
          hint="For the selected schema —"
        >
          Inspect search health
        </:step>
      </.ops_handoff>

      <.ops_modal
        :if={@confirm_swap? && @selected_schema}
        id="confirm-index-promotion"
        title="Confirm index promotion"
        description="Meilisearch will change the live alias after its swap task completes."
        action_label="promote index"
        cancel_event="cancel_swap_live"
        successor="#index-promotion-summary"
      >
        <.form for={%{}} phx-submit="swap_live" class="space-y-3">
          <p>
            Schema:
            <.ops_inline_code>{module_flat_name(@selected_schema)}</.ops_inline_code>
          </p>
          <p>
            Live index:
            <.ops_inline_code>{promotion_index(@reconcile_result, :live_index)}</.ops_inline_code>
          </p>
          <p>
            Target index:
            <.ops_inline_code>{promotion_index(@reconcile_result, :target_index)}</.ops_inline_code>
          </p>
          <p>Effect: replace the live alias with the prepared target index.</p>
          <div class="flex justify-between gap-2">
            <.ops_button
              type="button"
              phx-click="cancel_swap_live"
              variant={:ghost}
              data-ops-modal-cancel
            >
              Cancel index swap
            </.ops_button>
            <.ops_button type="submit" variant={:danger}>Promote target index</.ops_button>
          </div>
        </.form>
      </.ops_modal>
    </Layouts.app>
    """
  end

  defp drift_status_kind(_result, error) when not is_nil(error), do: :error
  defp drift_status_kind(nil, nil), do: :info

  defp drift_status_kind(result, nil),
    do: if(drift_mismatch_count(result) == 0, do: :success, else: :warning)

  defp drift_status_title(_result, error) when not is_nil(error), do: "Drift check failed"
  defp drift_status_title(nil, nil), do: "Drift not loaded"

  defp drift_status_title(result, nil) do
    if drift_mismatch_count(result) == 0,
      do: "No contract drift detected",
      else: "Contract drift detected"
  end

  defp drift_status_copy(_result, error) when not is_nil(error) do
    "Reconcile above remains usable. Fix the drift check input or backend state, then reload contract drift. Reason: #{inspect(error)}"
  end

  defp drift_status_copy(nil, nil) do
    "This check compares declared fields and settings. It does not verify document freshness."
  end

  defp drift_status_copy(result, nil) do
    mismatches = drift_mismatch_count(result)

    if mismatches == 0 do
      "Declared fields, filterable attributes, sortable attributes, faceting, and settings match this snapshot."
    else
      "#{mismatches} contract #{if mismatches == 1, do: "dimension differs", else: "dimensions differ"} from the live index. Review the differences before promoting a target index."
    end
  end

  defp drift_mismatch_count(%{dimensions: dimensions}) when is_map(dimensions) do
    Enum.count(dimensions, fn {_key, dimension} -> not Map.get(dimension, :match, false) end)
  end

  defp format_dt(nil), do: "—"

  defp format_dt(%DateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%d %H:%M:%SZ")
  end
end
