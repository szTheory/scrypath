defmodule ScrypathOpsWeb.CatalogContractTest do
  use ScrypathOpsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias ScrypathOps.Catalog.RenderAll
  alias ScrypathOps.Test.CatalogChecks

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

  describe "no two identical variations" do
    test "no two variations of one story render the same page in a theme" do
      digests =
        for {path, variation_id, theme, {:ok, html}} <- render_every_variation() do
          {path, variation_id, theme, CatalogChecks.main_digest(html)}
        end

      # The cause is real data: the catalog has stories with several variations to compare.
      assert length(digests) > length(Enum.uniq_by(digests, &elem(&1, 0)))

      assert CatalogChecks.identical_variations(digests) == [],
             "variations that render identically (drop one or make it show a different state): " <>
               inspect(CatalogChecks.identical_variations(digests))
    end
  end

  describe "DOM hygiene" do
    test "every rendered story has unique ids, resolvable ARIA references and named controls" do
      problems =
        for {path, variation_id, theme, rendered} <- render_every_variation(),
            problem <- hygiene_problems(path, rendered) do
          {path, variation_id, theme, problem}
        end

      assert problems == [], "DOM hygiene problems: #{inspect(problems)}"
    end
  end

  describe "planted catalog checks" do
    test "identical_variations/1 reports a planted pair with its cause and ignores distinct pages" do
      distinct = [
        {"/areas/row", "retryable", "light", "d1"},
        {"/areas/row", "retrying", "light", "d2"}
      ]

      assert CatalogChecks.identical_variations(distinct) == []

      planted = distinct ++ [{"/areas/row", "retry_queued", "light", "d1"}]

      assert CatalogChecks.identical_variations(planted) ==
               [{:identical, "/areas/row", "light", ["retry_queued", "retryable"]}]

      # The same digest in another theme or another story is not a pair.
      apart = [
        {"/areas/row", "retryable", "light", "d1"},
        {"/areas/row", "retryable", "dark", "d1"},
        {"/areas/other", "retryable", "light", "d1"}
      ]

      assert CatalogChecks.identical_variations(apart) == []
    end

    test "main_digest/1 hashes the story's markup and ignores the per-mount session tokens" do
      page = fn token, text ->
        ~s(<html><body><div data-phx-main data-phx-session="#{token}" data-phx-static="#{token}">) <>
          ~s(<section><p>#{text}</p></section></div></body></html>)
      end

      assert CatalogChecks.main_digest(page.("aaa", "Same")) ==
               CatalogChecks.main_digest(page.("bbb", "Same"))

      refute CatalogChecks.main_digest(page.("aaa", "Same")) ==
               CatalogChecks.main_digest(page.("aaa", "Different"))
    end

    test "dom_problems/2 passes the real production render" do
      conn = build_conn()

      {:ok, _view, html} =
        live(conn, "/storybook/iframe/primitives/ops_button?variation_id=default&theme=light")

      assert CatalogChecks.dom_problems(html, CatalogChecks.tier("/primitives/ops_button")) == []
    end

    test "dom_problems/2 reports a cause planted into the real Failed sync renders", %{conn: conn} do
      {:ok, _view, filters} =
        live(
          conn,
          "/storybook/iframe/patterns/failed_filters?variation_id=shopadelic_failed_journey_mixed_causes&theme=light"
        )

      {:ok, _view, surface} =
        live(
          conn,
          "/storybook/iframe/surfaces/failed_sync?variation_id=shopadelic_failed_journey&theme=light"
        )

      # Controls: the real renders are clean, so each failure below comes from the edit.
      assert CatalogChecks.dom_problems(filters, :pattern) == []
      assert CatalogChecks.dom_problems(surface, :surface) == []

      # The cause chips are checkboxes named only by their wrapping label: without the labels none is
      # named.
      boxes =
        filters
        |> LazyHTML.from_document()
        |> LazyHTML.query("[data-phx-main] input[type=checkbox]")
        |> Enum.count()

      assert boxes > 0

      assert CatalogChecks.dom_problems(
               Regex.replace(~r/<\/?label\b[^>]*>/, filters, ""),
               :pattern
             ) ==
               List.duplicate({:unnamed_control, "input"}, boxes)

      # The summary section is labelled by the verdict heading's id: rename the id and the reference
      # dangles.
      renamed = String.replace(surface, ~s(id="failed-sync-summary-heading"), ~s(id="renamed"))
      refute renamed == surface

      assert CatalogChecks.dom_problems(renamed, :surface) ==
               [{:dangling_aria, "aria-labelledby", "failed-sync-summary-heading"}]
    end

    test "dom_problems/2 reports each planted cause as its own tagged problem" do
      assert CatalogChecks.dom_problems(page(~s(<p id="x">A</p><p id="x">B</p>)), :area) ==
               [{:duplicate_id, "x"}]

      assert CatalogChecks.dom_problems(page(~s(<div aria-describedby="false">A</div>)), :area) ==
               [{:dangling_aria, "aria-describedby", "false"}]

      assert CatalogChecks.dom_problems(page(~s(<div aria-labelledby="nope">A</div>)), :area) ==
               [{:dangling_aria, "aria-labelledby", "nope"}]

      assert CatalogChecks.dom_problems(page(~s(<div aria-controls="a b" id="a">A</div>)), :area) ==
               [{:dangling_aria, "aria-controls", "b"}]

      assert CatalogChecks.dom_problems(page("<button></button>"), :area) ==
               [{:unnamed_control, "button"}]

      assert CatalogChecks.dom_problems(
               page(~s(<button><span aria-hidden="true">x</span></button>)),
               :area
             ) == [{:unnamed_control, "button"}]

      assert CatalogChecks.dom_problems(page(~s(<a href="/x"></a>)), :area) ==
               [{:unnamed_control, "a"}]

      assert CatalogChecks.dom_problems(page(~s(<input type="checkbox" name="a">)), :area) ==
               [{:unnamed_control, "input"}]

      assert CatalogChecks.dom_problems(page("<p>No landmark</p>"), :surface) ==
               [{:main_count, 0}]

      assert CatalogChecks.dom_problems(page("<main>A</main><main>B</main>"), :surface) ==
               [{:main_count, 2}]

      assert CatalogChecks.dom_problems(
               page(~s(<main>A</main><div role="main">B</div>)),
               :surface
             ) ==
               [{:main_count, 2}]
    end

    test "dom_problems/2 accepts the ways a control is really named, and only checks mains on surfaces" do
      # A checkbox named only by its wrapping label (the Failed sync cause chips).
      assert CatalogChecks.dom_problems(
               page(~s(<label><input type="checkbox" name="a"><span>Cause</span></label>)),
               :area
             ) == []

      # A wrapping label with no text names nothing.
      assert CatalogChecks.dom_problems(
               page(~s(<label><input type="checkbox" name="a"></label>)),
               :area
             ) == [{:unnamed_control, "input"}]

      named = [
        ~s(<button>Retry</button>),
        ~s(<button aria-label="Close"><svg aria-hidden="true"></svg></button>),
        ~s(<button title="Copy"></button>),
        ~s(<h2 id="t">Title</h2><button aria-labelledby="t"></button>),
        ~s(<label for="a">Name</label><input id="a">),
        ~s(<a href="/x"><span class="sr-only">Home</span></a>),
        ~s(<input type="submit" value="Save">),
        ~s(<input type="hidden" name="csrf">),
        ~s(<button><img alt="Run" src="/x.png"></button>)
      ]

      for fragment <- named do
        assert CatalogChecks.dom_problems(page(fragment), :area) == [], fragment
      end

      # An id that resolves, and exactly one main, are clean.
      assert CatalogChecks.dom_problems(
               page(~s(<main><h2 id="t">T</h2><section aria-labelledby="t">S</section></main>)),
               :surface
             ) == []

      # Mains are only counted for surface-tier stories.
      assert CatalogChecks.dom_problems(page("<p>No landmark</p>"), :area) == []
    end

    test "tier/1 reads the story path's first segment" do
      assert CatalogChecks.tier("/surfaces/failed_sync") == :surface
      assert CatalogChecks.tier("/areas/failed_row") == :area
      assert CatalogChecks.tier("/patterns/failed_filters") == :pattern
      assert CatalogChecks.tier("/primitives/ops_button") == :primitive
      assert CatalogChecks.tier("/jobs/job_03") == :job
      assert CatalogChecks.tier("/welcome") == :other
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
    case render_document(endpoint, url) do
      {:ok, html} ->
        {:rendered, RenderAll.problems(html) ++ List.wrap(RenderAll.theme_problem(html, theme))}

      {:crashed, _kind, _cause} = crashed ->
        crashed
    end
  end

  # The rendered iframe document, or the crash that took the render down.
  defp render_document(endpoint, url) do
    conn = Phoenix.ConnTest.dispatch(build_conn(), endpoint, :get, url, nil)
    {:ok, _view, html} = live(conn)
    {:ok, html}
  catch
    kind, reason -> {:crashed, kind, crash_cause(reason)}
  end

  # Every variation of every story in both themes through the real endpoint, as
  # `{path, variation_id, theme, {:ok, html} | {:crashed, kind, cause}}`.
  defp render_every_variation do
    for {path, variation_id} <- RenderAll.targets(ScrypathOps.Catalog.Storybook),
        theme <- @themes do
      url = RenderAll.url("/storybook", path, variation_id, theme)
      {path, variation_id, theme, render_document(ScrypathOpsWeb.Endpoint, url)}
    end
  end

  defp hygiene_problems(path, {:ok, html}),
    do: CatalogChecks.dom_problems(html, CatalogChecks.tier(path))

  defp hygiene_problems(_path, {:crashed, kind, cause}), do: [{:crashed, kind, cause}]

  # A rendered iframe document around a hand-written fragment.
  defp page(fragment) do
    ~s(<html><body><div data-phx-main data-phx-session="s" data-phx-static="t">#{fragment}</div></body></html>)
  end

  # The cause keeps a crash attributable: without it a mistyped route (StoryNotFound) or a missing
  # error view would read as the same "crashed" as the failure the plant is meant to show.
  defp crash_cause(%Plug.Conn.WrapperError{reason: reason}), do: crash_cause(reason)

  defp crash_cause(%{__exception__: true} = exception),
    do: Exception.format_banner(:error, exception)

  defp crash_cause(reason), do: inspect(reason)
end
