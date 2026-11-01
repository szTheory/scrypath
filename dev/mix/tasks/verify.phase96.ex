defmodule Mix.Tasks.Verify.Phase96 do
  @moduledoc false
  use Mix.Task

  @shortdoc "Runs focused facet value search verification (Phase 96)"

  @focused_tests [
    "test/scrypath/search_test.exs",
    "test/scrypath/meilisearch_test.exs",
    "test/scrypath/docs_contract_test.exs"
  ]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    ensure_no_args!(args)

    run_test!(@focused_tests, "Phase 96 facet value search verification")

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
    Mix.raise("verify.phase96 does not accept arguments, got: #{Enum.join(args, " ")}")
  end
end
