defmodule ScrypathEcommerceWeb.E2EControllerTest do
  use ScrypathEcommerceWeb.ConnCase

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
end
