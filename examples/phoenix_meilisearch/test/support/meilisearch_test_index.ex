defmodule ScrypathDemo.MeilisearchTestIndex do
  @moduledoc false

  alias Scrypath.Meilisearch.Client
  alias Scrypath.Meilisearch.Tasks

  def create!(index_uid, url) when is_binary(index_uid) and is_binary(url) do
    config = [meilisearch_url: url, inline_poll_interval: 50, inline_timeout: 10_000]

    {:ok, response} = Client.create_index(index_uid, "id", config)
    task_uid = Map.fetch!(response, "taskUid")

    {:ok, task} = Tasks.wait_for_task(%{"uid" => task_uid, "status" => "enqueued"}, config)

    unless task.state == :succeeded and task.reference.index_uid == index_uid do
      raise "Meilisearch test index creation task did not succeed for #{index_uid}"
    end

    task
  end
end
