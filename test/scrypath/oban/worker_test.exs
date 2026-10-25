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

  test "workers return retryable errors for transient backend failures" do
    FakeRepo.put_records([%QueryablePost{id: 1, title: "One"}])
    args = upsert_args(QueryablePost, TransientBackend, [1])

    assert {:error, :timeout} = Scrypath.Oban.UpsertWorker.perform(%Oban.Job{args: args})
    assert {:error, :timeout} = Scrypath.Oban.DeleteWorker.perform(%Oban.Job{args: args})
  end
end
