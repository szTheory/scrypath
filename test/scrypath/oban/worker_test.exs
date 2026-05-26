defmodule Scrypath.Oban.WorkerTest do
  use ExUnit.Case, async: true

  alias Scrypath.Document

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

  test "upsert worker writes serialized documents without reloading source rows" do
    args = %{
      "schema" => "Elixir.SearchablePost",
      "backend" => "Elixir.Scrypath.Oban.WorkerTest.RecordingBackend",
      "index" => "tenant_searchable_post",
      "sync_mode" => "oban",
      "document_count" => 2,
      "document_ids" => [1, 2],
      "documents" => [
        %{"id" => 1, "data" => %{"title" => "One"}, "source" => "fields"},
        %{"id" => 2, "data" => %{"title" => "Two"}, "source" => "custom"}
      ]
    }

    assert :ok = Scrypath.Oban.UpsertWorker.perform(%Oban.Job{args: args})

    assert_received {:upsert_documents, SearchablePost, documents, config}

    assert documents == [
             %Document{id: 1, data: %{"title" => "One"}, source: :fields},
             %Document{id: 2, data: %{"title" => "Two"}, source: :custom}
           ]

    assert config[:backend] == RecordingBackend
    assert config[:index_name] == "tenant_searchable_post"
    refute_received {:fake_repo_all, _}
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
    args = %{
      "schema" => "Elixir.SearchablePost",
      "backend" => "Elixir.Scrypath.Oban.WorkerTest.TransientBackend",
      "index" => "tenant_searchable_post",
      "sync_mode" => "oban",
      "document_count" => 1,
      "document_ids" => [1],
      "documents" => [%{"id" => 1, "data" => %{"title" => "One"}, "source" => "fields"}]
    }

    assert {:error, :timeout} = Scrypath.Oban.UpsertWorker.perform(%Oban.Job{args: args})

    assert {:error, :timeout} =
             Scrypath.Oban.DeleteWorker.perform(%Oban.Job{args: Map.delete(args, "documents")})
  end
end
