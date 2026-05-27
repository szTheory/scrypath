defmodule Mix.Tasks.Verify.Phase97 do
  @moduledoc false
  use Mix.Task

  @shortdoc "Runs canonical contract freeze and scope guard verification (Phase 97)"

  @focused_tests [
    "test/mix/tasks/verify.phase97_test.exs",
    "test/mix/tasks/workflow_wiring_test.exs",
    "test/scrypath/docs_contract_test.exs"
  ]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    ensure_no_args!(args)

    Mix.shell().info("==> verify.phase97: canonical contract freeze and scope guard checks")
    run_test!(@focused_tests, "Phase 97 trust-hardening verification")

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
    Mix.raise("verify.phase97 does not accept arguments, got: #{Enum.join(args, " ")}")
  end
end
