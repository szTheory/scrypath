defmodule Mix.Tasks.Scrypath.Retry do
  use Mix.Task

  alias Scrypath.CLI.OperatorTask

  @shortdoc "Retries one explicit retryable Scrypath failed-work entry"

  @moduledoc """
  Retries one explicit failed-work entry by id using the existing Scrypath operator APIs.

  ## Read next

  - [guides/golden-path.md](guides/golden-path.md) — first-hour checklist from dependencies through search.
  - [guides/sync-modes-and-visibility.md](guides/sync-modes-and-visibility.md) — authority on sync modes, eventual consistency, and operator lifecycle language.
  """

  @switches [id: :string]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, argv} = OperatorTask.parse!(args, @switches)
    schema = OperatorTask.schema_from_argv!(argv)
    id = OperatorTask.id!(opts)
    runtime_opts = Scrypath.Config.resolve!(OperatorTask.runtime_opts(opts))
    task_opts = runtime_opts ++ OperatorTask.test_operator_opts()

    with {:ok, failed_work} <- Scrypath.failed_sync_work(schema, task_opts),
         work <- OperatorTask.find_failed_work!(failed_work, id),
         {:ok, result} <- Scrypath.retry_sync_work(work, runtime_opts) do
      Mix.shell().info(OperatorTask.render_retry_result(id, result))
    else
      {:error, reason} -> OperatorTask.error!("scrypath.retry", reason)
    end
  end
end
