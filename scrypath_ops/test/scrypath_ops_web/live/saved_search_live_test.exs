defmodule ScrypathOpsWeb.SavedSearchLiveTest do
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScrypathOps.Test.OpsPostA
  alias ScrypathOps.Test.OpsPostB
  alias ScrypathOps.Test.SearchPlaygroundStubAdapter

  setup do
    prev_allow = Application.get_env(:scrypath_ops, :schema_allowlist)
    prev_backend = Application.get_env(:scrypath_ops, :backend)
    prev_sync = Application.get_env(:scrypath_ops, :sync_mode)
    prev_prefix = Application.get_env(:scrypath_ops, :index_prefix)
    prev_url = Application.get_env(:scrypath_ops, :meilisearch_url)
    prev_adapter = Application.get_env(:scrypath_ops, :search_playground_adapter)
    prev_stub_variant = Application.get_env(:scrypath_ops, :search_stub_variant)
    prev_sigra = Application.get_env(:scrypath_ops, :sigra)
    prev_opsui_auth_mode = System.get_env("OPSUI_AUTH_MODE")

    Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostA, OpsPostB])
    Application.put_env(:scrypath_ops, :backend, Scrypath.Meilisearch)
    Application.put_env(:scrypath_ops, :sync_mode, :manual)
    Application.put_env(:scrypath_ops, :index_prefix, "pblv_test")
    Application.put_env(:scrypath_ops, :meilisearch_url, "http://localhost:7700")
    Application.put_env(:scrypath_ops, :search_playground_adapter, SearchPlaygroundStubAdapter)
    Application.put_env(:scrypath_ops, :search_stub_variant, :ok)

    Application.put_env(:scrypath_ops, :sigra,
      sudo_confirm_path: "/sudo/confirm",
      sudo_window: 300
    )

    System.put_env("OPSUI_AUTH_MODE", "sigra")

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
      restore.(:sigra, prev_sigra)

      if prev_opsui_auth_mode == nil,
        do: System.delete_env("OPSUI_AUTH_MODE"),
        else: System.put_env("OPSUI_AUTH_MODE", prev_opsui_auth_mode)
    end)

    :ok
  end

  test "import errors explain an invalid result limit without an internal tuple", %{conn: conn} do
    {:ok, view, _} = live(conn, ~p"/ops/playbooks")

    json =
      Jason.encode!(%{
        playbook_format: 1,
        mode: "search",
        schema: "ScrypathOps.Test.OpsPostA",
        q: "a",
        opts: %{page: %{size: 999}}
      })

    html = view |> form("form[phx-submit='import_paste']", %{json: json}) |> render_submit()
    assert html =~ "Results per schema must be between 1 and 50; received 999."
    refute html =~ ":page_size_out_of_range"
    refute has_element?(view, "button[phx-click=run]")
  end

  test "mount shows honesty panel", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")
    html = render(view)
    assert html =~ "Saved searches contain query inputs, not results"

    assert html =~
             "Save queries and options to run again. A saved search can include multiple schemas."
  end

  test "empty catalog shows the empty hero and import anchor", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/ops/playbooks")

    assert html =~ ~s(data-testid="saved-searches-empty-hero")
    assert html =~ "No saved searches yet"
    assert html =~ ~s(href="#saved-search-import")
    refute has_element?(view, "details[data-testid='saved-search-manage-actions']")
  end

  test "catalog management is contextual, closed, and wraps long names", %{conn: conn} do
    long_name = "saved-search-" <> String.duplicate("long-segment-", 10) <> ".json"
    names = ["one.json", "two.json", long_name]

    Enum.each(names, fn name ->
      put_saved_search!(name, saved_search_json("query for #{name}"))
    end)

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    Enum.each(names, fn name ->
      dom_id = Base.url_encode64(name, padding: false)

      assert has_element?(
               view,
               "details#saved-search-manage-#{dom_id}[data-ops-file-name='#{name}']:not([open]) > summary#saved-search-manage-summary-#{dom_id}",
               "File actions"
             )

      assert has_element?(view, "#saved-search-row-#{dom_id} .ops-saved-search-filename", name)

      assert has_element?(
               view,
               "details#saved-search-manage-#{dom_id} button[aria-label='Duplicate #{name}']"
             )

      assert has_element?(
               view,
               "details#saved-search-manage-#{dom_id} button[aria-label='Rename #{name}']"
             )

      assert has_element?(
               view,
               "details#saved-search-manage-#{dom_id} button[aria-label='Delete #{name}']"
             )

      assert has_element?(view, "#saved-search-primary-#{dom_id}", "Preview")

      assert has_element?(
               view,
               "#saved-search-row-#{dom_id} button[aria-label='Run #{name} without preview']"
             )
    end)
  end

  test "the page never discloses or asks about a storage location", %{conn: conn} do
    put_saved_search!("stored.json", saved_search_json("stored query"))

    {:ok, view, html} = live(conn, ~p"/ops/playbooks")

    refute html =~ "Storage folder"
    refute html =~ "Read-only examples"
    refute html =~ "Configure a storage folder"
    assert has_element?(view, "details[data-testid='saved-search-manage-actions']")

    view |> element("button[phx-click='load'][phx-value-name='stored.json']") |> render_click()
    assert has_element?(view, "#saved-search-draft-origin", "Saved search · stored.json")
    assert has_element?(view, "#saved-search-save-form")
    refute render(view) =~ "storage folder"
  end

  test "upload and paste controls have persistent labels and format help", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/ops/playbooks")

    assert html =~ "Saved search JSON file"

    [upload_id] =
      html
      |> LazyHTML.from_document()
      |> LazyHTML.query("input[type=file]")
      |> LazyHTML.attribute("id")

    assert html =~ ~s(for="#{upload_id}")
    assert html =~ ~s(id="#{upload_id}-hint")
    assert html =~ ~s(aria-describedby="#{upload_id}-hint")
    assert html =~ ~s(accept=".json")
    assert html =~ ~s(max-file-size="256000") || html =~ "256000 bytes"
    assert html =~ ~s(for="saved-search-paste-json")
    assert html =~ "Saved search JSON"
    assert html =~ "JSON only"
  end

  test "paste import accepts the exact byte ceiling and retains the preview after an oversized attempt",
       %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    for size <- [255_999, 256_000] do
      json = sized_saved_search_json(size, "paste-#{size}")
      assert byte_size(json) == size

      view
      |> form("form[phx-submit='import_paste']", %{json: json})
      |> render_submit()

      assert has_element?(view, "#saved-search-draft-origin", "Imported draft · not saved")
      assert has_element?(view, "#saved-search-summary", "paste-#{size}")
    end

    too_large = sized_saved_search_json(256_001, "paste-too-large")
    assert byte_size(too_large) == 256_001

    html =
      view
      |> form("form[phx-submit='import_paste']", %{json: too_large})
      |> render_submit()

    assert html =~ "Maximum size is 256,000 bytes"
    assert html =~ "The previous valid preview remains selected."
    assert has_element?(view, "#saved-search-import details[open]")
    assert has_element?(view, "#saved-search-summary", "paste-256000")
    assert :sys.get_state(view.pid).socket.assigns.paste_json == too_large
  end

  test "malformed and empty paste imports keep a prior valid preview and retain the entered value",
       %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    view
    |> form("form[phx-submit='import_paste']", %{json: saved_search_json("prior preview")})
    |> render_submit()

    for invalid_json <- ["", "{"] do
      html =
        view
        |> form("form[phx-submit='import_paste']", %{json: invalid_json})
        |> render_submit()

      assert html =~ "The previous valid preview remains selected."
      assert has_element?(view, "#saved-search-import details[open]")
      assert has_element?(view, "#saved-search-summary", "prior preview")
      assert :sys.get_state(view.pid).socket.assigns.paste_json == invalid_json
    end
  end

  test "non-text paste payload returns an import error without crashing the LiveView", %{
    conn: conn
  } do
    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    html = render_submit(view, "import_paste", %{"json" => %{"unexpected" => "object"}})

    assert Process.alive?(view.pid)
    assert html =~ "Paste content must be text."
    refute has_element?(view, "#saved-search-preview")
  end

  test "uploaded saved search is not imported until submit and malformed upload preserves the preview",
       %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    empty_html =
      view
      |> form("form[phx-submit='import_upload']")
      |> render_submit()

    assert has_element?(view, "#saved-search-import-error", "Choose a JSON file first.")
    assert empty_html =~ "No previous valid preview is available."
    refute has_element?(view, "#flash-error")

    assert is_binary(
             upload_saved_search(view, "selected.json", saved_search_json("uploaded on submit"))
           )

    refute has_element?(view, "#saved-search-preview")
    refute has_element?(view, "#saved-search-draft-origin")

    view
    |> form("form[phx-submit='import_upload']")
    |> render_submit()

    assert has_element?(view, "#saved-search-draft-origin", "selected.json")
    assert has_element?(view, "#saved-search-summary", "uploaded on submit")

    assert is_binary(upload_saved_search(view, "malformed.json", "{"))

    html =
      view
      |> form("form[phx-submit='import_upload']")
      |> render_submit()

    assert html =~ "This file is not valid saved search JSON."
    assert html =~ "The previous valid preview remains selected."

    assert has_element?(
             view,
             "#saved-search-import-error",
             "The previous valid preview remains selected."
           )

    refute has_element?(view, "#flash-error")
    assert has_element?(view, "#saved-search-draft-origin", "selected.json")
    assert has_element?(view, "#saved-search-summary", "uploaded on submit")
  end

  test "file uploads require explicit submit, enforce the byte ceiling, and preserve the selected preview on failure",
       %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    view
    |> form("form[phx-submit='import_paste']", %{json: saved_search_json("prior upload preview")})
    |> render_submit()

    _ =
      Enum.reduce_while([255_999, 256_000], "prior upload preview", fn size, prior_query ->
        filename = "upload-#{size}.json"
        json = sized_saved_search_json(size, "upload-#{size}")
        assert byte_size(json) == size

        assert is_binary(upload_saved_search(view, filename, json))
        assert :sys.get_state(view.pid).socket.assigns.draft_saved_search["q"] == prior_query
        assert has_element?(view, "#saved-search-preview", prior_query)

        view
        |> form("form[phx-submit='import_upload']")
        |> render_submit()

        assert has_element?(view, "#saved-search-draft-origin", filename)
        assert has_element?(view, "#saved-search-preview", "upload-#{size}")
        {:cont, "upload-#{size}"}
      end)

    too_large = sized_saved_search_json(256_001, "upload-too-large")
    assert byte_size(too_large) == 256_001
    assert {:error, _reasons} = upload_saved_search(view, "too-large.json", too_large)

    upload_config = :sys.get_state(view.pid).socket.assigns.uploads.saved_search_file

    assert Enum.any?(upload_config.errors, fn {_ref, reason} -> reason == :too_large end),
           inspect(upload_config)

    html =
      view
      |> form("form[phx-submit='import_upload']")
      |> render_submit()

    assert html =~ "256,000-byte"
    assert has_element?(view, "#saved-search-upload-error", "256,000-byte")
    assert html =~ "The previous valid preview remains selected."
    assert has_element?(view, "#saved-search-draft-origin", "upload-256000.json")
    assert has_element?(view, "#saved-search-preview", "upload-256000")

    assert is_binary(upload_saved_search(view, "malformed.json", "{"))

    malformed_html =
      view
      |> form("form[phx-submit='import_upload']")
      |> render_submit()

    assert malformed_html =~ "This file is not valid saved search JSON."
    assert malformed_html =~ "The previous valid preview remains selected."
    assert has_element?(view, "#saved-search-draft-origin", "upload-256000.json")
    assert has_element?(view, "#saved-search-preview", "upload-256000")
  end

  test "file dialogs expose unique names, contextual Cancel, and a successor target", %{
    conn: conn
  } do
    put_saved_search!("one.json", "{}\n")
    put_saved_search!("two.json", "{}\n")
    too_long = String.duplicate("n", 121)

    {:ok, view, html} = live(conn, ~p"/ops/playbooks")
    assert html =~ "one.json"
    assert html =~ "two.json"

    view
    |> element("button[phx-click='rename_open'][phx-value-name='one.json']")
    |> render_click()

    html = render(view)
    assert html =~ ~s(role="dialog")
    assert html =~ ~s(aria-labelledby="rename-saved-search-modal-title")
    assert html =~ ~s(aria-describedby="rename-saved-search-modal-description")
    assert html =~ ~s(aria-label="Cancel rename")
    assert html =~ ~s(for="rename-new-name-input")
    assert html =~ ~s(data-ops-modal-initial-focus="#rename-new-name-input")
    assert html =~ ~s(data-ops-modal-successor-name="")
    assert html =~ ~s(data-ops-modal-fallback-successor="#saved-search-catalog-heading")
    assert html =~ ~s(data-ops-modal-focus-error="#rename-new-name-input")

    view
    |> form("form[phx-change='rename_change']", %{"new_name" => too_long})
    |> render_change()

    assert render(view) =~ ~s(value="#{too_long}")

    view
    |> form("form[phx-submit='rename_submit']", %{"new_name" => too_long})
    |> render_submit()

    assert has_element?(view, "#rename-saved-search-modal [role='alert']", "Enter a name")
    assert has_element?(view, "#rename-new-name-input[aria-invalid='true']")

    assert has_element?(
             view,
             "#rename-new-name-input[aria-describedby*='rename-new-name-input-error']"
           )

    assert has_element?(view, "#rename-saved-search-modal[data-ops-modal-focus-request='1']")

    view
    |> form("form[phx-change='rename_change']", %{"new_name" => "two.json"})
    |> render_change()

    view
    |> form("form[phx-submit='rename_submit']", %{"new_name" => "two.json"})
    |> render_submit()

    assert has_element?(view, "#rename-saved-search-modal [role='alert']", "already in use")
    assert has_element?(view, "#rename-new-name-input[value='two.json']")
    assert saved_definition("one.json") == %{}
    assert saved_definition("two.json") == %{}

    render_click(view, "rename_cancel", %{})
    render_click(view, "dup_open", %{"name" => "one.json"})
    refute has_element?(view, "#duplicate-saved-search-modal [role='alert']")
    view |> form("form[phx-submit='dup_submit']", %{"to_name" => "two.json"}) |> render_submit()
    assert has_element?(view, "#duplicate-saved-search-modal [role='alert']", "already in use")
    assert has_element?(view, "#dup-to-name-input[aria-invalid='true']")
    render_click(view, "dup_cancel", %{})

    view
    |> element("button[phx-click='request_delete'][phx-value-name='one.json']")
    |> render_click()

    html = render(view)
    assert html =~ "This cannot be undone."
    assert html =~ ~s(data-ops-modal-initial-focus="[data-ops-modal-cancel]")

    assert html =~
             ~s(data-ops-modal-successor="#saved-search-primary-#{Base.url_encode64("two.json", padding: false)}")

    assert html =~ ~s(aria-label="Cancel delete")

    html =
      view
      |> form("form[phx-submit='confirm_delete']", %{"confirm" => " one.json "})
      |> render_submit()

    assert html =~ ~s(value=" one.json ")

    assert has_element?(
             view,
             "#delete-saved-search-modal [role='alert']",
             "match the name exactly"
           )

    assert saved_search?("one.json")

    view
    |> form("form[phx-submit='confirm_delete']", %{"confirm" => "one.json"})
    |> render_submit()

    refute saved_search?("one.json")
    assert saved_search?("two.json")
    refute has_element?(view, "#delete-saved-search-modal")

    assert has_element?(
             view,
             "#saved-search-primary-#{Base.url_encode64("two.json", padding: false)}"
           )
  end

  test "paste import validates and shows preview marker", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "x",
        "opts" => %{}
      })

    html =
      view
      |> form("form[phx-submit='import_paste']", %{json: json})
      |> render_submit()

    assert html =~ "data-testid=\"saved-search-preview-marker\""
  end

  test "imported draft replaces loaded provenance and can be saved before a run", %{conn: conn} do
    put_saved_search!("previous.json", saved_search_json("old query"))

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")
    render_click(view, "load", %{"name" => "previous.json"})

    imported =
      saved_search_json("new query", %{"title" => "New title", "description" => "New details"})

    html =
      view
      |> form("form[phx-submit='import_paste']", %{json: imported})
      |> render_submit()

    assert has_element?(view, "#saved-search-draft-origin", "Imported draft · not saved")
    assert has_element?(view, "#saved-search-draft-origin", "pasted JSON")
    refute has_element?(view, "#saved-search-draft-origin", "previous.json")
    assert html =~ "Saving replaces the saved search with the same name."
    assert html =~ "Run search"

    html =
      view
      |> form("form[phx-submit='save']", %{basename: "captured.json"})
      |> render_submit()

    assert html =~ "Saved captured.json"
    assert has_element?(view, "#saved-search-draft-origin", "Saved search · captured.json")
    refute has_element?(view, "#saved-search-run-outcome")

    saved = saved_definition("captured.json")
    assert saved["q"] == "new query"
    assert saved["title"] == "New title"
    assert saved["description"] == "New details"
  end

  test "saving under an existing name replaces that saved search's definition", %{conn: conn} do
    put_saved_search!("shared.json", saved_search_json("old query"))

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    view
    |> form("form[phx-submit='import_paste']", %{json: saved_search_json("replacement query")})
    |> render_submit()

    html =
      view
      |> form("form[phx-submit='save']", %{basename: " shared.json "})
      |> render_submit()

    assert html =~ "Saved shared.json"
    assert saved_definition("shared.json")["q"] == "replacement query"
    assert [_one] = ScrypathOps.SavedSearches.list(ScrypathOps.Repo)
  end

  test "an invalid name keeps the draft and explains the naming rule", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    view
    |> form("form[phx-submit='import_paste']", %{json: saved_search_json("retain this draft")})
    |> render_submit()

    too_long = String.duplicate("n", 121)

    html =
      view
      |> form("form[phx-submit='save']", %{basename: too_long})
      |> render_submit()

    assert has_element?(view, "#save_basename[value='#{too_long}']")
    assert has_element?(view, "#save-basename-error", "Enter a name of up to 120 characters.")
    assert has_element?(view, "#saved-search-draft-origin", "Imported draft · not saved")
    assert has_element?(view, "#saved-search-summary", "retain this draft")
    refute html =~ "Saved #{too_long}"
    assert ScrypathOps.SavedSearches.list(ScrypathOps.Repo) == []
  end

  test "a completed run stays attributed to its submitted saved search after importing another draft",
       %{
         conn: conn
       } do
    put_saved_search!("submitted.json", saved_search_json("submitted query"))

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")
    render_click(view, "load", %{"name" => "submitted.json"})
    render_click(view, "run", %{})
    render_async(view)

    view
    |> form("form[phx-submit='import_paste']", %{json: saved_search_json("current draft query")})
    |> render_submit()

    assert has_element?(view, "#saved-search-preview", "current draft query")
    assert has_element?(view, "#saved-search-run-outcome", "Last completed run")
    assert has_element?(view, "#saved-search-run-outcome", "submitted.json")
    assert has_element?(view, "#saved-search-run-outcome", "submitted query")
    refute has_element?(view, "#saved-search-run-outcome", "current draft query")
    assert has_element?(view, "#saved-search-run-outcome a[href*='q=submitted+query']")
  end

  test "saving a changed draft does not relabel the earlier run or its Search handoff", %{
    conn: conn
  } do
    put_saved_search!("submitted.json", saved_search_json("submitted query"))

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")
    render_click(view, "load", %{"name" => "submitted.json"})
    render_click(view, "run", %{})
    render_async(view)

    view
    |> form("form[phx-submit='import_paste']", %{
      json: saved_search_json("saved current query", %{"title" => "Saved current draft"})
    })
    |> render_submit()

    view
    |> form("form[phx-submit='save']", %{basename: "current.json"})
    |> render_submit()

    assert has_element?(view, "#saved-search-preview", "saved current query")
    assert has_element?(view, "#saved-search-draft-origin", "Saved search · current.json")
    assert has_element?(view, "#saved-search-run-outcome", "Last completed run")
    assert has_element?(view, "#saved-search-run-outcome", "submitted.json")
    assert has_element?(view, "#saved-search-run-outcome", "submitted query")
    refute has_element?(view, "#saved-search-run-outcome", "saved current query")
    assert has_element?(view, "#saved-search-run-outcome a[href*='q=submitted+query']")
  end

  test "run with stub adapter shows explicit lifecycle transition to success", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "x",
        "opts" => %{}
      })

    view
    |> form("form[phx-submit='import_paste']", %{json: json})
    |> render_submit()

    running_html = render_click(view, "run", %{})
    assert running_html =~ "Running search"
    assert running_html =~ "Cancel run"

    html = render_async(view)
    assert html =~ "Run finished"
    refute html =~ "data-testid=\"run-failure-panel\""
  end

  test "bounded execution contract keeps the stable lifecycle affordances", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "x",
        "opts" => %{}
      })

    view
    |> form("form[phx-submit='import_paste']", %{json: json})
    |> render_submit()

    running_html = render_click(view, "run", %{})
    assert running_html =~ "Running search"
    assert running_html =~ "Cancel run"

    html = render_async(view)
    assert html =~ "Run finished"
    refute html =~ "data-testid=\"run-failure-panel\""
  end

  # OPS-PB-05: end-to-end proof on SearchPlaygroundStubAdapter (no Meilisearch).
  test "OPS-PB-05 stub path: paste → save → listed → load → run", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "x",
        "opts" => %{}
      })

    view
    |> form("form[phx-submit='import_paste']", %{json: json})
    |> render_submit()

    basename = "ops-pb-05-#{:erlang.unique_integer([:positive])}.json"

    view
    |> form("form[phx-submit='save']", %{basename: basename})
    |> render_submit()

    listed = render(view)
    assert listed =~ basename
    assert listed =~ ~s(phx-value-name="#{basename}")

    render_click(view, "load", %{"name" => basename})
    render_click(view, "run", %{})
    ran = render_async(view)
    assert ran =~ "Run finished" || ran =~ "Search completed"
  end

  test "search_many paste then run shows multi-schema summary on stub", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search_many",
        "entries" => [
          ["ScrypathOps.Test.OpsPostA", "a", %{}],
          ["ScrypathOps.Test.OpsPostB", "b", %{}]
        ],
        "opts" => %{}
      })

    view
    |> form("form[phx-submit='import_paste']", %{json: json})
    |> render_submit()

    render_click(view, "run", %{})
    html = render_async(view)
    assert html =~ "schema(s)"
  end

  test "forced failure shows anchored doc links and copyable diagnostics", %{conn: conn} do
    prev_variant = Application.get_env(:scrypath_ops, :search_stub_variant)
    Application.put_env(:scrypath_ops, :search_stub_variant, :hard_error)

    on_exit(fn ->
      if prev_variant == nil,
        do: Application.delete_env(:scrypath_ops, :search_stub_variant),
        else: Application.put_env(:scrypath_ops, :search_stub_variant, prev_variant)
    end)

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search_many",
        "entries" => [
          ["ScrypathOps.Test.OpsPostA", "a", %{}],
          ["ScrypathOps.Test.OpsPostB", "b", %{}]
        ],
        "opts" => %{}
      })

    view
    |> form("form[phx-submit='import_paste']", %{json: json})
    |> render_submit()

    render_click(view, "run", %{})
    html = render_async(view)
    doc_links = saved_search_doc_links(html)

    assert html =~ "data-testid=\"run-failure-panel\""
    assert html =~ "backend"
    assert html =~ "Search adapter returned a forced hard failure."
    assert html =~ "Copy diagnostics"

    assert doc_links in [
             [
               "https://github.com/szTheory/scrypath/blob/main/scrypath_ops/docs/saved-search-schema-v1.md#troubleshooting",
               "https://github.com/szTheory/scrypath/blob/main/scrypath_ops/docs/team-saved-search-persistence.md",
               "https://github.com/szTheory/scrypath/blob/main/guides/multi-index-search.md"
             ],
             [
               "https://github.com/szTheory/scrypath/blob/main/scrypath_ops/docs/saved-search-schema-v1.md",
               "https://github.com/szTheory/scrypath/blob/main/scrypath_ops/docs/saved-search-schema-v1.md#troubleshooting",
               "https://github.com/szTheory/scrypath/blob/main/scrypath_ops/docs/team-saved-search-persistence.md",
               "https://github.com/szTheory/scrypath/blob/main/guides/multi-index-search.md"
             ]
           ]

    copied = render_click(view, "copy_run_diagnostics", %{})
    refute copied =~ "Copied diagnostics."
    assert has_element?(view, "button[data-ops-copy-text]")
  end

  test "forced failure keeps raw run_error before enrichment formatting", %{conn: conn} do
    prev_variant = Application.get_env(:scrypath_ops, :search_stub_variant)
    Application.put_env(:scrypath_ops, :search_stub_variant, :hard_error)

    on_exit(fn ->
      if prev_variant == nil,
        do: Application.delete_env(:scrypath_ops, :search_stub_variant),
        else: Application.put_env(:scrypath_ops, :search_stub_variant, prev_variant)
    end)

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search_many",
        "entries" => [
          ["ScrypathOps.Test.OpsPostA", "a", %{}],
          ["ScrypathOps.Test.OpsPostB", "b", %{}]
        ],
        "opts" => %{}
      })

    view
    |> form("form[phx-submit='import_paste']", %{json: json})
    |> render_submit()

    render_click(view, "run", %{})
    _html = render_async(view)
    assigns = :sys.get_state(view.pid).socket.assigns

    assert assigns.run_error == :stub_hard_failure
    assert %{reason: "stub_hard_failure", failure_class: "backend"} = assigns.run_failure_enriched
    assert assigns.run_failure_enriched.message =~ "forced hard failure"
  end

  test "saved search run emits telemetry start and stop for a completed run", %{conn: conn} do
    unique = System.unique_integer([:positive])
    start_handler_id = "saved-search-live-start-#{unique}"
    stop_handler_id = "saved-search-live-stop-#{unique}"
    parent = self()

    :telemetry.attach(
      start_handler_id,
      [:scrypath_ops, :saved_search_run, :start],
      fn _event, measurements, metadata, _config ->
        send(parent, {:telemetry_start, measurements, metadata})
      end,
      nil
    )

    :telemetry.attach(
      stop_handler_id,
      [:scrypath_ops, :saved_search_run, :stop],
      fn _event, measurements, metadata, _config ->
        send(parent, {:telemetry_stop, measurements, metadata})
      end,
      nil
    )

    on_exit(fn ->
      :telemetry.detach(start_handler_id)
      :telemetry.detach(stop_handler_id)
    end)

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "x",
        "opts" => %{}
      })

    view
    |> form("form[phx-submit='import_paste']", %{json: json})
    |> render_submit()

    render_click(view, "run", %{})
    render_async(view)

    assert_receive {:telemetry_start, %{system_time: system_time}, %{run_id: run_id}}

    assert is_integer(system_time)
    assert is_integer(run_id)

    assert_receive {:telemetry_stop, %{duration: duration}, %{run_id: ^run_id, result: :ok}}

    assert is_integer(duration)
    assert duration >= 0
  end

  test "catalog run_now shows explicit lifecycle and success state", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    basename = "catalog-run-#{System.unique_integer([:positive])}.json"

    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "x",
        "opts" => %{}
      })

    view
    |> form("form[phx-submit='import_paste']", %{json: json})
    |> render_submit()

    view
    |> form("form[phx-submit='save']", %{basename: basename})
    |> render_submit()

    running_html = render_click(view, "run_now", %{"name" => basename})
    assert running_html =~ "Running search"

    html = render_async(view)

    assert html =~ "Run finished"
    assert html =~ basename
    refute html =~ "data-testid=\"run-failure-panel\""
  end

  test "explicit cancellation retains the source captured for that run", %{conn: conn} do
    previous_variant = Application.get_env(:scrypath_ops, :search_stub_variant)
    previous_waiter = Application.get_env(:scrypath_ops, :search_stub_waiter)
    Application.put_env(:scrypath_ops, :search_stub_variant, :paused)
    Application.put_env(:scrypath_ops, :search_stub_waiter, self())

    on_exit(fn ->
      if previous_variant == nil,
        do: Application.delete_env(:scrypath_ops, :search_stub_variant),
        else: Application.put_env(:scrypath_ops, :search_stub_variant, previous_variant)

      if previous_waiter == nil,
        do: Application.delete_env(:scrypath_ops, :search_stub_waiter),
        else: Application.put_env(:scrypath_ops, :search_stub_waiter, previous_waiter)
    end)

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    view
    |> form("form[phx-submit='import_paste']", %{json: saved_search_json("cancelled query")})
    |> render_submit()

    assert render_click(view, "run", %{}) =~ "Running search"
    assert_receive {:saved_search_run_adapter_started, _runner_pid}

    render_click(view, "cancel_run", %{})
    html = render_async(view)

    assert html =~ "Search canceled before results were returned."
    assert has_element?(view, "#saved-search-run-outcome", "pasted JSON")
    assert has_element?(view, "#saved-search-run-outcome", "cancelled query")

    assigns = :sys.get_state(view.pid).socket.assigns
    assert assigns.run_ui.phase == :error
    assert assigns.run_error == :cancelled
    assert assigns.run_snapshot.draft["q"] == "cancelled query"
  end

  test "timeout keeps the captured run identity and ignores its canceled late result", %{
    conn: conn
  } do
    previous_variant = Application.get_env(:scrypath_ops, :search_stub_variant)
    previous_waiter = Application.get_env(:scrypath_ops, :search_stub_waiter)
    Application.put_env(:scrypath_ops, :search_stub_variant, :paused)
    Application.put_env(:scrypath_ops, :search_stub_waiter, self())

    on_exit(fn ->
      if previous_variant == nil,
        do: Application.delete_env(:scrypath_ops, :search_stub_variant),
        else: Application.put_env(:scrypath_ops, :search_stub_variant, previous_variant)

      if previous_waiter == nil,
        do: Application.delete_env(:scrypath_ops, :search_stub_waiter),
        else: Application.put_env(:scrypath_ops, :search_stub_waiter, previous_waiter)
    end)

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    view
    |> form("form[phx-submit='import_paste']", %{json: saved_search_json("timed-out query")})
    |> render_submit()

    assert render_click(view, "run", %{}) =~ "Running search"
    assert_receive {:saved_search_run_adapter_started, _runner_pid}
    run_id = :sys.get_state(view.pid).socket.assigns.run_ui.run_id
    send(view.pid, {:saved_search_run_timeout, run_id})
    html = render(view)

    assert html =~ "Search timed out before results were returned."
    assert has_element?(view, "#saved-search-run-outcome", "pasted JSON")
    assert has_element?(view, "#saved-search-run-outcome", "timed-out query")

    assigns = :sys.get_state(view.pid).socket.assigns
    assert assigns.run_ui.phase == :error
    assert assigns.run_error == :timed_out
    assert assigns.run_snapshot.draft["q"] == "timed-out query"
  end

  test "loading a new saved search while running cancels and resets the active run", %{conn: conn} do
    prev_variant = Application.get_env(:scrypath_ops, :search_stub_variant)
    prev_waiter = Application.get_env(:scrypath_ops, :search_stub_waiter)
    Application.put_env(:scrypath_ops, :search_stub_variant, :paused)
    Application.put_env(:scrypath_ops, :search_stub_waiter, self())

    on_exit(fn ->
      if prev_variant == nil,
        do: Application.delete_env(:scrypath_ops, :search_stub_variant),
        else: Application.put_env(:scrypath_ops, :search_stub_variant, prev_variant)

      if prev_waiter == nil,
        do: Application.delete_env(:scrypath_ops, :search_stub_waiter),
        else: Application.put_env(:scrypath_ops, :search_stub_waiter, prev_waiter)
    end)

    one_json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "one",
        "opts" => %{}
      })

    two_json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "two",
        "opts" => %{}
      })

    put_saved_search!("one.json", one_json)
    put_saved_search!("two.json", two_json)

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    render_click(view, "load", %{"name" => "one.json"})
    running_html = render_click(view, "run", %{})
    assert running_html =~ "Running search"
    assert_receive {:saved_search_run_adapter_started, _runner_pid}

    load_html = render_click(view, "load", %{"name" => "two.json"})
    assert load_html =~ "Loaded saved search."
    refute load_html =~ "Search canceled before results were returned."
    refute render_async(view) =~ "Search canceled before results were returned."
  end

  test "superseded run exit does not override the newer run result", %{conn: conn} do
    prev_variant = Application.get_env(:scrypath_ops, :search_stub_variant)
    prev_waiter = Application.get_env(:scrypath_ops, :search_stub_waiter)
    Application.put_env(:scrypath_ops, :search_stub_variant, :paused)
    Application.put_env(:scrypath_ops, :search_stub_waiter, self())

    on_exit(fn ->
      if prev_variant == nil,
        do: Application.delete_env(:scrypath_ops, :search_stub_variant),
        else: Application.put_env(:scrypath_ops, :search_stub_variant, prev_variant)

      if prev_waiter == nil,
        do: Application.delete_env(:scrypath_ops, :search_stub_waiter),
        else: Application.put_env(:scrypath_ops, :search_stub_waiter, prev_waiter)
    end)

    one_json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "one",
        "opts" => %{}
      })

    two_json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "two",
        "opts" => %{}
      })

    put_saved_search!("one.json", one_json)
    put_saved_search!("two.json", two_json)

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    render_click(view, "load", %{"name" => "one.json"})
    assert render_click(view, "run", %{}) =~ "Running search"
    assert_receive {:saved_search_run_adapter_started, _first_runner_pid}

    load_html = render_click(view, "load", %{"name" => "two.json"})
    assert load_html =~ "Loaded saved search."

    assert render_click(view, "run", %{}) =~ "Running search"
    assert_receive {:saved_search_run_adapter_started, current_runner_pid}
    send(current_runner_pid, :continue_saved_search_run)

    html = render_async(view)
    assert html =~ "Run finished"
    refute html =~ "Search canceled before results were returned."
    refute html =~ "data-testid=\"run-failure-panel\""
  end

  test "legacy saved search JSON without title shows Untitled saved search", %{conn: conn} do
    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "x",
        "opts" => %{}
      })

    put_saved_search!("legacy.json", json)

    {:ok, _view, html} = live(conn, ~p"/ops/playbooks")
    assert html =~ "Untitled saved search"
    assert html =~ "legacy.json"
  end

  test "duplicate flow saves the suggested copy name", %{conn: conn} do
    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "x",
        "opts" => %{}
      })

    put_saved_search!("one.json", json)

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    render_click(view, "dup_open", %{"name" => "one.json"})
    assert has_element?(view, "#dup-to-name-input[value='one.json copy']")

    view
    |> form("form[phx-submit='dup_submit']", %{"to_name" => "one.json copy"})
    |> render_submit()

    assert saved_search?("one.json copy")
    assert saved_definition("one.json copy") == saved_definition("one.json")
  end

  test "delete confirmation mismatch shows flash and keeps the saved search", %{conn: conn} do
    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "x",
        "opts" => %{}
      })

    put_saved_search!("todelete.json", json)

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    render_click(view, "request_delete", %{"name" => "todelete.json"})

    html =
      view
      |> form("form[phx-submit='confirm_delete']", %{"confirm" => "wrong-name.json"})
      |> render_submit()

    assert html =~ "Confirmation must match the name exactly."

    assert has_element?(
             view,
             "#delete-saved-search-modal [role='alert']",
             "Confirmation must match"
           )

    assert has_element?(view, "#delete-confirm-input[aria-invalid='true']")
    assert has_element?(view, "#delete-confirm-input[value='wrong-name.json']")
    assert saved_search?("todelete.json")
  end

  test "sigra confirm delete redirects stale sudo and keeps the saved search", %{} do
    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "x",
        "opts" => %{}
      })

    put_saved_search!("sigra-delete.json", json)

    socket = %Phoenix.LiveView.Socket{
      assigns: %{
        __changed__: %{},
        flash: %{},
        delete_pending: "sigra-delete.json",
        scrypath_repo: ScrypathOps.Repo,
        selected_basename: "sigra-delete.json",
        operator_context: %ScrypathOps.Integrations.Sigra.OperatorContext{
          user_id: "user_123",
          active_org_id: "org_456",
          impersonator_user_id: nil,
          sudo_at: DateTime.add(DateTime.utc_now(), -600, :second)
        }
      },
      host_uri: URI.parse("https://scrypath.example/ops/playbooks")
    }

    {:noreply, result_socket} =
      ScrypathOpsWeb.SavedSearchLive.handle_event(
        "confirm_delete",
        %{"confirm" => "sigra-delete.json"},
        socket
      )

    socket = result_socket
    assert inspect(socket.redirected) =~ "/sudo/confirm"
    assert inspect(socket.redirected) =~ "return_to=%2Fops%2Fplaybooks"
    assert saved_search?("sigra-delete.json")
  end

  test "sigra confirm delete clears only the selected saved search state", %{conn: conn} do
    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "x",
        "opts" => %{}
      })

    put_saved_search!("sigra-delete-ok.json", json)

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    render_click(view, "load", %{"name" => "sigra-delete-ok.json"})
    render_click(view, "request_delete", %{"name" => "sigra-delete-ok.json"})

    put_live_assigns(view,
      current_scope: %{user: %{id: "user_123"}, active_organization: %{id: "org_456"}},
      operator_context: %ScrypathOps.Integrations.Sigra.OperatorContext{
        user_id: "user_123",
        active_org_id: "org_456",
        impersonator_user_id: nil,
        sudo_at: DateTime.add(DateTime.utc_now(), -60, :second)
      }
    )

    html =
      view
      |> form("form[phx-submit='confirm_delete']", %{"confirm" => "sigra-delete-ok.json"})
      |> render_submit()

    assert html =~ "Deleted sigra-delete-ok.json"
    refute saved_search?("sigra-delete-ok.json")

    assigns = :sys.get_state(view.pid).socket.assigns
    assert assigns.delete_pending == nil
    assert assigns.selected_basename == nil
    assert assigns.draft_saved_search == nil
    assert assigns.preview_json == nil
    assert assigns.preview_marker == false
    assert assigns.run_result == nil
    assert assigns.run_error == nil
  end

  test "rename collision shows in-use flash", %{conn: conn} do
    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "x",
        "opts" => %{}
      })

    put_saved_search!("a.json", json)
    put_saved_search!("b.json", json)

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    render_click(view, "rename_open", %{"name" => "a.json"})

    html =
      view
      |> form("form[phx-submit='rename_submit']", %{"new_name" => "b.json"})
      |> render_submit()

    assert html =~ "That name is already in use"
  end

  defp saved_search_doc_links(html) do
    Regex.scan(~r/href="(https:\/\/github\.com\/szTheory\/scrypath\/blob\/main\/[^"]+)"/, html)
    |> Enum.map(fn [_, href] -> href end)
    |> Enum.uniq()
  end

  # Inserts a row directly so tests can also seed definitions the v1 validator rejects.
  defp put_saved_search!(name, json) do
    definition = Jason.decode!(json)

    ScrypathOps.Repo.insert!(%ScrypathOps.SavedSearches.SavedSearch{
      name: name,
      schema: ScrypathOps.SavedSearches.SavedSearch.schema_for(definition) || "unknown",
      definition: definition
    })
  end

  defp saved_search?(name) do
    match?({:ok, _}, ScrypathOps.SavedSearches.get(ScrypathOps.Repo, name))
  end

  defp saved_definition(name) do
    {:ok, saved_search} = ScrypathOps.SavedSearches.get(ScrypathOps.Repo, name)
    saved_search.definition
  end

  defp saved_search_json(query, metadata \\ %{}) do
    %{
      "playbook_format" => 1,
      "mode" => "search",
      "schema" => "ScrypathOps.Test.OpsPostA",
      "q" => query,
      "opts" => %{}
    }
    |> Map.merge(metadata)
    |> Jason.encode!()
  end

  defp sized_saved_search_json(size, query) do
    json = saved_search_json(query)
    padding = size - byte_size(json)
    true = padding >= 0
    json <> String.duplicate(" ", padding)
  end

  defp upload_saved_search(view, filename, content) do
    upload =
      file_input(view, "form[phx-submit='import_upload']", :saved_search_file, [
        %{
          name: filename,
          content: content,
          size: byte_size(content),
          type: "application/json"
        }
      ])

    render_upload(upload, filename)
  end

  defp put_live_assigns(view, assigns) do
    :sys.replace_state(view.pid, fn state ->
      socket =
        Enum.reduce(assigns, state.socket, fn {key, value}, socket ->
          Phoenix.Component.assign(socket, key, value)
        end)

      %{state | socket: socket}
    end)
  end
end
