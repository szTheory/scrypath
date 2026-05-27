defmodule Mix.Tasks.Verify.Phase98 do
  @moduledoc false
  use Mix.Task

  @shortdoc "Runs surface reconciliation and adopter-flow contract checks (Phase 98)"

  @focused_tests [
    "test/scrypath/phase98_contract_test.exs",
    "test/scrypath/readiness_contract_test.exs",
    "test/scrypath/docs_contract_test.exs",
    "test/mix/tasks/verify.phase98_test.exs"
  ]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    ensure_no_args!(args)

    Mix.shell().info("==> verify.phase98: surface reconciliation and adopter-flow checks")
    run_test!(@focused_tests, "Phase 98 trust-hardening verification")

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
    Mix.raise("verify.phase98 does not accept arguments, got: #{Enum.join(args, " ")}")
  end
end
