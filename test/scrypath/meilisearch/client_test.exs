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

    test "normalizes a retry-disabled transport failure through the public tuple" do
      stub = Module.concat(__MODULE__, GetSettingsTransportErrorStub)

      Req.Test.stub(stub, fn conn ->
        Req.Test.transport_error(conn, :timeout)
      end)

      assert {:error, {:transport_error, %Req.TransportError{reason: :timeout}}} =
               Client.get_settings("posts_v2",
                 meilisearch_url: "http://localhost:7700",
                 req_options: [plug: {Req.Test, stub}, retry: false]
               )
    end

    test "merges the configured API key with caller headers and options" do
      stub = Module.concat(__MODULE__, GetSettingsHeaderMergeStub)

      Req.Test.stub(stub, fn conn ->
        assert Plug.Conn.get_req_header(conn, "x-meili-api-key") == ["api-key-144"]
        assert Plug.Conn.get_req_header(conn, "x-request-id") == ["request-144"]

        Req.Test.json(conn, %{"rankingRules" => ["words"]})
      end)

      assert {:ok, %{"rankingRules" => ["words"]}} =
               Client.get_settings("posts_v2",
                 meilisearch_url: "http://localhost:7700",
                 meilisearch_api_key: "api-key-144",
                 req_options: [
                   plug: {Req.Test, stub},
                   headers: [{"x-request-id", "request-144"}]
                 ]
               )
    end

    test "configured endpoint and API key override transport options" do
      stub = Module.concat(__MODULE__, GetSettingsConfiguredEndpointStub)

      Req.Test.stub(stub, fn conn ->
        assert conn.host == "configured.example.test"
        assert Plug.Conn.get_req_header(conn, "x-meili-api-key") == ["configured-key"]
        Req.Test.json(conn, %{})
      end)

      assert {:ok, %{}} =
               Client.get_settings("posts_v2",
                 meilisearch_url: "https://configured.example.test",
                 meilisearch_api_key: "configured-key",
                 req_options: [
                   plug: {Req.Test, stub},
                   base_url: "https://untrusted.example.test",
                   headers: [{"x-meili-api-key", "untrusted-key"}]
                 ]
               )
    end
  end

  describe "tasks/2" do
    test "encodes list filters once as comma-separated camelCase query values" do
      stub = Module.concat(__MODULE__, TasksFilterEncodingStub)

      Req.Test.stub(stub, fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/tasks"

        assert conn.query_params == %{
                 "indexUids" => "posts_v2,comments_v2",
                 "statuses" => "enqueued,failed",
                 "types" => "documentAdditionOrUpdate,documentDeletion"
               }

        Req.Test.json(conn, %{"results" => []})
      end)

      assert {:ok, %{"results" => []}} =
               Client.tasks(
                 [
                   statuses: [:enqueued, :failed],
                   types: ["documentAdditionOrUpdate", "documentDeletion"],
                   index_uids: ["posts_v2", "comments_v2"],
                   from: nil
                 ],
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
