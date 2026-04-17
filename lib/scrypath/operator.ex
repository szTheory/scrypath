defmodule Scrypath.Operator do
  @moduledoc false

  alias Scrypath.Config
  alias Scrypath.Operator.FailedWork
  alias Scrypath.Operator.Reconcile
  alias Scrypath.Operator.RecoveryAction
  alias Scrypath.Operator.Status

  @operator_only_opts [:meilisearch_tasks, :oban_jobs, :oban_inspector, :target_index]

  @spec sync_status(module(), keyword()) :: {:ok, Status.t()} | {:error, term()}
  def sync_status(schema_module, opts \\ []) do
    {operator_opts, runtime_opts} = Keyword.split(opts, @operator_only_opts)
    config = Config.resolve!(runtime_opts)
    Status.fetch(schema_module, config, operator_opts)
  end

  @spec failed_sync_work(module(), keyword()) :: {:ok, [FailedWork.t()]} | {:error, term()}
  def failed_sync_work(schema_module, opts \\ []) do
    {operator_opts, runtime_opts} = Keyword.split(opts, @operator_only_opts)
    config = Config.resolve!(runtime_opts)
    FailedWork.list(schema_module, config, operator_opts)
  end

  @spec retry_sync_work(FailedWork.t() | RecoveryAction.t(), keyword()) ::
          {:ok, map()} | {:error, term()}
  def retry_sync_work(work_or_action, opts \\ []) do
    RecoveryAction.retry(work_or_action, opts)
  end

  @spec reconcile_sync(module(), keyword()) :: {:ok, Reconcile.t()} | {:error, term()}
  def reconcile_sync(schema_module, opts \\ []) do
    {operator_opts, runtime_opts} = Keyword.split(opts, @operator_only_opts)

    case Keyword.pop(runtime_opts, :action) do
      {nil, runtime_opts} ->
        config = Config.resolve!(runtime_opts)
        Reconcile.run(schema_module, config, operator_opts)

      {%RecoveryAction{} = action, runtime_opts} ->
        Reconcile.apply_action(action, runtime_opts)
    end
  end
end
