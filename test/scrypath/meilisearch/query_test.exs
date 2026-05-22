defmodule Scrypath.Meilisearch.QueryTest do
  use ExUnit.Case, async: true

  alias Scrypath.Meilisearch.Query, as: MeilisearchQuery
  alias Scrypath.Query
  alias Scrypath.QueryParams

  test "filter only — facetFilters absent, filter present" do
    q = %Query{
      text: "q",
      filter: [status: "live"],
      sort: [],
      page: %{},
      facets: [],
      facet_filter: [],
      per_query: %{}
    }

    payload = MeilisearchQuery.to_payload(q)
    assert Map.has_key?(payload, :filter)
    refute Map.has_key?(payload, "facetFilters")
    refute Map.has_key?(payload, :facets)
  end

  test "facet_filter only — facetFilters present, filter absent" do
    q = %Query{
      text: "q",
      filter: [],
      sort: [],
      page: %{},
      facets: [:genre],
      facet_filter: [genre: "Action"],
      per_query: %{}
    }

    payload = MeilisearchQuery.to_payload(q)
    refute Map.has_key?(payload, :filter)
    assert Map.has_key?(payload, "facetFilters")
    assert payload["facetFilters"] == ["genre = \"Action\""]
    assert payload[:facets] == ["genre"]
  end

  test "filter and facet_filter both present (FACET-09 AND)" do
    q = %Query{
      text: "q",
      filter: [status: "live"],
      sort: [],
      page: %{},
      facets: [:genre],
      facet_filter: [genre: "Action"],
      per_query: %{}
    }

    payload = MeilisearchQuery.to_payload(q)
    assert Map.has_key?(payload, :filter)
    assert Map.has_key?(payload, "facetFilters")
  end

  test "multi-field facet_filter + filter" do
    q = %Query{
      text: "q",
      filter: [status: "live"],
      sort: [],
      page: %{},
      facets: [:genre, :year],
      facet_filter: [genre: "Action", year: 1999],
      per_query: %{}
    }

    payload = MeilisearchQuery.to_payload(q)
    assert is_list(payload["facetFilters"])
    assert "genre = \"Action\"" in payload["facetFilters"]
    assert "year = 1999" in payload["facetFilters"]
  end

  test "disjunctive within one facet field and conjunctive with another (FACET-04)" do
    q = %Query{
      text: "q",
      filter: [],
      sort: [],
      page: %{},
      facets: [:genre, :rating],
      facet_filter: [genre: ["Action", "Drama"], rating: 4],
      per_query: %{}
    }

    payload = MeilisearchQuery.to_payload(q)
    assert [["genre = \"Action\"", "genre = \"Drama\""], "rating = 4"] == payload["facetFilters"]
  end

  test "numeric range operators on facet_filter" do
    q = %Query{
      text: "q",
      filter: [],
      sort: [],
      page: %{},
      facets: [:year],
      facet_filter: [year: [gte: 2000, lte: 2010]],
      per_query: %{}
    }

    payload = MeilisearchQuery.to_payload(q)
    assert "year >= 2000" in payload["facetFilters"]
    assert "year <= 2010" in payload["facetFilters"]
  end

  test "query params output preserves the existing meilisearch payload grammar" do
    query_params =
      QueryParams.cast(%{
        "q" => "phoenix",
        "filter" => [status: "published"],
        "sort" => [desc: :inserted_at],
        "page" => [number: 2, size: 20],
        "facets" => [:status],
        "facet_filter" => [status: ["published", "scheduled"]],
        "per_query" => %{show_ranking_score: true}
      })

    {text, search_opts} = QueryParams.to_search_args(query_params)

    toolkit_payload =
      text
      |> Query.new(search_opts)
      |> MeilisearchQuery.to_payload()

    direct_payload =
      "phoenix"
      |> Query.new(
        filter: [status: "published"],
        sort: [desc: :inserted_at],
        page: [number: 2, size: 20],
        facets: [:status],
        facet_filter: [status: ["published", "scheduled"]],
        per_query: %{show_ranking_score: true}
      )
      |> MeilisearchQuery.to_payload()

    assert toolkit_payload == direct_payload

    assert %{
             :q => "phoenix",
             :filter => ["status = \"published\""],
             :sort => ["inserted_at:desc"],
             :facets => ["status"],
             :page => 2,
             :hitsPerPage => 20,
             "facetFilters" => [["status = \"published\"", "status = \"scheduled\""]],
             "showRankingScore" => true
           } = toolkit_payload
  end
end
