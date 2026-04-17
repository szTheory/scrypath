defmodule Mix.Tasks.Verify.MeilisearchSmoke do
  use Mix.Task

  @shortdoc "Runs live Meilisearch integration smoke tests (curated list)"

  @moduledoc """
  Runs a **fixed** set of `@moduletag :integration` suites against a real Meilisearch.

  Each file runs in a **separate** `mix test` process: the suites share the named
  `IntegrationRepo` process; a single multi-file ExUnit run can interleave modules
  and race repo lifecycle (see `MeilisearchIntegration.cleanup_repo!/1`).

  Use in CI (GitHub Actions service) or locally with Docker Compose (see README).

  Pass `--skip-integration` to exit successfully without running live tests (not
  used in CI).

  ## Environment

  - `SCRYPATH_MEILISEARCH_URL` — required unless `--skip-integration`
  - `SCRYPATH_INTEGRATION` — set to `1` automatically when live tests run
  """

  @integration_tests [
    "test/scrypath/live_meilisearch_verification_test.exs",
    "test/scrypath/live_operator_verification_test.exs",
    "test/scrypath/search_many_integration_test.exs",
    "test/scrypath/meilisearch/settings_hot_apply_integration_test.exs"
  ]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _argv, _invalid} =
      OptionParser.parse(args, strict: [skip_integration: :boolean])

    if opts[:skip_integration] do
      Mix.shell().info("==> Skipping Meilisearch smoke (--skip-integration)")
    else
      ensure_integration_env!()

      # One file per `mix test` invocation: each suite uses the shared
      # `IntegrationRepo` name; running multiple integration modules in one ExUnit
      # run can schedule their `setup_all` callbacks concurrently and races the
      # singleton repo (see MeilisearchIntegration.setup_repo!/0).
      Mix.shell().info("==> Running Meilisearch integration smoke")

      for path <- @integration_tests do
        Mix.shell().info("==>   #{path}")
        Mix.Task.reenable("test")
        Mix.Task.run("test", ["--include", "integration", path])
      end
    end
  end

  defp ensure_integration_env! do
    unless System.get_env("SCRYPATH_MEILISEARCH_URL") do
      Mix.raise("""
      SCRYPATH_MEILISEARCH_URL is required for Meilisearch smoke verification.

      Example:
        SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix verify.meilisearch_smoke

      With Docker Compose (from repo root):
        docker compose up -d
        SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix verify.meilisearch_smoke
      """)
    end

    System.put_env("SCRYPATH_INTEGRATION", "1")
  end
end
