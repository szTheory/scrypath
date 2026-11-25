defmodule ScrypathOps.Catalog.Stories.Areas.RecoveryStatus do
  # The Retry status area of Sync and index, over the same function component the page renders.
  #
  # Every variation is a status the observer can emit (`ScrypathOpsWeb.SyncDriftLive` receives it as a
  # status, an evidence map and a document observation), built into a view by
  # `ScrypathOps.RecoveryView.build/1` with Shopadelic's values: the replacement queue job 991 for
  # failed job 101, Meilisearch task 44 and the `shopadelic_product` index. `build/1` refuses a status
  # that claims an outcome without its evidence, so no variation can show a state the page cannot.
  # `variations/0` runs when the storybook backend compiles with no application started, so it only
  # calls pure code.
  #
  # The unavailable variation is defect D3: the handle in the URL cannot be resolved (an expired
  # receipt, another node, a different organization), so the observer reports an unknown outcome and
  # leaves an empty evidence map. Before the fix the page crashed on it; the area now says the
  # outcome could not be checked and shows no evidence line. That test mounts a stub schema, not
  # Shopadelic, so its note names the test by the test's own name (`Claim:`).
  use PhoenixStorybook.Story, :component

  alias ScrypathOps.RecoveryView

  @journey "Mounted scrypath_ops/test/scrypath_ops_web/live/catalog_journey_test.exs"
  @d3_test "Mounted scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs · Claim: an unresolved recovery handle renders a closed unavailable state"

  def function, do: &ScrypathOpsWeb.Components.Recovery.recovery_status/1
  def container, do: ScrypathOps.Catalog.Frames.full_width()
  def job, do: "JOB-03"
  def covers, do: [ScrypathOpsWeb.SyncDriftLive]

  def variations do
    now = ScrypathFixtures.preview_epoch()
    checked_at = DateTime.add(now, -120, :second)

    for {id, status, task_uid, proof, description} <- [
          {:shopadelic_failed_journey_queued, :accepted, nil, @journey,
           "Shopadelic, Retry was queued as job 991: the status says the queue has it and that refresh only observes, never resubmits."},
          {:shopadelic_failed_journey_running, :running, 44, "render only",
           "Shopadelic, the retry is running: the status follows job 991 and Meilisearch task 44."},
          {:shopadelic_failed_journey_queue_done_backend_pending, :queue_only_completed, nil,
           "render only",
           "Shopadelic, the queue job completed but backend and document evidence are not confirmed: completed is not verified."},
          {:shopadelic_failed_journey_verified, :verified, 44, @journey,
           "Shopadelic, the retry's task and its expected documents were observed: recovery is verified."},
          {:shopadelic_failed_journey_failed, :failed, 44, "render only",
           "Shopadelic, the retry job or its backend task failed: the status says to review it before retrying."},
          {:shopadelic_failed_journey_canceled, :cancelled, 44, "render only",
           "Shopadelic, the retry job or its backend task was canceled: the status says to review it."},
          {:shopadelic_failed_journey_unavailable, :unknown, nil, @d3_test,
           "Shopadelic, the retry's handle cannot be resolved: the area says the outcome could not be checked, with no job number."}
        ] do
      %Variation{
        id: id,
        description: description,
        note:
          "Adopter: Shopadelic (fictional) · Persona: On-call (ROLE-OPS) · Job: JOB-03 · Proof: #{proof}",
        attributes: %{
          view: view(status, task_uid, checked_at),
          now: now,
          mount_path: "/ops"
        }
      }
    end
  end

  # An unknown outcome is what the observer reports for a handle it cannot resolve: no evidence (the
  # LiveView stores the empty map) and a document observation that was never made.
  defp view(:unknown, _task_uid, _checked_at) do
    unchecked = %{
      state: :not_checked,
      reason: :receipt_unavailable,
      checked_at: nil,
      operation: nil,
      index: nil,
      expected_ids: nil
    }

    {:ok, view} =
      RecoveryView.build(%{
        schema: ScrypathFixtures.Shopadelic.Product,
        handle: "catalog-preview-handle",
        status: :unknown,
        evidence: %{},
        document_observation: unchecked,
        error: :receipt_unavailable,
        checked_at: nil,
        loading?: false
      })

    view
  end

  defp view(status, task_uid, checked_at) do
    {:ok, view} =
      RecoveryView.build(%{
        schema: ScrypathFixtures.Shopadelic.Product,
        handle: "catalog-preview-handle",
        status: status,
        evidence: %{
          replacement_job: 991,
          attempt: 1,
          task_uid: task_uid,
          index: "shopadelic_product"
        },
        document_observation: document(status, checked_at),
        error: nil,
        checked_at: checked_at,
        loading?: false
      })

    view
  end

  # Only a verified recovery carries a document observation (the observer reads documents once the
  # backend task is known to have succeeded).
  defp document(:verified, checked_at) do
    %{
      state: :verified,
      reason: nil,
      checked_at: checked_at,
      operation: :upsert,
      index: "shopadelic_product",
      expected_ids: ["SPD-2041", "SPD-2042"]
    }
  end

  defp document(_status, _checked_at), do: nil
end
