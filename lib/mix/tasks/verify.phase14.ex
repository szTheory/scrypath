defmodule Mix.Tasks.Verify.Phase14 do
  @moduledoc false
  use Mix.Task

  @shortdoc "Runs operator Mix tasks, docs contract, package metadata, and ExDoc strict build"

  @focused_tests [
    "test/scrypath/mix_tasks/operator_tasks_test.exs",
    "test/scrypath/docs_contract_test.exs",
    "test/release/package_metadata_test.exs"
  ]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    ensure_no_args!(args)

    run_test!(@focused_tests, "Operator Mix task and docs contract tests")

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
    Mix.raise("verify.phase14 does not accept arguments, got: #{Enum.join(args, " ")}")
  end
end
