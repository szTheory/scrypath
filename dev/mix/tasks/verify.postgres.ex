defmodule Mix.Tasks.Verify.Postgres do
  use Mix.Task

  @shortdoc "Runs loader/backfill tests against a real Postgres (curated list)"

  @moduledoc """
  Runs a **fixed** set of `@moduletag :postgres` suites against a real Postgres.

  These suites prove that loader-routed backfill and full-key paging behave the
  same on Postgres as they do on the SQLite sandbox repo. Each file runs in its
  own `mix test` invocation and always receives `--include postgres`, because the
  test helper evaluates its exclude list once per VM.

  Use in CI (the `backend (required)` job provides a Postgres service) or locally
  with Docker Compose (see README).

  Pass `--skip-integration` to exit successfully without running the Postgres
  suites (not used in CI).

  ## Environment

  - `SCRYPATH_POSTGRES_URL` — required unless `--skip-integration`, for example
    `postgres://postgres:postgres@127.0.0.1:5434`

  The test database `scrypath_test<MIX_TEST_PARTITION>` on that server is dropped
  and recreated on every run. Do not point this task at a database you care about.
  """

  @postgres_tests [
    "test/scrypath/loader_backfill_postgres_test.exs"
  ]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _argv, _invalid} =
      OptionParser.parse(args, strict: [skip_integration: :boolean])

    if opts[:skip_integration] do
      Mix.shell().info("==> Skipping Postgres loader suite (--skip-integration)")
    else
      ensure_postgres_env!()

      Mix.shell().info("==> Running Postgres loader suite")

      for path <- @postgres_tests do
        Mix.shell().info("==>   #{path}")
        Mix.Task.reenable("test")
        Mix.Task.run("test", ["--include", "postgres", path])
      end
    end
  end

  defp ensure_postgres_env! do
    if System.get_env("SCRYPATH_POSTGRES_URL") in [nil, ""] do
      Mix.raise("""
      SCRYPATH_POSTGRES_URL is required for Postgres loader verification.

      Example:
        SCRYPATH_POSTGRES_URL=postgres://postgres:postgres@127.0.0.1:5434 mix verify.postgres

      With Docker Compose (from repo root):
        docker compose up -d postgres
        SCRYPATH_POSTGRES_URL=postgres://postgres:postgres@127.0.0.1:5434 mix verify.postgres
      """)
    end
  end
end
