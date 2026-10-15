defmodule ScrypathOpsWeb.SyncDriftLive do
  @moduledoc """
  Read-only sync and index contract drift using `Scrypath.reconcile_sync/2` and
  `Scrypath.index_contract_drift/2`.

  On mount, **reconcile** loads automatically (without `include_index_contract_drift`).
  Index settings load automatically in a bounded, generation-scoped asynchronous read.
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
      |> assign(:drift_request, 0)
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
        |> maybe_load_settings()
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
      socket = socket |> refresh_reconcile() |> start_settings_read()

      socket =
        if is_nil(socket.assigns.reconcile_error),
          do: put_flash(socket, :info, "Sync refreshed; index settings are being checked."),
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
      {:noreply, start_settings_read(socket)}
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
      {:noreply, socket}
    end
  end

  defp maybe_load_settings(socket) do
    if connected?(socket) and is_nil(socket.assigns.drift_result) and
         not socket.assigns.drift_loading and is_nil(socket.assigns.drift_error) and
         Keyword.has_key?(socket.assigns.scrypath_opts, :backend),
       do: start_settings_read(socket),
       else: socket
  end

  defp start_settings_read(%{assigns: %{drift_loading: true}} = socket), do: socket

  defp start_settings_read(socket) do
    schema = socket.assigns.selected_schema
    generation = socket.assigns.context_generation
    opts = ScrypathOps.Schemas.runtime_opts(socket.assigns.scrypath_opts)
    request = Map.get(socket.assigns, :drift_request, 0) + 1

    socket
    |> assign(:drift_request, request)
    |> assign(:drift_loading, true)
    |> assign(:promotion_eligibility, {:blocked, :check_in_progress})
    |> start_async({:index_settings, generation, request}, fn ->
      task =
        Task.async(fn -> Scrypath.index_contract_drift(schema, opts) end)

      case Task.yield(task, 15_000) || Task.shutdown(task, :brutal_kill) do
        {:ok, result} -> result
        {:exit, reason} -> {:error, {:settings_read_failed, reason}}
        nil -> {:error, :settings_read_timeout}
      end
    end)
  end

  @impl true
  def handle_async({:index_settings, generation, request}, outcome, socket) do
    if generation == socket.assigns.context_generation and
         request == Map.get(socket.assigns, :drift_request, 0) and current_selection?(socket) do
      result =
        case outcome do
          {:ok, result} -> result
          {:exit, reason} -> {:error, {:settings_read_failed, reason}}
        end

      socket = assign(socket, :drift_loading, false)

      socket =
        case result do
          {:ok, report} ->
            socket
            |> assign(:drift_result, report)
            |> assign(:drift_error, nil)
            |> assign(:drift_loaded_at, DateTime.utc_now())
            |> assign(:drift_generation, generation)

          {:error, reason} ->
            assign(socket, :drift_error, reason)
        end

      {:noreply, refresh_promotion_eligibility(socket)}
    else
      {:noreply, socket}
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
    socket = assign(socket, :drift_request, Map.get(socket.assigns, :drift_request, 0) + 1)
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

  defp reconcile_signal_label(:pending_backend_work, report),
    do:
      counted_work(length(report.status.backend.pending), "Meilisearch task", "Meilisearch tasks") <>
        " pending"

  defp reconcile_signal_label(:pending_queue_work, report) do
    pending = length(report.status.queue.pending)
    retrying = length(report.status.queue.retrying)

    [
      if(pending > 0,
        do: counted_work(pending, "background job", "background jobs") <> " pending"
      ),
      if(retrying > 0, do: counted_work(retrying, "scheduled retry", "scheduled retries"))
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" · ")
  end

  defp reconcile_signal_label(:failed_sync_work, report),
    do:
      counted_work(
        terminal_failure_count(report),
        "failed sync operation",
        "failed sync operations"
      )

  defp reconcile_signal_label(:reindex_in_progress, _report), do: "Reindex is in progress"

  defp reconcile_signal_label(:reindex_cutover_pending, _report),
    do: "Prepared index is awaiting cutover"

  defp reconcile_signal_label(_, _report), do: "Additional sync state needs inspection"

  defp counted_work(1, singular, _plural), do: "1 " <> singular
  defp counted_work(count, _singular, plural), do: "#{count} " <> plural

  defp terminal_failure_count(report),
    do: Enum.count(report.failed_work, &(Map.get(&1, :state) == :failed))

  defp reconcile_activity(report) do
    Enum.reject(report.drift_signals, fn
      :reindex_visibility_available -> true
      :failed_sync_work -> terminal_failure_count(report) == 0
      _ -> false
    end)
  end

  defp reconcile_signal_icon(:failed_sync_work), do: "hero-exclamation-circle"
  defp reconcile_signal_icon(:reindex_cutover_pending), do: "hero-arrow-path"
  defp reconcile_signal_icon(_), do: "hero-clock"

  defp setting_effect("Filterable attributes"),
    do: "Fields allowed in query filters."

  defp setting_effect("Sortable attributes"), do: "Fields enabled for sorting search results."
  defp setting_effect("Fields"), do: "Searchable fields and their declared order."
  defp setting_effect(_), do: nil

  defp drift_dimension_label(key) do
    key
    |> to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp setting_differences(%{dimensions: dimensions}) do
    categories = [
      fields: "searchableAttributes",
      filterable_attributes: "filterableAttributes",
      sortable_attributes: "sortableAttributes",
      faceting: "faceting"
    ]

    specific =
      Enum.flat_map(categories, fn {key, _wire} ->
        case Map.get(dimensions, key) do
          %{match: false, details: details} ->
            Enum.flat_map(details, &difference_rows(drift_dimension_label(key), &1))

          _ ->
            []
        end
      end)

    covered =
      for {key, wire} <- categories, match?(%{match: false}, Map.get(dimensions, key)), do: wire

    other =
      case Map.get(dimensions, :settings) do
        %{match: false, details: details} ->
          details
          |> Enum.reject(&(Map.get(&1, :key) in covered))
          |> Enum.flat_map(fn detail ->
            difference_rows(to_string(Map.get(detail, :key, "Setting")), detail)
          end)

        _ ->
          []
      end

    specific ++ other
  end

  defp difference_rows(label, {:only_declared, value}),
    do: [
      %{
        label: label,
        declared: display_setting(value),
        live:
          if(label == "Filterable attributes",
            do: "Not enabled for filtering",
            else: "Not applied in the live index"
          )
      }
    ]

  defp difference_rows(label, {:only_applied, value}),
    do: [%{label: label, declared: "Not declared", live: display_setting(value)}]

  defp difference_rows(label, %{declared: declared, applied: applied})
       when is_map(declared) and is_map(applied) do
    (Map.keys(declared) ++ Map.keys(applied))
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.filter(&(Map.get(declared, &1) != Map.get(applied, &1)))
    |> Enum.map(fn key ->
      %{
        label: "#{label} · #{key}",
        declared: display_setting(Map.get(declared, key)),
        live: display_setting(Map.get(applied, key))
      }
    end)
  end

  defp difference_rows(label, %{declared: declared, applied: applied}),
    do: [%{label: label, declared: display_setting(declared), live: display_setting(applied)}]

  defp difference_rows(label, {:truncated, true}),
    do: [
      %{
        label: label,
        declared: "Additional differences omitted by the report limit",
        live: "Use the library report for full inspection"
      }
    ]

  defp difference_rows(label, detail),
    do: [%{label: label, declared: inspect(detail), live: "Comparison details unavailable"}]

  defp display_setting(value) when is_binary(value), do: value
  defp display_setting(value), do: Jason.encode!(value, pretty: true)

  defp matching_settings(%{dimensions: dimensions}) do
    dimensions
    |> Enum.filter(fn {_key, dim} -> dim.match end)
    |> Enum.map_join(", ", fn {key, _dim} -> drift_dimension_label(key) end)
  end

  defp sync_mode_label(:oban), do: "Background sync with Oban"
  defp sync_mode_label(:inline), do: "Inline sync"
  defp sync_mode_label(:manual), do: "Manual sync"
  defp sync_mode_label(mode), do: to_string(mode)

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
      <.ops_toolbar class="items-end gap-4">
        <.ops_page_header
          title="Sync and drift"
          subtitle="Check sync work and compare declared settings with Meilisearch."
        />
        <.ops_refresh_control
          id="sync-drift-refresh"
          checked_at={@reconcile_loaded_at}
          checked_label="Sync checked"
          phx-click="refresh_reconcile"
          aria_label="Refresh sync and index settings"
          disabled={!@selected_schema}
        />
      </.ops_toolbar>

      <.ops_trail current={:sync_drift} class="mt-4" />

      <div>
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
        title="Sync status"
      >
        <dl :if={@reconcile_result} class="ops-sync-facts">
          <div>
            <dt>Meilisearch index</dt>
            <dd>
              <.ops_inline_code>{@reconcile_result.index}</.ops_inline_code>
            </dd>
          </div>
          <div>
            <dt>Synchronization</dt>
            <dd>{sync_mode_label(@reconcile_result.mode)}</dd>
          </div>
          <div>
            <dt>Sync activity</dt>
            <dd>
              <span :if={reconcile_activity(@reconcile_result) == []}>
                No pending or failed work reported.
              </span>
              <ul :if={reconcile_activity(@reconcile_result) != []} class="ops-sync-work">
                <li
                  :for={signal <- reconcile_activity(@reconcile_result)}
                  data-tone={if signal == :failed_sync_work, do: "error"}
                >
                  <.icon name={reconcile_signal_icon(signal)} class="size-4" />
                  <.link
                    :if={signal == :failed_sync_work}
                    navigate={OperatorSelection.path(@mount_path, "failed-sync", @selected_schema)}
                    class="ops-text-action"
                  >
                    {reconcile_signal_label(signal, @reconcile_result)}
                    <.icon name="hero-arrow-right" class="size-4" />
                  </.link>
                  <.link
                    :if={signal in [:pending_queue_work, :pending_backend_work]}
                    navigate={OperatorSelection.path(@mount_path, "health", @selected_schema)}
                    class="ops-sync-activity-link"
                  >
                    {reconcile_signal_label(signal, @reconcile_result)}
                    <.icon name="hero-arrow-right" class="size-4" />
                  </.link>
                  <span :if={
                    signal not in [:failed_sync_work, :pending_queue_work, :pending_backend_work]
                  }>
                    {reconcile_signal_label(signal, @reconcile_result)}
                  </span>
                </li>
              </ul>
              <.ops_help_link
                :if={reconcile_activity(@reconcile_result) != []}
                href={"#{@mount_path}/help#sync"}
              >
                About sync activity
              </.ops_help_link>
            </dd>
          </div>
        </dl>

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
        title="Index settings"
        class="mt-6"
      >
        <:metadata>
          <.ops_time
            :if={@selected_schema && Keyword.has_key?(@scrypath_opts, :backend)}
            id="settings-checked-at"
            label="Settings checked"
            dt={@drift_loaded_at}
            state_text={if @drift_error, do: "Not available", else: "Checking…"}
            class="ops-settings-check"
          />
        </:metadata>

        <div
          :if={@drift_loading}
          class="space-y-3"
          role="status"
          aria-label="Loading index settings"
        >
          <p class="text-ops-body text-base-content/70">
            Comparing declared settings with Meilisearch…
          </p>
          <.ops_loading lines={4} label="Loading index settings" />
        </div>

        <.ops_status
          :if={@drift_loading && @drift_result}
          kind={:info}
          title="Checking index settings"
          role="status"
          neutral
        >
          The previous settings comparison remains below until this check finishes.
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

        <div :if={@drift_result} class="space-y-3">
          <.ops_table
            :if={setting_differences(@drift_result) != []}
            class="ops-settings-diff"
            tabindex="0"
            role="region"
            aria-label="Index settings differences"
          >
            <thead>
              <tr>
                <th scope="col">Setting</th>
                <th scope="col">Declared in schema</th>
                <th scope="col">Live in Meilisearch</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={difference <- setting_differences(@drift_result)}>
                <th scope="row" class="align-top">
                  <span>{difference.label}</span>
                  <span :if={setting_effect(difference.label)} class="ops-setting-description">
                    {setting_effect(difference.label)}
                  </span>
                </th>
                <td class="align-top">
                  <pre class="whitespace-pre-wrap break-words text-ops-sm">{difference.declared}</pre>
                </td>
                <td class="align-top">
                  <pre
                    class="ops-setting-live whitespace-pre-wrap break-words text-ops-sm"
                    data-missing={
                      difference.live in [
                        "Not enabled for filtering",
                        "Not applied in the live index"
                      ]
                    }
                  >{difference.live}</pre>
                </td>
              </tr>
            </tbody>
          </.ops_table>
          <p :if={setting_differences(@drift_result) != []} class="ops-search-query-hint">
            Apply the intended settings through your app's setup or reindex workflow, then Refresh.
            <.ops_help_link href={"#{@mount_path}/help#settings"}>
              Understanding settings differences
            </.ops_help_link>
          </p>
          <.ops_disclosure
            summary="Full comparison details"
            variant={:compact}
          >
            <p :if={matching_settings(@drift_result) != ""} class="text-ops-sm text-base-content/70">
              Matching: {matching_settings(@drift_result)}.
            </p>
            <.ops_code_block
              :if={match?(%{match: false}, Map.get(@drift_result.dimensions, :settings))}
              variant={:embedded}
              text={Jason.encode!(Map.get(@drift_result.dimensions, :settings).details, pretty: true)}
            />
          </.ops_disclosure>
        </div>
      </.ops_section>

      <.ops_section
        :if={
          @selected_schema &&
            (@recovery_handle || @recovery_observation_error || @recovery_document_observation)
        }
        id="document-freshness"
        class="mt-6"
        title="Document freshness"
        subtitle="Check the expected effect for the exact recovery task in this schema's active index."
      >
        <:metadata>
          <.ops_time
            :if={@recovery_document_observation && @recovery_document_observation.checked_at}
            id="documents-checked-at"
            label="Checked"
            dt={@recovery_document_observation.checked_at}
          />
        </:metadata>
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
        :if={
          @selected_schema &&
            (@recovery_handle || @recovery_observation_error || @recovery_document_observation)
        }
        id="ordinary-recovery"
        class="mt-6"
        title="Retry status"
        subtitle="Follow the exact retry from its queue job to Meilisearch and document visibility."
      >
        <:metadata>
          <.ops_time
            :if={@recovery_checked_at}
            id="recovery-checked-at"
            label="Checked"
            dt={@recovery_checked_at}
          />
        </:metadata>
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
        class="ops-disclosure ops-sync-advanced"
        open={@promotion_status != nil}
      >
        <summary
          id="index-promotion-summary"
          class="cursor-pointer font-medium"
        >
          Advanced: index promotion
        </summary>
        <div class="space-y-3 pt-3">
          <p class="text-ops-body text-base-content/75">
            Promotion swaps the live and prepared indexes for <.ops_inline_code>{module_flat_name(@selected_schema)}</.ops_inline_code>.
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

      <nav class="ops-sync-related" aria-label="Related search views">
        <.link navigate={@mount_path} class="ops-sync-activity-link">
          Return to Control Room
        </.link>
        <.link
          :if={@selected_schema}
          navigate={OperatorSelection.path(@mount_path, "health", @selected_schema)}
          class="ops-sync-activity-link"
        >
          Inspect search health
        </.link>
      </nav>

      <.ops_modal
        :if={@confirm_swap? && @selected_schema}
        id="confirm-index-promotion"
        title="Confirm index promotion"
        description="Meilisearch will exchange the live and prepared indexes when its swap task completes."
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
          <p>Effect: replace live index contents and settings with the prepared target.</p>
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

  defp drift_status_title(_result, error) when not is_nil(error),
    do: "Index settings could not be checked"

  defp drift_status_title(nil, nil), do: "Index settings not checked"

  defp drift_status_title(result, nil) do
    if drift_mismatch_count(result) == 0,
      do: "Index settings match",
      else: "Index settings differ"
  end

  defp drift_status_copy(_result, error) when not is_nil(error) do
    "Sync status is checked separately. Previous comparisons keep their original checked time. Check the Meilisearch connection, then use Refresh. Reason: #{inspect(error)}"
  end

  defp drift_status_copy(nil, nil) do
    "This check compares declared fields and settings. It does not verify document freshness."
  end

  defp drift_status_copy(result, nil) do
    mismatches = drift_mismatch_count(result)

    if mismatches == 0 do
      "Declared fields, filterable attributes, sortable attributes, faceting, and settings match this snapshot."
    else
      "Review the differences below. No settings have been changed."
    end
  end

  defp drift_mismatch_count(%{dimensions: dimensions}) when is_map(dimensions) do
    Enum.count(dimensions, fn {_key, dimension} -> not Map.get(dimension, :match, false) end)
  end
end
