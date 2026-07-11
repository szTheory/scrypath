defmodule ScrypathOpsWeb.ControlRoomLive do
  @moduledoc """
  Intent-first landing for `/ops`.

  Shows a glanceable fleet-posture strip and routes the operator to the surface that
  matches the job they brought: incident triage, change verification, or exploration.
  The deep per-schema posture table lives on `ScrypathOpsWeb.PostureLive` — this page
  is the overview, not a duplicate of it.
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
      |> load_summary()

    {:ok, socket}
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    {:noreply, load_summary(socket)}
  end

  defp load_summary(socket) do
    summary = Posture.summary(socket.assigns.schema_allowlist, socket.assigns.scrypath_opts)
    assign(socket, :posture, summary)
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
          title="Control Room"
          subtitle="Start here. See whether search is in sync, then pick the job you're doing."
        />
      </.ops_toolbar>

      <section aria-labelledby="control-room-posture-heading" class="space-y-4">
        <h2 id="control-room-posture-heading" class="sr-only">Fleet posture</h2>

        <.ops_config_empty :if={@posture.state == :unconfigured} kind={:no_schemas}>
          <:actions>
            <.ops_refresh_button phx-click="refresh" aria_label="Refresh search trust status" />
          </:actions>
        </.ops_config_empty>
        <.ops_config_empty :if={@posture.state == :missing_backend} kind={:missing_backend}>
          <:actions>
            <.ops_refresh_button phx-click="refresh" aria_label="Refresh search trust status" />
          </:actions>
        </.ops_config_empty>

        <.ops_verdict
          :if={@posture.state in [:ok, :degraded]}
          kind={Posture.badge_kind(@posture.state)}
          label="Can I trust search right now?"
          headline={@posture.headline}
          class="ops-verdict--hero"
        >
          <:actions>
            <.ops_refresh_button phx-click="refresh" aria_label="Refresh search trust status" />
            <.ops_link_button navigate={"#{@mount_path}/posture"} variant={:ghost} size={:sm}>
              Open full posture <span aria-hidden="true">→</span>
            </.ops_link_button>
          </:actions>
          <p>{@posture.evidence}</p>
          <p class="mt-2 text-ops-sm text-base-content/60">
            {schema_health_label(@posture.schema_count)} · {fetch_health_label(@posture.error_count)} · {backend_health_label(
              @posture.backend_failed_count
            )} · <.ops_time label="Checked" dt={@posture.refreshed_at} />
          </p>
        </.ops_verdict>
      </section>

      <section aria-labelledby="control-room-intents-heading" class="space-y-3">
        <.ops_heading level={2} id="control-room-intents-heading">
          What do you need to do?
        </.ops_heading>
        <div class="grid gap-4 md:grid-cols-3">
          <.ops_intent_card
            icon="hero-wrench-screwdriver"
            kind={intent_tone(@posture)}
            recommended={@posture.state in [:degraded, :missing_backend]}
            title="If something looks broken"
            summary="Recover from an incident. Check fleet posture, work the failed-sync queue, then confirm sync drift."
            route_label="Start recovery"
            navigate={"#{@mount_path}/posture"}
            data-testid="intent-incident"
          >
            <:badge :if={@posture.state == :degraded}>
              <span class="ops-badge ops-copper-badge">Federated</span>
            </:badge>
          </.ops_intent_card>
          <.ops_intent_card
            icon="hero-arrow-up-tray"
            title="I'm shipping a change"
            summary="Pre-flight a deploy. Reconcile sync posture, compare index-contract drift, then promote with the gated swap."
            route_label="Pre-flight sync drift"
            navigate={"#{@mount_path}/sync-drift"}
            data-testid="intent-change"
          />
          <.ops_intent_card
            icon="hero-map"
            title="Explore & capture"
            summary="Probe search behavior with bounded read-only queries, then save the useful ones as reusable playbooks."
            route_label="Explore search"
            navigate={"#{@mount_path}/search"}
            data-testid="intent-explore"
          />
        </div>
      </section>

      <section
        aria-labelledby="control-room-orient-heading"
        class="flex flex-wrap items-center justify-between gap-3 pt-ops-2 text-ops-sm text-base-content/55"
      >
        <h2 id="control-room-orient-heading" class="sr-only">Getting around</h2>
        <.ops_command_hint />
        <a href={@orientation_href} class="link link-hover">
          New here? See what each surface does <span aria-hidden="true">→</span>
        </a>
      </section>
    </Layouts.app>
    """
  end

  defp intent_tone(%Posture{state: :degraded}), do: :warning
  defp intent_tone(%Posture{state: :missing_backend}), do: :error
  defp intent_tone(_), do: :neutral

  defp schema_health_label(1), do: "1 schema checked"
  defp schema_health_label(count), do: "#{count} schemas checked"

  defp fetch_health_label(0), do: "All fetches healthy"
  defp fetch_health_label(1), do: "1 fetch needs attention"
  defp fetch_health_label(count), do: "#{count} fetches need attention"

  defp backend_health_label(0), do: "All backends healthy"
  defp backend_health_label(1), do: "1 backend needs attention"
  defp backend_health_label(count), do: "#{count} backends need attention"
end
