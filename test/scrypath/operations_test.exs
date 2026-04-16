defmodule Scrypath.OperationsTest do
  use ExUnit.Case, async: true

  alias Scrypath.Operations
  alias Scrypath.Operations.Result
  alias Scrypath.Operations.Task

  test "normalizes meilisearch task payloads into a seam-owned task struct" do
    payload = %{
      uid: 301,
      status: :enqueued,
      index_uid: "tenant_posts",
      type: "documentAdditionOrUpdate",
      raw: %{"uid" => 301, "status" => "enqueued"}
    }

    assert %Task{} = task = Operations.task_from_backend(payload, source: :meilisearch)
    assert task.source == :meilisearch
    assert task.kind == :backend_task
    assert task.id == 301
    assert task.state == :enqueued
    assert task.reference == %{task_uid: 301, index_uid: "tenant_posts"}
    assert task.metadata.type == "documentAdditionOrUpdate"
    assert task.raw == payload.raw
  end

  test "normalizes canceled atom states to the canonical cancelled task state" do
    assert %Task{state: :cancelled} =
             Operations.task_from_backend(%{uid: 302, status: :canceled}, source: :meilisearch)
  end

  test "normalizes oban enqueue metadata without collapsing queue state into lifecycle state" do
    payload = %{
      job: %{
        id: 901,
        state: "available",
        worker: "Scrypath.Oban.UpsertWorker",
        queue: "search_sync"
      },
      document_ids: [11, 12],
      document_count: 2
    }

    assert %Result{} = result = Operations.result_from_enqueue(payload, mode: :oban)
    assert result.mode == :oban
    assert result.status == :accepted
    assert result.document_ids == [11, 12]
    assert result.document_count == 2
    assert %Task{} = task = result.task
    assert task.source == :oban
    assert task.kind == :queue_job
    assert task.id == 901
    assert task.state == :queued

    assert task.reference == %{
             job_id: 901,
             worker: "Scrypath.Oban.UpsertWorker",
             queue: "search_sync"
           }

    assert task.metadata.oban_state == "available"
  end

  test "normalizes retryable queue jobs into retrying operator state" do
    payload = %{
      job: %{
        id: 902,
        state: "retryable",
        worker: "Scrypath.Oban.UpsertWorker",
        queue: "search_sync"
      },
      document_ids: [13],
      document_count: 1
    }

    assert %Result{task: %Task{} = task} = Operations.result_from_enqueue(payload, mode: :oban)
    assert task.state == :retrying
    assert task.metadata.oban_state == "retryable"
  end

  test "result structs adapt back into the current public sync fields" do
    result =
      Result.new(
        mode: :manual,
        status: :accepted,
        document_ids: ["post:7"],
        document_count: 1,
        task:
          Task.new(
            source: :meilisearch,
            kind: :backend_task,
            id: 88,
            state: :enqueued,
            reference: %{task_uid: 88},
            metadata: %{type: "documentDeletion"}
          )
      )

    assert %{
             mode: :manual,
             status: :accepted,
             document_ids: ["post:7"],
             document_count: 1,
             task: %{uid: 88, status: :enqueued}
           } = Result.to_public_sync(result)

    refute Map.has_key?(Result.to_public_sync(result), :job)
  end
end
