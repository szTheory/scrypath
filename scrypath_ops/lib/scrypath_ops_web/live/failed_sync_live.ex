defmodule ScrypathOpsWeb.FailedSyncLive do
  @moduledoc """
  Read-only failed sync triage using `Scrypath.failed_sync_work/2` with
  `reason_class_counts: true` and `%Scrypath.Operator.FailedSyncWorkInspection{}`.
  """

  use ScrypathOpsWeb, :live_view

  alias Scrypath.Operator.FailedWork
  alias Scrypath.Operator.FailedSyncWorkInspection
  alias ScrypathOps.Integrations.Sigra.Gating
  alias ScrypathOps.OperatorSelection

  @impl true
  def mount(_params, _session, socket) do
    allowlist = ScrypathOps.Schemas.allowlist()
    scrypath_opts = ScrypathOps.Schemas.scrypath_opts()

    socket =
      socket
      |> assign(:page_title, "Failed sync work")
      |> assign(:schema_allowlist, allowlist)
      |> assign(:scrypath_opts, scrypath_opts)
      |> assign(:selected_schema, nil)
      |> assign(:selection_error, nil)
      |> assign(:context_generation, 0)
      |> assign(:inspection, nil)
      |> assign(:load_error, nil)
      |> assign(:last_refresh_at, nil)
      |> assign(:recovery_receipts, %{})
      |> assign(:delete_confirmation, nil)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket), do: {:noreply, resolve_selection(socket, params)}

  @impl true
  def handle_event("refresh", _params, socket) do
    socket =
      if current_selection?(socket), do: refresh_inspection(socket), else: unavailable(socket)

    socket =
      if is_nil(socket.assigns.load_error),
        do: put_flash(socket, :info, "Failed sync work refreshed."),
        else: socket

    {:noreply, socket}
  end

  def handle_event("retry", %{"key" => key, "generation" => generation}, socket) do
    {:noreply, request_retry(socket, key, generation)}
  end

  def handle_event("retry", %{"id" => id}, socket) do
    rows =
      case Map.get(socket.assigns, :inspection) do
        %FailedSyncWorkInspection{entries: entries} ->
          Enum.filter(entries, &(to_string(&1.id) == to_string(id)))

        _ ->
          []
      end

    case rows do
      [row] ->
        {:noreply,
         request_retry(socket, failed_work_key(row), to_string(socket.assigns.context_generation))}

      [] when not is_map_key(socket.assigns, :inspection) ->
        {:noreply,
         request_retry(socket, to_string(id), to_string(socket.assigns.context_generation))}

      _ ->
        {:noreply, put_flash(socket, :error, "Could not identify that failed sync work row.")}
    end
  end

  def handle_event("confirm_retry_delete", _params, socket) do
    socket =
      case socket.assigns.delete_confirmation do
        nil ->
          socket

        id ->
          if current_selection?(socket) do
            Gating.gate_sensitive_action(socket, :failed_work_retry, fn ->
              retry_failed_work(socket, id)
            end)
          else
            unavailable(socket)
          end
      end

    {:noreply, normalize_live_reply(assign(socket, :delete_confirmation, nil))}
  end

  def handle_event("cancel_retry_delete", _params, socket) do
    {:noreply, assign(socket, :delete_confirmation, nil)}
  end

  def handle_event("select_schema", %{"schema" => mod_str}, socket) do
    case OperatorSelection.resolve(%{"schema" => mod_str}, ScrypathOps.Schemas.allowlist()) do
      {:ok, mod} ->
        {:noreply,
         push_patch(socket,
           to: OperatorSelection.path(socket.assigns.mount_path, "failed-sync", mod)
         )}

      _ ->
        {:noreply, unavailable(socket)}
    end
  end

  defp resolve_selection(socket, params) do
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

    if selected do
      refresh_inspection(socket)
    else
      socket
      |> assign(:inspection, nil)
      |> assign(:load_error, error)
      |> assign(:last_refresh_at, nil)
    end
  end

  defp maybe_advance_generation(socket, true) do
    Enum.each(Map.values(Map.get(socket.assigns, :recovery_receipts, %{})), fn receipt ->
      if receipt.handle, do: ScrypathOps.RecoveryObservation.invalidate(receipt.handle)
    end)

    socket
    |> update(:context_generation, &(&1 + 1))
    |> assign(:inspection, nil)
    |> assign(:load_error, nil)
    |> assign(:last_refresh_at, nil)
    |> assign(:recovery_receipts, %{})
    |> assign(:delete_confirmation, nil)
  end

  defp maybe_advance_generation(socket, false), do: socket

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
    Enum.each(Map.values(Map.get(socket.assigns, :recovery_receipts, %{})), fn receipt ->
      if receipt.handle, do: ScrypathOps.RecoveryObservation.invalidate(receipt.handle)
    end)

    socket
    |> assign(:selected_schema, nil)
    |> assign(:selection_error, :unavailable)
    |> update(:context_generation, &(&1 + 1))
    |> assign(:inspection, nil)
    |> assign(:load_error, :unavailable)
    |> assign(:last_refresh_at, nil)
    |> assign(:recovery_receipts, %{})
    |> assign(:delete_confirmation, nil)
  end

  defp refresh_inspection(socket) do
    mod = socket.assigns.selected_schema
    opts = Keyword.put(socket.assigns.scrypath_opts, :reason_class_counts, true)

    cond do
      not current_selection?(socket) ->
        unavailable(socket)

      is_nil(mod) ->
        socket
        |> assign(:inspection, nil)
        |> assign(:load_error, :no_schemas)
        |> assign(:last_refresh_at, DateTime.utc_now())

      not Keyword.has_key?(opts, :backend) ->
        socket
        |> assign(:inspection, nil)
        |> assign(:load_error, :missing_backend)
        |> assign(:last_refresh_at, DateTime.utc_now())

      true ->
        case Scrypath.failed_sync_work(mod, opts) do
          {:ok, %FailedSyncWorkInspection{} = insp} ->
            socket
            |> assign(:inspection, insp)
            |> assign(:load_error, nil)
            |> assign(:last_refresh_at, DateTime.utc_now())

          {:ok, rows} when is_list(rows) ->
            # Should not happen when reason_class_counts is true; treat as empty inspection.
            socket
            |> assign(:inspection, %FailedSyncWorkInspection{
              entries: rows,
              counts: empty_counts(rows)
            })
            |> assign(:load_error, nil)
            |> assign(:last_refresh_at, DateTime.utc_now())

          {:error, reason} ->
            socket
            |> assign(:inspection, nil)
            |> assign(:load_error, reason)
            |> assign(:last_refresh_at, DateTime.utc_now())
        end
    end
  end

  defp request_retry(socket, key, generation) do
    cond do
      generation != to_string(socket.assigns.context_generation) ->
        put_flash(socket, :info, "That retry action belongs to an earlier inspection.")

      not current_selection?(socket) ->
        unavailable(socket)

      receipt_already_accepted?(socket, key) ->
        put_flash(socket, :info, "A retry for job #{row_id_from_key(key)} is already accepted.")

      true ->
        case failed_work_row(socket, key) do
          nil ->
            Gating.gate_sensitive_action(socket, :failed_work_retry, fn ->
              put_flash(socket, :error, "Could not find that failed sync work row.")
            end)

          %{operation: :delete, recovery: recovery} when not is_nil(recovery) ->
            assign(socket, :delete_confirmation, key)

          %{recovery: recovery} when not is_nil(recovery) ->
            Gating.gate_sensitive_action(socket, :failed_work_retry, fn ->
              retry_failed_work(socket, key)
            end)

          _row ->
            put_flash(socket, :error, "That job does not expose a retry action.")
        end
    end
  end

  defp retry_failed_work(socket, key) do
    case failed_work_row(socket, key) do
      nil ->
        put_flash(socket, :error, "Could not find that failed job.")

      row ->
        case FailedWork.recovery_action(row) do
          nil ->
            put_flash(socket, :error, "That job does not expose a retry action.")

          recovery ->
            runtime_opts = ScrypathOps.Schemas.runtime_opts(socket.assigns.scrypath_opts)

            case Scrypath.retry_sync_work(recovery, runtime_opts) do
              {:ok, result} ->
                receipt = accepted_receipt(socket, row, recovery, result, runtime_opts)
                receipt_key = receipt_key(row, socket.assigns.inspection)

                socket
                |> refresh_inspection()
                |> update(:recovery_receipts, &Map.put(&1, receipt_key, receipt))
                |> put_flash(:info, "Retry accepted · queue job #{receipt.replacement_job}")

              {:error, reason} ->
                put_flash(socket, :error, "Retry failed: #{inspect(reason)}")
            end
        end
    end
  end

  defp accepted_receipt(socket, row, recovery, result, runtime_opts) do
    task = result.task
    task_raw = task && task.raw
    task_reference = (task && task.reference) || %{}
    job_id = Map.get(task_reference, :job_id) || Map.get(task_reference, "job_id")
    raw_attempt = if is_map(task_raw), do: Map.get(task_raw, :attempt), else: nil
    expected_attempt = if is_integer(raw_attempt), do: raw_attempt + 1, else: 1
    schema = OperatorSelection.canonical(socket.assigns.selected_schema)

    index =
      recovery.index || Map.get(result.metadata || %{}, :index) || Map.get(row.metadata, :index)

    config =
      try do
        Scrypath.Config.resolve!(runtime_opts)
      rescue
        _ -> runtime_opts
      end

    host_context = recovery_host_context(socket, schema)

    receipt = %{
      replacement_job: job_id,
      attempt: expected_attempt,
      operation: recovery.operation,
      schema: Atom.to_string(socket.assigns.selected_schema),
      index: index,
      backend: Atom.to_string(recovery.backend),
      source_failure: %{
        id: row.id,
        task_uid: Map.get(row.metadata, :task_uid),
        index: Map.get(row.metadata, :index),
        operation: row.operation
      },
      accepted_result: %{job_id: job_id},
      endpoint: Keyword.get(config, :meilisearch_url),
      instance: Keyword.get(config, :oban),
      repo: oban_repo(Keyword.get(config, :oban)) || Keyword.get(config, :repo),
      prefix: oban_prefix(Keyword.get(config, :oban)),
      node: node(),
      generation: socket.assigns.context_generation,
      created_at: DateTime.utc_now()
    }

    handle =
      case ScrypathOps.RecoveryObservation.register(host_context, receipt) do
        {:ok, handle} -> handle
        _ -> nil
      end

    Map.merge(receipt, %{handle: handle, state: :accepted, checked_at: DateTime.utc_now()})
  end

  defp recovery_host_context(socket, schema) do
    operator_context = Map.get(socket.assigns, :operator_context)
    current_scope = Map.get(socket.assigns, :current_scope, %{})

    organization =
      field(operator_context, :active_org_id) ||
        get_in(current_scope, [:active_organization, :id])

    host = (socket.host_uri && socket.host_uri.host) || "unknown"

    %{
      host: host,
      org: organization && to_string(organization),
      schema: schema,
      generation: socket.assigns.context_generation
    }
  end

  defp oban_prefix(instance) when is_atom(instance) do
    if Code.ensure_loaded?(Oban) and function_exported?(Oban, :config, 1) do
      case apply(Oban, :config, [instance]) do
        %{prefix: prefix} -> prefix
        _ -> nil
      end
    else
      nil
    end
  rescue
    _ -> nil
  end

  defp oban_prefix(_), do: nil

  defp oban_repo(instance) when is_atom(instance) do
    if Code.ensure_loaded?(Oban) and function_exported?(Oban, :config, 1) do
      case apply(Oban, :config, [instance]) do
        %{repo: repo} -> repo
        _ -> nil
      end
    else
      nil
    end
  rescue
    _ -> nil
  end

  defp oban_repo(_), do: nil

  defp field(map, key) when is_map(map), do: Map.get(map, key)
  defp field(_, _), do: nil

  defp recovery_receipt(receipts, row, inspection) do
    Map.get(receipts, receipt_key(row, inspection))
  end

  defp receipt_key(row, %FailedSyncWorkInspection{entries: entries}) do
    if Enum.count(entries, &(to_string(&1.id) == to_string(row.id))) > 1 do
      failed_work_key(row)
    else
      to_string(row.id)
    end
  end

  defp receipt_key_for_key(socket, key) do
    case failed_work_row(socket, key) do
      nil -> key
      row -> receipt_key(row, socket.assigns.inspection)
    end
  end

  defp receipt_already_accepted?(socket, key) do
    receipts = Map.get(socket.assigns, :recovery_receipts, %{})

    Map.has_key?(receipts, receipt_key_for_key(socket, key)) or
      Map.has_key?(receipts, row_id_from_key(key))
  end

  defp row_id_from_key(key), do: key |> String.split(":") |> List.last()

  defp recovery_handoff_path(mount_path, schema, receipt) do
    base = String.trim_trailing(mount_path, "/")

    query =
      URI.encode_query(%{
        "schema" => OperatorSelection.canonical(schema),
        "recovery" => receipt.handle,
        "recovery_generation" => receipt.generation
      })

    "#{base}/sync-drift?#{query}"
  end

  defp delete_confirmation_row(%FailedSyncWorkInspection{entries: entries}, key)
       when is_binary(key) do
    Enum.find(entries, fn row ->
      failed_work_key(row) == key and row.operation == :delete and row.recovery
    end)
  end

  defp delete_confirmation_row(_, _), do: nil

  defp delete_confirmation_ids(row) do
    get_in(row.recovery.reference, [:payload, "document_ids"]) || []
  end

  defp delete_confirmation_index(row) do
    row.recovery.index || Map.get(row.metadata, :index) || "unknown"
  end

  defp delete_confirmation_description(row) do
    count = length(delete_confirmation_ids(row))

    "Retry deletion of #{count} documents for #{module_flat_name(row.schema)} in #{delete_confirmation_index(row)}."
  end

  defp failed_work_row(socket, key) do
    inspection = Map.get(socket.assigns, :inspection)

    if inspection do
      Enum.find(inspection.entries, &(failed_work_key(&1) == key))
    end
  end

  defp failed_work_key(row) do
    "#{OperatorSelection.canonical(row.schema)}:#{row.source}:#{row.id}"
  end

  defp empty_counts(rows) do
    Scrypath.Operator.FailedWork.reason_class_counts(rows)
  end

  defp module_flat_name(mod) when is_atom(mod), do: OperatorSelection.canonical(mod)

  defp sorted_entries(%FailedSyncWorkInspection{entries: entries}) do
    Enum.sort_by(
      entries,
      fn row ->
        row.last_attempt_at || row.failed_at || ~U[0001-01-01 00:00:00Z]
      end,
      {:desc, DateTime}
    )
  end

  defp reason_class_label(nil), do: "unknown"
  defp reason_class_label(:unknown), do: "unknown"

  defp reason_class_label(other) do
    other
    |> to_string()
    |> String.replace("_", " ")
  end

  defp failed_sync_status_kind(%FailedSyncWorkInspection{counts: %{total: 0}}), do: :success
  defp failed_sync_status_kind(_inspection), do: :warning

  defp failed_sync_status_title(%FailedSyncWorkInspection{counts: %{total: 0}}),
    do: "No failed sync work visible"

  defp failed_sync_status_title(%FailedSyncWorkInspection{counts: %{total: 1}}),
    do: "1 failed sync job needs triage"

  defp failed_sync_status_title(%FailedSyncWorkInspection{counts: %{total: total}}),
    do: "#{total} failed sync jobs need triage"

  defp dominant_reason_class(%FailedSyncWorkInspection{counts: %{by_class: by_class}}) do
    by_class
    |> maybe_map_from_struct()
    |> Enum.max_by(fn {_class, count} -> count end, fn -> {:unknown, 0} end)
    |> elem(0)
  end

  defp maybe_map_from_struct(%_{} = struct), do: Map.from_struct(struct)
  defp maybe_map_from_struct(map) when is_map(map), do: map

  defp retryable_count(%FailedSyncWorkInspection{entries: entries}) do
    Enum.count(entries, & &1.retryable?)
  end

  defp retryable_label(1), do: "1 retryable job"
  defp retryable_label(count), do: "#{count} retryable jobs"

  defp reason_counts(%FailedSyncWorkInspection{counts: %{by_class: by_class}}) do
    by_class
    |> maybe_map_from_struct()
    |> Enum.map(fn {class, count} -> {reason_class_label(class), count} end)
    |> Enum.sort_by(&elem(&1, 0))
  end

  defp normalize_live_reply({:noreply, %Phoenix.LiveView.Socket{} = socket}), do: socket
  defp normalize_live_reply(%Phoenix.LiveView.Socket{} = socket), do: socket
  defp normalize_live_reply(other), do: other

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
          title={@page_title}
          subtitle="Inspect failed queue/backend work by newest evidence first. Retry only after the failure class and row evidence make sense."
        />
        <.ops_refresh_control
          id="failed-sync-refresh"
          checked_at={@last_refresh_at}
          phx-click="refresh"
          aria_label="Refresh failed sync work"
        />
      </.ops_toolbar>

      <.ops_trail current={:failed_sync} />

      <.ops_panel>
        <.form for={%{}} id="failed-sync-schema-form" phx-change="select_schema">
          <.ops_schema_select
            id="schema-select"
            schemas={@schema_allowlist}
            selected={@selected_schema}
            hint="Choose a schema to inspect its failed sync work."
          />
        </.form>
      </.ops_panel>

      <.ops_empty_state :if={@load_error == :no_schemas} title="No schemas configured">
        Add allowlisted schema modules with
        <.ops_inline_code>schema_allowlist</.ops_inline_code>
        in <.ops_inline_code>:scrypath_ops</.ops_inline_code>, then refresh failed sync jobs.
      </.ops_empty_state>

      <.ops_status
        :if={@load_error == :unavailable}
        kind={:error}
        title="That schema is unavailable"
        role="alert"
      >
        Select an allowlisted schema to continue.
      </.ops_status>

      <.ops_empty_state
        :if={@load_error == :missing_backend}
        title="Runtime not configured"
      >
        Configure the Scrypath runtime under
        <.ops_inline_code>:scrypath_ops</.ops_inline_code>
        — see <.ops_inline_code>scrypath_ops/README.md</.ops_inline_code>, then refresh.
      </.ops_empty_state>

      <.ops_status
        :if={
          @inspection == nil && @load_error &&
            @load_error not in [:no_schemas, :missing_backend, :unavailable]
        }
        kind={:error}
        title="Failed sync work could not load"
        role="alert"
      >
        The selected schema could not be inspected. Check backend and queue configuration, then
        refresh failed sync jobs. Reason:
        <.ops_inline_code>{inspect(@load_error)}</.ops_inline_code>
      </.ops_status>

      <.ops_panel :if={@inspection}>
        <section aria-labelledby="failed-sync-rollups-heading">
          <.ops_status
            kind={failed_sync_status_kind(@inspection)}
            title={failed_sync_status_title(@inspection)}
          >
            Selected schema:
            <.ops_inline_code>{module_flat_name(@selected_schema)}</.ops_inline_code>
            · dominant reason:
            <strong>{reason_class_label(dominant_reason_class(@inspection))}</strong>
          </.ops_status>

          <div class="mt-3 flex flex-wrap items-center gap-x-3 gap-y-1 text-ops-body text-base-content/80">
            <span>
              <strong>{@inspection.counts.total}</strong>
              failed sync {if @inspection.counts.total == 1, do: "job", else: "jobs"}
            </span>
            <span aria-hidden="true">·</span>
            <span>{retryable_label(retryable_count(@inspection))}</span>
            <span class="sr-only" id="failed-sync-rollups-heading">Failure reasons</span>
            <span
              :for={{label, count} <- reason_counts(@inspection)}
              class="rounded-full border border-base-300 px-2 py-0.5 text-ops-sm"
            >
              {label}: {count}
            </span>
          </div>
        </section>

        <section aria-labelledby="failed-sync-table-heading" class="mt-4">
          <h2
            id="failed-sync-table-heading"
            class="text-ops-h2 font-semibold leading-ops-tight text-base-content"
          >
            Failed sync jobs
          </h2>
          <.ops_empty_hero
            :if={@inspection.counts.total == 0}
            title="No failed sync jobs"
            icon="hero-shield-check"
            class="mt-3"
            data-testid="failed-sync-empty-hero"
          >
            Nothing needs retry for this schema. If you are confirming recovery, check sync drift before changing indexes.
            <:actions>
              <.ops_button phx-click="refresh" variant={:default}>
                Refresh this view
              </.ops_button>
            </:actions>
          </.ops_empty_hero>

          <div :if={@inspection.counts.total > 0} class="mt-3 grid gap-2">
            <.ops_result_row
              :for={row <- sorted_entries(@inspection)}
              title={failed_work_title(row)}
              subtitle={"#{row.operation} · #{row.source} · last attempt #{format_dt(row.last_attempt_at || row.failed_at)}"}
              data-testid="failed-sync-row"
            >
              <:meta>
                <.ops_badge kind={:warning}>{reason_class_label(row.reason_class)}</.ops_badge>
                <.ops_badge kind={:error}>{row.state}</.ops_badge>
                <.ops_badge :if={row.retryable?} kind={:partial}>retryable</.ops_badge>
              </:meta>
              <p
                class="mt-2 break-words text-ops-body text-base-content/85"
                data-testid="failed-sync-reason"
              >
                {row.reason}
              </p>
              <.ops_action_group
                :if={row.recovery && is_nil(recovery_receipt(@recovery_receipts, row, @inspection))}
                tone={:advanced}
                class="mt-3 items-start"
              >
                <.ops_button
                  phx-click="retry"
                  phx-value-key={failed_work_key(row)}
                  phx-value-generation={@context_generation}
                  data-testid="failed-sync-retry"
                  variant={:primary}
                  size={:xs}
                >
                  Retry sync work
                </.ops_button>
              </.ops_action_group>
              <.ops_status
                :if={receipt = recovery_receipt(@recovery_receipts, row, @inspection)}
                class="mt-3"
                kind={:info}
                title="Retry accepted"
                role="status"
                data-testid="recovery-receipt"
              >
                Queue job {receipt.replacement_job} · {receipt.operation} · <.ops_inline_code>{receipt.index}</.ops_inline_code>.
                Original failure #{row.id} retained.
                <.link
                  :if={receipt.handle}
                  navigate={recovery_handoff_path(@mount_path, @selected_schema, receipt)}
                  class="ml-2 min-h-ops-control link link-primary underline underline-offset-2"
                >
                  Check sync status
                </.link>
              </.ops_status>
              <.ops_disclosure
                id={"failed-detail-#{failed_work_key(row)}"}
                summary="Diagnostics"
                variant={:compact}
                class="mt-3"
              >
                <.ops_code_block :if={map_size(row.metadata) > 0} variant={:embedded}>
                  {inspect(row.metadata, pretty: true)}
                </.ops_code_block>
              </.ops_disclosure>
            </.ops_result_row>
          </div>
        </section>

        <.ops_disclosure summary="Operator reference" class="mt-3">
          <p class="text-ops-sm text-base-content/75">
            See <.ops_inline_code>mix scrypath.failed</.ops_inline_code>, <.ops_inline_code>guides/drift-recovery.md</.ops_inline_code>, and <.ops_inline_code>guides/operator-mix-tasks.md</.ops_inline_code>.
          </p>
        </.ops_disclosure>
      </.ops_panel>

      <.ops_handoff :if={@inspection && @selected_schema}>
        <:step
          navigate={OperatorSelection.path(@mount_path, "sync-drift", @selected_schema)}
          hint="When the queue's clear —"
        >
          Check sync and drift
        </:step>
      </.ops_handoff>

      <.ops_modal
        :if={delete_confirmation_row(@inspection, @delete_confirmation)}
        id="retry-delete-modal"
        title="Confirm delete sync work"
        description={
          delete_confirmation_description(delete_confirmation_row(@inspection, @delete_confirmation))
        }
        action_label="retry delete"
        initial_focus="[data-ops-modal-cancel]"
        cancel_event="cancel_retry_delete"
      >
        <.form for={%{}} phx-submit="confirm_retry_delete" class="space-y-3">
          <div class="rounded-ops-surface border border-base-300 p-ops-3 text-ops-body">
            <p>
              Schema
              <.ops_inline_code>{module_flat_name(@selected_schema)}</.ops_inline_code>
            </p>
            <p>
              Index
              <.ops_inline_code>
                {delete_confirmation_index(delete_confirmation_row(@inspection, @delete_confirmation))}
              </.ops_inline_code>
            </p>
            <p>
              {length(
                delete_confirmation_ids(delete_confirmation_row(@inspection, @delete_confirmation))
              )} documents
            </p>
            <ul class="mt-2 list-inside list-disc break-all font-mono text-ops-sm">
              <li :for={
                document_id <-
                  delete_confirmation_ids(delete_confirmation_row(@inspection, @delete_confirmation))
              }>
                {inspect(document_id)}
              </li>
            </ul>
          </div>
          <div class="flex justify-between gap-2">
            <.ops_button
              type="button"
              phx-click="cancel_retry_delete"
              variant={:ghost}
              aria-label="Cancel delete sync work"
              data-ops-modal-cancel
            >
              Cancel
            </.ops_button>
            <.ops_button type="submit" variant={:danger}>Retry delete sync work</.ops_button>
          </div>
        </.form>
      </.ops_modal>
    </Layouts.app>
    """
  end

  defp format_dt(nil), do: "—"

  defp format_dt(%DateTime{} = dt) do
    Calendar.strftime(dt, "%b %d, %Y at %H:%M UTC")
  end

  defp failed_work_title(%{source: :oban, id: id}), do: "Queue job #{inspect(id)}"
  defp failed_work_title(%{source: :meilisearch, id: id}), do: "Backend task #{inspect(id)}"
  defp failed_work_title(%{source: source, id: id}), do: "#{source} work #{inspect(id)}"
end
