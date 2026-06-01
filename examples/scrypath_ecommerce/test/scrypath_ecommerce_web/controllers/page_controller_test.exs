defmodule ScrypathEcommerceWeb.PageControllerTest do
  use ScrypathEcommerceWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Tenant-scoped catalog search"
  end

  test "GET /admin/search/posture", %{conn: conn} do
    conn = get(conn, ~p"/admin/search/posture")
    html = html_response(conn, 200)

    assert html =~ "Posture / health"
    assert html =~ ~s(href="/admin/search/assets/css/app.css")
    assert html =~ ~s(src="/assets/js/app.js")
  end

  test "GET / keeps ScrypathOps mounted asset out of storefront", %{conn: conn} do
    conn = get(conn, ~p"/")
    html = html_response(conn, 200)

    refute html =~ ~s(href="/admin/search/assets/css/app.css")
  end
end
