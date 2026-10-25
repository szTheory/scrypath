defmodule Scrypath.Oban.EnqueueTest do
  use ExUnit.Case, async: true

  alias Scrypath.TestSupport.FakeRepo
  alias Scrypath.Operations.Result
  alias Scrypath.Operations.Task

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

    @impl true
    def search_facet_values(_schema, _facet, _query, _opts, _config) do
      {:error, :not_implemented}
    end
  end

  defmodule RecordingOban do
    def insert(changeset) do
      job = Ecto.Changeset.apply_changes(changeset)

      send(self(), {:oban_insert, job})

      {:ok, %{job | id: 901, state: "available"}}
    end
  end

  defmodule RetryableOban do
    def insert(changeset) do
      job = Ecto.Changeset.apply_changes(changeset)
      {:ok, %{job | id: 902, state: "retryable"}}
    end
  end

  defmodule CountingOban do
    def insert(changeset) do
      send(self(), {:inserted, changeset})
      job = Ecto.Changeset.apply_changes(changeset)

      {:ok, %{job | id: System.unique_integer([:positive]), state: "available"}}
    end
  end

  defmodule FailingSecondOban do
    def insert(changeset) do
      count = Process.get(:failing_second_oban_count, 0) + 1
      Process.put(:failing_second_oban_count, count)
      send(self(), {:inserted, changeset})

      if count == 2 do
        {:error, :boom}
      else
        job = Ecto.Changeset.apply_changes(changeset)
        {:ok, %{job | id: System.unique_integer([:positive]), state: "available"}}
      end
    end
  end

  defp oban_opts(oban) do
    [
      backend: RecordingBackend,
      sync_mode: :oban,
      repo: FakeRepo,
      oban: oban,
      oban_queue: :search_sync
    ]
  end

  defp inserted_id_lists do
    Stream.repeatedly(fn ->
      receive do
        {:inserted, changeset} -> Ecto.Changeset.get_field(changeset, :args)["document_ids"]
      after
        0 -> nil
      end
    end)
    |> Enum.take_while(&(&1 != nil))
  end

  describe "chunked enqueue (D-04)" do
    test "2,500 records under sync_mode: :oban enqueue three bounded jobs and one result" do
      records = Enum.map(2500..1//-1, &%SearchablePost{id: &1, title: "T#{&1}", body: "B"})

      assert {:ok, result} =
               Scrypath.sync_records(SearchablePost, records, oban_opts(CountingOban))

      id_lists = inserted_id_lists()
      assert length(id_lists) == 3
      assert Enum.all?(id_lists, &(length(&1) <= 1000))
      assert Enum.all?(id_lists, &(&1 == Enum.sort_by(&1, fn id -> to_string(id) end)))
      all_ids = Enum.concat(id_lists)
      assert length(all_ids) == 2500
      assert Enum.sort(all_ids) == Enum.to_list(1..2500)

      assert result.document_count == 2500
      assert result.status == :accepted
      assert length(result.tasks) == 3
      assert result.job == List.last(result.tasks)
      assert Enum.all?(result.tasks, &(&1.conflict? == false))
      assert Enum.uniq_by(result.tasks, & &1.id) |> length() == 3
    end

    test "2,500 ids under delete_documents enqueue three delete jobs and one result" do
      ids = Enum.to_list(1..2500)

      assert {:ok, result} =
               Scrypath.delete_documents(SearchablePost, ids, oban_opts(CountingOban))

      id_lists = inserted_id_lists()
      assert length(id_lists) == 3
      assert Enum.all?(id_lists, &(length(&1) <= 1000))
      assert Enum.sort(Enum.concat(id_lists)) == ids

      assert result.document_count == 2500
      assert length(result.tasks) == 3
      assert Enum.all?(result.tasks, &(&1.worker == "Scrypath.Oban.DeleteWorker"))
      assert result.job == List.last(result.tasks)
    end

    test "a failed chunk insert returns the bare error and stops later inserts" do
      ids = Enum.to_list(1..2500)

      assert {:error, :boom} =
               Scrypath.Oban.Enqueue.enqueue_upsert(
                 SearchablePost,
                 ids,
                 oban_opts(FailingSecondOban)
               )

      assert length(inserted_id_lists()) == 2
    end

    test "every chunk job carries the shared unique policy" do
      assert Scrypath.Oban.Enqueue.unique_opts() ==
               [period: :infinity, states: [:available, :scheduled, :retryable]]

      assert {:ok, _result} =
               Scrypath.Oban.Enqueue.enqueue_upsert(
                 SearchablePost,
                 Enum.to_list(1..1500),
                 oban_opts(CountingOban)
               )

      changesets =
        for _ <- 1..2 do
          assert_received {:inserted, changeset}
          changeset
        end

      for changeset <- changesets do
        unique = Ecto.Changeset.get_field(changeset, :unique)
        assert unique[:states] == [:available, :scheduled, :retryable]
        assert unique[:period] == :infinity
      end
    end

    test "a single chunk inserts once and keeps today's map plus one task" do
      records = [%SearchablePost{id: 2, title: "T", body: "B"}, %SearchablePost{id: 1}]

      assert {:ok, result} =
               Scrypath.sync_records(SearchablePost, records, oban_opts(CountingOban))

      assert [[1, 2]] = inserted_id_lists()
      assert result.document_ids == [1, 2]
      assert result.document_count == 2
      assert result.mode == :oban
      assert result.status == :accepted
      assert result.index =~ ~r/_searchable_post$/
      assert result.oban == %{queue: :search_sync, max_attempts: 8, name: CountingOban}
      assert result.job.conflict? == false
      assert result.job.worker == "Scrypath.Oban.UpsertWorker"
      assert result.tasks == [result.job]
    end
  end

  test "enqueue_upsert/3 inserts one job with the caller batch intact" do
    assert {:ok, %Result{} = result} =
             Scrypath.Oban.Enqueue.enqueue_upsert(SearchablePost, [11, 12],
               backend: RecordingBackend,
               sync_mode: :oban,
               repo: FakeRepo,
               oban: RecordingOban,
               oban_queue: :search_sync
             )

    assert result.document_ids == [11, 12]
    assert result.document_count == 2
    assert result.mode == :oban
    assert result.status == :accepted
    assert %Task{} = task = result.task
    assert task.id == 901
    assert task.kind == :queue_job
    assert task.state == :queued

    assert task.reference == %{
             job_id: 901,
             worker: "Scrypath.Oban.UpsertWorker",
             queue: "search_sync"
           }

    assert task.metadata.oban_state == "available"

    assert_received {:oban_insert, job}
    assert job.worker == "Scrypath.Oban.UpsertWorker"
    assert job.args["document_count"] == 2
    assert job.args["document_ids"] == [11, 12]
    assert job.args["repo"] == "Elixir.Scrypath.TestSupport.FakeRepo"
    refute Map.has_key?(job.args, "documents")
    assert job.unique[:states] == [:available, :scheduled, :retryable]
  end

  test "enqueue_upsert/3 fails at the call site when records cannot be loaded later" do
    assert_raise ArgumentError, ~r/needs :repo to load current records/, fn ->
      Scrypath.Oban.Enqueue.enqueue_upsert(SearchablePost, [11],
        backend: RecordingBackend,
        sync_mode: :oban,
        oban: RecordingOban,
        oban_queue: :search_sync
      )
    end
  end

  test "enqueue_delete/3 inserts one delete job with resolved ids only" do
    assert {:ok, %Result{} = result} =
             Scrypath.Oban.Enqueue.enqueue_delete(SearchablePost, ["post:7", "post:8"],
               backend: RecordingBackend,
               sync_mode: :oban,
               oban: RecordingOban,
               oban_queue: :search_sync,
               oban_max_attempts: 5
             )

    assert result.document_ids == ["post:7", "post:8"]
    assert result.document_count == 2
    assert result.mode == :oban
    assert result.status == :accepted
    assert %Task{} = task = result.task
    assert task.id == 901
    assert task.kind == :queue_job
    assert task.state == :queued

    assert task.reference == %{
             job_id: 901,
             worker: "Scrypath.Oban.DeleteWorker",
             queue: "search_sync"
           }

    assert task.metadata.oban_state == "available"

    assert_received {:oban_insert, job}
    assert job.worker == "Scrypath.Oban.DeleteWorker"
    assert job.args["document_count"] == 2
    assert job.args["document_ids"] == ["post:7", "post:8"]
    refute Map.has_key?(job.args, "documents")
  end

  test "enqueue dedupes ids in the form the job stores them (IN-01)" do
    assert {:ok, %Result{} = result} =
             Scrypath.Oban.Enqueue.enqueue_delete(SearchablePost, [:a, "a", 1, "1", :b],
               backend: RecordingBackend,
               sync_mode: :oban,
               oban: RecordingOban,
               oban_queue: :search_sync
             )

    assert_received {:oban_insert, job}
    assert job.args["document_ids"] == [1, "1", "a", "b"]
    assert job.args["document_count"] == 4
    assert result.document_ids == [1, "1", "a", "b"]
    assert result.document_count == 4
  end

  describe "ids the worker would cancel are rejected at enqueue (WR-06)" do
    test "sync_records/3 raises for a struct with id: nil and inserts nothing" do
      posts = [%SearchablePost{id: 1, title: "Saved"}, %SearchablePost{id: nil, title: "New"}]

      assert_raise ArgumentError, ~r/document ids must be integers or strings, got nil/, fn ->
        Scrypath.sync_records(SearchablePost, posts, oban_opts(RecordingOban))
      end

      refute_received {:oban_insert, _job}
    end

    test "delete_record/3 on a struct with id: nil is a noop, never an accepted job" do
      # List.wrap(nil) leaves no id, so there is nothing to delete and nothing to enqueue.
      assert {:ok, %{status: :noop, document_count: 0}} =
               Scrypath.delete_record(
                 SearchablePost,
                 %SearchablePost{id: nil},
                 oban_opts(RecordingOban)
               )

      refute_received {:oban_insert, _job}
    end

    test "delete_documents/3 raises for nil, float and boolean ids" do
      for bad <- [nil, 1.5, true] do
        assert_raise ArgumentError, ~r/must be integers or strings/, fn ->
          Scrypath.delete_documents(SearchablePost, [1, bad], oban_opts(RecordingOban))
        end
      end

      refute_received {:oban_insert, _job}
    end

    test "the Ecto.Multi helper rejects the same ids" do
      assert_raise ArgumentError, ~r/got nil/, fn ->
        Scrypath.Oban.enqueue_delete(
          Ecto.Multi.new(),
          :delete,
          SearchablePost,
          [nil],
          oban_opts(RecordingOban)
        )
      end
    end

    test "every id enqueue accepts decodes in the worker" do
      ids = Scrypath.Oban.Payload.serialize_ids!([1, "a", :b])
      assert ids == [1, "a", "b"]
      assert Enum.all?(ids, &Scrypath.Oban.JobArgs.document_id?/1)
    end
  end

  test "enqueue helpers keep retryable queue state distinct from backend lifecycle" do
    assert {:ok, %Result{} = result} =
             Scrypath.Oban.Enqueue.enqueue_upsert(SearchablePost, [21],
               backend: RecordingBackend,
               sync_mode: :oban,
               repo: FakeRepo,
               oban: RetryableOban,
               oban_queue: :search_sync
             )

    assert %Task{} = task = result.task
    assert task.kind == :queue_job
    assert task.state == :retrying
    assert task.metadata.oban_state == "retryable"
  end

  test "rejects an ephemeral Oban API key before job insertion" do
    assert_raise ArgumentError, ~r/must be configured durably/, fn ->
      Scrypath.Oban.Enqueue.enqueue_upsert(SearchablePost, [],
        backend: RecordingBackend,
        sync_mode: :oban,
        oban: RecordingOban,
        oban_queue: :search_sync,
        meilisearch_api_key: "ephemeral-key"
      )
    end

    refute_received {:oban_insert, _}
  end
end
