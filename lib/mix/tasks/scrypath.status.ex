defmodule Mix.Tasks.Scrypath.Status do
  use Mix.Task

  alias Scrypath.CLI.OperatorTask

  @shortdoc "Prints sync visibility for one Scrypath schema"

  @moduledoc """
  Shows pending, failed, and last-successful sync visibility for one searchable schema.

  ## Read next

  - [guides/golden-path.md](guides/golden-path.md) — first-hour checklist from dependencies through search.
  - [guides/sync-modes-and-visibility.md](guides/sync-modes-and-visibility.md) — authority on sync modes, eventual consistency, and operator lifecycle language.
  """

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, argv} = OperatorTask.parse!(args)
    schema = OperatorTask.schema_from_argv!(argv)

    case Scrypath.sync_status(
           schema,
           OperatorTask.runtime_opts(opts) ++ OperatorTask.test_operator_opts()
         ) do
      {:ok, status} -> Mix.shell().info(OperatorTask.render_status(status))
      {:error, reason} -> OperatorTask.error!("scrypath.status", reason)
    end
  end
end
