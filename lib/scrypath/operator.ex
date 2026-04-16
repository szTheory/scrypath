defmodule Scrypath.Operator do
  @moduledoc false

  alias Scrypath.Config
  alias Scrypath.Operator.Status

  @operator_only_opts [:meilisearch_tasks, :oban_jobs, :oban_inspector]

  @spec sync_status(module(), keyword()) :: {:ok, Status.t()} | {:error, term()}
  def sync_status(schema_module, opts \\ []) do
    {operator_opts, runtime_opts} = Keyword.split(opts, @operator_only_opts)
    config = Config.resolve!(runtime_opts)
    Status.fetch(schema_module, config, operator_opts)
  end
end
