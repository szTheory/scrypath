defmodule ScrypathOpsWeb.SearchLiveTest do
  @moduledoc false
  # Phase 47 D-10: SECURITY + prod guard tests. D-11: allowlist-only targeting.
  # D-15/D-16: no auto-run on mount; page ceiling copy; partial vs hard errors.
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

    Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostA, OpsPostB])
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
    {:ok, _lv, html} = live(conn, ~p"/ops/search")

    assert html =~ "Non-production search playground"
    assert html =~ "Run sample searches"
    refute html =~ "Per-schema panels"
    refute html =~ ~s(<h2 class="text-heading font-semibold">Results</h2>)
  end

  test "empty schema_allowlist shows OPSUI guard copy and disables targeting", %{conn: conn} do
    Application.put_env(:scrypath_ops, :schema_allowlist, [])

    {:ok, _lv, html} = live(conn, ~p"/ops/search")

    assert html =~ "No schemas configured for OPSUI"
    assert html =~ "pointer-events-none"
  end

  test "mode=multi renders multi toggle test id", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/ops/search?mode=multi")

    assert html =~ ~s(data-testid="search-mode-multi")
    assert html =~ "Multi index"
  end

  test "multi search with stub partial shows L1 partial copy", %{conn: conn} do
    Application.put_env(:scrypath_ops, :search_stub_variant, :partial)

    {:ok, view, _html} = live(conn, ~p"/ops/search?mode=multi")

    html =
      view
      |> element("form")
      |> render_submit(%{
        "q" => "hello",
        "page_size" => "10",
        "schemas" => [inspect(OpsPostA), inspect(OpsPostB)]
      })

    assert html =~ "Some indexes did not return results."
  end

  test "page_size above ceiling surfaces 50 in error messaging", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/search")

    html =
      view
      |> element("form")
      |> render_submit(%{
        "q" => "x",
        "page_size" => "99",
        "schema" => inspect(OpsPostA)
      })

    assert html =~ "50"
  end

  test "merge stub exposes merge trace block", %{conn: conn} do
    Application.put_env(:scrypath_ops, :search_stub_variant, :merge)

    {:ok, view, _html} = live(conn, ~p"/ops/search?mode=multi")

    html =
      view
      |> element("form")
      |> render_submit(%{
        "q" => "merge",
        "page_size" => "10",
        "schemas" => [inspect(OpsPostA), inspect(OpsPostB)]
      })

    assert html =~ "Merge trace"
  end

  test "multi search_many total failure shows hard error alert, not partial banner", %{conn: conn} do
    Application.put_env(:scrypath_ops, :search_stub_variant, :hard_error)

    {:ok, view, _html} = live(conn, ~p"/ops/search?mode=multi")

    html =
      view
      |> element("form")
      |> render_submit(%{
        "q" => "boom",
        "page_size" => "10",
        "schemas" => [inspect(OpsPostA), inspect(OpsPostB)]
      })

    assert html =~ "Search could not run"
    assert html =~ "stub_hard_failure"
    refute html =~ "Some indexes did not return results."
  end
end
