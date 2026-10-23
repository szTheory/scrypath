defmodule ScrypathOpsWeb.SearchLiveTest do
  @moduledoc false
  # Phase 47 D-10: SECURITY + prod guard tests. D-11: allowlist-only targeting.
  # D-15/D-16: no auto-run on mount; page ceiling copy; partial vs hard errors.
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScrypathOps.Test.OpsPostA
  alias ScrypathOps.Test.OpsPostB
  alias ScrypathOps.Test.OpsPostC
  alias ScrypathOps.Test.SearchPlaygroundStubAdapter
  alias ScrypathOpsWeb.OpsUi

  setup do
    prev_allow = Application.get_env(:scrypath_ops, :schema_allowlist)
    prev_backend = Application.get_env(:scrypath_ops, :backend)
    prev_sync = Application.get_env(:scrypath_ops, :sync_mode)
    prev_prefix = Application.get_env(:scrypath_ops, :index_prefix)
    prev_url = Application.get_env(:scrypath_ops, :meilisearch_url)
    prev_adapter = Application.get_env(:scrypath_ops, :search_playground_adapter)
    prev_stub_variant = Application.get_env(:scrypath_ops, :search_stub_variant)

    Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostA, OpsPostB, OpsPostC])
    Application.put_env(:scrypath_ops, :backend, Scrypath.Meilisearch)
    Application.put_env(:scrypath_ops, :sync_mode, :manual)
    Application.put_env(:scrypath_ops, :index_prefix, "sltlv")
    Application.put_env(:scrypath_ops, :meilisearch_url, "http://localhost:7700")
    Application.put_env(:scrypath_ops, :search_playground_adapter, SearchPlaygroundStubAdapter)
    Application.put_env(:scrypath_ops, :search_stub_variant, :ok)

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
    end)

    :ok
  end

  test "mount shows non-production strip and primary CTA", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/ops/search")

    assert html =~ "Queries may be logged by Meilisearch"

    assert html =~
             "Run queries against your schemas. Save useful searches to run again."

    assert html =~ "Run search"
    assert html =~ "ops-form-stack"
    assert html =~ "ops-search-targets"
    assert html =~ ~s(for="search_q")
    assert html =~ ~s(aria-describedby="search-honesty-panel")
    refute html =~ ~s(data-testid="search-empty-hero")
    refute has_element?(view, "#search-results-heading")
    refute html =~ "Select a schema above and run a search. An empty query browses the index."
    refute html =~ "Index details"
    refute html =~ ~s(<h2 class="text-heading font-semibold">Results</h2>)

    submit_buttons =
      Regex.scan(~r/<button\b[^>]*>/, html)
      |> Enum.count(fn [button] -> String.contains?(button, ~s(type="submit")) end)

    assert submit_buttons == 1

    ordered_markers =
      ["Search mode", "search_schema", "Search text", "Results per page", "Run search"]
      |> Enum.map(fn marker -> :binary.match(html, marker) |> elem(0) end)

    assert ordered_markers == Enum.sort(ordered_markers)
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

      html =
        render_component(&OpsUi.ops_schema_select/1, %{
          id: "picker",
          schemas: schemas,
          selected: List.first(schemas)
        })

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
          assert html =~ ~s(class="ops-schema-picker__radio")
          refute html =~ ~s(class="sr-only")
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

  test "partial multi search distinguishes returned, no-hit and failed indexes", %{conn: conn} do
    Application.put_env(:scrypath_ops, :search_stub_variant, :partial)

    {:ok, view, _html} = live(conn, ~p"/ops/search?mode=multi")

    view
    |> element("#ops-search-playground-form")
    |> render_submit(%{
      "q" => "hello",
      "page_size" => "10",
      "schemas" => [inspect(OpsPostA), inspect(OpsPostB), inspect(OpsPostC)]
    })

    html = render(view)
    assert html =~ "Some schemas could not be searched"

    assert html =~ "1 result shown"
    assert html =~ "Partial result"
    refute html =~ "No matching documents returned for this index."
    assert html =~ inspect(OpsPostA)
    assert html =~ ":stub"
    assert html =~ ~s(data-index-outcome="failed")
    refute html =~ ~s(data-index-outcome="no-hits")
    refute html =~ ~r/<details[^>]*open/
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

  test "the primary list follows backend order even for duplicate titles", %{conn: conn} do
    Application.put_env(:scrypath_ops, :search_stub_variant, :reverse_merge)

    {:ok, view, _html} = live(conn, ~p"/ops/search?mode=multi")

    view
    |> element("#ops-search-playground-form")
    |> render_submit(%{
      "q" => "merge",
      "page_size" => "10",
      "schemas" => [inspect(OpsPostA), inspect(OpsPostB)]
    })

    assert has_element?(view, "#search-combined-results .ops-readable-hit")

    sources =
      render(view)
      |> LazyHTML.from_fragment()
      |> LazyHTML.query("#search-combined-results .ops-hit-source")
      |> Enum.map(&LazyHTML.text/1)
      |> Enum.map(&String.trim/1)

    assert sources == ["OpsPostB", "OpsPostA"]
  end

  test "nested JSON hit fields render as safe structured values", %{conn: conn} do
    Application.put_env(:scrypath_ops, :search_stub_variant, :nested_hit)

    {:ok, view, _html} = live(conn, ~p"/ops/search")

    view
    |> element("#ops-search-playground-form")
    |> render_submit(%{
      "q" => "nested fields",
      "page_size" => "10",
      "schema" => inspect(OpsPostA)
    })

    html = render(view)
    assert html =~ "nested"
    assert html =~ "value"
  end

  test "successful single search shows validated capture preview", %{conn: conn} do
    dir = temporary_playbook_workspace()

    {:ok, view, html} = live(conn, ~p"/ops/search")
    refute html =~ "Save search"
    refute has_element?(view, "#search-capture-form")

    view
    |> element("#ops-search-playground-form")
    |> render_submit(%{
      "q" => "hello",
      "page_size" => "10",
      "schema" => inspect(OpsPostA)
    })

    html = render(view)
    assert html =~ "Save search"
    refute html =~ "Query inputs ready to save"
    assert has_element?(view, "#search-capture-json")
    assert html =~ ~s(id="search-capture-json")
    assert has_element?(view, "details#search-capture-json")
    refute has_element?(view, "details#search-capture-json[open]")

    assert has_element?(view, "#search-capture-form")
    assert has_element?(view, "label[for='capture_basename']", "Filename")
    assert has_element?(view, "label[for='capture_title']", "Search title")
    assert has_element?(view, "#capture_basename-hint")

    view
    |> element("#search-capture-form")
    |> render_submit(%{
      "capture" => %{
        "basename" => "zero-hit-check.json",
        "title" => "Zero hit check",
        "description" => "Saved from the returned empty search."
      }
    })

    saved = Path.join(dir, "zero-hit-check.json") |> File.read!() |> Jason.decode!()
    assert saved["mode"] == "search"
    assert saved["schema"] == inspect(OpsPostA)
    assert saved["q"] == "hello"
    assert saved["title"] == "Zero hit check"
    assert saved["description"] == "Saved from the returned empty search."
    refute Map.has_key?(saved, "hits")
    refute Map.has_key?(saved, "result")
    refute File.read!(Path.join(dir, "zero-hit-check.json")) =~ "partial-hit"
    assert render(view) =~ "Saved search zero-hit-check.json."
  end

  test "malformed capture fields return a field error without crashing the LiveView", %{
    conn: conn
  } do
    temporary_playbook_workspace()
    {:ok, view, _html} = live(conn, ~p"/ops/search")

    view
    |> element("#ops-search-playground-form")
    |> render_submit(%{
      "q" => "hello",
      "page_size" => "10",
      "schema" => inspect(OpsPostA)
    })

    html =
      render_submit(view, "capture_change", %{
        "capture" => %{"basename" => %{"unexpected" => "object"}}
      })

    assert Process.alive?(view.pid)
    assert html =~ "search-capture-form"

    html =
      render_submit(view, "save_search_capture", %{
        "capture" => %{"basename" => %{"unexpected" => "object"}}
      })

    assert Process.alive?(view.pid)
    assert html =~ "Filename must be a .json basename"

    render_submit(view, "search", %{
      "q" => %{"unexpected" => "object"},
      "page_size" => %{"unexpected" => "object"},
      "schema" => %{"unexpected" => "object"},
      "schemas" => [%{"unexpected" => "object"}]
    })

    assert Process.alive?(view.pid)
  end

  test "eligible partial multi response saves criteria without response documents", %{conn: conn} do
    Application.put_env(:scrypath_ops, :search_stub_variant, :partial)
    dir = temporary_playbook_workspace()

    {:ok, view, html} = live(conn, ~p"/ops/search?mode=multi")
    refute html =~ "Save search"

    view
    |> element("#ops-search-playground-form")
    |> render_submit(%{
      "q" => "partial criteria",
      "page_size" => "9",
      "schemas" => [inspect(OpsPostA), inspect(OpsPostB), inspect(OpsPostC)]
    })

    html = render(view)
    assert html =~ "Some schemas could not be searched"
    assert has_element?(view, "[aria-controls='search-capture-form-panel']", "Save search")

    view
    |> element("#search-capture-form")
    |> render_submit(%{
      "capture" => %{
        "basename" => "partial-check.json",
        "title" => "Partial check",
        "description" => "The criteria were saved, not returned documents."
      }
    })

    saved = Path.join(dir, "partial-check.json") |> File.read!() |> Jason.decode!()
    assert saved["mode"] == "search_many"

    assert Enum.map(saved["entries"], &hd/1) == [
             inspect(OpsPostA),
             inspect(OpsPostB),
             inspect(OpsPostC)
           ]

    assert Enum.all?(saved["entries"], fn [_schema, query, _opts] ->
             query == "partial criteria"
           end)

    assert saved["title"] == "Partial check"
    refute Map.has_key?(saved, "hits")
    refute File.read!(Path.join(dir, "partial-check.json")) =~ "partial-hit"
    refute File.read!(Path.join(dir, "partial-check.json")) =~ "Partial result"
  end

  test "collision retains capture fields and leaves the occupied file untouched", %{conn: conn} do
    dir = temporary_playbook_workspace()
    occupied = Path.join(dir, "occupied.json")
    original = ~s({"original":true})
    File.write!(occupied, original)

    {:ok, view, _html} = live(conn, ~p"/ops/search")

    view
    |> element("#ops-search-playground-form")
    |> render_submit(%{
      "q" => "collision criteria",
      "page_size" => "10",
      "schema" => inspect(OpsPostA)
    })

    view
    |> element("#search-capture-form")
    |> render_submit(%{
      "capture" => %{
        "basename" => "occupied.json",
        "title" => "Keep this title",
        "description" => "Keep this description"
      }
    })

    html = render(view)
    assert html =~ "That filename is already in use. Choose another."
    assert has_element?(view, "#capture_basename[value='occupied.json'][aria-invalid='true']")
    assert has_element?(view, "#capture_title[value='Keep this title']")
    assert has_element?(view, "#capture_description")
    assert html =~ "Keep this description"
    assert has_element?(view, "#capture_basename[aria-describedby~='capture_basename-error']")
    assert File.read!(occupied) == original
    refute html =~ "Saved search occupied.json."
  end

  test "missing workspace setup retains fields and gives the approved recovery guidance", %{
    conn: conn
  } do
    previous = Application.get_env(:scrypath_ops, :playbook_workspace_dir)

    on_exit(fn ->
      if previous == nil,
        do: Application.delete_env(:scrypath_ops, :playbook_workspace_dir),
        else: Application.put_env(:scrypath_ops, :playbook_workspace_dir, previous)
    end)

    Application.delete_env(:scrypath_ops, :playbook_workspace_dir)
    {:ok, view, _html} = live(conn, ~p"/ops/search")

    view
    |> element("#ops-search-playground-form")
    |> render_submit(%{
      "q" => "setup criteria",
      "page_size" => "10",
      "schema" => inspect(OpsPostA)
    })

    view
    |> element("#search-capture-form")
    |> render_submit(%{
      "capture" => %{
        "basename" => "keep-me.json",
        "title" => "Setup title",
        "description" => "Setup description"
      }
    })

    html = render(view)
    assert html =~ "Could not save this search."
    assert html =~ "Configure a storage folder, then retry saving."
    assert has_element?(view, "#capture_basename[value='keep-me.json']")
    assert has_element?(view, "#capture_title[value='Setup title']")
    assert html =~ "Setup description"
    assert has_element?(view, "#capture_basename[aria-describedby~='capture_basename-error']")
    refute html =~ "Saved search keep-me.json."
  end

  test "workspace write failure retains fields and exposes the actual reason", %{conn: conn} do
    root_file =
      Path.join(
        System.tmp_dir!(),
        "scrypath_ops_workspace_file_#{:erlang.unique_integer([:positive])}"
      )

    File.write!(root_file, "not a directory")
    previous = Application.get_env(:scrypath_ops, :playbook_workspace_dir)
    Application.put_env(:scrypath_ops, :playbook_workspace_dir, root_file)

    on_exit(fn ->
      File.rm(root_file)

      if previous == nil,
        do: Application.delete_env(:scrypath_ops, :playbook_workspace_dir),
        else: Application.put_env(:scrypath_ops, :playbook_workspace_dir, previous)
    end)

    {:ok, view, _html} = live(conn, ~p"/ops/search")

    view
    |> element("#ops-search-playground-form")
    |> render_submit(%{
      "q" => "write failure criteria",
      "page_size" => "10",
      "schema" => inspect(OpsPostA)
    })

    view
    |> element("#search-capture-form")
    |> render_submit(%{
      "capture" => %{
        "basename" => "write-error.json",
        "title" => "Write title",
        "description" => "Write description"
      }
    })

    html = render(view)
    assert html =~ "Could not save this search."
    assert html =~ "Reason: :enotdir"

    assert has_element?(
             view,
             "[data-testid='search-capture-error']",
             "Check the storage folder's permissions and available disk space, then retry saving."
           )

    assert has_element?(view, "#capture_basename[value='write-error.json']")
    assert has_element?(view, "#capture_title[value='Write title']")
    assert html =~ "Write description"
    refute html =~ "Saved search write-error.json."
  end

  test "search result and capture attribution stay bound to the submitted criteria", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/search")

    view
    |> element("#ops-search-playground-form")
    |> render_submit(%{
      "q" => "  original probe  ",
      "page_size" => "7",
      "schema" => inspect(OpsPostA)
    })

    html = render(view)
    assert html =~ ~s(id="search-run-attribution")

    assert has_element?(
             view,
             "#search-run-attribution[data-query='original probe'][data-limit='7']"
           )

    assert has_element?(view, "#search-run-attribution[data-mode=single]")
    assert html =~ inspect(OpsPostA)
    assert html =~ "original probe"
    assert has_element?(view, "#search-run-attribution[data-limit='7']")
    assert html =~ "No matching documents"
    refute html =~ "Run current search"

    render_patch(
      view,
      ~p"/ops/search?mode=single&q=edited%20criteria&page_size=22&schema=#{inspect(OpsPostB)}"
    )

    html = render(view)
    assert html =~ ~s(value="edited criteria")
    assert has_element?(view, "#search-run-attribution[data-mode=single]")
    assert html =~ inspect(OpsPostA)
    assert html =~ "original probe"
    assert has_element?(view, "#search-run-attribution[data-limit='7']")
    assert html =~ ~s(id="search-capture-json")

    view
    |> element(~s([data-testid="search-mode-multi"]))
    |> render_click()

    render_patch(view, ~p"/ops/search?mode=multi&q=multi%20edit&page_size=22")

    html = render(view)
    assert html =~ ~s(data-testid="search-mode-multi")
    assert html =~ "original probe"
    assert has_element?(view, "#search-run-attribution[data-limit='7']")
    assert html =~ ~s(id="search-capture-json")
  end

  test "an empty query remains a valid submitted search", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/ops/search")
    refute has_element?(view, "#search-results-heading")
    refute html =~ "Run current search"

    view
    |> element("#ops-search-playground-form")
    |> render_submit(%{
      "q" => "",
      "page_size" => "5",
      "schema" => inspect(OpsPostA)
    })

    html = render(view)
    assert html =~ "No matching documents"
    assert html =~ "all documents"
    refute html =~ "Select a query"
  end

  test "missing Search targets fail validation without reusing a prior selection", %{conn: conn} do
    {:ok, single_view, _html} = live(conn, ~p"/ops/search")

    single_view
    |> element("#ops-search-playground-form")
    |> render_submit(%{"q" => "probe", "page_size" => "5", "schema" => ""})

    single_html = render(single_view)
    assert single_html =~ "No schema selected."
    assert single_html =~ "No schema selected"
    refute single_html =~ "Search completed:"
    refute single_html =~ "Query inputs ready to save"

    {:ok, multi_view, _html} = live(conn, ~p"/ops/search?mode=multi")

    multi_view
    |> element("#ops-search-playground-form")
    |> render_submit(%{"q" => "probe", "page_size" => "5", "schemas" => []})

    multi_html = render(multi_view)
    assert multi_html =~ "Select at least one schema for multi-search."
    assert multi_html =~ "Select at least one schema for multi-search."
    refute multi_html =~ "Search completed:"
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
    assert html =~ "Fix the query options or operator config, then run search again."
    assert html =~ "ops-badge-error"
    refute html =~ ~s(data-testid="search-outcome")
    refute html =~ "Some schemas could not be searched"
  end

  defp temporary_playbook_workspace do
    dir =
      Path.join(
        System.tmp_dir!(),
        "scrypath_ops_search_capture_#{:erlang.unique_integer([:positive])}"
      )

    :ok = File.mkdir_p!(dir)
    previous = Application.get_env(:scrypath_ops, :playbook_workspace_dir)
    Application.put_env(:scrypath_ops, :playbook_workspace_dir, dir)

    on_exit(fn ->
      File.rm_rf(dir)

      if previous == nil,
        do: Application.delete_env(:scrypath_ops, :playbook_workspace_dir),
        else: Application.put_env(:scrypath_ops, :playbook_workspace_dir, previous)
    end)

    dir
  end

  test "invalid numeric input is retained and never submits a substitute limit", %{conn: conn} do
    {:ok, view, _} = live(conn, ~p"/ops/search")

    for limit <- ["", "3.5", "15oops", "51"] do
      view
      |> element("#ops-search-playground-form")
      |> render_submit(%{"q" => "keep", "page_size" => limit, "schema" => inspect(OpsPostA)})

      assert has_element?(view, "#search_page_size-error", "Enter a whole number from 1 to 50.")
      refute has_element?(view, "#search-results-heading")
    end
  end

  test "one empty multi search has one empty state and no source zero-match claims", %{conn: conn} do
    {:ok, view, _} = live(conn, ~p"/ops/search?mode=multi")

    view
    |> element("#ops-search-playground-form")
    |> render_submit(%{
      "q" => "",
      "page_size" => "10",
      "schemas" => [inspect(OpsPostA), inspect(OpsPostB)]
    })

    assert has_element?(view, ".ops-empty-hero", "No matching documents")
    refute has_element?(view, "[data-index-outcome=no-hits]")
    assert has_element?(view, "details", "Response data")
  end
end
