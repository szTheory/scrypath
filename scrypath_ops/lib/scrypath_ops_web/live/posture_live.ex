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
    allowlist = ScrypathOps.Schemas.allowlist()
    scrypath_opts = ScrypathOps.Schemas.scrypath_opts()
    fixture_action = socket.assigns.live_action
    fixture_source = fixture_source_for(fixture_action)

    {allowlist, scrypath_opts, observed_at, fixture_scenario, refresh_disabled?} =
      if fixture_action in [:phase173, :phase174] and fixture_source?(fixture_source) do
        scenario = Map.get(params, "scenario", default_scenario(fixture_action))
        fixture = fixture_source.scenario(scenario)

        {fixture.allowlist, fixture.opts, fixture.observed_at, scenario,
         Map.get(fixture, :refresh_disabled?, false)}
      else
        {allowlist, scrypath_opts, nil, nil, false}
      end

    socket =
      socket
      |> assign(:page_title, "Search health")
      |> assign(:schema_allowlist, allowlist)
      |> assign(:scrypath_opts, scrypath_opts)
      |> assign(:selected_schema, nil)
      |> assign(:selection_error, nil)
      |> assign(:auto_refresh, false)
      |> assign(:posture_rows, [])
      |> assign(:aggregate_error_count, 0)
      |> assign(:last_refresh_at, nil)
      |> assign(:posture_state, :ok)
      |> assign(:posture_headline, "—")
      |> assign(:posture_evidence, "")
      |> assign(:next_checks, [])
      |> assign(:phase173_observed_at, observed_at)
      |> assign(:phase173_fixture_scenario, fixture_scenario)
      |> assign(:phase173_refresh_disabled?, refresh_disabled?)

    {:ok, load_posture(socket)}
  end

  @impl true
  def handle_event("refresh", params, socket) do
    start_ms = System.monotonic_time(:millisecond)
    socket = maybe_select_fixture_scenario(socket, params)
    socket = load_posture(socket)
    duration_ms = System.monotonic_time(:millisecond) - start_ms

    # Low-cardinality telemetry: no per-schema labels (CONTEXT D-08).
    :telemetry.execute(
      [:scrypath_ops, :posture, :refresh],
      %{duration_ms: duration_ms, schema_count: length(socket.assigns.schema_allowlist)},
      %{outcome: if(socket.assigns.aggregate_error_count > 0, do: :degraded, else: :ok)}
    )

    {:noreply, put_flash(socket, :info, "Search health refreshed.")}
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

  def handle_params(params, _uri, socket) do
    allowlist =
      if socket.assigns.live_action == :phase174,
        do: socket.assigns.schema_allowlist,
        else: ScrypathOps.Schemas.allowlist()

    resolution = OperatorSelection.resolve(params, allowlist)

    {selected_schema, selection_error} =
      case resolution do
        {:ok, schema} -> {schema, nil}
        :setup -> {nil, :no_schemas}
        :unavailable -> {nil, :unavailable}
      end

    socket =
      socket
      |> assign(:schema_allowlist, allowlist)
      |> assign(:selected_schema, selected_schema)
      |> assign(:selection_error, selection_error)
      |> refresh_next_checks()

    {:noreply, socket}
  end

  defp load_posture(socket) do
    summary =
      case socket.assigns.phase173_observed_at do
        %DateTime{} = observed_at ->
          ScrypathOps.Posture.summary(
            socket.assigns.schema_allowlist,
            socket.assigns.scrypath_opts,
            observed_at,
            Map.get(socket.assigns, :posture_summary)
          )

        nil ->
          ScrypathOps.Posture.summary(
            socket.assigns.schema_allowlist,
            socket.assigns.scrypath_opts,
            DateTime.utc_now(),
            Map.get(socket.assigns, :posture_summary)
          )
      end

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

  defp maybe_select_fixture_scenario(
         %{assigns: %{live_action: :phase173}} = socket,
         %{"scenario" => scenario}
       ) do
    source = Application.get_env(:scrypath_ops, :phase173_fixture_source)

    if fixture_source?(source) do
      fixture = source.scenario(scenario)

      socket
      |> assign(:schema_allowlist, fixture.allowlist)
      |> assign(:scrypath_opts, fixture.opts)
      |> assign(:phase173_observed_at, fixture.observed_at)
      |> assign(:phase173_fixture_scenario, scenario)
      |> assign(:phase173_refresh_disabled?, Map.get(fixture, :refresh_disabled?, false))
    else
      socket
    end
  end

  defp maybe_select_fixture_scenario(
         %{assigns: %{live_action: :phase174}} = socket,
         %{"scenario" => scenario}
       ) do
    source = fixture_source_for(:phase174)

    if fixture_source?(source) do
      fixture = source.scenario(scenario)

      socket
      |> assign(:schema_allowlist, fixture.allowlist)
      |> assign(:scrypath_opts, fixture.opts)
      |> assign(:phase173_observed_at, fixture.observed_at)
      |> assign(:phase173_fixture_scenario, scenario)
    else
      socket
    end
  end

  defp maybe_select_fixture_scenario(socket, _params), do: socket

  defp fixture_source_for(:phase173),
    do: Application.get_env(:scrypath_ops, :phase173_fixture_source)

  defp fixture_source_for(:phase174) do
    if Mix.env() == :test,
      do: Application.get_env(:scrypath_ops, :phase174_fixture_source),
      else: nil
  end

  defp fixture_source_for(_action), do: nil

  defp default_scenario(:phase174), do: "a-selected-b-worse"
  defp default_scenario(_action), do: "default"

  defp fixture_source?(source) when is_atom(source) do
    Code.ensure_loaded?(source) and function_exported?(source, :scenario, 1)
  end

  defp fixture_source?(_source), do: false

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

  defp module_heading(mod) do
    mod
    |> inspect()
    |> String.split(".")
    |> Enum.intersperse([".", Phoenix.HTML.raw("<wbr>")])
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
      recovery_target={@recovery_target}
    >
      <.ops_toolbar class="items-end gap-4">
        <.ops_page_header
          title="Search health"
          subtitle="Check sync and backend health for every configured schema. Start here when something looks wrong."
        />
        <.ops_refresh_control
          id="search-health-refresh"
          checked_at={@last_refresh_at}
          phx-click="refresh"
          phx-value-scenario={@phase173_fixture_scenario}
          disabled={@phase173_refresh_disabled?}
          aria_label="Refresh search health"
        />
        <p :if={@phase173_refresh_disabled?} class="ops-text-meta" role="status">
          Refresh is disabled by the phase 173 eligibility fixture.
        </p>
      </.ops_toolbar>

      <.ops_trail current={:posture} />

      <.ops_status
        :if={@selected_schema}
        kind={:info}
        title="Recovery target"
        data-testid="recovery-target"
      >
        {OperatorSelection.canonical(@selected_schema)}
      </.ops_status>
      <.ops_status
        :if={@selection_error == :unavailable}
        kind={:error}
        title="That schema is unavailable"
        role="alert"
      >
        Select an allowlisted schema to continue.
      </.ops_status>

      <div class="grid gap-ops-section">
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
              kind={metric_tone(@aggregate_error_count)}
            />
            <.ops_metric
              label="Failed backend tasks"
              value={posture_backend_failed_count(@posture_rows)}
              kind={metric_tone(posture_backend_failed_count(@posture_rows))}
            />
            <.ops_metric
              label="Queues observed"
              value={posture_queue_observed_count(@posture_rows)}
              kind={:neutral}
            />
          </.ops_metric_grid>
        </section>

        <section
          :if={@next_checks != []}
          data-testid="posture-next-checks"
          aria-labelledby="posture-jtbd-heading"
          class="space-y-3"
        >
          <.ops_heading level={2} id="posture-jtbd-heading">Next checks</.ops_heading>
          <ul class="ops-next-checks">
            <li :for={{check, index} <- Enum.with_index(@next_checks)} class="ops-next-checks__item">
              <.ops_link_button
                :if={check[:navigate] || check[:href]}
                navigate={check[:navigate]}
                href={check[:href]}
                variant={:ghost}
                class="justify-self-start gap-2 text-base-content"
                aria-describedby={"posture-next-check-#{index}"}
              >
                {check.label}
                <.icon
                  name={if(check[:href], do: "hero-arrow-up-right", else: "hero-arrow-right")}
                  class="size-4"
                />
              </.ops_link_button>
              <p
                id={"posture-next-check-#{index}"}
                class={[
                  "text-ops-body text-base-content/75",
                  is_nil(check[:navigate]) && is_nil(check[:href]) && "col-span-full"
                ]}
              >
                {check.text}
                <code :if={check[:mix]} class="mt-1 block font-mono text-ops-sm">{check.mix}</code>
              </p>
            </li>
          </ul>
        </section>

        <p :if={@auto_refresh} class="mt-2 text-ops-body text-base-content/70">
          Auto-refresh is not enabled by default; only manual refresh runs in this build.
        </p>

        <.ops_config_empty :if={@posture_rows == :empty_allowlist} kind={:no_schemas} class="mt-4" />
        <.ops_config_empty
          :if={@posture_rows == :missing_backend}
          kind={:missing_backend}
          class="mt-4"
        />

        <.ops_section
          :if={match?({:ok, _}, @posture_rows)}
          id="posture-fleet-heading"
          title="Per-schema signals"
          subtitle="Schemas with the most issues appear first. Review backend tasks, queue status, and each schema's last successful sync."
        >
          <div class="ops-schema-signal-list">
            <article
              :for={{mod, row} <- posture_rows_worst_first(elem(@posture_rows, 1))}
              :key={mod}
              data-testid="posture-row"
              id={"posture-#{inspect(mod)}"}
              class={[
                "ops-schema-signal-card",
                posture_card_tone(row)
              ]}
            >
              <%= case row do %>
                <% {:ok, status} -> %>
                  <div class="ops-schema-signal-card__header">
                    <div class="min-w-0">
                      <h3 class="font-mono text-ops-h3 font-semibold text-base-content">
                        {module_heading(mod)}
                      </h3>
                      <p class="mt-1 text-ops-sm text-base-content/65">
                        Index
                        <.ops_inline_code>{status.index}</.ops_inline_code>
                        · sync mode <strong>{status.mode}</strong>
                      </p>
                    </div>
                  </div>

                  <div class="ops-schema-signal-card__groups">
                    <section
                      aria-label={"Backend task signals for #{inspect(mod)}"}
                      class="ops-signal-group"
                    >
                      <p class="ops-signal-group__title">Backend tasks</p>
                      <dl :if={!source_error?(status, :backend)} class="ops-signal-metrics">
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
                              id={"ops-time-#{module_flat_name(mod)}-backend-success"}
                              dt={status.backend.last_succeeded && status.backend.last_succeeded.at}
                              source_iso={state_source_iso(status.backend.last_succeeded)}
                              copy={true}
                              reference={success_reference(@posture_summary, mod, :backend)}
                              empty={success_time_empty(status.backend.last_succeeded)}
                            />
                          </dd>
                        </div>
                      </dl>
                      <.unavailable_signal
                        :if={source_error?(status, :backend)}
                        status={status}
                        source={:backend}
                        mod={mod}
                        summary={@posture_summary}
                      />
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
                              id={"ops-time-#{module_flat_name(mod)}-queue-success"}
                              dt={status.queue.last_succeeded && status.queue.last_succeeded.at}
                              source_iso={state_source_iso(status.queue.last_succeeded)}
                              copy={true}
                              reference={success_reference(@posture_summary, mod, :queue)}
                              empty={success_time_empty(status.queue.last_succeeded)}
                            />
                          </dd>
                        </div>
                      </dl>
                      <.unavailable_signal
                        :if={source_error?(status, :queue)}
                        status={status}
                        source={:queue}
                        mod={mod}
                        summary={@posture_summary}
                      />
                      <p
                        :if={!status.queue.observed? and !source_error?(status, :queue)}
                        class="text-ops-sm text-base-content/75"
                      >
                        {queue_unobserved_copy(status)}
                      </p>
                    </section>
                  </div>
                  <.ops_link_button
                    :if={is_nil(@selection_error)}
                    navigate={OperatorSelection.path(@mount_path, "failed-sync", mod)}
                    variant={:ghost}
                    class="justify-self-start gap-2 text-base-content"
                    aria-label={"View failed sync work for #{module_flat_name(mod)}"}
                    id={"posture-failed-sync-link-#{module_flat_name(mod)}"}
                    data-testid="posture-failed-sync-link"
                  >
                    View failed sync work <.icon name="hero-arrow-right" class="size-4" />
                  </.ops_link_button>
                <% {:error, reason} -> %>
                  <div class="ops-schema-signal-card__header">
                    <div class="min-w-0">
                      <h3 class="font-mono text-ops-h3 font-semibold text-base-content">
                        {module_heading(mod)}
                      </h3>
                      <p class="mt-1 text-ops-sm text-error">fetch error: {inspect(reason)}</p>
                    </div>
                  </div>
                  <div class="ops-schema-signal-card__groups">
                    <section
                      :for={source <- [:backend, :queue]}
                      aria-label={"#{if(source == :backend, do: "Backend task", else: "Queue job")} signals for #{inspect(mod)}"}
                      class="ops-signal-group"
                    >
                      <p class="ops-signal-group__title">
                        {if(source == :backend, do: "Backend tasks", else: "Queue jobs")}
                      </p>
                      <.unavailable_signal
                        :if={source == :backend or !queue_unused_mode?(queue_mode(@scrypath_opts))}
                        status={%{source_errors: %{source => reason}}}
                        source={source}
                        mod={mod}
                        summary={@posture_summary}
                      />
                      <p
                        :if={source == :queue and queue_unused_mode?(queue_mode(@scrypath_opts))}
                        class="text-ops-sm text-base-content/75"
                      >
                        Queue not used in {queue_mode(@scrypath_opts)} sync mode.
                      </p>
                    </section>
                  </div>
                  <.ops_link_button
                    :if={is_nil(@selection_error)}
                    navigate={OperatorSelection.path(@mount_path, "failed-sync", mod)}
                    variant={:ghost}
                    class="justify-self-start gap-2 text-base-content"
                    aria-label={"View failed sync work for #{module_flat_name(mod)}"}
                    id={"posture-failed-sync-link-#{module_flat_name(mod)}"}
                    data-testid="posture-failed-sync-link"
                  >
                    View failed sync work <.icon name="hero-arrow-right" class="size-4" />
                  </.ops_link_button>
              <% end %>
            </article>
          </div>
        </.ops_section>

        <.ops_handoff :if={match?({:ok, _}, @posture_rows) && @selection_error == nil}>
          <:step
            navigate={OperatorSelection.path(@mount_path, "failed-sync", @selected_schema)}
            hint="When you've spotted a failing schema —"
          >
            Work the failed-sync queue
          </:step>
        </.ops_handoff>
      </div>
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

  defp state_source_iso(%Scrypath.Operator.State{metadata: metadata}),
    do: Map.get(metadata, :source_iso)

  defp state_source_iso(_state), do: nil

  defp success_time_empty(%Scrypath.Operator.State{state: :completed, at: nil}),
    do: "Success time not observed"

  defp success_time_empty(_state), do: "No success observed"

  defp retained_time(%Scrypath.Operator.State{at: at}), do: at
  defp retained_time(_state), do: nil

  defp success_reference(summary, schema, source),
    do: ScrypathOps.Posture.last_success_ref(summary, schema, source)

  defp metric_tone(0), do: :neutral
  defp metric_tone(_), do: :warning

  defp posture_card_tone({:error, _reason}), do: "ops-schema-signal-card--error"

  defp posture_card_tone({:ok, status}) do
    cond do
      length(status.backend.failed) > 0 -> "ops-schema-signal-card--warning"
      length(status.queue.failed) > 0 -> "ops-schema-signal-card--warning"
      length(status.queue.retrying) > 0 -> "ops-schema-signal-card--warning"
      not status.queue.observed? -> "ops-schema-signal-card--warning"
      true -> "ops-schema-signal-card--success"
    end
  end

  defp posture_card_tone(_), do: nil

  defp source_error?(status, source),
    do: Map.has_key?(Map.get(status, :source_errors, %{}), source)

  defp unavailable_signal(assigns) do
    assigns =
      assigns
      |> assign(
        :reference,
        ScrypathOps.Posture.last_success_ref(assigns.summary, assigns.mod, assigns.source)
      )
      |> assign(:reason, Map.get(assigns.status.source_errors, assigns.source))
      |> assign(:source_label, if(assigns.source == :backend, do: "Backend", else: "Queue"))

    ~H"""
    <p class="text-ops-body text-base-content">
      {@source_label} observation unavailable;
      <span :if={@reference && @reference.state}>last success retained from the previous check.</span>
      fetch error: {inspect(@reason)}
    </p>
    <.ops_time
      id={"ops-time-#{module_flat_name(@mod)}-retained-#{@source}-success"}
      dt={retained_time(@reference && @reference.state)}
      source_iso={state_source_iso(@reference && @reference.state)}
      copy={true}
      reference={@reference}
      label="Last success retained"
      empty="Not observed"
      unavailable_reason={inspect(@reason)}
    />
    """
  end

  defp queue_mode(opts) do
    opts |> Scrypath.Config.resolve!() |> Keyword.fetch!(:sync_mode)
  rescue
    ArgumentError -> :unknown
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
