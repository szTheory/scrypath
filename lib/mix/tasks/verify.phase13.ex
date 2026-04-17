defmodule Mix.Tasks.Verify.Phase13 do
  use Mix.Task

  @shortdoc "Runs operator API and integration checks (optional live Meilisearch)"

  @moduledoc """
  Runs the focused operator verification flow.

  By default this includes:

  - focused operator contract tests
  - docs contract tests covering explicit recovery wording
  - `mix docs --warnings-as-errors`
  - optional live Meilisearch operator smoke verification

  Pass `--skip-integration` to run everything except the live backend suite.
  """

  @focused_tests [
    "test/scrypath/operator/status_test.exs",
    "test/scrypath/operator/failed_work_test.exs",
    "test/scrypath/operator/reconcile_test.exs",
    "test/scrypath/meilisearch/tasks_test.exs",
    "test/scrypath/operations_test.exs",
    "test/scrypath/oban/enqueue_test.exs",
    "test/scrypath/oban/worker_test.exs",
    "test/scrypath/reindex_test.exs",
    "test/scrypath/docs_contract_test.exs"
  ]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _argv, _invalid} =
      OptionParser.parse(args,
        strict: [skip_integration: :boolean]
      )

    run_test!(@focused_tests, "focused operator tests")

    Mix.shell().info("==> Building docs with warnings as errors")
    Mix.Task.reenable("docs")
    Mix.Task.run("docs", ["--warnings-as-errors"])

    unless opts[:skip_integration] do
      ensure_integration_env!()

      run_test!(
        ["--include", "integration", "test/scrypath/live_operator_verification_test.exs"],
        "live Meilisearch operator verification"
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
      SCRYPATH_MEILISEARCH_URL is required for live operator integration verification.

      Example:
        SCRYPATH_INTEGRATION=1 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix verify.phase13
      """)
    end

    System.put_env("SCRYPATH_INTEGRATION", "1")
  end
end
