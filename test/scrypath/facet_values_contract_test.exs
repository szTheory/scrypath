defmodule Scrypath.FacetValuesContractTest do
  use ExUnit.Case, async: false

  defmodule FacetPost do
    use Ecto.Schema

    use Scrypath,
      fields: [:title, :status, :tenant_id, :category],
      filterable: [:status, :tenant_id, :category],
      faceting: [attributes: [:category], max_values_per_facet: 100],
      tenant_field: :tenant_id

    embedded_schema do
      field(:title, :string)
      field(:status, :string)
      field(:tenant_id, :integer)
      field(:category, :string)
    end
  end

  @index_prefix "facet_contract"
  @meilisearch_url "http://localhost:7700"

  @tag :facet_defaults
  test "search_facet_values/4 forwards supported defaults through encoded HTTP" do
    stub = Module.concat(__MODULE__, FacetDefaultsStub)
    owner = self()

    Req.Test.stub(stub, fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/indexes/facet_contract_facet_post/facet-search"
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      params = Jason.decode!(body)

      assert params["facetName"] == "category"
      assert params["facetQuery"] == "pho"
      assert params["filter"] == []
      send(owner, {:facet_defaults_request, params})

      Req.Test.json(conn, %{
        "facetHits" => [%{"value" => "phone", "count" => 2}],
        "facetQuery" => "pho"
      })
    end)

    assert {:ok,
            %Scrypath.FacetSearchResult{
              facet_query: "pho",
              hits: [%Scrypath.SearchResult.Facets.Bucket{value: "phone", count: 2}]
            }} =
             Scrypath.search_facet_values(FacetPost, "category", "pho", request_options(stub))

    assert_received {:facet_defaults_request, params}
    assert params["filter"] == []
  end

  defp request_options(stub) do
    [
      backend: Scrypath.Meilisearch,
      index_prefix: @index_prefix,
      meilisearch_url: @meilisearch_url,
      req_options: [plug: {Req.Test, stub}, retry: false]
    ]
  end
end
