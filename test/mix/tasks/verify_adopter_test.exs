defmodule Mix.Tasks.Verify.AdopterTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @phoenix_lock File.read!("examples/phoenix_meilisearch/mix.lock")
  @source_sha String.duplicate("a", 40)

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
      assert source =~ ~S|"test/scrypath/phase110_contract_test.exs"|
      assert source =~ ~S|"test/mix/tasks/verify_adopter_test.exs"|
    end

    test "help text names the current fast/live contract" do
      output =
        capture_io(fn ->
          Mix.Task.reenable("help")
          Mix.Task.run("help", ["verify.adopter"])
        end)

      assert output =~ "mix test test/scrypath/readiness_contract_test.exs"
      assert output =~ "mix test test/scrypath/phase110_contract_test.exs"
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

  describe "run_live!/1 graph contract" do
    @tag :phase168_path_guard
    test "reports the actual sorted graph and preserves the source lock" do
      {example_dir, source_lock} = example_workspace(@phoenix_lock)
      calls_key = {__MODULE__, make_ref()}
      runner = command_runner(calls_key)

      output =
        capture_io(fn ->
          assert :ok =
                   Mix.Tasks.Verify.Adopter.run_live!(
                     example_dir: example_dir,
                     command_runner: runner,
                     service_check: fn -> :ok end
                   )
        end)

      expected_hash = :crypto.hash(:sha256, source_lock) |> Base.encode16(case: :lower)
      assert Process.get(calls_key) == [:fetch, :test]
      assert File.read!(Path.join(example_dir, "mix.lock")) == source_lock

      assert output =~
               ~r/source_sha=#{@source_sha} mode=path source_lock_sha256=#{expected_hash} resolved_lock_sha256=#{expected_hash}/

      assert output =~ ~r/packages=.*hpax@1\.1\.0.*mint@1\.11\.0/
      refute output =~ "authorization=secret"
    end

    test "lock mutation after dependency fetch prevents consumer tests" do
      {example_dir, source_lock} = example_workspace(@phoenix_lock)
      calls_key = {__MODULE__, make_ref()}

      mutated_lock =
        String.replace(
          source_lock,
          "\"mint\": {:hex, :mint, \"1.11.0\"",
          "\"mint\": {:hex, :mint, \"1.10.1\"",
          global: false
        )

      runner = command_runner(calls_key, fetch_lock: mutated_lock)

      assert_raise Mix.Error, ~r/lock bytes changed/i, fn ->
        capture_io(fn ->
          Mix.Tasks.Verify.Adopter.run_live!(
            example_dir: example_dir,
            command_runner: runner,
            service_check: fn -> :ok end
          )
        end)
      end

      assert Process.get(calls_key) == [:fetch]
      refute File.read!(Path.join(example_dir, "mix.lock")) == source_lock
    end

    test "failed fetch stops before tests while confirming lock bytes" do
      {example_dir, source_lock} = example_workspace(@phoenix_lock)
      calls_key = {__MODULE__, make_ref()}
      runner = command_runner(calls_key, fetch_status: 17)

      assert_raise Mix.Error, ~r/fetch stage:.*exited 17/i, fn ->
        capture_io(fn ->
          Mix.Tasks.Verify.Adopter.run_live!(
            example_dir: example_dir,
            command_runner: runner,
            service_check: fn -> :ok end
          )
        end)
      end

      assert Process.get(calls_key) == [:fetch]
      assert File.read!(Path.join(example_dir, "mix.lock")) == source_lock
    end

    test "failed tests retain their error when the source lock is unchanged" do
      {example_dir, source_lock} = example_workspace(@phoenix_lock)
      calls_key = {__MODULE__, make_ref()}
      runner = command_runner(calls_key, test_status: 19)

      assert_raise Mix.Error, ~r/test stage:.*exited 19/i, fn ->
        capture_io(fn ->
          Mix.Tasks.Verify.Adopter.run_live!(
            example_dir: example_dir,
            command_runner: runner,
            service_check: fn -> :ok end
          )
        end)
      end

      assert Process.get(calls_key) == [:fetch, :test]
      assert File.read!(Path.join(example_dir, "mix.lock")) == source_lock
    end

    test "failed tests still detect and report lock mutation" do
      {example_dir, source_lock} = example_workspace(@phoenix_lock)
      calls_key = {__MODULE__, make_ref()}
      mutated_lock = String.replace(source_lock, "\"1.11.0\"", "\"1.10.1\"", global: false)
      runner = command_runner(calls_key, test_status: 19, test_lock: mutated_lock)

      assert_raise Mix.Error, ~r/test stage:.*lock bytes changed/i, fn ->
        capture_io(fn ->
          Mix.Tasks.Verify.Adopter.run_live!(
            example_dir: example_dir,
            command_runner: runner,
            service_check: fn -> :ok end
          )
        end)
      end

      assert Process.get(calls_key) == [:fetch, :test]
      refute File.read!(Path.join(example_dir, "mix.lock")) == source_lock
    end

    test "missing or malformed locks fail before resolver dispatch" do
      for lock <- [nil, "%{broken"] do
        {example_dir, _source_lock} = example_workspace(lock)
        if is_nil(lock), do: File.rm!(Path.join(example_dir, "mix.lock"))
        calls_key = {__MODULE__, make_ref()}
        runner = command_runner(calls_key)

        assert_raise Mix.Error, ~r/(lock|syntax)/i, fn ->
          Mix.Tasks.Verify.Adopter.run_live!(
            example_dir: example_dir,
            command_runner: runner,
            service_check: fn -> :ok end
          )
        end

        assert Process.get(calls_key, []) == []
      end
    end

    test "service preflight blocks commands and redacts endpoint values" do
      secret_url = "http://user:secret@example.test:7700"
      original = System.get_env("SCRYPATH_MEILISEARCH_URL")
      System.put_env("SCRYPATH_MEILISEARCH_URL", secret_url)
      on_exit(restore_env("SCRYPATH_MEILISEARCH_URL", original))
      {example_dir, _source_lock} = example_workspace(@phoenix_lock)
      runner = fn _command, _args, _opts -> flunk("command ran before live service preflight") end

      output =
        capture_io(fn ->
          assert_raise Mix.Error, ~r/service preflight: services unavailable/i, fn ->
            Mix.Tasks.Verify.Adopter.run_live!(
              example_dir: example_dir,
              command_runner: runner,
              service_check: fn -> Mix.raise("services unavailable: #{secret_url}") end
            )
          end
        end)

      refute output =~ secret_url
    end
  end

  defp example_workspace(lock) do
    example_dir =
      Path.join(
        System.tmp_dir!(),
        "scrypath-adopter-proof-test-#{System.unique_integer([:positive, :monotonic])}"
      )

    File.mkdir_p!(example_dir)
    if is_binary(lock), do: File.write!(Path.join(example_dir, "mix.lock"), lock)
    on_exit(fn -> File.rm_rf!(example_dir) end)
    {example_dir, lock}
  end

  defp command_runner(calls_key, effects \\ []) do
    effects = Map.new(effects)

    fn
      "git", ["rev-parse", "HEAD"], _opts ->
        {@source_sha <> "\n", 0}

      "mix", ["deps.get", "--check-locked"], opts ->
        record_call(calls_key, :fetch)
        maybe_write_lock(opts[:cd], Map.get(effects, :fetch_lock))
        {Map.get(effects, :fetch_output, ""), Map.get(effects, :fetch_status, 0)}

      "mix", ["test"], opts ->
        record_call(calls_key, :test)
        maybe_write_lock(opts[:cd], Map.get(effects, :test_lock))
        {Map.get(effects, :test_output, ""), Map.get(effects, :test_status, 0)}
    end
  end

  defp record_call(key, call), do: Process.put(key, Process.get(key, []) ++ [call])

  defp maybe_write_lock(_example_dir, nil), do: :ok

  defp maybe_write_lock(example_dir, lock) do
    File.write!(Path.join(example_dir, "mix.lock"), lock)
  end

  defp restore_env(name, nil), do: fn -> System.delete_env(name) end
  defp restore_env(name, value), do: fn -> System.put_env(name, value) end
end
