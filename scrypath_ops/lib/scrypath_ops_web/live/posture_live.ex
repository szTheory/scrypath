defmodule ScrypathOpsWeb.PostureLive do
  @moduledoc """
  Read-only fleet posture over `Scrypath.sync_status/2` for allowlisted schemas.

  Uses bounded `Task.async_stream/3` per refresh. **Manual refresh** is primary;
  optional auto-refresh is reserved (assign defaults to `false`; see README).
  """

  use ScrypathOpsWeb, :live_view

  alias ScrypathOps.Integrations.Sigra.Gating
  alias Scrypath.Meilisearch.Tasks

  @impl true
  def mount(_params, _session, socket) do
    allowlist = ScrypathOps.Schemas.allowlist()
    scrypath_opts = ScrypathOps.Schemas.scrypath_opts()

    socket =
      socket
      |> assign(:page_title, "Posture / health")
      |> assign(:schema_allowlist, allowlist)
      |> assign(:scrypath_opts, scrypath_opts)
      |> assign(:auto_refresh, false)
      |> assign(:posture_rows, [])
      |> assign(:aggregate_error_count, 0)
      |> assign(:last_refresh_at, nil)
      |> assign(:posture_state, :ok)
      |> assign(:posture_headline, "—")
      |> assign(:posture_evidence, "")
      |> assign(:next_checks, [])

    {:ok, load_posture(socket)}
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    start_ms = System.monotonic_time(:millisecond)
    socket = load_posture(socket)
    duration_ms = System.monotonic_time(:millisecond) - start_ms

    # Low-cardinality telemetry: no per-schema labels (CONTEXT D-08).
    :telemetry.execute(
      [:scrypath_ops, :posture, :refresh],
      %{duration_ms: duration_ms, schema_count: length(socket.assigns.schema_allowlist)},
      %{outcome: if(socket.assigns.aggregate_error_count > 0, do: :degraded, else: :ok)}
    )

    {:noreply, socket}
  end

  def handle_event("swap_live", %{"schema" => mod_str}, socket) do
    case mod_from_allowlist(mod_str, socket.assigns.schema_allowlist) do
      {:ok, mod} ->
        {:noreply, swap_live(socket, mod)}

      :error ->
        {:noreply, put_flash(socket, :error, "Select an allowlisted schema.")}
    end
  end

  defp load_posture(socket) do
    summary =
      ScrypathOps.Posture.summary(
        socket.assigns.schema_allowlist,
        socket.assigns.scrypath_opts
      )

    socket
    |> assign(:posture_rows, posture_rows_assign(summary))
    |> assign(:aggregate_error_count, summary.error_count)
    |> assign(:last_refresh_at, summary.refreshed_at)
    |> assign(:posture_state, summary.state)
    |> assign(:posture_headline, summary.headline)
    |> assign(:posture_evidence, summary.evidence)
    |> assign(
      :next_checks,
      summary |> ScrypathOps.Posture.next_checks(socket.assigns.mount_path) |> Enum.take(5)
    )
  end

  # Map the shared summary back onto this view's legacy `posture_rows` assign,
  # which the per-schema table and empty-state guards still pattern-match on.
  defp posture_rows_assign(%ScrypathOps.Posture{state: :unconfigured}), do: :empty_allowlist
  defp posture_rows_assign(%ScrypathOps.Posture{state: :missing_backend}), do: :missing_backend
  defp posture_rows_assign(%ScrypathOps.Posture{rows: rows}), do: {:ok, rows}

  defp swap_live(socket, mod) do
    Gating.gate_sensitive_action(socket, :swap_live, fn ->
      scrypath_opts = socket.assigns.scrypath_opts
      wait_opts = task_wait_opts(scrypath_opts)

      case Scrypath.Meilisearch.swap_indexes(mod, scrypath_opts) do
        {:ok, %{task: task}} ->
          case Tasks.wait_for_task(task, wait_opts) do
            {:ok, _waited} ->
              socket
              |> load_posture()
              |> put_flash(:info, "Swap live index completed for #{module_flat_name(mod)}")

            {:error, reason} ->
              put_flash(socket, :error, "Swap live failed: #{inspect(reason)}")
          end

        {:error, reason} ->
          put_flash(socket, :error, "Swap live failed: #{inspect(reason)}")
      end
    end)
  end

  defp task_wait_opts(opts) do
    opts
    |> Keyword.put_new(:inline_poll_interval, 50)
    |> Keyword.put_new(:inline_timeout, 15_000)
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
          title="Posture"
          subtitle="The fleet's sync health, schema by schema. Start here when something looks wrong."
        />
        <.ops_button phx-click="refresh" variant={:primary} data-ops-refresh>
          Refresh posture
        </.ops_button>
      </.ops_toolbar>

      <.ops_journey mount_path={@mount_path} current={:posture} />

      <.ops_panel :if={match?({:ok, _}, @posture_rows)}>
        <section aria-labelledby="posture-summary-heading" class="space-y-4">
          <h2 id="posture-summary-heading" class="sr-only">Fleet posture</h2>
          <.ops_verdict
            kind={ScrypathOps.Posture.badge_kind(@posture_state)}
            label="Fleet posture"
            headline={@posture_headline}
          >
            <:actions>
              <.ops_link_button
                :if={@posture_state == :degraded}
                navigate={"#{@mount_path}/failed-sync"}
                variant={:primary}
                size={:sm}
              >
                Start triage: failed sync <span aria-hidden="true">→</span>
              </.ops_link_button>
            </:actions>
            {@posture_evidence}
          </.ops_verdict>
          <.ops_metric_grid cols={5}>
            <.ops_metric
              label="Schemas"
              value={posture_schema_count(@posture_rows)}
              kind={:neutral}
            />
            <.ops_metric
              label="Fetch errors"
              value={@aggregate_error_count}
              kind={metric_tone(@aggregate_error_count)}
            />
            <.ops_metric
              label="Failed backend"
              value={posture_backend_failed_count(@posture_rows)}
              kind={metric_tone(posture_backend_failed_count(@posture_rows))}
            />
            <.ops_metric
              label="Queue observed"
              value={posture_queue_observed_count(@posture_rows)}
              kind={:neutral}
            />
            <.ops_metric
              label="Refreshed"
              value={format_dt(@last_refresh_at)}
              kind={:neutral}
            />
          </.ops_metric_grid>
        </section>
      </.ops_panel>

      <.ops_panel :if={@next_checks != []}>
        <section
          data-testid="posture-next-checks"
          aria-labelledby="posture-jtbd-heading"
          class="space-y-1"
        >
          <.ops_heading level={2} id="posture-jtbd-heading">Next checks</.ops_heading>
          <p class="text-ops-body text-base-content/80">{@posture_evidence}</p>
          <ol class="mt-3 list-decimal list-inside space-y-2 text-ops-body text-base-content/90">
            <li :for={check <- @next_checks} class="pl-1">
              <span>{check.text}</span>
              <span :if={check[:navigate]} class="ml-2">
                <.link navigate={check.navigate} class="link link-primary">Open in OPSUI</.link>
              </span>
              <span :if={check[:href]} class="ml-2">
                <a href={check.href} class="link link-primary">Open guide</a>
              </span>
              <span :if={check[:mix]} class="mt-1 block font-mono text-ops-sm text-base-content/70">
                {check.mix}
              </span>
            </li>
          </ol>
        </section>
      </.ops_panel>

      <p :if={@auto_refresh} class="mt-2 text-ops-body text-base-content/70">
        Auto-refresh is not enabled by default; only manual refresh runs in this build.
      </p>

      <.ops_config_empty :if={@posture_rows == :empty_allowlist} kind={:no_schemas} class="mt-4" />
      <.ops_config_empty :if={@posture_rows == :missing_backend} kind={:missing_backend} class="mt-4" />

      <.ops_panel :if={match?({:ok, _}, @posture_rows)}>
        <.ops_section
          id="posture-fleet-heading"
          title="Per-schema signals"
          subtitle={"#{@aggregate_error_count} schema(s) with fetch errors"}
          meta={"refreshed #{format_dt(@last_refresh_at)}"}
        >
          <.ops_table zebra class="mt-3">
            <thead>
              <tr>
                <th scope="col">Schema</th>
                <th scope="col">Index</th>
                <th scope="col">Sync mode</th>
                <th scope="col">Backend pending</th>
                <th scope="col">Backend failed</th>
                <th scope="col">Backend last OK</th>
                <th scope="col">Queue observed</th>
                <th scope="col">Queue pending</th>
                <th scope="col">Queue retrying</th>
                <th scope="col">Queue failed</th>
                <th scope="col">Queue last OK</th>
              </tr>
            </thead>
            <tbody class="text-ops-body leading-snug tabular-nums">
              <%= for {mod, row} <- elem(@posture_rows, 1) do %>
                <tr data-testid="posture-row" id={"posture-#{inspect(mod)}"}>
                  <%= case row do %>
                    <% {:ok, status} -> %>
                      <td class="font-mono text-ops-sm">{inspect(mod)}</td>
                      <td class="font-mono text-ops-sm">{status.index}</td>
                      <td>{status.mode}</td>
                      <td>{length(status.backend.pending)}</td>
                      <td>{length(status.backend.failed)}</td>
                      <td>{format_state_ts(status.backend.last_succeeded)}</td>
                      <td>
                        <%= if status.queue.observed? do %>
                          <.ops_badge kind={:success}>observed</.ops_badge>
                        <% else %>
                          <.ops_badge kind={:warning}>queue not observed</.ops_badge>
                        <% end %>
                      </td>
                      <td>{length(status.queue.pending)}</td>
                      <td>{length(status.queue.retrying)}</td>
                      <td>{length(status.queue.failed)}</td>
                      <td>{format_state_ts(status.queue.last_succeeded)}</td>
                    <% {:error, reason} -> %>
                      <td class="font-mono text-ops-sm">{inspect(mod)}</td>
                      <td colspan="10" class="text-error">
                        fetch error: {inspect(reason)}
                      </td>
                  <% end %>
                </tr>
              <% end %>
            </tbody>
          </.ops_table>
        </.ops_section>
      </.ops_panel>
    </Layouts.app>
    """
  end

  defp posture_schema_count({:ok, rows}), do: length(rows)
  defp posture_schema_count(_), do: 0

  defp posture_backend_failed_count({:ok, rows}) do
    Enum.reduce(rows, 0, fn
      {_mod, {:ok, status}}, acc -> acc + length(status.backend.failed)
      _row, acc -> acc
    end)
  end

  defp posture_backend_failed_count(_), do: 0

  defp posture_queue_observed_count({:ok, rows}) do
    Enum.count(rows, fn
      {_mod, {:ok, status}} -> status.queue.observed?
      _row -> false
    end)
  end

  defp posture_queue_observed_count(_), do: 0

  defp format_dt(nil), do: "—"

  defp format_dt(%DateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%d %H:%M:%SZ")
  end

  defp format_state_ts(nil), do: "—"
  defp format_state_ts(%Scrypath.Operator.State{} = s), do: format_dt(s.at)

  defp metric_tone(0), do: :success
  defp metric_tone(_), do: :warning
end
