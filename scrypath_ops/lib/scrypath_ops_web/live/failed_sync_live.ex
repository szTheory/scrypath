defmodule ScrypathOpsWeb.FailedSyncLive do
  @moduledoc """
  Read-only failed sync triage using `Scrypath.failed_sync_work/2` with
  `reason_class_counts: true` and `%Scrypath.Operator.FailedSyncWorkInspection{}`.
  """

  use ScrypathOpsWeb, :live_view

  alias Scrypath.Operator.FailedSyncWorkInspection

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

  def handle_event("select_schema", %{"schema" => mod_str}, socket) do
    mod = mod_from_flat!(mod_str)

    {:noreply,
     socket
     |> assign(:selected_schema, mod)
     |> refresh_inspection()}
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

  defp empty_counts(rows) do
    Scrypath.Operator.FailedWork.reason_class_counts(rows)
  end

  defp module_flat_name(mod) when is_atom(mod) do
    mod |> Atom.to_string() |> String.replace_prefix("Elixir.", "")
  end

  defp mod_from_flat!(str) when is_binary(str) do
    str
    |> String.trim()
    |> String.split(".")
    |> Enum.map(&String.to_atom/1)
    |> Module.concat()
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
  defp reason_class_label(other), do: to_string(other)

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} shell={@shell}>
      <div class="flex flex-wrap items-center justify-between gap-4">
        <h1 class="text-2xl font-semibold leading-8 tracking-tight text-balance">Failed sync work</h1>
        <div class="flex flex-wrap gap-2">
          <button type="button" phx-click="refresh" class="btn btn-sm btn-primary">Refresh</button>
          <button type="button" phx-click="toggle_compact" class="btn btn-sm">
            Toggle compact mode
          </button>
        </div>
      </div>

      <form :if={@schema_allowlist != []} class="mt-4 flex flex-wrap items-center gap-2">
        <label for="schema-select" class="text-sm">Schema</label>
        <select
          id="schema-select"
          name="schema"
          class="select select-bordered select-sm"
          phx-change="select_schema"
        >
          <%= for mod <- @schema_allowlist do %>
            <option value={module_flat_name(mod)} selected={mod == @selected_schema}>
              {module_flat_name(mod)}
            </option>
          <% end %>
        </select>
      </form>

      <p :if={@load_error == :no_schemas} class="mt-4 text-base-content/80">
        No schemas configured — set <code class="text-sm">schema_allowlist</code>
        in <code class="text-sm">:scrypath_ops</code>
        (see README).
      </p>

      <p :if={@load_error == :missing_backend} class="mt-4 text-base-content/80">
        Scrypath runtime is not configured — see <code class="text-sm">scrypath_ops/README.md</code>.
      </p>

      <p
        :if={@inspection == nil && @load_error && @load_error not in [:no_schemas, :missing_backend]}
        class="mt-4 text-error"
      >
        {inspect(@load_error)}
      </p>

      <div :if={@inspection} class="mt-4 space-y-4">
        <div class={["rounded border border-base-300 p-3", @compact_mode && "hidden"]}>
          <h2 class="text-sm font-semibold uppercase tracking-wide text-base-content/70">Rollups</h2>
          <p class="mt-2 font-mono text-sm">
            total <span class="font-bold">{@inspection.counts.total}</span>
            · transport {@inspection.counts.by_class.transport} · validation {@inspection.counts.by_class.validation} · backend_rejected {@inspection.counts.by_class.backend_rejected} · queue_exhausted {@inspection.counts.by_class.queue_exhausted} · unknown {@inspection.counts.by_class.unknown}
          </p>
        </div>

        <p class="text-xs text-base-content/60">
          For recovery actions use <code class="text-sm">mix scrypath.failed</code>
          and the repo guides <code class="text-sm">guides/drift-recovery.md</code>, <code class="text-sm">guides/operator-mix-tasks.md</code>.
        </p>

        <div class="overflow-x-auto">
          <table class="table table-zebra table-sm">
            <thead>
              <tr>
                <th>ID</th>
                <th>reason_class</th>
                <th>Operation</th>
                <th>State</th>
                <th>Source</th>
                <th>Last attempt</th>
                <th>Detail</th>
              </tr>
            </thead>
            <tbody>
              <%= for row <- sorted_entries(@inspection) do %>
                <tr id={"failed-#{row.id}"}>
                  <td class="font-mono text-xs">{inspect(row.id)}</td>
                  <td>{reason_class_label(row.reason_class)}</td>
                  <td>{row.operation}</td>
                  <td>{row.state}</td>
                  <td>{row.source}</td>
                  <td class="font-mono text-xs">{format_dt(row.last_attempt_at || row.failed_at)}</td>
                  <td>
                    <details>
                      <summary class="cursor-pointer text-sm">Row detail</summary>
                      <pre class="mt-2 max-h-48 overflow-auto text-xs whitespace-pre-wrap"><%= row.reason %></pre>
                      <pre :if={map_size(row.metadata) > 0} class="mt-2 text-xs"><%= inspect(row.metadata, pretty: true) %></pre>
                      <p class="mt-2 text-xs">
                        See guides: <code class="text-xs">guides/drift-recovery.md</code>,
                        <code class="text-xs">guides/operator-mix-tasks.md</code>
                      </p>
                    </details>
                  </td>
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
end
