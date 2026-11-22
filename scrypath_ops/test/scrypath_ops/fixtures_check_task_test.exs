defmodule ScrypathOps.FixturesCheckTaskTest do
  @moduledoc false
  # Phase 196: `mix scrypath_fixtures.check_fixtures` must run without a database and must run
  # first in the ops `test` alias, before the nav contract and before `ecto.create`. Both are
  # proven here through a real child `mix`, with `PGPORT=1` so that nothing is listening.
  #
  # Synchronous on purpose, and for the same reason as `mix/saved_searches_validate_test.exs`: the
  # child `mix` compiles into this run's build directory, and on a fresh build it can delete the
  # `.beam` files of modules that depend on `scrypath` at compile time for a moment. An async test
  # that lazily loads one of them in that window fails with "module is not available". The guard
  # at the end of that file reads every file that calls `System.cmd("mix"`, this one included.
  use ExUnit.Case, async: false

  @moduletag timeout: 180_000

  @ops_root Path.expand("../..", __DIR__)

  # The nonexistent test path means that, even if a database were reachable, the inner `test` task
  # would stop at once instead of running the whole suite a second time.
  @missing_test_file "test/does_not_exist_test.exs"

  test "mix scrypath_fixtures.check_fixtures runs with no database and prints the registered count" do
    count = length(ScrypathFixtures.Scenarios.all(ScrypathFixtures.preview_epoch()))

    assert {output, 0} = mix(["scrypath_fixtures.check_fixtures"])
    assert output =~ "Fixtures OK: #{count} scenario(s)"
  end

  test "mix test checks the fixtures first, the nav contract second, and only then reaches the database" do
    assert {output, status} = mix(["test", @missing_test_file])
    assert status != 0

    assert {fixtures_at, _} = :binary.match(output, "Fixtures OK")
    assert {nav_at, _} = :binary.match(output, "Nav contract OK")
    assert {refused_at, _} = :binary.match(output, "econnrefused")

    assert fixtures_at < nav_at,
           "the fixtures check should print before the nav contract:\n#{output}"

    assert nav_at < refused_at,
           "the nav contract should print before the first connection error:\n#{output}"

    # positive control: PGPORT=1 really did remove the database, so reaching `ecto.create` failed
    # instead of passing silently, and the two checks above ran without one
    assert output =~ "The database for ScrypathOps.Repo couldn't be created"
  end

  defp mix(args) do
    System.cmd("mix", args,
      cd: @ops_root,
      env: [{"PGPORT", "1"}, {"MIX_ENV", "test"}],
      stderr_to_stdout: true
    )
  end
end
