defmodule ScrypathOpsWeb.Components.SearchHealth do
  @moduledoc """
  Function components for the Search health page (`ScrypathOpsWeb.PostureLive`).

  The LiveView and the component catalog (`scrypath_ops/storybook`) both call these, so a story
  renders the same markup the page does. They are pure: no socket, flash or authorization reads,
  and no clock. The posture comes in as a `%ScrypathOps.Posture{}` built by
  `ScrypathOps.Posture.build/3`, which is what lets a story build one with no process running.
  """
  use Phoenix.Component
  import ScrypathOpsWeb.OpsUi

  alias ScrypathOps.Posture

  @doc """
  The answer at the top of Search health: a verdict that follows the worst row, then a one-line
  count of schemas and the sync mode. A posture with a setup problem (no schemas, or no backend)
  shows the matching configuration empty state instead.
  """
  attr(:summary, Posture, required: true, doc: "built by `ScrypathOps.Posture.build/3`")

  attr(:sync_mode, :any,
    default: :inline,
    doc: "the `:sync_mode` option the page scans with: `:oban`, `:inline` or `:manual`"
  )

  def health_verdict(%{summary: %Posture{state: :unconfigured}} = assigns) do
    ~H"""
    <.ops_config_empty kind={:no_schemas} class="mt-ops-4" />
    """
  end

  def health_verdict(%{summary: %Posture{state: :missing_backend}} = assigns) do
    ~H"""
    <.ops_config_empty kind={:missing_backend} class="mt-ops-4" />
    """
  end

  def health_verdict(assigns) do
    ~H"""
    <section aria-labelledby="posture-summary-heading" class="space-y-ops-4">
      <h2 id="posture-summary-heading" class="sr-only">Search health summary</h2>
      <.ops_verdict
        kind={Posture.verdict_kind(@summary.rows)}
        status={Posture.worst_status(@summary.rows)}
        class="ops-posture-verdict"
        headline={@summary.headline}
      >
        {@summary.evidence}
      </.ops_verdict>
      <p class="text-ops-sm ops-muted">
        {@summary.schema_count} {if @summary.schema_count == 1,
          do: "schema",
          else: "schemas"} · {sync_summary(@sync_mode)}
        <span :if={@summary.error_count > 0}>
          · {@summary.error_count} {if @summary.error_count == 1, do: "check", else: "checks"} unavailable
        </span>
      </p>
    </section>
    """
  end

  defp sync_summary(mode) do
    case mode do
      :oban -> "Background sync with Oban"
      :inline -> "Inline sync"
      :manual -> "Manual sync"
      _ -> "Sync mode unavailable"
    end
  end
end
