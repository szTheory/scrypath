defmodule Scrypath.Reindex do
  @moduledoc false

  alias Scrypath.Meilisearch.Tasks
  alias Scrypath.Options

  @spec run(module(), keyword()) :: {:ok, map()} | {:error, term()}
  def run(schema_module, opts \\ []) do
    meilisearch = Keyword.get(opts, :meilisearch, Scrypath.Meilisearch)
    backfill = Keyword.get(opts, :backfill, Scrypath.Backfill)
    config = Options.validate_reindex_options!(Keyword.drop(opts, [:meilisearch, :backfill]))
    backend = Keyword.fetch!(config, :backend)
    live_index = backend.index_name(schema_module, config)
    target_index = Keyword.get(config, :target_index) || "#{live_index}__reindex"
    workflow_config = Keyword.put(config, :target_index, target_index)
    wait_for_tasks? = backend == Scrypath.Meilisearch

    with {:ok, create_result} <-
           meilisearch.create_index(schema_module, primary_key(schema_module), workflow_config),
         {:ok, _create_result} <- maybe_wait_for_result_task(create_result, workflow_config, wait_for_tasks?),
         {:ok, settings_result} <-
           meilisearch.apply_settings(schema_module, target_index, workflow_config),
         {:ok, _settings_result} <- maybe_wait_for_result_task(settings_result, workflow_config, wait_for_tasks?),
         {:ok, backfill_result} <-
           backfill.run(
             schema_module,
             workflow_config
             |> backfill_config()
             |> Keyword.put(:index_name, target_index)
           ),
         {:ok, _backfill_result} <-
           maybe_wait_for_backfill_tasks(backfill_result, workflow_config, wait_for_tasks?),
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

  defp maybe_cutover(schema_module, config, meilisearch) do
    if Keyword.get(config, :cutover?) do
      case meilisearch.swap_indexes(schema_module, config) do
        {:ok, result} ->
          case maybe_wait_for_result_task(result, config, Keyword.fetch!(config, :backend) == Scrypath.Meilisearch) do
            {:ok, _waited} -> {:ok, true}
            {:error, reason} -> {:error, reason}
          end

        {:error, reason} -> {:error, reason}
      end
    else
      {:ok, false}
    end
  end

  defp maybe_wait_for_result_task(%{task: task} = result, config, true) when is_map(task) do
    case Tasks.wait_for_task(task, config) do
      {:ok, waited_task} -> {:ok, %{result | task: waited_task}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp maybe_wait_for_result_task(result, _config, _wait_for_tasks?), do: {:ok, result}

  defp maybe_wait_for_backfill_tasks(%{batch_results: batch_results} = result, config, true)
       when is_list(batch_results) do
    batch_results
    |> Enum.reduce_while({:ok, []}, fn batch_result, {:ok, acc} ->
      case maybe_wait_for_result_task(batch_result, config, true) do
        {:ok, waited_batch_result} -> {:cont, {:ok, [waited_batch_result | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, waited_batch_results} -> {:ok, %{result | batch_results: Enum.reverse(waited_batch_results)}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp maybe_wait_for_backfill_tasks(result, _config, _wait_for_tasks?), do: {:ok, result}

  defp backfill_config(config) do
    Keyword.drop(config, [:target_index, :cutover?])
  end

  defp primary_key(schema_module) do
    case schema_module.__schema__(:primary_key) do
      [field | _rest] -> field
      [] -> Scrypath.document_id_field(schema_module)
    end
  end
end
