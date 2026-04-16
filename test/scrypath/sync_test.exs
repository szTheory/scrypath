defmodule Scrypath.SyncTest do
  use ExUnit.Case, async: true

  alias Scrypath.Config
  alias Scrypath.Document

  defmodule HookedIdentityPost do
    use Ecto.Schema

    use Scrypath, fields: [:title], document_id: :external_id

    embedded_schema do
      field(:external_id, :string)
      field(:legacy_id, :string)
      field(:title, :string)
    end

    def search_document(_post) do
      raise "delete identity should not require search_document/1"
    end

    def search_document_id(%__MODULE__{legacy_id: legacy_id}) when is_binary(legacy_id),
      do: legacy_id
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

  defmodule ReadyOban do
  end

  setup do
    {:ok, agent} = Agent.start_link(fn -> [] end)
    %{task_responses: agent}
  end

  defp req_stub(agent) do
    stub = Module.concat(__MODULE__, "ReqStub#{System.unique_integer([:positive])}")

    Req.Test.stub(stub, fn conn ->
      send(self(), {:meili_request, conn.method, conn.request_path, conn.body_params})

      case {conn.method, conn.request_path} do
        {"POST", path} ->
          [_, index_name, _] = String.split(path, "/", trim: true)

          Req.Test.json(conn, %{
            "taskUid" => 301,
            "indexUid" => index_name,
            "status" => "enqueued",
            "type" => "documentAdditionOrUpdate"
          })

        {"GET", "/tasks/301"} ->
          case Agent.get_and_update(agent, fn
                 [next | rest] -> {next, rest}
                 [] -> {{:ok, %{"uid" => 301, "status" => "succeeded"}}, []}
               end) do
            {:ok, body} ->
              Req.Test.json(conn, body)

            {:error, {status, body}} ->
              conn |> Plug.Conn.put_status(status) |> Req.Test.json(body)
          end
      end
    end)

    stub
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

    assert {:ok, %{document_ids: [1, 2], sync_mode: :manual, mode: :manual, status: :accepted}} =
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

    assert {:ok, %{document_ids: [10], sync_mode: :inline, mode: :inline, status: :completed}} =
             Scrypath.delete_record(SearchablePost, record, backend: RecordingBackend)

    assert_received {:delete_documents, SearchablePost, [10], inline_config}
    assert inline_config[:sync_mode] == :inline

    assert {:ok,
            %{document_ids: ["post:11"], sync_mode: :manual, mode: :manual, status: :accepted}} =
             Scrypath.delete_document(SearchablePost, "post:11",
               backend: RecordingBackend,
               sync_mode: :manual
             )

    assert_received {:delete_documents, SearchablePost, ["post:11"], manual_config}
    assert manual_config[:sync_mode] == :manual

    assert {:ok,
            %{
              document_ids: ["post:12", "post:13"],
              sync_mode: :inline,
              mode: :inline,
              status: :completed
            }} =
             Scrypath.delete_documents(SearchablePost, ["post:12", "post:13"],
               backend: RecordingBackend
             )

    assert_received {:delete_documents, SearchablePost, ["post:12", "post:13"], _}
  end

  test "delete_record/3 resolves ids without calling search_document/1" do
    record = %HookedIdentityPost{external_id: "db-42", legacy_id: "legacy-42", title: "Ignored"}

    assert {:ok, %{document_ids: ["legacy-42"], sync_mode: :inline}} =
             Scrypath.delete_record(HookedIdentityPost, record, backend: RecordingBackend)

    assert_received {:delete_documents, HookedIdentityPost, ["legacy-42"], _}
  end

  test "inline sync waits for terminal backend task success", %{task_responses: agent} do
    Agent.update(agent, fn _ ->
      [
        {:ok, %{"uid" => 301, "status" => "processing"}},
        {:ok,
         %{
           "uid" => 301,
           "status" => "succeeded",
           "indexUid" => "tenant_searchable_post",
           "type" => "documentAdditionOrUpdate"
         }}
      ]
    end)

    record = %SearchablePost{id: 77, title: "Inline", body: "Success"}

    assert {:ok,
            %{
              mode: :inline,
              status: :completed,
              task: %{uid: 301, status: :succeeded, index_uid: "tenant_searchable_post"}
            }} =
             Scrypath.sync_record(SearchablePost, record,
               backend: Scrypath.Meilisearch,
               index_prefix: "tenant",
               meilisearch_url: "http://localhost:7700",
               req_options: [plug: {Req.Test, req_stub(agent)}],
               inline_poll_interval: 1,
               inline_timeout: 50
             )

    assert_received {:meili_request, "POST", "/indexes/tenant_searchable_post/documents", _}
    assert_received {:meili_request, "GET", "/tasks/301", %{}}
  end

  test "inline timeout returns a distinct error tuple", %{task_responses: agent} do
    Agent.update(agent, fn _ ->
      List.duplicate({:ok, %{"uid" => 301, "status" => "processing"}}, 5)
    end)

    record = %SearchablePost{id: 78, title: "Inline", body: "Timeout"}

    assert {:error, {:timeout, %{uid: 301, status: :processing}}} =
             Scrypath.sync_record(SearchablePost, record,
               backend: Scrypath.Meilisearch,
               meilisearch_url: "http://localhost:7700",
               req_options: [plug: {Req.Test, req_stub(agent)}],
               inline_poll_interval: 5,
               inline_timeout: 10
             )
  end

  test "inline backend failure stays distinct while manual mode remains non-waiting", %{
    task_responses: agent
  } do
    Agent.update(agent, fn _ ->
      [
        {:ok,
         %{
           "uid" => 301,
           "status" => "failed",
           "error" => %{"code" => "index_not_found"}
         }}
      ]
    end)

    record = %SearchablePost{id: 79, title: "Inline", body: "Failure"}

    assert {:error, {:task_failed, %{uid: 301, status: :failed, raw: raw}}} =
             Scrypath.sync_record(SearchablePost, record,
               backend: Scrypath.Meilisearch,
               meilisearch_url: "http://localhost:7700",
               req_options: [plug: {Req.Test, req_stub(agent)}],
               inline_poll_interval: 1,
               inline_timeout: 50
             )

    assert raw["error"]["code"] == "index_not_found"

    assert {:ok, %{mode: :manual, status: :accepted, task: %{uid: 301, status: "enqueued"}}} =
             Scrypath.sync_record(SearchablePost, record,
               backend: Scrypath.Meilisearch,
               meilisearch_url: "http://localhost:7700",
               req_options: [plug: {Req.Test, req_stub(agent)}],
               sync_mode: :manual
             )
  end

  test "manual and inline share verbs while producing different completion states", %{
    task_responses: agent
  } do
    Agent.update(agent, fn _ ->
      [
        {:ok,
         %{
           "uid" => 301,
           "status" => "succeeded",
           "indexUid" => "scrypath_searchable_post",
           "type" => "documentAdditionOrUpdate"
         }}
      ]
    end)

    record = %SearchablePost{id: 81, title: "Shared", body: "Verb"}

    assert {:ok, %{mode: :manual, status: :accepted, task: %{status: "enqueued"}}} =
             Scrypath.sync_record(SearchablePost, record,
               backend: Scrypath.Meilisearch,
               meilisearch_url: "http://localhost:7700",
               req_options: [plug: {Req.Test, req_stub(agent)}],
               sync_mode: :manual
             )

    assert {:ok, %{mode: :inline, status: :completed, task: %{status: :succeeded}}} =
             Scrypath.sync_record(SearchablePost, record,
               backend: Scrypath.Meilisearch,
               meilisearch_url: "http://localhost:7700",
               req_options: [plug: {Req.Test, req_stub(agent)}],
               inline_poll_interval: 1,
               inline_timeout: 50
             )
  end

  test "sync_mode :oban stays on shared sync verbs and returns accepted metadata" do
    records = [
      %SearchablePost{id: 1, title: "One", body: "First"},
      %SearchablePost{id: 2, title: "Two", body: "Second"}
    ]

    assert {:ok, %{mode: :oban, status: :accepted, document_ids: [1, 2]}} =
             Scrypath.sync_records(SearchablePost, records,
               backend: RecordingBackend,
               sync_mode: :oban,
               oban: ReadyOban,
               oban_queue: :search_sync
             )

    refute_received {:upsert_documents, _, _, _}

    assert {:ok, %{mode: :oban, status: :accepted, document_ids: ["post:2", "post:3"]}} =
             Scrypath.delete_documents(SearchablePost, ["post:2", "post:3"],
               backend: RecordingBackend,
               sync_mode: :oban,
               oban: ReadyOban,
               oban_queue: :search_sync
             )

    refute_received {:delete_documents, _, _, _}
  end

  test "sync_mode :oban fails clearly when the dependency is unavailable" do
    record = %SearchablePost{id: 91, title: "Queued", body: "Missing"}

    assert_raise ArgumentError,
                 "configured Oban instance MissingOban is not available for sync_mode :oban",
                 fn ->
                   Scrypath.sync_record(SearchablePost, record,
                     backend: RecordingBackend,
                     sync_mode: :oban,
                     oban: MissingOban,
                     oban_queue: :search_sync
                   )
                 end
  end

  test "sync_mode :oban requires explicit queue configuration" do
    assert_raise ArgumentError,
                 "oban_queue is required when sync_mode is :oban",
                 fn ->
                   Config.resolve!(
                     backend: RecordingBackend,
                     sync_mode: :oban
                   )
                 end
  end

  test "inline cancellation returns a distinct cancellation tuple", %{task_responses: agent} do
    Agent.update(agent, fn _ ->
      [
        {:ok, %{"uid" => 301, "status" => "canceled", "canceledBy" => %{"uid" => 9}}}
      ]
    end)

    record = %SearchablePost{id: 80, title: "Inline", body: "Cancelled"}

    assert {:error, {:cancelled, %{uid: 301, status: :cancelled, raw: raw}}} =
             Scrypath.sync_record(SearchablePost, record,
               backend: Scrypath.Meilisearch,
               meilisearch_url: "http://localhost:7700",
               req_options: [plug: {Req.Test, req_stub(agent)}],
               inline_poll_interval: 1,
               inline_timeout: 50
             )

    assert raw["canceledBy"]["uid"] == 9
  end
end
