defmodule Scrypath.PhoenixTest do
  use ExUnit.Case, async: true

  alias Scrypath.Phoenix
  alias Scrypath.QueryParams

  test "from_params/1 delegates to the core query params normalizer" do
    params = %{
      "q" => "phoenix",
      "page" => %{"number" => "2"},
      "facet_filter" => %{"genre" => ["Drama", "Sci-Fi"]}
    }

    assert Phoenix.from_params(params) == QueryParams.normalize(params)
  end

  test "to_query_params/1 round-trips normalized state into canonical Plug-friendly params" do
    assert {:ok, query_params} =
             QueryParams.normalize(%{
               "q" => "phoenix",
               "page" => %{"number" => "2", "size" => "20"},
               "facets" => ["genre", "year"],
               "filter" => %{"status" => "published"},
               "facet_filter" => %{"genre" => ["Drama", "Sci-Fi"]},
               "sort" => %{"field" => "inserted_at", "dir" => "desc"}
             })

    assert Phoenix.to_query_params(query_params) == %{
             "q" => "phoenix",
             "page" => %{"number" => "2", "size" => "20"},
             "facets" => ["genre", "year"],
             "filter" => %{"status" => "published"},
             "facet_filter" => %{"genre" => ["Drama", "Sci-Fi"]},
             "sort" => %{"field" => "inserted_at", "dir" => "desc"}
           }
  end

  test "to_form_data/2 projects attempted values and structured field errors" do
    params = %{"q" => "ecto", "page" => %{"number" => "0"}, "sort" => %{"dir" => "sideways"}}

    assert {:error, error_map} = QueryParams.normalize(params)

    assert %{
             values: %{
               "q" => "ecto",
               "page" => %{"number" => "0"},
               "sort" => %{"dir" => "sideways"}
             },
             params: %{
               "q" => "ecto",
               "page" => %{"number" => "0"},
               "sort" => %{"dir" => "sideways"}
             },
             form_errors: [],
             field_errors: %{
               "page" => [%{code: :invalid_value, path: ["page", "number"]}],
                "sort" => [
                  %{code: :invalid_value, path: ["sort", "dir"]},
                  %{code: :missing_key, path: ["sort", "field"]},
                  %{code: :unknown_field, path: ["sort", "field"]}
                ]
              },
              errors: errors
           } = Phoenix.to_form_data(params, error_map)

    assert Enum.map(errors, & &1.code) == [:invalid_value, :invalid_value, :missing_key, :unknown_field]
  end

  test "to_form_data/1 projects normalized values without Phoenix runtime coupling" do
    assert {:ok, query_params} = QueryParams.normalize(%{"q" => "phoenix", "page" => %{"number" => "2"}})

    assert %{
             values: %{"q" => "phoenix", "page" => %{"number" => "2"}},
             form_errors: [],
             field_errors: %{},
             errors: []
           } = Phoenix.to_form_data(query_params)
  end
end
