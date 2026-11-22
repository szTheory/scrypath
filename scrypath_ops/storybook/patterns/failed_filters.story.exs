defmodule ScrypathOps.Catalog.Stories.Patterns.FailedFilters do
  # The cause filter chips on Failed sync, over the same function component the page renders.
  #
  # The view is built by `ScrypathOps.FailedSyncView.build/4` over `Scrypath.failed_sync_work/2`
  # results for the scenario's own options. `variations/0` runs when the storybook backend compiles
  # with no application started, so it only calls pure code.
  #
  # The schema chips (a second fieldset) only appear when more than one schema is allowlisted, and no
  # fixture scenario has two schemas, so no variation shows them. The mounted behavior with several
  # schemas is covered by `failed_sync_live_test.exs`.
  use PhoenixStorybook.Story, :component

  alias Scrypath.Operator.FailedSyncWorkInspection
  alias ScrypathOps.FailedSyncView

  @seam "Mounted scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs"

  def function, do: &ScrypathOpsWeb.Components.FailedSync.failed_filters/1
  def container, do: :iframe
  def job, do: "JOB-03"
  def covers, do: [ScrypathOpsWeb.FailedSyncLive]

  def variations do
    now = ScrypathFixtures.preview_epoch()
    scenario = ScrypathFixtures.Scenarios.get!(:shopadelic_failed_journey, now)

    for {id, cause_filter, description} <- [
          {:shopadelic_failed_journey_mixed_causes, [],
           "Shopadelic, five failed or retrying jobs: each cause is a chip with its count, most common first."},
          {:shopadelic_failed_journey_cause_selected, [:transport],
           "Shopadelic, filtered to one cause: that chip is selected and the others keep their counts."}
        ] do
      %Variation{
        id: id,
        description: description,
        note:
          "Adopter: Shopadelic (fictional) · Persona: On-call (ROLE-OPS) · Job: JOB-03 · Proof: #{@seam}",
        attributes: %{view: view(scenario, cause_filter, now)}
      }
    end
  end

  defp view(scenario, cause_filter, now) do
    opts = Keyword.put(scenario.scrypath_opts, :reason_class_counts, true)

    loads =
      for mod <- scenario.allowlist do
        {:ok, %FailedSyncWorkInspection{entries: entries}} = Scrypath.failed_sync_work(mod, opts)
        {mod, {:ok, entries}}
      end

    scope = %{
      error: nil,
      allowlist: scenario.allowlist,
      schema_filter: [],
      cause_filter: cause_filter,
      delete_confirmation: nil
    }

    FailedSyncView.build(loads, scope, %{}, now)
  end
end
