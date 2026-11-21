defmodule ScrypathOpsWeb.CatalogContractTest do
  use ScrypathOpsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  # The catalog contract file: Plan 02 and Phase 197 extend it. It adds no gate row and no CI context.

  describe "mount" do
    test "the real iframe route renders the production ops_button with the built stylesheet", %{
      conn: conn
    } do
      {:ok, _view, html} =
        live(conn, "/storybook/iframe/primitives/ops_button?variation_id=default&theme=light")

      doc = LazyHTML.from_document(html)

      button = LazyHTML.query(doc, "[data-phx-main] button")
      refute Enum.empty?(button)
      assert LazyHTML.text(button) =~ "Retry"

      styles = doc |> LazyHTML.query("style") |> LazyHTML.text()
      assert styles =~ ~r|@import "/assets/css/app\.css\?hash=[0-9a-f]{32}"|

      refute Enum.empty?(LazyHTML.query(doc, ~s(body[data-theme="light"])))
    end
  end
end
