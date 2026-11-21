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

  @primitive_stories [
    "/primitives/ops_button",
    "/primitives/ops_badge",
    "/primitives/ops_panel",
    "/primitives/ops_empty_state",
    "/primitives/ops_sync_status"
  ]
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

  describe "planted tree" do
    setup do
      start_supervised!(ScrypathOps.Catalog.PlantedEndpoint)
      :ok
    end

    test "the same render-all path reports the planted crash, empty story and unknown variation" do
      # The unknown id is planted on the raising story (the plan's case) and on the story that renders
      # fine on its own, so the second crash can only come from the unknown id, not from a raising story.
      targets =
        RenderAll.targets(ScrypathOps.Catalog.PlantedStorybook) ++
          [{"/failing/boom", "no_such_variation"}, {"/failing/empty", "no_such_variation"}]

      {results, _log} =
        ExUnit.CaptureLog.with_log(fn ->
          Map.new(targets, fn {path, variation_id} ->
            url = RenderAll.url("/storybook", path, variation_id, "light")

            {{path, variation_id},
             render_target(ScrypathOps.Catalog.PlantedEndpoint, url, "light")}
          end)
        end)

      # A story that raises, or an id no variation owns, takes the iframe render down; both are errors
      # raised out of the request (the endpoint re-raises after rendering its 500 page), each with its own cause.
      assert results == %{
               {"/failing/boom", "boom"} =>
                 {:crashed, :error, "** (RuntimeError) planted render failure"},
               {"/failing/empty", "empty"} => {:rendered, ["empty output"]},
               {"/failing/boom", "no_such_variation"} => {:crashed, :error, ":function_clause"},
               {"/failing/empty", "no_such_variation"} => {:crashed, :error, ":function_clause"}
             }
    end

    test "problems/1 flags a missing sandbox, stripped hashes and a data-phx-error marker", %{
      conn: conn
    } do
      assert "no LiveView sandbox container" in RenderAll.problems("<html><body></body></html>")

      {:ok, _view, html} =
        live(conn, "/storybook/iframe/primitives/ops_button?variation_id=default&theme=light")

      # Control: the production render passes every check, so the failures below come from the edit.
      assert RenderAll.problems(html) == []
      assert RenderAll.theme_problem(html, "light") == nil
      assert RenderAll.theme_problem(html, "dark") == "body data-theme is not dark"

      stripped = Regex.replace(~r/\?hash=[0-9a-f]{32}/, html, "")
      refute stripped == html

      assert RenderAll.problems(stripped) == [
               "css_path did not resolve (no ?hash=)",
               "js_path did not resolve (no ?hash=)"
             ]

      marked =
        String.replace(html, "data-phx-main", ~s(data-phx-error="planted" data-phx-main),
          global: false
        )

      assert marked
             |> LazyHTML.from_document()
             |> LazyHTML.query("[data-phx-main][data-phx-error]")
             |> Enum.empty?() == false

      assert RenderAll.problems(marked) == ["data-phx-error present"]
    end
  end

  # Renders one iframe url through the real LiveView mount and returns the problems found, or
  # {:crashed, kind, cause} when the story or the route took the render down (the request raises or the
  # LiveView exits; both are caught, so a crash is data here, not a test error).
  defp render_target(endpoint, url, theme) do
    conn = Phoenix.ConnTest.dispatch(build_conn(), endpoint, :get, url, nil)
    {:ok, _view, html} = live(conn)
    {:rendered, RenderAll.problems(html) ++ List.wrap(RenderAll.theme_problem(html, theme))}
  catch
    kind, reason -> {:crashed, kind, crash_cause(reason)}
  end

  # The cause keeps a crash attributable: without it a mistyped route (StoryNotFound) or a missing
  # error view would read as the same "crashed" as the failure the plant is meant to show.
  defp crash_cause(%Plug.Conn.WrapperError{reason: reason}), do: crash_cause(reason)

  defp crash_cause(%{__exception__: true} = exception),
    do: Exception.format_banner(:error, exception)

  defp crash_cause(reason), do: inspect(reason)
end
