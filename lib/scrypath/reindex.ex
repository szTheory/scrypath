defmodule Scrypath.Reindex do
  @moduledoc false

  require Logger

  alias Scrypath.Meilisearch.Settings
  alias Scrypath.Meilisearch.Tasks
  alias Scrypath.Operations
  alias Scrypath.Options
  alias Scrypath.Operations.Result
  alias Scrypath.Operations.Task, as: OperationTask

  @meilisearch_default_ranking_rules [:words, :typo, :proximity, :attribute, :sort, :exactness]

  @spec run(module(), keyword()) :: {:ok, map()} | {:error, term()}
  def run(schema_module, opts \\ []) do
    :ok = enforce_ranking_rules_strict!(schema_module)

    meilisearch = Keyword.get(opts, :meilisearch, Scrypath.Meilisearch)
    backfill = Keyword.get(opts, :backfill, Scrypath.Backfill)

    {test_client_extras, rest} = Keyword.split(opts, [:__get_settings_response__])
    dropped = Keyword.drop(rest, [:meilisearch, :backfill])
    config = dropped |> Options.validate_reindex_options!() |> Keyword.merge(test_client_extras)

    backend = Keyword.fetch!(config, :backend)
    live_index = backend.index_name(schema_module, config)
    target_index = Keyword.get(config, :target_index) || "#{live_index}__reindex"

    workflow_config =
      config
      |> Keyword.put(:target_index, target_index)
      |> Keyword.put(:_scrypath_schema, schema_module)

    with {:ok, create_result} <-
           meilisearch.create_index(schema_module, primary_key(schema_module), workflow_config),
         {:ok, _create_result} <- maybe_wait_for_result_task(create_result, workflow_config),
         {:ok, settings_result} <-
           meilisearch.apply_settings(schema_module, target_index, workflow_config),
         {:ok, _settings_result} <- maybe_wait_for_result_task(settings_result, workflow_config),
         :ok <- maybe_verify_settings(schema_module, target_index, workflow_config),
         {:ok, backfill_result} <-
           backfill.run(
             schema_module,
             workflow_config
             |> backfill_config()
             |> Keyword.put(:index_name, target_index)
           ),
         {:ok, _backfill_result} <-
           maybe_wait_for_backfill_tasks(backfill_result, workflow_config),
         {:ok, cutover} <- maybe_cutover(schema_module, workflow_config, meilisearch) do
      {:ok,
       %{
         live_index: live_index,
         target_index: target_index,
         settings_applied: true,
         batches: Map.fetch!(backfill_result, :batches),
         documents: Map.fetch!(backfill_result, :documents),
         cutover: cutover
       }}
    end
  end

  defp enforce_ranking_rules_strict!(schema_module) do
    declared = Scrypath.schema_settings(schema_module)

    case Map.get(declared, :ranking_rules) do
      nil ->
        :ok

      rules when is_list(rules) ->
        if ranking_rules_strict?(declared) do
          assert_ranking_rules_cover_defaults!(rules)
        end

        :ok
    end
  end

  defp ranking_rules_strict?(declared) do
    unrec = Map.get(declared, :__unrecognized__, %{})

    cond do
      Map.get(declared, :ranking_rules_strict?) == false -> false
      Map.get(unrec, :ranking_rules_strict?) == false -> false
      Map.get(unrec, "ranking_rules_strict?") == false -> false
      true -> true
    end
  end

  defp assert_ranking_rules_cover_defaults!(rules) do
    normalized = normalized_ranking_rule_tokens(rules)
    missing = @meilisearch_default_ranking_rules -- normalized

    if missing != [] do
      raise ArgumentError,
            "[scrypath] ranking_rules is missing Meilisearch defaults: " <>
              "#{inspect(missing)}. " <>
              "Declared: #{inspect(rules)}. " <>
              "Add the missing defaults OR set settings: %{..., ranking_rules_strict?: false} on the schema to opt out."
    end
  end

  defp normalized_ranking_rule_tokens(rules) do
    Enum.flat_map(rules, fn
      r when is_atom(r) ->
        [r]

      r when is_binary(r) ->
        head = r |> String.split(":") |> List.first()

        try do
          [String.to_existing_atom(head)]
        rescue
          ArgumentError -> []
        end

      _ ->
        []
    end)
  end

  defp maybe_verify_settings(schema_module, target_index, config) do
    if Keyword.get(config, :skip_settings_verification?, false) do
      Logger.warning(
        "[scrypath] skip_settings_verification? is true; skipping post-apply drift check for #{inspect(schema_module)} (target_index=#{target_index}). Drift may go undetected until next reindex without this opt."
      )

      :telemetry.execute(
        [:scrypath, :reindex, :verify_skipped],
        %{},
        %{schema: schema_module, target_index: target_index, reason: :user_opt_out}
      )

      :ok
    else
      Scrypath.Telemetry.span(
        [:scrypath, :reindex, :settings_verified],
        %{schema: schema_module, target_index: target_index},
        fn ->
          result = Settings.verify_applied(schema_module, target_index, config)
          {result, %{result: verify_result_tag(result)}}
        end
      )
    end
  end

  defp verify_result_tag(:ok), do: :parity
  defp verify_result_tag({:error, {:settings_drift, _}}), do: :drift
  defp verify_result_tag({:error, :index_not_found}), do: :index_not_found
  defp verify_result_tag({:error, _}), do: :other_error

  defp maybe_cutover(schema_module, config, meilisearch) do
    if Keyword.get(config, :cutover?) do
      case meilisearch.swap_indexes(schema_module, config) do
        {:ok, result} ->
          case maybe_wait_for_result_task(result, config) do
            {:ok, _waited} -> {:ok, true}
            {:error, reason} -> {:error, reason}
          end

        {:error, reason} ->
          {:error, reason}
      end
    else
      {:ok, false}
    end
  end

  defp maybe_wait_for_result_task(result, config) do
    case followable_task(result) do
      %OperationTask{source: :meilisearch} = task ->
        wait_for_result_task(result, task, config)

      %OperationTask{} ->
        {:ok, result}

      nil ->
        {:ok, result}
    end
  end

  defp wait_for_result_task(result, task, config) do
    case Tasks.wait_for_task(task, config) do
      {:ok, waited_task} -> {:ok, put_followable_task(result, waited_task)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp maybe_wait_for_backfill_tasks(%{batch_results: batch_results} = result, config)
       when is_list(batch_results) do
    batch_results
    |> Enum.reduce_while({:ok, []}, fn batch_result, {:ok, acc} ->
      case maybe_wait_for_result_task(batch_result, config) do
        {:ok, waited_batch_result} -> {:cont, {:ok, [waited_batch_result | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, waited_batch_results} ->
        {:ok, %{result | batch_results: Enum.reverse(waited_batch_results)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp maybe_wait_for_backfill_tasks(result, _config), do: {:ok, result}

  defp followable_task(%Result{task: %OperationTask{} = task}), do: task
  defp followable_task(%{task: %OperationTask{} = task}), do: task

  defp followable_task(%{task: task}) when is_map(task),
    do: Operations.task_from_backend(task, source: :meilisearch)

  defp followable_task(_result), do: nil

  defp put_followable_task(%Result{} = result, task), do: %{result | task: task}
  defp put_followable_task(result, task) when is_map(result), do: %{result | task: task}

  # Reindex workflow config carries keys that only apply to managed reindex
  # (settings, verify skips, internal schema pointer). Backfill validates a
  # smaller option surface — pass only what `Options.validate_backfill_options!/1` allows.
  @backfill_pass_through_keys [
    :backend,
    :repo,
    :batch_size,
    :query,
    :index_prefix,
    :index_name,
    :meilisearch_url,
    :meilisearch_api_key,
    :meilisearch_client,
    :req_options,
    :inline_poll_interval,
    :inline_timeout,
    :sync_mode
  ]

  defp backfill_config(config) do
    Keyword.take(config, @backfill_pass_through_keys)
  end

  defp primary_key(schema_module) do
    case schema_module.__schema__(:primary_key) do
      [field | _rest] -> field
      [] -> Scrypath.document_id_field(schema_module)
    end
  end
end
