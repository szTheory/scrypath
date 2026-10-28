defmodule Mix.Tasks.Verify.Phase94 do
  @moduledoc false
  use Mix.Task

  @shortdoc "Runs focused tenant-safety + docs-contract verification (Phase 94)"

  @focused_tests [
    "test/scrypath/schema_test.exs",
    "test/scrypath/options_test.exs",
    "test/scrypath/projection_test.exs",
    "test/scrypath/metadata_test.exs",
    "test/scrypath/docs_contract_test.exs"
  ]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    ensure_no_args!(args)

    run_test!(@focused_tests, "Phase 94 tenant-safety + docs-contract verification")

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
    Mix.raise("verify.phase94 does not accept arguments, got: #{Enum.join(args, " ")}")
  end
end
