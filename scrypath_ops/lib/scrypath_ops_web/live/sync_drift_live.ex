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
            |> put_flash(:info, "Swap live index completed for #{module_flat_name(mod)}")

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

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app mount_path={@mount_path} flash={@flash} shell={@shell} page_title={@page_title}>
      <.ops_page_header
        title="Sync & Drift"
        subtitle="Check one schema before you promote it: reconcile, compare drift, then swap."
      />

      <.ops_journey mount_path={@mount_path} current={:sync_drift} class="mt-4" />

      <.ops_panel class="mt-4">
        <.ops_schema_select
          id="sync-schema-select"
          schemas={@schema_allowlist}
          selected={@selected_schema}
          phx-change="select_schema"
        />
      </.ops_panel>

      <.ops_notice kind={:info} title="Read-only checks first" class="mt-4">
        Use <code class="text-xs">mix scrypath.reconcile</code>, <code class="text-xs">mix scrypath.index.contract_drift</code>, <code class="text-xs">guides/drift-recovery.md</code>,
        <code class="text-xs">guides/sync-modes-and-visibility.md</code>
        for canonical workflows. The primary checks below stay read-only over
        <code class="text-xs">Scrypath.reconcile_sync/2</code>
        and <code class="text-xs">Scrypath.index_contract_drift/2</code>.
      </.ops_notice>

      <.ops_panel>
        <section aria-labelledby="sync-preflight-heading" class="space-y-3">
          <h2
            id="sync-preflight-heading"
            class="text-ops-h2 font-semibold leading-ops-tight text-base-content"
          >
            Promotion preflight
          </h2>
          <div class="grid gap-3 md:grid-cols-4">
            <.ops_data_card title="1. Reconcile">
              <.ops_badge kind={if @reconcile_result, do: :success, else: :warning}>
                {if @reconcile_result, do: "loaded", else: "needed"}
              </.ops_badge>
            </.ops_data_card>
            <.ops_data_card title="2. Contract drift">
              <.ops_badge kind={drift_status_kind(@drift_result, @drift_error)}>
                {drift_status_title(@drift_result, @drift_error)}
              </.ops_badge>
            </.ops_data_card>
            <.ops_data_card title="3. Mismatches">
              <.ops_badge kind={
                if @drift_result && drift_mismatch_count(@drift_result) == 0,
                  do: :success,
                  else: :warning
              }>
                {if @drift_result,
                  do: "#{drift_mismatch_count(@drift_result)} mismatch(es)",
                  else: "unknown"}
              </.ops_badge>
            </.ops_data_card>
            <.ops_data_card title="4. Promote">
              <.ops_badge kind={promotion_readiness_kind(@reconcile_result, @drift_result)}>
                {promotion_readiness_label(@reconcile_result, @drift_result)}
              </.ops_badge>
            </.ops_data_card>
          </div>
        </section>
      </.ops_panel>

      <.ops_panel>
        <.ops_section
          id="sync-reconcile-heading"
          title="Sync & queue posture"
          subtitle="The fast reconcile check answers whether Scrypath can see queue and backend posture for this schema."
          meta={if @reconcile_loaded_at, do: "last loaded #{format_dt(@reconcile_loaded_at)}"}
        >
          <:actions>
            <.ops_button phx-click="refresh_reconcile" variant={:primary}>
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
                <td><code class="text-xs">{@reconcile_result.index}</code></td>
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

          <p :if={@reconcile_result == nil && @selected_schema} class="text-sm text-base-content/70">
            Reconcile not loaded yet — choose a schema or tap “Refresh reconcile”.
          </p>
        </.ops_section>
      </.ops_panel>

      <.ops_panel>
        <.ops_section
          id="sync-drift-heading"
          title="Index contract (declared vs live)"
          subtitle="This check compares declared schema settings with the live Meilisearch index contract."
          meta={if @drift_loaded_at, do: "last loaded #{format_dt(@drift_loaded_at)}"}
        >
          <:actions>
            <.ops_button phx-click="load_drift">
              Load / refresh contract drift
            </.ops_button>
          </:actions>

          <.ops_status
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

          <.ops_signal_table :if={@drift_result}>
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
              <tr>
                <th scope="row" class="font-medium align-top">Dimension mismatches</th>
                <td class="font-mono text-xs tabular-nums">
                  {drift_mismatch_count(@drift_result)} of {map_size(@drift_result.dimensions)}
                </td>
              </tr>
            </tbody>
          </.ops_signal_table>
          <.ops_data_card :if={@drift_result} title="Contract dimensions" class="mt-3">
            <div class="grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
              <div
                :for={{label, match?} <- drift_dimension_rows(@drift_result)}
                class={[
                  "rounded-ops-md border px-3 py-2 text-ops-xs",
                  match? && "ops-tone-success",
                  not match? && "ops-tone-warning"
                ]}
              >
                <span class="font-semibold">{label}</span>
                <span class={["ml-2", match? && "text-success", not match? && "text-warning"]}>
                  {if match?, do: "matches", else: "differs"}
                </span>
              </div>
            </div>
          </.ops_data_card>
        </.ops_section>
      </.ops_panel>

      <.ops_panel :if={@selected_schema}>
        <.ops_section
          id="sync-advanced-recovery-heading"
          title="Advanced recovery"
          subtitle="Promotion is intentionally separate from read-only drift checks. Use it only after posture and failed-sync signals are quiet."
        >
          <.ops_verdict
            kind={promotion_readiness_kind(@reconcile_result, @drift_result)}
            label="Promotion readiness"
            headline={promotion_readiness_headline(@reconcile_result, @drift_result)}
            class="mb-3"
          >
            The preflight above is the source of truth: reconcile must be loaded and contract
            drift clean before the gated swap is safe.
          </.ops_verdict>
          <.ops_action_group tone={:advanced}>
            <p class="max-w-xl text-sm text-base-content/75">
              Swap the prepared target index into the live alias for <code>{module_flat_name(@selected_schema)}</code>. This runs the existing gated
              recovery path and refreshes loaded checks afterward.
            </p>
            <.ops_button phx-click="swap_live" phx-disable-with="Swapping...">
              Swap live index
            </.ops_button>
          </.ops_action_group>
        </.ops_section>
      </.ops_panel>

      <.ops_toolbar class="justify-end">
        <.ops_link_button navigate={"#{@mount_path}/posture"} variant={:ghost} size={:sm}>
          Re-check fleet posture <span aria-hidden="true">→</span>
        </.ops_link_button>
      </.ops_toolbar>
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
