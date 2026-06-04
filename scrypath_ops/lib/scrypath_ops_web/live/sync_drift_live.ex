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
      |> assign(:drift_loading, false)

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
    # Two-step so the loading skeleton paints before the bounded backend read runs.
    # The contract-drift call is fast but synchronous; deferring it to handle_info/2
    # lets LiveView push the `:drift_loading` frame first. Event name unchanged.
    send(self(), :run_drift)
    {:noreply, assign(socket, :drift_loading, true)}
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
          |> assign(:drift_loading, false)
          |> load_reconcile_on_mount()

        {:noreply, socket}

      :error ->
        {:noreply, put_flash(socket, :error, "Select an allowlisted schema.")}
    end
  end

  def handle_event("swap_live", _params, socket) do
    {:noreply, swap_live(socket)}
  end

  @impl true
  def handle_info(:run_drift, socket) do
    {:noreply, refresh_drift(socket)}
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
        subtitle="Check one schema before you promote it: reconcile, compare drift, then swap."
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
          subtitle="The fast reconcile check answers whether Scrypath can see queue and backend posture for this schema."
          meta={if @reconcile_loaded_at, do: "last loaded #{format_dt(@reconcile_loaded_at)}"}
        >
          <:actions>
            <.ops_button phx-click="refresh_reconcile" variant={:primary} data-ops-refresh>
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
                <td><.ops_inline_code>{@reconcile_result.index}</.ops_inline_code></td>
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
          subtitle="This check compares declared schema settings with the live Meilisearch index contract."
          meta={if @drift_loaded_at, do: "last loaded #{format_dt(@drift_loaded_at)}"}
        >
          <:actions>
            <.ops_button phx-click="load_drift" phx-disable-with="Loading…" disabled={@drift_loading}>
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
          <.ops_data_card :if={@drift_result && !@drift_loading} title="Contract dimensions" class="mt-3">
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
            <p class="max-w-xl text-ops-body text-base-content/75">
              Swap the prepared target index into the live alias for <.ops_inline_code>{module_flat_name(@selected_schema)}</.ops_inline_code>. This runs the existing gated
              recovery path and refreshes loaded checks afterward.
            </p>
            <.ops_button phx-click="swap_live" phx-disable-with="Swapping...">
              Swap live index
            </.ops_button>
          </.ops_action_group>
        </.ops_section>
      </.ops_panel>

      <.ops_handoff>
        <:step navigate={"#{@mount_path}/posture"} hint="After promoting —">
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
