defmodule Mix.Tasks.Verify.Phase108 do
  @moduledoc false
  use Mix.Task

  @shortdoc "Runs truth alignment and closeout proof checks (Phase 108)"

  # task runs only the phase108 contract suite and task self-test
  @focused_tests [
    "test/scrypath/phase108_contract_test.exs",
    "test/mix/tasks/verify.phase108_test.exs"
  ]

  @impl true
  def run(args) do
    ensure_no_args!(args)
    Mix.Task.run("app.start")

    Mix.shell().info("==> verify.phase108: truth alignment and closeout proof checks")
    run_test!(@focused_tests, "Phase 108 truth alignment and closeout proof verification")
  end

  defp run_test!(args, label) do
    Mix.shell().info("==> Running #{label}")
    Mix.Task.reenable("test")
    Mix.Task.run("test", args)
  end

  defp ensure_no_args!([]), do: :ok

  defp ensure_no_args!(args) do
    Mix.raise("verify.phase108 does not accept arguments, got: #{Enum.join(args, " ")}")
  end
end
