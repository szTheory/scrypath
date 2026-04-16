defmodule Scrypath.Oban.EnqueueTest do
  use ExUnit.Case, async: true

  alias Scrypath.Document

  defmodule RecordingBackend do
    @behaviour Scrypath.Backend

    @impl true
    def name, do: :recording

    @impl true
    def index_name(schema_module, config) do
      prefix = Keyword.get(config, :index_prefix, "scrypath")
      schema_name = schema_module |> Module.split() |> List.last() |> Macro.underscore()

      "#{prefix}_#{schema_name}"
    end

    @impl true
    def upsert_documents(_schema_module, _documents, _config), do: {:ok, %{}}

    @impl true
    def delete_documents(_schema_module, _document_ids, _config), do: {:ok, %{}}

    @impl true
    def search(_schema_module, _query, _config), do: {:ok, %{hits: []}}
  end

  defmodule RecordingOban do
    def insert(changeset) do
      job = Ecto.Changeset.apply_changes(changeset)

      send(self(), {:oban_insert, job})

      {:ok, %{job | id: 901, state: "available"}}
    end
  end

  test "enqueue_upsert/3 inserts one job with the caller batch intact" do
    documents = [
      %Document{id: 11, data: %{title: "One"}, source: :fields},
      %Document{id: 12, data: %{title: "Two"}, source: :fields}
    ]

    assert {:ok, result} =
             Scrypath.Oban.Enqueue.enqueue_upsert(SearchablePost, documents,
               backend: RecordingBackend,
               sync_mode: :oban,
               oban: RecordingOban,
               oban_queue: :search_sync
             )

    assert result.document_ids == [11, 12]
    assert result.document_count == 2
    assert result.job.id == 901
    assert result.job.worker == "Scrypath.Oban.UpsertWorker"
    assert result.job.queue == "search_sync"

    assert_received {:oban_insert, job}
    assert job.worker == "Scrypath.Oban.UpsertWorker"
    assert job.args["document_count"] == 2
    assert job.args["document_ids"] == [11, 12]
    assert Enum.map(job.args["documents"], & &1["id"]) == [11, 12]
  end

  test "enqueue_delete/3 inserts one delete job with resolved ids only" do
    assert {:ok, result} =
             Scrypath.Oban.Enqueue.enqueue_delete(SearchablePost, ["post:7", "post:8"],
               backend: RecordingBackend,
               sync_mode: :oban,
               oban: RecordingOban,
               oban_queue: :search_sync,
               oban_max_attempts: 5
             )

    assert result.document_ids == ["post:7", "post:8"]
    assert result.document_count == 2
    assert result.job.id == 901
    assert result.job.worker == "Scrypath.Oban.DeleteWorker"
    assert result.job.queue == "search_sync"

    assert_received {:oban_insert, job}
    assert job.worker == "Scrypath.Oban.DeleteWorker"
    assert job.args["document_count"] == 2
    assert job.args["document_ids"] == ["post:7", "post:8"]
    refute Map.has_key?(job.args, "documents")
  end
end
