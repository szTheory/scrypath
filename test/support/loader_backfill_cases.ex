defmodule Scrypath.TestSupport.LoaderBackfillCases do
  @moduledoc false

  # Shared real-database cases for the loader and backfill paths.
  #
  #     use ExUnit.Case, async: false
  #     use Scrypath.TestSupport.LoaderBackfillCases, repo: MyRepo
  #
  # The same tests run against the SQLite sandbox repo in the core lane and
  # against Postgres when SCRYPATH_POSTGRES_URL is set. Elixir 1.17 has no
  # ExUnit `parameterize:`, hence the macro. Cases are grouped into several
  # quote blocks so each group stays readable.

  alias Scrypath.TestSupport.LoaderBackfill

  defmacro __using__(opts) do
    repo = Keyword.fetch!(opts, :repo)

    quote do
      unquote(harness(repo))
      unquote(composite_paging_cases())
      unquote(query_scope_cases())
    end
  end

  defp harness(repo) do
    quote location: :keep do
      use ExUnitProperties

      require Ecto.Query

      import Scrypath.TestSupport.LoaderBackfillCases,
        only: [backfill!: 3, recorded_upserts: 0, upserted_ids: 0, insert_memberships!: 2]

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

  defp composite_paging_cases do
    quote location: :keep do
      test "backfill pages a composite key on every key column (pinned {1, 3} regression)",
           %{repo: repo} do
        keys = [{1, 1}, {1, 2}, {1, 3}, {2, 1}]
        insert_memberships!(repo, keys)

        assert {:ok, result} = backfill!(LoaderBackfill.Membership, repo, batch_size: 2)

        assert result |> Map.keys() |> Enum.sort() ==
                 [:batch_results, :batches, :documents, :index, :mode, :removed]

        assert result.batches == 2
        assert result.documents == 4
        assert upserted_ids() == ["1:1", "1:2", "1:3", "2:1"]

        assert [
                 %{documents: 2, last_primary_key: [org_id: 1, seq: 2]},
                 %{documents: 2, last_primary_key: [org_id: 2, seq: 1]}
               ] = result.batch_results
      end

      property "composite keys: every row visited once, full cursor per batch", %{repo: repo} do
        check all(
                keys <- uniq_list_of({integer(1..3), integer(1..20)}, max_length: 30),
                batch_size <- integer(1..12),
                max_runs: 40
              ) do
          repo.transaction(fn ->
            _ = recorded_upserts()
            insert_memberships!(repo, keys)

            assert {:ok, result} =
                     backfill!(LoaderBackfill.Membership, repo, batch_size: batch_size)

            upserted_ids = upserted_ids()
            expected_ids = Enum.map(keys, fn {o, s} -> "#{o}:#{s}" end)

            assert Enum.sort(upserted_ids) == Enum.sort(expected_ids)
            assert length(upserted_ids) == length(Enum.uniq(upserted_ids))
            assert result.documents == length(keys)
            assert result.batches == div(length(keys) + batch_size - 1, batch_size)

            # Integers only, so Elixir tuple order matches the database order.
            expected_cursors =
              keys
              |> Enum.sort()
              |> Enum.chunk_every(batch_size)
              |> Enum.map(fn chunk ->
                {org_id, seq} = List.last(chunk)
                [org_id: org_id, seq: seq]
              end)

            cursors = Enum.map(result.batch_results, & &1.last_primary_key)
            assert cursors == expected_cursors

            cursors
            |> Enum.map(fn [org_id: o, seq: s] -> {o, s} end)
            |> Enum.chunk_every(2, 1, :discard)
            |> Enum.each(fn [previous, next] -> assert previous < next end)

            repo.rollback(:reset)
          end)
        end
      end

      test "backfill pages a binary_id second key column", %{repo: repo} do
        rows =
          for org_id <- [1, 1, 1, 2, 2] do
            %{org_id: org_id, uid: Ecto.UUID.generate(), name: "d"}
          end

        {5, _} = repo.insert_all(LoaderBackfill.Device, rows)
        expected = rows |> Enum.map(&"#{&1.org_id}:#{&1.uid}") |> Enum.sort()

        for batch_size <- [1, 2] do
          assert {:ok, result} = backfill!(LoaderBackfill.Device, repo, batch_size: batch_size)
          assert result.documents == 5

          upserted_ids = upserted_ids()
          assert Enum.sort(upserted_ids) == expected
          assert length(upserted_ids) == 5

          assert Enum.all?(result.batch_results, fn batch ->
                   match?([org_id: _, uid: _], batch.last_primary_key)
                 end)
        end
      end

      test "an empty table backfills zero batches; a single row is one batch", %{repo: repo} do
        assert {:ok, %{batches: 0, documents: 0, batch_results: []}} =
                 backfill!(LoaderBackfill.Membership, repo, batch_size: 2)

        insert_memberships!(repo, [{3, 9}])

        assert {:ok, %{batches: 1, documents: 1, batch_results: [batch]}} =
                 backfill!(LoaderBackfill.Membership, repo, batch_size: 2)

        assert batch.last_primary_key == [org_id: 3, seq: 9]
      end
    end
  end

  defp query_scope_cases do
    quote location: :keep do
      test "a caller query keeps its where scope while its offset is ignored", %{repo: repo} do
        posts =
          for title <- ["a", "skip", "b", "skip", "c", "d"] do
            repo.insert!(%LoaderBackfill.Post{title: title})
          end

        query =
          Ecto.Query.from(p in LoaderBackfill.Post,
            where: p.title != "skip",
            offset: 2,
            order_by: [desc: p.id],
            limit: 1
          )

        assert {:ok, result} =
                 backfill!(LoaderBackfill.Post, repo, batch_size: 2, query: query)

        assert upserted_ids() == for(%{title: t, id: id} <- posts, t != "skip", do: id)
        assert result.documents == 4
      end

      test "rows a fanned-out caller join duplicates are upserted once", %{repo: repo} do
        ids = for n <- 1..3, do: repo.insert!(%LoaderBackfill.Post{title: "p#{n}"}).id

        query =
          Ecto.Query.from(p in LoaderBackfill.Post, join: o in LoaderBackfill.Post, on: true)

        assert {:ok, result} = backfill!(LoaderBackfill.Post, repo, batch_size: 2, query: query)

        assert upserted_ids() == ids
        assert result.documents == 3
      end

      test "keyless schemas page on the document id and skip nil ids", %{repo: repo} do
        rows =
          for ref <- ["b", nil, "a", "d", nil, "c"] do
            %{external_ref: ref, title: "t"}
          end

        {6, _} = repo.insert_all(LoaderBackfill.KeylessEvent, rows)

        assert {:ok, result} = backfill!(LoaderBackfill.KeylessEvent, repo, batch_size: 3)

        assert upserted_ids() == ["a", "b", "c", "d"]
        assert result.documents == 4
        assert Enum.map(result.batch_results, & &1.last_primary_key) == ["c", "d"]
      end

      test "single-column keyset SQL is one plain comparison", %{repo: repo} do
        for n <- 1..3, do: repo.insert!(%LoaderBackfill.Post{title: "p#{n}"})

        handler_id = {__MODULE__, :sql_shape, make_ref()}

        :ok =
          :telemetry.attach(
            handler_id,
            repo.config()[:telemetry_prefix] ++ [:query],
            &Scrypath.TestSupport.LoaderBackfillCases.forward_query/4,
            self()
          )

        on_exit(fn -> :telemetry.detach(handler_id) end)

        assert {:ok, %{batches: 2}} = backfill!(LoaderBackfill.Post, repo, batch_size: 2)
        :telemetry.detach(handler_id)

        [first | later] =
          Scrypath.TestSupport.LoaderBackfillCases.forwarded_queries()
          |> Enum.filter(&String.contains?(&1, "lb_posts"))

        refute first =~ "WHERE"
        assert length(later) == 2

        for sql <- later do
          assert sql =~ "WHERE"
          assert length(String.split(sql, ">")) == 2
          refute sql =~ ">="
          refute sql =~ ~r/\bOR\b/i
        end
      end
    end
  end

  @doc false
  def forward_query(_event, _measurements, metadata, pid) do
    send(pid, {:lb_sql, metadata.query})
  end

  @doc "Drains SQL strings forwarded by `forward_query/4`."
  def forwarded_queries, do: drain_queries([])

  defp drain_queries(acc) do
    receive do
      {:lb_sql, sql} -> drain_queries([sql | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end

  @doc "Inserts `lb_memberships` rows for `{org_id, seq}` key tuples."
  def insert_memberships!(repo, keys) do
    rows = Enum.map(keys, fn {org_id, seq} -> %{org_id: org_id, seq: seq, label: "m"} end)
    {count, _} = repo.insert_all(LoaderBackfill.Membership, rows)
    count
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

  @doc "Drains recorded upserts and returns their document ids in arrival order."
  def upserted_ids do
    Enum.flat_map(recorded_upserts(), fn {_schema, documents, _config} ->
      Enum.map(documents, & &1.id)
    end)
  end

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
