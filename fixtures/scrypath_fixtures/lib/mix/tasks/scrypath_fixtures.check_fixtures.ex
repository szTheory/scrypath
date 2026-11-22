defmodule Mix.Tasks.ScrypathFixtures.CheckFixtures do
  @shortdoc "Checks every Scrypath fixture scenario (no database)"

  @moduledoc """
  Checks every Scrypath fixture scenario without a database.

      mix scrypath_fixtures.check_fixtures

  A thin shell over `ScrypathFixtures.Check.run/1`: it prints `Fixtures OK: <n> scenario(s)` on
  success and raises with one problem per line on failure. It starts no application and no Repo,
  so it runs first in the `scrypath_ops` `test` alias and works with the database down. Fictional
  data, development and tests only.
  """

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    case ScrypathFixtures.Check.run() do
      {:ok, %{scenarios: count}} ->
        Mix.shell().info("Fixtures OK: #{count} scenario(s)")

      {:error, problems} ->
        Mix.raise("Fixture check failed:\n" <> Enum.map_join(problems, "\n", &"  #{inspect(&1)}"))
    end
  end
end
