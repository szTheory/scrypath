defmodule Mix.Tasks.Verify.Phase112 do
  @moduledoc false
  use Mix.Task

  @shortdoc "Runs public website and docs truth alignment checks (Phase 112)"

  @focused_tests [
    "test/scrypath/phase112_contract_test.exs",
    "test/mix/tasks/verify.phase112_test.exs"
  ]

  @impl true
  def run(args) do
    ensure_no_args!(args)
    Mix.Task.run("app.start")

    Mix.shell().info("==> verify.phase112: public website and docs truth alignment checks")
    run_test!(@focused_tests, "Phase 112 public website and docs truth alignment verification")
  end

  defp run_test!(args, label) do
    Mix.shell().info("==> Running #{label}")
    Mix.Task.reenable("test")
    Mix.Task.run("test", args)
  end

  defp ensure_no_args!([]), do: :ok

  defp ensure_no_args!(args) do
    Mix.raise("verify.phase112 does not accept arguments, got: #{Enum.join(args, " ")}")
  end
end
