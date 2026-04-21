defmodule ScrypathOpsWeb.SyncDriftLive do
  @moduledoc """
  Read-only sync and index contract drift using `Scrypath.reconcile_sync/2` and
  `Scrypath.index_contract_drift/2`.

  On mount, **reconcile** loads automatically (without `include_index_contract_drift`).
  **Index contract drift** loads only after the explicit control.
  """

  use ScrypathOpsWeb, :live_view

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
      |> assign(:page_title, "Sync / drift")
      |> assign(:schema_allowlist, allowlist)
      |> assign(:scrypath_opts, scrypath_opts)
      |> assign(:selected_schema, selected)
      |> assign(:reconcile_result, nil)
      |> assign(:reconcile_loaded_at, nil)
      |> assign(:drift_result, nil)
      |> assign(:drift_loaded_at, nil)
      |> assign(:drift_error, nil)

    {:ok, load_reconcile_on_mount(socket)}
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
    mod = socket.assigns.selected_schema
    opts = socket.assigns.scrypath_opts

    socket =
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

    {:noreply, socket}
  end

  def handle_event("load_drift", _params, socket) do
    mod = socket.assigns.selected_schema
    opts = socket.assigns.scrypath_opts

    socket =
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

    {:noreply, socket}
  end

  def handle_event("select_schema", %{"schema" => mod_str}, socket) do
    mod = mod_from_flat!(mod_str)

    socket =
      socket
      |> assign(:selected_schema, mod)
      |> assign(:reconcile_result, nil)
      |> assign(:reconcile_loaded_at, nil)
      |> assign(:drift_result, nil)
      |> assign(:drift_loaded_at, nil)
      |> assign(:drift_error, nil)
      |> load_reconcile_on_mount()

    {:noreply, socket}
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

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} shell={@shell}>
      <.ops_page_header title={@page_title} />

      <form :if={@schema_allowlist != []} class="mt-4 flex flex-wrap items-center gap-2">
        <label for="sync-schema-select" class="text-sm">Schema</label>
        <select
          id="sync-schema-select"
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

      <p class="mt-4 text-sm text-base-content/70">
        Use <code class="text-xs">mix scrypath.reconcile</code>, <code class="text-xs">mix scrypath.index.contract_drift</code>, <code class="text-xs">guides/drift-recovery.md</code>,
        <code class="text-xs">guides/sync-modes-and-visibility.md</code>
        for canonical workflows. This page stays read-only over
        <code class="text-xs">Scrypath.reconcile_sync/2</code>
        and <code class="text-xs">Scrypath.index_contract_drift/2</code>.
      </p>

      <.ops_panel>
        <div class="mt-2 space-y-3">
          <div class="flex flex-wrap items-center justify-between gap-2">
            <h2 class="text-lg font-semibold">Sync & queue posture</h2>
            <button type="button" phx-click="refresh_reconcile" class="btn btn-sm btn-primary">
              Refresh reconcile
            </button>
          </div>

          <p :if={@reconcile_loaded_at} class="text-xs text-base-content/60">
            Last loaded: <span class="font-mono tabular-nums">{format_dt(@reconcile_loaded_at)}</span>
          </p>

          <div :if={@reconcile_result} class="rounded border border-base-300 p-3 text-sm space-y-1">
            <p>
              <span class="font-medium">Index:</span>
              <code class="text-xs">{@reconcile_result.index}</code>
            </p>
            <p><span class="font-medium">Mode:</span> {@reconcile_result.mode}</p>
            <p>
              <span class="font-medium">Drift signals:</span>
              {inspect(@reconcile_result.drift_signals)}
            </p>
          </div>

          <p :if={@reconcile_result == nil && @selected_schema} class="text-sm text-base-content/70">
            Reconcile not loaded yet — choose a schema or tap “Refresh reconcile”.
          </p>
        </div>
      </.ops_panel>

      <.ops_panel>
        <div class="mt-2 space-y-3">
          <div class="flex flex-wrap items-center justify-between gap-2">
            <h2 class="text-lg font-semibold">Index contract (declared vs live)</h2>
            <button type="button" phx-click="load_drift" class="btn btn-sm">
              Load / refresh contract drift
            </button>
          </div>

          <p :if={@drift_loaded_at} class="text-xs text-base-content/60">
            Last loaded: <span class="font-mono tabular-nums">{format_dt(@drift_loaded_at)}</span>
          </p>

          <p :if={@drift_error} class="text-sm text-error">
            Drift error (reconcile above stays usable): {inspect(@drift_error)}
          </p>

          <div :if={@drift_result} class="rounded border border-base-300 p-3 text-sm">
            <p class="font-medium">Index contract snapshot</p>
            <p class="mt-2 font-mono text-xs tabular-nums">
              version {@drift_result.version} · index {@drift_result.index}
            </p>
          </div>

          <p :if={@drift_result == nil && @drift_error == nil} class="text-sm text-base-content/70">
            Contract drift has not been loaded yet — it runs only after the explicit control.
          </p>
        </div>
      </.ops_panel>
    </Layouts.app>
    """
  end

  defp format_dt(nil), do: "—"

  defp format_dt(%DateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%d %H:%M:%SZ")
  end
end
