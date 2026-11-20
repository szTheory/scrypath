defmodule ScrypathOps.Test.CopyStubs.Posture do
  @moduledoc false
  # One definition of the Search health stub client, its Agent state and the environment
  # `PostureLiveTest` runs in. The copy rules surfaces use it too, so the fixture is never copied.

  @state :posture_live_test_state

  @env_keys ~w(
    schema_allowlist backend sync_mode index_prefix meilisearch_url meilisearch_client
    meilisearch_tasks oban oban_queue oban_inspector oban_jobs sigra
  )a

  defmodule FakeClient do
    @moduledoc false

    @state :posture_live_test_state

    def tasks(filters, config) do
      Agent.update(@state, fn state ->
        Map.update!(state, :tasks_calls, &(&1 + 1))
      end)

      uids = filters[:index_uids] || []
      boom_indexes = Agent.get(@state, & &1.boom_indexes)
      boom_reason = Agent.get(@state, & &1.boom_reason)
      exit_index = Agent.get(@state, & &1.exit_index)

      cond do
        exit_index in uids -> exit(:posture_backend_exit)
        Enum.any?(boom_indexes, &(&1 in uids)) -> {:error, boom_reason}
        true -> {:ok, %{results: Keyword.get(config, :meilisearch_tasks, [])}}
      end
    end

    def swap_indexes(_indexes, _config) do
      Agent.update(@state, fn state ->
        Map.put(state, :swap_called, true)
      end)

      {:ok,
       %{
         "uid" => 101,
         "status" => "succeeded",
         "type" => "indexSwap",
         "indexUid" => "postlv_ops_post_a"
       }}
    end
  end

  @doc "Registered name of the stub's Agent state."
  def state_name, do: @state

  @doc """
  Puts the allowlist, Meilisearch and sigra environment the Search health tests use and returns
  the previous values for `restore_env/1`.
  """
  def put_env do
    previous = {
      Map.new(@env_keys, &{&1, Application.get_env(:scrypath_ops, &1)}),
      System.get_env("OPSUI_AUTH_MODE")
    }

    Application.put_env(:scrypath_ops, :schema_allowlist, [
      ScrypathOps.Test.OpsPostA,
      ScrypathOps.Test.OpsPostB
    ])

    Application.put_env(:scrypath_ops, :backend, Scrypath.Meilisearch)
    Application.put_env(:scrypath_ops, :sync_mode, :manual)
    Application.put_env(:scrypath_ops, :index_prefix, "postlv")
    Application.put_env(:scrypath_ops, :meilisearch_url, "http://localhost:7700")
    Application.put_env(:scrypath_ops, :meilisearch_client, FakeClient)

    Application.put_env(:scrypath_ops, :sigra,
      sudo_confirm_path: "/sudo/confirm",
      sudo_window: 300
    )

    System.put_env("OPSUI_AUTH_MODE", "sigra")

    Application.put_env(:scrypath_ops, :meilisearch_tasks, [
      %{
        "uid" => 1,
        "status" => "succeeded",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "postlv_ops_post_b",
        "finishedAt" => "2026-04-16T18:00:00Z"
      }
    ])

    previous
  end

  @doc "Restores the environment captured by `put_env/0`."
  def restore_env({previous, previous_auth_mode}) do
    Enum.each(previous, fn
      {k, nil} -> Application.delete_env(:scrypath_ops, k)
      {k, v} -> Application.put_env(:scrypath_ops, k, v)
    end)

    if is_nil(previous_auth_mode),
      do: System.delete_env("OPSUI_AUTH_MODE"),
      else: System.put_env("OPSUI_AUTH_MODE", previous_auth_mode)
  end

  @doc """
  Starts the stub's Agent, replacing a stale one. It is not linked to the caller, so it stays
  alive until `stop_agent/0` performs deterministic cleanup (a linked Agent can exit with the
  test process before an `on_exit` callback runs).
  """
  def start_agent do
    stop_agent()

    {:ok, pid} =
      Agent.start(
        fn ->
          %{
            tasks_calls: 0,
            swap_called: false,
            exit_index: nil,
            boom_indexes: ["postlv_ops_post_a"],
            boom_reason: :boom
          }
        end,
        name: @state
      )

    pid
  end

  @doc "Stops the stub's Agent if it is running."
  def stop_agent do
    if pid = Process.whereis(@state) do
      Agent.stop(pid)
    end

    :ok
  end

  @doc """
  Runs `fun` with the environment and Agent state in place, then restores the environment and
  stops the Agent, even if `fun` raises. For renderers outside a test's own setup.
  """
  def with_stubs(fun) when is_function(fun, 0) do
    previous = put_env()
    start_agent()

    try do
      fun.()
    after
      restore_env(previous)
      stop_agent()
    end
  end
end
