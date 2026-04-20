defmodule Mix.Tasks.Verify.Phase41 do
  @moduledoc false
  use Mix.Task

  @shortdoc "Runs federation docs + doc contract verification (Phase 41)"

  @focused_tests [
    "test/scrypath/docs_contract_test.exs"
  ]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    ensure_no_args!(args)

    run_test!(@focused_tests, "Phase 41 federation docs verification")
  end

  defp run_test!(args, label) do
    Mix.shell().info("==> Running #{label}")
    Mix.Task.reenable("test")
    Mix.Task.run("test", args)
  end

  defp ensure_no_args!([]), do: :ok

  defp ensure_no_args!(args) do
    Mix.raise("verify.phase41 does not accept arguments, got: #{Enum.join(args, " ")}")
  end
end
