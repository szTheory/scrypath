defmodule ScrypathOpsWeb.SearchSavedSearchesTest do
  @moduledoc false
  # Saved searches inside Search: toolbar picker, Save / Save as, and the Manage sheet.
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScrypathOps.SavedSearches
  alias ScrypathOps.Test.OpsPostA
  alias ScrypathOps.Test.OpsPostB
  alias ScrypathOps.Test.SearchPlaygroundStubAdapter

  @envs ~w(schema_allowlist backend sync_mode index_prefix meilisearch_url search_playground_adapter search_stub_variant sigra)a

  setup do
    previous = Map.new(@envs, &{&1, Application.get_env(:scrypath_ops, &1)})
    prev_auth = System.get_env("OPSUI_AUTH_MODE")

    Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostA, OpsPostB])
    Application.put_env(:scrypath_ops, :backend, Scrypath.Meilisearch)
    Application.put_env(:scrypath_ops, :sync_mode, :manual)
    Application.put_env(:scrypath_ops, :index_prefix, "sslv_test")
    Application.put_env(:scrypath_ops, :meilisearch_url, "http://localhost:7700")
    Application.put_env(:scrypath_ops, :search_playground_adapter, SearchPlaygroundStubAdapter)
    Application.put_env(:scrypath_ops, :search_stub_variant, :ok)

    Application.put_env(:scrypath_ops, :sigra,
      sudo_confirm_path: "/sudo/confirm",
      sudo_window: 300
    )

    # This router does not install the host's Sigra OnMount context; these tests
    # exercise saved-search UI behavior under host-owned authentication instead.
    System.put_env("OPSUI_AUTH_MODE", "basic")

    on_exit(fn ->
      Enum.each(previous, fn
        {key, nil} -> Application.delete_env(:scrypath_ops, key)
        {key, value} -> Application.put_env(:scrypath_ops, key, value)
      end)

      if prev_auth,
        do: System.put_env("OPSUI_AUTH_MODE", prev_auth),
        else: System.delete_env("OPSUI_AUTH_MODE")
    end)

    :ok
  end

  describe "toolbar" do
    test "shows the picker, Save search and Manage, without storage or page-era controls", %{
      conn: conn
    } do
      put!("Daily check", single("daily", %{"description" => "Checks the catalog"}))
      {:ok, view, html} = live(conn, ~p"/ops/search")

      assert has_element?(
               view,
               "#saved-search-picker-button[aria-expanded=false]",
               "Saved searches"
             )

      assert has_element?(view, "#saved-search-menu button", "Daily check")
      assert has_element?(view, "#saved-search-menu", "Checks the catalog")
      assert has_element?(view, "#search-save-new", "Save search")
      assert has_element?(view, "#saved-search-manage-open[data-ops-modal-trigger]")
      refute has_element?(view, "#saved-search-manage")

      for text <- ["Refresh list", "Your searches", "Storage folder", "playbook", "folder"] do
        refute html =~ text
      end
    end

    test "the picker reads the list again when opened", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/ops/search")
      refute has_element?(view, "#saved-search-menu button", "Added elsewhere")

      put!("Added elsewhere", single("x"))
      render_click(view, "reload_saved_searches", %{})

      assert has_element?(view, "#saved-search-menu button", "Added elsewhere")
    end
  end

  describe "pick a saved search" do
    test "fills the form and runs it immediately", %{conn: conn} do
      put!("Daily check", single("daily", %{"opts" => %{"page" => %{"size" => 7}}}, OpsPostB))
      {:ok, view, _html} = live(conn, ~p"/ops/search")

      view |> element("#saved-search-menu button", "Daily check") |> render_click()

      assert has_element?(view, "#search_q[value='daily']")
      assert has_element?(view, "#search_page_size[value='7']")
      assert has_element?(view, "input[name=schema][value='#{inspect(OpsPostB)}'][checked]")

      assert has_element?(
               view,
               "#search-run-attribution[data-query='daily'][data-limit='7'][data-mode=single]"
             )

      assert has_element?(view, "#saved-search-status", "Loaded “Daily check”")
      assert has_element?(view, "#saved-search-menu button[aria-current=true]", "Daily check")
      assert render(view) =~ "No matching documents"
      refute has_element?(view, "#search-save-new")
      refute has_element?(view, "#search-save-loaded")
      refute has_element?(view, "#search-stored-inputs")
      assert_patch(view)
    end

    test "reports saved_search_run telemetry for a picked search", %{conn: conn} do
      put!("Measured", single("m"))
      ref = make_ref()
      parent = self()

      :telemetry.attach_many(
        "saved-search-run-#{inspect(ref)}",
        [[:scrypath_ops, :saved_search_run, :start], [:scrypath_ops, :saved_search_run, :stop]],
        fn event, measurements, metadata, _ ->
          send(parent, {ref, event, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach("saved-search-run-#{inspect(ref)}") end)
      {:ok, view, _html} = live(conn, ~p"/ops/search")

      view |> element("#saved-search-menu button", "Measured") |> render_click()
      _ = render(view)

      assert_receive {^ref, [:scrypath_ops, :saved_search_run, :start], _, %{run_id: run_id}}

      assert_receive {^ref, [:scrypath_ops, :saved_search_run, :stop], %{duration: _},
                      %{run_id: ^run_id, result: :ok}}
    end

    test "loads a multi-schema saved search into multi mode", %{conn: conn} do
      put!("Both", multi([{OpsPostA, "shared"}, {OpsPostB, "shared"}]))
      {:ok, view, _html} = live(conn, ~p"/ops/search")

      view |> element("#saved-search-menu button", "Both") |> render_click()

      assert has_element?(view, "[data-testid=search-mode-multi][aria-pressed=true]")
      assert has_element?(view, "input[name='schemas[]'][value='#{inspect(OpsPostA)}'][checked]")
      assert has_element?(view, "input[name='schemas[]'][value='#{inspect(OpsPostB)}'][checked]")
      assert has_element?(view, "#search-run-attribution[data-mode=multi][data-query=shared]")
    end

    test "runs a saved search the form can't show exactly as saved, with its inputs", %{
      conn: conn
    } do
      put!("Per schema", multi([{OpsPostA, "alpha"}, {OpsPostB, "beta"}]))
      {:ok, view, _html} = live(conn, ~p"/ops/search")

      view |> element("#saved-search-menu button", "Per schema") |> render_click()

      assert has_element?(view, "#search-stored-inputs", "Inputs used for these results")
      assert has_element?(view, "#search-stored-inputs", "OpsPostA: “alpha”")
      assert has_element?(view, "#search-stored-inputs", "OpsPostB: “beta”")
      refute has_element?(view, "#search-run-attribution")
      refute has_element?(view, "nav[aria-label='Result pages']")

      refute has_element?(view, "#search-save-as")

      view
      |> element("#ops-search-playground-form")
      |> render_change(%{
        "q" => "gamma",
        "page_size" => "10",
        "schemas" => [inspect(OpsPostA), inspect(OpsPostB)]
      })

      # Overwriting would drop the per-schema queries, so only Save as is offered.
      refute has_element?(view, "#search-save-loaded")
      assert has_element?(view, "#search-save-as")
    end

    test "reports options Scrypath rejects as a run error instead of crashing", %{conn: conn} do
      put!("Bad filter", single("quantum", %{"opts" => %{"filter" => %{"missing_field" => "x"}}}))
      {:ok, view, _html} = live(conn, ~p"/ops/search")

      view |> element("#saved-search-menu button", "Bad filter") |> render_click()

      assert has_element?(view, "#search-stored-inputs", "Inputs used for these results")
      assert has_element?(view, "[role=alert]", "Search could not run")
      assert has_element?(view, "#search-run-error", "filter")
      assert render(view) =~ "Manage saved searches"
    end

    test "refuses a saved search that targets a schema that isn't allowlisted", %{conn: conn} do
      put!("Elsewhere", single("x", %{"schema" => "Some.Other.Schema"}))
      {:ok, view, _html} = live(conn, ~p"/ops/search")

      html = view |> element("#saved-search-menu button", "Elsewhere") |> render_click()

      assert html =~ "load “Elsewhere”"
      assert html =~ "available here: Some.Other.Schema"
      refute has_element?(view, "#search-results-heading")
      refute has_element?(view, "#saved-search-status", "Loaded")
    end

    test "a saved search deleted elsewhere gives a clear error and refreshes the list", %{
      conn: conn
    } do
      put!("Gone", single("x"))
      {:ok, view, _html} = live(conn, ~p"/ops/search")
      :ok = SavedSearches.delete(ScrypathOps.Repo, "Gone")

      html = render_click(view, "load_saved_search", %{"name" => "Gone"})

      assert html =~ "“Gone” no longer exists."
      refute has_element?(view, "#saved-search-menu button", "Gone")
    end
  end

  describe "save" do
    test "Save search names the current form inputs", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/ops/search")

      view
      |> element("#ops-search-playground-form")
      |> render_change(%{"q" => "unrun query", "page_size" => "9", "schema" => inspect(OpsPostB)})

      view |> element("#search-save-new") |> render_click()
      assert has_element?(view, "#saved-search-name-modal[role=dialog][aria-modal=true]")
      assert has_element?(view, "label[for=saved-search-name-input]", "Name")

      view
      |> form("#saved-search-name-form", %{"name" => "  Unrun  "})
      |> render_submit()

      assert definition("Unrun") == %{
               "playbook_format" => 1,
               "mode" => "search",
               "schema" => inspect(OpsPostB),
               "q" => "unrun query",
               "opts" => %{"page" => %{"size" => 9}}
             }

      refute has_element?(view, "#saved-search-name-modal")
      assert has_element?(view, "#saved-search-status", "Loaded “Unrun”")
      assert render(view) =~ "Saved “Unrun”."
      refute has_element?(view, "#search-save-new")
    end

    test "a taken name is reported inline and nothing is overwritten", %{conn: conn} do
      original = put!("Taken", single("original"))
      {:ok, view, _html} = live(conn, ~p"/ops/search")

      view |> element("#search-save-new") |> render_click()
      focus_before = focus_request(view)

      view |> form("#saved-search-name-form", %{"name" => "Taken"}) |> render_submit()

      assert has_element?(view, "#saved-search-name-input[aria-invalid=true][value=Taken]")
      assert has_element?(view, "#saved-search-name-input-error", "already exists")
      assert focus_request(view) > focus_before
      assert definition("Taken") == original.definition
    end

    test "an invalid result limit can't be saved", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/ops/search")

      view
      |> element("#ops-search-playground-form")
      |> render_change(%{"q" => "x", "page_size" => "999", "schema" => inspect(OpsPostA)})

      view |> element("#search-save-new") |> render_click()
      view |> form("#saved-search-name-form", %{"name" => "Too big"}) |> render_submit()

      assert has_element?(view, "#saved-search-name-input-error", "Results per page")
      assert {:error, :not_found} = SavedSearches.get(ScrypathOps.Repo, "Too big")
    end

    test "after edits, Save overwrites the loaded search and keeps its metadata", %{conn: conn} do
      put!("Daily", single("daily", %{"title" => "Daily", "description" => "Keep me"}))
      {:ok, view, _html} = live(conn, ~p"/ops/search")

      view |> element("#saved-search-menu button", "Daily") |> render_click()
      refute has_element?(view, "#search-save-loaded")

      view
      |> element("#ops-search-playground-form")
      |> render_change(%{"q" => "nightly", "page_size" => "10", "schema" => inspect(OpsPostA)})

      assert has_element?(view, "#saved-search-status", "edited")
      assert has_element?(view, "#search-save-loaded", "Save")
      assert has_element?(view, "#search-save-as", "Save as…")

      view |> element("#search-save-loaded") |> render_click()

      saved = definition("Daily")
      assert saved["q"] == "nightly"
      assert saved["description"] == "Keep me"
      refute has_element?(view, "#search-save-loaded")
    end

    test "Save as keeps the original and loads the copy", %{conn: conn} do
      put!("Daily", single("daily"))
      {:ok, view, _html} = live(conn, ~p"/ops/search")

      view |> element("#saved-search-menu button", "Daily") |> render_click()

      view
      |> element("#ops-search-playground-form")
      |> render_change(%{"q" => "weekly", "page_size" => "10", "schema" => inspect(OpsPostA)})

      view |> element("#search-save-as") |> render_click()
      assert has_element?(view, "#saved-search-name-modal-title", "Save as new search")

      view |> form("#saved-search-name-form", %{"name" => "Weekly"}) |> render_submit()

      assert definition("Daily")["q"] == "daily"
      assert definition("Weekly")["q"] == "weekly"
      assert has_element?(view, "#saved-search-status", "Loaded “Weekly”")
    end
  end

  describe "manage sheet" do
    test "opens from the toolbar as a labelled dialog and closes", %{conn: conn} do
      put!("One", single("one"))
      {:ok, view, _html} = live(conn, ~p"/ops/search")

      view |> element("#saved-search-manage-open") |> render_click()

      assert has_element?(
               view,
               "#saved-search-manage[role=dialog][aria-modal=true][aria-labelledby=saved-search-manage-title][phx-hook=OpsModal][data-ops-modal-cancel-event=close_manage]"
             )

      assert has_element?(
               view,
               "#saved-search-manage-title[tabindex='-1']",
               "Manage saved searches"
             )

      assert has_element?(view, "#saved-search-manage [data-ops-sheet-close][aria-label=Close]")
      assert has_element?(view, "#saved-search-list li", "One")

      for action <- ~w(Load Rename Export Delete) do
        assert has_element?(view, "#saved-search-list [aria-label='#{action} One']", action)
      end

      render_click(view, "close_manage", %{})
      refute has_element?(view, "#saved-search-manage")
    end

    test "?saved=manage opens the sheet and old /playbooks links redirect there", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/ops/search?saved=manage")
      assert has_element?(view, "#saved-search-manage")
      assert has_element?(view, "#saved-search-manage", "No saved searches yet.")

      render_click(view, "close_manage", %{})
      refute has_element?(view, "#saved-search-manage")
      assert_patch(view)

      assert {:error, {:live_redirect, %{to: "/ops/search?saved=manage"}}} =
               live(conn, ~p"/ops/playbooks")
    end

    test "opening the sheet reads the list again", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/ops/search")
      put!("Fresh", single("x"))

      view |> element("#saved-search-manage-open") |> render_click()

      assert has_element?(view, "#saved-search-list li", "Fresh")
    end

    test "Load closes the sheet and runs the search", %{conn: conn} do
      put!("One", single("one"))
      {:ok, view, _html} = live(conn, ~p"/ops/search?saved=manage")

      view |> element("#saved-search-list button[aria-label='Load One']") |> render_click()

      refute has_element?(view, "#saved-search-manage")
      assert has_element?(view, "#search-run-attribution[data-query=one]")
    end

    test "rename works inline, reports a taken name and keeps the loaded name in sync", %{
      conn: conn
    } do
      put!("A", single("a"))
      put!("B", single("b"))
      {:ok, view, _html} = live(conn, ~p"/ops/search")
      view |> element("#saved-search-menu button", "A") |> render_click()
      view |> element("#saved-search-manage-open") |> render_click()

      view |> element("#saved-search-list button[aria-label='Rename A']") |> render_click()
      assert has_element?(view, "#saved-search-rename-input[value=A]")
      assert sheet_focus(view) == "#saved-search-rename-input"

      view |> form("#saved-search-rename-form", %{"new_name" => "B"}) |> render_submit()
      assert has_element?(view, "#saved-search-rename-input-error", "already exists")
      assert definition("B")["q"] == "b"

      view |> form("#saved-search-rename-form", %{"new_name" => "Renamed"}) |> render_submit()

      assert has_element?(view, "#saved-search-list li", "Renamed")
      assert {:error, :not_found} = SavedSearches.get(ScrypathOps.Repo, "A")
      assert has_element?(view, "#saved-search-status", "Loaded “Renamed”")
      assert sheet_focus(view) == "#saved-search-rename-#{dom_id("Renamed")}"
    end

    test "Escape inside a row action returns to the list, then closes the sheet", %{conn: conn} do
      put!("A", single("a"))
      {:ok, view, _html} = live(conn, ~p"/ops/search?saved=manage")

      view |> element("#saved-search-list button[aria-label='Delete A']") |> render_click()
      assert has_element?(view, "#saved-search-delete-form")

      render_click(view, "close_manage", %{})
      refute has_element?(view, "#saved-search-delete-form")
      assert has_element?(view, "#saved-search-manage")
      assert sheet_focus(view) == "#saved-search-delete-#{dom_id("A")}"

      render_click(view, "close_manage", %{})
      refute has_element?(view, "#saved-search-manage")
    end

    test "delete requires the exact name and moves focus to the next row", %{conn: conn} do
      put!("A", single("a"))
      put!("B", single("b"))
      {:ok, view, _html} = live(conn, ~p"/ops/search")
      view |> element("#saved-search-menu button", "A") |> render_click()
      view |> element("#saved-search-manage-open") |> render_click()

      view |> element("#saved-search-list button[aria-label='Delete A']") |> render_click()
      view |> form("#saved-search-delete-form", %{"confirm" => "a"}) |> render_submit()

      assert has_element?(view, "#saved-search-delete-input[aria-invalid=true][value=a]")
      assert {:ok, _} = SavedSearches.get(ScrypathOps.Repo, "A")

      html = view |> form("#saved-search-delete-form", %{"confirm" => "A"}) |> render_submit()

      assert html =~ "Deleted “A”."
      assert {:error, :not_found} = SavedSearches.get(ScrypathOps.Repo, "A")
      refute has_element?(view, "#saved-search-list li", "A\n")
      refute has_element?(view, "#saved-search-status", "Loaded")
      assert sheet_focus(view) == "#saved-search-load-#{dom_id("B")}"

      view |> element("#saved-search-list button[aria-label='Delete B']") |> render_click()
      view |> form("#saved-search-delete-form", %{"confirm" => "B"}) |> render_submit()
      assert sheet_focus(view) == "#saved-search-manage-title"
      assert has_element?(view, "#saved-search-manage", "No saved searches yet.")
    end

    test "Sigra stale sudo redirects instead of deleting", %{conn: conn} do
      put!("Guarded", single("x"))
      {:ok, view, _html} = live(conn, ~p"/ops/search?saved=manage")

      view |> element("#saved-search-list button[aria-label='Delete Guarded']") |> render_click()

      put_live_assigns(view,
        operator_context: %ScrypathOps.Integrations.Sigra.OperatorContext{
          user_id: "user_123",
          active_org_id: "org_456",
          impersonator_user_id: nil,
          sudo_at: DateTime.add(DateTime.utc_now(), -600, :second)
        }
      )

      assert {:error, {:live_redirect, %{to: to}}} =
               view
               |> form("#saved-search-delete-form", %{"confirm" => "Guarded"})
               |> render_submit()

      assert to =~ "/sudo/confirm"
      assert to =~ "return_to=" <> URI.encode_www_form("/ops/search?saved=manage")
      assert {:ok, _} = SavedSearches.get(ScrypathOps.Repo, "Guarded")
    end

    test "Export links download the v1 JSON", %{conn: conn} do
      put!("Daily check", single("daily"))
      {:ok, view, _html} = live(conn, ~p"/ops/search?saved=manage")

      [href] =
        view
        |> element("#saved-search-export-#{dom_id("Daily check")}")
        |> render()
        |> LazyHTML.from_fragment()
        |> LazyHTML.attribute("href")

      assert has_element?(
               view,
               "#saved-search-export-#{dom_id("Daily check")}[download='Daily-check.json']"
             )

      "data:application/json;charset=utf-8," <> encoded = href
      assert Jason.decode!(URI.decode(encoded)) == single("daily")
    end
  end

  describe "import" do
    test "the file button opens the file input directly and imports on selection", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/ops/search?saved=manage")

      assert has_element?(view, "#saved-search-import-file", "Import JSON file")
      refute has_element?(view, "a[href='#saved-search-import']")
      refute has_element?(view, "#saved-search-import-form button[type=submit]")

      upload(view, "my-search.json", Jason.encode!(single("from file")))

      assert definition("my-search")["q"] == "from file"
      assert has_element?(view, "#saved-search-list li", "my-search")
      assert render(view) =~ "Imported “my-search”."
      assert sheet_focus(view) == "#saved-search-load-#{dom_id("my-search")}"
    end

    test "explains invalid JSON, an unsupported version and an unknown schema", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/ops/search?saved=manage")

      cases = [
        {"broken.json", "{not json", "isn't valid JSON"},
        {"v2.json", Jason.encode!(single("x", %{"playbook_format" => 2})),
         "Only format 1 is supported"},
        {"other.json", Jason.encode!(single("x", %{"schema" => "Not.Here"})),
         "isn't available here: Not.Here"}
      ]

      for {filename, content, message} <- cases do
        upload(view, filename, content)
        assert has_element?(view, "#saved-search-import-error[role=alert]", message)
        assert has_element?(view, "#saved-search-import-error", "Couldn't import #{filename}.")
      end

      assert SavedSearches.list(ScrypathOps.Repo) == []
    end

    test "a file named like an existing saved search isn't imported over it", %{conn: conn} do
      original = put!("daily", single("original"))
      {:ok, view, _html} = live(conn, ~p"/ops/search?saved=manage")

      upload(view, "daily.json", Jason.encode!(single("replacement")))

      assert has_element?(view, "#saved-search-import-error", "already exists")
      assert definition("daily") == original.definition
    end

    test "rejects files over the size limit", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/ops/search?saved=manage")
      content = String.duplicate(" ", 256_001)

      view
      |> file_input("#saved-search-import-form", :saved_search_file, [
        %{name: "huge.json", content: content, size: byte_size(content), type: "application/json"}
      ])
      |> render_upload("huge.json")

      render_change(view, "validate_import", %{})
      assert has_element?(view, "#saved-search-import-error", "larger than 256 KB")
    end

    test "paste import names and validates pasted JSON", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/ops/search?saved=manage")

      view
      |> form("#saved-search-paste-form", %{"name" => "Pasted", "json" => "[]"})
      |> render_submit()

      assert has_element?(view, "#saved-search-import-error", "Couldn't import the pasted JSON.")
      assert has_element?(view, "#saved-search-paste-json", "[]")

      view
      |> form("#saved-search-paste-form", %{
        "name" => "Pasted",
        "json" => Jason.encode!(multi([{OpsPostA, "q"}, {OpsPostB, "q"}]))
      })
      |> render_submit()

      assert definition("Pasted")["mode"] == "search_many"
      refute has_element?(view, "#saved-search-import-error")
    end
  end

  defp single(q, overrides \\ %{}, schema \\ OpsPostA) do
    Map.merge(
      %{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => inspect(schema),
        "q" => q,
        "opts" => %{}
      },
      overrides
    )
  end

  defp multi(entries) do
    %{
      "playbook_format" => 1,
      "mode" => "search_many",
      "entries" => Enum.map(entries, fn {schema, q} -> [inspect(schema), q, %{}] end),
      "opts" => %{}
    }
  end

  # Inserts the row directly so tests can store definitions the validator would reject.
  defp put!(name, definition) do
    ScrypathOps.Repo.insert!(%ScrypathOps.SavedSearches.SavedSearch{
      name: name,
      schema: ScrypathOps.SavedSearches.SavedSearch.schema_for(definition) || "unknown",
      definition: definition
    })
  end

  defp definition(name) do
    {:ok, saved_search} = SavedSearches.get(ScrypathOps.Repo, name)
    saved_search.definition
  end

  defp dom_id(name), do: Base.url_encode64(name, padding: false)

  defp upload(view, filename, content) do
    view
    |> file_input("#saved-search-import-form", :saved_search_file, [
      %{name: filename, content: content, size: byte_size(content), type: "application/json"}
    ])
    |> render_upload(filename)
  end

  defp assigns(view), do: :sys.get_state(view.pid).socket.assigns
  defp focus_request(view), do: assigns(view).modal_focus_request
  defp sheet_focus(view), do: assigns(view).sheet_focus

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
