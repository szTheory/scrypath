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
  alias Scrypath.Meilisearch.{Client, TaskPayload, Tasks}
  alias Scrypath.Operations.Task, as: OperationTask

  @impl true
  def mount(_params, _session, socket) do
    {allowlist, scrypath_opts} = initial_route_config(socket)

    socket =
      socket
      |> assign(:page_title, "Sync and drift")
      |> assign(:schema_allowlist, allowlist)
      |> assign(:scrypath_opts, scrypath_opts)
      |> assign(:fixture_scenario, nil)
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
      |> assign(:recovery_runtime, nil)
      |> assign(:recovery_origin_generation, nil)
      |> assign(:recovery_status, nil)
      |> assign(:recovery_evidence, nil)
      |> assign(:recovery_checked_at, nil)
      |> assign(:recovery_loading, false)
      |> assign(:promotion_task_id, nil)
      |> assign(:promotion_status, nil)
      |> assign(:promotion_loading, false)
      |> assign(:promotion_check_loading, false)
      |> assign(:promotion_context, nil)
      |> assign(:promotion_schema, nil)
      |> assign(:promotion_indexes, nil)
      |> assign(:confirm_swap?, false)
      |> assign(:promotion_eligibility, {:blocked, :reconcile_not_current})

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {allowlist, scrypath_opts, fixture_scenario} =
      route_config(params, Map.get(socket.assigns, :live_action))

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
      selected != socket.assigns.selected_schema or error != socket.assigns.selection_error or
        fixture_scenario != socket.assigns.fixture_scenario

    socket =
      socket
      |> assign(:schema_allowlist, allowlist)
      |> assign(:scrypath_opts, scrypath_opts)
      |> assign(:fixture_scenario, fixture_scenario)
      |> assign(:selected_schema, selected)
      |> assign(:selection_error, error)
      |> maybe_advance_generation(changed?)

    socket =
      if selected do
        socket
        |> load_reconcile_on_mount()
        |> seed_phase175_promotion(fixture_scenario)
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

  defp initial_route_config(%{assigns: %{live_action: :phase175}}) do
    if Mix.env() == :test do
      source = phase175_fixture_source()
      {source.allowlist("accepted-processing"), source.opts("accepted-processing")}
    else
      {ScrypathOps.Schemas.allowlist(), ScrypathOps.Schemas.scrypath_opts()}
    end
  end

  defp initial_route_config(_socket),
    do: {ScrypathOps.Schemas.allowlist(), ScrypathOps.Schemas.scrypath_opts()}

  defp route_config(params, :phase175) do
    if Mix.env() == :test do
      source = phase175_fixture_source()
      scenario = Map.get(params, "scenario", "accepted-processing")

      case source.scenario(scenario) do
        {:ok, fixture} -> {fixture.allowlist, fixture.opts, scenario}
        {:error, :unknown_scenario} -> {[], source.opts("accepted-processing"), scenario}
      end
    else
      {ScrypathOps.Schemas.allowlist(), ScrypathOps.Schemas.scrypath_opts(), nil}
    end
  end

  defp route_config(_params, _action),
    do: {ScrypathOps.Schemas.allowlist(), ScrypathOps.Schemas.scrypath_opts(), nil}

  defp phase175_fixture_source,
    do: Module.concat(["ScrypathOps.Test.Phase175FixtureSource"])

  defp seed_phase175_promotion(socket, scenario) when is_binary(scenario) do
    if Mix.env() == :test and socket.assigns.live_action == :phase175 do
      source = phase175_fixture_source()

      case source.scenario(scenario) do
        {:ok, %{task_uid: task_id}} ->
          schema = socket.assigns.selected_schema
          indexes = source.indexes(schema)

          context = %{
            generation: socket.assigns.context_generation,
            task_id: task_id,
            schema: schema,
            indexes: indexes,
            runtime:
              promotion_runtime_identity(
                schema,
                ScrypathOps.Schemas.runtime_opts(socket.assigns.scrypath_opts)
              )
          }

          socket
          |> assign(:promotion_task_id, task_id)
          |> assign(:promotion_status, :accepted)
          |> assign(:promotion_loading, false)
          |> assign(:promotion_check_loading, false)
          |> assign(:promotion_context, context)
          |> assign(:promotion_schema, schema)
          |> assign(:promotion_indexes, indexes)

        _ ->
          socket
      end
    else
      socket
    end
  end

  defp seed_phase175_promotion(socket, _scenario), do: socket

  defp active_allowlist(%{assigns: %{live_action: :phase175, fixture_scenario: scenario}})
       when is_binary(scenario) do
    if Mix.env() == :test do
      phase175_fixture_source().allowlist(scenario)
    else
      ScrypathOps.Schemas.allowlist()
    end
  end

  defp active_allowlist(_socket), do: ScrypathOps.Schemas.allowlist()

  defp active_runtime_opts(socket) do
    if Mix.env() == :test and Map.get(socket.assigns, :live_action) == :phase175 do
      socket.assigns.scrypath_opts |> ScrypathOps.Schemas.runtime_opts()
    else
      ScrypathOps.Schemas.scrypath_opts() |> ScrypathOps.Schemas.runtime_opts()
    end
  end

  defp load_reconcile_on_mount(socket) do
    case {socket.assigns.selected_schema,
          Keyword.has_key?(socket.assigns.scrypath_opts, :backend)} do
      {nil, _} ->
        socket

      {_mod, false} ->
        socket
        |> assign(:reconcile_error, :missing_backend)
        |> refresh_promotion_eligibility()

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
            |> put_flash(:error, "Sync status could not be checked. Refresh to try again.")
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
      {:noreply, socket}
    else
      {:noreply, unavailable(socket)}
    end
  end

  def handle_event("check_swap_status", _params, socket) do
    case {socket.assigns.promotion_task_id, socket.assigns.promotion_context} do
      {task_id, context} when is_integer(task_id) and is_map(context) ->
        cond do
          socket.assigns.promotion_check_loading ->
            {:noreply, socket}

          promotion_context_current?(socket, context) ->
            {:noreply, start_promotion_check(socket, context)}

          same_promotion_task?(socket, context) ->
            {:noreply,
             socket
             |> assign(:promotion_status, :unknown)
             |> assign(:promotion_loading, false)
             |> assign(:promotion_check_loading, false)}

          true ->
            {:noreply, socket}
        end

      _ ->
        {:noreply,
         socket
         |> assign(:promotion_status, :unknown)
         |> assign(:promotion_check_loading, false)}
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
         |> assign(:recovery_status, :unknown)
         |> assign(:recovery_evidence, nil)
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
    case OperatorSelection.resolve(%{"schema" => mod_str}, active_allowlist(socket)) do
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
    cond do
      generation == socket.assigns.context_generation and
        handle == socket.assigns.recovery_handle and current_selection?(socket) and
          recovery_runtime_current?(socket) ->
        {status, evidence} =
          case result do
            {status, evidence} when is_map(evidence) or is_nil(evidence) -> {status, evidence}
            status -> {status, socket.assigns.recovery_evidence}
          end

        evidence = evidence || socket.assigns.recovery_evidence

        {:noreply,
         socket
         |> assign(:recovery_status, status)
         |> assign(:recovery_evidence, evidence)
         |> assign(:recovery_checked_at, DateTime.utc_now())
         |> assign(:recovery_loading, false)}

      generation == socket.assigns.context_generation and
          handle == socket.assigns.recovery_handle ->
        {:noreply, stale_recovery_result(socket)}

      true ->
        {:noreply, socket}
    end
  end

  def handle_async({:recovery_observation, generation, handle}, {:exit, _reason}, socket) do
    cond do
      generation == socket.assigns.context_generation and
        handle == socket.assigns.recovery_handle and current_selection?(socket) and
          recovery_runtime_current?(socket) ->
        {:noreply,
         socket
         |> assign(:recovery_status, :unknown)
         |> assign(:recovery_checked_at, DateTime.utc_now())
         |> assign(:recovery_loading, false)}

      generation == socket.assigns.context_generation and
          handle == socket.assigns.recovery_handle ->
        {:noreply, stale_recovery_result(socket)}

      true ->
        {:noreply, socket}
    end
  end

  def handle_async(
        {:promotion_swap, _generation, _task_id},
        {:ok, {generation, task_id, result}},
        socket
      ) do
    context = socket.assigns.promotion_context

    cond do
      is_map(context) and context.generation == generation and context.task_id == task_id and
          promotion_context_current?(socket, context) ->
        socket
        |> assign(:promotion_loading, false)
        |> assign(:promotion_status, promotion_wait_status(result, context.task_id))
        |> maybe_refresh_after_promotion_success(result, context.task_id)
        |> invalidate_recovery_claim()
        |> refresh_promotion_eligibility()
        |> then(&{:noreply, &1})

      is_map(context) and context.generation == generation and context.task_id == task_id and
          same_promotion_task?(socket, context) ->
        {:noreply,
         socket
         |> assign(:promotion_loading, false)
         |> assign(:promotion_status, :unknown)
         |> invalidate_recovery_claim()}

      true ->
        {:noreply, socket}
    end
  end

  def handle_async({:promotion_swap, generation, task_id}, {:exit, _reason}, socket) do
    context = socket.assigns.promotion_context

    if is_map(context) and context.generation == generation and context.task_id == task_id and
         promotion_context_current?(socket, context) do
      {:noreply,
       socket
       |> assign(:promotion_loading, false)
       |> assign(:promotion_status, :unknown)}
    else
      if is_map(context) and context.generation == generation and context.task_id == task_id and
           same_promotion_task?(socket, context) do
        {:noreply,
         socket
         |> assign(:promotion_loading, false)
         |> assign(:promotion_status, :unknown)}
      else
        {:noreply, socket}
      end
    end
  end

  def handle_async(
        {:promotion_check, _generation, _task_id},
        {:ok, {context, result}},
        socket
      ) do
    cond do
      promotion_context_current?(socket, context) ->
        {:noreply,
         socket
         |> assign(:promotion_check_loading, false)
         |> assign(:promotion_status, promotion_check_status(result, context.task_id))}

      same_promotion_task?(socket, context) ->
        {:noreply,
         socket
         |> assign(:promotion_check_loading, false)
         |> assign(:promotion_status, :unknown)}

      true ->
        {:noreply, socket}
    end
  end

  def handle_async({:promotion_check, generation, task_id}, {:exit, _reason}, socket) do
    context = socket.assigns.promotion_context

    cond do
      is_map(context) and context.generation == generation and context.task_id == task_id and
          promotion_context_current?(socket, context) ->
        {:noreply,
         socket
         |> assign(:promotion_check_loading, false)
         |> assign(:promotion_status, :unknown)}

      is_map(context) and context.generation == generation and context.task_id == task_id and
          same_promotion_task?(socket, context) ->
        {:noreply,
         socket
         |> assign(:promotion_check_loading, false)
         |> assign(:promotion_status, :unknown)}

      true ->
        {:noreply, socket}
    end
  end

  defp module_flat_name(mod) when is_atom(mod), do: OperatorSelection.canonical(mod)

  defp recovery_status_label(:accepted), do: "Retry accepted"
  defp recovery_status_label(:running), do: "Retry running"

  defp recovery_status_label(:queue_only_completed),
    do: "Queue job completed; backend evidence pending"

  defp recovery_status_label(:verified), do: "Recovery verified"
  defp recovery_status_label(:failed), do: "Recovery failed"
  defp recovery_status_label(:timed_out), do: "Recovery check timed out"
  defp recovery_status_label(_), do: "Recovery unknown"

  defp recovery_source_label(:oban), do: "Oban"
  defp recovery_source_label(:meilisearch), do: "Meilisearch"
  defp recovery_source_label(source) when is_binary(source), do: source
  defp recovery_source_label(_), do: "Unknown source"

  defp recovery_status_kind(:verified), do: :success
  defp recovery_status_kind(:failed), do: :error

  defp recovery_status_kind(status) when status in [:accepted, :running, :queue_only_completed],
    do: :warning

  defp recovery_status_kind(_), do: :neutral

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
    |> assign(:recovery_runtime, nil)
    |> assign(:recovery_origin_generation, nil)
    |> assign(:recovery_status, nil)
    |> assign(:recovery_evidence, nil)
    |> assign(:recovery_checked_at, nil)
    |> assign(:recovery_loading, false)
    |> assign(:promotion_task_id, nil)
    |> assign(:promotion_status, nil)
    |> assign(:promotion_loading, false)
    |> assign(:promotion_check_loading, false)
    |> assign(:promotion_context, nil)
    |> assign(:promotion_schema, nil)
    |> assign(:promotion_indexes, nil)
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
    |> assign(:recovery_runtime, nil)
    |> assign(:recovery_origin_generation, nil)
    |> assign(:recovery_status, nil)
    |> assign(:recovery_evidence, nil)
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
      socket
      |> assign(:recovery_handle, handle)
      |> assign(:recovery_runtime, promotion_runtime_identity(schema, opts))
      |> assign(:recovery_status, :unknown)
      |> assign(:recovery_loading, true)

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
        :timed_out
    end
  rescue
    _ -> :unknown
  end

  defp observe_recovery_now(context, handle, schema, opts, operator_opts) do
    observed = RecoveryObservation.observe(context, handle)
    evidence = if is_map(observed), do: recovery_receipt_evidence(observed), else: nil

    result =
      with true <- schema in ScrypathOps.Schemas.allowlist(),
           receipt when is_map(receipt) <- observed,
           true <- receipt.generation == context.generation,
           true <- current_runtime_matches?(receipt, opts),
           {:ok, expected_index} <- active_index(schema, opts),
           true <- receipt.index == expected_index,
           {:ok, job} <- read_recovery_job(receipt),
           {:ok, queue_state} <- validate_recovery_job(job, receipt) do
        status =
          case receipt.task_uid do
            task_uid when is_integer(task_uid) ->
              verify_task_and_documents(task_uid, receipt, schema, opts, operator_opts)

            _ when queue_state == :completed ->
              :queue_only_completed

            _ when queue_state == :running ->
              :running

            _ ->
              :accepted
          end

        {status, Map.take(receipt, [:replacement_job, :attempt, :task_uid, :index])}
      else
        false -> :unknown
        :unknown -> :unknown
        {:error, :job_running} -> :running
        {:error, :queue_only_completed} -> :queue_only_completed
        {:error, :job_failed} -> :failed
        {:error, _} -> :unknown
        _ -> :unknown
      end

    case result do
      {status, _existing_evidence} -> {status, evidence}
      status -> {status, evidence}
    end
  end

  defp recovery_receipt_evidence(receipt) do
    Map.take(receipt, [
      :replacement_job,
      :attempt,
      :task_uid,
      :operation,
      :schema,
      :source_failure,
      :index
    ])
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

  defp recovery_runtime_current?(socket) do
    runtime = Map.get(socket.assigns, :recovery_runtime)

    is_map(runtime) and
      runtime ==
        promotion_runtime_identity(socket.assigns.selected_schema, active_runtime_opts(socket))
  rescue
    _ -> false
  end

  defp stale_recovery_result(socket) do
    if current_selection?(socket) do
      socket
      |> assign(:recovery_status, :unknown)
      |> assign(:recovery_checked_at, nil)
      |> assign(:recovery_loading, false)
    else
      unavailable(socket)
    end
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
         :ok <- validate_recovery_task(task, receipt, task_uid),
         {:ok, expected} <- read_expected_effects(schema, receipt, operator_opts),
         {:ok, observation} <-
           ScrypathOps.DocumentObservation.check(
             Map.merge(receipt, expected),
             task,
             Keyword.put(opts, :document_id_field, Scrypath.Schema.Metadata.document_id(schema))
           ) do
      observation.state
    else
      {:error, :job_running} -> :running
      {:error, :queue_only_completed} -> :queue_only_completed
      {:error, :job_failed} -> :failed
      _ -> :unknown
    end
  rescue
    _ -> :unknown
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
        {:error, :job_failed}

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
    source = get_in(receipt, [:source_failure, :source])

    with {:ok, rows} when is_list(rows) <- Scrypath.failed_sync_work(schema, opts),
         row when not is_nil(row) <-
           Enum.find(rows, &(&1.source == source and to_string(&1.id) == to_string(source_id))),
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
           active_allowlist(socket)
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
          |> assign(:reconcile_result, nil)
          |> assign(:reconcile_loaded_at, nil)
          |> assign(:reconcile_generation, nil)
          |> assign(:reconcile_error, reason)
          |> refresh_promotion_eligibility()
          |> put_flash(:error, "Sync status could not be checked. Refresh to try again.")
      end
    else
      socket
      |> assign(:reconcile_result, nil)
      |> assign(:reconcile_loaded_at, nil)
      |> assign(:reconcile_generation, nil)
      |> assign(:reconcile_error, :missing_backend)
      |> refresh_promotion_eligibility()
      |> put_flash(:error, sync_error_copy(:missing_backend))
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
          |> assign(:drift_result, nil)
          |> assign(:drift_loaded_at, nil)
          |> assign(:drift_generation, nil)
          |> assign(:drift_error, reason)
          |> refresh_promotion_eligibility()
      end
    else
      socket
      |> assign(:drift_result, nil)
      |> assign(:drift_generation, nil)
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
              generation = socket.assigns.context_generation
              task_id = Map.get(task, :uid)
              indexes = {Map.get(task, :live_index), Map.get(task, :target_index)}

              context =
                if is_integer(task_id) do
                  %{
                    generation: generation,
                    task_id: task_id,
                    schema: mod,
                    indexes: indexes,
                    runtime: promotion_runtime_identity(mod, opts)
                  }
                end

              socket =
                socket
                |> assign(:promotion_task_id, task_id)
                |> assign(
                  :promotion_status,
                  if(is_integer(task_id), do: :accepted, else: :unknown)
                )
                |> assign(:promotion_loading, is_integer(task_id))
                |> assign(:promotion_check_loading, false)
                |> assign(:promotion_context, context)
                |> assign(:promotion_schema, mod)
                |> assign(:promotion_indexes, indexes)

              if is_integer(task_id) do
                start_async(socket, {:promotion_swap, generation, task_id}, fn ->
                  result = Tasks.wait_for_task(task, task_wait_opts(opts))
                  {generation, task_id, result}
                end)
              else
                put_flash(
                  socket,
                  :warning,
                  "Index swap was accepted without a usable task ID. Check the current index state."
                )
              end

            {:error, reason} ->
              put_flash(socket, :error, "Index swap was not accepted: #{inspect(reason)}")
          end

        {:blocked, reason} ->
          put_flash(socket, :error, "Index promotion blocked: #{promotion_reason(reason)}")
      end
    end)
  end

  defp fetch_promotion_prerequisites(socket) do
    mod = socket.assigns.selected_schema
    operator_opts = socket.assigns.scrypath_opts
    opts = ScrypathOps.Schemas.runtime_opts(operator_opts)

    if (mod && mod in active_allowlist(socket)) and
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
  defp promotion_reason(:contract_failed), do: "refresh the index configuration check"
  defp promotion_reason(:reconcile_not_current), do: "refresh sync and queue status"
  defp promotion_reason(:contract_not_current), do: "check the index configuration"
  defp promotion_reason(:check_in_progress), do: "wait for the current check"
  defp promotion_reason(:context_mismatch), do: "refresh checks for this schema and index"
  defp promotion_reason(:indexes_not_distinct), do: "confirm live and target indexes differ"
  defp promotion_reason(:target_unobserved), do: "observe the prepared target index first"
  defp promotion_reason(:backend_work_pending), do: "wait for backend tasks to finish"
  defp promotion_reason(:queue_work_pending), do: "wait for queued work to finish"
  defp promotion_reason(:reindex_pending), do: "wait for reindex work to finish"
  defp promotion_reason(:cutover_pending), do: "wait for the current cutover to finish"
  defp promotion_reason(:failed_work), do: "resolve failed sync work first"
  defp promotion_reason(:contract_mismatch), do: "resolve index configuration differences first"
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

  defp promotion_status_title(:accepted), do: "Index swap accepted"
  defp promotion_status_title(:running), do: "Index swap running"
  defp promotion_status_title(:completed), do: "Index swap completed"
  defp promotion_status_title({:failed, :cancelled}), do: "Index swap cancelled"
  defp promotion_status_title({:failed, _}), do: "Index swap failed"
  defp promotion_status_title(:timed_out), do: "Index swap outcome unconfirmed"
  defp promotion_status_title(:unknown), do: "Index swap outcome unconfirmed"
  defp promotion_status_title(_), do: "Index swap status"

  defp task_wait_opts(opts) do
    opts
    |> Keyword.put_new(:inline_poll_interval, 50)
    |> Keyword.put_new(:inline_timeout, 15_000)
  end

  defp start_promotion_check(socket, context) do
    opts = active_runtime_opts(socket)

    socket
    |> assign(:promotion_check_loading, true)
    |> start_async({:promotion_check, context.generation, context.task_id}, fn ->
      result = observe_promotion_task(context.task_id, opts)
      {context, result}
    end)
  end

  defp observe_promotion_task(task_id, opts) do
    client = Keyword.get(opts, :meilisearch_client) || Client

    if Code.ensure_loaded?(client) and function_exported?(client, :task, 2) do
      case apply(client, :task, [task_id, opts]) do
        {:ok, response} -> TaskPayload.normalize(response, :poll)
        {:error, reason} -> {:error, reason}
        _ -> {:error, :invalid_task_response}
      end
    else
      {:error, :task_client_unavailable}
    end
  rescue
    _ -> {:error, :task_observation_failed}
  catch
    _, _ -> {:error, :task_observation_failed}
  end

  defp promotion_check_status({:ok, %{uid: task_id, status: :enqueued}}, task_id), do: :accepted
  defp promotion_check_status({:ok, %{uid: task_id, status: :processing}}, task_id), do: :running
  defp promotion_check_status({:ok, %{uid: task_id, status: :succeeded}}, task_id), do: :completed

  defp promotion_check_status({:ok, %{uid: task_id, status: :failed}}, task_id),
    do: {:failed, :task_failed}

  defp promotion_check_status({:ok, %{uid: task_id, status: :cancelled}}, task_id),
    do: {:failed, :cancelled}

  defp promotion_check_status(_, _task_id), do: :unknown

  defp promotion_wait_status({:ok, %OperationTask{id: task_id, state: :succeeded}}, task_id),
    do: :completed

  defp promotion_wait_status(
         {:error, {:task_failed, %OperationTask{id: task_id, state: :failed}}},
         task_id
       ),
       do: {:failed, :task_failed}

  defp promotion_wait_status(
         {:error, {:cancelled, %OperationTask{id: task_id, state: :cancelled}}},
         task_id
       ),
       do: {:failed, :cancelled}

  defp promotion_wait_status({:error, {:timeout, _}}, _task_id), do: :timed_out
  defp promotion_wait_status(_, _task_id), do: :unknown

  defp maybe_refresh_after_promotion_success(
         socket,
         {:ok, %OperationTask{id: task_id, state: :succeeded}},
         task_id
       ),
       do: socket |> load_reconcile_on_mount() |> refresh_drift()

  defp maybe_refresh_after_promotion_success(socket, _result, _task_id), do: socket

  defp same_promotion_task?(socket, context) do
    context.generation == socket.assigns.context_generation and
      context.task_id == socket.assigns.promotion_task_id and
      context.schema == socket.assigns.promotion_schema and
      context.indexes == socket.assigns.promotion_indexes
  end

  defp promotion_context_current?(socket, context) when is_map(context) do
    current_runtime =
      promotion_runtime_identity(
        context.schema,
        active_runtime_opts(socket)
      )

    same_promotion_task?(socket, context) and
      context.schema == socket.assigns.selected_schema and
      context.schema in active_allowlist(socket) and
      current_selection?(socket) and
      context == socket.assigns.promotion_context and
      context.runtime == current_runtime
  rescue
    _ -> false
  end

  defp promotion_context_current?(_socket, _context), do: false

  defp promotion_runtime_identity(schema, opts) do
    instance = Keyword.get(opts, :oban)

    oban_state =
      if is_atom(instance) and not is_nil(instance), do: oban_config(instance), else: {:ok, %{}}

    {repo, prefix} =
      case oban_state do
        {:ok, config} ->
          {Map.get(config, :repo) || Keyword.get(opts, :repo),
           Map.get(config, :prefix) || Keyword.get(opts, :prefix)}

        _ ->
          {Keyword.get(opts, :repo), Keyword.get(opts, :prefix)}
      end

    %{
      schema: schema,
      backend: Keyword.get(opts, :backend),
      endpoint: endpoint_identity(Keyword.get(opts, :meilisearch_url)),
      index_prefix: Keyword.get(opts, :index_prefix),
      meilisearch_client: Keyword.get(opts, :meilisearch_client) || Client,
      oban: instance,
      repo: repo,
      prefix: prefix,
      node: node()
    }
  end

  defp invalidate_recovery_claim(socket) do
    socket
    |> assign(:recovery_status, :unknown)
    |> assign(:recovery_evidence, nil)
    |> assign(:recovery_checked_at, nil)
    |> assign(:recovery_loading, false)
  end

  defp reconcile_signal_label(:reindex_visibility_available), do: "Reindex task history available"
  defp reconcile_signal_label(:pending_backend_work), do: "Backend tasks pending"
  defp reconcile_signal_label(:pending_queue_work), do: "Queue jobs pending"
  defp reconcile_signal_label(:failed_sync_work), do: "Failed sync work"
  defp reconcile_signal_label(:reindex_in_progress), do: "Reindex in progress"
  defp reconcile_signal_label(:reindex_cutover_pending), do: "Index swap pending"

  defp reconcile_signal_label(signal) do
    signal
    |> to_string()
    |> String.trim_leading(":")
    |> String.replace("_", " ")
  end

  defp sync_summary(report) do
    signals = report.drift_signals

    cond do
      :failed_sync_work in signals ->
        {"Sync failures need attention", "Review the failure reason before retrying."}

      :pending_backend_work in signals or :pending_queue_work in signals ->
        {"Sync work is pending", "Refresh sync status to check progress."}

      :reindex_in_progress in signals or :reindex_cutover_pending in signals ->
        {"Reindex work is pending", "Refresh sync status to check progress."}

      report.reindex.task_state == :failed ->
        {"A reindex task failed", "Review the reindex evidence before promoting an index."}

      report.reindex.task_state == :unknown ->
        {"Reindex status is unknown", "Refresh sync status to check again."}

      true ->
        {"No pending or failed sync work found", nil}
    end
  end

  defp sync_error_copy(:missing_backend) do
    "Sync status is unavailable because the backend is not configured. Configure the backend, then refresh to check again."
  end

  defp sync_error_copy(_reason) do
    "Sync status is incomplete because a required backend task or queue read failed. Refresh to try again, then review the backend and queue configuration if needed."
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
      recovery_target={@recovery_target}
    >
      <.ops_page_header
        title="Sync and drift"
        subtitle="Check sync progress and compare index configuration."
      />

      <.ops_trail current={:sync_drift} />

      <.ops_panel>
        <.form for={%{}} id="sync-drift-schema-form" phx-change="select_schema">
          <.ops_schema_select
            id="sync-schema-select"
            schemas={@schema_allowlist}
            selected={@selected_schema}
          />
        </.form>
      </.ops_panel>

      <.ops_panel :if={@recovery_handle} id="recovery-observation">
        <.ops_section
          title="Retry status"
          subtitle="Check whether this retry reached the queue, search backend, and live index."
          meta={if @recovery_checked_at, do: "checked #{format_dt(@recovery_checked_at)}"}
        >
          <:actions>
            <.ops_button
              phx-click="refresh_recovery_status"
              phx-disable-with="Checking…"
              disabled={@recovery_loading || !@selected_schema}
            >
              Refresh recovery status
            </.ops_button>
          </:actions>
          <.ops_status
            kind={recovery_status_kind(@recovery_status)}
            title={recovery_status_label(@recovery_status)}
          >
            <span
              :if={!@recovery_loading and @recovery_status in [:unknown, :timed_out]}
              data-testid="recovery-unavailable"
            >
              The receipt or one of its queue, task, or document reads is unavailable. The selected
              schema and any known retry identity remain shown. Refresh checks this same retry; it
              does not submit work.
            </span>
            <span :if={@recovery_loading or @recovery_status not in [:unknown, :timed_out]}>
              A refresh observes this retry and never submits work.
            </span>
          </.ops_status>
          <p :if={@recovery_evidence} class="mt-2 text-ops-body" data-testid="recovery-evidence">
            Queue job {@recovery_evidence.replacement_job} · attempt {@recovery_evidence.attempt}
            <span :if={@recovery_evidence.task_uid}>
              · Meilisearch task {@recovery_evidence.task_uid}
            </span>
            ·
            <.ops_inline_code>{@recovery_evidence.index}</.ops_inline_code>
          </p>
          <p
            :if={is_map(@recovery_evidence) and is_map(@recovery_evidence.source_failure)}
            class="mt-2 break-words text-ops-body"
            data-testid="recovery-source"
          >
            Original failure: {recovery_source_label(@recovery_evidence.source_failure.source)}
            {@recovery_evidence.source_failure.id} · operation {@recovery_evidence.operation} ·
            schema
            <.ops_inline_code>{@recovery_evidence.schema}</.ops_inline_code>
          </p>
        </.ops_section>
      </.ops_panel>

      <.ops_empty_state :if={@selection_error == :no_schemas} title="No schemas configured">
        Add allowlisted schemas before loading sync or drift observations.
      </.ops_empty_state>

      <.ops_status
        :if={@selection_error == :unavailable}
        kind={:error}
        title="That schema is unavailable"
        role="alert"
      >
        Choose an available schema to continue.
      </.ops_status>

      <.ops_panel>
        <.ops_section
          id="sync-reconcile-heading"
          title="Sync status"
          subtitle="Check backend tasks and queued work for this schema."
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

          <div :if={@reconcile_result} class="space-y-2" id="sync-work-status" role="status">
            <p class="font-semibold">{elem(sync_summary(@reconcile_result), 0)}</p>
            <p :if={elem(sync_summary(@reconcile_result), 1)} class="text-base-content/80">
              {elem(sync_summary(@reconcile_result), 1)}
            </p>
            <.ops_link_button
              :if={:failed_sync_work in @reconcile_result.drift_signals}
              navigate={OperatorSelection.path(@mount_path, "failed-sync", @selected_schema)}
              variant={:ghost}
            >
              Review failed sync work <span aria-hidden="true">→</span>
            </.ops_link_button>
          </div>

          <.ops_disclosure
            :if={@reconcile_result}
            id={"sync-details-#{@context_generation}"}
            summary="Sync details"
            variant={:compact}
            class="mt-3"
            phx-mounted={JS.ignore_attributes("open")}
          >
            <.ops_signal_table>
              <thead>
                <tr>
                  <th scope="col">Check</th>
                  <th scope="col">Value</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <th scope="row" class="font-semibold align-top">Index</th>
                  <td>
                    <.ops_inline_code>{@reconcile_result.index}</.ops_inline_code>
                  </td>
                </tr>
                <tr>
                  <th scope="row" class="font-semibold align-top">Mode</th>
                  <td>{reconcile_signal_label(@reconcile_result.mode)}</td>
                </tr>
                <tr>
                  <th scope="row" class="font-semibold align-top">Work observed</th>
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
          </.ops_disclosure>

          <p
            :if={@reconcile_result == nil && @selected_schema && !@reconcile_error}
            class="text-ops-body text-base-content/70"
          >
            Sync status is not available yet. Refresh sync status to check again.
          </p>
          <.ops_status
            :if={@reconcile_error && @selected_schema}
            kind={:error}
            title="Sync status is unavailable"
            role="alert"
          >
            {sync_error_copy(@reconcile_error)}
            <.ops_disclosure summary="Check diagnostics" variant={:compact} class="mt-2">
              <.ops_code_block>{inspect(@reconcile_error)}</.ops_code_block>
            </.ops_disclosure>
          </.ops_status>
        </.ops_section>
      </.ops_panel>

      <.ops_panel>
        <.ops_section
          id="sync-drift-heading"
          title="Index configuration"
          subtitle="Compare declared fields and search settings. This does not check document freshness."
          meta={if @drift_loaded_at, do: "last loaded #{format_dt(@drift_loaded_at)}"}
        >
          <:actions>
            <.ops_button
              phx-click="load_drift"
              phx-disable-with="Checking…"
              disabled={@drift_loading || !@selected_schema}
            >
              {if @drift_result, do: "Refresh configuration check", else: "Check index configuration"}
            </.ops_button>
          </:actions>

          <div
            :if={@drift_loading}
            class="space-y-3"
            role="status"
            aria-label="Checking index configuration"
          >
            <p class="text-ops-body text-base-content/70">
              Comparing index configuration…
            </p>
            <.ops_loading lines={4} label="Checking index configuration" />
          </div>

          <p
            :if={!@drift_loading && !@drift_result && !@drift_error && @selected_schema}
            class="text-ops-sm text-base-content/75"
            data-testid="configuration-not-checked"
          >
            Not checked
          </p>

          <.ops_status
            :if={!@drift_loading && @drift_error && @selected_schema}
            kind={drift_status_kind(@drift_result, @drift_error)}
            title={drift_status_title(@drift_result, @drift_error)}
            role={if @drift_error, do: "alert"}
          >
            {drift_status_copy(@drift_result, @drift_error)}
            <.ops_disclosure summary="Check diagnostics" variant={:compact} class="mt-2">
              <.ops_code_block>{inspect(@drift_error)}</.ops_code_block>
            </.ops_disclosure>
          </.ops_status>

          <div :if={@drift_result && !@drift_loading} class="space-y-2" role="status">
            <p class="font-semibold">{drift_status_title(@drift_result, nil)}</p>
            <p :if={drift_mismatch_count(@drift_result) > 0} class="text-base-content/80">
              {drift_status_copy(@drift_result, nil)}
            </p>
          </div>

          <.ops_disclosure
            :if={@drift_result && !@drift_loading}
            id={"index-configuration-details-#{@context_generation}-#{drift_mismatch_count(@drift_result) > 0}"}
            summary="Comparison details"
            open={drift_mismatch_count(@drift_result) > 0}
            variant={:compact}
            class="mt-3"
            data-testid="configuration-details"
            phx-mounted={JS.ignore_attributes("open")}
          >
            <.ops_signal_table>
              <thead>
                <tr>
                  <th scope="col">Field</th>
                  <th scope="col">Value</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <th scope="row" class="font-semibold align-top">Summary</th>
                  <td>Index configuration comparison</td>
                </tr>
                <tr>
                  <th scope="row" class="font-semibold align-top">Version · index</th>
                  <td class="font-mono text-ops-sm tabular-nums">
                    version {@drift_result.version} · index {@drift_result.index}
                  </td>
                </tr>
                <tr>
                  <th scope="row" class="font-semibold align-top">Differences</th>
                  <td class="font-mono text-ops-sm tabular-nums">
                    {drift_mismatch_count(@drift_result)} of {map_size(@drift_result.dimensions)}
                  </td>
                </tr>
              </tbody>
            </.ops_signal_table>
            <div class="mt-3">
              <div class="grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
                <.ops_tone_chip
                  :for={{label, match?} <- drift_dimension_rows(@drift_result)}
                  kind={if match?, do: :neutral, else: :warning}
                  label={label}
                  value={if match?, do: "matches", else: "differs"}
                />
              </div>
            </div>
          </.ops_disclosure>
        </.ops_section>
      </.ops_panel>

      <.ops_panel
        :if={@promotion_schema || @promotion_task_id}
        id="promotion-task-status"
      >
        <.ops_section
          title={promotion_status_title(@promotion_status)}
          subtitle="Task completion is separate from the current index and document state."
        >
          <p class="text-ops-body" data-testid="promotion-task-identity">
            Schema
            <.ops_inline_code>{module_flat_name(@promotion_schema)}</.ops_inline_code>
            <span :if={@promotion_indexes}>
              · swap pair
              <.ops_inline_code>{elem(@promotion_indexes, 0)}</.ops_inline_code>
              →
              <.ops_inline_code>{elem(@promotion_indexes, 1)}</.ops_inline_code>
            </span>
            <span :if={@promotion_task_id}>
              · task
              <.ops_inline_code>{@promotion_task_id}</.ops_inline_code>
            </span>
          </p>
          <p :if={@promotion_status == :accepted} class="text-ops-body">
            The backend accepted this swap. Its task is still queued or its latest status is not yet known.
          </p>
          <p :if={@promotion_status == :running} class="text-ops-body">
            Meilisearch reports that this swap task is processing.
          </p>
          <p :if={@promotion_status == :completed} class="text-ops-body">
            The matching swap task completed. Check current index state separately.
          </p>
          <p :if={match?({:failed, :cancelled}, @promotion_status)} class="text-ops-body">
            The matching swap task was cancelled. Check current index state separately.
          </p>
          <p
            :if={
              match?({:failed, _}, @promotion_status) and
                not match?({:failed, :cancelled}, @promotion_status)
            }
            class="text-ops-body"
          >
            The matching swap task failed. Check current index state separately.
          </p>
          <p
            :if={@promotion_status in [:timed_out, :unknown]}
            class="text-ops-body"
            data-testid="promotion-unconfirmed"
          >
            The task result could not be confirmed. The returned task UID remains shown; checking it again never submits another swap.
          </p>
          <p
            :if={is_nil(@promotion_task_id)}
            class="text-ops-body"
            data-testid="promotion-missing-task-id"
          >
            The swap response did not provide a usable task ID. Review the current index state; no task lookup is available.
          </p>
          <.ops_button
            :if={is_integer(@promotion_task_id)}
            phx-click="check_swap_status"
            phx-disable-with="Checking swap status…"
            disabled={@promotion_check_loading}
            size={:sm}
          >
            Check swap status
          </.ops_button>
          <span :if={@promotion_check_loading} role="status" class="text-ops-sm text-base-content/70">
            Checking swap status…
          </span>
        </.ops_section>
      </.ops_panel>

      <details
        :if={@selected_schema}
        id="index-promotion"
        class="ops-panel"
        phx-hook="OpsHealthDetails"
        phx-mounted={JS.ignore_attributes("open")}
        data-testid="advanced-promotion-disclosure"
        data-ops-required-open="false"
      >
        <summary
          class="cursor-pointer p-4 font-semibold"
          data-testid="advanced-promotion-summary"
        >
          Advanced: index promotion
        </summary>
        <div class="space-y-3 px-4 pb-4">
          <p class="text-ops-body text-base-content/75">
            Promotion swaps the live and prepared target indexes for <.ops_inline_code>{module_flat_name(@selected_schema)}</.ops_inline_code>. Their
            documents, primary keys, settings, and task history move as a pair.
          </p>
          <.ops_status
            kind={if @promotion_eligibility == :eligible, do: :neutral, else: :warning}
            title={promotion_eligibility_title(@promotion_eligibility)}
          >
            {promotion_eligibility_copy(@promotion_eligibility)}
          </.ops_status>
          <.ops_button
            phx-click="confirm_swap_live"
            disabled={@promotion_eligibility != :eligible || @promotion_loading}
          >
            Promote target index
          </.ops_button>
          <.ops_button phx-click="refresh_promotion_checks" size={:sm}>
            Refresh sync and configuration checks
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
          navigate={OperatorSelection.path(@mount_path, "health", nil)}
          hint="Across all configured schemas —"
        >
          Review search health
        </:step>
      </.ops_handoff>

      <.ops_modal
        :if={@confirm_swap? && @selected_schema}
        id="confirm-index-promotion"
        title="Confirm index promotion"
        description="This swaps the selected indexes' documents, primary keys, settings, and task history so the prepared target becomes live."
        action_label="promote index"
        cancel_event="cancel_swap_live"
      >
        <.form for={%{}} id="index-promotion-form" phx-submit="swap_live" class="space-y-3">
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
          <p>
            Effect: Meilisearch swaps this pair atomically. The prepared target's documents,
            primary key, settings, and task history take the live index's place after the task
            completes; the other index keeps the prior live data.
          </p>
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
    do: "Index configuration could not be checked"

  defp drift_status_title(nil, nil), do: "Not checked"

  defp drift_status_title(result, nil) do
    if drift_mismatch_count(result) == 0,
      do: "Index configuration matches",
      else: "Index configuration differs"
  end

  defp drift_status_copy(_result, error) when not is_nil(error) do
    "Refresh the configuration check to try again. You can still check sync status above."
  end

  defp drift_status_copy(nil, nil) do
    "This check compares declared fields and settings. It does not verify document freshness."
  end

  defp drift_status_copy(result, nil) do
    mismatches = drift_mismatch_count(result)

    if mismatches == 0 do
      "Declared fields, filterable attributes, sortable attributes, faceting, and settings match this snapshot."
    else
      "#{mismatches} configuration #{if mismatches == 1, do: "difference", else: "differences"} found. Review the comparison before promoting an index."
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
