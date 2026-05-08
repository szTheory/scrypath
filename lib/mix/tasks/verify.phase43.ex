defmodule Mix.Tasks.Verify.Phase43 do
  @moduledoc false
  use Mix.Task

  @shortdoc "Runs focused Per-query Plane B runtime tests (Phase 43)"

  @focused_tests [
    "test/scrypath/per_query_tuning_test.exs",
    "test/scrypath/search_test.exs",
    "test/scrypath/search_many_test.exs",
    "test/scrypath/docs_contract_test.exs"
  ]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    ensure_no_args!(args)

    run_test!(@focused_tests, "Phase 43 per-query runtime verification")
  end

  defp run_test!(args, label) do
    Mix.shell().info("==> Running #{label}")
    Mix.Task.reenable("test")
    Mix.Task.run("test", args)
  end

  defp ensure_no_args!([]), do: :ok

  defp ensure_no_args!(args) do
    Mix.raise("verify.phase43 does not accept arguments, got: #{Enum.join(args, " ")}")
  end
end
