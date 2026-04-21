defmodule ScrypathOpsWeb.FailedSyncLiveTest do
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScrypathOps.Test.OpsPostA

  defmodule FailedSyncFakeClient do
    def tasks(_filters, config) do
      {:ok, %{results: Keyword.get(config, :meilisearch_tasks, [])}}
    end
  end

  defmodule FailedSyncObanInspector do
    def list_jobs(_schema_module, config) do
      {:ok, Keyword.get(config, :oban_jobs, [])}
    end
  end

  defmodule RecordingOban do
    def insert(changeset) do
      job = Ecto.Changeset.apply_changes(changeset)
      {:ok, %{job | id: 991, state: "available"}}
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
    Application.put_env(:scrypath_ops, :sync_mode, :oban)
    Application.put_env(:scrypath_ops, :index_prefix, "fsv")
    Application.put_env(:scrypath_ops, :meilisearch_url, "http://localhost:7700")
    Application.put_env(:scrypath_ops, :meilisearch_client, FailedSyncFakeClient)

    Application.put_env(:scrypath_ops, :meilisearch_tasks, [
      %{
        "uid" => 401,
        "status" => "failed",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "fsv_ops_post_a",
        "error" => %{"message" => "index missing"}
      }
    ])

    Application.put_env(:scrypath_ops, :oban, RecordingOban)
    Application.put_env(:scrypath_ops, :oban_queue, :search_sync)
    Application.put_env(:scrypath_ops, :oban_inspector, FailedSyncObanInspector)

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
          "index" => "fsv_ops_post_a",
          "document_count" => 1,
          "document_ids" => [1],
          "documents" => [
            %{"id" => 1, "data" => %{"title" => "One"}, "source" => "fields"}
          ]
        }
      }
    ])

    on_exit(fn ->
      Enum.each(previous, fn
        {k, nil} -> Application.delete_env(:scrypath_ops, k)
        {k, v} -> Application.put_env(:scrypath_ops, k, v)
      end)
    end)

    :ok
  end

  test "renders rollups and reason_class columns", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/ops/failed-sync")

    assert html =~ ~r/total[^\d]*2/s

    assert Enum.any?(
             ~w(transport validation backend_rejected queue_exhausted unknown),
             &String.contains?(html, &1)
           )
  end
end
