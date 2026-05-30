defmodule ScrypathEcommerceWeb.E2EController do
  use ScrypathEcommerceWeb, :controller

  alias ScrypathEcommerce.CatalogFixtures

  def seed(conn, %{"scenario" => scenario}) do
    case scenario do
      "standard_catalog" ->
        # Generate the standard catalog scenario data
        data = CatalogFixtures.scenario_standard_catalog()

        # Extract only the data needed by the test (like tenant id) or serialize the full map
        json(conn, %{
          message: "Seeded standard catalog successfully",
          tenant_id: data.tenant.id
        })

      _ ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Unknown scenario: #{scenario}"})
    end
  end
end
