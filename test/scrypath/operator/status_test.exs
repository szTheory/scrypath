defmodule Scrypath.Operator.StatusTest do
  use ExUnit.Case, async: true

  alias Scrypath.Operator.State
  alias Scrypath.Operator.Status

  defmodule StatusMeilisearchClient do
    def tasks(filters, config) do
      send(self(), {:meilisearch_tasks, filters, config})
      {:ok, %{results: Keyword.get(config, :meilisearch_tasks, [])}}
    end
  end

  defmodule StatusObanInspector do
    def list_jobs(schema_module, config) do
      send(self(), {:oban_jobs, schema_module, config})
      {:ok, Keyword.get(config, :oban_jobs, [])}
    end
  end

  test "Scrypath.sync_status/2 returns a Scrypath-owned status struct without raw backend or queue payloads" do
    assert {:ok, %Status{} = status} =
             Scrypath.sync_status(SearchablePost,
               backend: Scrypath.Meilisearch,
               sync_mode: :manual,
               index_prefix: "tenant",
               meilisearch_url: "http://localhost:7700",
               meilisearch_client: StatusMeilisearchClient,
               meilisearch_tasks: [
                 %{
                   "uid" => 101,
                   "status" => "enqueued",
                   "type" => "documentAdditionOrUpdate",
                   "indexUid" => "tenant_searchable_post"
                 },
                 %{
                   "uid" => 102,
                   "status" => "failed",
                   "type" => "documentDeletion",
                   "indexUid" => "tenant_searchable_post",
                   "error" => %{"code" => "index_not_found"}
                 },
                 %{
                   "uid" => 103,
                   "status" => "succeeded",
                   "type" => "documentAdditionOrUpdate",
                   "indexUid" => "tenant_searchable_post",
                   "finishedAt" => "2026-04-16T18:00:00Z"
                 }
               ]
             )

    assert status.schema == SearchablePost
    assert status.mode == :manual
    assert status.index == "tenant_searchable_post"
    assert [%State{id: 101, state: :pending, source: :meilisearch}] = status.backend.pending
    assert [%State{id: 102, state: :failed, source: :meilisearch}] = status.backend.failed
    assert %State{id: 103, state: :completed, source: :meilisearch} = status.backend.last_succeeded
    assert status.queue.observed? == false
    assert status.queue.pending == []
    assert status.queue.retrying == []
    assert status.queue.failed == []
    assert status.queue.last_succeeded == nil

    refute Map.has_key?(Map.from_struct(hd(status.backend.pending)), :raw)
    refute Map.has_key?(Map.from_struct(status.backend.last_succeeded), :raw)

    assert_received {:meilisearch_tasks, filters, _config}
    assert filters[:index_uids] == ["tenant_searchable_post"]
  end

  test "oban mode reports queue state separately from backend state" do
    assert {:ok, %Status{} = status} =
             Scrypath.sync_status(SearchablePost,
               backend: Scrypath.Meilisearch,
               sync_mode: :oban,
               index_prefix: "tenant",
               meilisearch_url: "http://localhost:7700",
               meilisearch_client: StatusMeilisearchClient,
               meilisearch_tasks: [
                 %{
                   "uid" => 201,
                   "status" => "processing",
                   "type" => "documentAdditionOrUpdate",
                   "indexUid" => "tenant_searchable_post"
                 }
               ],
               oban: Scrypath.SyncTest.ReadyOban,
               oban_queue: :search_sync,
               oban_inspector: StatusObanInspector,
               oban_jobs: [
                 %{
                   id: 301,
                   state: "available",
                   worker: "Scrypath.Oban.UpsertWorker",
                   queue: "search_sync"
                 },
                 %{
                   id: 302,
                   state: "retryable",
                   worker: "Scrypath.Oban.UpsertWorker",
                   queue: "search_sync",
                   attempted_at: ~U[2026-04-16 18:10:00Z]
                 },
                 %{
                   id: 303,
                   state: "discarded",
                   worker: "Scrypath.Oban.DeleteWorker",
                   queue: "search_sync"
                 }
               ]
             )

    assert [%State{id: 201, state: :pending}] = status.backend.pending
    assert status.backend.failed == []
    assert status.backend.last_succeeded == nil

    assert status.queue.observed? == true
    assert [%State{id: 301, state: :queued, source: :oban}] = status.queue.pending
    assert [%State{id: 302, state: :retrying, source: :oban}] = status.queue.retrying
    assert [%State{id: 303, state: :failed, source: :oban}] = status.queue.failed
    assert status.queue.last_succeeded == nil

    assert_received {:oban_jobs, SearchablePost, _config}
  end

  test "last success stays nil when Scrypath cannot observe it for the chosen mode" do
    assert {:ok, %Status{} = status} =
             Scrypath.sync_status(SearchablePost,
               backend: Scrypath.Meilisearch,
               sync_mode: :inline,
               index_prefix: "tenant",
               meilisearch_url: "http://localhost:7700",
               meilisearch_client: StatusMeilisearchClient,
               meilisearch_tasks: []
             )

    assert status.backend.pending == []
    assert status.backend.failed == []
    assert status.backend.last_succeeded == nil
    assert status.queue.observed? == false
    assert status.queue.last_succeeded == nil
  end
end
