defmodule Mix.Tasks.Verify.Phase5 do
  use Mix.Task

  @shortdoc "Runs backfill, reindex, and Meilisearch integration verification"

  @moduledoc """
  Runs the focused verification flow for backfill, reindex, and Meilisearch integration.

  By default this includes:

  - focused unit/contract tests for those areas
  - `mix docs --warnings-as-errors`
  - live Meilisearch integration tests

  Pass `--skip-integration` to run everything except the live backend suite.
  """

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _argv, _invalid} =
      OptionParser.parse(args,
        strict: [skip_integration: :boolean]
      )

    run_test!(
      [
        "test/scrypath/options_test.exs",
        "test/scrypath/schema_test.exs",
        "test/scrypath/backfill_test.exs",
        "test/scrypath/meilisearch_test.exs",
        "test/scrypath/reindex_test.exs"
      ],
      "focused backfill/reindex tests"
    )

    Mix.shell().info("==> Building docs with warnings as errors")
    Mix.Task.reenable("docs")
    Mix.Task.run("docs", ["--warnings-as-errors"])

    unless opts[:skip_integration] do
      ensure_integration_env!()

      run_test!(
        ["--include", "integration", "test/scrypath/live_meilisearch_verification_test.exs"],
        "live Meilisearch verification"
      )
    end
  end

  defp run_test!(args, label) do
    Mix.shell().info("==> Running #{label}")
    Mix.Task.reenable("test")
    Mix.Task.run("test", args)
  end

  defp ensure_integration_env! do
    unless System.get_env("SCRYPATH_MEILISEARCH_URL") do
      Mix.raise("""
      SCRYPATH_MEILISEARCH_URL is required for live integration verification.

      Example:
        SCRYPATH_INTEGRATION=1 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix verify.phase5
      """)
    end

    System.put_env("SCRYPATH_INTEGRATION", "1")
  end
end
