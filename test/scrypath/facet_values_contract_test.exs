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

  @tag :facet_tenant_tracer
  test "search_facet_values/4 combines tenant scope and a keyword filter in encoded HTTP" do
    stub = Module.concat(__MODULE__, FacetTenantTracerStub)
    owner = self()

    Req.Test.stub(stub, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      params = Jason.decode!(body)
      send(owner, {:facet_tenant_tracer_request, params})
      Req.Test.json(conn, %{"facetHits" => [], "facetQuery" => "pho"})
    end)

    assert {:ok, %Scrypath.FacetSearchResult{facet_query: "pho"}} =
             Scrypath.search_facet_values(
               FacetPost,
               "category",
               "pho",
               request_options(stub) ++ [tenant_scope: 123, filter: [status: "published"]]
             )

    assert_received {:facet_tenant_tracer_request, params}
    assert length(params["filter"]) == 2
    assert "status = \"published\"" in params["filter"]
    assert "tenant_id = 123" in params["filter"]
  end

  @tag :facet_keyword
  test "search_facet_values/4 renders a common keyword filter in the encoded request" do
    stub = Module.concat(__MODULE__, FacetKeywordStub)
    owner = self()

    Req.Test.stub(stub, fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/indexes/facet_contract_facet_post/facet-search"
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      params = Jason.decode!(body)
      send(owner, {:facet_keyword_request, params})

      Req.Test.json(conn, %{
        "facetHits" => [%{"value" => "phone", "count" => 2}],
        "facetQuery" => "pho"
      })
    end)

    assert {:ok, %Scrypath.FacetSearchResult{facet_query: "pho"}} =
             Scrypath.search_facet_values(FacetPost, "category", "pho",
               filter: [status: "published"],
               backend: Scrypath.Meilisearch,
               index_prefix: @index_prefix,
               meilisearch_url: @meilisearch_url,
               req_options: [plug: {Req.Test, stub}, retry: false]
             )

    assert_received {:facet_keyword_request, params}
    assert params["facetName"] == "category"
    assert params["facetQuery"] == "pho"
    assert params["filter"] == ["status = \"published\""]
  end

  test "search_facet_values/4 escapes common filter string literals in encoded HTTP" do
    stub = Module.concat(__MODULE__, FacetEscapedFilterStub)
    owner = self()
    value = "he said \"hi\" \\ path"

    Req.Test.stub(stub, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      params = Jason.decode!(body)
      send(owner, {:facet_escaped_filter_request, params})
      Req.Test.json(conn, %{"facetHits" => [], "facetQuery" => "pho"})
    end)

    assert {:ok, %Scrypath.FacetSearchResult{facet_query: "pho"}} =
             Scrypath.search_facet_values(
               FacetPost,
               "category",
               "pho",
               request_options(stub) ++ [filter: [status: value]]
             )

    assert_received {:facet_escaped_filter_request, params}
    assert params["filter"] == ["status = \"he said \\\"hi\\\" \\\\ path\""]
  end

  test "invalid boolean filter raises before HTTP dispatch" do
    stub = Module.concat(__MODULE__, FacetInvalidFilterStub)
    owner = self()

    Req.Test.stub(stub, fn conn ->
      send(owner, :facet_invalid_filter_request)
      Req.Test.json(conn, %{"facetHits" => [], "facetQuery" => "pho"})
    end)

    assert_raise ArgumentError, ~r/boolean composition is not supported/, fn ->
      Scrypath.search_facet_values(
        FacetPost,
        "category",
        "pho",
        request_options(stub) ++ [filter: [or: [status: "published"]]]
      )
    end

    refute_received :facet_invalid_filter_request
  end

  test "HTTP rejection preserves its error tuple and submitted filter" do
    stub = Module.concat(__MODULE__, FacetHttpErrorStub)
    owner = self()
    error_body = %{"message" => "invalid filter"}

    Req.Test.stub(stub, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      params = Jason.decode!(body)
      send(owner, {:facet_http_error_request, params})

      conn
      |> Plug.Conn.put_status(400)
      |> Req.Test.json(error_body)
    end)

    assert {:error, {:http_error, 400, ^error_body}} =
             Scrypath.search_facet_values(
               FacetPost,
               "category",
               "pho",
               request_options(stub) ++ [filter: [status: "published"]]
             )

    assert_received {:facet_http_error_request, params}
    assert params["filter"] == ["status = \"published\""]
    refute_received {:facet_http_error_request, _}
  end

  test "transport timeout preserves its error tuple and submitted filter" do
    stub = Module.concat(__MODULE__, FacetTransportErrorStub)
    owner = self()

    Req.Test.stub(stub, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      params = Jason.decode!(body)
      send(owner, {:facet_transport_error_request, params})
      Req.Test.transport_error(conn, :timeout)
    end)

    assert {:error, {:transport_error, %Req.TransportError{reason: :timeout}}} =
             Scrypath.search_facet_values(
               FacetPost,
               "category",
               "pho",
               request_options(stub) ++ [filter: [status: "published"]]
             )

    assert_received {:facet_transport_error_request, params}
    assert params["filter"] == ["status = \"published\""]
    refute_received {:facet_transport_error_request, _}
  end

  test "bang wrapper retains operational error reason without retrying or dropping filter" do
    stub = Module.concat(__MODULE__, FacetBangErrorStub)
    owner = self()
    error_body = %{"message" => "temporarily unavailable"}

    Req.Test.stub(stub, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      params = Jason.decode!(body)
      send(owner, {:facet_bang_error_request, params})

      conn
      |> Plug.Conn.put_status(503)
      |> Req.Test.json(error_body)
    end)

    error =
      assert_raise Scrypath.Search.Error, fn ->
        Scrypath.search_facet_values!(
          FacetPost,
          "category",
          "pho",
          request_options(stub) ++ [filter: [status: "published"]]
        )
      end

    assert error.reason == {:http_error, 503, error_body}
    assert_received {:facet_bang_error_request, params}
    assert params["filter"] == ["status = \"published\""]
    refute_received {:facet_bang_error_request, _}
  end

  test "search_facet_values/4 combines tenant scope with the ordinary filter in encoded HTTP" do
    stub = Module.concat(__MODULE__, FacetTenantFilterStub)
    owner = self()

    Req.Test.stub(stub, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      params = Jason.decode!(body)
      send(owner, {:facet_tenant_filter_request, params})
      Req.Test.json(conn, %{"facetHits" => [], "facetQuery" => "pho"})
    end)

    assert {:ok, %Scrypath.FacetSearchResult{facet_query: "pho"}} =
             Scrypath.search_facet_values(
               FacetPost,
               "category",
               "pho",
               request_options(stub) ++ [tenant_scope: 123, filter: [status: "published"]]
             )

    assert_received {:facet_tenant_filter_request, params}

    assert length(params["filter"]) == 2
    assert "status = \"published\"" in params["filter"]
    assert "tenant_id = 123" in params["filter"]
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
