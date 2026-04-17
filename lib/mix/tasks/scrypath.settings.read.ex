defmodule Mix.Tasks.Scrypath.Settings.Read do
  @moduledoc """
  Reads current applied Meilisearch settings for one Scrypath schema and prints them.

  ## Usage

      mix scrypath.settings.read MyApp.Blog.Post
      mix scrypath.settings.read MyApp.Blog.Post --repo MyApp.Repo --index-prefix tenant

  TUNE-08.
  """

  @shortdoc "Prints applied Meilisearch settings for one Scrypath schema"

  use Mix.Task

  alias Scrypath.CLI.OperatorTask
  alias Scrypath.Meilisearch.Client

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, argv} = OperatorTask.parse!(args)
    schema = OperatorTask.schema_from_argv!(argv)

    config =
      Scrypath.Config.resolve!(
        OperatorTask.runtime_opts(opts) ++ OperatorTask.test_operator_opts()
      )

    index = Scrypath.Meilisearch.index_name(schema, config)

    case Client.get_settings(index, config) do
      {:ok, settings} ->
        Mix.shell().info(
          inspect(settings, pretty: true, limit: :infinity, printable_limit: :infinity)
        )

      {:error, {:http_error, 404, _}} ->
        OperatorTask.error!("scrypath.settings.read", :index_not_found)

      {:error, reason} ->
        OperatorTask.error!("scrypath.settings.read", reason)
    end
  end
end
