defmodule ScrypathEcommerceWeb.PageControllerTest do
  use ScrypathEcommerceWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Tenant-scoped catalog search"
  end

  test "GET /admin/search/health", %{conn: conn} do
    conn = get(conn, ~p"/admin/search/health")
    html = html_response(conn, 200)

    assert html =~ "Search health"
    assert html =~ ~s(href="/admin/search/favicon.svg")
    assert html =~ ~s(href="/admin/search/favicon.ico")
    assert html =~ ~r|href="/admin/search/assets/css/app\.css\?v=[a-f0-9]{64}"|
    assert html =~ ~r/src="\/assets\/js\/app(?:-[^"]+)?\.js(?:\?[^"]*)?"/
    assert html =~ ~s(href="/admin/search/failed-sync")
    assert html =~ ~s(href="/admin/search/sync-drift")
    refute html =~ ~s(href="/search/failed-sync")
    refute html =~ ~s(href="/search/sync-drift")
  end

  test "mounted ScrypathOps favicon routes serve the package brand assets", %{conn: conn} do
    svg = get(conn, "/admin/search/favicon.svg")
    assert response(svg, 200) =~ "<svg"
    assert Plug.Conn.get_resp_header(svg, "content-type") == ["image/svg+xml; charset=utf-8"]

    ico = get(conn, "/admin/search/favicon.ico")

    assert response(ico, 200) ==
             File.read!(Application.app_dir(:scrypath_ops, "priv/static/favicon.ico"))
  end

  test "GET /admin/search keeps generated operator links inside nested mount", %{conn: conn} do
    conn = get(conn, ~p"/admin/search")
    html = html_response(conn, 200)

    assert html =~ "Control Room"

    assert html =~
             ~s(href="/admin/search" data-phx-link="redirect" data-phx-link-state="push")

    assert html =~
             ~s(href="/admin/search" data-phx-link="redirect" data-phx-link-state="push" id="ops-cmdk-item-0")

    for path <- ~w(
           /admin/search/health
           /admin/search/failed-sync
           /admin/search/sync-drift
           /admin/search/search
           /admin/search/playbooks
         ) do
      assert html =~ ~s(href="#{path}")
    end

    refute html =~ ~s(href="/admin")
    refute html =~ ~s(href="/admin/posture")
    refute html =~ ~s(href="/admin/failed-sync")
    refute html =~ ~s(href="/admin/sync-drift")
    refute html =~ ~s(href="/admin/playbooks")
  end

  test "GET / keeps ScrypathOps mounted asset out of storefront", %{conn: conn} do
    conn = get(conn, ~p"/")
    html = html_response(conn, 200)

    refute html =~ "/admin/search/assets/css/app.css"
    refute html =~ "/admin/search/favicon.svg"
  end
end
