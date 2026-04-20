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
end
