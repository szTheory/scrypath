defmodule ScrypathOpsWeb.ControlRoomLive do
  @moduledoc """
  Intent-first landing for `/ops`.

  Shows a glanceable search-health summary and routes the operator to the surface that
  matches the job they brought: incident triage, change verification, or exploration.
  The deep per-schema health table lives on `ScrypathOpsWeb.PostureLive` — this page
  is the overview, not a duplicate of it.
  """

  use ScrypathOpsWeb, :live_view

  alias ScrypathOps.Posture
  alias ScrypathOps.OperatorSelection

  @orientation_href "https://github.com/szTheory/scrypath/blob/main/scrypath_ops/docs/operator-ia.md"

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Control Room")
      |> assign(:orientation_href, @orientation_href)
      |> assign(:schema_allowlist, ScrypathOps.Schemas.allowlist())
      |> assign(:selected_schema, nil)
      |> assign(:selection_error, nil)
      |> assign(:scrypath_opts, ScrypathOps.Schemas.scrypath_opts())
      |> load_summary()

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    allowlist = ScrypathOps.Schemas.allowlist()
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
      |> load_summary()

    {:noreply, socket}
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    socket =
      socket
      |> load_summary()
      |> put_flash(:info, "Search health refreshed.")

    {:noreply, socket}
  end

  defp load_summary(socket) do
    previous = Map.get(socket.assigns, :posture)
    scrypath_opts = ScrypathOps.Schemas.scrypath_opts()

    summary =
      Posture.summary(
        socket.assigns.schema_allowlist,
        scrypath_opts,
        DateTime.utc_now(),
        previous
      )

    socket
    |> assign(:scrypath_opts, scrypath_opts)
    |> assign(:posture, summary)
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
      recovery_target={@selected_schema}
    >
      <div class="space-y-ops-page-gap">
        <.ops_toolbar class="items-end gap-4">
          <.ops_page_header
            title="Control Room"
            subtitle="Recover search, verify a change before promotion, or inspect and save a useful search check."
          />
          <.ops_refresh_control
            id="control-room-refresh"
            checked_at={@posture.refreshed_at}
            phx-click="refresh"
            aria_label="Refresh search health"
          />
        </.ops_toolbar>

        <section aria-labelledby="control-room-health-heading" class="space-y-4">
          <h2 id="control-room-health-heading" class="sr-only">Search health</h2>

          <.ops_status
            :if={@selection_error == :unavailable}
            kind={:error}
            title="That schema is unavailable"
            role="alert"
          >
            Select an allowlisted schema to continue.
          </.ops_status>

          <.ops_config_empty :if={@posture.state == :unconfigured} kind={:no_schemas} />
          <.ops_config_empty :if={@posture.state == :missing_backend} kind={:missing_backend} />

          <.ops_verdict
            :if={@posture.state in [:ok, :degraded]}
            kind={Posture.badge_kind(@posture.state)}
            label="Can I trust search right now?"
            headline={@posture.headline}
            class="ops-verdict--hero"
          >
            <:actions>
              <.ops_link_button
                :if={is_nil(@selection_error)}
                id="control-room-health-link"
                data-testid="control-room-health-link"
                navigate={health_path(@mount_path, @selected_schema)}
                variant={:ghost}
                size={:sm}
              >
                Review Search health <span aria-hidden="true">→</span>
              </.ops_link_button>
            </:actions>
            <p>{@posture.evidence}</p>
            <div class="mt-3 space-y-ops-2" data-testid="control-room-affected-scope">
              <p class="text-ops-body text-base-content">
                {affected_scope_label(@posture)}
              </p>
              <ul :if={affected_rows(@posture) != []} class="space-y-ops-2">
                <li
                  :for={{schema, reasons} <- affected_rows(@posture)}
                  class="ops-control-room__scope"
                >
                  <.ops_inline_code>{OperatorSelection.canonical(schema)}</.ops_inline_code>
                  <ul class="ml-4 list-disc space-y-1">
                    <li
                      :for={reason <- reasons}
                      data-testid={
                        if String.contains?(reason, "observation unavailable"),
                          do: "control-room-observation-error",
                          else: nil
                      }
                    >
                      {reason}
                    </li>
                  </ul>
                </li>
              </ul>
            </div>
            <p
              :if={@selected_schema}
              class="mt-2 text-ops-sm text-base-content/75"
              data-testid="recovery-target"
            >
              Recovery target:
              <.ops_inline_code>{OperatorSelection.canonical(@selected_schema)}</.ops_inline_code>
            </p>
            <p class="mt-2 text-ops-sm text-base-content/60">
              {schema_health_label(@posture.schema_count)} · {fetch_health_label(@posture.error_count)} · {backend_health_label(
                @posture.backend_failed_count
              )}
            </p>
          </.ops_verdict>
        </section>

        <section aria-labelledby="control-room-intents-heading" class="space-y-3">
          <.ops_heading level={2} id="control-room-intents-heading">
            What do you need to do?
          </.ops_heading>
          <div class="grid gap-4 md:grid-cols-2">
            <.ops_intent_card
              icon="hero-arrow-up-tray"
              title="Verify a change"
              summary="Verify a change before promotion. Reconcile, compare contract drift, then use the gated swap."
              route_label="Pre-flight sync drift"
              navigate={"#{@mount_path}/sync-drift"}
              data-testid="intent-change"
            />
            <.ops_intent_card
              icon="hero-map"
              title="Inspect and save a search check"
              summary="Inspect a search result, then save a useful check. Queries stay bounded and read-only."
              route_label="Explore search"
              navigate={"#{@mount_path}/search"}
              data-testid="intent-explore"
            />
          </div>
        </section>

        <section
          aria-labelledby="control-room-orient-heading"
          class="flex flex-wrap items-center justify-end gap-3 pt-ops-2 text-ops-body text-base-content/55"
        >
          <h2 id="control-room-orient-heading" class="sr-only">Operator guide</h2>
          <a href={@orientation_href} class="link link-hover">
            Read the operator guide <span aria-hidden="true">→</span>
          </a>
        </section>
      </div>
    </Layouts.app>
    """
  end

  defp health_path(mount_path, schema) when is_atom(schema),
    do: OperatorSelection.path(mount_path, "health", schema)

  defp health_path(mount_path, _schema), do: "#{String.trim_trailing(mount_path, "/")}/health"

  defp schema_health_label(1), do: "1 schema checked"
  defp schema_health_label(count), do: "#{count} schemas checked"

  defp fetch_health_label(0), do: "No schema fetch errors observed"
  defp fetch_health_label(1), do: "1 fetch needs attention"
  defp fetch_health_label(count), do: "#{count} fetches need attention"

  defp backend_health_label(0), do: "No failed backend tasks observed"
  defp backend_health_label(1), do: "1 backend needs attention"
  defp backend_health_label(count), do: "#{count} backends need attention"

  defp affected_scope_label(summary) do
    count = length(affected_rows(summary))

    case count do
      0 -> "No affected schemas identified on this check."
      1 -> "1 schema affected on this check:"
      count -> "#{count} schemas affected on this check:"
    end
  end

  defp affected_rows(summary) do
    Enum.flat_map(summary.rows, fn
      {schema, {:error, reason}} ->
        [{schema, ["Search health observation unavailable: #{inspect(reason)}"]}]

      {schema, {:ok, status}} ->
        reasons =
          [:backend, :queue]
          |> Enum.flat_map(&source_findings(status, summary, schema, &1))

        if reasons == [], do: [], else: [{schema, reasons}]
    end)
  end

  defp source_findings(status, summary, schema, source) do
    case Map.fetch(Map.get(status, :source_errors, %{}), source) do
      {:ok, reason} ->
        reference = Posture.last_success_ref(summary, schema, source)
        label = source_label(source)

        retained =
          if reference && reference.retained?,
            do: " last success retained from the previous check.",
            else: ""

        time = retained_time(reference && reference.state)

        timestamp =
          if time do
            " Last successful source observation: #{DateTime.to_iso8601(time)}."
          else
            ""
          end

        ["#{label} observation unavailable: #{inspect(reason)}.#{retained}#{timestamp}"]

      :error ->
        source_failed_findings(status, source)
    end
  end

  defp source_failed_findings(status, :backend) do
    case length(status.backend.failed) do
      0 -> []
      count -> ["Backend: #{count} failed task(s) observed on this check."]
    end
  end

  defp source_failed_findings(status, :queue) do
    case length(status.queue.failed) do
      0 -> []
      count -> ["Queue: #{count} failed job(s) observed on this check."]
    end
  end

  defp source_label(:backend), do: "Backend"
  defp source_label(:queue), do: "Queue"

  defp retained_time(%Scrypath.Operator.State{at: %DateTime{} = at}), do: at
  defp retained_time(_), do: nil
end
