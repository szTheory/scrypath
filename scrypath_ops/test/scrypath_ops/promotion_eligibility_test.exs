defmodule ScrypathOps.PromotionEligibilityTest do
  use ExUnit.Case, async: true

  alias ScrypathOps.PromotionEligibility
  alias ScrypathOps.Test.OpsPostA

  defp ready_context do
    %{
      schema: OpsPostA,
      allowlist: [OpsPostA],
      backend: Scrypath.Meilisearch,
      generation: 3,
      reconcile_generation: 3,
      drift_generation: 3,
      reconcile_loading: false,
      drift_loading: false,
      reconcile_error: nil,
      drift_error: nil,
      reconcile: %{
        schema: OpsPostA,
        index: "posts_live",
        status: %{
          backend: %{pending: [], failed: []},
          queue: %{pending: [], retrying: [], failed: []}
        },
        drift_signals: [],
        failed_work: [],
        reindex: %{
          live_index: "posts_live",
          target_index: "posts_next",
          observed?: true,
          task_state: :completed,
          cutover: :not_started
        }
      },
      drift: %{
        schema: OpsPostA,
        index: "posts_live",
        dimensions: %{fields: %{match: true}, settings: %{match: true}}
      }
    }
  end

  test "current same-context reports allow a distinct observed target" do
    assert :eligible = PromotionEligibility.evaluate(ready_context())
  end

  test "missing, failed, pending, wrong-context, unsupported, or unresolved signals deny by name" do
    cases = [
      {%{reconcile: nil}, :reconcile_not_current},
      {%{drift: nil}, :contract_not_current},
      {%{reconcile_error: :offline}, :reconcile_failed},
      {%{drift_error: :offline}, :contract_failed},
      {%{reconcile_loading: true}, :check_in_progress},
      {%{reconcile_generation: 2}, :reconcile_not_current},
      {%{drift_generation: 2}, :contract_not_current},
      {%{backend: :other}, :unsupported_backend},
      {%{allowlist: []}, :schema_not_allowed},
      {%{drift: %{schema: OpsPostA, index: "other", dimensions: %{fields: %{match: true}}}},
       :context_mismatch},
      {%{drift: %{schema: OpsPostA, index: "posts_live", dimensions: %{fields: %{match: false}}}},
       :contract_mismatch},
      {%{
         reconcile: put_in(ready_context().reconcile.status.backend.pending, [:pending]).reconcile
       }, :backend_work_pending},
      {%{
         reconcile: put_in(ready_context().reconcile.status.queue.retrying, [:retrying]).reconcile
       }, :queue_work_pending},
      {%{reconcile: put_in(ready_context().reconcile.reindex.task_state, :pending).reconcile},
       :reindex_pending},
      {%{reconcile: put_in(ready_context().reconcile.reindex.cutover, :pending).reconcile},
       :cutover_pending},
      {%{reconcile: put_in(ready_context().reconcile.reindex.observed?, false).reconcile},
       :target_unobserved},
      {%{reconcile: put_in(ready_context().reconcile.failed_work, [:failed]).reconcile},
       :failed_work},
      {%{
         reconcile: put_in(ready_context().reconcile.drift_signals, [:failed_sync_work]).reconcile
       }, :failed_work},
      {%{reconcile: put_in(ready_context().reconcile.status.backend.failed, [:failed]).reconcile},
       :failed_work},
      {%{
         reconcile: put_in(ready_context().reconcile.reindex.target_index, "posts_live").reconcile
       }, :indexes_not_distinct}
    ]

    for {changes, expected} <- cases do
      context = Map.merge(ready_context(), changes)
      assert {:blocked, ^expected} = PromotionEligibility.evaluate(context), inspect(changes)
    end
  end

  test "retained failed history blocks promotion while recovery remains independently available" do
    context = put_in(ready_context().reconcile.failed_work, [%{id: 1, state: :failed}])

    assert {:blocked, :failed_work} = PromotionEligibility.evaluate(context)
    refute Map.has_key?(context, :recovery_handle)
  end
end
