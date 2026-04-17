defmodule Scrypath.Operator.FailedWorkTest do
  use ExUnit.Case, async: false

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

  def fw_observed_handler(_event, measurements, metadata, parent) do
    send(parent, {:failed_work_observed, measurements, metadata})
  end

  test "failed_sync_work/2 returns Scrypath-owned entries for backend and queue failures" do
    parent = self()
    handler_id = "failed-work-telemetry-#{System.unique_integer([:positive])}"

    :telemetry.attach(
      handler_id,
      [:scrypath, :operator, :failed_work, :observed],
      &__MODULE__.fw_observed_handler/4,
      parent
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

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
                     "documents" => [
                       %{"id" => 1, "data" => %{"title" => "One"}, "source" => "fields"}
                     ]
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

    assert [
             %FailedWork{} = backend_failure,
             %FailedWork{} = retryable_job,
             %FailedWork{} = discarded_job
           ] =
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

    for _ <- 1..3 do
      assert_receive {:failed_work_observed, %{count: 1}, meta}

      assert meta.reason_class in [
               :validation,
               :backend_rejected,
               :transport,
               :queue_exhausted,
               :unknown
             ]

      assert meta.schema == SearchablePost
      assert meta.mode in [:inline, :oban, :manual]
      assert Map.has_key?(meta, :operation)
      assert Map.has_key?(meta, :retryable?)
    end

    refute_receive {:failed_work_observed, _, _}
  end

  test "backend rows keep attempt fields nil and classify Meilisearch error.type" do
    assert {:ok, [%FailedWork{} = row]} =
             Scrypath.failed_sync_work(SearchablePost,
               backend: Scrypath.Meilisearch,
               sync_mode: :inline,
               index_prefix: "tenant",
               meilisearch_url: "http://localhost:7700",
               meilisearch_client: FailedWorkMeilisearchClient,
               meilisearch_tasks: [
                 %{
                   "uid" => 801,
                   "status" => "failed",
                   "type" => "documentAdditionOrUpdate",
                   "indexUid" => "tenant_searchable_post",
                   "error" => %{
                     "type" => "invalid_request",
                     "code" => "invalid_document_id",
                     "message" => "bad id"
                   }
                 }
               ]
             )

    assert row.reason_class == :validation
    assert row.attempt == nil
    assert row.max_attempts == nil
    assert row.last_attempt_at == row.failed_at
  end

  test "internal and auth backend errors map to backend_rejected and transport" do
    assert {:ok, [%FailedWork{reason_class: :backend_rejected}]} =
             Scrypath.failed_sync_work(SearchablePost,
               backend: Scrypath.Meilisearch,
               sync_mode: :inline,
               index_prefix: "tenant",
               meilisearch_url: "http://localhost:7700",
               meilisearch_client: FailedWorkMeilisearchClient,
               meilisearch_tasks: [
                 %{
                   "uid" => 802,
                   "status" => "failed",
                   "type" => "documentDeletion",
                   "indexUid" => "tenant_searchable_post",
                   "error" => %{"type" => "internal", "message" => "disk"}
                 }
               ]
             )

    assert {:ok, [%FailedWork{reason_class: :transport}]} =
             Scrypath.failed_sync_work(SearchablePost,
               backend: Scrypath.Meilisearch,
               sync_mode: :inline,
               index_prefix: "tenant",
               meilisearch_url: "http://localhost:7700",
               meilisearch_client: FailedWorkMeilisearchClient,
               meilisearch_tasks: [
                 %{
                   "uid" => 803,
                   "status" => "failed",
                   "type" => "documentDeletion",
                   "indexUid" => "tenant_searchable_post",
                   "error" => %{"type" => "auth", "message" => "nope"}
                 }
               ]
             )
  end

  test "backend error without type classifies as unknown" do
    assert {:ok, [%FailedWork{reason_class: :unknown}]} =
             Scrypath.failed_sync_work(SearchablePost,
               backend: Scrypath.Meilisearch,
               sync_mode: :inline,
               index_prefix: "tenant",
               meilisearch_url: "http://localhost:7700",
               meilisearch_client: FailedWorkMeilisearchClient,
               meilisearch_tasks: [
                 %{
                   "uid" => 804,
                   "status" => "failed",
                   "type" => "documentAdditionOrUpdate",
                   "indexUid" => "tenant_searchable_post",
                   "error" => %{"message" => "no type field"}
                 }
               ]
             )
  end

  test "discarded Oban job without classifiable error is queue_exhausted" do
    assert {:ok, [%FailedWork{reason_class: :queue_exhausted} = row]} =
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
                   id: 901,
                   state: "discarded",
                   worker: "Scrypath.Oban.DeleteWorker",
                   queue: "search_sync",
                   args: %{
                     "operation" => "delete",
                     "schema" => "Elixir.SearchablePost",
                     "backend" => "Elixir.Scrypath.Meilisearch",
                     "index" => "tenant_searchable_post",
                     "document_count" => 1,
                     "document_ids" => ["post:1"]
                   }
                 }
               ]
             )

    assert row.attempt == nil
    assert row.max_attempts == nil
  end

  test "discarded job with validation-shaped error prefers validation over queue_exhausted" do
    assert {:ok, [%FailedWork{reason_class: :validation}]} =
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
                   id: 902,
                   state: "discarded",
                   worker: "Scrypath.Oban.UpsertWorker",
                   queue: "search_sync",
                   errors: ["** (Ecto.CastError) cast failed"],
                   args: %{
                     "operation" => "upsert",
                     "schema" => "Elixir.SearchablePost",
                     "backend" => "Elixir.Scrypath.Meilisearch",
                     "index" => "tenant_searchable_post",
                     "document_count" => 1,
                     "document_ids" => [1],
                     "documents" => [
                       %{"id" => 1, "data" => %{"title" => "One"}, "source" => "fields"}
                     ]
                   }
                 }
               ]
             )
  end

  test "Oban rows populate attempt and max_attempts when present" do
    assert {:ok, [%FailedWork{} = row]} =
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
                   id: 903,
                   state: "retryable",
                   attempt: 3,
                   max_attempts: 20,
                   worker: "Scrypath.Oban.UpsertWorker",
                   queue: "search_sync",
                   args: %{
                     "operation" => "upsert",
                     "schema" => "Elixir.SearchablePost",
                     "backend" => "Elixir.Scrypath.Meilisearch",
                     "index" => "tenant_searchable_post",
                     "document_count" => 1,
                     "document_ids" => [1],
                     "documents" => [
                       %{"id" => 1, "data" => %{"title" => "One"}, "source" => "fields"}
                     ]
                   }
                 }
               ]
             )

    assert row.attempt == 3
    assert row.max_attempts == 20
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
              "documents" => [
                %{"id" => 9, "data" => %{"title" => "Replay"}, "source" => "fields"}
              ]
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
