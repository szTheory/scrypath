defmodule Scrypath.Operator.FailedWorkTest do
  use ExUnit.Case, async: true

  alias Scrypath.Operator.FailedWork
  alias Scrypath.Operator.RecoveryAction

  defmodule FailedWorkMeilisearchClient do
    def tasks(_filters, config) do
      {:ok, %{results: Keyword.get(config, :meilisearch_tasks, [])}}
    end
  end

  defmodule FailedWorkObanInspector do
    def list_jobs(_schema_module, config) do
      {:ok, Keyword.get(config, :oban_jobs, [])}
    end
  end

  defmodule RecordingOban do
    def insert(changeset) do
      job = Ecto.Changeset.apply_changes(changeset)
      send(self(), {:oban_insert, job})
      {:ok, %{job | id: 991, state: "available"}}
    end
  end

  test "failed_sync_work/2 returns Scrypath-owned entries for backend and queue failures" do
    assert {:ok, failed_work} =
             Scrypath.failed_sync_work(SearchablePost,
               backend: Scrypath.Meilisearch,
               sync_mode: :oban,
               index_prefix: "tenant",
               meilisearch_url: "http://localhost:7700",
               meilisearch_client: FailedWorkMeilisearchClient,
               meilisearch_tasks: [
                 %{
                   "uid" => 401,
                   "status" => "failed",
                   "type" => "documentAdditionOrUpdate",
                   "indexUid" => "tenant_searchable_post",
                   "error" => %{"message" => "index missing"}
                 }
               ],
               oban: RecordingOban,
               oban_queue: :search_sync,
               oban_inspector: FailedWorkObanInspector,
               oban_jobs: [
                 %{
                   id: 501,
                   state: "retryable",
                   worker: "Scrypath.Oban.UpsertWorker",
                   queue: "search_sync",
                   args: %{
                     "operation" => "upsert",
                     "schema" => "Elixir.SearchablePost",
                     "backend" => "Elixir.Scrypath.Meilisearch",
                     "index" => "tenant_searchable_post",
                     "document_count" => 1,
                     "document_ids" => [1],
                     "documents" => [%{"id" => 1, "data" => %{"title" => "One"}, "source" => "fields"}]
                   }
                 },
                 %{
                   id: 502,
                   state: "discarded",
                   worker: "Scrypath.Oban.DeleteWorker",
                   queue: "search_sync",
                   args: %{
                     "operation" => "delete",
                     "schema" => "Elixir.SearchablePost",
                     "backend" => "Elixir.Scrypath.Meilisearch",
                     "index" => "tenant_searchable_post",
                     "document_count" => 1,
                     "document_ids" => ["post:7"]
                   }
                 }
               ]
             )

    assert [%FailedWork{} = backend_failure, %FailedWork{} = retryable_job, %FailedWork{} = discarded_job] =
             failed_work

    assert backend_failure.source == :meilisearch
    assert backend_failure.operation == :upsert
    assert backend_failure.state == :failed
    assert backend_failure.retryable? == false
    assert backend_failure.reason == "index missing"
    refute Map.has_key?(backend_failure.metadata, :raw)

    assert retryable_job.source == :oban
    assert retryable_job.state == :retrying
    assert retryable_job.retryable? == true
    assert %RecoveryAction{} = retryable_job.recovery

    assert discarded_job.source == :oban
    assert discarded_job.state == :failed
    assert discarded_job.retryable? == true
    assert %RecoveryAction{} = discarded_job.recovery
  end

  test "retry_sync_work/2 replays retryable Oban work through enqueue helpers" do
    [retryable_job] =
      Scrypath.failed_sync_work(SearchablePost,
        backend: Scrypath.Meilisearch,
        sync_mode: :oban,
        index_prefix: "tenant",
        meilisearch_url: "http://localhost:7700",
        meilisearch_client: FailedWorkMeilisearchClient,
        meilisearch_tasks: [],
        oban: RecordingOban,
        oban_queue: :search_sync,
        oban_inspector: FailedWorkObanInspector,
        oban_jobs: [
          %{
            id: 601,
            state: "retryable",
            worker: "Scrypath.Oban.UpsertWorker",
            queue: "search_sync",
            args: %{
              "operation" => "upsert",
              "schema" => "Elixir.SearchablePost",
              "backend" => "Elixir.Scrypath.Meilisearch",
              "index" => "tenant_searchable_post",
              "document_count" => 1,
              "document_ids" => [9],
              "documents" => [%{"id" => 9, "data" => %{"title" => "Replay"}, "source" => "fields"}]
            }
          }
        ]
      )
      |> elem(1)

    assert {:ok, result} =
             Scrypath.retry_sync_work(retryable_job,
               backend: Scrypath.Meilisearch,
               sync_mode: :oban,
               index_prefix: "tenant",
               oban: RecordingOban,
               oban_queue: :search_sync
             )

    assert result.mode == :oban
    assert result.status == :accepted

    assert_received {:oban_insert, job}
    assert job.worker == "Scrypath.Oban.UpsertWorker"
    assert job.args["document_ids"] == [9]
    assert Enum.map(job.args["documents"], & &1["id"]) == [9]
  end

  test "retry_sync_work/2 rejects non-retryable failed work" do
    assert {:error, :not_retryable} =
             Scrypath.retry_sync_work(
               %FailedWork{
                 id: 701,
                 schema: SearchablePost,
                 mode: :manual,
                 source: :meilisearch,
                 operation: :upsert,
                 state: :failed,
                 retryable?: false
               },
               []
             )
  end

  test "retry_sync_work/2 rejects mismatched recovery references" do
    action =
      RecoveryAction.new(
        schema: SearchablePost,
        backend: Scrypath.Meilisearch,
        mode: :oban,
        operation: :delete,
        index: "tenant_searchable_post",
        reference: %{
          queue: "search_sync",
          payload: %{
            "operation" => "delete",
            "document_count" => 1,
            "document_ids" => ["post:7"]
          }
        }
      )

    assert {:error, :index_mismatch} =
             Scrypath.retry_sync_work(action,
               backend: Scrypath.Meilisearch,
               sync_mode: :oban,
               index_prefix: "wrong",
               oban: RecordingOban,
               oban_queue: :search_sync
             )
  end
end
