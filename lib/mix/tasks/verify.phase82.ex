defmodule Mix.Tasks.Verify.Phase82 do
  @moduledoc false
  use Mix.Task

  @shortdoc "Runs focused request-edge docs/examples verification (Phase 82)"

  @focused_tests [
    "test/scrypath/query_params_test.exs",
    "test/scrypath/phoenix_test.exs",
    "test/support/docs/phoenix_examples_test.exs",
    "test/support/docs/phoenix_request_shape_smoke_test.exs",
    "test/scrypath/docs_contract_test.exs"
  ]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    ensure_no_args!(args)

    run_test!(@focused_tests, "Phase 82 request-edge docs/examples verification")

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
    Mix.raise("verify.phase82 does not accept arguments, got: #{Enum.join(args, " ")}")
  end
end
