defmodule Mix.Tasks.Verify.Phase99 do
  @moduledoc false
  use Mix.Task

  @shortdoc "Runs phase99 trust checks, including phase100 install/release, phase101 compatibility-truth closure, and phase111 advisory-proof stability contract"

  @focused_tests [
    "test/scrypath/phase99_contract_test.exs",
    "test/scrypath/phase111_contract_test.exs",
    "test/mix/tasks/verify.phase99_test.exs",
    "test/mix/tasks/workflow_wiring_test.exs"
  ]

  @impl true
  def run(args) do
    ensure_no_args!(args)
    verify!(docs?: true)
  end

  @doc false
  def run_without_docs do
    verify!(docs?: false)
  end

  defp verify!(opts) do
    Mix.Task.run("app.start")

    Mix.shell().info(
      "==> verify.phase99: drift-gate trust lane with phase100 install/release, phase101 compatibility-truth closure, and phase111 advisory-proof stability contract checks"
    )

    run_test!(@focused_tests, "Phase 99 trust-hardening verification")

    if opts[:docs?] do
      Mix.shell().info("==> Building docs with warnings as errors")
      Mix.Task.reenable("docs")
      Mix.Task.run("docs", ["--warnings-as-errors"])
    end
  end

  defp run_test!(args, label) do
    Mix.shell().info("==> Running #{label}")
    Mix.Task.reenable("test")
    Mix.Task.run("test", args)
  end

  defp ensure_no_args!([]), do: :ok

  defp ensure_no_args!(args) do
    Mix.raise("verify.phase99 does not accept arguments, got: #{Enum.join(args, " ")}")
  end
end
