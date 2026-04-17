defmodule Mix.Tasks.Verify.Phase20 do
  @moduledoc false
  use Mix.Task

  @shortdoc "Runs faceting, Meilisearch settings, Phoenix guide examples, and ExDoc strict build"

  @focused_tests [
    "test/scrypath/options_test.exs",
    "test/scrypath/schema_test.exs",
    "test/scrypath/search_test.exs",
    "test/scrypath/meilisearch/query_test.exs",
    "test/scrypath/meilisearch/settings_test.exs",
    "test/scrypath/backend_test.exs",
    "test/scrypath/docs_contract_test.exs",
    "test/support/docs/phoenix_examples_test.exs"
  ]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    ensure_no_args!(args)

    run_test!(@focused_tests, "Faceting, settings, and docs contract tests")

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
    Mix.raise("verify.phase20 does not accept arguments, got: #{Enum.join(args, " ")}")
  end
end
