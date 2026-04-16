defmodule Scrypath.ObanTest do
  use ExUnit.Case, async: true

  alias Ecto.Multi

  defmodule NamedOban do
    use Oban, otp_app: :scrypath

    def insert(%Multi{} = multi, multi_name, changeset, opts \\ []) do
      send(self(), {:named_oban_insert, multi_name, changeset, opts})

      Ecto.Multi.run(multi, multi_name, fn _repo, _changes ->
        {:ok, Ecto.Changeset.apply_changes(changeset)}
      end)
    end
  end

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
    def insert(%Multi{} = multi, multi_name, changeset, _opts \\ []) do
      Ecto.Multi.run(multi, multi_name, fn _repo, _changes ->
        {:ok, Ecto.Changeset.apply_changes(changeset)}
      end)
    end
  end

  test "exposes only narrow Ecto.Multi enqueue helpers" do
    assert Code.ensure_loaded?(Scrypath.Oban)
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
        oban: RecordingOban,
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
        oban: RecordingOban,
        oban_queue: :search_sync
      )

    assert %Multi{} = multi
    assert [:search_delete] == Enum.map(Ecto.Multi.to_list(multi), &elem(&1, 0))
  end

  test "enqueue_upsert/5 uses the named Oban module multi insert signature" do
    multi =
      Multi.new()
      |> Scrypath.Oban.enqueue_upsert(
        :search_sync,
        SearchablePost,
        [%SearchablePost{id: 7, title: "Queued", body: "Body"}],
        backend: RecordingBackend,
        sync_mode: :oban,
        oban: NamedOban,
        oban_queue: :search_sync
      )

    assert %Multi{} = multi
    assert_received {:named_oban_insert, :search_sync, changeset, []}
    assert changeset.changes.worker == "Scrypath.Oban.UpsertWorker"
  end

  test "Oban integration sources compile without Oban on the code path" do
    script = """
    Code.put_compiler_option(:ignore_module_conflict, true)

    Path.wildcard("_build/test/lib/*/ebin")
    |> Enum.reject(&String.contains?(&1, "/oban/"))
    |> Enum.each(fn path -> Code.append_path(String.to_charlist(Path.expand(path))) end)

    for file <- [
      "lib/scrypath/config.ex",
      "lib/scrypath/oban/enqueue.ex",
      "lib/scrypath/oban/upsert_worker.ex",
      "lib/scrypath/oban/delete_worker.ex",
      "lib/scrypath/oban.ex"
    ] do
      Code.compile_file(file)
    end

    IO.puts("compile_without_oban_ok")
    """

    assert {"compile_without_oban_ok\n", 0} =
             System.cmd("elixir", ["-e", script], cd: File.cwd!(), stderr_to_stdout: true)
  end
end
