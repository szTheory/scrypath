defmodule ScrypathEcommerceWeb.E2EControllerTest do
  use ScrypathEcommerceWeb.ConnCase
  use Oban.Testing, repo: ScrypathEcommerce.Repo

  alias Scrypath.Query
  alias ScrypathEcommerce.Catalog.Product

  defmodule SearchVisibleBackend do
    def name, do: :e2e_controller_test

    def index_name(_schema_module, _config), do: "e2e_controller_test_products"

    def create_index(_index_name, _primary_key, _config),
      do: {:ok, %{"taskUid" => 1, "status" => "enqueued"}}

    def update_settings(_index_name, _settings, _config),
      do: {:ok, %{"taskUid" => 2, "status" => "enqueued"}}

    def upsert_documents(_index_name, documents, _config),
      do: {:ok, %{"taskUid" => 3, "status" => "enqueued", "documents" => documents}}

    def delete_documents(_index_name, document_ids, _config),
      do: {:ok, %{"taskUid" => 4, "status" => "enqueued", "document_ids" => document_ids}}

    def task(uid, _config), do: {:ok, %{"uid" => uid, "status" => "succeeded"}}

    def tasks(_filters, _config), do: {:ok, %{"results" => []}}

    def get_settings(_index_name, _config), do: {:ok, %{}}

    def swap_indexes(_pair, _config), do: {:ok, %{"taskUid" => 5, "status" => "enqueued"}}

    def search(index_name, %Query{} = query, _config) do
      if pid = Process.whereis(:e2e_controller_test) do
        send(pid, {:search_visible_query, index_name, query})
      end

      {:ok, %{"hits" => [%{"name" => "Quantum CyberPhone X"}]}}
    end

    def facet_search(_index_name, _facet_name, facet_query, _opts, _config) do
      {:ok, %{"facetQuery" => facet_query, "facetHits" => []}}
    end

    def multi_search(_payload, _config), do: {:ok, %{"hits" => []}}
  end

  setup do
    defaults = Application.get_env(:scrypath, :defaults, [])

    Application.put_env(
      :scrypath,
      :defaults,
      Keyword.put(defaults, :meilisearch_client, SearchVisibleBackend)
    )

    on_exit(fn ->
      Application.put_env(:scrypath, :defaults, defaults)
    end)

    :ok
  end

  describe "POST /dev/e2e/seed" do
    test "seeds e2e_search_catalog and returns deterministic ids", %{conn: conn} do
      conn = post(conn, ~p"/dev/e2e/seed", scenario: "e2e_search_catalog")

      assert %{
               "tenant_id" => tenant_id,
               "categories" => %{
                 "Smartphones" => smartphones_id,
                 "Laptops" => laptops_id
               },
               "products" => %{
                 "Quantum CyberPhone X" => product_x_id,
                 "Quantum CyberPhone Pro" => product_pro_id,
                 "Nebula Ultrabook" => nebula_id
               }
             } = json_response(conn, 200)

      assert is_integer(tenant_id)
      assert is_integer(smartphones_id)
      assert is_integer(laptops_id)
      assert is_integer(product_x_id)
      assert is_integer(product_pro_id)
      assert is_integer(nebula_id)

      assert %ScrypathEcommerce.Catalog.Tenant{} =
               ScrypathEcommerce.Catalog.get_tenant!(tenant_id)
    end

    test "returns 400 for unknown scenario", %{conn: conn} do
      conn = post(conn, ~p"/dev/e2e/seed", scenario: "invalid_scenario_123")

      assert %{"error" => "Unknown scenario: invalid_scenario_123"} = json_response(conn, 400)
    end
  end

  describe "POST /dev/e2e/drain" do
    test "returns drain counts", %{conn: conn} do
      conn = post(conn, ~p"/dev/e2e/drain", %{})

      assert %{"success" => success, "failure" => failure} = json_response(conn, 200)
      assert is_integer(success)
      assert is_integer(failure)
    end
  end

  describe "GET /dev/e2e/search-visible" do
    test "category readiness filter preserves tenant scope", %{conn: conn} do
      Process.register(self(), :e2e_controller_test)

      on_exit(fn ->
        if Process.whereis(:e2e_controller_test) do
          Process.unregister(:e2e_controller_test)
        end
      end)

      conn =
        get(conn, ~p"/dev/e2e/search-visible", %{
          tenant_id: "101",
          category_id: "202",
          query: "quantum"
        })

      assert %{"hits" => ["Quantum CyberPhone X"]} = json_response(conn, 200)

      assert_receive {:search_visible_query, _index_name, %Query{text: "quantum", filter: filter}}
      assert Enum.sort(filter) == [category_id: 202, tenant_id: 101]
    end
  end

  describe "POST /dev/e2e/category-name" do
    test "renames seeded category and reports queued related sync", %{conn: conn} do
      seed_conn = post(conn, ~p"/dev/e2e/seed", scenario: "e2e_search_catalog")

      assert %{
               "tenant_id" => tenant_id,
               "categories" => %{"Smartphones" => category_id}
             } = json_response(seed_conn, 200)

      conn =
        post(conn, ~p"/dev/e2e/category-name", %{
          tenant_id: tenant_id,
          category_id: category_id,
          name: "Pocket Superphones"
        })

      assert %{
               "category_id" => ^category_id,
               "name" => "Pocket Superphones",
               "queued_related_sync" => true
             } = json_response(conn, 200)

      assert_enqueued(
        worker: Scrypath.Sync.RelatedWorker,
        args: %{
          "schema" => "Elixir.ScrypathEcommerce.Catalog.Category",
          "document_ids" => [category_id],
          "fan_out" => "products"
        }
      )
    end

    test "returns deterministic 400 for invalid numeric params", %{conn: conn} do
      conn =
        post(conn, ~p"/dev/e2e/category-name", %{
          tenant_id: "not-an-int",
          category_id: "also-bad",
          name: "Pocket Superphones"
        })

      assert %{"error" => "invalid integer parameter"} = json_response(conn, 400)
    end
  end

  describe "POST /dev/e2e/product-delete" do
    test "deletes a seeded product and queues delete sync", %{conn: conn} do
      seed_conn = post(conn, ~p"/dev/e2e/seed", scenario: "e2e_search_catalog")

      assert %{
               "tenant_id" => tenant_id,
               "products" => %{"Quantum CyberPhone Pro" => product_id}
             } = json_response(seed_conn, 200)

      conn =
        post(conn, ~p"/dev/e2e/product-delete", %{
          tenant_id: tenant_id,
          product_id: product_id
        })

      assert %{
               "product_id" => ^product_id,
               "deleted" => true,
               "queued_delete_sync" => true
             } = json_response(conn, 200)
    end

    test "returns deterministic 400 for invalid numeric params", %{conn: conn} do
      conn =
        post(conn, ~p"/dev/e2e/product-delete", %{
          tenant_id: "not-an-int",
          product_id: "also-bad"
        })

      assert %{"error" => "invalid integer parameter"} = json_response(conn, 400)
    end
  end

  describe "POST /dev/e2e/inject-failed-sync" do
    test "injects one deterministic failed work item and is one-shot per scenario key", %{
      conn: conn
    } do
      seed_conn = post(conn, ~p"/dev/e2e/seed", scenario: "e2e_search_catalog")
      assert %{"tenant_id" => tenant_id} = json_response(seed_conn, 200)

      conn =
        post(conn, ~p"/dev/e2e/inject-failed-sync", %{
          tenant_id: tenant_id,
          scenario_key: "failed-sync-operator-triage"
        })

      assert %{
               "failed_work_id" => failed_work_id,
               "schema" => schema,
               "state" => state,
               "reason_class" => reason_class
             } = json_response(conn, 200)

      assert is_integer(failed_work_id)

      assert schema in [
               "Elixir.ScrypathEcommerce.Catalog.Product",
               "ScrypathEcommerce.Catalog.Product"
             ]

      assert state in ["failed", "retrying"]

      assert reason_class in [
               "transport",
               "validation",
               "backend_rejected",
               "queue_exhausted",
               "unknown"
             ]

      assert {:ok, failed_work} =
               Scrypath.failed_sync_work(Product,
                 sync_mode: :oban,
                 oban_queue: :scrypath_sync,
                 oban_inspector: ScrypathEcommerceWeb.E2EObanInspector
               )

      assert Enum.any?(failed_work, fn row ->
               to_string(row.schema) == "Elixir.ScrypathEcommerce.Catalog.Product"
             end)

      second_conn =
        post(conn, ~p"/dev/e2e/inject-failed-sync", %{
          tenant_id: tenant_id,
          scenario_key: "failed-sync-operator-triage"
        })

      assert %{
               "failed_work_id" => ^failed_work_id,
               "schema" => ^schema,
               "state" => second_state,
               "reason_class" => second_reason_class
             } = json_response(second_conn, 200)

      assert second_state in ["failed", "retrying"]

      assert second_reason_class in [
               "transport",
               "validation",
               "backend_rejected",
               "queue_exhausted",
               "unknown"
             ]

      third_conn =
        post(conn, ~p"/dev/e2e/inject-failed-sync", %{
          tenant_id: tenant_id,
          scenario_key: "failed-sync-operator-triage-alt"
        })

      assert %{"failed_work_id" => third_failed_work_id} = json_response(third_conn, 200)
      assert third_failed_work_id != failed_work_id
    end
  end

  describe "GET /dev/e2e/operator-state" do
    test "returns deterministic 400 for invalid tenant id", %{conn: conn} do
      conn = get(conn, ~p"/dev/e2e/operator-state", %{tenant_id: "not-an-int"})

      assert %{"error" => "invalid integer parameter"} = json_response(conn, 400)
    end

    test "returns stable failed-work and swap outcome summary without leaking raw payloads", %{
      conn: conn
    } do
      seed_conn = post(conn, ~p"/dev/e2e/seed", scenario: "e2e_search_catalog")

      assert %{
               "tenant_id" => tenant_id,
               "products" => %{"Quantum CyberPhone X" => _product_id}
             } = json_response(seed_conn, 200)

      _inject_conn =
        post(conn, ~p"/dev/e2e/inject-failed-sync", %{
          tenant_id: tenant_id,
          scenario_key: "operator-state-summary"
        })

      conn = get(conn, ~p"/dev/e2e/operator-state", %{tenant_id: tenant_id})
      body = json_response(conn, 200)

      assert %{
               "failed_count" => failed_count,
               "retryable" => retryable,
               "first_failed_work_id" => first_failed_work_id,
               "reason_class_counts" => reason_class_counts,
               "swap_terminal_success" => swap_terminal_success,
               "swap_terminal_state" => swap_terminal_state,
               "active_index" => active_index,
               "active_index_visible" => active_index_visible
             } = body

      assert is_integer(failed_count)
      assert is_boolean(retryable)
      assert is_map(reason_class_counts)
      assert is_boolean(swap_terminal_success)
      assert swap_terminal_state in ["completed", "pending", "not_started", "unknown"]
      assert is_binary(active_index)
      assert is_boolean(active_index_visible)
      assert first_failed_work_id == nil or is_integer(first_failed_work_id)
      refute Map.has_key?(body, "args")
      refute Map.has_key?(body, "documents")
      refute Map.has_key?(body, "taskUid")
      refute Map.has_key?(body, "raw")
    end
  end
end
