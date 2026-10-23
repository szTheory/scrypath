defmodule ScrypathEcommerceWeb.E2ESavedSearchesTest do
  use ScrypathEcommerceWeb.ConnCase

  @definition %{
    "playbook_format" => 1,
    "mode" => "search",
    "schema" => "ScrypathEcommerce.Catalog.Product",
    "q" => "Quantum",
    "opts" => %{}
  }

  test "saved-search fixtures are written, listed and deleted through the database", %{conn: conn} do
    assert %{"name" => "spec-a"} =
             conn
             |> post(~p"/dev/e2e/saved-searches", %{name: "spec-a", definition: @definition})
             |> json_response(200)

    # A spec can seed a definition the v1 validator rejects; it still lists.
    post(conn, ~p"/dev/e2e/saved-searches", %{name: "spec-b", definition: %{"q" => "x"}})
    post(conn, ~p"/dev/e2e/saved-searches", %{name: "keep", definition: @definition})

    names =
      conn
      |> get(~p"/dev/e2e/saved-searches")
      |> json_response(200)
      |> Map.fetch!("saved_searches")
      |> Enum.map(& &1["name"])

    assert names == ["keep", "spec-a", "spec-b"]

    assert %{"deleted" => 2} =
             conn
             |> post(~p"/dev/e2e/saved-searches/delete", %{prefix: "spec-"})
             |> json_response(200)

    assert %{"deleted" => 1} =
             conn
             |> post(~p"/dev/e2e/saved-searches/delete", %{names: ["keep"]})
             |> json_response(200)

    assert ScrypathOps.SavedSearches.list(ScrypathEcommerce.Repo) == []
  end
end
