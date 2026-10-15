defmodule ScrypathOpsWeb.HelpLiveTest do
  use ScrypathOpsWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  test "help is within the same shell and links to scoped tasks", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/ops/help")
    assert has_element?(view, "h1#ops-page-title", "Help")
    assert has_element?(view, "a[href='/ops/search']", "Open Search")
    assert has_element?(view, "a[href='/ops/playbooks']", "Open Saved searches")
    assert has_element?(view, "nav a[href='/ops/help'][aria-current=page]")
    assert has_element?(view, "section#saved-searches")
    assert has_element?(view, "section#sync")
    assert has_element?(view, "p#ranking")
  end
end
