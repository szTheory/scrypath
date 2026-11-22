defmodule ScrypathFixtures.FakeObanInspector do
  @moduledoc """
  A stand-in for an Oban job inspector that serves a scenario's job maps. The data is fictional
  and for development and tests only.

  Scrypath calls `list_jobs/2` through the `:oban_inspector` option. The jobs come from the
  `:oban_jobs` option and are scoped to the schema the way the repository's real inspector scopes
  them: a job belongs to a schema when `args["schema"]` is that module's name.
  """

  @doc "Returns the scenario's jobs for `schema_module`."
  @spec list_jobs(module(), keyword()) :: {:ok, [map()]}
  def list_jobs(schema_module, config) do
    schema = Atom.to_string(schema_module)

    jobs =
      config
      |> Keyword.get(:oban_jobs, [])
      |> Enum.filter(&(get_in(&1, [:args, "schema"]) == schema))

    {:ok, jobs}
  end
end
