defmodule ScrypathEcommerceWeb.E2EControllerTest do
  use ScrypathEcommerceWeb.ConnCase

  describe "POST /dev/e2e/seed" do
    test "seeds standard_catalog and returns 200", %{conn: conn} do
      conn = post(conn, ~p"/dev/e2e/seed", scenario: "standard_catalog")

      assert %{"message" => "Seeded standard catalog successfully", "tenant_id" => tenant_id} = json_response(conn, 200)
      assert is_integer(tenant_id)

      # Verify the tenant was actually created in the DB
      assert %ScrypathEcommerce.Catalog.Tenant{} = ScrypathEcommerce.Catalog.get_tenant!(tenant_id)
    end

    test "returns 400 for unknown scenario", %{conn: conn} do
      conn = post(conn, ~p"/dev/e2e/seed", scenario: "invalid_scenario_123")

      assert %{"error" => "Unknown scenario: invalid_scenario_123"} = json_response(conn, 400)
    end
  end
end
