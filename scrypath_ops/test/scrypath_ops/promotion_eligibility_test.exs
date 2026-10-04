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

  test "canonical ready report structs remain eligible" do
    context = ready_context()

    reconcile =
      context.reconcile
      |> Map.merge(%{mode: :manual, actions: []})
      |> Map.update!(:reindex, &struct!(Scrypath.Operator.Reconcile.ReindexVisibility, &1))
      |> Map.update!(:status, fn status ->
        struct!(
          Scrypath.Operator.Status,
          Map.merge(status, %{schema: OpsPostA, mode: :manual, index: "posts_live"})
        )
      end)
      |> then(&struct!(Scrypath.Operator.Reconcile, &1))

    drift =
      context.drift
      |> Map.put(:version, 1)
      |> Map.update!(:dimensions, fn dimensions ->
        Map.new(dimensions, fn {name, dimension} ->
          {name, struct!(Scrypath.Operator.IndexContractDrift.Report.Dimension, dimension)}
        end)
      end)
      |> then(&struct!(Scrypath.Operator.IndexContractDrift.Report, &1))

    assert :eligible =
             PromotionEligibility.evaluate(%{context | reconcile: reconcile, drift: drift})
  end

  test "missing, nil, and malformed reports deny without raising" do
    for {key, reason} <- [reconcile: :reconcile_not_current, drift: :contract_not_current] do
      assert {:blocked, ^reason} =
               ready_context() |> Map.delete(key) |> PromotionEligibility.evaluate()

      for value <- [nil, :unknown, "unavailable", [], 123] do
        assert {:blocked, ^reason} =
                 ready_context() |> Map.put(key, value) |> PromotionEligibility.evaluate()
      end
    end
  end

  for {path, reason} <- [
        {[:reconcile, :reindex], :indexes_not_distinct},
        {[:reconcile, :status], :backend_work_pending},
        {[:reconcile, :status, :backend], :backend_work_pending},
        {[:reconcile, :status, :queue], :queue_work_pending},
        {[:reconcile, :failed_work], :failed_work},
        {[:reconcile, :drift_signals], :failed_work},
        {[:drift, :dimensions], :contract_mismatch}
      ] do
    test "missing, nil, and malformed #{inspect(path)} deny by name" do
      path = unquote(path)
      reason = unquote(reason)
      {_removed, missing} = pop_in(ready_context(), path)

      assert {:blocked, ^reason} = PromotionEligibility.evaluate(missing)

      for value <- [nil, :unknown, "unavailable", 123, %URI{}] do
        context = put_in(ready_context(), path, value)
        assert {:blocked, ^reason} = PromotionEligibility.evaluate(context)
      end
    end
  end

  test "unknown pending and failure lists remain unavailable instead of reading as empty" do
    for {path, reason} <- [
          {[:reconcile, :status, :backend, :pending], :backend_work_pending},
          {[:reconcile, :status, :backend, :failed], :failed_work},
          {[:reconcile, :status, :queue, :pending], :queue_work_pending},
          {[:reconcile, :status, :queue, :retrying], :queue_work_pending},
          {[:reconcile, :status, :queue, :failed], :failed_work}
        ] do
      {_removed, missing} = pop_in(ready_context(), path)
      assert {:blocked, ^reason} = PromotionEligibility.evaluate(missing)

      for value <- [nil, :unknown, %{}, "unavailable"] do
        context = put_in(ready_context(), path, value)
        assert {:blocked, ^reason} = PromotionEligibility.evaluate(context)
      end
    end
  end

  test "missing and unknown target task states are unobserved" do
    {_removed, missing} = pop_in(ready_context(), [:reconcile, :reindex, :task_state])
    assert {:blocked, :target_unobserved} = PromotionEligibility.evaluate(missing)

    for value <- [nil, :unknown, :cancelled, "completed", [], %{}, 123] do
      context = put_in(ready_context().reconcile.reindex.task_state, value)
      assert {:blocked, :target_unobserved} = PromotionEligibility.evaluate(context)
    end
  end

  test "missing and unknown cutover states require a current reconcile report" do
    {_removed, missing} = pop_in(ready_context(), [:reconcile, :reindex, :cutover])
    assert {:blocked, :reconcile_not_current} = PromotionEligibility.evaluate(missing)

    for value <- [nil, :unknown, "not_started", [], %{}, 123] do
      context = put_in(ready_context().reconcile.reindex.cutover, value)
      assert {:blocked, :reconcile_not_current} = PromotionEligibility.evaluate(context)
    end
  end

  test "known task and cutover enums keep their existing outcomes" do
    for {state, expected} <- [
          {:idle, :eligible},
          {:completed, :eligible},
          {:pending, {:blocked, :reindex_pending}},
          {:failed, {:blocked, :failed_work}}
        ] do
      context = put_in(ready_context().reconcile.reindex.task_state, state)
      assert ^expected = PromotionEligibility.evaluate(context)
    end

    for {state, expected} <- [
          {:not_started, :eligible},
          {:completed, :eligible},
          {:pending, {:blocked, :cutover_pending}}
        ] do
      context = put_in(ready_context().reconcile.reindex.cutover, state)
      assert ^expected = PromotionEligibility.evaluate(context)
    end

    unobserved =
      ready_context()
      |> put_in([:reconcile, :reindex, :task_state], :idle)
      |> put_in([:reconcile, :reindex, :observed?], false)

    assert {:blocked, :target_unobserved} = PromotionEligibility.evaluate(unobserved)
  end

  test "malformed dimension entries remain contract mismatches" do
    for value <- [nil, :unknown, "matching", [], 123, %{}, %{match: "true"}] do
      context = put_in(ready_context().drift.dimensions.fields, value)
      assert {:blocked, :contract_mismatch} = PromotionEligibility.evaluate(context)
    end
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
