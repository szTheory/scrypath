defmodule ScrypathOps.PromotionEligibility do
  @moduledoc false

  @spec evaluate(map()) :: :eligible | {:blocked, atom()}
  def evaluate(context) when is_map(context) do
    cond do
      not allowed_schema?(context) ->
        {:blocked, :schema_not_allowed}

      Map.get(context, :backend) != Scrypath.Meilisearch ->
        {:blocked, :unsupported_backend}

      Map.get(context, :reconcile_error) ->
        {:blocked, :reconcile_failed}

      Map.get(context, :drift_error) ->
        {:blocked, :contract_failed}

      Map.get(context, :reconcile_loading, false) or Map.get(context, :drift_loading, false) ->
        {:blocked, :check_in_progress}

      not current_generation?(context, :reconcile) ->
        {:blocked, :reconcile_not_current}

      not current_generation?(context, :drift) ->
        {:blocked, :contract_not_current}

      not is_map(Map.get(context, :reconcile)) ->
        {:blocked, :reconcile_not_current}

      not is_map(Map.get(context, :drift)) ->
        {:blocked, :contract_not_current}

      not same_context?(context) ->
        {:blocked, :context_mismatch}

      not supported_config?(context) ->
        {:blocked, :unsupported_backend}

      not indexes_distinct?(context) ->
        {:blocked, :indexes_not_distinct}

      not target_observed?(context) ->
        {:blocked, :target_unobserved}

      backend_pending?(context) ->
        {:blocked, :backend_work_pending}

      queue_pending?(context) ->
        {:blocked, :queue_work_pending}

      reindex_pending?(context) ->
        {:blocked, :reindex_pending}

      cutover_pending?(context) ->
        {:blocked, :cutover_pending}

      failed_work?(context) ->
        {:blocked, :failed_work}

      not cutover_observed?(context) ->
        {:blocked, :reconcile_not_current}

      contract_mismatch?(context) ->
        {:blocked, :contract_mismatch}

      true ->
        :eligible
    end
  end

  def evaluate(_), do: {:blocked, :reconcile_not_current}

  defp allowed_schema?(context) do
    schema = Map.get(context, :schema)
    is_atom(schema) and schema in Map.get(context, :allowlist, [])
  end

  defp supported_config?(%{opts: opts}) when is_list(opts) do
    Keyword.get(opts, :backend) == Scrypath.Meilisearch
  end

  defp supported_config?(_), do: true

  defp current_generation?(context, key) do
    generation = Map.get(context, :generation)
    report_generation = Map.get(context, String.to_existing_atom("#{key}_generation"))
    is_integer(generation) and report_generation == generation
  rescue
    ArgumentError -> false
  end

  defp same_context?(context) do
    schema = Map.get(context, :schema)
    reconcile = Map.get(context, :reconcile)
    drift = Map.get(context, :drift)

    expected_index = expected_index(context, schema)

    Map.get(reconcile, :schema) == schema and Map.get(drift, :schema) == schema and
      Map.get(reconcile, :index) == Map.get(drift, :index) and
      (is_nil(expected_index) or Map.get(reconcile, :index) == expected_index)
  end

  defp expected_index(%{opts: opts}, schema) when is_list(opts),
    do: Scrypath.Meilisearch.index_name(schema, opts)

  defp expected_index(_context, _schema), do: nil

  defp indexes_distinct?(context) do
    reindex = field(context, :reconcile, :reindex)
    live = field(reindex, :live_index)
    target = field(reindex, :target_index)
    is_binary(live) and live != "" and is_binary(target) and target != "" and live != target
  end

  defp target_observed?(context) do
    reindex = field(context, :reconcile, :reindex)

    field(reindex, :observed?) == true and
      field(reindex, :task_state) in [:pending, :completed, :failed, :idle]
  end

  defp cutover_observed?(context),
    do:
      field(field(context, :reconcile, :reindex), :cutover) in [
        :not_started,
        :pending,
        :completed
      ]

  defp backend_pending?(context),
    do: section_has?(field(context, :reconcile, :status), :backend, :pending)

  defp queue_pending?(context) do
    section_has?(field(context, :reconcile, :status), :queue, :pending) or
      section_has?(field(context, :reconcile, :status), :queue, :retrying)
  end

  defp reindex_pending?(context),
    do: Map.get(field(context, :reconcile, :reindex), :task_state) == :pending

  defp cutover_pending?(context),
    do: Map.get(field(context, :reconcile, :reindex), :cutover) == :pending

  defp failed_work?(context) do
    reconcile = Map.get(context, :reconcile)
    failed_work = Map.get(reconcile, :failed_work)
    signals = Map.get(reconcile, :drift_signals)
    status = Map.get(reconcile, :status)

    not is_list(failed_work) or failed_work != [] or not is_list(signals) or
      Enum.any?(signals, &(&1 in [:failed_sync_work, :failed_backend_work])) or
      section_has?(status, :backend, :failed) or section_has?(status, :queue, :failed) or
      Map.get(field(context, :reconcile, :reindex), :task_state) == :failed
  end

  defp contract_mismatch?(context) do
    dimensions = field(context, :drift, :dimensions)

    not (is_map(dimensions) and map_size(dimensions) > 0 and
           Enum.all?(Map.to_list(dimensions), fn {_name, dimension} ->
             field(dimension, :match) == true
           end))
  end

  defp section_has?(status, section, key) do
    values = field(status, section, key)
    not (is_list(values) and values == [])
  end

  defp field(map, key) when is_map(map), do: Map.get(map, key)
  defp field(_, _key), do: nil
  defp field(map, outer, inner) when is_map(map), do: map |> Map.get(outer, %{}) |> field(inner)
  defp field(_, _, _), do: nil
end
