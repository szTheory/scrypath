defmodule ScrypathOpsWeb.FailedSyncLive do
  @moduledoc """
  Read-only failed sync triage using `Scrypath.failed_sync_work/2` with
  `reason_class_counts: true` and `%Scrypath.Operator.FailedSyncWorkInspection{}`.
  """

  use ScrypathOpsWeb, :live_view

  alias Scrypath.Operator.FailedWork
  alias Scrypath.Operator.FailedSyncWorkInspection
  alias ScrypathOps.Integrations.Sigra.Gating

  @impl true
  def mount(_params, _session, socket) do
    allowlist = ScrypathOps.Schemas.allowlist()
    scrypath_opts = ScrypathOps.Schemas.scrypath_opts()

    selected =
      case allowlist do
        [first | _] -> first
        [] -> nil
      end

    socket =
      socket
      |> assign(:page_title, "Failed sync work")
      |> assign(:schema_allowlist, allowlist)
      |> assign(:scrypath_opts, scrypath_opts)
      |> assign(:selected_schema, selected)
      |> assign(:inspection, nil)
      |> assign(:load_error, nil)
      |> assign(:compact_mode, false)
      |> assign(:last_refresh_at, nil)

    {:ok, refresh_inspection(socket)}
  end

  @impl true
  def handle_event("refresh", _params, socket), do: {:noreply, refresh_inspection(socket)}

  def handle_event("retry", %{"id" => id}, socket) do
    socket =
      Gating.gate_sensitive_action(socket, :failed_work_retry, fn ->
        retry_failed_work(socket, id)
      end)

    {:noreply, normalize_live_reply(socket)}
  end

  def handle_event("select_schema", %{"schema" => mod_str}, socket) do
    case mod_from_allowlist(mod_str, socket.assigns.schema_allowlist) do
      {:ok, mod} ->
        {:noreply,
         socket
         |> assign(:selected_schema, mod)
         |> refresh_inspection()}

      :error ->
        {:noreply, put_flash(socket, :error, "Select an allowlisted schema.")}
    end
  end

  def handle_event("toggle_compact", _params, socket) do
    {:noreply, assign(socket, :compact_mode, not socket.assigns.compact_mode)}
  end

  defp refresh_inspection(socket) do
    mod = socket.assigns.selected_schema
    opts = Keyword.put(socket.assigns.scrypath_opts, :reason_class_counts, true)

    cond do
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

  defp retry_failed_work(socket, id) do
    case failed_work_row(socket, id) do
      nil ->
        put_flash(socket, :error, "Could not find that failed job.")

      row ->
        case FailedWork.recovery_action(row) do
          nil ->
            put_flash(socket, :error, "That job does not expose a retry action.")

          recovery ->
            case Scrypath.retry_sync_work(
                   recovery,
                   ScrypathOps.Schemas.runtime_opts(socket.assigns.scrypath_opts)
                 ) do
              {:ok, _result} ->
                socket
                |> refresh_inspection()
                |> put_flash(:info, "Retried #{id}")

              {:error, reason} ->
                put_flash(socket, :error, "Retry failed: #{inspect(reason)}")
            end
        end
    end
  end

  defp failed_work_row(socket, id) do
    inspection = socket.assigns.inspection

    if inspection do
      Enum.find(inspection.entries, &(to_string(&1.id) == to_string(id)))
    end
  end

  defp empty_counts(rows) do
    Scrypath.Operator.FailedWork.reason_class_counts(rows)
  end

  defp module_flat_name(mod) when is_atom(mod) do
    mod |> Atom.to_string() |> String.replace_prefix("Elixir.", "")
  end

  defp mod_from_allowlist(str, allowlist) when is_binary(str) do
    name = String.trim(str)

    case Enum.find(allowlist, &(module_flat_name(&1) == name)) do
      nil -> :error
      mod -> {:ok, mod}
    end
  end

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

  defp failed_sync_status_title(%FailedSyncWorkInspection{counts: counts}),
    do: "#{counts.total} failed sync job(s) need triage"

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
        <div class="flex flex-wrap gap-2">
          <.ops_button phx-click="refresh" variant={:primary} data-ops-refresh>
            Refresh failed sync jobs
          </.ops_button>
          <.ops_button phx-click="toggle_compact" variant={:ghost}>
            {if @compact_mode, do: "Show reason rollups", else: "Hide reason rollups"}
          </.ops_button>
        </div>
      </.ops_toolbar>

      <.ops_journey mount_path={@mount_path} current={:failed_sync} />

      <.ops_panel>
        <.ops_schema_select
          id="schema-select"
          schemas={@schema_allowlist}
          selected={@selected_schema}
          phx-change="select_schema"
          hint="Choose the allowlisted schema whose failed queue/backend work you want to inspect."
        />
      </.ops_panel>

      <.ops_empty_state :if={@load_error == :no_schemas} title="No Schemas Configured">
        Set
        <.ops_inline_code>schema_allowlist</.ops_inline_code>
        in <.ops_inline_code>:scrypath_ops</.ops_inline_code>.
      </.ops_empty_state>

      <.ops_empty_state
        :if={@load_error == :missing_backend}
        title="Runtime Not Configured"
      >
        Scrypath runtime is not configured — see <.ops_inline_code>scrypath_ops/README.md</.ops_inline_code>.
      </.ops_empty_state>

      <.ops_status
        :if={@inspection == nil && @load_error && @load_error not in [:no_schemas, :missing_backend]}
        kind={:error}
        title="Failed sync work could not load"
        role="alert"
      >
        The selected schema could not be inspected. Check backend and queue configuration, then
        refresh failed sync jobs. Reason: <code>{inspect(@load_error)}</code>
      </.ops_status>

      <.ops_panel :if={@inspection}>
        <section aria-labelledby="failed-sync-rollups-heading">
          <.ops_status
            kind={failed_sync_status_kind(@inspection)}
            title={failed_sync_status_title(@inspection)}
          >
            Selected schema: <code>{module_flat_name(@selected_schema)}</code>
            · dominant reason:
            <strong>{reason_class_label(dominant_reason_class(@inspection))}</strong>
            · retryable jobs: <strong>{retryable_count(@inspection)}</strong>
            · refreshed <span class="font-mono tabular-nums">{format_dt(@last_refresh_at)}</span>
          </.ops_status>

          <.ops_metric_grid cols={6} class={@compact_mode && "hidden"}>
            <h2
              id="failed-sync-rollups-heading"
              class="sr-only"
            >
              Rollups
            </h2>
            <.ops_metric
              label="Total"
              value={@inspection.counts.total}
              kind={metric_tone(@inspection.counts.total)}
            />
            <.ops_metric label="Transport" value={@inspection.counts.by_class.transport} />
            <.ops_metric label="Validation" value={@inspection.counts.by_class.validation} />
            <.ops_metric label="Backend" value={@inspection.counts.by_class.backend_rejected} />
            <.ops_metric label="Queue" value={@inspection.counts.by_class.queue_exhausted} />
            <.ops_metric label="Unknown" value={@inspection.counts.by_class.unknown} />
          </.ops_metric_grid>

          <.ops_disclosure
            summary="Triage guidance"
            class="mt-4"
          >
            <div class="grid gap-3 lg:grid-cols-3">
              <.ops_data_card
                title="Triage order"
                subtitle="Use the largest nonzero class first, then inspect retryable rows."
              >
                <ol class="list-inside list-decimal space-y-1 text-ops-sm text-base-content/75">
                  <li>Transport: check connectivity, timeout, and credential drift.</li>
                  <li>Validation: compare payload shape against the current schema contract.</li>
                  <li>Backend / queue: inspect backend rejection and retry exhaustion separately.</li>
                </ol>
              </.ops_data_card>
              <.ops_data_card
                title="Unknown failures"
                subtitle="Unknown means Scrypath could not classify the stored failure into a known operational bucket."
              >
                <p class="text-ops-sm text-base-content/75">
                  Open row evidence before retrying. Unknown rows usually need a human read of the raw reason.
                </p>
              </.ops_data_card>
              <.ops_data_card
                title="Retry semantics"
                subtitle="Retry re-enqueues original work; it does not erase history or guarantee backend acceptance."
              >
                <p class="text-ops-sm text-base-content/75">
                  Retry only after the class-specific cause is addressed. The row remains useful evidence until the next successful sync path updates operator state.
                </p>
              </.ops_data_card>
            </div>
          </.ops_disclosure>

          <p class="mt-4 text-ops-sm text-base-content/60">
            For recovery actions use <code class="text-ops-body">mix scrypath.failed</code>
            and the repo guides <code class="text-ops-body">guides/drift-recovery.md</code>, <code class="text-ops-body">guides/operator-mix-tasks.md</code>.
          </p>
        </section>

        <section aria-labelledby="failed-sync-table-heading" class="mt-4">
          <h2
            id="failed-sync-table-heading"
            class="text-ops-h2 font-semibold leading-ops-tight text-base-content"
          >
            Failed sync jobs
          </h2>
          <p class="mt-1 max-w-3xl text-ops-body text-base-content/70">
            Rows are sorted by latest attempt so the newest operator evidence stays at the top.
            Open evidence only when needed; retry is scoped to the selected row.
          </p>
          <.ops_empty_state
            :if={@inspection.counts.total == 0}
            title="No Failed Sync Jobs"
            class="mt-2"
          >
            No failed sync work is visible for this schema. Keep checking posture and drift before changing indexes.
          </.ops_empty_state>

          <div :if={@inspection.counts.total > 0} class="mt-3 grid gap-2">
            <.ops_result_row
              :for={row <- sorted_entries(@inspection)}
              title={"Failed job #{inspect(row.id)}"}
              subtitle={"#{row.operation} · #{row.source} · last attempt #{format_dt(row.last_attempt_at || row.failed_at)}"}
              data-testid="failed-sync-row"
            >
              <:meta>
                <.ops_badge kind={:warning}>{reason_class_label(row.reason_class)}</.ops_badge>
                <.ops_badge kind={:error}>{row.state}</.ops_badge>
                <.ops_badge :if={row.retryable?} kind={:partial}>retryable</.ops_badge>
              </:meta>
              <.ops_disclosure
                id={"failed-detail-#{row.id}"}
                summary="View evidence"
                variant={:compact}
              >
                <div class="grid gap-3 lg:grid-cols-[minmax(0,1fr)_18rem]">
                  <div>
                    <.ops_code_block
                      id={"failed-detail-body-#{row.id}"}
                      variant={:embedded}
                    >
                      {row.reason}
                    </.ops_code_block>
                    <.ops_code_block
                      :if={map_size(row.metadata) > 0}
                      variant={:embedded}
                      class="mt-2"
                    >
                      {inspect(row.metadata, pretty: true)}
                    </.ops_code_block>
                  </div>
                  <.ops_action_group :if={row.recovery} tone={:advanced} class="items-start">
                    <p class="text-ops-sm text-base-content/75">
                      Retry re-enqueues the original sync work and keeps this row visible until the backend confirms recovery.
                    </p>
                    <.ops_button
                      phx-click="retry"
                      phx-value-id={row.id}
                      data-testid="failed-sync-retry"
                      variant={:primary}
                      size={:xs}
                    >
                      Retry job
                    </.ops_button>
                  </.ops_action_group>
                </div>
              </.ops_disclosure>
            </.ops_result_row>
          </div>
        </section>
      </.ops_panel>

      <.ops_toolbar :if={@inspection} class="justify-end">
        <.ops_link_button navigate={"#{@mount_path}/sync-drift"} variant={:ghost} size={:sm}>
          Worked the queue? Verify sync drift <span aria-hidden="true">→</span>
        </.ops_link_button>
      </.ops_toolbar>
    </Layouts.app>
    """
  end

  defp format_dt(nil), do: "—"

  defp format_dt(%DateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%d %H:%M:%SZ")
  end

  defp metric_tone(0), do: :success
  defp metric_tone(_), do: :warning
end
