defmodule Scrypath.Operator.FailedWork.Retrieval do
  @moduledoc false

  alias Scrypath.Config
  alias Scrypath.Meilisearch.Tasks
  alias Scrypath.Oban.Inspect

  @spec fetch(module(), keyword(), keyword()) ::
          {:ok, %{backend_tasks: [map()], queue_jobs: [map()]}} | {:error, term()}
  def fetch(schema_module, config, operator_opts) do
    backend = Config.fetch_backend!(config)
    index = backend.index_name(schema_module, config)

    with {:ok, backend_tasks} <- backend_tasks(config, operator_opts, index),
         {:ok, queue_jobs} <- queue_jobs(schema_module, config, operator_opts) do
      {:ok, %{backend_tasks: backend_tasks, queue_jobs: queue_jobs}}
    end
  end

  defp backend_tasks(config, operator_opts, index) do
    case Config.fetch_backend!(config) do
      Scrypath.Meilisearch ->
        task_config =
          Keyword.merge(
            config,
            Keyword.take(operator_opts, [:meilisearch_tasks, :task_history_limit])
          )

        Tasks.list_sync_tasks(index, task_config)

      backend ->
        {:error, {:unsupported_operator_backend, backend}}
    end
  end

  defp queue_jobs(schema_module, config, operator_opts) do
    case Keyword.fetch!(config, :sync_mode) do
      :oban ->
        inspect_config =
          Keyword.merge(config, Keyword.take(operator_opts, [:oban_jobs, :oban_inspector]))

        Inspect.list_jobs(schema_module, inspect_config)

      _ ->
        {:ok, []}
    end
  end
end
