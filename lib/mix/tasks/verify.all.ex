defmodule Mix.Tasks.Verify.All do
  @moduledoc """
  The Scrypath master maturity gate.
  Runs all quality checks, all unit tests, and live integration smoke tests.
  """
  use Mix.Task

  @shortdoc "Runs the full maturity gate including integration tests"

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    Mix.shell().info("==> [1/6] Checking formatting...")
    Mix.Task.run("format", ["--check-formatted"])

    Mix.shell().info("==> [2/6] Verifying workspace is clean...")
    Mix.Task.run("verify.workspace_clean")

    Mix.shell().info("==> [3/6] Running Credo...")
    Mix.Task.run("credo", ["--strict"])

    Mix.shell().info("==> [4/6] Running unit tests...")
    # Reset test task to ensure it runs
    Mix.Task.reenable("test")
    Mix.Task.run("test", args)

    Mix.shell().info("==> [5/6] Running Meilisearch integration smoke...")
    Mix.Task.run("verify.meilisearch_smoke", args)

    Mix.shell().info("==> [6/6] Building docs with warnings as errors...")
    Mix.Task.reenable("docs")
    Mix.Task.run("docs", ["--warnings-as-errors"])

    Mix.shell().info("==> Repository Maturity Gate: PASSED")
  end
end
