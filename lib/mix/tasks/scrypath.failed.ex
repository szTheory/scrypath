defmodule Mix.Tasks.Scrypath.Failed do
  use Mix.Task

  alias Scrypath.CLI.OperatorTask

  @shortdoc "Lists failed or retrying sync work for one Scrypath schema"

  @moduledoc """
  Lists Scrypath-owned failed-work entries for one searchable schema.
  """

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, argv} = OperatorTask.parse!(args)
    schema = OperatorTask.schema_from_argv!(argv)

    case Scrypath.failed_sync_work(
           schema,
           OperatorTask.runtime_opts(opts) ++ OperatorTask.test_operator_opts()
         ) do
      {:ok, failed_work} -> Mix.shell().info(OperatorTask.render_failed_work(schema, failed_work))
      {:error, reason} -> OperatorTask.error!("scrypath.failed", reason)
    end
  end
end
