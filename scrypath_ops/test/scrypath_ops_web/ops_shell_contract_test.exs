defmodule ScrypathOpsWeb.OpsShellContractTest do
  @moduledoc false
  # Phase 49 OPSUX-05: structural contracts for `/ops` shell (D-19) — no Phase 48 IA duplication.
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScrypathOpsWeb.CoreComponents
  alias ScrypathOps.Test.OpsPostA
  alias ScrypathOps.Test.OpsPostB
  alias ScrypathOps.Test.SearchPlaygroundStubAdapter

  @root_template Path.join(
                   __DIR__,
                   "../../lib/scrypath_ops_web/components/layouts/root.html.heex"
                 )
                 |> Path.expand()

  @app_js Path.join(__DIR__, "../../assets/js/app.js") |> Path.expand()
  @app_css Path.join(__DIR__, "../../assets/css/app.css") |> Path.expand()
  @ops_hooks Path.join(__DIR__, "../../assets/js/ops_hooks.js") |> Path.expand()
  @host_js Path.join(__DIR__, "../../../examples/scrypath_ecommerce/assets/js/app.js")
           |> Path.expand()

  defmodule OpsShellContractMeili do
    @moduledoc false
    def tasks(filters, config) do
      uids = filters[:index_uids] || []

      if "octst_ops_post_a" in uids do
        {:error, :boom}
      else
        {:ok, %{results: Keyword.get(config, :meilisearch_tasks, [])}}
      end
    end

    def get_settings(_index, _config), do: {:error, :settings}
  end

  defmodule OpsShellContractObanInspector do
    @moduledoc false
    def list_jobs(_schema_module, config) do
      {:ok, Keyword.get(config, :oban_jobs, [])}
    end
  end

  defmodule RecordingOban do
    @moduledoc false
    def insert(changeset) do
      job = Ecto.Changeset.apply_changes(changeset)
      {:ok, %{job | id: 991, state: "available"}}
    end
  end

  setup do
    keys = ~w(
      schema_allowlist backend sync_mode index_prefix meilisearch_url meilisearch_client
      meilisearch_tasks oban oban_queue oban_inspector oban_jobs search_playground_adapter
      search_stub_variant
    )a

    previous = Map.new(keys, &{&1, Application.get_env(:scrypath_ops, &1)})

    Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostA, OpsPostB])
    Application.put_env(:scrypath_ops, :backend, Scrypath.Meilisearch)
    Application.put_env(:scrypath_ops, :sync_mode, :manual)
    Application.put_env(:scrypath_ops, :index_prefix, "octst")
    Application.put_env(:scrypath_ops, :meilisearch_url, "http://localhost:7700")
    Application.put_env(:scrypath_ops, :meilisearch_client, OpsShellContractMeili)

    Application.put_env(:scrypath_ops, :meilisearch_tasks, [
      %{
        "uid" => 1,
        "status" => "succeeded",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "octst_ops_post_b",
        "finishedAt" => "2026-04-16T18:00:00Z"
      }
    ])

    Application.put_env(:scrypath_ops, :oban, RecordingOban)
    Application.put_env(:scrypath_ops, :oban_queue, :search_sync)
    Application.put_env(:scrypath_ops, :oban_inspector, OpsShellContractObanInspector)

    Application.put_env(:scrypath_ops, :oban_jobs, [
      %{
        id: 501,
        state: "retryable",
        worker: "Scrypath.Oban.UpsertWorker",
        queue: "search_sync",
        args: %{
          "operation" => "upsert",
          "schema" => "Elixir.ScrypathOps.Test.OpsPostA",
          "backend" => "Elixir.Scrypath.Meilisearch",
          "index" => "octst_ops_post_a",
          "document_count" => 1,
          "document_ids" => [1],
          "documents" => [
            %{"id" => 1, "data" => %{"title" => "One"}, "source" => "fields"}
          ]
        }
      }
    ])

    Application.put_env(:scrypath_ops, :search_playground_adapter, SearchPlaygroundStubAdapter)
    Application.put_env(:scrypath_ops, :search_stub_variant, :ok)

    on_exit(fn ->
      Enum.each(previous, fn
        {k, nil} -> Application.delete_env(:scrypath_ops, k)
        {k, v} -> Application.put_env(:scrypath_ops, k, v)
      end)
    end)

    :ok
  end

  defp assert_ops_shell!(html, title_fragment) do
    assert html =~ "data-phx-session"
    assert html =~ title_fragment
    assert html =~ ~r/href="\/ops\/assets\/css\/app(?:-[^"]+)?\.css(?:\?[^"]*)?"/
    assert html =~ ~r/src="\/ops\/assets\/js\/app(?:-[^"]+)?\.js(?:\?[^"]*)?"/
    assert html =~ ~s(id="flash-group")
    assert Regex.scan(~r/id=\"flash-group\"/, html) |> length() == 1
    assert html =~ ~s(id="ops-main")
    assert html =~ "Skip to operator content"
    assert html =~ ~s(href="#ops-main")
    assert html =~ ~s(id="ops-page-title")
    assert html =~ ~s(aria-current="page")

    assert Regex.scan(
             ~r/<a[^>]*class=\"[^\"]*ops-nav-item-active[^\"]*\"[^>]*aria-current=\"page\"/,
             html
           )
           |> length() == 2

    assert html =~ ~s(href="/ops/health")
    assert html =~ ~s(id="ops-shell-frame")
    assert html =~ ~s(phx-hook="OpsNavDrawer")
    assert html =~ ~s(class="ops-sidebar")
    assert html =~ ~s(id="ops-mobile-nav")
    assert html =~ ~s(data-ops-nav-drawer)
    assert html =~ ~s(data-ops-nav-panel)
    assert html =~ ~s(data-ops-nav-open)
    assert html =~ ~s(aria-label="Open navigation")
    assert html =~ ~s(aria-controls="ops-mobile-nav")
    assert html =~ ~s(aria-expanded="false")
    assert html =~ ~s(aria-label="Close navigation")
    assert html =~ ~s(data-ops-nav-link)
    # The shell renders the canonical horizontal wordmark in both themes; the
    # enclosing logo-only home link retains its accessible name.
    assert html =~ ~s(ops-wordmark)
    assert html =~ ~s(src="/ops/images/scrypath-wordmark.svg")
    assert html =~ ~s(src="/ops/images/scrypath-wordmark-inverse.svg")
    assert html =~ ~s(aria-label="Scrypath home")
    assert html =~ ~s(class="ops-theme-toggle)
    assert Regex.scan(~r/class=\"[^\"]*ops-theme-toggle__button/, html) |> length() == 3
    assert Regex.scan(~r/data-phx-theme=\"(?:system|light|dark)\"/, html) |> length() == 3
    assert html =~ ~s(aria-label="Theme preference")
    assert html =~ ~s(aria-label="Use system theme")
    assert html =~ ~s(aria-label="Use light theme")
    assert html =~ ~s(aria-label="Use dark theme")
    assert html =~ "System"
    assert html =~ "Light"
    assert html =~ "Dark"
    assert File.read!(@app_css) =~ "min-height: 44px;"

    assert Regex.scan(
             ~r/class=\"[^\"]*ops-theme-toggle__button[^\"]*\"[^>]*aria-pressed=\"false\"/,
             html
           )
           |> length() == 3

    assert Regex.scan(~r/data-theme-selected=\"false\"/, html) |> length() == 3
    assert html =~ ~s(id="ops-command-palette")
    assert html =~ ~s(phx-hook="CommandPalette")
    assert html =~ ~s(data-cheatsheet="ops-cheatsheet")
    assert Regex.scan(~r/data-ops-command-open/, html) |> length() == 1
    assert Regex.scan(~r/aria-label=\"Jump to surface\"/, html) |> length() == 1
    assert html =~ ~s(aria-keyshortcuts="Meta+K Control+K")
    assert html =~ ~s(id="ops-cmdk")
    assert html =~ ~s(id="ops-cheatsheet")
    assert html =~ ~s(data-cmdk-close)
    assert html =~ ~s(data-cmdk-input)
    assert html =~ ~s(data-cmdk-empty)
    assert Regex.scan(~r/data-cmdk-item/, html) |> length() == 6
    assert Regex.scan(~r/aria-selected=\"false\"/, html) |> length() == 6
    assert Regex.scan(~r/id=\"ops-cmdk-item-\d+\"/, html) |> length() == 6
    assert html =~ ~s(aria-controls="ops-cmdk-list")
  end

  describe "ops shell markers" do
    test "/ops/health", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/ops/health")
      assert_ops_shell!(html, "Search health")
    end

    test "/ops/failed-sync", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/ops/failed-sync")
      assert_ops_shell!(html, "Failed sync work")
    end

    test "/ops/sync-drift", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/ops/sync-drift")
      assert_ops_shell!(html, "Sync and drift")
    end

    test "/ops/search", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/ops/search")
      assert_ops_shell!(html, "Search")
    end
  end

  test "shell recovery context follows the selected schema across health, failed work, and drift",
       %{
         conn: conn
       } do
    schema_a = ScrypathOps.OperatorSelection.canonical(OpsPostA)
    schema_b = ScrypathOps.OperatorSelection.canonical(OpsPostB)
    query_a = URI.encode_query(%{"schema" => schema_a})

    {:ok, health_lv, _health_html} = live(conn, "/ops/health?" <> query_a)
    assert has_element?(health_lv, "[data-testid='shell-recovery-target']", schema_a)

    for destination <- ["health", "failed-sync", "sync-drift"] do
      href = "/ops/#{destination}?#{query_a}"
      assert has_element?(health_lv, ".ops-sidebar a[href='#{href}']")
      assert has_element?(health_lv, "#ops-mobile-nav a[href='#{href}']")
    end

    assert has_element?(
             health_lv,
             "[data-testid='posture-failed-sync-link'][href$='schema=#{schema_b}']"
           )

    Application.put_env(:scrypath_ops, :sync_mode, :oban)
    Application.put_env(:scrypath_ops, :meilisearch_tasks, [])
    Application.put_env(:scrypath_ops, :index_prefix, "shell-contract")
    {:ok, failed_lv, _failed_html} = live(conn, "/ops/failed-sync?" <> query_a)
    assert has_element?(failed_lv, "[data-testid='shell-recovery-target']", schema_a)
    assert has_element?(failed_lv, "a[href='/ops/sync-drift?#{query_a}']", "Check sync and drift")

    {:ok, drift_lv, _drift_html} = live(conn, "/ops/sync-drift?" <> query_a)
    assert has_element?(drift_lv, "[data-testid='shell-recovery-target']", schema_a)
    assert has_element?(drift_lv, "a[href='/ops/health?#{query_a}']", "Inspect search health")

    drift_lv
    |> form("#sync-drift-schema-form", %{"schema" => schema_b})
    |> render_change()

    query_b = URI.encode_query(%{"schema" => schema_b})
    assert_patch(drift_lv, "/ops/sync-drift?" <> query_b)
    assert has_element?(drift_lv, "[data-testid='shell-recovery-target']", schema_b)
    assert has_element?(drift_lv, ".ops-sidebar a[href='/ops/health?#{query_b}']")
  end

  test "root theme provider synchronizes selected theme button state" do
    source = File.read!(@root_template)

    assert source =~ "syncThemeButtons"
    assert source =~ "querySelectorAll(\"[data-phx-theme]\")"
    assert source =~ "setAttribute(\"aria-pressed\""
    assert source =~ "setAttribute(\"data-theme-selected\""
    assert source =~ "syncThemeButtons();"
    assert source =~ "DOMContentLoaded"
    assert source =~ "closest(\"[data-phx-theme]\")"
    assert source =~ "phx:page-loading-stop"
    assert source =~ "safeThemePreference"
    assert source =~ "try {"
    assert source =~ "catch (_) {}"
    refute source =~ "localStorage.getItem(\"phx:theme\");\n          if"
  end

  test "shortcut sheet advertises command palette shortcut across platforms", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/ops/health")

    assert html =~ "Command or Control K"
    assert html =~ "<kbd"
    assert html =~ "Ctrl"
  end

  test "command palette recovery destinations follow the validated schema through patches", %{conn: conn} do
    schema_a = ScrypathOps.OperatorSelection.canonical(OpsPostA)
    schema_b = ScrypathOps.OperatorSelection.canonical(OpsPostB)
    query_a = URI.encode_query(%{"schema" => schema_a})
    query_b = URI.encode_query(%{"schema" => schema_b})

    {:ok, lv, _html} = live(conn, "/ops/sync-drift?" <> query_a)

    assert has_element?(lv, "#ops-command-palette-destinations")
    assert has_element?(lv, "#ops-palette-destination-health[href='/ops/health?#{query_a}']")
    assert has_element?(lv, "#ops-cmdk-item-1[href='/ops/health?#{query_a}']")

    lv
    |> form("#sync-drift-schema-form", %{"schema" => schema_b})
    |> render_change()

    assert_patch(lv, "/ops/sync-drift?" <> query_b)
    assert has_element?(lv, "#ops-palette-destination-health[href='/ops/health?#{query_b}']")
    assert has_element?(lv, "#ops-cmdk-item-1[href='/ops/health?#{query_a}']")

    {:ok, invalid_lv, _invalid_html} = live(conn, "/ops/health?schema=ScrypathOps.Test.NotAllowed")
    refute has_element?(invalid_lv, "#ops-palette-destination-health")
    refute has_element?(invalid_lv, "#ops-command-palette-destinations a[href*='schema=']")
  end

  test "command palette hook opens from visible shortcut affordances" do
    source = File.read!(@ops_hooks)

    assert source =~ ~S|closest("[data-ops-command-open]")|
    assert source =~ ~S|document.addEventListener("click", this.onCommandOpenClick)|
    assert source =~ ~S|document.removeEventListener("click", this.onCommandOpenClick)|
    assert source =~ "this.open()"
  end

  test "refresh hook overlays loading on server-rendered disabled eligibility" do
    source = File.read!(@ops_hooks)

    assert source =~ "this.serverDisabled = this.el.disabled"
    assert source =~ "this.el.disabled = this.serverDisabled || loading"
    assert source =~ "updated()"
    [_, hook] = Regex.run(~r/const OpsRefreshButton = \{([\s\S]*?)\n\}/, source)
    refute hook =~ "textContent"
    refute hook =~ "innerHTML"
  end

  test "standalone and mounted LiveSockets share all operator hooks" do
    for path <- [@app_js, @host_js] do
      source = File.read!(path)
      [_, imports] = Regex.run(~r/import\s*\{([^}]+)\}\s*from\s*["'][^"']*ops_hooks["']/, source)
      [_, hooks] = Regex.run(~r/hooks:\s*\{([^}]+)\}/, source)
      imported = String.split(imports, ~r/\s*,\s*/, trim: true) |> Enum.map(&String.trim/1)
      registered = String.split(hooks, ~r/\s*,\s*/, trim: true) |> Enum.map(&String.trim/1)

      for hook <- ~w(CommandPalette OpsNavDrawer OpsModal OpsRefreshButton OpsToast) do
        assert hook in imported, "#{path} must import #{hook}"
        assert hook in registered, "#{path} must register #{hook}"
      end
    end

    refute File.read!(@host_js) =~ "const CommandPalette ="
  end

  test "flash distinguishes informational status from persistent error alerts" do
    info =
      render_component(&CoreComponents.flash/1,
        kind: :info,
        flash: %{"info" => "Saved playbook."}
      )

    error =
      render_component(&CoreComponents.flash/1,
        kind: :error,
        flash: %{"error" => "Search sync failed."}
      )

    assert info =~ ~s(role="status")
    assert info =~ ~s(phx-hook="OpsToast")
    assert info =~ "ops-flash"
    assert info =~ "ops-flash--info"
    assert info =~ "Saved playbook."
    assert info =~ ~s(aria-label="Close notification")
    assert info =~ "lv:clear-flash"
    assert info =~ "hero-information-circle" or Regex.scan(~r/<svg\b/, info) |> length() == 2

    assert error =~ ~s(role="alert")
    refute error =~ ~s(phx-hook="OpsToast")
    assert error =~ "ops-flash"
    assert error =~ "ops-flash--error"
    assert error =~ "Search sync failed."
    assert error =~ ~s(aria-label="Close notification")
    assert error =~ "lv:clear-flash"
    assert error =~ "hero-exclamation-circle" or Regex.scan(~r/<svg\b/, error) |> length() == 2
  end
end
