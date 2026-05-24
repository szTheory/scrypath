defmodule Scrypath.Sync.RelatedTest do
  use ExUnit.Case, async: true

  defmodule DummyTarget do
    use Ecto.Schema

    @primary_key {:id, :id, autogenerate: true}
    schema "dummy_targets" do
      field :title, :string
    end

    def __scrypath__(:document_id), do: :id
    def __scrypath__(:fields), do: [:title]
    def __scrypath__(:custom_document), do: false
    def __scrypath__(:config) do
      %{
        fields: [:title],
        index_prefix: nil,
        document_id: :id,
        backend: nil,
        settings: %{__unrecognized__: %{}},
        faceting: [],
        document_source: :fields,
        filterable: [],
        sortable: [],
        fan_outs: []
      }
    end
  end

  defmodule DummySource do
    use Ecto.Schema

    @primary_key {:id, :id, autogenerate: true}
    schema "dummy_sources" do
      field :name, :string
    end

    def __scrypath__(:fan_outs) do
      [
        comments: [
          target: DummyTarget,
          resolver: {__MODULE__, :resolve_comments, [:extra_arg]}
        ]
      ]
    end

    def __scrypath__(:document_id), do: :id

    def resolve_comments([_ | _] = records, :extra_arg) do
      Enum.map(records, &%DummyTarget{id: &1.id * 10, title: "Resolved for #{&1.name}"})
    end
  end

  defmodule RecordingBackend do
    def name, do: RecordingBackend

    def upsert_documents(schema, documents, config) do
      send(self(), {:upsert_documents, schema, documents, config})
      {:ok, %{status: "enqueued", taskUid: 42}}
    end

    def index_name(_schema, _config), do: "dummy_index"
  end

  defmodule EnqueueOban do
    def insert(changeset) do
      job = Ecto.Changeset.apply_changes(changeset)
      send(self(), {:oban_insert, job})
      {:ok, %{job | id: 501, state: "available"}}
    end
  end

  test "sync_mode: :inline executes resolver and forwards to sync_records" do
    records = [
      %DummySource{id: 1, name: "Source 1"},
      %DummySource{id: 2, name: "Source 2"}
    ]

    assert {:ok, result} =
             Scrypath.sync_related(DummySource, records,
               fan_out: :comments,
               sync_mode: :inline,
               backend: RecordingBackend
             )

    assert result.status == :completed
    assert result.mode == :inline

    assert_received {:upsert_documents, DummyTarget, documents, _config}
    assert length(documents) == 2
    assert Enum.map(documents, & &1.id) == [10, 20]
    assert Enum.map(documents, & &1.data[:title]) == ["Resolved for Source 1", "Resolved for Source 2"]
  end

  test "sync_mode: :oban enqueues a job" do
    records = [%DummySource{id: 3, name: "Source 3"}]

    assert {:ok, result} =
             Scrypath.sync_related(DummySource, records,
               fan_out: :comments,
               sync_mode: :oban,
               oban: EnqueueOban,
               oban_queue: :test_queue,
               backend: RecordingBackend
             )

    assert result.status == :accepted
    assert result.mode == :oban
    assert result.document_count == 1
    assert result.document_ids == [3]

    assert %{queue: :test_queue} = result.oban
  end

  test "missing fan_out raises ArgumentError" do
    assert_raise ArgumentError, "opts[:fan_out] is required", fn ->
      Scrypath.sync_related(DummySource, [%DummySource{id: 1}], backend: RecordingBackend)
    end
  end

  test "invalid fan_out key raises ArgumentError" do
    assert_raise ArgumentError, "fan_out :unknown is not configured on Scrypath.Sync.RelatedTest.DummySource", fn ->
      Scrypath.sync_related(DummySource, [%DummySource{id: 1}],
        fan_out: :unknown,
        backend: RecordingBackend
      )
    end
  end
end