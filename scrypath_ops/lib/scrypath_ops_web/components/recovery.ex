defmodule ScrypathOpsWeb.Components.Recovery do
  @moduledoc """
  Function components for the two recovery areas of Sync and index
  (`ScrypathOpsWeb.SyncDriftLive`): document freshness and retry status.

  The LiveView and the component catalog (`scrypath_ops/storybook`) both call these, so a story
  renders the same markup the page does. They are pure: no socket, flash or authorization reads, and
  no clock. What they show comes in as a `%ScrypathOps.RecoveryView{}` built by
  `ScrypathOps.RecoveryView.build/1`, which is what lets a story build one with no process running.
  The `refresh_recovery_status` event is bound here by name and handled in the LiveView.

  Whether a section appears at all is the caller's decision (`view.visible?`); these components
  always render the section they are given.
  """
  use Phoenix.Component
  import ScrypathOpsWeb.OpsUi

  alias ScrypathOps.OperatorSelection
  alias ScrypathOps.RecoveryView

  @doc """
  Whether the documents the retry was expected to write or delete were seen in the active index: one
  verdict (observed, running, failed, canceled or not checked) and, once an observation exists, the
  expected effect, the index and the document identities.
  """
  attr(:view, RecoveryView, required: true, doc: "built by `ScrypathOps.RecoveryView.build/1`")
  attr(:now, :any, required: true, doc: "the render's snapshot instant, used for relative ages")

  def document_freshness(assigns) do
    ~H"""
    <.ops_section
      id="document-freshness"
      class="mt-6"
      title="Document freshness"
      subtitle="Check the expected effect for the exact recovery task in this schema's active index."
    >
      <:metadata>
        <.ops_time
          :if={@view.document.checked_at}
          id="documents-checked-at"
          label="Checked"
          dt={@view.document.checked_at}
          snapshot_at={@now}
        />
      </:metadata>
      <p :if={@view.loading?} role="status" aria-label="Checking document freshness">
        Checking the expected effect for this same recovery operation. Any previous result remains available with its checked time.
      </p>
      <.ops_status
        id="document-freshness-result"
        kind={@view.document.kind}
        title={@view.document.title}
        role="status"
        neutral
      >
        {@view.document.copy}
      </.ops_status>
      <div :if={@view.document.present?} class="mt-2 space-y-1 text-ops-body">
        <p :if={@view.document.operation}>
          Expected effect: {@view.document.operation}
        </p>
        <p :if={@view.document.index}>
          Active index:
          <.ops_inline_code>{@view.document.index}</.ops_inline_code>
        </p>
        <p :if={is_list(@view.document.expected_ids)}>
          Expected document identities:
          <span :for={id <- @view.document.expected_ids} class="break-all">
            <.ops_inline_code>{id}</.ops_inline_code>
          </span>
        </p>
      </div>
    </.ops_section>
    """
  end

  @doc """
  Where the retry stands: its status (queued, running, queue done with backend evidence pending,
  verified, failed, canceled, not checked or could not be checked), the exact queue job it follows
  and the way back to Failed sync. A status that could not be read shows no evidence line.
  """
  attr(:view, RecoveryView, required: true, doc: "built by `ScrypathOps.RecoveryView.build/1`")
  attr(:now, :any, required: true, doc: "the render's snapshot instant, used for relative ages")
  attr(:mount_path, :string, required: true, doc: "the path the operator UI is mounted at")

  def recovery_status(assigns) do
    ~H"""
    <.ops_section
      id="ordinary-recovery"
      class="mt-6"
      title="Retry status"
      subtitle="Follow the exact retry from its queue job to Meilisearch and document visibility."
    >
      <:metadata>
        <.ops_time
          :if={@view.checked_at}
          id="recovery-checked-at"
          label="Checked"
          dt={@view.checked_at}
          snapshot_at={@now}
        />
      </:metadata>
      <:actions>
        <.link
          navigate={OperatorSelection.path(@mount_path, "failed-sync", @view.schema)}
          class="link link-primary"
        >
          Review failed sync work
        </.link>
        <.ops_button
          :if={@view.handle?}
          phx-click="refresh_recovery_status"
          phx-disable-with="Checking…"
          disabled={@view.loading? || !@view.schema}
        >
          Refresh recovery status
        </.ops_button>
      </:actions>
      <p class="text-ops-body ops-muted">
        Retry failed work there. Refresh recovery status observes the queued retry and never resubmits it.
      </p>
      <div :if={@view.handle?} id="recovery-observation" class="mt-3 space-y-2">
        <p :if={@view.loading?} role="status" aria-label="Checking recovery status">
          Checking this same recovery operation. The last observed result remains visible until this check finishes.
        </p>
        <.ops_status
          kind={@view.kind}
          title={
            if @view.error,
              do: "Recovery refresh could not be checked",
              else: @view.label
          }
          role={if @view.error, do: "alert", else: "status"}
          neutral
        >
          {@view.copy}
          <span :if={@view.error}>
            Check detail: {inspect(@view.error)}.
          </span>
        </.ops_status>
        <p
          :if={@view.evidence}
          class="text-ops-body break-all"
          data-testid="recovery-evidence"
        >
          Schema:
          <.ops_inline_code>{@view.schema_name}</.ops_inline_code>
          · Queue job {@view.evidence.replacement_job} · attempt {@view.evidence.attempt}
          <span :if={@view.evidence.task_uid}>
            · Meilisearch task {@view.evidence.task_uid}
          </span>
          · Active index
          <.ops_inline_code>{@view.evidence.index}</.ops_inline_code>
        </p>
      </div>
    </.ops_section>
    """
  end
end
