defmodule Scrypath.Meilisearch.TasksTest do
  use ExUnit.Case, async: true

  alias Scrypath.Operations.Task, as: OperationTask
  alias Scrypath.Meilisearch.Tasks

  defmodule SequencedClient do
    def task(task_uid, config) do
      agent = Keyword.fetch!(config, :task_responses)
      send(self(), {:client_task, task_uid, config})

      Agent.get_and_update(agent, fn
        [next | rest] -> {next, rest}
        [] -> {{:ok, %{"uid" => task_uid, "status" => "succeeded"}}, []}
      end)
    end

    def tasks(filters, config) do
      send(self(), {:client_tasks, filters, config})

      case Keyword.get(config, :task_pages) do
        nil -> {:ok, %{results: Keyword.get(config, :task_history, [])}}
        agent -> Agent.get_and_update(agent, fn [page | rest] -> {page, rest} end)
      end
    end
  end

  setup do
    {:ok, agent} = Agent.start_link(fn -> [] end)
    %{task_responses: agent}
  end

  test "accepted tasks poll to terminal success and preserve task metadata", %{
    task_responses: agent
  } do
    Agent.update(agent, fn _ ->
      [
        {:ok, %{"uid" => 101, "status" => "processing", "type" => "documentAdditionOrUpdate"}},
        {:ok,
         %{
           "uid" => 101,
           "status" => "succeeded",
           "type" => "documentAdditionOrUpdate",
           "indexUid" => "tenant_posts"
         }}
      ]
    end)

    assert {:ok, %OperationTask{id: 101, state: :succeeded, raw: raw} = task} =
             Tasks.wait_for_task(
               %{uid: 101, status: "enqueued", type: "documentAdditionOrUpdate"},
               meilisearch_client: SequencedClient,
               task_responses: agent,
               inline_poll_interval: 1,
               inline_timeout: 1_000
             )

    assert task.source == :meilisearch
    assert task.kind == :backend_task
    assert task.reference == %{task_uid: 101, index_uid: "tenant_posts"}
    assert task.metadata.type == "documentAdditionOrUpdate"
    assert raw["status"] == "succeeded"
    assert_received {:client_task, 101, _}
  end

  test "list_sync_tasks/2 filters history through seam-owned operation tasks" do
    task_history = [
      %{
        "uid" => 401,
        "status" => "enqueued",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "tenant_posts"
      },
      %{
        "uid" => 402,
        "status" => "failed",
        "type" => "documentDeletion",
        "indexUid" => "tenant_posts",
        "error" => %{"code" => "index_not_found"}
      }
    ]

    assert {:ok, [%OperationTask{} = first, %OperationTask{} = second]} =
             Tasks.list_sync_tasks("tenant_posts",
               meilisearch_client: SequencedClient,
               task_history: task_history
             )

    assert first.id == 401
    assert first.state == :enqueued
    assert first.reference.index_uid == "tenant_posts"
    assert second.id == 402
    assert second.state == :failed
    assert second.raw["error"]["code"] == "index_not_found"

    assert_received {:client_tasks, filters, _config}
    assert filters[:index_uids] == ["tenant_posts"]
    assert filters[:types] == ["documentAdditionOrUpdate", "documentDeletion"]
  end

  test "list_index_tasks/2 keeps reindex visibility on explicit Meilisearch task reads" do
    task_history = [
      %{
        "uid" => 501,
        "status" => "processing",
        "type" => "indexCreation",
        "indexUid" => "tenant_posts__reindex"
      },
      %{
        "uid" => 502,
        "status" => "succeeded",
        "type" => "settingsUpdate",
        "indexUid" => "tenant_posts__reindex"
      }
    ]

    assert {:ok, [%OperationTask{} = first, %OperationTask{} = second]} =
             Tasks.list_index_tasks("tenant_posts__reindex",
               meilisearch_client: SequencedClient,
               task_history: task_history
             )

    assert first.metadata.type == "indexCreation"
    assert second.metadata.type == "settingsUpdate"

    assert_received {:client_tasks, filters, _config}
    assert filters[:index_uids] == ["tenant_posts__reindex"]
    assert "indexSwap" in filters[:types]
  end

  test "task history paginates until the configured cap" do
    {:ok, pages} =
      Agent.start_link(fn ->
        [
          {:ok,
           %{
             "results" => [
               %{
                 "uid" => 601,
                 "status" => "failed",
                 "type" => "documentDeletion",
                 "indexUid" => "tenant_posts"
               }
             ],
             "next" => 600
           }},
          {:ok,
           %{
             "results" => [
               %{
                 "uid" => 600,
                 "status" => "succeeded",
                 "type" => "documentAdditionOrUpdate",
                 "indexUid" => "tenant_posts"
               }
             ],
             "next" => nil
           }}
        ]
      end)

    assert {:ok, [%OperationTask{id: 601}, %OperationTask{id: 600}]} =
             Tasks.list_sync_tasks("tenant_posts",
               meilisearch_client: SequencedClient,
               task_pages: pages,
               task_history_limit: 2
             )
  end

  test "task history signals truncation at the configured cap" do
    {:ok, pages} =
      Agent.start_link(fn ->
        [
          {:ok,
           %{
             "results" => [
               %{
                 "uid" => 701,
                 "status" => "failed",
                 "type" => "documentDeletion",
                 "indexUid" => "tenant_posts"
               }
             ],
             "next" => 700
           }}
        ]
      end)

    assert {:error,
            {:task_history_truncated, %{index_uid: "tenant_posts", limit: 1, observed: 1}}} =
             Tasks.list_sync_tasks("tenant_posts",
               meilisearch_client: SequencedClient,
               task_pages: pages,
               task_history_limit: 1
             )
  end

  test "backend task failure returns a distinct failure shape", %{task_responses: agent} do
    Agent.update(agent, fn _ ->
      [
        {:ok,
         %{
           "uid" => 102,
           "status" => "failed",
           "error" => %{"code" => "index_not_found", "message" => "missing index"}
         }}
      ]
    end)

    assert {:error, {:task_failed, %OperationTask{id: 102, state: :failed, raw: raw} = task}} =
             Tasks.wait_for_task(
               %{uid: 102, status: "enqueued"},
               meilisearch_client: SequencedClient,
               task_responses: agent,
               inline_poll_interval: 1,
               inline_timeout: 400
             )

    assert task.source == :meilisearch
    assert raw["error"]["code"] == "index_not_found"
  end

  test "malformed initial payload returns an explicit invalid-task error", %{
    task_responses: agent
  } do
    assert {:error,
            {:invalid_task_payload,
             %{
               stage: :initial,
               task_uid: nil,
               problems: [uid: :missing_or_invalid],
               payload: payload
             }}} =
             Tasks.wait_for_task(
               %{"status" => "enqueued"},
               meilisearch_client: SequencedClient,
               task_responses: agent,
               inline_poll_interval: 1,
               inline_timeout: 50
             )

    assert payload == %{"status" => "enqueued"}
    refute_received {:client_task, _, _}
  end

  test "unknown status in a polled payload returns an explicit invalid-task error", %{
    task_responses: agent
  } do
    Agent.update(agent, fn _ ->
      [
        {:ok, %{"uid" => 301, "status" => "weird"}}
      ]
    end)

    assert {:error,
            {:invalid_task_payload,
             %{stage: :poll, task_uid: 301, problems: [status: :unknown], payload: payload}}} =
             Tasks.wait_for_task(
               %{uid: 301, status: "enqueued"},
               meilisearch_client: SequencedClient,
               task_responses: agent,
               inline_poll_interval: 1,
               inline_timeout: 50
             )

    assert payload == %{"uid" => 301, "status" => "weird"}
  end

  test "missing uid on a polled terminal task stays invalid instead of surfacing terminal tuples",
       %{
         task_responses: agent
       } do
    Agent.update(agent, fn _ ->
      [
        {:ok, %{"uid" => nil, "status" => "failed"}}
      ]
    end)

    assert {:error,
            {:invalid_task_payload,
             %{
               stage: :poll,
               task_uid: nil,
               problems: [uid: :missing_or_invalid],
               payload: payload
             }}} =
             Tasks.wait_for_task(
               %{uid: 301, status: "enqueued"},
               meilisearch_client: SequencedClient,
               task_responses: agent,
               inline_poll_interval: 1,
               inline_timeout: 50
             )

    assert payload == %{"uid" => nil, "status" => "failed"}
  end

  test "timeout while polling returns a distinct timeout error", %{task_responses: agent} do
    Agent.update(agent, fn _ ->
      List.duplicate({:ok, %{"uid" => 103, "status" => "processing"}}, 6)
    end)

    assert {:error, {:timeout, %OperationTask{id: 103, state: status, raw: raw}}} =
             Tasks.wait_for_task(
               %{uid: 103, status: "enqueued"},
               meilisearch_client: SequencedClient,
               task_responses: agent,
               inline_poll_interval: 5,
               inline_timeout: 10
             )

    assert status in [:enqueued, :processing]
    assert (raw["status"] || raw[:status]) in ["enqueued", "processing"]
  end

  test "cancelled backend tasks return a distinct cancellation error", %{task_responses: agent} do
    Agent.update(agent, fn _ ->
      [
        {:ok,
         %{
           "uid" => 104,
           "status" => "canceled",
           "type" => "documentDeletion",
           "canceledBy" => %{"uid" => 7}
         }}
      ]
    end)

    assert {:error, {:cancelled, %OperationTask{id: 104, state: :cancelled, raw: raw} = task}} =
             Tasks.wait_for_task(
               %{uid: 104, status: "enqueued", type: "documentDeletion"},
               meilisearch_client: SequencedClient,
               task_responses: agent,
               inline_poll_interval: 1,
               inline_timeout: 50
             )

    assert task.metadata.type == "documentDeletion"
    assert raw["canceledBy"]["uid"] == 7
  end

  test "transport errors from polling propagate unchanged", %{task_responses: agent} do
    Agent.update(agent, fn _ ->
      [
        {:error, :econnrefused}
      ]
    end)

    assert {:error, :econnrefused} =
             Tasks.wait_for_task(
               %{uid: 105, status: "enqueued"},
               meilisearch_client: SequencedClient,
               task_responses: agent,
               inline_poll_interval: 1,
               inline_timeout: 50
             )
  end

  defmodule RecordingClient do
    def upsert_documents(index, documents, config) do
      send(self(), {:client_upsert, index, documents, config})

      {:ok,
       %{
         "taskUid" => 17,
         "indexUid" => index,
         "status" => "enqueued",
         "type" => "documentAdditionOrUpdate"
       }}
    end
  end

  test "Scrypath.Meilisearch keeps the public namespace while delegating writes through operations" do
    documents = [%Scrypath.Document{id: 1, data: %{title: "One"}, source: :fields}]

    assert {:ok,
            %{
              index: "tenant_searchable_post",
              document_ids: [1],
              task: %{uid: 17, status: :enqueued}
            }} =
             Scrypath.Meilisearch.upsert_documents(SearchablePost, documents,
               index_prefix: "tenant",
               meilisearch_client: RecordingClient
             )

    assert {:ok, %Scrypath.Operations.Result{} = result} =
             Scrypath.Meilisearch.Operations.upsert_documents(SearchablePost, documents,
               index_prefix: "tenant",
               meilisearch_client: RecordingClient
             )

    assert %OperationTask{id: 17, state: :enqueued} = result.task
    assert_received {:client_upsert, "tenant_searchable_post", ^documents, _}
  end
end
