defmodule ScrypathOps.Test.FixtureEnv do
  @moduledoc """
  Puts a `ScrypathFixtures.Scenario` into the `:scrypath_ops` application env for one test, and
  hands back a function that restores the env exactly as it was.

  App env is global to the VM, so callers must run `async: false` and register the returned
  function with `on_exit/1`. A key the scenario does not mention is deleted while the scenario is
  in effect (a scenario with no `:backend` really has no backend), then put back or deleted again
  on restore. The clock file is written from `scenario.now` so `ScrypathOps.Clock` reads the
  scenario's instant.

  Fictional data, development and tests only.
  """

  # The twelve keys ScrypathOps.Schemas.scrypath_opts/0 forwards to Scrypath.
  @scrypath_opt_keys ~w(
    backend repo meilisearch_url index_prefix sync_mode oban oban_queue
    meilisearch_api_key meilisearch_client oban_inspector meilisearch_tasks oban_jobs
  )a

  @keys [:schema_allowlist] ++ @scrypath_opt_keys ++ [:test_clock_file]

  @doc "Every app-env key `put/1` touches."
  @spec keys() :: [atom()]
  def keys, do: @keys

  @doc "Applies the scenario and returns a zero-arity function that undoes it."
  @spec put(ScrypathFixtures.Scenario.t()) :: (-> :ok)
  def put(%ScrypathFixtures.Scenario{} = scenario) do
    previous = Map.new(@keys, &{&1, Application.fetch_env(:scrypath_ops, &1)})

    clock =
      Path.join(
        System.tmp_dir!(),
        "scrypath-fixture-clock-#{System.unique_integer([:positive])}.txt"
      )

    File.write!(clock, DateTime.to_iso8601(scenario.now) <> "\n")

    Application.put_env(:scrypath_ops, :schema_allowlist, scenario.allowlist)

    for key <- @scrypath_opt_keys do
      case Keyword.fetch(scenario.scrypath_opts, key) do
        {:ok, value} -> Application.put_env(:scrypath_ops, key, value)
        :error -> Application.delete_env(:scrypath_ops, key)
      end
    end

    Application.put_env(:scrypath_ops, :test_clock_file, clock)

    fn ->
      File.rm(clock)

      for {key, result} <- previous do
        case result do
          {:ok, value} -> Application.put_env(:scrypath_ops, key, value)
          :error -> Application.delete_env(:scrypath_ops, key)
        end
      end

      :ok
    end
  end
end
