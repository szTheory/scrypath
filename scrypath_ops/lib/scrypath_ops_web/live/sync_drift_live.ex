defmodule ScrypathOpsWeb.SyncDriftLive do
  @moduledoc """
  Read-only sync and index contract drift using `Scrypath.reconcile_sync/2` and
  `Scrypath.index_contract_drift/2`.

  On mount, **reconcile** loads automatically (without `include_index_contract_drift`).
  **Index contract drift** loads only after the explicit control.
  """

  use ScrypathOpsWeb, :live_view

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
    {:noreply, refresh_reconcile(socket)}
  end

  def handle_event("load_drift", _params, socket) do
    {:noreply, refresh_drift(socket)}
  end

  def handle_event("select_schema", %{"schema" => mod_str}, socket) do
    case mod_from_allowlist(mod_str, socket.assigns.schema_allowlist) do
      {:ok, mod} ->
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

      :error ->
        {:noreply, put_flash(socket, :error, "Select an allowlisted schema.")}
    end
  end

  def handle_event("swap_live", _params, socket) do
    {:noreply, swap_live(socket)}
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
            |> refresh_reconcile()
            |> maybe_refresh_drift()

          {:error, reason} ->
            put_flash(socket, :error, "Swap live failed: #{inspect(reason)}")
        end
      else
        put_flash(socket, :error, "Select a schema and configure Scrypath runtime.")
      end
    end)
  end

  defp maybe_refresh_drift(socket) do
    if socket.assigns.drift_loaded_at || socket.assigns.drift_result || socket.assigns.drift_error do
      refresh_drift(socket)
    else
      socket
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app mount_path={@mount_path} flash={@flash} shell={@shell} page_title={@page_title}>
      <.ops_page_header title={@page_title} />

      <.ops_schema_select
        id="sync-schema-select"
        schemas={@schema_allowlist}
        selected={@selected_schema}
        phx-change="select_schema"
        class="mt-4"
      />

      <.ops_notice kind={:info} title="Read-only Recovery Map" class="mt-4">
        Use <code class="text-xs">mix scrypath.reconcile</code>, <code class="text-xs">mix scrypath.index.contract_drift</code>, <code class="text-xs">guides/drift-recovery.md</code>,
        <code class="text-xs">guides/sync-modes-and-visibility.md</code>
        for canonical workflows. This page stays read-only over
        <code class="text-xs">Scrypath.reconcile_sync/2</code>
        and <code class="text-xs">Scrypath.index_contract_drift/2</code>.
      </.ops_notice>

      <.ops_panel>
        <section aria-labelledby="sync-reconcile-heading" class="mt-2 space-y-3">
          <.ops_toolbar class="gap-2">
            <h2 id="sync-reconcile-heading" class="text-lg font-semibold">Sync & queue posture</h2>
            <.ops_button phx-click="refresh_reconcile" variant={:primary}>
              Refresh reconcile
            </.ops_button>
          </.ops_toolbar>

          <p :if={@reconcile_loaded_at} class="text-xs text-base-content/60">
            Last loaded: <span class="font-mono tabular-nums">{format_dt(@reconcile_loaded_at)}</span>
          </p>

          <.ops_table
            :if={@reconcile_result}
            class="rounded border border-base-300 p-3 text-sm"
          >
            <thead>
              <tr>
                <th scope="col">Signal</th>
                <th scope="col">Value</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <th scope="row" class="font-medium align-top">Index</th>
                <td><code class="text-xs">{@reconcile_result.index}</code></td>
              </tr>
              <tr>
                <th scope="row" class="font-medium align-top">Mode</th>
                <td>{@reconcile_result.mode}</td>
              </tr>
              <tr>
                <th scope="row" class="font-medium align-top">Drift signals</th>
                <td class="font-mono text-xs">{inspect(@reconcile_result.drift_signals)}</td>
              </tr>
            </tbody>
          </.ops_table>

          <p :if={@reconcile_result == nil && @selected_schema} class="text-sm text-base-content/70">
            Reconcile not loaded yet — choose a schema or tap “Refresh reconcile”.
          </p>
        </section>
      </.ops_panel>

      <.ops_panel>
        <section aria-labelledby="sync-drift-heading" class="mt-2 space-y-3">
          <.ops_toolbar class="gap-2">
            <h2 id="sync-drift-heading" class="text-lg font-semibold">
              Index contract (declared vs live)
            </h2>
            <div class="flex flex-wrap gap-2">
              <.ops_button phx-click="load_drift">
                Load / refresh contract drift
              </.ops_button>
              <.ops_button
                :if={@selected_schema}
                phx-click="swap_live"
                phx-disable-with="Swapping..."
              >
                Swap live index
              </.ops_button>
            </div>
          </.ops_toolbar>

          <p :if={@drift_loaded_at} class="text-xs text-base-content/60">
            Last loaded: <span class="font-mono tabular-nums">{format_dt(@drift_loaded_at)}</span>
          </p>

          <p :if={@drift_error} class="text-sm text-error">
            Drift error (reconcile above stays usable): {inspect(@drift_error)}
          </p>

          <.ops_table
            :if={@drift_result}
            class="rounded border border-base-300 p-3 text-sm"
          >
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
                <td class="font-mono text-xs tabular-nums">
                  version {@drift_result.version} · index {@drift_result.index}
                </td>
              </tr>
            </tbody>
          </.ops_table>

          <p :if={@drift_result == nil && @drift_error == nil} class="text-sm text-base-content/70">
            Contract drift has not been loaded yet — it runs only after the explicit control.
          </p>
        </section>
      </.ops_panel>
    </Layouts.app>
    """
  end

  defp format_dt(nil), do: "—"

  defp format_dt(%DateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%d %H:%M:%SZ")
  end
end
