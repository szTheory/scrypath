defmodule ScrypathOpsWeb.PostureLive do
  @moduledoc """
  Read-only fleet posture over `Scrypath.sync_status/2` for allowlisted schemas.

  Uses bounded `Task.async_stream/3` per refresh. **Manual refresh** is primary;
  optional auto-refresh is reserved (assign defaults to `false`; see README).
  """

  use ScrypathOpsWeb, :live_view

  alias ScrypathOps.OperatorSelection
  alias ScrypathOps.Posture
  alias ScrypathOpsWeb.Components.SearchHealth

  @impl true
  def mount(params, _session, socket) do
    fixture? = Map.get(socket.assigns, :live_action) == :phase173_fixture

    {allowlist, scrypath_opts, snapshot_at, scenario} =
      if fixture? do
        fixture = phase173_fixture(params)

        {
          fixture.allowlist,
          fixture.scrypath_opts,
          fixture.snapshot_at,
          fixture.scenario
        }
      else
        {
          ScrypathOps.Schemas.allowlist(),
          ScrypathOps.Schemas.scrypath_opts(),
          nil,
          nil
        }
      end

    socket =
      socket
      |> assign(:page_title, "Search health")
      |> assign(:schema_allowlist, allowlist)
      |> assign(:scrypath_opts, scrypath_opts)
      |> assign(:phase173_fixture?, fixture?)
      |> assign(:phase173_snapshot_at, snapshot_at)
      |> assign(:phase173_scenario, scenario)
      |> assign(:auto_refresh, false)
      |> assign(:posture_rows, [])
      |> assign(:aggregate_error_count, 0)
      |> assign(:last_refresh_at, nil)
      |> assign(:posture_state, :ok)
      |> assign(:posture_headline, "—")
      |> assign(:posture_evidence, "")

    {:ok, load_posture(socket)}
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    start_ms = System.monotonic_time(:millisecond)
    socket = socket |> fail_phase173_refresh() |> load_posture()
    duration_ms = System.monotonic_time(:millisecond) - start_ms
    summary = socket.assigns.posture_summary

    refresh_succeeded? =
      summary.state in [:ok, :degraded] and summary.schema_count > 0 and summary.error_count == 0

    # Low-cardinality telemetry: no per-schema labels (CONTEXT D-08).
    :telemetry.execute(
      [:scrypath_ops, :posture, :refresh],
      %{duration_ms: duration_ms, schema_count: length(socket.assigns.schema_allowlist)},
      %{outcome: if(refresh_succeeded?, do: :ok, else: :degraded)}
    )

    socket =
      if refresh_succeeded? do
        put_flash(socket, :info, "Search health refreshed.")
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event(
        "phase173_scenario",
        %{"scenario" => scenario},
        %{assigns: %{live_action: :phase173_fixture}} = socket
      ) do
    fixture = phase173_fixture(%{"scenario" => scenario})

    socket =
      socket
      |> assign(:schema_allowlist, fixture.allowlist)
      |> assign(:scrypath_opts, fixture.scrypath_opts)
      |> assign(:phase173_snapshot_at, fixture.snapshot_at)
      |> assign(:phase173_scenario, fixture.scenario)
      |> load_posture()

    {:noreply, socket}
  end

  def handle_event("swap_live", %{"schema" => mod_str}, socket) do
    case mod_from_allowlist(mod_str, socket.assigns.schema_allowlist) do
      {:ok, mod} ->
        {:noreply,
         push_navigate(socket,
           to: OperatorSelection.path(socket.assigns.mount_path, "sync-and-index", mod)
         )}

      :error ->
        {:noreply, put_flash(socket, :error, "Select an allowlisted schema.")}
    end
  end

  @impl true
  def handle_params(_params, uri, %{assigns: %{live_action: :legacy}} = socket) do
    query_suffix =
      case URI.parse(uri).query do
        nil -> ""
        query -> "?" <> query
      end

    mount_path =
      uri
      |> URI.parse()
      |> Map.fetch!(:path)
      |> String.replace_suffix("/posture", "")
      |> String.trim_trailing("/")

    {:noreply, push_navigate(socket, to: "#{mount_path}/health#{query_suffix}")}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  defp load_posture(socket) do
    summary = posture_summary(socket)

    socket
    |> assign(:posture_rows, posture_rows_assign(summary))
    |> assign(:aggregate_error_count, summary.error_count)
    |> assign(:last_refresh_at, summary.refreshed_at)
    |> assign(:posture_state, summary.state)
    |> assign(:posture_headline, summary.headline)
    |> assign(:posture_evidence, summary.evidence)
    |> assign(:posture_summary, summary)
  end

  defp posture_summary(%{assigns: %{phase173_fixture?: true}} = socket) do
    ScrypathOps.Posture.summary(
      socket.assigns.schema_allowlist,
      socket.assigns.scrypath_opts,
      socket.assigns.phase173_snapshot_at,
      Map.get(socket.assigns, :posture_summary)
    )
  end

  defp posture_summary(socket) do
    ScrypathOps.Posture.summary(
      socket.assigns.schema_allowlist,
      socket.assigns.scrypath_opts,
      ScrypathOps.Clock.utc_now(),
      Map.get(socket.assigns, :posture_summary)
    )
  end

  defp phase173_fixture(params) do
    :scrypath_ops
    |> Application.fetch_env!(:phase173_fixture_source)
    |> apply(:fixture, [params])
  end

  defp fail_phase173_refresh(
         %{
           assigns: %{phase173_fixture?: true, phase173_scenario: "refresh-failure"}
         } = socket
       ) do
    fixture_source = Application.fetch_env!(:scrypath_ops, :phase173_fixture_source)
    opts = apply(fixture_source, :fail_refresh, [socket.assigns.scrypath_opts])
    assign(socket, :scrypath_opts, opts)
  end

  defp fail_phase173_refresh(socket), do: socket

  # Map the shared summary back onto this view's legacy `posture_rows` assign,
  # which the per-schema table and empty-state guards still pattern-match on.
  #
  # Rows are ranked here, once, when they are loaded or refreshed (SKIN-07): failed, retrying,
  # pending, unverified, clear, then module name. Rendering never sorts, so a row does not jump
  # while an operator reads it; it moves only when a refresh brings new evidence.
  defp posture_rows_assign(%Posture{state: :unconfigured}), do: :empty_allowlist
  defp posture_rows_assign(%Posture{state: :missing_backend}), do: :missing_backend
  defp posture_rows_assign(%Posture{rows: rows}), do: {:ok, Posture.sort_by_urgency(rows)}

  defp posture_rows({:ok, rows}) when is_list(rows), do: rows
  defp posture_rows(_other), do: []

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
    <SearchHealth.screen
      mount_path={@mount_path}
      flash={@flash}
      shell={@shell}
      page_title={@page_title}
      summary={@posture_summary}
      rows={posture_rows(@posture_rows)}
      sync_mode={Keyword.get(@scrypath_opts, :sync_mode, :inline)}
      now={@last_refresh_at}
      refresh_disabled={@phase173_fixture? and @phase173_scenario == "refresh-disabled"}
      auto_refresh={@auto_refresh}
    >
      <:fixture_controls :if={@phase173_fixture?}>
        <form
          id="phase173-fixture-controls"
          phx-change="phase173_scenario"
          class="mb-ops-4 max-w-sm"
        >
          <label for="phase173-fixture-scenario" class="mb-ops-1 block text-ops-sm font-semibold">
            Fixture scenario
          </label>
          <select
            id="phase173-fixture-scenario"
            name="scenario"
            data-testid="phase173-fixture-scenario"
            class="select select-bordered w-full"
          >
            <option
              :for={
                scenario <- [
                  "healthy",
                  "failed",
                  "unavailable",
                  "unknown",
                  "empty",
                  "partial",
                  "long",
                  "invalid-time",
                  "queue-unused",
                  "refresh-failure",
                  "refresh-disabled",
                  "processing",
                  "backend-failed",
                  "retrying",
                  "completed",
                  "all-statuses"
                ]
              }
              value={scenario}
              selected={@phase173_scenario == scenario}
            >
              {String.capitalize(scenario)}
            </option>
          </select>
        </form>
      </:fixture_controls>
    </SearchHealth.screen>
    """
  end
end
