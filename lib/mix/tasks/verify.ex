defmodule Mix.Tasks.Verify do
  @moduledoc """
  The Scrypath repository maturity gate (Standard).
  Runs formatting, linting, all unit tests, and documentation verification.
  Does NOT run live integration tests by default.
  """
  use Mix.Task

  @shortdoc "Runs the standard repository maturity gate"

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    Mix.shell().info("==> [1/5] Checking formatting...")
    Mix.Task.run("format", ["--check-formatted"])

    Mix.shell().info("==> [2/5] Verifying workspace is clean...")
    Mix.Task.run("verify.workspace_clean")

    Mix.shell().info("==> [3/5] Running Credo...")
    Mix.Task.run("credo", ["--strict"])

    Mix.shell().info("==> [4/5] Running unit tests...")
    Mix.Task.reenable("test")
    Mix.Task.run("test", args)

    Mix.shell().info("==> [5/5] Building docs with warnings as errors...")
    Mix.Task.reenable("docs")
    Mix.Task.run("docs", ["--warnings-as-errors"])

    Mix.shell().info("==> Standard Maturity Gate: PASSED")
  end
end
