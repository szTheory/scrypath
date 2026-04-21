defmodule ScrypathOpsWeb.PostureLiveTest do
  @moduledoc false
  # Phase 47 D-10: prod fail-closed `/ops` boot is `OPSUI_AUTH_MODE` + `Application`
  # (`scrypath_ops/docs/SECURITY.md`, `config_prod_guard_test.exs`). D-12: mixed
  # `{:ok, _}` / `{:error, _}` rows surface per-row errors (no fleet-level “all healthy”).
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScrypathOps.Test.OpsPostA
  alias ScrypathOps.Test.OpsPostB

  defmodule PostureFakeClient do
    def tasks(filters, config) do
      uids = filters[:index_uids] || []
      boom_index = "postlv_ops_post_a"

      if boom_index in uids do
        {:error, :boom}
      else
        {:ok, %{results: Keyword.get(config, :meilisearch_tasks, [])}}
      end
    end
  end

  setup do
    prev_allow = Application.get_env(:scrypath_ops, :schema_allowlist)
    prev_backend = Application.get_env(:scrypath_ops, :backend)
    prev_sync = Application.get_env(:scrypath_ops, :sync_mode)
    prev_prefix = Application.get_env(:scrypath_ops, :index_prefix)
    prev_url = Application.get_env(:scrypath_ops, :meilisearch_url)
    prev_client = Application.get_env(:scrypath_ops, :meilisearch_client)
    prev_tasks = Application.get_env(:scrypath_ops, :meilisearch_tasks)
    prev_oban = Application.get_env(:scrypath_ops, :oban)
    prev_queue = Application.get_env(:scrypath_ops, :oban_queue)
    prev_insp = Application.get_env(:scrypath_ops, :oban_inspector)
    prev_jobs = Application.get_env(:scrypath_ops, :oban_jobs)

    Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostA, OpsPostB])
    Application.put_env(:scrypath_ops, :backend, Scrypath.Meilisearch)
    Application.put_env(:scrypath_ops, :sync_mode, :manual)
    Application.put_env(:scrypath_ops, :index_prefix, "postlv")
    Application.put_env(:scrypath_ops, :meilisearch_url, "http://localhost:7700")
    Application.put_env(:scrypath_ops, :meilisearch_client, PostureFakeClient)

    Application.put_env(:scrypath_ops, :meilisearch_tasks, [
      %{
        "uid" => 1,
        "status" => "succeeded",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "postlv_ops_post_b",
        "finishedAt" => "2026-04-16T18:00:00Z"
      }
    ])

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
      restore.(:meilisearch_client, prev_client)
      restore.(:meilisearch_tasks, prev_tasks)
      restore.(:oban, prev_oban)
      restore.(:oban_queue, prev_queue)
      restore.(:oban_inspector, prev_insp)
      restore.(:oban_jobs, prev_jobs)
    end)

    :ok
  end

  test "renders posture rows with sync_status and surfaces errors first", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/ops/posture")

    assert html =~ "data-testid=\"posture-row\""
    assert html =~ "fetch error: :boom"
    assert html =~ "queue not observed"
  end
end
