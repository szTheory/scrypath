defmodule ScrypathOps.Test.Phase175FixtureSource do
  @moduledoc false

  alias ScrypathOps.Test.OpsPostA
  alias ScrypathOps.Test.OpsPostB

  @scenarios ["accepted-processing"]

  def scenarios, do: @scenarios
  def state_name, do: __MODULE__.State

  def initial_state do
    %{task_calls: [], swap_post_count: 1, scenario: "accepted-processing", task_delay_ms: 0}
  end

  def scenario(name) when name in @scenarios do
    {:ok,
     %{
       name: name,
       allowlist: allowlist(name),
       opts: opts(name),
       task_uid: 17_501,
       indexes: indexes(OpsPostB)
     }}
  end

  def scenario(_name), do: {:error, :unknown_scenario}

  def allowlist(name) when name in @scenarios do
    if name == "removed-schema", do: [OpsPostA], else: [OpsPostA, OpsPostB]
  end

  def allowlist(_name), do: []

  def opts(name) when name in @scenarios do
    [
      backend: Scrypath.Meilisearch,
      repo: ScrypathOps.Repo,
      sync_mode: :manual,
      index_prefix: "phase175_",
      meilisearch_url: "http://phase175.fixture.invalid",
      meilisearch_client: __MODULE__,
      meilisearch_tasks: [],
      oban: nil,
      oban_queue: nil,
      oban_inspector: __MODULE__,
      oban_jobs: []
    ]
  end

  def opts(_name), do: opts("accepted-processing")

  def indexes(schema) do
    live = Scrypath.Meilisearch.index_name(schema, index_prefix: "phase175_")
    {live, live <> "__reindex"}
  end

  def tasks(filters, _opts) do
    index_uids = Keyword.get(filters, :index_uids, [])

    {:ok,
     %{results: [], next: nil, phase175_requested_indexes: index_uids}}
  end

  def list_jobs(_schema, _opts), do: {:ok, []}
  def get_settings(_index, _opts), do: {:ok, %{"searchableAttributes" => ["*"]}}

  def task(uid, _opts) do
    Agent.update(state_name(), fn state ->
      Map.update!(state, :task_calls, &[uid | &1])
    end)

    state = Agent.get(state_name(), & &1)
    if state.task_delay_ms > 0, do: Process.sleep(state.task_delay_ms)

    response = Map.get(state, :task_response, response_for(state.scenario))

    case Map.get(state, :task_error) do
      nil -> {:ok, response}
      reason -> {:error, reason}
    end
  end

  def swap_indexes(_indexes, _opts) do
    Agent.update(state_name(), &Map.update!(&1, :swap_post_count, fn count -> count + 1 end))
    {:ok, %{"uid" => 17_501, "status" => "enqueued"}}
  end

  defp response_for("accepted-processing"), do: %{"uid" => 17_501, "status" => "processing"}
end
