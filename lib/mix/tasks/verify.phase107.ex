defmodule Mix.Tasks.Verify.Phase107 do
  @moduledoc false
  use Mix.Task

  @shortdoc "Runs focused ecommerce readiness regression checks (Phase 107)"

  @focused_tests [
    "examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/e2e_controller_test.exs",
    "test/mix/tasks/verify.phase107_test.exs"
  ]

  @impl true
  def run(args) do
    ensure_no_args!(args)
    Mix.Task.run("app.start")

    Mix.shell().info("==> verify.phase107: ecommerce readiness regression checks")
    [ecommerce_test, task_test] = @focused_tests
    run_ecommerce_test!(ecommerce_test)

    run_test!(
      [task_test],
      "Phase 107 ecommerce readiness regression guard"
    )
  end

  defp run_test!(args, label) do
    Mix.shell().info("==> Running #{label}")
    Mix.Task.reenable("test")
    Mix.Task.run("test", args)
  end

  defp run_ecommerce_test!(path) do
    app_path = "examples/scrypath_ecommerce"
    test_path = String.replace_prefix(path, "#{app_path}/", "")

    Mix.shell().info("==> Running Phase 107 ecommerce readiness regression guard")

    {out, status} =
      System.cmd("mix", ["test", test_path],
        cd: app_path,
        stderr_to_stdout: true
      )

    Mix.shell().info(out)

    if status != 0 do
      Mix.raise("verify.phase107 ecommerce test failed with status #{status}")
    end
  end

  defp ensure_no_args!([]), do: :ok

  defp ensure_no_args!(args) do
    Mix.raise("verify.phase107 does not accept arguments, got: #{Enum.join(args, " ")}")
  end
end
