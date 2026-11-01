defmodule Mix.Tasks.Verify.Coverage do
  @moduledoc """
  Produces a built-in line-coverage report for the fast, service-free test suite.

  Coverage is informational: Scrypath deliberately does not enforce a percentage.
  """
  use Mix.Task

  @shortdoc "Reports informational coverage for the fast test suite"

  @impl true
  def run(args) do
    ensure_no_args!(args)

    Mix.shell().info("==> Running informational coverage (no acceptance threshold)")
    Mix.Task.reenable("test")

    Mix.Task.run("test", [
      "--cover",
      "--warnings-as-errors",
      "--exclude",
      "integration",
      "--exclude",
      "docs_contract"
    ])
  end

  defp ensure_no_args!([]), do: :ok

  defp ensure_no_args!(args) do
    Mix.raise("verify.coverage does not accept arguments, got: #{Enum.join(args, " ")}")
  end
end
