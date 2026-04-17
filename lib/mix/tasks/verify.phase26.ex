defmodule Mix.Tasks.Verify.Phase26 do
  @moduledoc false
  use Mix.Task

  @shortdoc "Runs the automated Phase 26 operator failure rollups (OPS14-01) verification flow"

  @focused_tests [
    "test/scrypath/operator/failed_work_test.exs",
    "test/scrypath/operator/reconcile_test.exs",
    "test/scrypath/mix_tasks/operator_tasks_test.exs",
    "test/scrypath/docs_contract_test.exs"
  ]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    ensure_no_args!(args)

    run_test!(
      @focused_tests ++ ["--warnings-as-errors"],
      "Phase 26 failed-work rollups, reconcile, operator Mix, and docs contract tests"
    )

    Mix.shell().info("==> Building docs with warnings as errors")
    Mix.Task.reenable("docs")
    Mix.Task.run("docs", ["--warnings-as-errors"])
  end

  defp run_test!(args, label) do
    Mix.shell().info("==> Running #{label}")
    Mix.Task.reenable("test")
    Mix.Task.run("test", args)
  end

  defp ensure_no_args!([]), do: :ok

  defp ensure_no_args!(args) do
    Mix.raise("verify.phase26 does not accept arguments, got: #{Enum.join(args, " ")}")
  end
end
