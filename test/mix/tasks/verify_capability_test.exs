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
          "lib/mix/tasks/verify.ops_ui.ex"
        else
          "lib/mix/tasks/verify/#{task}.ex"
        end

      assert File.exists?(path)
    end
  end

  test "canonical capabilities select the test environment before dispatch" do
    preferred_envs = Scrypath.MixProject.cli()[:preferred_envs]

    for task <- ["verify.core", "verify.backend" | @strict_tasks] do
      assert preferred_envs[String.to_existing_atom(task)] == :test
    end
  end
end
