defmodule ScrypathOpsWeb.OpsShellContractTest do
  @moduledoc false
  # Phase 49 OPSUX-05: structural contracts for `/ops` shell (D-19) — no Phase 48 IA duplication.
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScrypathOps.Test.OpsPostA
  alias ScrypathOps.Test.OpsPostB
  alias ScrypathOps.Test.SearchPlaygroundStubAdapter

  @root_template Path.join(
                   __DIR__,
                   "../../lib/scrypath_ops_web/components/layouts/root.html.heex"
                 )
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
           |> length() == 1

    assert html =~ ~s(href="/ops/posture")
    # v1.5 brand: the shell header renders the inline-SVG brand mark (decorative,
    # aria-hidden) with the copper "/" accent — no more <img src="/ops/images/logo.svg">.
    # "ScrypathOps" below is its accessible name.
    assert html =~ ~s(ops-brand-mark)
    assert html =~ ~s(fill="#C17A3E")
    assert html =~ "ScrypathOps"
    assert html =~ ~s(class="ops-theme-toggle)
    assert html =~ ~s(id="theme-toggle-pill")
    assert html =~ ~s(ops-theme-toggle__pill)
    assert Regex.scan(~r/class=\"[^\"]*ops-theme-toggle__button/, html) |> length() == 3
    assert Regex.scan(~r/data-phx-theme=\"(?:system|light|dark)\"/, html) |> length() == 3
    assert html =~ ~s(aria-label="Theme preference")
    assert html =~ ~s(aria-label="Use system theme")
    assert html =~ ~s(aria-label="Use light theme")
    assert html =~ ~s(aria-label="Use dark theme")
    assert Regex.scan(~r/aria-pressed=\"false\"/, html) |> length() == 3
    assert Regex.scan(~r/data-theme-selected=\"false\"/, html) |> length() == 3
    assert html =~ ~s(id="ops-command-palette")
    assert html =~ ~s(phx-hook="CommandPalette")
    assert html =~ ~s(data-cheatsheet="ops-cheatsheet")
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
    test "/ops/posture", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/ops/posture")
      assert_ops_shell!(html, "Posture / health")
    end

    test "/ops/failed-sync", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/ops/failed-sync")
      assert_ops_shell!(html, "Failed sync work")
    end

    test "/ops/sync-drift", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/ops/sync-drift")
      assert_ops_shell!(html, "Sync / drift")
    end

    test "/ops/search", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/ops/search")
      assert_ops_shell!(html, "Search &amp; federation")
    end
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
  end
end
