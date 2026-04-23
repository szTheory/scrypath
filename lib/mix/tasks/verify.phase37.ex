defmodule Mix.Tasks.Verify.Phase37 do
  @moduledoc false
  use Mix.Task

  @shortdoc "Runs Disjunctive facet count merge and query encoding tests"

  @focused_tests [
    "test/scrypath/facets/disjunctive_test.exs",
    "test/scrypath/meilisearch/query_test.exs"
  ]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    ensure_no_args!(args)

    run_test!(@focused_tests, "Phase 37 disjunctive facet counts verification")
  end

  defp run_test!(args, label) do
    Mix.shell().info("==> Running #{label}")
    Mix.Task.reenable("test")
    Mix.Task.run("test", args)
  end

  defp ensure_no_args!([]), do: :ok

  defp ensure_no_args!(args) do
    Mix.raise("verify.phase37 does not accept arguments, got: #{Enum.join(args, " ")}")
  end
end
