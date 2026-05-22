defmodule Scrypath.QueryParamsTest do
  use ExUnit.Case, async: true

  alias Scrypath.QueryParams
  alias Scrypath.QueryParams.Error

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

  test "normalize/1 accepts Plug-decoded request maps and returns runtime-compatible plain data" do
    params = %{
      "q" => "phoenix",
      "page" => %{"number" => "2", "size" => "20"},
      "facets" => ["genre", "year"],
      "filter" => %{"status" => "published", "genre" => ["Action", "Drama"]},
      "facet_filter" => %{"genre" => ["Action", "Drama"], "year" => "2024"},
      "sort" => %{"field" => "inserted_at", "dir" => "desc"},
      "ignored" => "value"
    }

    assert {:ok,
            %{
              text: "phoenix",
              filter: [status: "published", genre: ["Action", "Drama"]],
              sort: [desc: :inserted_at],
              page: [number: 2, size: 20],
              facets: [:genre, :year],
              facet_filter: [genre: ["Action", "Drama"], year: "2024"],
              per_query: %{}
            } = query_params} = QueryParams.normalize(params)

    assert {"phoenix",
            [
              filter: [status: "published", genre: ["Action", "Drama"]],
              sort: [desc: :inserted_at],
              page: [number: 2, size: 20],
              facets: [:genre, :year],
              facet_filter: [genre: ["Action", "Drama"], year: "2024"],
              per_query: %{}
            ]} = QueryParams.to_search_args(query_params)
  end

  test "normalize/1 accepts text as a compatibility alias and rejects browser per_query input" do
    assert {:ok, %{text: "ecto", filter: [], sort: [], page: [], facets: [], facet_filter: [], per_query: %{}}} =
             QueryParams.normalize(%{"text" => "ecto", "debug" => true})

    assert {:error, %{field_errors: %{per_query: [issue]}, form_errors: [], errors: [issue]}} =
             QueryParams.normalize(%{"q" => "ecto", "per_query" => %{"show_ranking_score" => true}})

    assert %Error{
             code: :unsupported_param,
             path: [:per_query],
             meta: %{namespace: :per_query}
           } = issue
  end

  test "normalize/1 returns aggregate field-scoped issues for invalid owned namespaces" do
    params = %{
      "q" => "ecto",
      "filter" => %{"status" => %{"eq" => "published"}, "oops" => "value"},
      "page" => %{"number" => "0", "size" => "many", "cursor" => "abc"},
      "sort" => %{"field" => "inserted_at", "dir" => "sideways", "extra" => "nope"},
      "facets" => %{"genre" => "bad"},
      "facet_filter" => %{"genre" => %{"eq" => "Action"}}
    }

    assert {:error, %{form_errors: [], field_errors: field_errors, errors: errors} = error_map} =
             QueryParams.normalize(params)

    assert is_map(field_errors)
    assert is_list(errors)
    assert length(errors) >= 6
    assert Enum.sort(Map.keys(field_errors)) == [:facet_filter, :facets, :filter, :page, :sort]

    assert Enum.all?(errors, fn issue ->
             match?(%Error{code: _, message: _, path: _, meta: _}, issue)
           end)

    assert [%Error{code: :invalid_shape, path: [:filter, :status], meta: %{expected: "scalar or list"}} | _] =
             field_errors.filter

    assert Enum.any?(field_errors.page, &(&1.code == :unknown_key and &1.path == [:page, :cursor]))
    assert Enum.any?(field_errors.page, &(&1.code == :invalid_value and &1.path == [:page, :number]))
    assert Enum.any?(field_errors.page, &(&1.code == :invalid_value and &1.path == [:page, :size]))
    assert Enum.any?(field_errors.sort, &(&1.code == :invalid_value and &1.path == [:sort, :dir]))
    assert Enum.any?(field_errors.sort, &(&1.code == :unknown_key and &1.path == [:sort, :extra]))
    assert Enum.any?(field_errors.facets, &(&1.code == :invalid_shape and &1.path == [:facets]))
    assert Enum.any?(field_errors.facet_filter, &(&1.code == :invalid_shape and &1.path == [:facet_filter, :genre]))

    assert error_map.errors == Enum.flat_map(field_errors, fn {_field, issues} -> issues end)
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
    assert function_exported?(QueryParams, :normalize, 1)
    assert %{text: "", filter: [], sort: [], page: [], facets: [], facet_filter: [], per_query: %{}} =
             QueryParams.cast(%{"debug" => true, "q" => nil, "backend" => Scrypath.Meilisearch})

    assert function_exported?(QueryParams, :cast, 1)
    assert function_exported?(QueryParams, :to_search_args, 1)
    refute function_exported?(QueryParams, :search, 0)
    refute function_exported?(QueryParams, :search, 1)
    refute function_exported?(QueryParams, :search, 2)
    refute function_exported?(QueryParams, :search, 3)
  end
end
