defmodule Scrypath.MixTasks.OperatorTasksTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  defmodule TaskMeilisearchClient do
    def tasks(filters, _config) do
      tasks =
        Application.get_env(:scrypath, :operator_task_test_meilisearch_tasks, [])
        |> Enum.filter(fn task ->
          index_uid = task["indexUid"] || task[:indexUid] || task["index_uid"] || task[:index_uid]
          type = task["type"] || task[:type]
          index_uid in filters[:index_uids] and type in filters[:types]
        end)

      {:ok, %{results: tasks}}
    end
  end

  defmodule TaskObanInspector do
    def list_jobs(_schema_module, _config) do
      {:ok, Application.get_env(:scrypath, :operator_task_test_oban_jobs, [])}
    end
  end

  defmodule RecordingOban do
    def insert(changeset) do
      job = Ecto.Changeset.apply_changes(changeset)
      send(self(), {:oban_insert, job})
      {:ok, %{job | id: 4401, state: "available"}}
    end
  end

  setup do
    original_defaults = Application.get_env(:scrypath, :defaults)
    original_operator_opts = Application.get_env(:scrypath, :operator_task_test_opts)

    Application.put_env(:scrypath, :defaults,
      backend: Scrypath.Meilisearch,
      sync_mode: :oban,
      index_prefix: "tenant",
      meilisearch_url: "http://localhost:7700",
      meilisearch_client: TaskMeilisearchClient,
      oban: RecordingOban,
      oban_queue: :search_sync,
      oban_max_attempts: 8
    )

    on_exit(fn ->
      put_env_or_delete(:defaults, original_defaults)
      put_env_or_delete(:operator_task_test_opts, original_operator_opts)
      Application.delete_env(:scrypath, :operator_task_test_meilisearch_tasks)
      Application.delete_env(:scrypath, :operator_task_test_oban_jobs)
    end)

    :ok
  end

  test "scrypath.status and scrypath.failed delegate through the root operator APIs and print stable output" do
    Application.put_env(:scrypath, :operator_task_test_meilisearch_tasks, [
      %{
        "uid" => 401,
        "status" => "processing",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "tenant_searchable_post"
      },
      %{
        "uid" => 402,
        "status" => "succeeded",
        "type" => "documentDeletion",
        "indexUid" => "tenant_searchable_post",
        "finishedAt" => "2026-04-16T22:00:00Z"
      },
      %{
        "uid" => 403,
        "status" => "failed",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "tenant_searchable_post",
        "error" => %{"message" => "write failed"}
      }
    ])

    Application.put_env(:scrypath, :operator_task_test_oban_jobs, [
      %{
        id: 501,
        state: "retryable",
        worker: "Scrypath.Oban.UpsertWorker",
        queue: "search_sync",
        args: %{
          "operation" => "upsert",
          "index" => "tenant_searchable_post",
          "documents" => [%{"id" => 1, "data" => %{"title" => "One"}, "source" => "fields"}],
          "document_ids" => [1]
        }
      }
    ])

    Application.put_env(:scrypath, :operator_task_test_opts,
      meilisearch_tasks: Application.fetch_env!(:scrypath, :operator_task_test_meilisearch_tasks),
      oban_inspector: TaskObanInspector,
      oban_jobs: Application.fetch_env!(:scrypath, :operator_task_test_oban_jobs)
    )

    status_output =
      capture_io(fn ->
        Mix.Task.reenable("scrypath.status")
        Mix.Task.run("scrypath.status", ["SearchablePost"])
      end)

    assert status_output =~ "Schema: SearchablePost"
    assert status_output =~ "Mode: oban"
    assert status_output =~ "Backend pending: 1"
    assert status_output =~ "Backend failed: 1"
    assert status_output =~ "Queue retrying: 1"

    failed_output =
      capture_io(fn ->
        Mix.Task.reenable("scrypath.failed")
        Mix.Task.run("scrypath.failed", ["SearchablePost"])
      end)

    assert failed_output =~ "Schema: SearchablePost"
    assert failed_output =~ "Failed work: 2"
    assert failed_output =~ "Failed work by class:"

    assert failed_output =~
             "id=403 source=meilisearch state=failed operation=upsert retryable=no reason_class=unknown reason=write failed"

    assert failed_output =~
             "id=501 source=oban state=retrying operation=upsert retryable=yes reason_class=unknown"
  end

  test "scrypath.failed --json emits one JSON document without Mix shell noise" do
    Application.put_env(:scrypath, :operator_task_test_meilisearch_tasks, [
      %{
        "uid" => 403,
        "status" => "failed",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "tenant_searchable_post",
        "error" => %{"message" => "write failed"}
      }
    ])

    Application.put_env(:scrypath, :operator_task_test_oban_jobs, [])

    Application.put_env(:scrypath, :operator_task_test_opts,
      meilisearch_tasks: Application.fetch_env!(:scrypath, :operator_task_test_meilisearch_tasks),
      oban_inspector: TaskObanInspector,
      oban_jobs: []
    )

    json =
      capture_io(fn ->
        Mix.Task.reenable("scrypath.failed")
        Mix.Task.run("scrypath.failed", ["SearchablePost", "--json"])
      end)

    decoded = Jason.decode!(json)
    assert decoded["schema"] == "SearchablePost"
    assert [%{"id" => 403, "reason_class" => _} | _] = decoded["entries"]
    assert %{"version" => 1, "total" => 1, "by_class" => by} = decoded["counts"]
    assert Map.keys(by) |> MapSet.new() == MapSet.new(~w(
      transport validation backend_rejected queue_exhausted unknown
    ))
  end

  test "scrypath.failed --no-class-summary hides the rollup header" do
    Application.put_env(:scrypath, :operator_task_test_meilisearch_tasks, [
      %{
        "uid" => 403,
        "status" => "failed",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "tenant_searchable_post",
        "error" => %{"message" => "write failed"}
      }
    ])

    Application.put_env(:scrypath, :operator_task_test_oban_jobs, [])

    Application.put_env(:scrypath, :operator_task_test_opts,
      meilisearch_tasks: Application.fetch_env!(:scrypath, :operator_task_test_meilisearch_tasks),
      oban_inspector: TaskObanInspector,
      oban_jobs: []
    )

    out =
      capture_io(fn ->
        Mix.Task.reenable("scrypath.failed")
        Mix.Task.run("scrypath.failed", ["SearchablePost", "--no-class-summary"])
      end)

    refute out =~ "Failed work by class:"
    assert out =~ "reason_class="
  end

  test "scrypath.retry requires an explicit failed-work id and replays through Scrypath.retry_sync_work/2" do
    Application.put_env(:scrypath, :operator_task_test_meilisearch_tasks, [])

    Application.put_env(:scrypath, :operator_task_test_oban_jobs, [
      %{
        id: 601,
        state: "retryable",
        worker: "Scrypath.Oban.UpsertWorker",
        queue: "search_sync",
        args: %{
          "operation" => "upsert",
          "index" => "tenant_searchable_post",
          "documents" => [%{"id" => 9, "data" => %{"title" => "Replay"}, "source" => "fields"}],
          "document_ids" => [9]
        }
      }
    ])

    Application.put_env(:scrypath, :operator_task_test_opts,
      meilisearch_tasks: [],
      oban_inspector: TaskObanInspector,
      oban_jobs: Application.fetch_env!(:scrypath, :operator_task_test_oban_jobs)
    )

    output =
      capture_io(fn ->
        Mix.Task.reenable("scrypath.retry")
        Mix.Task.run("scrypath.retry", ["SearchablePost", "--id", "601"])
      end)

    assert output =~ "Retried failed work 601"
    assert output =~ "Status: accepted"
    assert output =~ "Mode: oban"

    assert_received {:oban_insert, job}
    assert job.worker == "Scrypath.Oban.UpsertWorker"
    assert job.args["document_ids"] == [9]
  end

  test "scrypath.retry surfaces non-retryable failures instead of inventing recovery semantics" do
    Application.put_env(:scrypath, :operator_task_test_meilisearch_tasks, [
      %{
        "uid" => 701,
        "status" => "failed",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "tenant_searchable_post",
        "error" => %{"message" => "index missing"}
      }
    ])

    Application.put_env(:scrypath, :operator_task_test_oban_jobs, [])

    Application.put_env(:scrypath, :operator_task_test_opts,
      meilisearch_tasks: Application.fetch_env!(:scrypath, :operator_task_test_meilisearch_tasks),
      oban_inspector: TaskObanInspector,
      oban_jobs: []
    )

    assert_raise Mix.Error, ~r/scrypath.retry failed: not_retryable/, fn ->
      Mix.Task.reenable("scrypath.retry")
      Mix.Task.run("scrypath.retry", ["SearchablePost", "--id", "701"])
    end
  end

  test "scrypath.reconcile stays report-first unless an explicit action is requested" do
    Application.put_env(:scrypath, :operator_task_test_meilisearch_tasks, [
      %{
        "uid" => 801,
        "status" => "failed",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "tenant_searchable_post",
        "error" => %{"message" => "write failed"}
      },
      %{
        "uid" => 901,
        "status" => "processing",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "tenant_searchable_post__reindex"
      }
    ])

    Application.put_env(:scrypath, :operator_task_test_oban_jobs, [
      %{
        id: 1001,
        state: "retryable",
        worker: "Scrypath.Oban.UpsertWorker",
        queue: "search_sync",
        args: %{
          "operation" => "upsert",
          "index" => "tenant_searchable_post",
          "documents" => [%{"id" => 1, "data" => %{"title" => "One"}, "source" => "fields"}],
          "document_ids" => [1]
        }
      }
    ])

    Application.put_env(:scrypath, :operator_task_test_opts,
      meilisearch_tasks: Application.fetch_env!(:scrypath, :operator_task_test_meilisearch_tasks),
      oban_inspector: TaskObanInspector,
      oban_jobs: Application.fetch_env!(:scrypath, :operator_task_test_oban_jobs)
    )

    report_output =
      capture_io(fn ->
        Mix.Task.reenable("scrypath.reconcile")

        Mix.Task.run("scrypath.reconcile", [
          "SearchablePost",
          "--target-index",
          "tenant_searchable_post__reindex"
        ])
      end)

    assert report_output =~
             "Drift signals: pending_queue_work, failed_sync_work, reindex_visibility_available, reindex_in_progress"

    assert report_output =~ "Failed work by class:"
    assert report_output =~ "Recommended actions: retry(ids=1001), reindex"
    refute_received {:oban_insert, _job}

    action_output =
      capture_io(fn ->
        Mix.Task.reenable("scrypath.reconcile")

        Mix.Task.run("scrypath.reconcile", [
          "SearchablePost",
          "--target-index",
          "tenant_searchable_post__reindex",
          "--action",
          "retry",
          "--id",
          "1001"
        ])
      end)

    assert action_output =~ "Applied action: retry"
    assert action_output =~ "Status: accepted"
    assert action_output =~ "Mode: oban"

    assert_received {:oban_insert, job}
    assert job.worker == "Scrypath.Oban.UpsertWorker"
  end

  defp put_env_or_delete(key, nil), do: Application.delete_env(:scrypath, key)
  defp put_env_or_delete(key, value), do: Application.put_env(:scrypath, key, value)
end
