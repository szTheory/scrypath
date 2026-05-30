defmodule ScrypathEcommerceWeb.E2EControllerTest do
  use ScrypathEcommerceWeb.ConnCase
  use Oban.Testing, repo: ScrypathEcommerce.Repo

  alias ScrypathEcommerce.Catalog.Product

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

      assert %ScrypathEcommerce.Catalog.Tenant{} = ScrypathEcommerce.Catalog.get_tenant!(tenant_id)
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
  end

  describe "POST /dev/e2e/inject-failed-sync" do
    test "injects one deterministic failed work item and is one-shot per scenario key", %{conn: conn} do
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
      assert schema in ["Elixir.ScrypathEcommerce.Catalog.Product", "ScrypathEcommerce.Catalog.Product"]
      assert state in ["failed", "retrying"]
      assert reason_class in ["transport", "validation", "backend_rejected", "queue_exhausted", "unknown"]

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
      assert second_reason_class in ["transport", "validation", "backend_rejected", "queue_exhausted", "unknown"]

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
    test "returns stable failed-work summary without leaking raw payloads", %{conn: conn} do
      seed_conn = post(conn, ~p"/dev/e2e/seed", scenario: "e2e_search_catalog")
      assert %{"tenant_id" => tenant_id} = json_response(seed_conn, 200)

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
               "reason_class_counts" => reason_class_counts
             } = body

      assert is_integer(failed_count)
      assert is_boolean(retryable)
      assert is_map(reason_class_counts)
      assert first_failed_work_id == nil or is_integer(first_failed_work_id)
      refute Map.has_key?(body, "args")
      refute Map.has_key?(body, "documents")
    end
  end
end
