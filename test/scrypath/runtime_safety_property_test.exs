defmodule Scrypath.RuntimeSafetyPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Scrypath.Oban.Payload
  alias Scrypath.Query
  alias Scrypath.SearchResult

  defmodule SearchablePost do
    use Ecto.Schema
    use Scrypath, fields: [:title]

    schema "runtime_safety_posts" do
      field(:title, :string)
    end
  end

  property "unknown backend facet-stat keys remain binaries" do
    check all(suffix <- string(:alphanumeric, min_length: 1, max_length: 24)) do
      key = "untrusted_stat_#{suffix}_#{System.unique_integer([:positive])}"
      query = Query.new("", facets: [:price])

      result =
        SearchResult.new(
          query,
          %{"hits" => [], "facetStats" => %{"price" => %{key => 42}}},
          [],
          []
        )

      assert result.facets.stats.price[key] == 42
      assert_raise ArgumentError, fn -> String.to_existing_atom(key) end
    end
  end

  property "Oban payloads never serialize per-call API keys" do
    check all(suffix <- string(:alphanumeric, min_length: 8, max_length: 32)) do
      api_key = "secret:#{suffix}:end"

      payload =
        Payload.build_upsert(
          SearchablePost,
          [%Scrypath.Document{id: 1, data: %{title: "safe"}, source: :fields}],
          backend: Scrypath.Meilisearch,
          sync_mode: :oban,
          meilisearch_api_key: api_key
        )

      refute Map.has_key?(payload, "meilisearch_api_key")
      refute inspect(payload) =~ api_key
    end
  end
end
