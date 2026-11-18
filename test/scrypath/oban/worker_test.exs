defmodule Scrypath.Oban.WorkerTest do
  use ExUnit.Case, async: true

  alias Scrypath.Document
  alias Scrypath.TestSupport.FakeRepo

  defmodule RecordingBackend do
    @behaviour Scrypath.Backend

    @impl true
    def name, do: :recording

    @impl true
    def index_name(schema_module, config) do
      Keyword.get(config, :index_name) ||
        begin_index(schema_module, config)
    end

    defp begin_index(schema_module, config) do
      prefix = Keyword.get(config, :index_prefix, "scrypath")
      schema_name = schema_module |> Module.split() |> List.last() |> Macro.underscore()

      "#{prefix}_#{schema_name}"
    end

    @impl true
    def upsert_documents(schema_module, documents, config) do
      send(self(), {:upsert_documents, schema_module, documents, config})

      {:ok,
       %{document_ids: Enum.map(documents, & &1.id), index: index_name(schema_module, config)}}
    end

    @impl true
    def delete_documents(schema_module, document_ids, config) do
      send(self(), {:delete_documents, schema_module, document_ids, config})
      {:ok, %{document_ids: document_ids, index: index_name(schema_module, config)}}
    end

    @impl true
    def search(_schema_module, _query, _config), do: {:ok, %{hits: []}}

    @impl true
    def search_facet_values(_schema, _facet, _query, _opts, _config) do
      {:error, :not_implemented}
    end
  end

  defmodule TransientBackend do
    @behaviour Scrypath.Backend

    @impl true
    def name, do: :transient

    @impl true
    def index_name(_schema_module, _config), do: "scrypath_searchable_post"

    @impl true
    def upsert_documents(_schema_module, _documents, _config), do: {:error, :timeout}

    @impl true
    def delete_documents(_schema_module, _document_ids, _config), do: {:error, :timeout}

    @impl true
    def search(_schema_module, _query, _config), do: {:ok, %{hits: []}}

    @impl true
    def search_facet_values(_schema, _facet, _query, _opts, _config) do
      {:error, :not_implemented}
    end
  end

  defmodule LoaderPost do
    use Ecto.Schema

    use Scrypath, fields: [:title]

    schema "loader_posts" do
      field(:title, :string)
    end

    def search_records(ids, context) do
      send(self(), {:search_records, ids, context})
      Enum.map(ids -- [404], &%__MODULE__{id: &1, title: "Loaded #{&1}"})
    end
  end

  defmodule GoneLoaderPost do
    use Ecto.Schema

    use Scrypath, fields: [:title]

    schema "gone_loader_posts" do
      field(:title, :string)
    end

    def search_records(_ids, _context), do: []
  end

  defmodule BrokenLoaderPost do
    use Ecto.Schema

    use Scrypath, fields: [:title]

    schema "broken_loader_posts" do
      field(:title, :string)
    end

    def search_records(ids, _context), do: {:ok, Enum.map(ids, &%__MODULE__{id: &1})}
  end

  setup do
    FakeRepo.reset()
    :ok
  end

  defp upsert_args(schema, backend, ids, extra \\ %{}) do
    Map.merge(
      %{
        "schema" => to_string(schema),
        "backend" => to_string(backend),
        "index" => "tenant_queryable_post",
        "sync_mode" => "oban",
        "document_count" => length(ids),
        "document_ids" => ids,
        "repo" => to_string(FakeRepo)
      },
      extra
    )
  end

  test "upsert worker loads current records instead of trusting data in the job" do
    FakeRepo.put_records([%QueryablePost{id: 1, title: "Current title"}])

    # Jobs queued before ids-only payloads still carry an old copy; it must be ignored.
    legacy_snapshot = %{
      "documents" => [%{"id" => 1, "data" => %{"title" => "Old title"}, "source" => "fields"}]
    }

    args = upsert_args(QueryablePost, RecordingBackend, [1], legacy_snapshot)

    assert :ok = Scrypath.Oban.UpsertWorker.perform(%Oban.Job{args: args})

    assert_received {:fake_repo_all, %Ecto.Query{}}
    assert_received {:upsert_documents, QueryablePost, [%Document{id: 1} = document], config}
    assert document.data.title == "Current title"
    assert config[:backend] == RecordingBackend
    assert config[:index_name] == "tenant_queryable_post"
    refute_received {:delete_documents, _, _, _}
  end

  test "upsert worker deletes documents whose records no longer exist" do
    FakeRepo.put_records([%QueryablePost{id: 1, title: "Still here"}])

    args = upsert_args(QueryablePost, RecordingBackend, [1, 2])

    assert :ok = Scrypath.Oban.UpsertWorker.perform(%Oban.Job{args: args})

    assert_received {:upsert_documents, QueryablePost, [%Document{id: 1}], _config}
    assert_received {:delete_documents, QueryablePost, [2], _config}
  end

  test "upsert worker uses a schema's search_records/2 loader" do
    args = upsert_args(LoaderPost, RecordingBackend, [7, 404])

    assert :ok = Scrypath.Oban.UpsertWorker.perform(%Oban.Job{args: args})

    # The loader dedupes and sorts ids into chunks; there is no ordering contract.
    assert_received {:search_records, loaded_ids, %{repo: FakeRepo}}
    assert Enum.sort(loaded_ids) == [7, 404]
    assert_received {:upsert_documents, LoaderPost, [%Document{id: 7} = document], _config}
    assert document.data.title == "Loaded 7"
    assert_received {:delete_documents, LoaderPost, [404], _config}
    refute_received {:fake_repo_all, _}
  end

  test "upsert worker cancels jobs that cannot load records" do
    args = upsert_args(QueryablePost, RecordingBackend, [1]) |> Map.delete("repo")

    assert {:cancel, {:invalid_job, :repo_required}} =
             Scrypath.Oban.UpsertWorker.perform(%Oban.Job{args: args})
  end

  test "upsert worker cancels an id the integer primary key cannot cast (WR-07)" do
    args = upsert_args(QueryablePost, RecordingBackend, [1, "abc"])

    assert Scrypath.Oban.UpsertWorker.perform(%Oban.Job{args: args}) ==
             {:cancel, {:invalid_job, {:invalid_arg, "document_ids"}}}

    refute_received {:fake_repo_all, _}
    refute_received {:upsert_documents, _, _, _}
  end

  test "upsert worker casts string ids to the integer primary key before querying (WR-07)" do
    FakeRepo.put_records([%QueryablePost{id: 12, title: "Twelve"}])
    args = upsert_args(QueryablePost, RecordingBackend, ["12"])

    assert :ok = Scrypath.Oban.UpsertWorker.perform(%Oban.Job{args: args})

    assert_received {:fake_repo_all, %Ecto.Query{wheres: [%{params: [{[12], _type}]}]}}
    assert_received {:upsert_documents, QueryablePost, [%Document{id: 12}], _config}
  end

  test "upsert worker cancels when search_records/2 returns a non-list (IN-04)" do
    args = upsert_args(BrokenLoaderPost, RecordingBackend, [1])

    assert Scrypath.Oban.UpsertWorker.perform(%Oban.Job{args: args}) ==
             {:cancel, {:invalid_job, :invalid_search_records}}

    refute_received {:upsert_documents, _, _, _}
    refute_received {:delete_documents, _, _, _}
  end

  test "a job queued before 0.3.16 still syncs its snapshot when the app can't load records" do
    legacy_snapshot = %{
      "documents" => [%{"id" => 1, "data" => %{"title" => "Queued title"}, "source" => "fields"}]
    }

    args =
      QueryablePost
      |> upsert_args(RecordingBackend, [1], legacy_snapshot)
      |> Map.delete("repo")

    assert :ok = Scrypath.Oban.UpsertWorker.perform(%Oban.Job{args: args})
    assert_received {:upsert_documents, QueryablePost, [%Document{id: 1} = document], _config}
    assert document.data["title"] == "Queued title"
    assert document.source == :fields
    refute_received {:fake_repo_all, _}
  end

  test "a malformed legacy snapshot is cancelled rather than written" do
    mismatched = %{
      "documents" => [%{"id" => 2, "data" => %{"title" => "Other"}, "source" => "fields"}]
    }

    args =
      QueryablePost
      |> upsert_args(RecordingBackend, [1], mismatched)
      |> Map.delete("repo")

    assert {:cancel, {:invalid_job, :repo_required}} =
             Scrypath.Oban.UpsertWorker.perform(%Oban.Job{args: args})

    refute_received {:upsert_documents, _, _, _}
  end

  test "delete worker deletes resolved ids and does not expect documents in args" do
    args = %{
      "schema" => "Elixir.SearchablePost",
      "backend" => "Elixir.Scrypath.Oban.WorkerTest.RecordingBackend",
      "index" => "tenant_searchable_post",
      "sync_mode" => "oban",
      "document_count" => 2,
      "document_ids" => ["post:1", "post:2"]
    }

    assert :ok = Scrypath.Oban.DeleteWorker.perform(%Oban.Job{args: args})

    assert_received {:delete_documents, SearchablePost, ["post:1", "post:2"], config}
    assert config[:backend] == RecordingBackend
    assert config[:index_name] == "tenant_searchable_post"
  end

  test "workers cancel impossible payload problems instead of retrying forever" do
    bad_args = %{
      "schema" => "MissingSchema",
      "backend" => "Elixir.Scrypath.Oban.WorkerTest.RecordingBackend",
      "index" => "tenant_searchable_post",
      "sync_mode" => "oban",
      "document_count" => 1,
      "document_ids" => [1],
      "documents" => [%{"id" => 1, "data" => %{"title" => "One"}, "source" => "fields"}]
    }

    assert {:cancel, {:invalid_job, _reason}} =
             Scrypath.Oban.UpsertWorker.perform(%Oban.Job{args: bad_args})
  end

  defp delete_args(overrides) do
    Map.merge(
      %{
        "schema" => "Elixir.SearchablePost",
        "backend" => to_string(RecordingBackend),
        "index" => "tenant_searchable_post",
        "sync_mode" => "oban",
        "document_count" => 1,
        "document_ids" => ["post:1"]
      },
      overrides
    )
  end

  describe "delete worker bad args" do
    for {label, overrides, drop, tag} <- [
          {"schema", %{"schema" => "Elixir.Nope.Schema"}, nil,
           {:unknown_schema, "Elixir.Nope.Schema"}},
          {"backend", %{"backend" => "Elixir.Nope.Backend"}, nil,
           {:unknown_backend, "Elixir.Nope.Backend"}},
          {"document_ids", %{}, "document_ids", {:invalid_arg, "document_ids"}},
          {"document_count", %{"document_count" => 2}, nil, {:invalid_arg, "document_count"}},
          {"index", %{"index" => ""}, nil, {:invalid_arg, "index"}}
        ] do
      test "cancels a job with a bad #{label}" do
        args = delete_args(unquote(Macro.escape(overrides)))
        args = if unquote(drop), do: Map.delete(args, unquote(drop)), else: args

        assert Scrypath.Oban.DeleteWorker.perform(%Oban.Job{args: args}) ==
                 {:cancel, {:invalid_job, unquote(Macro.escape(tag))}}

        refute_received {:delete_documents, _, _, _}
      end
    end

    test "does not cancel on an unknown repo, which a delete job never uses" do
      args = delete_args(%{"repo" => "Elixir.Nope.Repo"})

      assert :ok = Scrypath.Oban.DeleteWorker.perform(%Oban.Job{args: args})
      assert_received {:delete_documents, SearchablePost, ["post:1"], _config}
    end
  end

  test "delete worker sends 2,500 ids as three chunks of at most 1000" do
    ids = Enum.to_list(1..2500)
    args = delete_args(%{"document_ids" => ids, "document_count" => 2500})

    assert :ok = Scrypath.Oban.DeleteWorker.perform(%Oban.Job{args: args})

    chunks = collect_messages(:delete_documents)
    assert length(chunks) == 3
    assert Enum.all?(chunks, &(length(&1) <= 1000))
    assert chunks |> Enum.concat() |> Enum.sort() == ids
  end

  describe "upsert worker bad args" do
    for {label, overrides, drop, tag} <- [
          {"schema", %{"schema" => "Elixir.Nope.Schema"}, nil,
           {:unknown_schema, "Elixir.Nope.Schema"}},
          {"backend", %{"backend" => "Elixir.Nope.Backend"}, nil,
           {:unknown_backend, "Elixir.Nope.Backend"}},
          {"repo", %{"repo" => "Elixir.Nope.Repo"}, nil, {:unknown_repo, "Elixir.Nope.Repo"}},
          {"document_ids", %{}, "document_ids", {:invalid_arg, "document_ids"}},
          {"index", %{"index" => ""}, nil, {:invalid_arg, "index"}}
        ] do
      test "cancels a job with a bad #{label}" do
        FakeRepo.put_records([%QueryablePost{id: 1, title: "One"}])
        args = upsert_args(QueryablePost, RecordingBackend, [1], unquote(Macro.escape(overrides)))
        args = if unquote(drop), do: Map.delete(args, unquote(drop)), else: args

        assert Scrypath.Oban.UpsertWorker.perform(%Oban.Job{args: args}) ==
                 {:cancel, {:invalid_job, unquote(Macro.escape(tag))}}

        refute_received {:fake_repo_all, _}
        refute_received {:upsert_documents, _, _, _}
      end
    end

    test "an edited repo is cancelled instead of silently loading without it" do
      legacy_snapshot = %{
        "documents" => [%{"id" => 1, "data" => %{"title" => "Old"}, "source" => "fields"}]
      }

      args =
        upsert_args(
          QueryablePost,
          RecordingBackend,
          [1],
          Map.put(legacy_snapshot, "repo", "Elixir.Nope.Repo")
        )

      assert {:cancel, {:invalid_job, {:unknown_repo, "Elixir.Nope.Repo"}}} =
               Scrypath.Oban.UpsertWorker.perform(%Oban.Job{args: args})

      refute_received {:upsert_documents, _, _, _}
    end
  end

  test "upsert worker loads and upserts 2,500 ids in chunks, then deletes missing ids" do
    ids = Enum.to_list(1..2500)
    args = upsert_args(LoaderPost, RecordingBackend, ids)

    assert :ok = Scrypath.Oban.UpsertWorker.perform(%Oban.Job{args: args})

    events = collect_events()
    loads = for {:search_records, chunk} <- events, do: chunk
    upserts = for {:upsert_documents, chunk} <- events, do: chunk
    deletes = for {:delete_documents, chunk} <- events, do: chunk

    assert length(loads) == 3
    assert Enum.all?(loads, &(length(&1) <= 1000))
    assert loads |> Enum.concat() |> Enum.sort() == ids

    assert length(upserts) == 3
    assert Enum.all?(upserts, &(length(&1) <= 1000))
    assert upserts |> Enum.concat() |> Enum.map(& &1.id) |> Enum.sort() == ids -- [404]

    assert deletes == [[404]]

    # Every upsert is sent (and awaited) before the first missing-id delete.
    writes = for {kind, _chunk} <- events, kind != :search_records, do: kind
    assert writes == [:upsert_documents, :upsert_documents, :upsert_documents, :delete_documents]
  end

  test "upsert worker deletes 2,500 missing ids in chunks of at most 1000" do
    ids = Enum.to_list(1..2500)
    args = upsert_args(GoneLoaderPost, RecordingBackend, ids)

    assert :ok = Scrypath.Oban.UpsertWorker.perform(%Oban.Job{args: args})

    events = collect_events()
    deletes = for {:delete_documents, chunk} <- events, do: chunk

    refute Enum.any?(events, &match?({:upsert_documents, _}, &1))
    assert length(deletes) == 3
    assert Enum.all?(deletes, &(length(&1) <= 1000))
    assert deletes |> Enum.concat() |> Enum.sort() == ids
  end

  defp collect_events(acc \\ []) do
    receive do
      {:search_records, ids, _context} -> collect_events([{:search_records, ids} | acc])
      {kind, _schema, entries, _config} -> collect_events([{kind, entries} | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end

  defp collect_messages(kind, acc \\ []) do
    receive do
      {^kind, _schema, entries, _config} -> collect_messages(kind, [entries | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end

  test "workers return retryable errors for transient backend failures" do
    FakeRepo.put_records([%QueryablePost{id: 1, title: "One"}])
    args = upsert_args(QueryablePost, TransientBackend, [1])

    assert {:error, :timeout} = Scrypath.Oban.UpsertWorker.perform(%Oban.Job{args: args})
    assert {:error, :timeout} = Scrypath.Oban.DeleteWorker.perform(%Oban.Job{args: args})
  end
end
