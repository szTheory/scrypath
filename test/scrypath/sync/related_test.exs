defmodule Scrypath.Sync.RelatedTest do
  use ExUnit.Case, async: true

  alias Scrypath.TestSupport.FakeRepo

  defmodule DummyTarget do
    use Ecto.Schema

    @primary_key {:id, :id, autogenerate: true}
    schema "dummy_targets" do
      field(:title, :string)
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
      field(:name, :string)
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

  defmodule OrdinarySource do
    use Ecto.Schema

    use Scrypath,
      fields: [:name],
      fan_outs: [
        comments: [
          target: DummyTarget,
          resolver: {__MODULE__, :resolve_comments, [:extra_arg]}
        ]
      ]

    @primary_key {:id, :id, autogenerate: true}
    schema "ordinary_sources" do
      field(:name, :string)
    end

    def resolve_comments([_ | _] = records, :extra_arg) do
      Enum.map(records, &%DummyTarget{id: &1.id * 100, title: "Ordinary for #{&1.name}"})
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

  # Keeps the raw changeset so tests can read unique: and gives every job its own id.
  defmodule CountingOban do
    def insert(changeset) do
      send(self(), {:oban_changeset, changeset})
      job = Ecto.Changeset.apply_changes(changeset)
      {:ok, %{job | id: System.unique_integer([:positive]), state: "available"}}
    end
  end

  defp oban_opts(extra) do
    [
      fan_out: :comments,
      sync_mode: :oban,
      oban: CountingOban,
      oban_queue: :test_queue,
      backend: RecordingBackend
    ] ++ extra
  end

  defp inserted_changesets do
    Stream.repeatedly(fn ->
      receive do
        {:oban_changeset, changeset} -> changeset
      after
        0 -> nil
      end
    end)
    |> Enum.take_while(&(&1 != nil))
  end

  describe "sync_mode: :oban related enqueue" do
    test "raises at the call site when triggers cannot be loaded (no repo, no search_records/2)" do
      assert_raise ArgumentError, ~r/needs :repo/, fn ->
        Scrypath.sync_related(DummySource, [%DummySource{id: 1, name: "S"}], oban_opts([]))
      end

      refute_received {:oban_changeset, _changeset}
    end

    test "2,500 triggers enqueue three bounded, sorted, disjoint RelatedWorker jobs" do
      records = Enum.map(2500..1//-1, &%DummySource{id: &1, name: "S#{&1}"})

      assert {:ok, result} =
               Scrypath.sync_related(DummySource, records, oban_opts(repo: FakeRepo))

      changesets = inserted_changesets()
      assert length(changesets) == 3

      id_lists =
        Enum.map(changesets, &(Ecto.Changeset.get_field(&1, :args) |> Map.fetch!("document_ids")))

      assert Enum.all?(id_lists, &(length(&1) <= 1000))
      assert Enum.all?(id_lists, &(&1 == Enum.sort_by(&1, fn id -> to_string(id) end)))
      all_ids = Enum.concat(id_lists)
      assert length(all_ids) == length(Enum.uniq(all_ids))
      assert Enum.sort(all_ids) == Enum.to_list(1..2500)

      assert Enum.all?(
               changesets,
               &(Ecto.Changeset.get_field(&1, :worker) == "Scrypath.Sync.RelatedWorker")
             )

      assert result.document_count == 2500
      assert [_, _, _] = result.tasks
    end

    test "every related job carries the shared unique policy" do
      assert {:ok, _result} =
               Scrypath.sync_related(
                 DummySource,
                 [%DummySource{id: 2, name: "S2"}, %DummySource{id: 1, name: "S1"}],
                 oban_opts(repo: FakeRepo)
               )

      assert [changeset] = inserted_changesets()
      unique = Ecto.Changeset.get_field(changeset, :unique)
      assert unique[:states] == [:available, :scheduled, :retryable]
      assert unique[:period] == :infinity
      assert Ecto.Changeset.get_field(changeset, :args)["document_ids"] == [1, 2]
    end

    test "related job ids are deduped in the form the job stores them (IN-01)" do
      assert {:ok, result} =
               Scrypath.sync_related(
                 DummySource,
                 [%DummySource{id: :a, name: "A"}, %DummySource{id: "a", name: "A2"}],
                 oban_opts(repo: FakeRepo)
               )

      assert [changeset] = inserted_changesets()
      assert Ecto.Changeset.get_field(changeset, :args)["document_ids"] == ["a"]
      assert result.document_count == 1
    end

    test "related job args keep the 0.3.17 shape" do
      assert {:ok, _result} =
               Scrypath.sync_related(
                 DummySource,
                 [%DummySource{id: 1, name: "S1"}],
                 oban_opts(repo: FakeRepo)
               )

      assert [changeset] = inserted_changesets()
      args = Ecto.Changeset.get_field(changeset, :args)
      assert args |> Map.keys() |> Enum.sort() == ["document_ids", "fan_out", "opts", "schema"]
      # Atom-keyed until Oban's JSON round trip turns the keys into strings.
      assert args["opts"][:repo] == to_string(FakeRepo)
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

    assert Enum.map(documents, & &1.data[:title]) == [
             "Resolved for Source 1",
             "Resolved for Source 2"
           ]
  end

  test "sync_mode: :oban enqueues a job" do
    records = [%DummySource{id: 3, name: "Source 3"}]

    assert {:ok, result} =
             Scrypath.sync_related(DummySource, records,
               fan_out: :comments,
               sync_mode: :oban,
               oban: EnqueueOban,
               oban_queue: :test_queue,
               repo: FakeRepo,
               backend: RecordingBackend
             )

    assert result.status == :accepted
    assert result.mode == :oban
    assert result.document_count == 1
    assert result.document_ids == [3]

    assert %{queue: :test_queue} = result.oban
    assert_received {:oban_insert, job}
    assert job.queue == "test_queue"
    assert job.args["document_ids"] == [3]
    assert job.args["fan_out"] == "comments"
    refute Map.has_key?(job.args["opts"], "meilisearch_api_key")
  end

  test "generated use Scrypath fan_out metadata is consumed for inline sync_related/3" do
    records = [
      %OrdinarySource{id: 7, name: "Source 7"},
      %OrdinarySource{id: 8, name: "Source 8"}
    ]

    assert {:ok, result} =
             Scrypath.sync_related(OrdinarySource, records,
               fan_out: :comments,
               sync_mode: :inline,
               backend: RecordingBackend
             )

    assert result.status == :completed
    assert result.mode == :inline

    assert_received {:upsert_documents, DummyTarget, documents, _config}
    assert Enum.map(documents, & &1.id) == [700, 800]

    assert Enum.map(documents, & &1.data[:title]) == [
             "Ordinary for Source 7",
             "Ordinary for Source 8"
           ]
  end

  test "generated use Scrypath fan_out metadata is consumed for oban enqueue" do
    records = [%OrdinarySource{id: 9, name: "Source 9"}]

    assert {:ok, result} =
             Scrypath.sync_related(OrdinarySource, records,
               fan_out: :comments,
               sync_mode: :oban,
               oban: EnqueueOban,
               oban_queue: :test_queue,
               repo: FakeRepo,
               backend: RecordingBackend
             )

    assert result.status == :accepted
    assert result.mode == :oban
    assert result.document_ids == [9]
    assert result.document_count == 1

    assert_received {:oban_insert, job}
    assert job.queue == "test_queue"
    assert job.args["document_ids"] == [9]
    assert job.args["fan_out"] == "comments"
  end

  test "Oban related sync rejects an ephemeral API key before insertion" do
    assert_raise ArgumentError, ~r/must be configured durably/, fn ->
      Scrypath.sync_related(DummySource, [%DummySource{id: 3, name: "Source 3"}],
        fan_out: :comments,
        sync_mode: :oban,
        oban: EnqueueOban,
        oban_queue: :test_queue,
        repo: FakeRepo,
        backend: RecordingBackend,
        meilisearch_api_key: "ephemeral-key"
      )
    end

    refute_received {:oban_insert, _job}
  end

  test "missing fan_out raises ArgumentError" do
    assert_raise ArgumentError, "opts[:fan_out] is required", fn ->
      Scrypath.sync_related(DummySource, [%DummySource{id: 1}], backend: RecordingBackend)
    end
  end

  test "invalid fan_out key raises ArgumentError" do
    assert_raise ArgumentError,
                 "fan_out :unknown is not configured on Scrypath.Sync.RelatedTest.DummySource",
                 fn ->
                   Scrypath.sync_related(DummySource, [%DummySource{id: 1}],
                     fan_out: :unknown,
                     backend: RecordingBackend
                   )
                 end
  end
end
