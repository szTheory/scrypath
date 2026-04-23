defmodule Mix.Tasks.Verify.Phase41 do
  @moduledoc false
  use Mix.Task

  @shortdoc "Runs federation and multi-search runtime verification (Phase 41)"

  @focused_tests [
    "test/scrypath/search_many_test.exs",
    "test/scrypath/multi_search/all_expansion_test.exs",
    "test/scrypath/multi_search/entries_test.exs",
    "test/scrypath/meilisearch/federated_decode_test.exs",
    "test/scrypath/meilisearch/client_multi_search_test.exs"
  ]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    ensure_no_args!(args)

    run_test!(@focused_tests, "Phase 41 federation and multi-search verification")
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
