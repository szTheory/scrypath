defmodule Scrypath.SyncTest do
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
    def upsert_documents(schema_module, documents, config) do
      send(self(), {:upsert_documents, schema_module, documents, config})
      {:ok, %{document_ids: Enum.map(documents, & &1.id), sync_mode: config[:sync_mode]}}
    end

    @impl true
    def delete_documents(schema_module, document_ids, config) do
      send(self(), {:delete_documents, schema_module, document_ids, config})
      {:ok, %{document_ids: document_ids, sync_mode: config[:sync_mode]}}
    end

    @impl true
    def search(_schema_module, _query, _config) do
      {:ok, %{hits: []}}
    end
  end

  test "Scrypath.sync_record/3 projects one record and delegates through shared sync orchestration" do
    record = %SearchablePost{id: 123, title: "Hello", body: "World"}

    assert {:ok, %{document_ids: [123], sync_mode: :inline}} =
             Scrypath.sync_record(SearchablePost, record, backend: RecordingBackend)

    assert_received {:upsert_documents, SearchablePost, documents, config}

    assert documents == [
             %Document{id: 123, data: %{title: "Hello", body: "World"}, source: :fields}
           ]

    assert config[:backend] == RecordingBackend
    assert config[:sync_mode] == :inline
  end

  test "Scrypath.sync_records/3 keeps batch upserts list-oriented" do
    records = [
      %SearchablePost{id: 1, title: "One", body: "First"},
      %SearchablePost{id: 2, title: "Two", body: "Second"}
    ]

    assert {:ok, %{document_ids: [1, 2], sync_mode: :manual}} =
             Scrypath.sync_records(SearchablePost, records,
               backend: RecordingBackend,
               sync_mode: :manual
             )

    assert_received {:upsert_documents, SearchablePost, documents, config}

    assert Enum.map(documents, & &1.id) == [1, 2]
    assert Enum.all?(documents, &match?(%Document{}, &1))
    assert config[:sync_mode] == :manual
    refute_received {:upsert_documents, _, [_], _}
  end

  test "delete APIs share the same delete orchestration" do
    record = %SearchablePost{id: 10, title: "Ten", body: "Body"}

    assert {:ok, %{document_ids: [10], sync_mode: :inline}} =
             Scrypath.delete_record(SearchablePost, record, backend: RecordingBackend)

    assert_received {:delete_documents, SearchablePost, [10], inline_config}
    assert inline_config[:sync_mode] == :inline

    assert {:ok, %{document_ids: ["post:11"], sync_mode: :manual}} =
             Scrypath.delete_document(SearchablePost, "post:11",
               backend: RecordingBackend,
               sync_mode: :manual
             )

    assert_received {:delete_documents, SearchablePost, ["post:11"], manual_config}
    assert manual_config[:sync_mode] == :manual

    assert {:ok, %{document_ids: ["post:12", "post:13"], sync_mode: :inline}} =
             Scrypath.delete_documents(SearchablePost, ["post:12", "post:13"],
               backend: RecordingBackend
             )

    assert_received {:delete_documents, SearchablePost, ["post:12", "post:13"], _}
  end
end
