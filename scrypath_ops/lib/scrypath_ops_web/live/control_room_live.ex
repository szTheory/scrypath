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

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Control Room")
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
        <.ops_button phx-click="refresh" variant={:primary} data-ops-refresh>
          Refresh posture
        </.ops_button>
      </.ops_toolbar>

      <.ops_journey mount_path={@mount_path} current={:control_room} />

      <.ops_panel>
        <section aria-labelledby="control-room-posture-heading" class="space-y-4">
          <h2 id="control-room-posture-heading" class="sr-only">Fleet posture</h2>

          <.ops_config_empty :if={@posture.state == :unconfigured} kind={:no_schemas} />
          <.ops_config_empty :if={@posture.state == :missing_backend} kind={:missing_backend} />

          <.ops_verdict
            :if={@posture.state in [:ok, :degraded]}
            kind={Posture.badge_kind(@posture.state)}
            label="Can I trust search right now?"
            headline={@posture.headline}
          >
            <:actions>
              <.ops_link_button navigate={"#{@mount_path}/posture"} variant={:ghost} size={:sm}>
                Open full posture <span aria-hidden="true">→</span>
              </.ops_link_button>
            </:actions>
            <p>{@posture.evidence}</p>
            <p class="mt-2 text-xs text-base-content/60">
              {@posture.schema_count} schema(s) · {@posture.error_count} fetch error(s) · {@posture.backend_failed_count} failed backend · refreshed {format_dt(
                @posture.refreshed_at
              )}
            </p>
          </.ops_verdict>

          <.ops_link_button
            :if={@posture.state in [:unconfigured, :missing_backend]}
            navigate={"#{@mount_path}/posture"}
            variant={:ghost}
            size={:sm}
          >
            Open full posture <span aria-hidden="true">→</span>
          </.ops_link_button>
        </section>
      </.ops_panel>

      <section aria-labelledby="control-room-intents-heading" class="space-y-3">
        <h2 id="control-room-intents-heading" class="text-lg font-semibold text-base-content">
          What do you need to do?
        </h2>
        <div class="grid gap-4 md:grid-cols-3">
          <.ops_intent_card
            icon="🚨"
            kind={intent_tone(@posture)}
            title="Something looks broken"
            summary="Triage an incident. Check fleet posture, work the failed-sync queue, then confirm sync drift."
            route_label="Start triage"
            navigate={"#{@mount_path}/posture"}
            data-testid="intent-incident"
          />
          <.ops_intent_card
            icon="🚀"
            title="I'm shipping a change"
            summary="Pre-flight a deploy. Reconcile sync posture, compare index-contract drift, then promote with the gated swap."
            route_label="Open sync drift"
            navigate={"#{@mount_path}/sync-drift"}
            data-testid="intent-change"
          />
          <.ops_intent_card
            icon="🔎"
            title="Explore & capture"
            summary="Probe search behavior with bounded read-only queries, then save the useful ones as reusable playbooks."
            route_label="Open search"
            navigate={"#{@mount_path}/search"}
            data-testid="intent-explore"
          />
        </div>
      </section>

      <.ops_section
        title="Jump to"
        subtitle="Power-user shortcuts — every surface is one click away."
      >
        <div class="flex flex-wrap gap-ops-control-gap">
          <.ops_link_button navigate={"#{@mount_path}/failed-sync"} size={:sm}>
            Failed sync
          </.ops_link_button>
          <.ops_link_button navigate={"#{@mount_path}/sync-drift"} size={:sm}>
            Sync drift
          </.ops_link_button>
          <.ops_link_button navigate={"#{@mount_path}/search"} size={:sm}>
            Search
          </.ops_link_button>
          <.ops_link_button navigate={"#{@mount_path}/playbooks"} size={:sm}>
            Playbooks
          </.ops_link_button>
        </div>
      </.ops_section>
    </Layouts.app>
    """
  end

  defp intent_tone(%Posture{state: :degraded}), do: :warning
  defp intent_tone(%Posture{state: :missing_backend}), do: :error
  defp intent_tone(_), do: :neutral

  defp format_dt(nil), do: "—"

  defp format_dt(%DateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%d %H:%M:%SZ")
  end
end
