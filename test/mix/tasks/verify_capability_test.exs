defmodule Mix.Tasks.Verify.CapabilityTest do
  use ExUnit.Case, async: true

  @strict_tasks [
    "verify.package",
    "verify.repository_contracts",
    "verify.compatibility",
    "verify.deep_quality",
    "verify.ecommerce_mounted",
    "verify.phoenix_example",
    "verify.ops_ui",
    "verify.ecommerce_e2e"
  ]

  test "strict canonical capabilities reject stray arguments before dispatch" do
    Enum.each(@strict_tasks, fn task ->
      assert_raise Mix.Error, ~r/does not accept arguments/, fn ->
        Mix.Task.reenable(task)
        Mix.Task.run(task, ["stray"])
      end
    end)
  end

  test "backend accepts only its documented integration opt-out" do
    assert_raise Mix.Error, ~r/accepts only --skip-integration/, fn ->
      Mix.Task.reenable("verify.backend")
      Mix.Task.run("verify.backend", ["stray"])
    end
  end

  test "canonical task modules cover the locked capability vocabulary" do
    for task <- [
          "core",
          "package",
          "repository_contracts",
          "backend",
          "compatibility",
          "deep_quality",
          "ecommerce_mounted",
          "phoenix_example",
          "ops_ui",
          "ecommerce_e2e"
        ] do
      path =
        if task == "ops_ui" do
          Scrypath.RepoTooling.task_path("verify.ops_ui.ex")
        else
          Scrypath.RepoTooling.task_path("verify/#{task}.ex")
        end

      assert File.exists?(path)
      assert Mix.Task.get("verify.#{task}")
    end
  end

  test "Phoenix package mode accepts its two documented switches only" do
    for args <- [["--unknown"], ["stray"], ["--keep-temp-on-failure"]] do
      assert_raise Mix.Error, ~r/does not accept arguments/, fn ->
        Mix.Tasks.Verify.Capability.run(:phoenix_example, args)
      end
    end
  end

  test "canonical capabilities select the test environment before dispatch" do
    preferred_envs = Scrypath.MixProject.cli()[:preferred_envs]

    for task <- ["verify.core", "verify.backend", "verify.postgres" | @strict_tasks] do
      assert preferred_envs[String.to_existing_atom(task)] == :test
    end
  end

  test "every maintainer Mix.Task has a :test preferred env and every verify key resolves" do
    preferred_envs = Scrypath.MixProject.cli()[:preferred_envs]

    {:ok, modules} = :application.get_key(:scrypath, :modules)

    # Classify by the Mix.Task behaviour, not Mix.Task.task?/1: the latter also
    # counts helper modules such as Mix.Tasks.Verify.PhoenixExample.Package.
    maintainer_tasks =
      for module <- modules,
          String.starts_with?(Atom.to_string(module), "Elixir.Mix.Tasks.Verify"),
          Code.ensure_loaded?(module),
          Mix.Task in Keyword.get(module.module_info(:attributes), :behaviour, []) do
        Mix.Task.task_name(module)
      end

    assert maintainer_tasks != [], "no Mix.Tasks.Verify* module declares the Mix.Task behaviour"

    for name <- maintainer_tasks do
      assert preferred_envs[String.to_atom(name)] == :test,
             "#{name} is a maintainer task without a :test entry in mix.exs preferred_envs"
    end

    for {key, _env} <- preferred_envs, String.starts_with?(Atom.to_string(key), "verify") do
      assert Mix.Task.get(Atom.to_string(key)),
             "preferred_envs key #{key} does not resolve through Mix.Task.get/1"
    end
  end

  test "core runs the root gate then the no-optional-deps build" do
    {task_runner, calls} = recording_task_runner()

    assert :ok =
             Mix.Tasks.Verify.Capability.run_core(["--exclude", "integration"],
               task_runner: task_runner
             )

    assert calls.() == [
             {:task, "verify", ["--exclude", "integration"]},
             {:task, "verify.no_optional_deps", []}
           ]
  end

  test "standalone deep quality audits once and shares every other quality check" do
    assert_deep_quality_sequence(&Mix.Tasks.Verify.Capability.run_deep_quality_with_audit/1, [
      {:task, "verify.no_optional_deps", []},
      {:task, "verify.namespace_fence", []},
      {:command, "hex.audit", []},
      {:command, "dialyzer", []}
    ])
  end

  test "the internal no-audit path retains quality checks without auditing" do
    assert_deep_quality_sequence(&Mix.Tasks.Verify.Capability.run_deep_quality_without_audit/1, [
      {:task, "verify.no_optional_deps", []},
      {:task, "verify.namespace_fence", []},
      {:command, "dialyzer", []}
    ])
  end

  test "Ops verification pins the mounted dependency proof before the direct suite" do
    root = File.cwd!()

    assert {:module, Mix.Tasks.Verify.OpsUi} = Code.ensure_loaded(Mix.Tasks.Verify.OpsUi)

    assert function_exported?(Mix.Tasks.Verify.OpsUi, :verification_commands, 1),
           "verify.ops_ui must expose its ordered command plan for invocation contract tests"

    [mounted_proof, hex_bootstrap, deps_get, direct_suite] =
      apply(Mix.Tasks.Verify.OpsUi, :verification_commands, [root])

    assert elem(mounted_proof, 1) == [
             "test",
             "test/release/ops_dependency_boundary_test.exs",
             "--warnings-as-errors"
           ]

    assert elem(mounted_proof, 2) == root
    assert elem(hex_bootstrap, 1) == ["local.hex", "--force"]
    assert elem(hex_bootstrap, 2) == Path.join(root, "scrypath_ops")
    assert elem(deps_get, 1) == ["deps.get"]
    assert elem(deps_get, 2) == Path.join(root, "scrypath_ops")
    assert elem(direct_suite, 1) == ["test"]
    assert elem(direct_suite, 2) == Path.join(root, "scrypath_ops")
  end

  defp recording_task_runner do
    calls_key = {__MODULE__, make_ref()}

    task_runner = fn task, args ->
      Process.put(calls_key, Process.get(calls_key, []) ++ [{:task, task, args}])
      :ok
    end

    {task_runner, fn -> Process.get(calls_key, []) end}
  end

  defp assert_deep_quality_sequence(run, expected) do
    calls_key = {__MODULE__, make_ref()}

    task_runner = fn task, args ->
      Process.put(calls_key, Process.get(calls_key, []) ++ [{:task, task, args}])
      :ok
    end

    command_runner = fn command, args ->
      Process.put(calls_key, Process.get(calls_key, []) ++ [{:command, command, args}])
      :ok
    end

    assert :ok = run.(task_runner: task_runner, command_runner: command_runner)
    assert Process.get(calls_key) == expected
  end
end
