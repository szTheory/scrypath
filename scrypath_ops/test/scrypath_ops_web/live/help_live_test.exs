defmodule ScrypathOpsWeb.HelpLiveTest do
  use ScrypathOpsWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  test "help is within the same shell and links to scoped tasks", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/ops/help")
    assert has_element?(view, "h1#ops-page-title", "Help")
    assert has_element?(view, "a[href='/ops/search']", "Open Search")
    assert has_element?(view, "a[href='/ops/search?saved=manage']", "Manage saved searches")
    refute render(view) =~ "folder"
    assert has_element?(view, "nav a[href='/ops/help'][aria-current=page]")
    assert has_element?(view, "section#saved-searches")
    assert has_element?(view, "section#sync")
    assert has_element?(view, "section#ranking h3")
  end

  test "section headings are plain text with no icon", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/ops/help")

    for {id, heading} <- [
          {"search", "Try a search"},
          {"saved-searches", "Save and reuse a search"},
          {"sync", "Understand a sync problem"},
          {"settings", "Check index settings"},
          {"reindexing", "Zero-downtime reindexing"}
        ] do
      assert has_element?(view, "section##{id} > h2", heading)
      refute has_element?(view, "section##{id} > h2 svg")
      refute has_element?(view, "section##{id} > h2 span")
    end

    refute has_element?(view, ".ops-help-heading")
  end
end
