defmodule Mix.Tasks.Verify.Phase36 do
  @moduledoc false
  use Mix.Task

  @shortdoc "Runs hierarchical facets, settings merge, drift, search, and doc contract tests"

  @focused_tests [
    "test/scrypath/options_test.exs",
    "test/scrypath/search_test.exs",
    "test/scrypath/meilisearch/settings_test.exs",
    "test/scrypath/operator/index_contract_drift_test.exs",
    "test/scrypath/docs_contract_test.exs"
  ]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    ensure_no_args!(args)

    run_test!(@focused_tests, "Phase 36 hierarchical facets verification")
  end

  defp run_test!(args, label) do
    Mix.shell().info("==> Running #{label}")
    Mix.Task.reenable("test")
    Mix.Task.run("test", args)
  end

  defp ensure_no_args!([]), do: :ok

  defp ensure_no_args!(args) do
    Mix.raise("verify.phase36 does not accept arguments, got: #{Enum.join(args, " ")}")
  end
end
