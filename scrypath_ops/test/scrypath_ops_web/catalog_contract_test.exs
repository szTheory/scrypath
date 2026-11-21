defmodule ScrypathOpsWeb.CatalogContractTest do
  use ScrypathOpsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias ScrypathOps.Catalog.RenderAll

  # The catalog contract file: Plan 02 and Phase 197 extend it. It adds no gate row and no CI context.
  #
  # Phase 197 handoff: every story under scrypath_ops/storybook is rendered by "render-all" below
  # through the real iframe route, in light and dark, so a new story needs no edit here. Extend
  # @primitive_stories only for a path that must never disappear. The planted-tree describe proves the
  # same render_target/2 plus RenderAll.problems/1 path fails on a crash, an empty story and an
  # unknown variation id; keep it green when you change either helper.

  @primitive_stories ["/primitives/ops_button"]
  @themes ["light", "dark"]

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

  describe "render-all" do
    test "every variation of every story renders non-empty with real css, js and theme" do
      targets = RenderAll.targets(ScrypathOps.Catalog.Storybook)
      paths = targets |> Enum.map(&elem(&1, 0)) |> Enum.uniq()

      for story <- @primitive_stories do
        assert story in paths, "missing story #{story}"
      end

      refute Enum.any?(targets, &match?({_, {:unsupported, _}}, &1))

      failures =
        for {path, variation_id} <- targets,
            theme <- @themes,
            result =
              render_target(
                ScrypathOpsWeb.Endpoint,
                RenderAll.url("/storybook", path, variation_id, theme),
                theme
              ),
            result != {:rendered, []},
            do: {path, variation_id, theme, result}

      assert failures == [], "render-all failures: #{inspect(failures)}"
    end
  end

  # Renders one iframe url through the real LiveView mount and returns the problems found, or
  # {:crashed, kind} when the story or the route took the LiveView down (a crash is an exit, not a raise).
  defp render_target(endpoint, url, theme) do
    conn = Phoenix.ConnTest.dispatch(build_conn(), endpoint, :get, url, nil)
    {:ok, _view, html} = live(conn)
    {:rendered, RenderAll.problems(html) ++ List.wrap(RenderAll.theme_problem(html, theme))}
  catch
    kind, _reason -> {:crashed, kind}
  end
end
