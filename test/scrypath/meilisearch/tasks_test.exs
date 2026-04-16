defmodule Scrypath.Meilisearch.TasksTest do
  use ExUnit.Case, async: true

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

    assert {:ok, %{uid: 101, status: :succeeded, index_uid: "tenant_posts", raw: raw}} =
             Tasks.wait_for_task(
               %{uid: 101, status: "enqueued", type: "documentAdditionOrUpdate"},
               meilisearch_client: SequencedClient,
               task_responses: agent,
               inline_poll_interval: 1,
               inline_timeout: 50
             )

    assert raw["status"] == "succeeded"
    assert_received {:client_task, 101, _}
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

    assert {:error, {:task_failed, %{uid: 102, status: :failed, raw: raw}}} =
             Tasks.wait_for_task(
               %{uid: 102, status: "enqueued"},
               meilisearch_client: SequencedClient,
               task_responses: agent,
               inline_poll_interval: 1,
               inline_timeout: 50
             )

    assert raw["error"]["code"] == "index_not_found"
  end

  test "timeout while polling returns a distinct timeout error", %{task_responses: agent} do
    Agent.update(agent, fn _ ->
      List.duplicate({:ok, %{"uid" => 103, "status" => "processing"}}, 6)
    end)

    assert {:error, {:timeout, %{uid: 103, status: :processing, raw: raw}}} =
             Tasks.wait_for_task(
               %{uid: 103, status: "enqueued"},
               meilisearch_client: SequencedClient,
               task_responses: agent,
               inline_poll_interval: 5,
               inline_timeout: 10
             )

    assert raw["status"] == "processing"
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

    assert {:error, {:cancelled, %{uid: 104, status: :cancelled, raw: raw}}} =
             Tasks.wait_for_task(
               %{uid: 104, status: "enqueued", type: "documentDeletion"},
               meilisearch_client: SequencedClient,
               task_responses: agent,
               inline_poll_interval: 1,
               inline_timeout: 50
             )

    assert raw["canceledBy"]["uid"] == 7
  end
end
