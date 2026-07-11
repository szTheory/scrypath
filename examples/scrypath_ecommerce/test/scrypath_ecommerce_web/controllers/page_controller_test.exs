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
    assert html =~ ~r/src="\/assets\/js\/app(?:-[^"]+)?\.js(?:\?[^"]*)?"/
    assert html =~ ~s(href="/admin/search/failed-sync")
    assert html =~ ~s(href="/admin/search/sync-drift")
    refute html =~ ~s(href="/search/failed-sync")
    refute html =~ ~s(href="/search/sync-drift")
  end

  test "GET /admin/search keeps generated operator links inside nested mount", %{conn: conn} do
    conn = get(conn, ~p"/admin/search")
    html = html_response(conn, 200)

    assert html =~ "Control Room"

    assert html =~
             ~s(href="/admin/search" data-phx-link="redirect" data-phx-link-state="push" class="flex w-fit items-center gap-3")

    assert html =~
             ~s(href="/admin/search" data-phx-link="redirect" data-phx-link-state="push" id="ops-cmdk-item-0")

    for path <- ~w(
           /admin/search/posture
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

    refute html =~ ~s(href="/admin/search/assets/css/app.css")
  end
end
