defmodule ScrypathOpsWeb.PostureLive do
  @moduledoc """
  Read-only fleet posture over `Scrypath.sync_status/2` for allowlisted schemas.

  Uses bounded `Task.async_stream/3` per refresh. **Manual refresh** is primary;
  optional auto-refresh is reserved (assign defaults to `false`; see README).
  """

  use ScrypathOpsWeb, :live_view

  alias ScrypathOps.OperatorSelection

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
      |> assign(:next_checks, [])

    {:ok, load_posture(socket)}
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    start_ms = System.monotonic_time(:millisecond)
    socket = socket |> fail_phase173_refresh() |> load_posture()
    duration_ms = System.monotonic_time(:millisecond) - start_ms

    # Low-cardinality telemetry: no per-schema labels (CONTEXT D-08).
    :telemetry.execute(
      [:scrypath_ops, :posture, :refresh],
      %{duration_ms: duration_ms, schema_count: length(socket.assigns.schema_allowlist)},
      %{outcome: if(socket.assigns.aggregate_error_count > 0, do: :degraded, else: :ok)}
    )

    socket =
      if socket.assigns.aggregate_error_count > 0 do
        socket
      else
        put_flash(socket, :info, "Search health refreshed.")
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
           to: OperatorSelection.path(socket.assigns.mount_path, "sync-drift", mod)
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
    {:noreply, refresh_next_checks(socket)}
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
    |> refresh_next_checks()
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
      DateTime.utc_now(),
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

  defp refresh_next_checks(%{assigns: %{posture_summary: summary}} = socket)
       when is_struct(summary, ScrypathOps.Posture) do
    assign(
      socket,
      :next_checks,
      summary |> ScrypathOps.Posture.next_checks(socket.assigns.mount_path) |> Enum.take(5)
    )
  end

  defp refresh_next_checks(socket), do: socket

  # Map the shared summary back onto this view's legacy `posture_rows` assign,
  # which the per-schema table and empty-state guards still pattern-match on.
  defp posture_rows_assign(%ScrypathOps.Posture{state: :unconfigured}), do: :empty_allowlist
  defp posture_rows_assign(%ScrypathOps.Posture{state: :missing_backend}), do: :missing_backend
  defp posture_rows_assign(%ScrypathOps.Posture{rows: rows}), do: {:ok, rows}

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
          title="Search health"
          subtitle="Check sync and backend health for every configured schema. Start here when something looks wrong."
        />
        <.ops_refresh_control
          id="search-health-refresh"
          checked_at={@last_refresh_at}
          disabled={@phase173_fixture? and @phase173_scenario == "refresh-disabled"}
          phx-click="refresh"
          aria_label="Refresh search health"
        />
      </.ops_toolbar>

      <.ops_trail current={:posture} />

      <form
        :if={@phase173_fixture?}
        id="phase173-fixture-controls"
        phx-change="phase173_scenario"
        class="mb-4 max-w-sm"
      >
        <label for="phase173-fixture-scenario" class="mb-1 block text-ops-sm font-medium">
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
                "refresh-disabled"
              ]
            }
            value={scenario}
            selected={@phase173_scenario == scenario}
          >
            {String.capitalize(scenario)}
          </option>
        </select>
      </form>

      <section
        :if={match?({:ok, _}, @posture_rows)}
        aria-labelledby="posture-summary-heading"
        class="space-y-4"
      >
        <h2 id="posture-summary-heading" class="sr-only">Search health summary</h2>
        <.ops_verdict
          kind={ScrypathOps.Posture.badge_kind(@posture_state)}
          label="Can I trust search right now?"
          headline={@posture_headline}
        >
          {@posture_evidence}
        </.ops_verdict>
        <.ops_metric_grid cols={4}>
          <.ops_metric
            label="Schemas"
            value={posture_schema_count(@posture_rows)}
            kind={:neutral}
          />
          <.ops_metric
            label="Schema check errors"
            value={@aggregate_error_count}
            kind={ScrypathOps.Posture.metric_tone(@aggregate_error_count)}
          />
          <.ops_metric
            label="Failed backend tasks"
            value={posture_backend_failed_count(@posture_rows)}
            kind={ScrypathOps.Posture.metric_tone(posture_backend_failed_count(@posture_rows))}
          />
          <.ops_metric
            label="Queues observed"
            value={posture_queue_observed_count(@posture_rows)}
            kind={:neutral}
          />
        </.ops_metric_grid>
      </section>

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
                <.link navigate={check.navigate} class="link link-primary">Open this check</.link>
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
          subtitle="Schemas with the most issues appear first. Review backend tasks, queue status, and each schema's last successful sync."
        >
          <div class="ops-schema-signal-list">
            <%= for {mod, row} <- posture_rows_worst_first(elem(@posture_rows, 1)) do %>
              <article
                data-testid="posture-row"
                id={"posture-#{inspect(mod)}"}
                class="ops-schema-signal-card"
              >
                <%= case row do %>
                  <% {:ok, status} -> %>
                    <div class="ops-schema-signal-card__header">
                      <div class="min-w-0">
                        <h3 class="font-mono text-ops-h3 font-semibold text-base-content">
                          {inspect(mod)}
                        </h3>
                        <p class="mt-1 text-ops-sm text-base-content/65">
                          Index
                          <.ops_inline_code>{status.index}</.ops_inline_code>
                          · sync mode <strong>{status.mode}</strong>
                        </p>
                      </div>
                      <div class="ops-schema-signal-card__badges">
                        <.ops_badge kind={backend_badge_kind(status)}>
                          {backend_badge_label(status)}
                        </.ops_badge>
                        <.ops_badge kind={queue_badge_kind(status)}>
                          {queue_badge_label(status)}
                        </.ops_badge>
                      </div>
                    </div>

                    <div class="ops-schema-signal-card__groups">
                      <section
                        aria-label={"Backend task signals for #{inspect(mod)}"}
                        class="ops-signal-group"
                      >
                        <p class="ops-signal-group__title">Backend tasks</p>
                        <dl class="ops-signal-metrics">
                          <div>
                            <dt>Pending</dt>
                            <dd>{length(status.backend.pending)}</dd>
                          </div>
                          <div>
                            <dt>Failed</dt>
                            <dd>{length(status.backend.failed)}</dd>
                          </div>
                          <div class="ops-signal-metrics__wide">
                            <dt>Last success</dt>
                            <dd>
                              <.ops_time
                                dt={state_at(status.backend.last_succeeded)}
                                source_iso={state_source_iso(status.backend.last_succeeded)}
                                snapshot_at={source_ref(@posture_summary, mod, :backend)[:checked_at]}
                                state_text={time_state_text(status.backend.last_succeeded)}
                                operational
                              />
                            </dd>
                          </div>
                        </dl>
                      </section>

                      <section
                        aria-label={"Queue job signals for #{inspect(mod)}"}
                        class="ops-signal-group"
                      >
                        <p class="ops-signal-group__title">Queue jobs</p>
                        <dl :if={status.queue.observed?} class="ops-signal-metrics">
                          <div>
                            <dt>Pending</dt>
                            <dd>{length(status.queue.pending)}</dd>
                          </div>
                          <div>
                            <dt>Retrying</dt>
                            <dd>{length(status.queue.retrying)}</dd>
                          </div>
                          <div>
                            <dt>Failed</dt>
                            <dd>{length(status.queue.failed)}</dd>
                          </div>
                          <div class="ops-signal-metrics__wide">
                            <dt>Last success</dt>
                            <dd>
                              <.ops_time
                                dt={state_at(status.queue.last_succeeded)}
                                source_iso={state_source_iso(status.queue.last_succeeded)}
                                snapshot_at={source_ref(@posture_summary, mod, :queue)[:checked_at]}
                                state_text={queue_time_state_text(status)}
                                operational
                              />
                            </dd>
                          </div>
                        </dl>
                        <p :if={!status.queue.observed?} class="text-ops-sm text-base-content/75">
                          {queue_unobserved_copy(status)}
                        </p>
                      </section>
                    </div>
                    <.link
                      navigate={OperatorSelection.path(@mount_path, "failed-sync", mod)}
                      class="link link-primary mt-3 inline-flex min-h-[var(--control-h-md)] items-center"
                      data-testid="posture-failed-sync-link"
                    >
                      Inspect failed work for {module_flat_name(mod)}
                    </.link>
                  <% {:error, reason} -> %>
                    <div class="ops-schema-signal-card__header">
                      <div class="min-w-0">
                        <h3 class="font-mono text-ops-h3 font-semibold text-base-content">
                          {inspect(mod)}
                        </h3>
                        <p class="mt-1 text-ops-sm text-error">fetch error: {inspect(reason)}</p>
                      </div>
                      <div class="ops-schema-signal-card__badges">
                        <.ops_badge kind={:error}>fetch error</.ops_badge>
                      </div>
                    </div>
                    <p class="mt-3 text-ops-sm text-error">
                      Search health could not be checked: {inspect(reason)}. Refresh to try again.
                    </p>
                    <dl class="ops-signal-metrics ops-signal-metrics--retained mt-3">
                      <div :for={source <- [:backend, :queue]}>
                        <dt>{source_last_success_label(source)}</dt>
                        <dd>
                          <.ops_time
                            dt={retained_state_at(@posture_summary, mod, source)}
                            source_iso={retained_source_iso(@posture_summary, mod, source)}
                            snapshot_at={retained_snapshot_at(@posture_summary, mod, source)}
                            state_text={retained_state_text(@posture_summary, mod, source, reason)}
                            retained_text={retained_evidence_text(@posture_summary, mod, source)}
                            operational
                          />
                        </dd>
                      </div>
                    </dl>
                    <.link
                      navigate={OperatorSelection.path(@mount_path, "failed-sync", mod)}
                      class="link link-primary mt-3 inline-flex min-h-[var(--control-h-md)] items-center"
                      data-testid="posture-failed-sync-link"
                    >
                      Inspect failed work for {module_flat_name(mod)}
                    </.link>
                <% end %>
              </article>
            <% end %>
          </div>
        </.ops_section>
      </.ops_panel>

      <.ops_handoff :if={match?({:ok, _}, @posture_rows)}>
        <:step
          navigate={"#{@mount_path}/failed-sync"}
          hint="When you've spotted a failing schema —"
        >
          Work the failed-sync queue
        </:step>
      </.ops_handoff>
    </Layouts.app>
    """
  end

  # Default-sort the per-schema table worst-first so a red/degraded schema lands at the
  # top of the scan path (B1). Rank: fetch error (0) → backend failures (1) → queue not
  # observed or queue failures (2) → clean (3); ties break alphabetically by module name.
  defp posture_rows_worst_first(rows) when is_list(rows) do
    Enum.sort_by(rows, fn {mod, row} -> {posture_row_rank(row), inspect(mod)} end)
  end

  defp posture_rows_worst_first(rows), do: rows

  defp posture_row_rank({:error, _reason}), do: 0

  defp posture_row_rank({:ok, status}) do
    cond do
      length(status.backend.failed) > 0 -> 1
      not status.queue.observed? -> 2
      length(status.queue.failed) > 0 -> 2
      length(status.queue.retrying) > 0 -> 2
      true -> 3
    end
  end

  defp posture_row_rank(_), do: 3

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

  defp state_at(%Scrypath.Operator.State{at: at}), do: at
  defp state_at(_state), do: nil

  defp state_source_iso(%Scrypath.Operator.State{metadata: metadata}),
    do: Map.get(metadata, :source_iso)

  defp state_source_iso(_state), do: nil

  defp time_state_text(nil), do: "No success observed"
  defp time_state_text(%Scrypath.Operator.State{at: nil}), do: "Success time not observed"
  defp time_state_text(%Scrypath.Operator.State{}), do: ""

  defp queue_time_state_text(%{queue: %{observed?: false}}), do: "Queue not used"
  defp queue_time_state_text(%{queue: %{last_succeeded: state}}), do: time_state_text(state)

  defp source_last_success_label(:backend), do: "Backend last success"
  defp source_last_success_label(:queue), do: "Queue last success"

  defp source_ref(%ScrypathOps.Posture{last_success_refs: refs}, schema, source) do
    refs
    |> Map.get(schema, %{})
    |> Map.get(source)
  end

  defp source_ref(_summary, _schema, _source), do: nil

  defp retained_state_at(summary, schema, source) do
    case source_ref(summary, schema, source) do
      %{state: %Scrypath.Operator.State{at: at}} -> at
      _other -> nil
    end
  end

  defp retained_source_iso(summary, schema, source) do
    case source_ref(summary, schema, source) do
      %{state: state} -> state_source_iso(state)
      _other -> nil
    end
  end

  defp retained_snapshot_at(summary, schema, source) do
    case source_ref(summary, schema, source) do
      %{checked_at: checked_at} -> checked_at
      _other -> nil
    end
  end

  defp retained_state_text(summary, schema, source, reason) do
    case source_ref(summary, schema, source) do
      %{unused?: true} -> "Queue not used"
      %{state: state} -> time_state_text(state)
      nil -> "Not observed: #{inspect(reason)}"
    end
  end

  defp retained_evidence_text(summary, schema, source) do
    case source_ref(summary, schema, source) do
      %{unused?: true} ->
        "Queue not used."

      %{checked_at: %DateTime{} = checked_at} ->
        checked_iso = checked_at |> DateTime.shift_zone!("Etc/UTC") |> DateTime.to_iso8601()

        "Current observation is unavailable; this source-local evidence is retained from check #{checked_iso}."

      _other ->
        nil
    end
  end

  defp backend_badge_kind(status) do
    if length(status.backend.failed) > 0, do: :error, else: :success
  end

  defp backend_badge_label(status) do
    if length(status.backend.failed) > 0, do: "backend failed", else: "backend clear"
  end

  defp queue_badge_kind(status) do
    cond do
      not status.queue.observed? and queue_unused_mode?(status.mode) -> :neutral
      not status.queue.observed? -> :warning
      length(status.queue.failed) > 0 -> :error
      length(status.queue.retrying) > 0 -> :warning
      true -> :success
    end
  end

  defp queue_badge_label(status) do
    cond do
      not status.queue.observed? and queue_unused_mode?(status.mode) -> "Queue not used"
      not status.queue.observed? -> "Queue observations unavailable"
      length(status.queue.failed) > 0 -> "queue failed"
      length(status.queue.retrying) > 0 -> "queue retrying"
      true -> "queue observed"
    end
  end

  defp queue_unused_mode?(mode), do: mode in [:inline, :manual, "inline", "manual"]

  defp queue_unobserved_copy(status) do
    if queue_unused_mode?(status.mode) do
      "Queue not used in #{status.mode} sync mode."
    else
      "Queue observations unavailable; no queue counts are reported as zero."
    end
  end
end
