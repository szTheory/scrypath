defmodule Mix.Tasks.Verify.Phase28 do
  @moduledoc false
  use Mix.Task

  @shortdoc "Runs index contract drift CLI tests, operator docs contracts, and docs build (v1.5 gate)"

  @focused_tests [
    "test/scrypath/operator/index_contract_drift_test.exs",
    "test/scrypath/mix_tasks/operator_tasks_test.exs",
    "test/scrypath/docs_contract_test.exs"
  ]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    ensure_no_args!(args)

    run_test!(
      @focused_tests ++ ["--warnings-as-errors"],
      "Index contract drift, operator Mix tasks, and docs contract tests"
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
    Mix.raise("verify.phase28 does not accept arguments, got: #{Enum.join(args, " ")}")
  end
end
