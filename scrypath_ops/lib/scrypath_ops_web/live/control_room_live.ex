defmodule ScrypathOpsWeb.ControlRoomLive do
  @moduledoc """
  Intent-first landing for `/ops`.

  Shows the current fleet observation and routes operators to the matching surface.
  The deep per-schema health table lives on `ScrypathOpsWeb.PostureLive`.
  """

  use ScrypathOpsWeb, :live_view

  alias ScrypathOps.Posture

  @orientation_href "https://github.com/szTheory/scrypath/blob/main/scrypath_ops/docs/operator-ia.md"

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Control Room")
      |> assign(:orientation_href, @orientation_href)
      |> assign(:schema_allowlist, ScrypathOps.Schemas.allowlist())
      |> assign(:scrypath_opts, ScrypathOps.Schemas.scrypath_opts())
      |> assign(:refresh_issue, nil)
      |> load_summary()

    {:ok, socket}
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    summary = Posture.summary(socket.assigns.schema_allowlist, socket.assigns.scrypath_opts)

    if complete_observation?(summary) do
      socket =
        socket
        |> assign(:posture, summary)
        |> assign(:last_successful_posture, summary)
        |> assign(:refresh_issue, nil)
        |> put_flash(:info, "Search health refreshed.")

      {:noreply, socket}
    else
      socket =
        socket
        |> retain_observation_or_show_partial(summary)
        |> assign(:refresh_issue, summary)

      {:noreply, socket}
    end
  end

  defp load_summary(socket) do
    summary = Posture.summary(socket.assigns.schema_allowlist, socket.assigns.scrypath_opts)
    socket = assign(socket, :posture, summary)

    if complete_observation?(summary) do
      assign(socket, :last_successful_posture, summary)
    else
      assign(socket, :last_successful_posture, nil)
    end
  end

  defp complete_observation?(%Posture{state: state, error_count: 0, schema_count: count})
       when state in [:ok, :degraded] and count > 0,
       do: true

  defp complete_observation?(_summary), do: false

  defp retain_observation_or_show_partial(socket, summary) do
    case socket.assigns.last_successful_posture do
      %Posture{} = previous -> assign(socket, :posture, previous)
      nil -> assign(socket, :posture, summary)
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
      <div class="space-y-ops-page-gap">
        <.ops_toolbar class="items-end gap-4">
          <.ops_page_header
            title="Control Room"
            subtitle="Try a search or check how your indexes are syncing."
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

          <.ops_notice
            :if={@refresh_issue}
            kind={:warning}
            title="Search health refresh incomplete."
            role="status"
            data-testid="control-room-refresh-issue"
          >
            {@refresh_issue.evidence}
            <span :if={@last_successful_posture}>
              The last complete observation is retained below; this refresh did not confirm current health.
            </span>
            <span :if={is_nil(@last_successful_posture) and @refresh_issue.state in [:ok, :degraded]}>
              No prior complete observation is available; this partial result does not confirm current health.
            </span>
            <span :if={
              is_nil(@last_successful_posture) and
                @refresh_issue.state in [:unconfigured, :missing_backend]
            }>
              No schema health observation was possible; resolve the setup guidance below before refreshing.
            </span>
            <span
              :if={@refresh_issue.schema_count > 0}
              data-testid="control-room-refresh-affected-scope"
            >
              Affected scope: {affected_scope(@refresh_issue)}
            </span>
          </.ops_notice>

          <div :if={@posture.state == :unconfigured} data-testid="control-room-unconfigured">
            <.ops_empty_state title="No search schemas configured.">
              Configure the host application's schema allowlist to inspect search health.
            </.ops_empty_state>
          </div>

          <div :if={@posture.state == :missing_backend} data-testid="control-room-missing-backend">
            <.ops_empty_state title="Search backend not configured.">
              Configure the Scrypath runtime in the host application before checking search health.
            </.ops_empty_state>
          </div>

          <.ops_verdict
            :if={@posture.state in [:ok, :degraded]}
            kind={Posture.badge_kind(@posture.state)}
            label={
              cond do
                @refresh_issue && @last_successful_posture -> "Last successful observation"
                @refresh_issue || @posture.error_count > 0 -> "Partial observation"
                true -> nil
              end
            }
            headline={verdict_headline(@posture)}
            class="ops-verdict--hero"
            data-testid="control-room-verdict"
          >
            <p :if={@posture.error_count > 0}>{@posture.evidence}</p>
            <p :if={@posture.state == :degraded} data-testid="control-room-affected-scope">
              {affected_names(@posture)} · Search results may be out of date.
            </p>
            <p :if={@posture.state == :ok}>
              No failed sync jobs or Meilisearch tasks were found across {@posture.schema_count} schemas.
              Document visibility is checked separately.
            </p>
            <div class="mt-2">
              <.ops_link_button
                navigate={"#{@mount_path}/health"}
                variant={:primary}
                size={:sm}
                data-testid="control-room-health-link"
              >
                View search health
              </.ops_link_button>
            </div>
            <p
              :if={@refresh_issue && @last_successful_posture}
              class="mt-2 text-ops-sm text-base-content/75"
            >
              Last successful check: <.ops_time label="" dt={@posture.refreshed_at} />.
            </p>
            <p
              :if={@refresh_issue && is_nil(@last_successful_posture)}
              class="mt-2 text-ops-sm text-base-content/75"
            >
              Incomplete observation checked: <.ops_time label="" dt={@posture.refreshed_at} />.
            </p>
          </.ops_verdict>

          <div
            :if={@posture.state in [:ok, :degraded]}
            class="mt-4 grid gap-4 sm:grid-cols-2"
            data-testid="control-room-secondary-intents"
          >
            <.ops_intent_card
              icon="hero-magnifying-glass"
              title="Try a search"
              summary="Query your schemas and inspect the results."
              route_label="Try a search"
              navigate={"#{@mount_path}/search"}
              data-testid="control-room-explore-search"
            />
            <.ops_intent_card
              icon="hero-arrows-right-left"
              title="Check sync and settings"
              summary="See pending work and compare your declared settings with Meilisearch."
              route_label="Check sync and settings"
              navigate={"#{@mount_path}/sync-drift"}
              data-testid="control-room-verify-change"
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

  defp verdict_headline(%Posture{state: :degraded} = summary), do: summary.headline
  defp verdict_headline(%Posture{state: :ok}), do: "No sync failures found"

  defp affected_names(%Posture{rows: rows}) do
    rows
    |> Enum.filter(fn {_schema, result} ->
      case result do
        {:ok, status} -> status.backend.failed != [] or status.queue.failed != []
        _ -> true
      end
    end)
    |> Enum.map_join(", ", fn {schema, _} -> inspect(schema) end)
  end

  defp affected_scope(%Posture{rows: rows}) do
    rows
    |> Enum.flat_map(&row_scope/1)
    |> Enum.join("; ")
  end

  defp row_scope({schema, {:error, reason}}) do
    ["#{inspect(schema)}: schema health could not be checked (#{inspect(reason)})"]
  end

  defp row_scope({schema, {:ok, status}}) do
    backend_count = length(status.backend.failed)
    queue_count = length(status.queue.failed)

    []
    |> maybe_scope(schema, backend_count, "backend task(s) failed")
    |> maybe_scope(schema, queue_count, "queue job(s) failed")
  end

  defp maybe_scope(items, _schema, 0, _reason), do: items

  defp maybe_scope(items, schema, count, reason) do
    ["#{inspect(schema)}: #{count} #{reason}" | items]
  end
end
