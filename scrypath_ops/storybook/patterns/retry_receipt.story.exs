defmodule ScrypathOps.Catalog.Stories.Patterns.RetryReceipt do
  # The receipt that replaces Retry on a Failed sync row once a retry was queued, over the same
  # function component the page renders.
  #
  # The row is a real one (`Scrypath.failed_sync_work/2` over the Shopadelic failed journey, built by
  # `ScrypathOps.FailedSyncView.build/4`); the receipt is shaped as `FailedSyncLive` stores it after
  # `Scrypath.retry_sync_work/2` is accepted. `variations/0` runs when the storybook backend compiles
  # with no application started, so it only calls pure code.
  use PhoenixStorybook.Story, :component

  alias Scrypath.Operator.FailedSyncWorkInspection
  alias ScrypathOps.FailedSyncView

  @journey "Mounted scrypath_ops/test/scrypath_ops_web/live/catalog_journey_test.exs"

  def function, do: &ScrypathOpsWeb.Components.FailedSync.retry_receipt/1
  def container, do: :iframe
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

    scope = %{
      error: nil,
      allowlist: scenario.allowlist,
      schema_filter: [],
      cause_filter: [],
      delete_confirmation: nil
    }

    entry = loads |> FailedSyncView.all_rows() |> Enum.find(&(&1.id == 101))
    receipts = %{FailedSyncView.row_key(entry) => receipt(now)}
    view = FailedSyncView.build(loads, scope, receipts, now)

    [
      %Variation{
        id: :shopadelic_failed_journey_queued,
        description:
          "Shopadelic, Retry was pressed on job 101: the replacement job, a plain not-yet-confirmed line, and the status link.",
        note:
          "Adopter: Shopadelic (fictional) · Persona: On-call (ROLE-OPS) · Job: JOB-03 · Proof: #{@journey}",
        attributes: %{row: Enum.find(view.rows, &(&1.id == 101)), mount_path: "/ops"}
      }
    ]
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
