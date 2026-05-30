defmodule ScrypathEcommerceWeb.PageControllerTest do
  use ScrypathEcommerceWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Catalog Search"
  end

  test "GET /admin/search/posture", %{conn: conn} do
    conn = get(conn, ~p"/admin/search/posture")
    assert html_response(conn, 200) =~ "Posture / health"
  end
end
