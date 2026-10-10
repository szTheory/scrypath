defmodule ScrypathOps.Test.Phase175FixtureSource do
  @moduledoc false

  alias ScrypathOps.Test.OpsPostA
  alias ScrypathOps.Test.OpsPostB

  @scenarios ~w(
    accepted-processing accepted-queued accepted-succeeded accepted-failed
    accepted-cancelled accepted-wrong-uid accepted-malformed accepted-timeout
    accepted-slow-processing auth-return-ready sync-error queue-error config-mismatch config-error
    promotion-blocked removed-schema retry-active retry-expired
  )

  def scenarios, do: @scenarios
  def state_name, do: __MODULE__.State

  def initial_state do
    %{
      task_calls: [],
      tasks_calls: 0,
      settings_calls: 0,
      jobs_calls: 0,
      swap_post_count: 1,
      scenario: "accepted-processing",
      task_delay_ms: 0
    }
  end

  def scenario(name) when name in @scenarios do
    if Process.whereis(state_name()),
      do: Agent.update(state_name(), &Map.put(&1, :scenario, name))

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

  def allowlist("removed-schema"), do: [OpsPostA]
  def allowlist(name) when name in @scenarios, do: [OpsPostA, OpsPostB]
  def allowlist(_name), do: []

  def opts(name) when name in @scenarios do
    [
      backend: Scrypath.Meilisearch,
      repo: ScrypathOps.Repo,
      sync_mode: :oban,
      index_prefix: "phase175_",
      meilisearch_url: "http://phase175.fixture.invalid",
      meilisearch_client: __MODULE__,
      meilisearch_tasks: [],
      oban: nil,
      oban_queue: :scrypath_sync,
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
    Agent.update(state_name(), &Map.update!(&1, :tasks_calls, fn count -> count + 1 end))
    state = Agent.get(state_name(), & &1)
    index_uids = Keyword.get(filters, :index_uids, [])

    case state.scenario do
      "sync-error" ->
        {:error, :fixture_backend_unavailable}

      "promotion-blocked" ->
        task = %{
          "uid" => 17_599,
          "status" => "enqueued",
          "type" => "documentAdditionOrUpdate",
          "indexUid" => indexes(OpsPostB) |> elem(0)
        }

        {:ok, %{results: if(task["indexUid"] in index_uids, do: [task], else: []), next: nil}}

      "auth-return-ready" ->
        target_index = indexes(OpsPostB) |> elem(1)

        task = %{
          "uid" => 17_500,
          "status" => "succeeded",
          "type" => "documentAdditionOrUpdate",
          "indexUid" => target_index
        }

        {:ok, %{results: if(target_index in index_uids, do: [task], else: []), next: nil}}

      _ ->
        {:ok, %{results: [], next: nil}}
    end
  end

  def list_jobs(_schema, _opts) do
    Agent.update(state_name(), &Map.update!(&1, :jobs_calls, fn count -> count + 1 end))

    if Agent.get(state_name(), & &1.scenario) == "queue-error",
      do: {:error, :fixture_queue_unavailable},
      else: {:ok, []}
  end

  def get_settings(_index, _opts) do
    Agent.update(state_name(), &Map.update!(&1, :settings_calls, fn count -> count + 1 end))

    case Agent.get(state_name(), & &1.scenario) do
      "config-error" ->
        {:error, :fixture_settings_unavailable}

      "config-mismatch" ->
        {:ok,
         %{
           "searchableAttributes" => ["*"],
           "filterableAttributes" => ["category"],
           "sortableAttributes" => []
         }}

      _ ->
        {:ok,
         %{
           "searchableAttributes" => ["*"],
           "filterableAttributes" => [],
           "sortableAttributes" => []
         }}
    end
  end

  def task(uid, _opts) do
    Agent.update(state_name(), fn state -> Map.update!(state, :task_calls, &[uid | &1]) end)
    state = Agent.get(state_name(), & &1)

    delay = if state.scenario == "accepted-slow-processing", do: 250, else: state.task_delay_ms
    if delay > 0, do: Process.sleep(delay)

    case state.scenario do
      "accepted-timeout" -> {:error, :fixture_timeout}
      _ -> {:ok, response_for(state.scenario)}
    end
  end

  def swap_indexes(_indexes, _opts) do
    Agent.update(state_name(), &Map.update!(&1, :swap_post_count, fn count -> count + 1 end))
    {:ok, %{"uid" => 17_501, "status" => "enqueued"}}
  end

  defp response_for("accepted-processing"), do: %{"uid" => 17_501, "status" => "processing"}
  defp response_for("accepted-slow-processing"), do: %{"uid" => 17_501, "status" => "processing"}
  defp response_for("accepted-queued"), do: %{"uid" => 17_501, "status" => "enqueued"}
  defp response_for("accepted-succeeded"), do: %{"uid" => 17_501, "status" => "succeeded"}
  defp response_for("accepted-failed"), do: %{"uid" => 17_501, "status" => "failed"}
  defp response_for("accepted-cancelled"), do: %{"uid" => 17_501, "status" => "canceled"}
  defp response_for("accepted-wrong-uid"), do: %{"uid" => 17_502, "status" => "succeeded"}
  defp response_for("accepted-malformed"), do: %{"status" => "processing"}

  defp response_for(_scenario), do: nil
end
