defmodule ScrypathOps.Catalog.Stories.Patterns.DeleteConfirmation do
  # The dialog that asks before a failed delete is retried, over the same function component the page
  # renders when an operator presses Retry on a delete row.
  #
  # The row is a real one (`Scrypath.failed_sync_work/2` over the Shopadelic failed journey, job 104,
  # built by `ScrypathOps.FailedSyncView.build/4` with that row's delete confirmation open).
  # `variations/0` runs when the storybook backend compiles with no application started, so it only
  # calls pure code. In the catalog the buttons do nothing.
  use PhoenixStorybook.Story, :component

  alias Scrypath.Operator.FailedSyncWorkInspection
  alias ScrypathOps.FailedSyncView

  @seam "Mounted scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs"

  def function, do: &ScrypathOpsWeb.Components.FailedSync.delete_confirmation/1
  # The dialog is a fixed overlay, so it adds no height of its own: without a minimum height the
  # frame collapses to a sliver. The height fits the dialog with one document id.
  def container, do: {:iframe, style: "min-height: 30rem;"}
  def job, do: "JOB-03"
  def covers, do: [ScrypathOpsWeb.FailedSyncLive]

  def variations do
    now = ScrypathFixtures.preview_epoch()
    scenario = ScrypathFixtures.Scenarios.get!(:shopadelic_failed_journey, now)
    opts = Keyword.put(scenario.scrypath_opts, :reason_class_counts, true)

    loads =
      for mod <- scenario.allowlist do
        {:ok, %FailedSyncWorkInspection{entries: entries}} = Scrypath.failed_sync_work(mod, opts)
        {mod, {:ok, entries}}
      end

    delete_entry = loads |> FailedSyncView.all_rows() |> Enum.find(&(&1.id == 104))

    scope = %{
      error: nil,
      allowlist: scenario.allowlist,
      schema_filter: [],
      cause_filter: [],
      delete_confirmation: FailedSyncView.row_key(delete_entry)
    }

    view = FailedSyncView.build(loads, scope, %{}, now)

    [
      %Variation{
        id: :shopadelic_failed_journey_delete_retry_open,
        description:
          "Shopadelic, Retry pressed on a failed delete: the dialog names the schema, index and document before anything is sent.",
        note:
          "Adopter: Shopadelic (fictional) · Persona: On-call (ROLE-OPS) · Job: JOB-03 · Proof: #{@seam}",
        attributes: %{row: view.delete_row}
      }
    ]
  end
end
