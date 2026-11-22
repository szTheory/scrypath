defmodule ScrypathOps.Catalog.Stories.Areas.FailedSummary do
  # The answer at the top of Failed sync (any load error, then the verdict, guidance and filter chips),
  # over the same function component the page renders.
  #
  # Each variation is a real state: `Scrypath.failed_sync_work/2` over the scenario's own options (the
  # loads the LiveView keeps, including the error one schema returns), built by
  # `ScrypathOps.FailedSyncView.build/4`. `variations/0` runs when the storybook backend compiles with
  # no application started, so it only calls pure code.
  use PhoenixStorybook.Story, :component

  alias Scrypath.Operator.FailedSyncWorkInspection
  alias ScrypathOps.FailedSyncView

  @seam "Mounted scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs"

  def function, do: &ScrypathOpsWeb.Components.FailedSync.failed_summary/1
  def container, do: :iframe
  def job, do: "JOB-03"
  def covers, do: [ScrypathOpsWeb.FailedSyncLive]

  def variations do
    now = ScrypathFixtures.preview_epoch()

    for {id, scenario_id, adopter, cause_filter, description} <- [
          {:shopadelic_failed_journey_failed_and_retrying, :shopadelic_failed_journey,
           "Shopadelic", [],
           "Shopadelic, five jobs failed or retrying: the verdict counts them and says what to do next."},
          {:shopadelic_failed_journey_filtered_out, :shopadelic_failed_journey, "Shopadelic",
           [:backend_rejected],
           "Shopadelic, filtered to a cause nothing has: the verdict says no work matches and offers Clear filters."},
          {:shopadelic_settings_aligned_nothing_failed, :shopadelic_settings_aligned,
           "Shopadelic", [],
           "Shopadelic, settings aligned: nothing failed, so the verdict says so and points to Sync and index."},
          {:logistify_history_over_limit_f1_load_error, :logistify_history_over_limit_f1,
           "Logistify", [],
           "Logistify, task history over the limit: the schema could not be checked, so its failures are not listed."}
        ] do
      scenario = ScrypathFixtures.Scenarios.get!(scenario_id, now)

      %Variation{
        id: id,
        description: description,
        note:
          "Adopter: #{adopter} (fictional) · Persona: On-call (ROLE-OPS) · Job: JOB-03 · Proof: #{@seam}",
        attributes: %{view: view(scenario, cause_filter, now), mount_path: "/ops"}
      }
    end
  end

  # The same per-schema loads `ScrypathOpsWeb.FailedSyncLive` keeps: `{:ok, entries}` or
  # `{:error, reason}` for each allowlisted schema.
  defp view(scenario, cause_filter, now) do
    opts = Keyword.put(scenario.scrypath_opts, :reason_class_counts, true)

    loads =
      for mod <- scenario.allowlist do
        case Scrypath.failed_sync_work(mod, opts) do
          {:ok, %FailedSyncWorkInspection{entries: entries}} -> {mod, {:ok, entries}}
          {:error, reason} -> {mod, {:error, reason}}
        end
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
