defmodule ScrypathOps.Test.CopyStubs.ControlRoom do
  @moduledoc false
  # One definition of the Control room environment (the `/ops` landing page). `ControlRoomLiveTest`
  # and the copy rules surfaces both use it, so a fixture state is never copied between them.

  @env_keys ~w(
    schema_allowlist backend sync_mode index_prefix meilisearch_url meilisearch_client
    meilisearch_tasks oban oban_queue oban_inspector oban_jobs control_room_client_state
  )a

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
