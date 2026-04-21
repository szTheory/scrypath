defmodule ScrypathOpsWeb.PostureLive do
  @moduledoc """
  Read-only fleet posture over `Scrypath.sync_status/2` for allowlisted schemas.

  Uses bounded `Task.async_stream/3` per refresh. **Manual refresh** is primary;
  optional auto-refresh is reserved (assign defaults to `false`; see README).
  """

  use ScrypathOpsWeb, :live_view

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

  defp load_posture(socket) do
    allowlist = socket.assigns.schema_allowlist
    opts = socket.assigns.scrypath_opts

    cond do
      allowlist == [] ->
        socket
        |> assign(:posture_rows, :empty_allowlist)
        |> assign(:aggregate_error_count, 0)
        |> assign(:last_refresh_at, DateTime.utc_now())

      not Keyword.has_key?(opts, :backend) ->
        socket
        |> assign(:posture_rows, :missing_backend)
        |> assign(:aggregate_error_count, 0)
        |> assign(:last_refresh_at, DateTime.utc_now())

      true ->
        rows =
          allowlist
          |> Task.async_stream(
            fn mod ->
              {mod, Scrypath.sync_status(mod, opts)}
            end,
            max_concurrency: 3,
            timeout: 15_000,
            on_timeout: :kill_task
          )
          |> Enum.map(fn
            {:ok, {mod, res}} -> {mod, res}
            {:exit, reason} -> {:posture_stream, {:error, {:async_stream, reason}}}
          end)
          |> sort_rows()

        err_count = Enum.count(rows, fn {_m, r} -> match?({:error, _}, r) end)

        socket
        |> assign(:posture_rows, {:ok, rows})
        |> assign(:aggregate_error_count, err_count)
        |> assign(:last_refresh_at, DateTime.utc_now())
    end
  end

  defp sort_rows(rows) do
    Enum.sort_by(
      rows,
      fn
        {_m, {:error, _}} -> 0
        _ -> 1
      end
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} shell={@shell}>
      <div class="flex flex-wrap items-center justify-between gap-4">
        <h1 class="text-2xl font-semibold leading-8 tracking-tight text-balance">Posture / health</h1>
        <button
          type="button"
          phx-click="refresh"
          class="btn btn-sm btn-primary"
        >
          Refresh
        </button>
      </div>

      <p :if={@auto_refresh} class="mt-2 text-sm text-base-content/70">
        Auto-refresh is not enabled by default; only manual refresh runs in this build.
      </p>

      <p :if={@posture_rows == :empty_allowlist} class="mt-4 text-base-content/80">
        No schemas configured for OPSUI. Set <code class="text-sm">schema_allowlist</code>
        under <code class="text-sm">:scrypath_ops</code>
        or use <code class="text-sm">SCRYPATH_OPS_SCHEMAS</code>
        — see <code class="text-sm">scrypath_ops/README.md</code>.
      </p>

      <p :if={@posture_rows == :missing_backend} class="mt-4 text-base-content/80">
        Scrypath runtime is not configured (missing <code class="text-sm">:backend</code> and related
        options under <code class="text-sm">:scrypath_ops</code>). See <code class="text-sm">scrypath_ops/README.md</code>.
      </p>

      <div :if={match?({:ok, _}, @posture_rows)} class="mt-4 space-y-2">
        <p class="text-sm text-base-content/80">
          <span class="font-medium">{@aggregate_error_count}</span>
          schema(s) with fetch errors · refreshed
          <span class="font-mono text-xs">{format_dt(@last_refresh_at)}</span>
        </p>

        <div class="overflow-x-auto">
          <table class="table table-zebra table-sm">
            <thead>
              <tr>
                <th>Schema</th>
                <th>Index</th>
                <th>sync_mode</th>
                <th>Backend pending</th>
                <th>Backend failed</th>
                <th>Backend last OK</th>
                <th>Queue observed</th>
                <th>Queue pending</th>
                <th>Queue retrying</th>
                <th>Queue failed</th>
                <th>Queue last OK</th>
              </tr>
            </thead>
            <tbody>
              <%= for {mod, row} <- elem(@posture_rows, 1) do %>
                <tr data-testid="posture-row" id={"posture-#{inspect(mod)}"}>
                  <%= case row do %>
                    <% {:ok, status} -> %>
                      <td class="font-mono text-xs">{inspect(mod)}</td>
                      <td class="font-mono text-xs">{status.index}</td>
                      <td>{status.mode}</td>
                      <td>{length(status.backend.pending)}</td>
                      <td>{length(status.backend.failed)}</td>
                      <td>{format_state_ts(status.backend.last_succeeded)}</td>
                      <td>
                        <%= if status.queue.observed? do %>
                          true
                        <% else %>
                          <span class="text-warning">queue not observed</span>
                        <% end %>
                      </td>
                      <td>{length(status.queue.pending)}</td>
                      <td>{length(status.queue.retrying)}</td>
                      <td>{length(status.queue.failed)}</td>
                      <td>{format_state_ts(status.queue.last_succeeded)}</td>
                    <% {:error, reason} -> %>
                      <td class="font-mono text-xs">{inspect(mod)}</td>
                      <td colspan="10" class="text-error">
                        fetch error: {inspect(reason)}
                      </td>
                  <% end %>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp format_dt(nil), do: "—"

  defp format_dt(%DateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%d %H:%M:%SZ")
  end

  defp format_state_ts(nil), do: "—"
  defp format_state_ts(%Scrypath.Operator.State{} = s), do: format_dt(s.at)
end
