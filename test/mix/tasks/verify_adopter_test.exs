defmodule Mix.Tasks.Verify.AdopterTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  describe "run/1 arg guards" do
    test "raises on stray positional args" do
      assert_raise Mix.Error, ~r/verify\.adopter does not accept arguments, got: stray-arg/, fn ->
        Mix.Task.reenable("verify.adopter")
        Mix.Task.run("verify.adopter", ["stray-arg"])
      end
    end

    test "raises on unknown flags" do
      assert_raise Mix.Error, ~r/verify\.adopter does not accept arguments, got: --bogus/, fn ->
        Mix.Task.reenable("verify.adopter")
        Mix.Task.run("verify.adopter", ["--bogus"])
      end
    end

    test "raises when --fast and --live are both passed" do
      assert_raise Mix.Error, ~r/either --fast or --live, not both/, fn ->
        Mix.Task.reenable("verify.adopter")
        Mix.Task.run("verify.adopter", ["--fast", "--live"])
      end
    end
  end

  describe "run/1 live prerequisites" do
    setup do
      original =
        for key <- ["SCRYPATH_EXAMPLE_INTEGRATION", "PGPORT", "SCRYPATH_MEILISEARCH_URL"],
            into: %{} do
          {key, System.get_env(key)}
        end

      on_exit(fn ->
        Enum.each(original, fn
          {key, nil} -> System.delete_env(key)
          {key, value} -> System.put_env(key, value)
        end)
      end)

      :ok
    end

    test "raises with required env names when live prerequisites are missing" do
      System.delete_env("SCRYPATH_EXAMPLE_INTEGRATION")
      System.delete_env("PGPORT")
      System.delete_env("SCRYPATH_MEILISEARCH_URL")

      assert_raise Mix.Error,
                   ~r/SCRYPATH_EXAMPLE_INTEGRATION, PGPORT, SCRYPATH_MEILISEARCH_URL/,
                   fn ->
                     Mix.Task.reenable("verify.adopter")
                     Mix.Task.run("verify.adopter", ["--live"])
                   end
    end

    test "raises clearly when live services are unreachable" do
      System.put_env("SCRYPATH_EXAMPLE_INTEGRATION", "1")
      System.put_env("PGPORT", "9")
      System.put_env("SCRYPATH_MEILISEARCH_URL", "http://127.0.0.1:9")

      assert_raise Mix.Error,
                   ~r/verify\.adopter --live requires running Postgres and Meilisearch services.*Postgres on localhost:9, Meilisearch on 127\.0\.0\.1:9/s,
                   fn ->
                     Mix.Task.reenable("verify.adopter")
                     Mix.Task.run("verify.adopter", ["--live"])
                   end
    end
  end

  describe "run/1 fast path" do
    test "advertises the current focused fast-test files" do
      source = File.read!("lib/mix/tasks/verify.adopter.ex")

      assert source =~ ~S|"test/scrypath/readiness_contract_test.exs"|
      assert source =~ ~S|"test/mix/tasks/verify_adopter_test.exs"|
    end

    test "help text names the current fast/live contract" do
      output =
        capture_io(fn ->
          Mix.Task.reenable("help")
          Mix.Task.run("help", ["verify.adopter"])
        end)

      assert output =~ "mix test test/scrypath/readiness_contract_test.exs"
      assert output =~ "mix test test/mix/tasks/verify_adopter_test.exs"
      assert output =~ "SCRYPATH_EXAMPLE_INTEGRATION"
      assert output =~ "PGPORT"
      assert output =~ "SCRYPATH_MEILISEARCH_URL"
      assert output =~ "cd examples/phoenix_meilisearch"
      assert output =~ "mix deps.get"
      assert output =~ "mix test"
    end

    test "emits a progress marker" do
      output =
        capture_io(fn ->
          Mix.Task.reenable("verify.adopter")
          Mix.Task.run("verify.adopter", ["--fast"])
        end)

      assert output =~ ~r/verify\.adopter: running fast adopter contracts/
      assert output =~ ~r/Running fast adopter contracts/
    end
  end
end
