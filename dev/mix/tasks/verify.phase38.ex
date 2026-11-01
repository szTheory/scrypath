defmodule Mix.Tasks.Verify.Phase38 do
  @moduledoc false
  use Mix.Task

  @shortdoc "Runs scoped facet search (`search_within_facet/4`) and Meilisearch query encoding tests"

  @focused_tests [
    "test/scrypath/search_within_facet_test.exs",
    "test/scrypath/meilisearch/query_test.exs",
    "test/scrypath/docs_contract_test.exs"
  ]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    ensure_no_args!(args)

    run_test!(@focused_tests, "Phase 38 search within facet verification")
  end

  defp run_test!(args, label) do
    Mix.shell().info("==> Running #{label}")
    Mix.Task.reenable("test")
    Mix.Task.run("test", args)
  end

  defp ensure_no_args!([]), do: :ok

  defp ensure_no_args!(args) do
    Mix.raise("verify.phase38 does not accept arguments, got: #{Enum.join(args, " ")}")
  end
end
