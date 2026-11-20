defmodule ScrypathOps.Test.CopyStubs.FailedSync do
  @moduledoc false
  # One definition of the Failed sync work stubs: the Meilisearch client, the Oban inspector, the
  # recording Oban insert, the `Oban.Job` struct the retry path builds, and the environment they
  # need. `FailedSyncLiveTest` and the copy rules surfaces both use it, so a fixture state is
  # never copied between them.
  #
  # Nothing here sets up the sudo confirmation. The namespace fence keeps references to that
  # integration out of `test/support`, so `FailedSyncLiveTest` adds the confirmation to its own
  # setup. The surface renders the retry in the default host-authenticated mode, where the
  # retry runs without one.

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint ScrypathOpsWeb.Endpoint

  @counter :failed_sync_insert_counter

  @env_keys ~w(
    schema_allowlist backend sync_mode index_prefix meilisearch_url meilisearch_client
    meilisearch_tasks oban oban_queue oban_inspector oban_jobs failing_index_uids
  )a

  defmodule Client do
    @moduledoc false

    # Scoped like Meilisearch: only tasks for the requested index come back.
    def tasks(filters, config) do
      uids = Keyword.get(filters, :index_uids, [])
      failing = Application.get_env(:scrypath_ops, :failing_index_uids, [])

      cond do
        Enum.any?(uids, &(&1 in failing)) ->
          {:error, :backend_unavailable}

        true ->
          case Keyword.get(config, :meilisearch_tasks, []) do
            {:error, reason} ->
              {:error, reason}

            results ->
              {:ok, %{results: Enum.filter(results, &(Map.get(&1, "indexUid") in uids))}}
          end
      end
    end
  end

  defmodule ObanInspector do
    @moduledoc false

    # Scoped like the real inspector: only jobs whose args name this schema.
    def list_jobs(schema_module, config) do
      schema = Atom.to_string(schema_module)

      jobs =
        config
        |> Keyword.get(:oban_jobs, [])
        |> Enum.filter(fn job ->
          Map.get(job.args, "schema", "Elixir.ScrypathOps.Test.OpsPostA") == schema
        end)

      {:ok, jobs}
    end
  end

  defmodule RecordingOban do
    @moduledoc false

    def insert(changeset) do
      Agent.update(:failed_sync_insert_counter, &(&1 + 1))
      job = Ecto.Changeset.apply_changes(changeset)
      {:ok, %{job | id: 991, state: "available"}}
    end
  end

  @doc "Registered name of the Agent that counts retry inserts."
  def counter_name, do: @counter

  @doc "Child spec for the Agent that counts retry inserts."
  def counter_spec do
    %{id: @counter, start: {Agent, :start_link, [fn -> 0 end, [name: @counter]]}}
  end

  @doc """
  Puts the allowlist, Meilisearch and Oban environment the Failed sync work tests use and
  returns the previous values for `restore_env/1`. The failed job is the Oban job 501.
  """
  def put_env do
    previous = Map.new(@env_keys, &{&1, Application.get_env(:scrypath_ops, &1)})

    Application.put_env(:scrypath_ops, :schema_allowlist, [
      ScrypathOps.Test.OpsPostA,
      ScrypathOps.Test.OpsPostB
    ])

    Application.put_env(:scrypath_ops, :backend, Scrypath.Meilisearch)
    Application.put_env(:scrypath_ops, :sync_mode, :oban)
    Application.put_env(:scrypath_ops, :index_prefix, "fsv")
    Application.put_env(:scrypath_ops, :meilisearch_url, "http://localhost:7700")
    Application.put_env(:scrypath_ops, :meilisearch_client, Client)

    Application.put_env(:scrypath_ops, :meilisearch_tasks, [
      %{
        "uid" => 401,
        "status" => "failed",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "fsv_ops_post_a",
        "error" => %{"message" => "index missing"}
      }
    ])

    Application.put_env(:scrypath_ops, :oban, RecordingOban)
    Application.put_env(:scrypath_ops, :oban_queue, :search_sync)
    Application.put_env(:scrypath_ops, :oban_inspector, ObanInspector)
    Application.put_env(:scrypath_ops, :oban_jobs, [retryable_job()])

    previous
  end

  @doc "Restores the environment captured by `put_env/0`."
  def restore_env(previous) do
    Enum.each(previous, fn
      {k, nil} -> Application.delete_env(:scrypath_ops, k)
      {k, v} -> Application.put_env(:scrypath_ops, k, v)
    end)
  end

  @doc "The one retryable upsert job (id 501) every Failed sync work test starts from."
  def retryable_job do
    %{
      id: 501,
      state: "retryable",
      worker: "Scrypath.Oban.UpsertWorker",
      queue: "search_sync",
      args: %{
        "operation" => "upsert",
        "repo" => "Elixir.ScrypathOps.Repo",
        "schema" => "Elixir.ScrypathOps.Test.OpsPostA",
        "backend" => "Elixir.Scrypath.Meilisearch",
        "index" => "fsv_ops_post_a",
        "document_count" => 1,
        "document_ids" => [1],
        "documents" => [
          %{"id" => 1, "data" => %{"title" => "One"}, "source" => "fields"}
        ]
      }
    }
  end

  @doc """
  Runs `fun` with the environment and the insert counter in place and the default
  host-authenticated mode (`basic`), then stops the counter and restores the environment, even
  if `fun` raises. For renderers that are not inside a test's own setup.
  """
  def with_stubs(fun) when is_function(fun, 0) do
    previous = put_env()
    previous_mode = System.get_env("OPSUI_AUTH_MODE")
    System.put_env("OPSUI_AUTH_MODE", "basic")
    {:ok, agent} = Agent.start_link(fn -> 0 end, name: @counter)

    try do
      fun.()
    after
      Agent.stop(agent)
      restore_env(previous)

      if previous_mode == nil,
        do: System.delete_env("OPSUI_AUTH_MODE"),
        else: System.put_env("OPSUI_AUTH_MODE", previous_mode)
    end
  end

  @doc """
  The Failed sync work page right after the operator retried job 501: the retry receipt and the
  flash are both on screen. `conn` is the calling test's own.
  """
  def render_after_retry(conn) do
    with_stubs(fn ->
      {:ok, view, _html} = live(conn, "/ops/failed-sync")

      render_click(view, "retry", %{"id" => "501", "schema" => "ScrypathOps.Test.OpsPostA"})
    end)
  end
end
