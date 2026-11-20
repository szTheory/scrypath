defmodule ScrypathOps.Test.CopyStubs.SyncDrift do
  @moduledoc false
  # One definition of the Sync and index stub client, its Oban inspector and the environment
  # and Agent state they need. `SyncDriftLiveTest` and the copy rules surfaces both use it, so
  # a fixture state is never copied between them.

  @state :sync_drift_live_test_state

  @env_keys ~w(
    schema_allowlist backend sync_mode index_prefix meilisearch_url meilisearch_client
    meilisearch_tasks oban oban_queue oban_inspector oban_jobs
  )a

  defmodule Client do
    @moduledoc false

    @state :sync_drift_live_test_state

    def tasks(filters, config) do
      Agent.update(@state, fn state ->
        Map.update!(state, :tasks_calls, &(&1 + 1))
      end)

      tasks =
        if Agent.get(@state, &Map.get(&1, :ready, false)) and
             Keyword.get(filters, :index_uids) == ["sdv_ops_post_a__reindex"] do
          [
            %{
              "uid" => 100,
              "status" => "succeeded",
              "type" => "indexCreation",
              "indexUid" => "sdv_ops_post_a__reindex"
            }
          ]
        else
          Keyword.get(config, :meilisearch_tasks, [])
        end

      {:ok, %{results: tasks}}
    end

    def get_settings(_index, _config) do
      Agent.update(@state, fn state ->
        Map.update!(state, :settings_calls, &(&1 + 1))
      end)

      if settings = Agent.get(@state, &Map.get(&1, :applied_settings)) do
        {:ok, settings}
      else
        if Agent.get(@state, &Map.get(&1, :ready, false)) do
          {:ok,
           %{
             "searchableAttributes" => ["*"],
             "filterableAttributes" => [],
             "sortableAttributes" => []
           }}
        else
          {:error, :settings}
        end
      end
    end

    def swap_indexes(_indexes, _config) do
      Agent.update(@state, fn state ->
        state
        |> Map.put(:swap_called, true)
        |> Map.update!(:swap_calls, &(&1 + 1))
      end)

      {:ok,
       %{
         "uid" => 201,
         "status" => "succeeded",
         "type" => "indexSwap",
         "indexUid" => "sdv_ops_post_b"
       }}
    end

    def task(uid, _config) do
      Agent.update(@state, fn state ->
        Map.update!(state, :task_calls, &[uid | &1])
      end)

      Agent.get(@state, fn state ->
        %{"uid" => uid, "status" => state.task_status, "type" => "indexSwap"}
      end)
      |> then(&{:ok, &1})
    end
  end

  defmodule ObanInspector do
    @moduledoc false

    def list_jobs(_schema_module, config) do
      {:ok, Keyword.get(config, :oban_jobs, [])}
    end
  end

  @doc "Registered name of the stub's Agent state."
  def state_name, do: @state

  @doc """
  Switches the stub environment to Oban background sync with the given jobs in the queue. An
  empty list is a queue that was observed and holds nothing. `restore_env/1` undoes it.
  """
  def put_oban_env(jobs \\ []) do
    Application.put_env(:scrypath_ops, :sync_mode, :oban)
    Application.put_env(:scrypath_ops, :oban, Oban)
    Application.put_env(:scrypath_ops, :oban_queue, :scrypath_sync)
    Application.put_env(:scrypath_ops, :oban_jobs, jobs)
  end

  @doc "One job waiting in the queue and one scheduled to retry."
  def pending_and_retrying_jobs do
    job = %{id: 1, state: "available", worker: "Scrypath.Oban.UpsertWorker", args: %{}}
    [job, %{job | id: 2, state: "retryable"}]
  end

  @doc """
  Puts the allowlist and Meilisearch environment the Sync and index tests use and returns the
  previous values for `restore_env/1`.
  """
  def put_env do
    previous = Map.new(@env_keys, &{&1, Application.get_env(:scrypath_ops, &1)})

    Application.put_env(:scrypath_ops, :schema_allowlist, [
      ScrypathOps.Test.OpsPostA,
      ScrypathOps.Test.OpsPostB
    ])

    Application.put_env(:scrypath_ops, :backend, Scrypath.Meilisearch)
    Application.put_env(:scrypath_ops, :sync_mode, :manual)
    Application.put_env(:scrypath_ops, :index_prefix, "sdv")
    Application.put_env(:scrypath_ops, :meilisearch_url, "http://localhost:7700")
    Application.put_env(:scrypath_ops, :meilisearch_client, Client)
    Application.put_env(:scrypath_ops, :meilisearch_tasks, [])
    Application.put_env(:scrypath_ops, :oban, nil)
    Application.put_env(:scrypath_ops, :oban_queue, nil)
    Application.put_env(:scrypath_ops, :oban_inspector, ObanInspector)
    Application.put_env(:scrypath_ops, :oban_jobs, [])

    previous
  end

  @doc "Restores the environment captured by `put_env/0`."
  def restore_env(previous) do
    Enum.each(previous, fn
      {k, nil} -> Application.delete_env(:scrypath_ops, k)
      {k, v} -> Application.put_env(:scrypath_ops, k, v)
    end)
  end

  @doc "Initial state of the stub's Agent: call counters and scripted values."
  def initial_state do
    %{
      tasks_calls: 0,
      settings_calls: 0,
      swap_called: false,
      swap_calls: 0,
      task_calls: [],
      task_status: "processing"
    }
  end

  @doc "Child spec for the Agent that holds the stub's call counters and scripted state."
  def agent_spec do
    %{
      id: @state,
      start: {Agent, :start_link, [&__MODULE__.initial_state/0, [name: @state]]}
    }
  end

  @doc """
  Runs `fun` with the environment and Agent state in place, then stops the Agent and restores
  the environment, even if `fun` raises. For renderers that are not inside a test's own setup.
  """
  def with_stubs(fun) when is_function(fun, 0) do
    previous = put_env()
    {:ok, agent} = Agent.start_link(&__MODULE__.initial_state/0, name: @state)

    try do
      fun.()
    after
      Agent.stop(agent)
      restore_env(previous)
    end
  end
end
