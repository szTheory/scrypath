defmodule Scrypath.FacetSearchResultTest do
  use ExUnit.Case, async: true

  alias Scrypath.FacetSearchResult
  alias Scrypath.SearchResult.Facets.Bucket

  describe "new/1" do
    test "parses facetHits into a list of Bucket structs" do
      raw = %{
        "facetHits" => [
          %{"value" => "comedy", "count" => 42},
          %{"value" => "drama", "count" => 15}
        ],
        "facetQuery" => "co",
        "processingTimeMs" => 1
      }

      result = FacetSearchResult.new(raw)

      assert %FacetSearchResult{} = result
      assert result.facet_query == "co"
      assert result.raw == raw

      assert result.hits == [
               %Bucket{value: "comedy", count: 42},
               %Bucket{value: "drama", count: 15}
             ]
    end

    test "handles missing facetHits gracefully" do
      raw = %{"facetQuery" => "nothing"}
      result = FacetSearchResult.new(raw)

      assert result.hits == []
      assert result.facet_query == "nothing"
      assert result.raw == raw
    end
  end
end
