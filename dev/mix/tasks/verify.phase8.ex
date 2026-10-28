defmodule Mix.Tasks.Verify.Phase8 do
  use Mix.Task

  @shortdoc "Runs reliability-focused tests with optional live Meilisearch"

  @moduledoc """
  Runs the focused reliability verification flow.

  By default this includes:

  - focused unit/contract tests for reliability paths
  - live Meilisearch integration tests

  Pass `--skip-integration` to run only the focused fast suite.
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
        "test/scrypath/meilisearch/tasks_test.exs",
        "test/scrypath/sync_test.exs",
        "test/scrypath/telemetry_test.exs"
      ],
      "focused reliability tests"
    )

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
        SCRYPATH_INTEGRATION=1 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix verify.phase8
      """)
    end

    System.put_env("SCRYPATH_INTEGRATION", "1")
  end
end
