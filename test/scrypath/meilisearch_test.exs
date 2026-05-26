defmodule Scrypath.MeilisearchTest do
  use ExUnit.Case, async: true

  alias Scrypath.Document
  alias Scrypath.SearchResult

  defmodule CustomIdPost do
    use Ecto.Schema

    use Scrypath, fields: [:title], document_id: :external_id

    embedded_schema do
      field(:external_id, :string)
      field(:title, :string)
    end
  end

  defmodule RecordingClient do
    def create_index(index_name, primary_key, config) do
      send(self(), {:client_create_index, index_name, primary_key, config})

      {:ok,
       %{
         "taskUid" => 19,
         "indexUid" => index_name,
         "status" => "enqueued",
         "type" => "indexCreation"
       }}
    end

    def update_settings(index_name, settings, config) do
      send(self(), {:client_update_settings, index_name, settings, config})

      {:ok,
       %{
         "taskUid" => 20,
         "indexUid" => index_name,
         "status" => "enqueued",
         "type" => "settingsUpdate"
       }}
    end

    def swap_indexes(indexes, config) do
      send(self(), {:client_swap_indexes, indexes, config})

      {:ok,
       %{
         "taskUid" => 21,
         "status" => "enqueued",
         "type" => "indexSwap"
       }}
    end

    def upsert_documents(index_name, documents, config) do
      send(self(), {:client_upsert, index_name, documents, config})

      {:ok,
       %{
         "taskUid" => 17,
         "indexUid" => index_name,
         "status" => "enqueued",
         "type" => "documentAdditionOrUpdate"
       }}
    end

    def delete_documents(index_name, document_ids, config) do
      send(self(), {:client_delete, index_name, document_ids, config})

      {:ok,
       %{
         "taskUid" => 18,
         "indexUid" => index_name,
         "status" => "enqueued",
         "type" => "documentDeletion"
       }}
    end

    def task(task_uid, config) do
      send(self(), {:client_task, task_uid, config})
      {:ok, %{"uid" => task_uid, "status" => "succeeded"}}
    end

    def search(index_name, query, config) do
      send(self(), {:client_search, index_name, query, config})
      {:ok, %{"hits" => [%{"id" => 99}], "query" => query}}
    end

    def facet_search(index_name, facet_name, facet_query, opts, config) do
      send(self(), {:client_facet_search, index_name, facet_name, facet_query, opts, config})

      {:ok,
       %{"facetHits" => [%{"value" => "comedy", "count" => 42}], "facetQuery" => facet_query}}
    end
  end

  test "Scrypath.Meilisearch satisfies backend name and index naming" do
    assert Scrypath.Meilisearch.name() == :meilisearch

    assert Scrypath.Meilisearch.index_name(SearchablePost, index_prefix: "tenant") ==
             "tenant_searchable_post"

    assert Scrypath.Meilisearch.index_name(SearchablePost, []) == "scrypath_searchable_post"
  end

  test "upsert_documents/3 keeps writes list-oriented and exposes task metadata" do
    documents = [
      %Document{id: 1, data: %{title: "One"}, source: :fields},
      %Document{id: 2, data: %{title: "Two"}, source: :custom}
    ]

    assert {:ok,
            %{
              index: "tenant_searchable_post",
              document_ids: [1, 2],
              task: %{uid: 17, status: :enqueued}
            }} =
             Scrypath.Meilisearch.upsert_documents(SearchablePost, documents,
               index_prefix: "tenant",
               meilisearch_client: RecordingClient
             )

    assert_received {:client_upsert, "tenant_searchable_post", ^documents, config}
    assert config[:index_prefix] == "tenant"
  end

  test "delete_documents/3 delegates canonical ids through the client" do
    assert {:ok,
            %{
              index: "tenant_searchable_post",
              document_ids: ["post:1"],
              task: %{uid: 18, status: :enqueued}
            }} =
             Scrypath.Meilisearch.delete_documents(SearchablePost, ["post:1"],
               index_prefix: "tenant",
               meilisearch_client: RecordingClient
             )

    assert_received {:client_delete, "tenant_searchable_post", ["post:1"], _config}
  end

  test "search/3 remains a minimal callback wrapper over the client" do
    assert {:ok, %{"hits" => [%{"id" => 99}], "query" => "hello"}} =
             Scrypath.Meilisearch.search(SearchablePost, "hello",
               index_prefix: "tenant",
               meilisearch_client: RecordingClient
             )

    assert_received {:client_search, "tenant_searchable_post", "hello", _config}
  end

  test "search/3 honors explicit target index overrides for reindex inspection" do
    assert {:ok, %{"hits" => [%{"id" => 99}], "query" => "hello"}} =
             Scrypath.Meilisearch.search(SearchablePost, "hello",
               index_prefix: "tenant",
               target_index: "tenant_searchable_post__reindex",
               meilisearch_client: RecordingClient
             )

    assert_received {:client_search, "tenant_searchable_post__reindex", "hello", _config}
  end

  test "search_facet_values/5 delegates to client's facet_search honoring index configuration" do
    assert {:ok, %{"facetHits" => [%{"value" => "comedy", "count" => 42}], "facetQuery" => "co"}} =
             Scrypath.Meilisearch.search_facet_values(SearchablePost, "genre", "co", [],
               index_prefix: "tenant",
               meilisearch_client: RecordingClient
             )

    assert_received {:client_facet_search, "tenant_searchable_post", "genre", "co", [], _config}
  end

  test "common search translates normalized query fields into Meilisearch payloads" do
    stub = Module.concat(__MODULE__, QueryReqStub)

    Req.Test.stub(stub, fn conn ->
      send(self(), {:search_request, conn.method, conn.request_path, conn.body_params})

      Req.Test.json(conn, %{
        "hits" => [%{"id" => 99}],
        "page" => 2,
        "hitsPerPage" => 20,
        "totalHits" => 1
      })
    end)

    assert {:ok, %SearchResult{hits: [%{"id" => 99}]}} =
             Scrypath.search(SearchablePost, "hello",
               backend: Scrypath.Meilisearch,
               meilisearch_url: "http://localhost:7700",
               req_options: [plug: {Req.Test, stub}],
               filter: [status: [eq: "published", gte: "archived"]],
               sort: [desc: :inserted_at],
               page: [number: 2, size: 20]
             )

    assert_received {:search_request, "POST", "/indexes/scrypath_searchable_post/search", body}
    assert body["q"] == "hello"
    assert body["sort"] == ["inserted_at:desc"]
    assert body["page"] == 2
    assert body["hitsPerPage"] == 20
    assert body["filter"] == ["status = \"published\"", "status >= \"archived\""]
  end

  test "native Meilisearch search remains available for backend-specific payloads" do
    payload = %{"q" => "hello", "facets" => ["status"]}

    assert {:ok, %{"hits" => [%{"id" => 99}], "query" => ^payload}} =
             Scrypath.Meilisearch.search(SearchablePost, payload,
               index_prefix: "tenant",
               meilisearch_client: RecordingClient
             )

    assert_received {:client_search, "tenant_searchable_post", ^payload, _config}
  end

  test "client shapes document writes, deletes, and task lookups for sync flows" do
    stub = Module.concat(__MODULE__, ReqStub)

    Req.Test.stub(stub, fn conn ->
      send(
        self(),
        {:request, conn.method, conn.request_path, conn.req_headers, conn.body_params}
      )

      case {conn.method, conn.request_path} do
        {"POST", "/indexes/tenant_searchable_post/documents"} ->
          Req.Test.json(conn, %{"taskUid" => 21, "status" => "enqueued"})

        {"POST", "/indexes/tenant_searchable_post/documents/delete-batch"} ->
          Req.Test.json(conn, %{"taskUid" => 22, "status" => "enqueued"})

        {"GET", "/tasks/22"} ->
          Req.Test.json(conn, %{"uid" => 22, "status" => "succeeded"})

        {"POST", "/indexes/tenant_searchable_post/search"} ->
          Req.Test.json(conn, %{"hits" => [], "query" => conn.body_params["q"]})
      end
    end)

    config = [
      meilisearch_url: "http://localhost:7700",
      meilisearch_api_key: "secret-key",
      req_options: [plug: {Req.Test, stub}]
    ]

    documents = [%Document{id: 5, data: %{title: "Hello"}, source: :fields}]

    assert {:ok, %{"taskUid" => 21, "status" => "enqueued"}} =
             Scrypath.Meilisearch.Client.upsert_documents(
               "tenant_searchable_post",
               documents,
               config
             )

    assert_received {:request, "POST", "/indexes/tenant_searchable_post/documents", headers, body}
    assert {"x-meili-api-key", "secret-key"} in headers
    assert body == %{"_json" => [%{"id" => 5, "title" => "Hello"}]}

    assert {:ok, %{"taskUid" => 22, "status" => "enqueued"}} =
             Scrypath.Meilisearch.Client.delete_documents(
               "tenant_searchable_post",
               ["post:5"],
               config
             )

    assert_received {:request, "POST", "/indexes/tenant_searchable_post/documents/delete-batch",
                     _, %{"_json" => ["post:5"]}}

    assert {:ok, %{"uid" => 22, "status" => "succeeded"}} =
             Scrypath.Meilisearch.Client.task(22, config)

    assert_received {:request, "GET", "/tasks/22", _, %{}}

    assert {:ok, %{"hits" => [], "query" => "hello"}} =
             Scrypath.Meilisearch.Client.search("tenant_searchable_post", "hello", config)

    assert_received {:request, "POST", "/indexes/tenant_searchable_post/search", _,
                     %{"q" => "hello"}}
  end

  test "client shapes document writes with the configured document id field" do
    stub = Module.concat(__MODULE__, CustomDocumentIdReqStub)

    Req.Test.stub(stub, fn conn ->
      send(self(), {:request, conn.method, conn.request_path, conn.body_params})
      Req.Test.json(conn, %{"taskUid" => 34, "status" => "enqueued"})
    end)

    config = [
      meilisearch_url: "http://localhost:7700",
      req_options: [plug: {Req.Test, stub}],
      document_id_field: :external_id
    ]

    documents = [%Document{id: "post-5", data: %{title: "Hello"}, source: :fields}]

    assert {:ok, %{"taskUid" => 34, "status" => "enqueued"}} =
             Scrypath.Meilisearch.Client.upsert_documents(
               "tenant_custom_id_post",
               documents,
               config
             )

    assert_received {:request, "POST", "/indexes/tenant_custom_id_post/documents",
                     %{"_json" => [%{"external_id" => "post-5", "title" => "Hello"}]}}
  end

  test "client can create an index through the explicit indexes endpoint" do
    stub = Module.concat(__MODULE__, CreateIndexReqStub)

    Req.Test.stub(stub, fn conn ->
      send(self(), {:request, conn.method, conn.request_path, conn.body_params})
      Req.Test.json(conn, %{"taskUid" => 31, "status" => "enqueued", "indexUid" => "rebuild_v2"})
    end)

    config = [
      meilisearch_url: "http://localhost:7700",
      req_options: [plug: {Req.Test, stub}]
    ]

    assert {:ok, %{"taskUid" => 31, "indexUid" => "rebuild_v2"}} =
             Scrypath.Meilisearch.Client.create_index("rebuild_v2", "id", config)

    assert_received {:request, "POST", "/indexes", %{"uid" => "rebuild_v2", "primaryKey" => "id"}}
  end

  test "client applies settings to the explicit index settings endpoint with caller payload" do
    stub = Module.concat(__MODULE__, UpdateSettingsReqStub)
    settings = %{"searchableAttributes" => ["title"], "sortableAttributes" => ["inserted_at"]}

    Req.Test.stub(stub, fn conn ->
      send(self(), {:request, conn.method, conn.request_path, conn.body_params})
      Req.Test.json(conn, %{"taskUid" => 32, "status" => "enqueued"})
    end)

    config = [
      meilisearch_url: "http://localhost:7700",
      req_options: [plug: {Req.Test, stub}]
    ]

    assert {:ok, %{"taskUid" => 32, "status" => "enqueued"}} =
             Scrypath.Meilisearch.Client.update_settings("rebuild_v2", settings, config)

    assert_received {:request, "PATCH", "/indexes/rebuild_v2/settings", ^settings}
  end

  test "client swaps indexes through the explicit Meilisearch swap endpoint" do
    stub = Module.concat(__MODULE__, SwapIndexesReqStub)

    Req.Test.stub(stub, fn conn ->
      send(self(), {:request, conn.method, conn.request_path, conn.body_params})
      Req.Test.json(conn, %{"taskUid" => 33, "status" => "enqueued"})
    end)

    config = [
      meilisearch_url: "http://localhost:7700",
      req_options: [plug: {Req.Test, stub}]
    ]

    assert {:ok, %{"taskUid" => 33, "status" => "enqueued"}} =
             Scrypath.Meilisearch.Client.swap_indexes({"live_posts", "rebuild_posts_v2"}, config)

    assert_received {:request, "POST", "/swap-indexes",
                     %{"_json" => [%{"indexes" => ["live_posts", "rebuild_posts_v2"]}]}}
  end

  test "apply_settings/3 resolves schema settings and applies them to the explicit target index" do
    override_settings = %{sortable_attributes: ["inserted_at"]}

    assert {:ok,
            %{index: "posts_rebuild_v2", settings: settings, task: %{uid: 20, status: :enqueued}}} =
             Scrypath.Meilisearch.apply_settings(ConfiguredSearchablePost, "posts_rebuild_v2",
               settings: override_settings,
               meilisearch_client: RecordingClient
             )

    assert settings == %{
             searchable_attributes: ["title", "body"],
             typo_tolerance: [enabled: true],
             __unrecognized__: %{},
             sortable_attributes: ["inserted_at"]
           }

    assert_received {:client_update_settings, "posts_rebuild_v2", wire, config}

    assert wire == %{
             "searchableAttributes" => ["title", "body"],
             "sortableAttributes" => ["inserted_at"],
             "typoTolerance" => [enabled: true]
           }

    assert config[:settings] == override_settings
  end

  test "create_index/3 remains Meilisearch-native and honors target index overrides" do
    assert {:ok,
            %{
              live_index: "tenant_searchable_post",
              target_index: "tenant_searchable_post_v2",
              task: %{uid: 19, status: :enqueued}
            }} =
             Scrypath.Meilisearch.create_index(SearchablePost, "id",
               index_prefix: "tenant",
               target_index: "tenant_searchable_post_v2",
               meilisearch_client: RecordingClient
             )

    assert_received {:client_create_index, "tenant_searchable_post_v2", "id", config}
    assert config[:target_index] == "tenant_searchable_post_v2"
  end

  test "swap_indexes/2 keeps cutover under Scrypath.Meilisearch and uses the explicit target index" do
    assert {:ok,
            %{
              live_index: "tenant_searchable_post",
              target_index: "tenant_searchable_post_v2",
              task: %{uid: 21, status: :enqueued}
            }} =
             Scrypath.Meilisearch.swap_indexes(SearchablePost,
               index_prefix: "tenant",
               target_index: "tenant_searchable_post_v2",
               meilisearch_client: RecordingClient
             )

    assert_received {:client_swap_indexes,
                     {"tenant_searchable_post", "tenant_searchable_post_v2"}, config}

    assert config[:target_index] == "tenant_searchable_post_v2"
  end

  test "backend upsert preserves schema-configured document id fields" do
    documents = [%Document{id: "post-9", data: %{title: "Hello"}, source: :fields}]

    assert {:ok,
            %{
              index: "tenant_custom_id_post",
              document_ids: ["post-9"],
              task: %{uid: 17, status: :enqueued}
            }} =
             Scrypath.Meilisearch.upsert_documents(CustomIdPost, documents,
               index_prefix: "tenant",
               meilisearch_client: RecordingClient
             )

    assert_received {:client_upsert, "tenant_custom_id_post", ^documents, config}
    assert config[:document_id_field] == :external_id
  end
end
