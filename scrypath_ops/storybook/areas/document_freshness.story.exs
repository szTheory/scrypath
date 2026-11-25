defmodule ScrypathOps.Catalog.Stories.Areas.DocumentFreshness do
  # The Document freshness area of Sync and index, over the same function component the page renders:
  # whether the documents a retry was expected to write or delete were seen in the active index.
  #
  # Every variation is a document observation the observer can emit, built into a view by
  # `ScrypathOps.RecoveryView.build/1` with Shopadelic's values (the failed upsert of SPD-2041 and
  # SPD-2042, replacement queue job 991, Meilisearch task 44, the `shopadelic_product` index).
  # `variations/0` runs when the storybook backend compiles with no application started, so it only
  # calls pure code.
  #
  # The unchecked variation is what an unresolved handle leaves (defect D3): the observation was never
  # made, so the area says it is unavailable and shows no effect, index or document ids.
  use PhoenixStorybook.Story, :component

  alias ScrypathOps.RecoveryView

  @journey "Mounted scrypath_ops/test/scrypath_ops_web/live/catalog_journey_test.exs"
  @d3_test "Mounted scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs · Claim: Expected-document evidence is unavailable"

  def function, do: &ScrypathOpsWeb.Components.Recovery.document_freshness/1
  def container, do: ScrypathOps.Catalog.Frames.area()
  def job, do: "JOB-03"
  def covers, do: [ScrypathOpsWeb.SyncDriftLive]

  def variations do
    now = ScrypathFixtures.preview_epoch()
    checked_at = DateTime.add(now, -120, :second)

    for {id, status, document, proof, description} <- [
          {:shopadelic_failed_journey_verified_upsert, :verified,
           observed(:verified, :upsert, checked_at), @journey,
           "Shopadelic, the retried upsert: the expected effect was observed in the active index, for SPD-2041 and SPD-2042."},
          {:shopadelic_failed_journey_verified_delete, :verified,
           observed(:verified, :delete, checked_at), "render only",
           "Shopadelic, a retried delete: the expected delete was seen in the active index."},
          {:shopadelic_failed_journey_running, :running, observed(:running, :upsert, checked_at),
           "render only",
           "Shopadelic, the backend task is still running: the area says to refresh and check again."},
          {:shopadelic_failed_journey_unchecked, :unknown, unchecked(), @d3_test,
           "Shopadelic, the retry's handle cannot be resolved: nothing was checked, and no effect or document ids show."}
        ] do
      %Variation{
        id: id,
        description: description,
        note:
          "Adopter: Shopadelic (fictional) · Persona: On-call (ROLE-OPS) · Job: JOB-03 · Proof: #{proof}",
        attributes: %{view: view(status, document, checked_at), now: now}
      }
    end
  end

  # An unknown outcome is what the observer reports with no evidence (the LiveView stores the empty
  # map); every other status has the full evidence of the exact retry.
  defp view(:unknown, document, _checked_at) do
    {:ok, view} =
      RecoveryView.build(%{
        schema: ScrypathFixtures.Shopadelic.Product,
        handle: "catalog-preview-handle",
        status: :unknown,
        evidence: %{},
        document_observation: document,
        error: :receipt_unavailable,
        checked_at: nil,
        loading?: false
      })

    view
  end

  defp view(status, document, checked_at) do
    {:ok, view} =
      RecoveryView.build(%{
        schema: ScrypathFixtures.Shopadelic.Product,
        handle: "catalog-preview-handle",
        status: status,
        evidence: %{
          replacement_job: 991,
          attempt: 1,
          task_uid: 44,
          index: "shopadelic_product"
        },
        document_observation: document,
        error: nil,
        checked_at: checked_at,
        loading?: false
      })

    view
  end

  # What `ScrypathOpsWeb.SyncDriftLive` stores once the backend task is known: the state, the expected
  # effect, the active index and the identities of the documents read.
  defp observed(state, operation, checked_at) do
    %{
      state: state,
      reason: nil,
      checked_at: checked_at,
      operation: operation,
      index: "shopadelic_product",
      expected_ids: ["SPD-2041", "SPD-2042"]
    }
  end

  # An observation that was never made: `unchecked_document_observation/2` for a handle with no
  # receipt behind it.
  defp unchecked do
    %{
      state: :not_checked,
      reason: :receipt_unavailable,
      checked_at: nil,
      operation: nil,
      index: nil,
      expected_ids: nil
    }
  end
end
