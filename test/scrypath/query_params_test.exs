defmodule Scrypath.QueryParamsTest do
  use ExUnit.Case, async: true

  alias Scrypath.QueryParams

  test "cast/1 returns one stable plain-data toolkit shape for top-level request params" do
    params = %{
      "q" => "phoenix",
      "filter" => [status: "published"],
      "sort" => [desc: :inserted_at],
      "page" => [number: 2, size: 20],
      "facets" => [:genre, :year],
      "facet_filter" => [genre: ["Action", "Drama"]],
      "per_query" => %{show_ranking_score: true},
      "ignored" => "value"
    }

    assert %{
             text: "phoenix",
             filter: [status: "published"],
             sort: [desc: :inserted_at],
             page: [number: 2, size: 20],
             facets: [:genre, :year],
             facet_filter: [genre: ["Action", "Drama"]],
             per_query: %{show_ranking_score: true}
           } = query_params = QueryParams.cast(params)

    assert Map.keys(query_params) |> Enum.sort() == [
             :facet_filter,
             :facets,
             :filter,
             :page,
             :per_query,
             :sort,
             :text
           ]

    refute match?(%Scrypath.Query{}, query_params)

    assert {"phoenix",
            [
              filter: [status: "published"],
              sort: [desc: :inserted_at],
              page: [number: 2, size: 20],
              facets: [:genre, :year],
              facet_filter: [genre: ["Action", "Drama"]],
              per_query: %{show_ranking_score: true}
            ]} = QueryParams.to_search_args(query_params)
  end

  test "cast/1 accepts string-keyed and atom-keyed text envelopes with runtime-compatible values" do
    assert %{text: "ecto", filter: [status: "draft"], sort: [], page: [], facets: [], facet_filter: [], per_query: %{}} =
             QueryParams.cast(%{"text" => "ecto", "filter" => [status: "draft"]})

    assert %{text: "search", filter: [], sort: [asc: :id], page: [number: 1], facets: [], facet_filter: [], per_query: %{show_ranking_score: true}} =
             QueryParams.cast(%{q: "search", sort: [asc: :id], page: [number: 1], per_query: %{show_ranking_score: true}})
  end

  test "cast/1 rejects nested request-style values that are not runtime-compatible yet" do
    assert_raise ArgumentError, ~r/runtime-compatible nested values for :filter/, fn ->
      QueryParams.cast(%{"q" => "phoenix", "filter" => %{"status" => "published"}})
    end

    assert_raise ArgumentError, ~r/runtime-compatible nested values for :page/, fn ->
      QueryParams.cast(%{"q" => "phoenix", "page" => %{"number" => "2", "size" => "20"}})
    end

    assert_raise ArgumentError, ~r/runtime-compatible nested values for :per_query/, fn ->
      QueryParams.cast(%{"q" => "phoenix", "per_query" => %{"show_ranking_score" => true}})
    end
  end

  test "the public facade stays narrow and data-only" do
    assert %{text: "", filter: [], sort: [], page: [], facets: [], facet_filter: [], per_query: %{}} =
             QueryParams.cast(%{"debug" => true, "q" => nil, "backend" => Scrypath.Meilisearch})

    assert function_exported?(QueryParams, :cast, 1)
    assert function_exported?(QueryParams, :to_search_args, 1)
    refute function_exported?(QueryParams, :search, 1)
    refute function_exported?(QueryParams, :search, 2)
    refute function_exported?(QueryParams, :search, 3)
  end
end
