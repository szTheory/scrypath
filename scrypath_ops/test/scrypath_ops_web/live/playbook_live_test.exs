defmodule ScrypathOpsWeb.PlaybookLiveTest do
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

  test "mount keeps query safety advice visible without assuming the environment", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")
    assert has_element?(view, "#playbook-honesty-panel", "Keep secrets and personal data")
    refute has_element?(view, "#playbook-honesty-panel", "Non-production")
  end

  test "empty workspace shows the empty hero and import anchor", %{conn: conn} do
    dir =
      Path.join(
        System.tmp_dir!(),
        "scrypath_ops_playbooks_empty_#{:erlang.unique_integer([:positive])}"
      )

    :ok = File.mkdir_p!(dir)
    prev_workspace = Application.get_env(:scrypath_ops, :playbook_workspace_dir)
    Application.put_env(:scrypath_ops, :playbook_workspace_dir, dir)

    on_exit(fn ->
      File.rm_rf(dir)

      if prev_workspace == nil,
        do: Application.delete_env(:scrypath_ops, :playbook_workspace_dir),
        else: Application.put_env(:scrypath_ops, :playbook_workspace_dir, prev_workspace)
    end)

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    assert has_element?(view, "[data-testid='playbooks-empty-hero']", "No playbooks yet")
    assert has_element?(view, "a[href='#playbook-import']")
    assert has_element?(view, "details#playbook-import[open] #playbook-upload-form")
    assert has_element?(view, "#playbook-workspace-details", dir)
    refute has_element?(view, "#playbook-workspace-details[open]")
  end

  test "upload and paste controls have persistent labels and format help", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/ops/playbooks")

    assert html =~ "Import playbook file"

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
    assert html =~ ~s(for="playbook-paste-json")
    assert html =~ "Playbook JSON"
    assert html =~ "JSON only"
  end

  test "file dialogs expose unique names, contextual Cancel, and a successor target", %{
    conn: conn
  } do
    dir =
      Path.join(
        System.tmp_dir!(),
        "scrypath_ops_playbooks_dialog_#{:erlang.unique_integer([:positive])}"
      )

    :ok = File.mkdir_p!(dir)
    :ok = File.write!(Path.join(dir, "one.json"), "{}\n")
    :ok = File.write!(Path.join(dir, "two.json"), "{}\n")
    previous = Application.get_env(:scrypath_ops, :playbook_workspace_dir)
    Application.put_env(:scrypath_ops, :playbook_workspace_dir, dir)

    on_exit(fn ->
      File.rm_rf(dir)

      if previous == nil,
        do: Application.delete_env(:scrypath_ops, :playbook_workspace_dir),
        else: Application.put_env(:scrypath_ops, :playbook_workspace_dir, previous)
    end)

    {:ok, view, html} = live(conn, ~p"/ops/playbooks")
    assert html =~ "one.json"
    assert html =~ "two.json"

    row_id = Base.url_encode64("one.json", padding: false)
    actions = "#playbook-actions-#{row_id}"

    assert has_element?(
             view,
             "#playbook-primary-#{row_id}[aria-label='Load preview of one.json']"
           )

    assert has_element?(view, "#{actions} > summary[aria-label='Actions for one.json']")
    refute has_element?(view, "#{actions}[open]")
    refute has_element?(view, "#{actions} [role='menu']")

    for {event, label} <- [
          {"run_now", "Run one.json without preview"},
          {"dup_open", "Duplicate one.json"},
          {"rename_open", "Rename one.json"},
          {"request_delete", "Delete one.json"}
        ] do
      assert has_element?(view, "#{actions} button[phx-click='#{event}'][aria-label='#{label}']")
    end

    view
    |> element("button[phx-click='rename_open'][phx-value-name='one.json']")
    |> render_click()

    html = render(view)
    assert html =~ ~s(role="dialog")
    assert html =~ ~s(aria-labelledby="rename-playbook-modal-title")
    assert html =~ ~s(aria-describedby="rename-playbook-modal-description")
    assert html =~ ~s(aria-label="Cancel rename")
    assert html =~ ~s(for="rename-new-name-input")
    assert html =~ ~s(data-ops-modal-initial-focus="#rename-new-name-input")
    assert has_element?(view, "#rename-playbook-modal-description", "Rename one.json")

    view
    |> form("form[phx-change='rename_change']", %{"new_name" => "invalid/name.json"})
    |> render_change()

    assert render(view) =~ ~s(value="invalid/name.json")

    view
    |> form("form[phx-submit='rename_submit']", %{"new_name" => "invalid/name.json"})
    |> render_submit()

    assert has_element?(
             view,
             "#rename-playbook-modal [role='alert']",
             "Filename must end in .json"
           )

    assert has_element?(view, "#rename-new-name-input[aria-invalid='true']")

    assert has_element?(
             view,
             "#rename-new-name-input[aria-describedby*='rename-new-name-input-error']"
           )

    render_click(view, "rename_cancel", %{})
    render_click(view, "dup_open", %{"name" => "one.json"})

    assert has_element?(
             view,
             "#duplicate-playbook-modal-description",
             "Create a copy of one.json"
           )

    refute has_element?(view, "#duplicate-playbook-modal [role='alert']")
    view |> form("form[phx-submit='dup_submit']", %{"to_name" => "two.json"}) |> render_submit()
    assert has_element?(view, "#duplicate-playbook-modal [role='alert']", "already in use")
    assert has_element?(view, "#dup-to-name-input[aria-invalid='true']")
    render_click(view, "dup_cancel", %{})

    view
    |> element("button[phx-click='request_delete'][phx-value-name='one.json']")
    |> render_click()

    html = render(view)
    assert html =~ "This cannot be undone."
    assert has_element?(view, "#delete-playbook-modal-description", "one.json")
    assert html =~ ~s(data-ops-modal-initial-focus="[data-ops-modal-cancel]")

    assert html =~
             ~s(data-ops-modal-successor="#playbook-primary-#{Base.url_encode64("two.json", padding: false)}")

    assert html =~ ~s(aria-label="Cancel delete")
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

    assert html =~ "data-testid=\"playbook-preview-marker\""
  end

  test "invalid imports retain loaded context and a valid paste replaces its source and results",
       %{conn: conn} do
    dir = configure_workspace("import_identity")
    File.write!(Path.join(dir, "saved.json"), search_playbook_json("saved query"))
    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    render_click(view, "load", %{"name" => "saved.json"})
    assert has_element?(view, "#playbook-run-origin", "Loaded file: saved.json")
    assert has_element?(view, "#playbook-run[aria-label='Run playbook: Loaded file: saved.json']")
    assert has_element?(view, "#playbook-preview ~ #playbook-import")
    refute has_element?(view, "#playbook-import[open]")

    render_click(view, "run", %{})
    render_async(view)
    assert has_element?(view, "#playbook-preview", "Run finished")

    for invalid <- [
          "{",
          Jason.encode!(%{"playbook_format" => 1, "mode" => "unknown"}),
          String.duplicate(" ", 256_001)
        ] do
      view |> form("#playbook-paste-form", %{json: invalid}) |> render_submit()
      assert has_element?(view, "#playbook-run-origin", "Loaded file: saved.json")
      assert has_element?(view, "#playbook-preview", "saved query")
    end

    view
    |> form("#playbook-paste-form", %{json: search_playbook_json("new query")})
    |> render_submit()

    assert has_element?(view, "#playbook-run-origin", "Imported from pasted JSON")

    assert has_element?(
             view,
             "#playbook-run[aria-label='Run playbook: Imported from pasted JSON']"
           )

    assert has_element?(view, "#playbook-preview", "new query")
    refute has_element?(view, "#playbook-preview", "Run finished")
    refute has_element?(view, "#playbook-run-origin", "saved.json")

    assigns = :sys.get_state(view.pid).socket.assigns
    assert assigns.selected_basename == nil
    assert assigns.preview_source == :paste
    assert assigns.run_result == nil
    assert assigns.run_error == nil
    assert assigns.run_ui.phase == :idle
  end

  test "rejected paste and upload imports preserve a completed failed run and its diagnostics", %{
    conn: conn
  } do
    dir = configure_workspace("failed_import_identity")

    File.write!(
      Path.join(dir, "saved.json"),
      multi_playbook_json([[inspect(OpsPostA), "saved query", %{}]], %{})
    )

    Application.put_env(:scrypath_ops, :search_stub_variant, :hard_error)
    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    render_click(view, "load", %{"name" => "saved.json"})
    render_click(view, "run", %{})
    render_async(view)
    previous = :sys.get_state(view.pid).socket.assigns

    assert_failed_run = fn ->
      assert has_element?(view, "#playbook-run-origin", "Loaded file: saved.json")
      assert has_element?(view, "[data-testid='run-failure-panel']", "Playbook run failed")

      assert has_element?(
               view,
               "[data-testid='run-failure-panel']",
               "Search adapter returned a forced hard failure."
             )

      assert has_element?(view, "[data-testid='run-failure-panel']", "stub_hard_failure")
      assert has_element?(view, "[data-testid='run-failure-panel']", "saved.json")

      assert has_element?(
               view,
               "[data-testid='run-failure-panel'] button[phx-click='copy_run_diagnostics']"
             )

      assigns = :sys.get_state(view.pid).socket.assigns
      assert assigns.selected_basename == previous.selected_basename
      assert assigns.preview_source == previous.preview_source
      assert assigns.draft_playbook == previous.draft_playbook
      assert assigns.run_ui == previous.run_ui
      assert assigns.run_error == previous.run_error
      assert assigns.run_failure_enriched == previous.run_failure_enriched
    end

    assert_failed_run.()

    for invalid <- ["{", Jason.encode!(%{"playbook_format" => 1, "mode" => "unknown"})] do
      view |> form("#playbook-paste-form", %{json: invalid}) |> render_submit()
      assert_failed_run.()
    end

    invalid =
      file_input(view, "#playbook-upload-form", :playbook_file, [
        %{name: "invalid.json", content: "{", type: "application/json"}
      ])

    render_upload(invalid, "invalid.json")
    view |> form("#playbook-upload-form") |> render_submit()
    assert_failed_run.()
  end

  test "loading malformed files clears the previous preview and its run context", %{conn: conn} do
    dir = configure_workspace("invalid_load_identity")
    File.write!(Path.join(dir, "saved.json"), search_playbook_json("saved query"))
    File.write!(Path.join(dir, "malformed.json"), "{")

    File.write!(
      Path.join(dir, "invalid-format.json"),
      Jason.encode!(%{"playbook_format" => 1, "mode" => "unknown"})
    )

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    for invalid_name <- ["malformed.json", "invalid-format.json"] do
      render_click(view, "load", %{"name" => "saved.json"})
      assert has_element?(view, "#playbook-run-origin", "Loaded file: saved.json")
      assert has_element?(view, "#playbook-preview", "saved query")

      render_click(view, "run", %{})
      render_async(view)
      assert has_element?(view, "#playbook-preview", "Run finished")

      render_click(view, "load", %{"name" => invalid_name})
      refute has_element?(view, "#playbook-preview")
      refute has_element?(view, "#playbook-run")

      assigns = :sys.get_state(view.pid).socket.assigns
      assert assigns.selected_basename == nil
      assert assigns.draft_playbook == nil
      assert assigns.preview_json == nil
      assert assigns.preview_marker == false
      assert assigns.preview_source == nil
      assert assigns.run_result == nil
      assert assigns.run_error == nil
      assert assigns.run_ui.phase == :idle

      render_click(view, "run", %{})
      assert has_element?(view, "[role='alert']", "Import or load a playbook before running.")
      refute has_element?(view, "#playbook-preview")
    end

    render_click(view, "load", %{"name" => "saved.json"})
    assert has_element?(view, "#playbook-run-origin", "Loaded file: saved.json")
    assert has_element?(view, "#playbook-preview", "saved query")
  end

  test "uploaded JSON imports show file origin and invalid JSON retains the loaded preview", %{
    conn: conn
  } do
    dir = configure_workspace("upload_identity")
    File.write!(Path.join(dir, "saved.json"), search_playbook_json("saved query"))
    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")
    render_click(view, "load", %{"name" => "saved.json"})

    invalid =
      file_input(view, "#playbook-upload-form", :playbook_file, [
        %{name: "invalid.json", content: "{", type: "application/json"}
      ])

    render_upload(invalid, "invalid.json")
    view |> form("#playbook-upload-form") |> render_submit()
    assert has_element?(view, "#playbook-run-origin", "Loaded file: saved.json")
    assert has_element?(view, "#playbook-preview", "saved query")

    upload =
      file_input(view, "#playbook-upload-form", :playbook_file, [
        %{
          name: "imported.json",
          content: search_playbook_json("uploaded query"),
          type: "application/json"
        }
      ])

    render_upload(upload, "imported.json")
    view |> form("#playbook-upload-form") |> render_submit()
    assert has_element?(view, "#playbook-run-origin", "Imported from uploaded JSON")
    assert has_element?(view, "#playbook-preview", "uploaded query")
    refute has_element?(view, "#playbook-run-origin", "saved.json")

    assigns = :sys.get_state(view.pid).socket.assigns
    assert assigns.selected_basename == nil
    assert assigns.preview_source == :upload
  end

  test "upload accepts only JSON files within the import size limit", %{conn: conn} do
    for {name, content, type, expected_error, expected_copy} <- [
          {"playbook.txt", search_playbook_json("query"), "text/plain", "not_accepted",
           "Choose a file ending in .json."},
          {"playbook.json", String.duplicate(" ", 256_001), "application/json", "too_large",
           "Choose a JSON file no larger than 256000 bytes."}
        ] do
      {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

      upload =
        file_input(view, "#playbook-upload-form", :playbook_file, [
          %{name: name, content: content, type: type}
        ])

      assert {:error, errors} = render_upload(upload, name)
      assert Enum.any?(errors, fn [_ref, reason] -> to_string(reason) == expected_error end)
      assert has_element?(view, "#playbook-upload-errors [role='alert']", expected_copy)
      refute has_element?(view, "#playbook-preview")
    end
  end

  test "single-search handoff preserves the second schema, executed query, and bounded limit", %{
    conn: conn
  } do
    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")
    query = "catalog & clearance"

    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => inspect(OpsPostB),
        "q" => query,
        "opts" => %{"page" => %{"size" => 7, "number" => 1}}
      })

    view |> form("#playbook-paste-form", %{json: json}) |> render_submit()
    render_click(view, "run", %{})
    render_async(view)
    assert has_element?(view, "#playbook-search-handoff")
    path = search_handoff_path(view)

    assert URI.decode_query(URI.parse(path).query) == %{
             "mode" => "single",
             "schema" => inspect(OpsPostB),
             "q" => query,
             "page_size" => "7"
           }

    {:ok, search_view, _html} = live(conn, path)
    assert has_element?(search_view, "#search_q[value='#{query}']")
    assert has_element?(search_view, "#search_page_size[value='7']")

    assert has_element?(
             search_view,
             "input[name='schema'][value='#{inspect(OpsPostB)}'][checked]"
           )

    refute has_element?(
             search_view,
             "input[name='schema'][value='#{inspect(OpsPostA)}'][checked]"
           )
  end

  test "representable multi-search handoff preserves its selected schemas and shared query", %{
    conn: conn
  } do
    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")
    query = "shared & terms"

    for schemas <- [[OpsPostB], [OpsPostA, OpsPostB]] do
      entries = Enum.map(schemas, &[inspect(&1), query, %{}])
      json = multi_playbook_json(entries, %{"federation_limit" => 9, "federation_offset" => 0})
      view |> form("#playbook-paste-form", %{json: json}) |> render_submit()
      render_click(view, "run", %{})
      render_async(view)
      assert has_element?(view, "#playbook-search-handoff")
      path = search_handoff_path(view)

      assert URI.decode_query(URI.parse(path).query) == %{
               "mode" => "multi",
               "schemas" => Enum.map_join(schemas, ",", &inspect/1),
               "q" => query,
               "page_size" => "9"
             }

      {:ok, search_view, _html} = live(conn, path)
      assert has_element?(search_view, "#search_q[value='#{query}']")
      assert has_element?(search_view, "#search_page_size[value='9']")

      for schema <- [OpsPostA, OpsPostB] do
        selector = "input[name='schemas[]'][value='#{inspect(schema)}'][checked]"
        assert has_element?(search_view, selector) == schema in schemas
      end
    end
  end

  test "multi-search omits the exact-query handoff when Search cannot reproduce its semantics", %{
    conn: conn
  } do
    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")
    first = [inspect(OpsPostA), "shared", %{}]
    second = [inspect(OpsPostB), "shared", %{}]

    for {entries, opts} <- [
          {[first, [inspect(OpsPostB), "different", %{}]], %{"federation_limit" => 9}},
          {[first, [inspect(OpsPostB), "shared", %{"federation_weight" => 2}]],
           %{"federation_limit" => 9}},
          {[first, second], %{"federation_limit" => 9, "federation_offset" => 2}},
          {[first, second], %{}},
          {[first, second], %{"federation_limit" => 51}},
          {[first, first], %{"federation_limit" => 9}},
          {[second, first], %{"federation_limit" => 9}}
        ] do
      view
      |> form("#playbook-paste-form", %{json: multi_playbook_json(entries, opts)})
      |> render_submit()

      render_click(view, "run", %{})
      render_async(view)
      assert has_element?(view, "#playbook-preview", "Run finished")
      refute has_element?(view, "#playbook-search-handoff")
    end
  end

  test "single-search omits the exact-query handoff for unsupported options or unknown limits", %{
    conn: conn
  } do
    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    for {query, opts} <- [
          {"query", %{}},
          {"query", %{"page" => %{"size" => 7, "number" => 2}}},
          {"query", %{"page" => %{"size" => 7}, "per_query" => %{"show_ranking_score" => true}}},
          {" query ", %{"page" => %{"size" => 7}}}
        ] do
      json =
        Jason.encode!(%{
          "playbook_format" => 1,
          "mode" => "search",
          "schema" => inspect(OpsPostB),
          "q" => query,
          "opts" => opts
        })

      view |> form("#playbook-paste-form", %{json: json}) |> render_submit()
      render_click(view, "run", %{})
      render_async(view)
      assert has_element?(view, "#playbook-preview", "Run finished")
      refute has_element?(view, "#playbook-search-handoff")
    end
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
    assert running_html =~ "Running playbook"
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
    assert running_html =~ "Running playbook"
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
    assert ran =~ "Run finished" || ran =~ "Playbook run completed"
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
    doc_links = playbook_doc_links(html)

    assert html =~ "data-testid=\"run-failure-panel\""
    assert html =~ "backend"
    assert html =~ "Search adapter returned a forced hard failure."
    assert html =~ "Copy diagnostics"

    assert doc_links in [
             [
               "https://github.com/szTheory/scrypath/blob/main/scrypath_ops/docs/playbook-schema-v1.md#troubleshooting",
               "https://github.com/szTheory/scrypath/blob/main/scrypath_ops/docs/team-playbook-persistence.md",
               "https://github.com/szTheory/scrypath/blob/main/guides/multi-index-search.md"
             ],
             [
               "https://github.com/szTheory/scrypath/blob/main/scrypath_ops/docs/playbook-schema-v1.md",
               "https://github.com/szTheory/scrypath/blob/main/scrypath_ops/docs/playbook-schema-v1.md#troubleshooting",
               "https://github.com/szTheory/scrypath/blob/main/scrypath_ops/docs/team-playbook-persistence.md",
               "https://github.com/szTheory/scrypath/blob/main/guides/multi-index-search.md"
             ]
           ]

    copied = render_click(view, "copy_run_diagnostics", %{})
    assert copied =~ "Copied diagnostics."
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

  test "playbook run emits telemetry start and stop for a completed run", %{conn: conn} do
    unique = System.unique_integer([:positive])
    start_handler_id = "playbook-live-start-#{unique}"
    stop_handler_id = "playbook-live-stop-#{unique}"
    parent = self()

    :telemetry.attach(
      start_handler_id,
      [:scrypath_ops, :playbook_run, :start],
      fn _event, measurements, metadata, _config ->
        send(parent, {:telemetry_start, measurements, metadata})
      end,
      nil
    )

    :telemetry.attach(
      stop_handler_id,
      [:scrypath_ops, :playbook_run, :stop],
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
    dir =
      Path.join(
        System.tmp_dir!(),
        "scrypath_ops_pb_run_now_#{:erlang.unique_integer([:positive])}"
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
    assert running_html =~ "Running playbook"

    html = render_async(view)

    assert html =~ "Run finished"
    assert html =~ basename
    refute html =~ "data-testid=\"run-failure-panel\""
  end

  test "loading a new playbook while running cancels and resets the active run", %{conn: conn} do
    dir =
      Path.join(
        System.tmp_dir!(),
        "scrypath_ops_pb_supersede_#{:erlang.unique_integer([:positive])}"
      )

    :ok = File.mkdir_p!(dir)
    prev_ws = Application.get_env(:scrypath_ops, :playbook_workspace_dir)
    prev_variant = Application.get_env(:scrypath_ops, :search_stub_variant)
    Application.put_env(:scrypath_ops, :playbook_workspace_dir, dir)
    Application.put_env(:scrypath_ops, :search_stub_variant, :slow_ok)

    on_exit(fn ->
      File.rm_rf(dir)

      if prev_ws == nil,
        do: Application.delete_env(:scrypath_ops, :playbook_workspace_dir),
        else: Application.put_env(:scrypath_ops, :playbook_workspace_dir, prev_ws)

      if prev_variant == nil,
        do: Application.delete_env(:scrypath_ops, :search_stub_variant),
        else: Application.put_env(:scrypath_ops, :search_stub_variant, prev_variant)
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

    File.write!(Path.join(dir, "one.json"), one_json)
    File.write!(Path.join(dir, "two.json"), two_json)

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    render_click(view, "load", %{"name" => "one.json"})
    running_html = render_click(view, "run", %{})
    assert running_html =~ "Running playbook"

    load_html = render_click(view, "load", %{"name" => "two.json"})
    assert load_html =~ "Loaded playbook from disk."
    refute load_html =~ "Playbook run cancelled before a result was applied."
    refute render_async(view) =~ "Playbook run cancelled before a result was applied."
  end

  test "superseded run exit does not override the newer run result", %{conn: conn} do
    dir =
      Path.join(
        System.tmp_dir!(),
        "scrypath_ops_pb_supersede_result_#{:erlang.unique_integer([:positive])}"
      )

    :ok = File.mkdir_p!(dir)
    prev_ws = Application.get_env(:scrypath_ops, :playbook_workspace_dir)
    prev_variant = Application.get_env(:scrypath_ops, :search_stub_variant)
    Application.put_env(:scrypath_ops, :playbook_workspace_dir, dir)
    Application.put_env(:scrypath_ops, :search_stub_variant, :slow_ok)

    on_exit(fn ->
      File.rm_rf(dir)

      if prev_ws == nil,
        do: Application.delete_env(:scrypath_ops, :playbook_workspace_dir),
        else: Application.put_env(:scrypath_ops, :playbook_workspace_dir, prev_ws)

      if prev_variant == nil,
        do: Application.delete_env(:scrypath_ops, :search_stub_variant),
        else: Application.put_env(:scrypath_ops, :search_stub_variant, prev_variant)
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

    File.write!(Path.join(dir, "one.json"), one_json)
    File.write!(Path.join(dir, "two.json"), two_json)

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    render_click(view, "load", %{"name" => "one.json"})
    assert render_click(view, "run", %{}) =~ "Running playbook"

    load_html = render_click(view, "load", %{"name" => "two.json"})
    assert load_html =~ "Loaded playbook from disk."

    assert render_click(view, "run", %{}) =~ "Running playbook"

    html = render_async(view)
    assert html =~ "Run finished"
    refute html =~ "Playbook run cancelled before a result was applied."
    refute html =~ "data-testid=\"run-failure-panel\""
  end

  test "legacy workspace JSON without title shows Untitled playbook", %{conn: conn} do
    dir =
      Path.join(
        System.tmp_dir!(),
        "scrypath_ops_pb_untitled_#{:erlang.unique_integer([:positive])}"
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

    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "x",
        "opts" => %{}
      })

    File.write!(Path.join(dir, "legacy.json"), json)

    {:ok, _view, html} = live(conn, ~p"/ops/playbooks")
    assert html =~ "Untitled playbook"
    assert html =~ "legacy.json"
  end

  test "duplicate flow writes suggested copy basename", %{conn: conn} do
    dir =
      Path.join(
        System.tmp_dir!(),
        "scrypath_ops_pb_dup_#{:erlang.unique_integer([:positive])}"
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

    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "x",
        "opts" => %{}
      })

    File.write!(Path.join(dir, "one.json"), json)

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    render_click(view, "dup_open", %{"name" => "one.json"})

    view
    |> form("form[phx-submit='dup_submit']", %{"to_name" => "one-1.json"})
    |> render_submit()

    assert File.exists?(Path.join(dir, "one-1.json"))
  end

  test "delete confirmation mismatch shows flash and keeps file", %{conn: conn} do
    dir =
      Path.join(
        System.tmp_dir!(),
        "scrypath_ops_pb_delcfm_#{:erlang.unique_integer([:positive])}"
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

    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "x",
        "opts" => %{}
      })

    path = Path.join(dir, "todelete.json")
    File.write!(path, json)

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    render_click(view, "request_delete", %{"name" => "todelete.json"})

    html =
      view
      |> form("form[phx-submit='confirm_delete']", %{"confirm" => "wrong-name.json"})
      |> render_submit()

    assert html =~ "Confirmation must match the filename exactly."
    assert has_element?(view, "#delete-playbook-modal [role='alert']", "Confirmation must match")
    assert has_element?(view, "#delete-confirm-input[aria-invalid='true']")
    assert File.exists?(path)
  end

  test "sigra confirm delete redirects stale sudo and keeps the workspace file", %{} do
    dir =
      Path.join(
        System.tmp_dir!(),
        "scrypath_ops_pb_sigra_del_#{:erlang.unique_integer([:positive])}"
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

    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "x",
        "opts" => %{}
      })

    path = Path.join(dir, "sigra-delete.json")
    File.write!(path, json)

    socket = %Phoenix.LiveView.Socket{
      assigns: %{
        __changed__: %{},
        flash: %{},
        delete_pending: "sigra-delete.json",
        workspace_root: dir,
        workspace_writable?: true,
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
      ScrypathOpsWeb.PlaybookLive.handle_event(
        "confirm_delete",
        %{"confirm" => "sigra-delete.json"},
        socket
      )

    socket = result_socket
    assert inspect(socket.redirected) =~ "/sudo/confirm"
    assert inspect(socket.redirected) =~ "return_to=%2Fops%2Fplaybooks"
    assert File.exists?(path)
  end

  test "sigra confirm delete clears only the selected playbook state", %{conn: conn} do
    dir =
      Path.join(
        System.tmp_dir!(),
        "scrypath_ops_pb_sigra_delete_ok_#{:erlang.unique_integer([:positive])}"
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

    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "x",
        "opts" => %{}
      })

    path = Path.join(dir, "sigra-delete-ok.json")
    File.write!(path, json)

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
    refute File.exists?(path)

    assigns = :sys.get_state(view.pid).socket.assigns
    assert assigns.delete_pending == nil
    assert assigns.selected_basename == nil
    assert assigns.draft_playbook == nil
    assert assigns.preview_json == nil
    assert assigns.preview_marker == false
    assert assigns.run_result == nil
    assert assigns.run_error == nil
  end

  test "rename collision shows in-use flash", %{conn: conn} do
    dir =
      Path.join(
        System.tmp_dir!(),
        "scrypath_ops_pb_ren_#{:erlang.unique_integer([:positive])}"
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

    json =
      Jason.encode!(%{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => "x",
        "opts" => %{}
      })

    File.write!(Path.join(dir, "a.json"), json)
    File.write!(Path.join(dir, "b.json"), json)

    {:ok, view, _html} = live(conn, ~p"/ops/playbooks")

    render_click(view, "rename_open", %{"name" => "a.json"})

    html =
      view
      |> form("form[phx-submit='rename_submit']", %{"new_name" => "b.json"})
      |> render_submit()

    assert html =~ "That playbook name is already in use"
  end

  defp playbook_doc_links(html) do
    Regex.scan(~r/href="(https:\/\/github\.com\/szTheory\/scrypath\/blob\/main\/[^"]+)"/, html)
    |> Enum.map(fn [_, href] -> href end)
    |> Enum.uniq()
  end

  defp configure_workspace(name) do
    dir =
      Path.join(
        System.tmp_dir!(),
        "scrypath_ops_pb_#{name}_#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(dir)
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

  defp search_playbook_json(query) do
    Jason.encode!(%{
      "playbook_format" => 1,
      "mode" => "search",
      "schema" => "ScrypathOps.Test.OpsPostA",
      "q" => query,
      "opts" => %{}
    })
  end

  defp multi_playbook_json(entries, opts) do
    Jason.encode!(%{
      "playbook_format" => 1,
      "mode" => "search_many",
      "entries" => entries,
      "opts" => opts
    })
  end

  defp search_handoff_path(view) do
    view
    |> element("#playbook-search-handoff")
    |> render()
    |> LazyHTML.from_fragment()
    |> LazyHTML.query("a")
    |> LazyHTML.attribute("href")
    |> hd()
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
