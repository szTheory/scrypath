defmodule ScrypathOps.Catalog.Stories.Flows.Job03OnCallRecoversFailedSync do
  # JOB-03 (Search looks unhealthy or sync work fails), the paged on-call engineer (ROLE-OPS), on
  # Shopadelic data: the Failed sync screen in the two states the engineer sees on the way to a
  # verified retry. A flow story is one screen state in one persona's situation; the walk across
  # screens (Search health, Failed sync, Sync and index and back) is the journey test, which is the
  # proof each caption below names.
  #
  # The screen is the real `FailedSync.screen/1` the page renders, a static render: buttons and
  # links do nothing here. `variations/0` runs when the storybook backend compiles with no application
  # started, so it only calls pure code (`Scrypath.failed_sync_work/2` over the scenario's own options,
  # then `ScrypathOps.FailedSyncView.build/4`).
  #
  # The captions say only what the journey asserts: which rows the page lists and which offer Retry,
  # and, after Retry on job 101, the receipt with the replacement queue job and the retained original.
  # Whether the retry later reads verified is the journey's verified test and the Retry status area
  # stories, not this one.
  use PhoenixStorybook.Story, :component

  alias Scrypath.Operator.FailedSyncWorkInspection
  alias ScrypathOps.FailedSyncView

  @journey "Mounted scrypath_ops/test/scrypath_ops_web/live/catalog_journey_test.exs"

  def function, do: &ScrypathOpsWeb.Components.FailedSync.screen/1
  def container, do: ScrypathOps.Catalog.Frames.full_width()
  def job, do: "JOB-03"
  def covers, do: [ScrypathOpsWeb.FailedSyncLive]

  def variations do
    now = ScrypathFixtures.preview_epoch()
    scenario = ScrypathFixtures.Scenarios.get!(:shopadelic_failed_journey, now)
    {loads, scope} = loads_and_scope(scenario)
    entry = loads |> FailedSyncView.all_rows() |> Enum.find(&(&1.id == 101))

    for {id, receipts, flash, description, caption} <- [
          {:shopadelic_failed_journey_arrived_from_health, %{}, %{},
           "Shopadelic, paged on-call: Failed sync as the engineer arrives from Search health, five rows and Retry where it is offered.",
           "The on-call engineer follows the unhealthy Search health row to this page. It lists the five failed or retrying items, offers Retry on the four Oban jobs and none on the failed Meilisearch task."},
          {:shopadelic_failed_journey_retry_queued,
           %{FailedSyncView.row_key(entry) => receipt(now)},
           %{"info" => "Retry queued · queue job 991"},
           "Shopadelic, paged on-call, after Retry on job 101: a receipt names the replacement queue job and links to Sync and index.",
           "The engineer pressed Retry on job 101. A receipt replaces the button, names the replacement queue job 991, says the original job 101 is retained and links to Sync and index to check the status."}
        ] do
      %Variation{
        id: id,
        description: description,
        note:
          "Adopter: Shopadelic (fictional) · Persona: On-call (ROLE-OPS) · Job: JOB-03 · Proof: #{@journey}\n\n" <>
            caption,
        attributes: %{
          view: FailedSyncView.build(loads, scope, receipts, now),
          mount_path: "/ops",
          flash: flash,
          shell: :ops,
          page_title: "Failed sync work",
          last_refresh_at: now
        }
      }
    end
  end

  # The same loads `ScrypathOpsWeb.FailedSyncLive` keeps: one result per allowlisted schema, with the
  # Oban and Meilisearch reads replaced by direct `Scrypath.failed_sync_work/2` calls.
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
