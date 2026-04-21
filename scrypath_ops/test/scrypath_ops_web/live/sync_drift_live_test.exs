defmodule ScrypathOpsWeb.SyncDriftLiveTest do
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScrypathOps.Test.OpsPostA

  defmodule SyncDriftClient do
    def tasks(_filters, config) do
      {:ok, %{results: Keyword.get(config, :meilisearch_tasks, [])}}
    end

    def get_settings(_index, _config) do
      {:error, :settings}
    end
  end

  defmodule SyncDriftObanInspector do
    def list_jobs(_schema_module, config) do
      {:ok, Keyword.get(config, :oban_jobs, [])}
    end
  end

  setup do
    keys = ~w(
      schema_allowlist backend sync_mode index_prefix meilisearch_url meilisearch_client
      meilisearch_tasks oban oban_queue oban_inspector oban_jobs
    )a

    previous = Map.new(keys, &{&1, Application.get_env(:scrypath_ops, &1)})

    Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostA])
    Application.put_env(:scrypath_ops, :backend, Scrypath.Meilisearch)
    Application.put_env(:scrypath_ops, :sync_mode, :manual)
    Application.put_env(:scrypath_ops, :index_prefix, "sdv")
    Application.put_env(:scrypath_ops, :meilisearch_url, "http://localhost:7700")
    Application.put_env(:scrypath_ops, :meilisearch_client, SyncDriftClient)
    Application.put_env(:scrypath_ops, :meilisearch_tasks, [])
    Application.put_env(:scrypath_ops, :oban, nil)
    Application.put_env(:scrypath_ops, :oban_queue, nil)
    Application.put_env(:scrypath_ops, :oban_inspector, SyncDriftObanInspector)
    Application.put_env(:scrypath_ops, :oban_jobs, [])

    on_exit(fn ->
      Enum.each(previous, fn
        {k, nil} -> Application.delete_env(:scrypath_ops, k)
        {k, v} -> Application.put_env(:scrypath_ops, k, v)
      end)
    end)

    :ok
  end

  test "loads reconcile on mount and scopes drift errors separately", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/ops/sync-drift")

    assert html =~ "queue posture"
    assert html =~ "Index contract (declared vs live)"
    assert html =~ "sdv_ops_post_a"

    html2 =
      lv
      |> element("button", "Load / refresh contract drift")
      |> render_click()

    assert html2 =~ ":settings"
    assert html2 =~ "sdv_ops_post_a"
  end
end
