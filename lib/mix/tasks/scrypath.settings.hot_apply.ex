defmodule Mix.Tasks.Scrypath.Settings.HotApply do
  @moduledoc """
  Applies a bounded live Meilisearch settings PATCH for one Scrypath schema.

  Only `synonyms`, `stop_words`, and `typo_tolerance` are sent (see
  **Scrypath.Meilisearch.Settings.hot_apply/3**). This mutates the **live** index.

  ## Usage

      mix scrypath.settings.hot_apply MyApp.Blog.Post --settings-file path/to/patch.json --ack-live
      mix scrypath.settings.hot_apply MyApp.Blog.Post --settings-file patch.json --ack-live \\
        --repo MyApp.Repo --index-prefix tenant

  JSON must be a single object (e.g. `{\"stopWords\": [\"the\"]}`). Prefer file
  mode with restrictive permissions (`chmod 600`) when the JSON is sensitive.

  Failures raise `Mix.Error` (same style as `scrypath.settings.read`).

  TUNE14-01.
  """

  @shortdoc "Live PATCH of allow-listed Meilisearch settings for one schema"

  use Mix.Task

  alias Scrypath.CLI.OperatorTask
  alias Scrypath.Meilisearch.Settings

  @extra_switches [ack_live: :boolean, settings_file: :string]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, argv} = OperatorTask.parse!(args, @extra_switches)
    schema = OperatorTask.schema_from_argv!(argv)

    if opts[:ack_live] != true do
      Mix.raise("live settings PATCH requires --ack-live acknowledgement")
    end

    path = opts[:settings_file]

    if is_nil(path) or path == "" do
      Mix.raise("--settings-file PATH is required")
    end

    settings_map =
      try do
        path |> File.read!() |> Jason.decode!()
      rescue
        e in Jason.DecodeError ->
          Mix.raise(Exception.message(e))
      end

    unless is_map(settings_map) do
      Mix.raise("settings JSON must be an object at the top level")
    end

    config =
      Scrypath.Config.resolve!(
        OperatorTask.runtime_opts(opts) ++ OperatorTask.test_operator_opts()
      )

    index = Scrypath.Meilisearch.index_name(schema, config)

    merged =
      Keyword.merge(config,
        acknowledge_live_index: true,
        settings: settings_map
      )

    case Settings.hot_apply(schema, index, merged) do
      {:ok, %{task: %{uid: uid} = task}} ->
        Mix.shell().info("task uid=#{uid} status=#{Map.get(task, :status)}")

      {:error, reason} ->
        OperatorTask.error!("scrypath.settings.hot_apply", reason)
    end
  end
end
