defmodule Scrypath.Meilisearch.ClientTest do
  use ExUnit.Case, async: true

  alias Scrypath.Meilisearch.Client

  describe "get_settings/2 (TUNE-05 wire primitive)" do
    test "GET /indexes/:uid/settings returns decoded JSON on 200" do
      stub = Module.concat(__MODULE__, GetSettingsOkStub)

      Req.Test.stub(stub, fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/indexes/posts_v2/settings"
        Req.Test.json(conn, %{"rankingRules" => ["words", "typo"]})
      end)

      assert {:ok, %{"rankingRules" => ["words", "typo"]}} =
               Client.get_settings("posts_v2",
                 meilisearch_url: "http://localhost:7700",
                 req_options: [plug: {Req.Test, stub}]
               )
    end

    test "404 maps to {:error, {:http_error, 404, _}}" do
      stub = Module.concat(__MODULE__, GetSettings404Stub)

      Req.Test.stub(stub, fn conn ->
        conn
        |> Plug.Conn.put_status(404)
        |> Req.Test.json(%{"message" => "not found"})
      end)

      assert {:error, {:http_error, 404, _body}} =
               Client.get_settings("missing_index",
                 meilisearch_url: "http://localhost:7700",
                 req_options: [plug: {Req.Test, stub}]
               )
    end
  end

  describe "facet_search/5" do
    test "POST /indexes/:uid/facet-search maps parameters to payload" do
      stub = Module.concat(__MODULE__, FacetSearchOkStub)

      Req.Test.stub(stub, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/indexes/posts_v2/facet-search"
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        params = Jason.decode!(body)

        assert params["facetName"] == "genre"
        assert params["facetQuery"] == "co"
        assert params["filter"] == ["status = 'published'"]
        
        Req.Test.json(conn, %{
          "facetHits" => [%{"value" => "comedy", "count" => 42}],
          "facetQuery" => "co"
        })
      end)

      assert {:ok, %{"facetHits" => [%{"value" => "comedy", "count" => 42}]}} =
               Client.facet_search("posts_v2", "genre", "co", [filter: ["status = 'published'"]],
                 meilisearch_url: "http://localhost:7700",
                 req_options: [plug: {Req.Test, stub}]
               )
    end
  end
end
