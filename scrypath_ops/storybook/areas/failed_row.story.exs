defmodule ScrypathOps.Catalog.Stories.Areas.FailedRow do
  # One failed or retrying sync job on Failed sync, over the same function component the page renders.
  #
  # Every variation is a real row: `Scrypath.failed_sync_work/2` over the scenario's own options,
  # built into a view by `ScrypathOps.FailedSyncView.build/4`, then the one row it holds.
  # `variations/0` runs when the storybook backend compiles, with no application started, so it only
  # calls pure code. Never call the LiveView or anything that needs `ScrypathOps.TaskSupervisor`.
  #
  # The long error is finding F2 (backend error text is shown unbounded) as it behaves today. The
  # text comes from the Shopadelic `:hostile_ids` fixture; the story neither shortens nor hides it.
  use PhoenixStorybook.Story, :component

  alias Scrypath.Operator.FailedSyncWorkInspection
  alias ScrypathOps.FailedSyncView

  @journey "Mounted scrypath_ops/test/scrypath_ops_web/live/catalog_journey_test.exs"
  @seam "Mounted scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs"

  def function, do: &ScrypathOpsWeb.Components.FailedSync.failed_row/1
  def container, do: ScrypathOps.Catalog.Frames.area()
  def job, do: "JOB-03"
  def covers, do: [ScrypathOpsWeb.FailedSyncLive]

  def variations do
    now = ScrypathFixtures.preview_epoch()

    for {id, scenario_id, job_id, receipt?, proof, description} <- [
          {:shopadelic_failed_journey_retryable, :shopadelic_failed_journey, 101, false, @journey,
           "Shopadelic, a failed sync job that could not reach Meilisearch: the row offers Retry."},
          {:shopadelic_failed_journey_retrying, :shopadelic_failed_journey, 102, false, @seam,
           "Shopadelic, a job that failed and is retrying: the row shows when Oban tries it next."},
          {:shopadelic_failed_journey_retry_queued, :shopadelic_failed_journey, 101, true,
           @journey,
           "Shopadelic, Retry was just pressed: the receipt replaces Retry and says completion is not confirmed."},
          {:shopadelic_failed_journey_ineligible_task, :shopadelic_failed_journey, 43, false,
           @seam,
           "Shopadelic, a failed Meilisearch task: no Retry, and the row says why it cannot be retried here."},
          {:shopadelic_failed_journey_delete_retry, :shopadelic_failed_journey, 104, false, @seam,
           "Shopadelic, a failed delete with its retries used up: Retry opens a confirmation first."},
          {:shopadelic_hostile_ids_long_error, :shopadelic_hostile_ids, 52, false, "render only",
           "Shopadelic, a Meilisearch error with a very long message, shown as the backend sent it (finding F2)."}
        ] do
      scenario = ScrypathFixtures.Scenarios.get!(scenario_id, now)
      {loads, scope} = loads_and_scope(scenario)
      entry = Enum.find(FailedSyncView.all_rows(loads), &(&1.id == job_id))
      receipts = if receipt?, do: %{FailedSyncView.row_key(entry) => receipt(now)}, else: %{}
      view = FailedSyncView.build(loads, scope, receipts, now)

      %Variation{
        id: id,
        description: description,
        note:
          "Adopter: Shopadelic (fictional) · Persona: On-call (ROLE-OPS) · Job: JOB-03 · Proof: #{proof}",
        attributes: %{
          row: Enum.find(view.rows, &(&1.id == job_id)),
          now: now,
          mount_path: "/ops"
        }
      }
    end
  end

  # The same loads `ScrypathOpsWeb.FailedSyncLive` keeps, with the Oban and Meilisearch reads replaced
  # by direct `Scrypath.failed_sync_work/2` calls over the scenario's own options.
  defp loads_and_scope(scenario) do
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
      cause_filter: [],
      delete_confirmation: nil
    }

    {loads, scope}
  end

  # A receipt shaped as the LiveView stores it after a retry is accepted: the replacement job the
  # journey sees (991), registered for observation so the page links to Sync and index.
  defp receipt(now) do
    %{
      replacement_job: 991,
      attempt: 1,
      operation: :upsert,
      schema: "Elixir.ScrypathFixtures.Shopadelic.Product",
      index: "shopadelic_product",
      backend: "Elixir.Scrypath.Meilisearch",
      source_failure: %{id: 101, task_uid: nil, index: nil, operation: :upsert},
      accepted_result: %{job_id: 991},
      generation: 0,
      created_at: now,
      handle: "catalog-preview-handle",
      state: :accepted,
      checked_at: now
    }
  end
end
