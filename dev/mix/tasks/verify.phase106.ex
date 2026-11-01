defmodule Mix.Tasks.Verify.Phase106 do
  @moduledoc false
  use Mix.Task

  @shortdoc "Runs focused fan-out reflection contract checks (Phase 106)"

  @focused_tests [
    "test/scrypath/schema_test.exs",
    "test/scrypath/sync/related_test.exs",
    "test/scrypath/sync/related_worker_test.exs",
    "test/mix/tasks/verify.phase106_test.exs"
  ]

  @impl true
  def run(args) do
    ensure_no_args!(args)
    Mix.Task.run("app.start")

    Mix.shell().info("==> verify.phase106: fan-out reflection contract checks")
    run_test!(@focused_tests, "Phase 106 fan-out reflection contract verification")
  end

  defp run_test!(args, label) do
    Mix.shell().info("==> Running #{label}")
    Mix.Task.reenable("test")
    Mix.Task.run("test", args)
  end

  defp ensure_no_args!([]), do: :ok

  defp ensure_no_args!(args) do
    Mix.raise("verify.phase106 does not accept arguments, got: #{Enum.join(args, " ")}")
  end
end
