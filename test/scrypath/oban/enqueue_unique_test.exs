defmodule Scrypath.TestSupport.ObanSQLite.TestOban do
  @moduledoc false
  # An Oban facade module, as host apps define one: `oban:` must name a loaded module.
  use Oban, otp_app: :scrypath
end

defmodule Scrypath.Oban.EnqueueUniqueTest do
  # Real Oban (Lite engine on SQLite) so uniqueness and the multi-chunk transaction are
  # enforced by the database, not by a fake. testing: :manual is required: inline
  # testing never enforces unique: (D-23).
  use ExUnit.Case, async: false
  use Oban.Testing, repo: Scrypath.TestSupport.ObanSQLiteRepo, engine: Oban.Engines.Lite

  alias Scrypath.Oban.Enqueue
  alias Scrypath.TestSupport.FakeRepo
  alias Scrypath.TestSupport.ObanSQLiteMigration
  alias Scrypath.TestSupport.ObanSQLiteRepo

  @oban Scrypath.TestSupport.ObanSQLite.TestOban
  @upsert_worker Scrypath.Oban.UpsertWorker

  defmodule RecordingBackend do
    @behaviour Scrypath.Backend

    @impl true
    def name, do: :recording

    @impl true
    def index_name(schema_module, _config) do
      "scrypath_" <> (schema_module |> Module.split() |> List.last() |> Macro.underscore())
    end

    @impl true
    def upsert_documents(_schema_module, _documents, _config), do: {:ok, %{}}

    @impl true
    def delete_documents(_schema_module, _document_ids, _config), do: {:ok, %{}}

    @impl true
    def search(_schema_module, _query, _config), do: {:ok, %{hits: []}}

    @impl true
    def search_facet_values(_schema, _facet, _query, _opts, _config),
      do: {:error, :not_implemented}
  end

  setup_all do
    repo = ObanSQLiteRepo
    adapter = repo.__adapter__()
    config = repo.config()

    {:ok, _apps} = Application.ensure_all_started(:ecto_sql)
    {:ok, _apps} = Application.ensure_all_started(:ecto_sqlite3)

    _ = adapter.storage_down(config)

    case adapter.storage_up(config) do
      :ok -> :ok
      {:error, :already_up} -> :ok
    end

    start_supervised!(repo)

    :ok = Ecto.Migrator.up(repo, 1, ObanSQLiteMigration, log: false)
    :ok = Ecto.Adapters.SQL.Sandbox.mode(repo, :manual)

    database = Keyword.fetch!(config, :database)

    on_exit(fn ->
      Enum.each(["", "-wal", "-shm"], &File.rm("#{database}#{&1}"))
    end)

    start_supervised!(
      {@oban,
       repo: repo,
       engine: Oban.Engines.Lite,
       testing: :manual,
       notifier: Oban.Notifiers.PG,
       queues: false,
       plugins: false}
    )

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(ObanSQLiteRepo)
    Ecto.Adapters.SQL.Sandbox.mode(ObanSQLiteRepo, {:shared, self()})
    :ok
  end

  defp sync_opts do
    [
      backend: RecordingBackend,
      sync_mode: :oban,
      oban: @oban,
      repo: FakeRepo,
      oban_queue: :search_sync
    ]
  end

  defp posts(ids), do: Enum.map(ids, &%SearchablePost{id: &1, title: "T#{&1}", body: "B"})

  test "a duplicate pending batch in a different order collapses with conflict?: true" do
    assert {:ok, first} = Scrypath.sync_records(SearchablePost, posts([2, 1]), sync_opts())
    assert {:ok, second} = Scrypath.sync_records(SearchablePost, posts([1, 2]), sync_opts())

    assert first.job.conflict? == false
    assert %{conflict?: true} = second.job
    assert second.status == :accepted
    assert second.job.id == first.job.id
    assert [%{conflict?: true}] = second.tasks

    assert [_job] = all_enqueued(worker: @upsert_worker)
  end

  test "a different id set is a new job" do
    assert {:ok, first} = Scrypath.sync_records(SearchablePost, posts([1, 2]), sync_opts())
    assert {:ok, third} = Scrypath.sync_records(SearchablePost, posts([1, 2, 3]), sync_opts())

    assert third.job.conflict? == false
    refute third.job.id == first.job.id
    assert length(all_enqueued(worker: @upsert_worker)) == 2
  end

  test "a failed multi-chunk insert rolls back every chunk job" do
    valid = fn ids ->
      Oban.Job.new(%{"document_ids" => ids}, worker: @upsert_worker, queue: "search_sync")
    end

    invalid =
      Oban.Job.new(%{"document_ids" => [3]},
        worker: @upsert_worker,
        queue: "search_sync",
        max_attempts: 0
      )

    assert {:error, _reason} = Enqueue.insert_chunks(@oban, [valid.([1]), invalid, valid.([2])])
    assert all_enqueued() == []
  end

  test "2,500 records enqueue three chunk jobs" do
    assert {:ok, result} = Scrypath.sync_records(SearchablePost, posts(1..2500), sync_opts())

    jobs = all_enqueued(worker: @upsert_worker)
    assert length(jobs) == 3
    assert Enum.all?(jobs, &(length(&1.args["document_ids"]) <= 1000))
    assert result.document_count == 2500
    assert length(result.tasks) == 3
    assert Enum.all?(result.tasks, &(&1.conflict? == false))
  end
end
