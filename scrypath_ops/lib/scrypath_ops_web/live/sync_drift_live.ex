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
  alias ScrypathOps.RecoveryObservation

  @impl true
  def mount(_params, _session, socket) do
    allowlist = ScrypathOps.Schemas.allowlist()
    scrypath_opts = ScrypathOps.Schemas.scrypath_opts()

    socket =
      socket
      |> assign(:page_title, "Sync / drift")
      |> assign(:schema_allowlist, allowlist)
      |> assign(:scrypath_opts, scrypath_opts)
      |> assign(:selected_schema, nil)
      |> assign(:selection_error, nil)
      |> assign(:context_generation, 0)
      |> assign(:reconcile_result, nil)
      |> assign(:reconcile_loaded_at, nil)
      |> assign(:drift_result, nil)
      |> assign(:drift_loaded_at, nil)
      |> assign(:drift_error, nil)
      |> assign(:drift_loading, false)
      |> assign(:recovery_handle, nil)
      |> assign(:recovery_status, nil)
      |> assign(:recovery_checked_at, nil)
      |> assign(:recovery_loading, false)

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
        |> maybe_start_recovery(Map.get(params, "recovery"))
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

          {:error, reason} ->
            put_flash(socket, :error, "Reconcile failed: #{inspect(reason)}")
        end
    end
  end

  @impl true
  def handle_event("refresh_reconcile", _params, socket) do
    {:noreply,
     if(current_selection?(socket), do: refresh_reconcile(socket), else: unavailable(socket))}
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
         socket |> assign(:recovery_status, :unknown) |> assign(:recovery_loading, false)}
    end
  end

  def handle_event("load_drift", _params, socket) do
    # Two-step so the loading skeleton paints before the bounded backend read runs.
    # The contract-drift call is fast but synchronous; deferring it to handle_info/2
    # lets LiveView push the `:drift_loading` frame first. Event name unchanged.
    if current_selection?(socket) do
      send(self(), {:run_drift, socket.assigns.context_generation})
      {:noreply, assign(socket, :drift_loading, true)}
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

  def handle_event("swap_live", _params, socket) do
    {:noreply, if(current_selection?(socket), do: swap_live(socket), else: unavailable(socket))}
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
  def handle_async(:recovery_observation, {:ok, {generation, handle, result}}, socket) do
    if generation == socket.assigns.context_generation and
         handle == socket.assigns.recovery_handle do
      {:noreply,
       socket
       |> assign(:recovery_status, result)
       |> assign(:recovery_checked_at, DateTime.utc_now())
       |> assign(:recovery_loading, false)}
    else
      {:noreply, socket}
    end
  end

  def handle_async(:recovery_observation, {:exit, _reason}, socket) do
    {:noreply,
     socket
     |> assign(:recovery_status, :unknown)
     |> assign(:recovery_checked_at, DateTime.utc_now())
     |> assign(:recovery_loading, false)}
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
    |> assign(:drift_result, nil)
    |> assign(:drift_loaded_at, nil)
    |> assign(:drift_error, nil)
    |> assign(:drift_loading, false)
    |> assign(:recovery_handle, nil)
    |> assign(:recovery_status, nil)
    |> assign(:recovery_checked_at, nil)
    |> assign(:recovery_loading, false)
  end

  defp maybe_start_recovery(socket, handle) when is_binary(handle) and byte_size(handle) <= 128 do
    start_recovery_observation(socket, handle)
  end

  defp maybe_start_recovery(socket, _), do: socket

  defp start_recovery_observation(socket, handle) do
    generation = socket.assigns.context_generation
    schema = socket.assigns.selected_schema
    opts = ScrypathOps.Schemas.runtime_opts(socket.assigns.scrypath_opts)
    context = recovery_host_context(socket, schema)

    socket =
      socket
      |> assign(:recovery_handle, handle)
      |> assign(:recovery_status, :unknown)
      |> assign(:recovery_loading, true)

    start_async(socket, :recovery_observation, fn ->
      result = observe_recovery(context, handle, schema, opts)
      {generation, handle, result}
    end)
  end

  defp observe_recovery(context, handle, schema, opts) do
    task = Task.async(fn -> observe_recovery_now(context, handle, schema, opts) end)

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

  defp observe_recovery_now(context, handle, schema, opts) do
    with true <- schema in ScrypathOps.Schemas.allowlist(),
         receipt when is_map(receipt) <- RecoveryObservation.observe(context, handle),
         true <- receipt.generation == context.generation,
         true <- current_runtime_matches?(receipt, opts),
         {:ok, expected_index} <- active_index(schema, opts),
         true <- receipt.index == expected_index,
         {:ok, job} <- read_recovery_job(receipt, opts),
         {:ok, queue_state} <- validate_recovery_job(job, receipt) do
      case receipt.task_uid do
        task_uid when is_integer(task_uid) ->
          verify_task_and_documents(task_uid, receipt, schema, opts)

        _ when queue_state == :completed ->
          :queue_only_completed

        _ when queue_state == :running ->
          :running

        _ ->
          :accepted
      end
    else
      false -> :unknown
      :unknown -> :unknown
      {:error, :job_running} -> :running
      {:error, :queue_only_completed} -> :queue_only_completed
      {:error, :job_failed} -> :failed
      {:error, _} -> :unknown
      _ -> :unknown
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

  defp verify_task_and_documents(task_uid, receipt, schema, opts) do
    with {:ok, task} <- read_recovery_task(task_uid, opts),
         :ok <- validate_recovery_task(task, receipt, task_uid),
         {:ok, expected} <- read_expected_effects(schema, receipt, opts),
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
      generation: socket.assigns.context_generation
    }
  end

  defp active_index(schema, opts) do
    try do
      {:ok, Scrypath.Meilisearch.index_name(schema, opts)}
    rescue
      _ -> {:error, :index_unavailable}
    end
  end

  defp read_recovery_job(receipt, opts) do
    repo = Keyword.get(opts, :repo)
    job_id = receipt.replacement_job

    if is_atom(repo) and is_integer(job_id) and Code.ensure_loaded?(Oban.Job) and
         Code.ensure_loaded?(repo) and
         function_exported?(repo, :get, 2) do
      case apply(repo, :get, [Oban.Job, job_id]) do
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

        {:error, reason} ->
          put_flash(socket, :error, "Reconcile failed: #{inspect(reason)}")
      end
    else
      put_flash(socket, :error, "Select a schema and configure Scrypath runtime.")
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
          |> assign(:drift_error, nil)

        {:error, reason} ->
          socket
          |> assign(:drift_error, reason)
      end
    else
      assign(socket, :drift_error, :missing_backend)
    end
  end

  defp swap_live(socket) do
    Gating.gate_sensitive_action(socket, :swap_live, fn ->
      mod = socket.assigns.selected_schema
      opts = socket.assigns.scrypath_opts

      if mod && Keyword.has_key?(opts, :backend) do
        case Scrypath.Meilisearch.swap_indexes(mod, opts) do
          {:ok, _result} ->
            socket
            |> invalidate_recovery_claim()
            |> refresh_reconcile()
            |> maybe_refresh_drift()
            |> put_flash(:info, "Swap live index completed for #{module_flat_name(mod)}")

          {:error, reason} ->
            put_flash(socket, :error, "Swap live failed: #{inspect(reason)}")
        end
      else
        put_flash(socket, :error, "Select a schema and configure Scrypath runtime.")
      end
    end)
  end

  defp invalidate_recovery_claim(socket) do
    socket
    |> assign(:recovery_status, :unknown)
    |> assign(:recovery_checked_at, nil)
    |> assign(:recovery_loading, false)
  end

  defp maybe_refresh_drift(socket) do
    if socket.assigns.drift_loaded_at || socket.assigns.drift_result || socket.assigns.drift_error do
      refresh_drift(socket)
    else
      socket
    end
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

  # Sequential promotion preflight. Each step's `locked?` gates the next so the
  # checklist reads as a wizard: contract drift waits on reconcile, mismatches wait
  # on drift, and promote lights up only when checks 1–3 are green.
  defp preflight_steps(reconcile, drift, drift_error) do
    recon_done? = not is_nil(reconcile)
    drift_done? = not is_nil(drift)
    mismatches = if drift_done?, do: drift_mismatch_count(drift), else: nil
    clean? = drift_done? and mismatches == 0

    [
      %{
        num: 1,
        title: "Reconcile",
        badge_kind: if(recon_done?, do: :success, else: :warning),
        badge: if(recon_done?, do: "loaded", else: "needed"),
        locked?: false,
        hint:
          if(recon_done?,
            do: "Queue & backend posture loaded.",
            else: "Run the reconcile check below to begin."
          )
      },
      %{
        num: 2,
        title: "Contract drift",
        badge_kind: drift_status_kind(drift, drift_error),
        badge: drift_status_title(drift, drift_error),
        locked?: not recon_done?,
        hint:
          cond do
            not recon_done? -> "Locked — load reconcile first."
            drift_done? -> "Declared vs live contract loaded."
            true -> "Load the contract-drift check below."
          end
      },
      %{
        num: 3,
        title: "Mismatches",
        badge_kind:
          cond do
            clean? -> :success
            drift_done? -> :warning
            true -> :neutral
          end,
        badge: if(drift_done?, do: "#{mismatches} mismatch(es)", else: "unknown"),
        locked?: not drift_done?,
        hint:
          cond do
            not drift_done? -> "Locked — run contract drift first."
            clean? -> "No dimension mismatches."
            true -> "Resolve drift before promoting."
          end
      },
      %{
        num: 4,
        title: "Promote",
        badge_kind: promotion_readiness_kind(reconcile, drift),
        badge: promotion_readiness_label(reconcile, drift),
        locked?: not (recon_done? and clean?),
        hint:
          cond do
            recon_done? and clean? -> "Ready for the gated swap below."
            not recon_done? -> "Locked — checks 1–3 must pass."
            not drift_done? -> "Locked — run contract drift."
            true -> "Locked — resolve mismatches first."
          end
      }
    ]
  end

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
        subtitle="Prepare a schema for promotion: reconcile its state, compare declared and live contracts, then use the gated swap."
      />

      <.ops_trail mount_path={@mount_path} current={:sync_drift} class="mt-4" />

      <.ops_panel class="mt-4">
        <.ops_schema_select
          id="sync-schema-select"
          schemas={@schema_allowlist}
          selected={@selected_schema}
          phx-change="select_schema"
        />
      </.ops_panel>

      <.ops_panel :if={@recovery_handle} class="mt-4" id="recovery-observation">
        <.ops_section
          title="Retry observation"
          subtitle="This read checks the accepted queue job, its exact Meilisearch task, and the active index documents."
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
            A refresh observes this retry and never submits work.
          </.ops_status>
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
        Select an allowlisted schema to continue.
      </.ops_status>

      <.ops_notice kind={:info} title="Read-only checks first" class="mt-4">
        Use <.ops_inline_code>mix scrypath.reconcile</.ops_inline_code>, <.ops_inline_code>mix scrypath.index.contract_drift</.ops_inline_code>, <.ops_inline_code>guides/drift-recovery.md</.ops_inline_code>,
        <.ops_inline_code>guides/sync-modes-and-visibility.md</.ops_inline_code>
        for canonical workflows. The primary checks below stay read-only over
        <.ops_inline_code>Scrypath.reconcile_sync/2</.ops_inline_code>
        and <.ops_inline_code>Scrypath.index_contract_drift/2</.ops_inline_code>.
      </.ops_notice>

      <.ops_panel>
        <section aria-labelledby="sync-preflight-heading" class="space-y-3">
          <h2
            id="sync-preflight-heading"
            class="text-ops-h2 font-semibold leading-ops-tight text-base-content"
          >
            Promotion preflight
          </h2>
          <p class="text-ops-body text-base-content/70">
            Work the checks in order — each unlocks the next, and promotion lights up only
            when all are green.
          </p>
          <ol class="ops-preflight">
            <li
              :for={step <- preflight_steps(@reconcile_result, @drift_result, @drift_error)}
              class={["ops-preflight__card", step.locked? && "ops-preflight__card--locked"]}
              aria-disabled={to_string(step.locked?)}
            >
              <div class="ops-preflight__head">
                <span class="ops-preflight__num" aria-hidden="true">{step.num}</span>
                <span class="ops-preflight__title">{step.title}</span>
              </div>
              <.ops_badge kind={step.badge_kind}>{step.badge}</.ops_badge>
              <p class="ops-preflight__hint">{step.hint}</p>
            </li>
          </ol>
        </section>
      </.ops_panel>

      <.ops_panel>
        <.ops_section
          id="sync-reconcile-heading"
          title="Sync & queue posture"
          subtitle="Confirm the current sync and queue state for this schema."
          meta={if @reconcile_loaded_at, do: "last loaded #{format_dt(@reconcile_loaded_at)}"}
        >
          <:actions>
            <.ops_button
              phx-click="refresh_reconcile"
              variant={:primary}
              data-ops-refresh
              disabled={!@selected_schema}
            >
              Refresh reconcile
            </.ops_button>
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
                <th scope="row" class="font-medium align-top">Index</th>
                <td>
                  <.ops_inline_code>{@reconcile_result.index}</.ops_inline_code>
                </td>
              </tr>
              <tr>
                <th scope="row" class="font-medium align-top">Mode</th>
                <td>{reconcile_signal_label(@reconcile_result.mode)}</td>
              </tr>
              <tr>
                <th scope="row" class="font-medium align-top">Drift signals</th>
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
            Reconcile not loaded yet — choose a schema or tap “Refresh reconcile”.
          </p>
        </.ops_section>
      </.ops_panel>

      <.ops_panel>
        <.ops_section
          id="sync-drift-heading"
          title="Index contract (declared vs live)"
          subtitle="Compare the declared schema contract with the live Meilisearch index before promoting."
          meta={if @drift_loaded_at, do: "last loaded #{format_dt(@drift_loaded_at)}"}
        >
          <:actions>
            <.ops_button
              phx-click="load_drift"
              phx-disable-with="Loading…"
              disabled={@drift_loading || !@selected_schema}
            >
              Load / refresh contract drift
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
            :if={!@drift_loading}
            kind={drift_status_kind(@drift_result, @drift_error)}
            title={drift_status_title(@drift_result, @drift_error)}
            role={if @drift_error, do: "alert"}
          >
            {drift_status_copy(@drift_result, @drift_error)}
            <div :if={is_nil(@drift_result) && is_nil(@drift_error)} class="mt-3">
              <.ops_button phx-click="load_drift" variant={:primary} size={:sm}>
                Run contract drift now
              </.ops_button>
            </div>
          </.ops_status>

          <.ops_signal_table :if={@drift_result && !@drift_loading}>
            <thead>
              <tr>
                <th scope="col">Field</th>
                <th scope="col">Value</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <th scope="row" class="font-medium align-top">Summary</th>
                <td>Index contract snapshot</td>
              </tr>
              <tr>
                <th scope="row" class="font-medium align-top">Version · index</th>
                <td class="font-mono text-ops-sm tabular-nums">
                  version {@drift_result.version} · index {@drift_result.index}
                </td>
              </tr>
              <tr>
                <th scope="row" class="font-medium align-top">Dimension mismatches</th>
                <td class="font-mono text-ops-sm tabular-nums">
                  {drift_mismatch_count(@drift_result)} of {map_size(@drift_result.dimensions)}
                </td>
              </tr>
            </tbody>
          </.ops_signal_table>
          <.ops_data_card
            :if={@drift_result && !@drift_loading}
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
      </.ops_panel>

      <.ops_panel :if={@selected_schema}>
        <.ops_section
          id="sync-advanced-recovery-heading"
          title="Advanced recovery"
          subtitle="Promote only after the read-only checks, posture, and failed-sync signals are clear."
        >
          <.ops_verdict
            kind={promotion_readiness_kind(@reconcile_result, @drift_result)}
            label="Promotion readiness"
            headline={promotion_readiness_headline(@reconcile_result, @drift_result)}
            class="mb-3"
          >
            Reconcile must be loaded and contract drift must be clean before the gated swap is safe.
          </.ops_verdict>
          <.ops_action_group tone={:advanced}>
            <p class="max-w-xl text-ops-body text-base-content/75">
              Promote the prepared target index to the live alias for <.ops_inline_code>{module_flat_name(@selected_schema)}</.ops_inline_code>. This gated,
              irreversible step refreshes the loaded checks afterward.
            </p>
            <.ops_button phx-click="swap_live" phx-disable-with="Swapping...">
              Swap live index
            </.ops_button>
          </.ops_action_group>
        </.ops_section>
      </.ops_panel>

      <.ops_handoff>
        <:step
          navigate={OperatorSelection.path(@mount_path, "posture", @selected_schema)}
          hint="After promoting —"
        >
          Re-check fleet posture
        </:step>
      </.ops_handoff>
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
    "Contract drift runs only after the explicit control so this screen does not hide a backend read behind page load."
  end

  defp drift_status_copy(result, nil) do
    mismatches = drift_mismatch_count(result)

    if mismatches == 0 do
      "Declared fields, filterable attributes, sortable attributes, faceting, and settings match this snapshot."
    else
      "#{mismatches} contract dimension(s) differ from the live index. Use the operator guides before changing aliases."
    end
  end

  defp drift_mismatch_count(%{dimensions: dimensions}) when is_map(dimensions) do
    Enum.count(dimensions, fn {_key, dimension} -> not Map.get(dimension, :match, false) end)
  end

  defp promotion_readiness_kind(reconcile_result, drift_result) do
    if reconcile_result && drift_result && drift_mismatch_count(drift_result) == 0 do
      :success
    else
      :warning
    end
  end

  defp promotion_readiness_label(reconcile_result, drift_result) do
    cond do
      is_nil(reconcile_result) -> "load reconcile first"
      is_nil(drift_result) -> "load drift first"
      drift_mismatch_count(drift_result) == 0 -> "ready for gated swap"
      true -> "resolve drift first"
    end
  end

  # Sentence-cased verdict headline for the Advanced-recovery promotion hero.
  defp promotion_readiness_headline(reconcile_result, drift_result) do
    cond do
      is_nil(reconcile_result) -> "Load reconcile to begin"
      is_nil(drift_result) -> "Load contract drift to continue"
      drift_mismatch_count(drift_result) == 0 -> "Ready for the gated swap"
      true -> "Resolve drift before promoting"
    end
  end

  defp format_dt(nil), do: "—"

  defp format_dt(%DateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%d %H:%M:%SZ")
  end
end
