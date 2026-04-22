defmodule Mix.Tasks.Scrypath.Reconcile do
  use Mix.Task

  alias Scrypath.CLI.OperatorTask

  @shortdoc "Prints a report-first Scrypath reconcile view or applies one explicit action"

  @moduledoc """
  Shows a report-first reconcile view for one schema. Pass `--action` to apply one
  explicit recovery action from that report.

  ## Read next

  - [guides/golden-path.md](guides/golden-path.md) — first-hour checklist from dependencies through search.
  - [guides/sync-modes-and-visibility.md](guides/sync-modes-and-visibility.md) — authority on sync modes, eventual consistency, and operator lifecycle language.
  """

  @switches [action: :string, id: :string, target_index: :string]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, argv} = OperatorTask.parse!(args, @switches)
    schema = OperatorTask.schema_from_argv!(argv)
    runtime_opts = OperatorTask.runtime_opts(opts) ++ OperatorTask.test_operator_opts()
    operator_opts = OperatorTask.target_index_opt(opts)

    case Keyword.get(opts, :action) do
      nil ->
        run_report(schema, runtime_opts, operator_opts)

      _value ->
        run_action(schema, opts, runtime_opts, operator_opts)
    end
  end

  defp run_report(schema, runtime_opts, operator_opts) do
    case Scrypath.reconcile_sync(schema, runtime_opts ++ operator_opts) do
      {:ok, report} -> Mix.shell().info(OperatorTask.render_reconcile_report(report))
      {:error, reason} -> OperatorTask.error!("scrypath.reconcile", reason)
    end
  end

  defp run_action(schema, opts, runtime_opts, operator_opts) do
    with {:ok, report} <- Scrypath.reconcile_sync(schema, runtime_opts ++ operator_opts),
         action <- select_action(report, opts),
         resolved_runtime_opts <-
           Scrypath.Config.resolve!(
             Keyword.drop(runtime_opts, [:meilisearch_tasks, :oban_jobs, :oban_inspector])
           ),
         {:ok, result} <-
           Scrypath.reconcile_sync(schema, resolved_runtime_opts ++ [action: action]) do
      Mix.shell().info(OperatorTask.render_action_result(action.kind, result))
    else
      {:error, reason} -> OperatorTask.error!("scrypath.reconcile", reason)
    end
  end

  defp select_action(report, opts) do
    case OperatorTask.action!(opts) do
      :retry -> OperatorTask.retry_action_from_report!(report, OperatorTask.id!(opts))
      kind -> OperatorTask.repair_action_from_report!(report, kind)
    end
  end
end
