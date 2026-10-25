defmodule Scrypath.TestSupport.LoaderBackfillCases do
  @moduledoc false

  # Shared real-database cases for the loader and backfill paths.
  #
  #     use ExUnit.Case, async: false
  #     use Scrypath.TestSupport.LoaderBackfillCases, repo: MyRepo
  #
  # The same tests run against the SQLite sandbox repo in the core lane and
  # against Postgres when SCRYPATH_POSTGRES_URL is set. Elixir 1.17 has no
  # ExUnit `parameterize:`, hence the macro.

  alias Scrypath.TestSupport.LoaderBackfill

  defmacro __using__(opts) do
    repo = Keyword.fetch!(opts, :repo)

    quote location: :keep do
      use ExUnitProperties

      import Scrypath.TestSupport.LoaderBackfillCases,
        only: [backfill!: 3, recorded_upserts: 0]

      alias Scrypath.TestSupport.LoaderBackfill

      @lb_repo unquote(repo)

      setup_all do
        Scrypath.TestSupport.LoaderBackfillCases.setup_repo!(@lb_repo)
        :ok
      end

      setup do
        :ok = Ecto.Adapters.SQL.Sandbox.checkout(@lb_repo)
        %{repo: @lb_repo}
      end

      test "backfill pages a single-column key end-to-end", %{repo: repo} do
        ids =
          for n <- 1..5 do
            repo.insert!(%LoaderBackfill.Post{title: "post #{n}"}).id
          end

        assert {:ok, result} = backfill!(LoaderBackfill.Post, repo, batch_size: 2)

        assert result.batches == 3
        assert result.documents == 5

        upserts = recorded_upserts()
        assert length(upserts) == 3

        upserted_ids =
          Enum.flat_map(upserts, fn {_schema, documents, _config} ->
            Enum.map(documents, & &1.id)
          end)

        assert Enum.sort(upserted_ids) == Enum.sort(ids)
        assert length(upserted_ids) == length(Enum.uniq(upserted_ids))

        upserts
        |> Enum.zip(result.batch_results)
        |> Enum.each(fn {{_schema, documents, _config}, batch} ->
          assert is_integer(batch.last_primary_key)
          assert batch.last_primary_key == documents |> Enum.map(& &1.id) |> Enum.max()
        end)
      end
    end
  end

  @doc """
  Drops and recreates the repo's database, starts the repo, runs the inline
  migration once, and switches the sandbox to manual mode.

  Call from `setup_all`.
  """
  def setup_repo!(repo) do
    adapter = repo.__adapter__()
    config = repo.config()

    {:ok, _apps} = Application.ensure_all_started(:ecto_sql)
    ensure_adapter_started!(adapter)

    _ = adapter.storage_down(config)

    case adapter.storage_up(config) do
      :ok -> :ok
      {:error, :already_up} -> :ok
    end

    ExUnit.Callbacks.start_supervised!(repo)

    :ok = Ecto.Migrator.up(repo, 0, LoaderBackfill.Migration, log: false)
    :ok = Ecto.Adapters.SQL.Sandbox.mode(repo, :manual)

    if adapter == Ecto.Adapters.SQLite3 do
      database = Keyword.fetch!(config, :database)

      ExUnit.Callbacks.on_exit(fn ->
        Enum.each(["", "-wal", "-shm"], &File.rm("#{database}#{&1}"))
      end)
    end

    :ok
  end

  @doc "Runs `Scrypath.backfill/2` against the recording backend."
  def backfill!(schema, repo, opts) do
    Scrypath.backfill(
      schema,
      Keyword.merge(
        [backend: LoaderBackfill.RecordingBackend, repo: repo, sync_mode: :manual],
        opts
      )
    )
  end

  @doc "Drains recorded `{schema, documents, config}` upserts in arrival order."
  def recorded_upserts, do: drain_upserts([])

  defp drain_upserts(acc) do
    receive do
      {:upsert_documents, schema, documents, config} ->
        drain_upserts([{schema, documents, config} | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end

  defp ensure_adapter_started!(Ecto.Adapters.Postgres) do
    {:ok, _apps} = Application.ensure_all_started(:postgrex)
    :ok
  end

  defp ensure_adapter_started!(_adapter), do: :ok
end
