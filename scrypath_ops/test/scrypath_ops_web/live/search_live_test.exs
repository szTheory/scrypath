defmodule ScrypathOpsWeb.SearchLiveTest do
  @moduledoc false
  # Phase 47 D-10: SECURITY + prod guard tests. D-11: allowlist-only targeting.
  # D-15/D-16: no auto-run on mount; page ceiling copy; partial vs hard errors.
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScrypathOps.Test.OpsPostA
  alias ScrypathOps.Test.OpsPostB
  alias ScrypathOps.Test.SearchPlaygroundStubAdapter
  alias ScrypathOpsWeb.OpsUi

  defmodule RecordingAdapter do
    @behaviour ScrypathOps.SearchPlayground.Adapter

    def search(schema, text, opts) do
      send(
        Application.fetch_env!(:scrypath_ops, :search_live_test_pid),
        {:search_dispatched, schema, text, opts}
      )

      ScrypathOps.Test.SearchPlaygroundStubAdapter.search(schema, text, opts)
    end

    defdelegate search_many(entries, opts), to: ScrypathOps.Test.SearchPlaygroundStubAdapter

    defdelegate search_facet_values(schema, facet, query, opts),
      to: ScrypathOps.Test.SearchPlaygroundStubAdapter
  end

  setup do
    prev_allow = Application.get_env(:scrypath_ops, :schema_allowlist)
    prev_backend = Application.get_env(:scrypath_ops, :backend)
    prev_sync = Application.get_env(:scrypath_ops, :sync_mode)
    prev_prefix = Application.get_env(:scrypath_ops, :index_prefix)
    prev_url = Application.get_env(:scrypath_ops, :meilisearch_url)
    prev_adapter = Application.get_env(:scrypath_ops, :search_playground_adapter)
    prev_stub_variant = Application.get_env(:scrypath_ops, :search_stub_variant)
    prev_test_pid = Application.get_env(:scrypath_ops, :search_live_test_pid)

    Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostA, OpsPostB])
    Application.put_env(:scrypath_ops, :backend, Scrypath.Meilisearch)
    Application.put_env(:scrypath_ops, :sync_mode, :manual)
    Application.put_env(:scrypath_ops, :index_prefix, "sltlv")
    Application.put_env(:scrypath_ops, :meilisearch_url, "http://localhost:7700")
    Application.put_env(:scrypath_ops, :search_playground_adapter, SearchPlaygroundStubAdapter)
    Application.put_env(:scrypath_ops, :search_stub_variant, :ok)
    Application.put_env(:scrypath_ops, :search_live_test_pid, self())

    on_exit(fn ->
      restore = fn k, v ->
        if v == nil,
          do: Application.delete_env(:scrypath_ops, k),
          else: Application.put_env(:scrypath_ops, k, v)
      end

      restore.(:schema_allowlist, prev_allow)
      restore.(:backend, prev_backend)
      restore.(:sync_mode, prev_sync)
      restore.(:index_prefix, prev_prefix)
      restore.(:meilisearch_url, prev_url)
      restore.(:search_playground_adapter, prev_adapter)
      restore.(:search_stub_variant, prev_stub_variant)
      restore.(:search_live_test_pid, prev_test_pid)
    end)

    :ok
  end

  test "mount keeps one search submit and query advice beside the labelled input", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/ops/search")

    refute html =~ "Non-production search playground"
    assert html =~ "Search your schemas and save useful queries as playbooks."
    assert html =~ "Queries may be logged by the search backend or proxies."
    assert has_element?(view, "#search_q[aria-describedby='search-honesty-panel']")
    assert has_element?(view, "#ops-search-playground-form #search-honesty-panel")
    assert has_element?(view, "#ops-search-playground-form button[type=submit]", "Run search")

    submits =
      html
      |> LazyHTML.from_document()
      |> LazyHTML.query("button[type=submit]")
      |> LazyHTML.to_tree()

    assert length(submits) == 1
    refute has_element?(view, "button[form='ops-search-playground-form']")
    assert has_element?(view, "[data-testid=search-empty-hero]", "Run a search to see results")

    assert has_element?(
             view,
             "#search-completion-status[role=status][aria-live=polite][aria-atomic=true]"
           )

    assert completion_text(view) == ""
    assert html =~ "Search in"
    assert html =~ "Single schema"
    assert html =~ inspect(OpsPostA)
    refute html =~ "Choose the index for this run."
    refute html =~ "Run a probe"
    refute html =~ "Last run loaded"
  end

  test "collapsed result options submit their selected limit and schema to the backend", %{
    conn: conn
  } do
    Application.put_env(:scrypath_ops, :search_playground_adapter, RecordingAdapter)
    {:ok, view, _html} = live(conn, ~p"/ops/search?page_size=7")

    assert has_element?(
             view,
             "#search-options:not([open]) #search_page_size[name=page_size][value='7']:not([disabled])"
           )

    assert has_element?(view, "#search_page_size[min='1'][max='50']")

    mounted =
      view
      |> element("#search-options")
      |> render()
      |> LazyHTML.from_fragment()
      |> LazyHTML.query("details")
      |> LazyHTML.attribute("phx-mounted")
      |> hd()
      |> Jason.decode!()

    assert mounted == [["ignore_attrs", %{"attrs" => ["open"]}]]

    view
    |> form("#ops-search-playground-form", %{"q" => "bounded", "schema" => inspect(OpsPostB)})
    |> render_submit()

    render(view)
    assert_receive {:search_dispatched, OpsPostB, "bounded", opts}
    assert Keyword.fetch!(opts, :page) == [size: 7]
    assert has_element?(view, "#search_page_size[value='7']")

    assert_patch(
      view,
      "/ops/search?" <>
        URI.encode_query(%{
          "mode" => "single",
          "page_size" => 7,
          "q" => "bounded",
          "schema" => inspect(OpsPostB)
        })
    )
  end

  test "zero results announce the completed query and offer relevant recovery", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/search")

    view
    |> form("#ops-search-playground-form", %{"q" => "no-match", "schema" => inspect(OpsPostA)})
    |> render_submit()

    html = render(view)
    assert completion_text(view) == "0 results returned for “no-match” in #{inspect(OpsPostA)}."
    assert html =~ "No matching documents"
    assert html =~ "Try different search text or choose another schema"
    refute html =~ "raise the page size"
    refute html =~ "The panel above explains merge ceilings"
  end

  test "editing query, schema and limit leaves completed results and saved payload identified by their run",
       %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/search")

    view
    |> form("#ops-search-playground-form", %{"q" => "executed", "schema" => inspect(OpsPostA)})
    |> render_submit()

    render(view)
    completed = completion_text(view)

    view
    |> form("#ops-search-playground-form", %{
      "q" => "draft",
      "schema" => inspect(OpsPostB),
      "page_size" => "7"
    })
    |> render_change()

    assert has_element?(view, "#search_q[value=draft]")
    assert has_element?(view, "input[name=schema][value='#{inspect(OpsPostB)}'][checked]")
    assert has_element?(view, "#search_page_size[value='7']")
    assert completion_text(view) == completed
    assert completed == "0 results returned for “executed” in #{inspect(OpsPostA)}."

    capture =
      view
      |> element("[data-testid=search-capture-preview-pre]")
      |> render()
      |> LazyHTML.from_fragment()
      |> LazyHTML.text()
      |> Jason.decode!()

    assert capture["q"] == "executed"
    assert capture["schema"] == inspect(OpsPostA)
    assert has_element?(view, "label[for=capture_basename]", "Filename (.json)")

    view |> element("[data-testid=search-mode-multi]") |> render_click()
    assert completion_text(view) == completed
  end

  test "empty schema_allowlist shows OPSUI guard copy and disables targeting", %{conn: conn} do
    Application.put_env(:scrypath_ops, :schema_allowlist, [])

    {:ok, _lv, html} = live(conn, ~p"/ops/search")

    assert html =~ "No schemas configured"
    assert html =~ ~r/<fieldset[^>]*disabled/
    assert html =~ ~r/<button[^>]*disabled/
  end

  test "schema picker keeps labels, names, and control semantics across empty and populated counts" do
    for count <- [0, 1, 4, 5] do
      schemas = for index <- 1..count//1, do: Module.concat(["PickerSchema#{index}"])
      html = render_component(&OpsUi.ops_schema_select/1, %{id: "picker", schemas: schemas})

      if count == 0 do
        assert html == ""
      else
        assert html =~ ~s(<legend)
        assert html =~ "Schema"
        assert html =~ ~s(name="schema")

        if count == 1 do
          assert html =~ ~s(type="hidden" name="schema" value="PickerSchema1")
          refute html =~ ~s(type="radio")
          refute html =~ ~s(<select)
        else
          assert html =~ ~s(type="radio")
          assert html =~ ~r/for="picker-[^"]+"/
          refute html =~ ~s(<select)
        end
      end
    end

    unicode_schema = Module.concat(["Catalog", "Café東京"])

    html =
      render_component(&OpsUi.ops_schema_select/1, %{
        id: "unicode-picker",
        schemas: [unicode_schema],
        selected: unicode_schema
      })

    assert html =~ "Café東京"
    assert html =~ ~s(value="Catalog.Café東京")
  end

  test "search controls are natively disabled without a configured backend", %{conn: conn} do
    Application.delete_env(:scrypath_ops, :backend)

    {:ok, view, html} = live(conn, ~p"/ops/search")

    assert html =~ ~r/<fieldset[^>]*disabled/
    assert html =~ ~r/<button[^>]*disabled/

    view
    |> element("#ops-search-playground-form")
    |> render_submit(%{
      "q" => "still visible",
      "page_size" => "10",
      "schema" => inspect(OpsPostA)
    })

    assert render(view) =~ "Search could not run"
    assert render(view) =~ "runtime is not configured"
  end

  test "mode buttons expose the selected mode and invalid entries retain query values", %{
    conn: conn
  } do
    {:ok, view, html} = live(conn, ~p"/ops/search")
    assert html =~ ~s(aria-label="Search mode")
    assert html =~ ~s(aria-pressed="true")
    assert html =~ ~s(aria-pressed="false")

    view
    |> element("#ops-search-playground-form")
    |> render_submit(%{"q" => "café 東京", "page_size" => "999", "schema" => inspect(OpsPostA)})

    html = render(view)
    assert html =~ ~s(value="café 東京")
    assert html =~ "999"
  end

  test "mode=multi renders multi toggle test id", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/ops/search?mode=multi")

    assert html =~ ~s(data-testid="search-mode-multi")
    assert html =~ "Multiple schemas"
  end

  test "partial multi search announces failures without claiming no matches", %{conn: conn} do
    Application.put_env(:scrypath_ops, :search_stub_variant, :partial)

    {:ok, view, _html} = live(conn, ~p"/ops/search?mode=multi")

    view
    |> element("#ops-search-playground-form")
    |> render_submit(%{
      "q" => "hello",
      "page_size" => "10",
      "schemas" => [inspect(OpsPostA), inspect(OpsPostB)]
    })

    # The bounded read is deferred to a :run_search message (S2 loading state);
    # render/1 flushes it and returns the result HTML.
    html = render(view)
    assert html =~ "Some schemas could not be searched."
    assert has_element?(view, ".ops-badge-partial", "Partial results")

    assert completion_text(view) ==
             "Partial results: 0 results returned for “hello” in #{inspect(OpsPostA)}, #{inspect(OpsPostB)}. 1 schema failed."

    refute html =~ "No matches"
  end

  test "page_size above ceiling surfaces 50 in error messaging", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/search")

    view
    |> element("#ops-search-playground-form")
    |> render_submit(%{
      "q" => "x",
      "page_size" => "99",
      "schema" => inspect(OpsPostA)
    })

    assert render(view) =~ "50"
  end

  test "merge stub exposes merge trace block", %{conn: conn} do
    Application.put_env(:scrypath_ops, :search_stub_variant, :merge)

    {:ok, view, _html} = live(conn, ~p"/ops/search?mode=multi")

    view
    |> element("#ops-search-playground-form")
    |> render_submit(%{
      "q" => "merge",
      "page_size" => "10",
      "schemas" => [inspect(OpsPostA), inspect(OpsPostB)]
    })

    assert render(view) =~ "Merge trace"

    assert completion_text(view) ==
             "2 results returned for “merge” in #{inspect(OpsPostA)}, #{inspect(OpsPostB)}."
  end

  test "successful single search shows validated capture preview", %{conn: conn} do
    dir =
      Path.join(
        System.tmp_dir!(),
        "scrypath_ops_search_capture_#{:erlang.unique_integer([:positive])}"
      )

    :ok = File.mkdir_p!(dir)
    prev_ws = Application.get_env(:scrypath_ops, :playbook_workspace_dir)
    Application.put_env(:scrypath_ops, :playbook_workspace_dir, dir)

    on_exit(fn ->
      File.rm_rf(dir)

      if prev_ws == nil,
        do: Application.delete_env(:scrypath_ops, :playbook_workspace_dir),
        else: Application.put_env(:scrypath_ops, :playbook_workspace_dir, prev_ws)
    end)

    {:ok, view, html} = live(conn, ~p"/ops/search")
    refute html =~ "Save as playbook"

    view
    |> element("#ops-search-playground-form")
    |> render_submit(%{
      "q" => "hello",
      "page_size" => "10",
      "schema" => inspect(OpsPostA)
    })

    html = render(view)
    assert html =~ "Save as playbook"
    assert html =~ "Playbook preview is ready"
    assert html =~ ~s(data-testid="playbook-preview-marker")
    assert html =~ ~s(data-testid="search-capture-preview-pre")
  end

  test "multi search_many total failure shows hard error alert, not partial banner", %{conn: conn} do
    Application.put_env(:scrypath_ops, :search_stub_variant, :hard_error)

    {:ok, view, _html} = live(conn, ~p"/ops/search?mode=multi")

    view
    |> element("#ops-search-playground-form")
    |> render_submit(%{
      "q" => "boom",
      "page_size" => "10",
      "schemas" => [inspect(OpsPostA), inspect(OpsPostB)]
    })

    html = render(view)
    assert html =~ "Search could not run"
    assert html =~ "stub_hard_failure"
    refute html =~ "Some schemas could not be searched."
    assert has_element?(view, "[role=alert]", "Search could not run")
    assert completion_text(view) == ""
  end

  defp completion_text(view) do
    view
    |> element("#search-completion-status")
    |> render()
    |> LazyHTML.from_fragment()
    |> LazyHTML.text()
    |> String.trim()
  end
end
