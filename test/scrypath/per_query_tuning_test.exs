defmodule Scrypath.PerQueryTuningTest do
  use ExUnit.Case, async: true

  alias Scrypath.Meilisearch.Query, as: MeilisearchQuery
  alias Scrypath.Options
  alias Scrypath.Query

  test "per_query rejects unknown inner keys" do
    assert {:error, _} = Options.validate_search_options(SearchablePost, per_query: [bad: :key])
  end

  test "per_query ranking threshold flows into Meilisearch JSON" do
    assert {:ok, kw} =
             Options.validate_search_options(SearchablePost,
               per_query: [ranking_score_threshold: 0.5]
             )

    payload =
      "hi"
      |> Query.new(kw)
      |> MeilisearchQuery.to_payload()

    assert payload["rankingScoreThreshold"] == 0.5
  end

  test "search/3 telemetry start metadata marks ranking_score_details when enabled" do
    handler_id = {:__MODULE__, :ranking_details, make_ref()}

    :telemetry.attach_many(
      handler_id,
      [[:scrypath, :search, :start]],
      fn _event, _meas, meta, _ -> send(self(), {:search_start_meta, meta}) end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    assert {:ok, _} =
             Scrypath.search(SearchablePost, "x",
               backend: Scrypath.TestSupport.FakeBackend,
               per_query: [show_ranking_score_details: true]
             )

    assert_receive {:search_start_meta, meta}
    assert meta.ranking_score_details == true
  end
end
