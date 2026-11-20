defmodule ScrypathOps.Test.CopyStubs.ControlRoom do
  @moduledoc false
  # One definition of the Control room environment (the `/ops` landing page). `ControlRoomLiveTest`
  # and the copy rules surfaces both use it, so a fixture state is never copied between them.

  @env_keys ~w(
    schema_allowlist backend sync_mode index_prefix meilisearch_url meilisearch_client
    meilisearch_tasks oban oban_queue oban_inspector oban_jobs control_room_client_state
  )a

  defmodule Client do
    @moduledoc false

    def tasks(filters, config) do
      case Application.get_env(:scrypath_ops, :control_room_client_state, :healthy) do
        :unavailable -> {:error, :backend_unavailable}
        :healthy -> healthy_tasks(filters, config)
      end
    end

    defp healthy_tasks(filters, config) do
      uids = filters[:index_uids] || []

      results =
        config
        |> Keyword.get(:meilisearch_tasks, [])
        |> Enum.filter(&(Map.get(&1, "indexUid") in uids))

      {:ok, %{results: results}}
    end
  end

  @doc """
  Starts from an empty allowlist and no backend, with the sigra auth mode the Control room tests
  use. Returns the previous values for `restore_env/1`.
  """
  def put_env do
    previous = Map.new(@env_keys, &{&1, Application.get_env(:scrypath_ops, &1)})
    previous_auth_mode = System.get_env("OPSUI_AUTH_MODE")

    Application.put_env(:scrypath_ops, :schema_allowlist, [])
    Application.delete_env(:scrypath_ops, :backend)
    System.put_env("OPSUI_AUTH_MODE", "sigra")

    {previous, previous_auth_mode}
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
  Two allowlisted schemas whose Meilisearch tasks all succeeded, so every row reads Clear. Call it
  inside `put_env/0`'s environment; the client is `Client`, switched by `:control_room_client_state`.
  """
  def put_healthy_posture! do
    Application.put_env(:scrypath_ops, :control_room_client_state, :healthy)

    Application.put_env(:scrypath_ops, :schema_allowlist, [
      ScrypathOps.Test.OpsPostA,
      ScrypathOps.Test.OpsPostB
    ])

    Application.put_env(:scrypath_ops, :backend, Scrypath.Meilisearch)
    Application.put_env(:scrypath_ops, :sync_mode, :manual)
    Application.put_env(:scrypath_ops, :index_prefix, "ctrl")
    Application.put_env(:scrypath_ops, :meilisearch_url, "http://localhost:7700")
    Application.put_env(:scrypath_ops, :meilisearch_client, Client)

    Application.put_env(:scrypath_ops, :meilisearch_tasks, [
      %{
        "uid" => 1,
        "status" => "succeeded",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "ctrl_ops_post_a",
        "finishedAt" => "2026-04-16T18:00:00Z"
      },
      %{
        "uid" => 2,
        "status" => "succeeded",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "ctrl_ops_post_b",
        "finishedAt" => "2026-04-16T18:05:00Z"
      }
    ])
  end

  @doc """
  The healthy environment with one failed Meilisearch task for the first schema, so the worst
  row reads Failed and the verdict is an error. Call it inside `put_env/0`'s environment.
  """
  def put_degraded_posture! do
    put_healthy_posture!()

    Application.put_env(:scrypath_ops, :meilisearch_tasks, [
      %{
        "uid" => 401,
        "status" => "failed",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "ctrl_ops_post_a",
        "error" => %{"message" => "index missing"}
      }
    ])
  end

  @doc "Runs `fun` inside the environment, then restores it, even if `fun` raises."
  def with_env(fun) when is_function(fun, 0) do
    previous = put_env()

    try do
      fun.()
    after
      restore_env(previous)
    end
  end
end
