defmodule Scrypath.ObanTest do
  use ExUnit.Case, async: true

  alias Ecto.Multi

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

  test "exposes only narrow Ecto.Multi enqueue helpers" do
    assert function_exported?(Scrypath.Oban, :enqueue_upsert, 5)
    assert function_exported?(Scrypath.Oban, :enqueue_delete, 5)

    refute function_exported?(Scrypath.Oban, :sync_records, 3)
    refute function_exported?(Scrypath.Oban, :delete_documents, 3)
  end

  test "enqueue_upsert/5 appends one named job insert to an Ecto.Multi" do
    multi =
      Multi.new()
      |> Scrypath.Oban.enqueue_upsert(
        :search_sync,
        SearchablePost,
        [%SearchablePost{id: 7, title: "Queued", body: "Body"}],
        backend: RecordingBackend,
        sync_mode: :oban,
        oban_queue: :search_sync
      )

    assert %Multi{} = multi
    assert [:search_sync] == Enum.map(Ecto.Multi.to_list(multi), &elem(&1, 0))
  end

  test "enqueue_delete/5 appends one named delete insert to an Ecto.Multi" do
    multi =
      Multi.new()
      |> Scrypath.Oban.enqueue_delete(
        :search_delete,
        SearchablePost,
        ["post:9", "post:10"],
        backend: RecordingBackend,
        sync_mode: :oban,
        oban_queue: :search_sync
      )

    assert %Multi{} = multi
    assert [:search_delete] == Enum.map(Ecto.Multi.to_list(multi), &elem(&1, 0))
  end
end
