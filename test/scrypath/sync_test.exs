defmodule Scrypath.SyncTest do
  use ExUnit.Case, async: true

  alias Scrypath.Config
  alias Scrypath.Document
  alias Scrypath.Operations.Result
  alias Scrypath.Operations.Task

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

  defmodule SeamBackend do
    @behaviour Scrypath.Backend

    @impl true
    def name, do: :seam_backend

    @impl true
    def index_name(schema_module, config) do
      prefix = Keyword.get(config, :index_prefix, "scrypath")
      schema_name = schema_module |> Module.split() |> List.last() |> Macro.underscore()

      "#{prefix}_#{schema_name}"
    end

    @impl true
    def upsert_documents(schema_module, documents, config) do
      task_state =
        if Keyword.get(config, :sync_mode, :inline) == :inline, do: :succeeded, else: :enqueued

      {:ok,
       Result.new(
         mode: Keyword.get(config, :sync_mode, :manual),
         status: :accepted,
         document_ids: Enum.map(documents, & &1.id),
         document_count: length(documents),
         task:
           Task.new(
             source: :meilisearch,
             kind: :backend_task,
             id: 711,
             state: task_state,
             reference: %{task_uid: 711, index_uid: index_name(schema_module, config)},
             metadata: %{type: "documentAdditionOrUpdate"},
             raw: %{"uid" => 711, "status" => Atom.to_string(task_state)}
           ),
         metadata: %{index: index_name(schema_module, config)}
       )}
    end

    @impl true
    def delete_documents(schema_module, document_ids, config) do
      task_state =
        if Keyword.get(config, :sync_mode, :inline) == :inline, do: :succeeded, else: :enqueued

      {:ok,
       Result.new(
         mode: Keyword.get(config, :sync_mode, :manual),
         status: :accepted,
         document_ids: document_ids,
         document_count: length(document_ids),
         task:
           Task.new(
             source: :meilisearch,
             kind: :backend_task,
             id: 712,
             state: task_state,
             reference: %{task_uid: 712, index_uid: index_name(schema_module, config)},
             metadata: %{type: "documentDeletion"},
             raw: %{"uid" => 712, "status" => Atom.to_string(task_state)}
           ),
         metadata: %{index: index_name(schema_module, config)}
       )}
    end

    @impl true
    def search(_schema_module, _query, _config), do: {:ok, %{hits: []}}
  end

  defmodule FutureBackend do
    @behaviour Scrypath.Backend

    @impl true
    def name, do: :future_backend

    @impl true
    def index_name(schema_module, config) do
      SeamBackend.index_name(schema_module, config)
    end

    @impl true
    def upsert_documents(schema_module, documents, config) do
      {:ok,
       Result.new(
         mode: Keyword.get(config, :sync_mode, :manual),
         status: :accepted,
         document_ids: Enum.map(documents, & &1.id),
         document_count: length(documents),
         task:
           Task.new(
             source: :future_backend,
             kind: :backend_task,
             id: 811,
             state: :enqueued,
             reference: %{task_uid: 811, index_uid: index_name(schema_module, config)},
             metadata: %{type: "documentAdditionOrUpdate"}
           ),
         metadata: %{index: index_name(schema_module, config)}
       )}
    end

    @impl true
    def delete_documents(schema_module, document_ids, config) do
      {:ok,
       Result.new(
         mode: Keyword.get(config, :sync_mode, :manual),
         status: :accepted,
         document_ids: document_ids,
         document_count: length(document_ids),
         task:
           Task.new(
             source: :future_backend,
             kind: :backend_task,
             id: 812,
             state: :enqueued,
             reference: %{task_uid: 812, index_uid: index_name(schema_module, config)},
             metadata: %{type: "documentDeletion"}
           ),
         metadata: %{index: index_name(schema_module, config)}
       )}
    end

    @impl true
    def search(_schema_module, _query, _config), do: {:ok, %{hits: []}}
  end

  defmodule ReadyOban do
  end

  defmodule EnqueueOban do
    def insert(changeset) do
      job = Ecto.Changeset.apply_changes(changeset)

      send(self(), {:oban_insert, job})

      {:ok, %{job | id: 501, state: "available"}}
    end
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

    assert {:ok, %{mode: :manual, status: :accepted, task: %{uid: 301, status: :enqueued}}} =
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

    assert {:ok, %{mode: :manual, status: :accepted, task: %{status: :enqueued}}} =
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

  test "sync adapts seam-owned backend results back into the public task map contract" do
    record = %SearchablePost{id: 82, title: "Seam", body: "Backend"}

    assert {:ok,
            %{
              mode: :manual,
              status: :accepted,
              index: "tenant_searchable_post",
              document_ids: [82],
              document_count: 1,
              task: %{uid: 711, status: :enqueued, index_uid: "tenant_searchable_post"}
            }} =
             Scrypath.sync_record(SearchablePost, record,
               backend: SeamBackend,
               index_prefix: "tenant",
               sync_mode: :manual
             )

    assert {:ok,
            %{
              mode: :inline,
              status: :completed,
              task: %{uid: 711, status: :succeeded, index_uid: "tenant_searchable_post"}
            }} =
             Scrypath.sync_record(SearchablePost, record,
               backend: SeamBackend,
               index_prefix: "tenant"
             )
  end

  test "inline sync does not route non-meilisearch seam tasks into meilisearch waiting" do
    record = %SearchablePost{id: 83, title: "Future", body: "Backend"}

    assert {:ok,
            %{
              mode: :inline,
              status: :completed,
              index: "tenant_searchable_post",
              task: %{uid: 811, status: :enqueued, index_uid: "tenant_searchable_post"}
            }} =
             Scrypath.sync_record(SearchablePost, record,
               backend: FutureBackend,
               index_prefix: "tenant"
             )

    refute_received {:meili_request, _, _, _}
  end

  test "sync_mode :oban stays on shared sync verbs and returns accepted metadata" do
    records = [
      %SearchablePost{id: 1, title: "One", body: "First"},
      %SearchablePost{id: 2, title: "Two", body: "Second"}
    ]

    assert {:ok,
            %{
              mode: :oban,
              status: :accepted,
              document_ids: [1, 2],
              document_count: 2,
              job: %{
                id: 501,
                worker: "Scrypath.Oban.UpsertWorker",
                queue: "search_sync",
                state: "available"
              }
            }} =
             Scrypath.sync_records(SearchablePost, records,
               backend: RecordingBackend,
               sync_mode: :oban,
               oban: EnqueueOban,
               oban_queue: :search_sync
             )

    assert_received {:oban_insert, upsert_job}
    assert upsert_job.args["document_ids"] == [1, 2]
    assert Enum.map(upsert_job.args["documents"], & &1["id"]) == [1, 2]
    refute_received {:upsert_documents, _, _, _}

    assert {:ok,
            %{
              mode: :oban,
              status: :accepted,
              document_ids: ["post:2", "post:3"],
              document_count: 2,
              job: %{
                id: 501,
                worker: "Scrypath.Oban.DeleteWorker",
                queue: "search_sync",
                state: "available"
              }
            }} =
             Scrypath.delete_documents(SearchablePost, ["post:2", "post:3"],
               backend: RecordingBackend,
               sync_mode: :oban,
               oban: EnqueueOban,
               oban_queue: :search_sync
             )

    assert_received {:oban_insert, delete_job}
    assert delete_job.args["document_ids"] == ["post:2", "post:3"]
    refute Map.has_key?(delete_job.args, "documents")
    refute_received {:delete_documents, _, _, _}
  end

  test "empty sync and delete batches return a no-op envelope across inline, manual, and oban" do
    for mode <- [:inline, :manual, :oban] do
      opts =
        [backend: RecordingBackend, sync_mode: mode]
        |> maybe_put_oban(mode)

      assert {:ok, %{mode: ^mode, status: :noop, document_ids: [], document_count: 0}} =
               Scrypath.sync_records(SearchablePost, [], opts)

      refute_received {:upsert_documents, _, _, _}
      refute_received {:oban_insert, _}

      assert {:ok, %{mode: ^mode, status: :noop, document_ids: [], document_count: 0}} =
               Scrypath.delete_documents(SearchablePost, [], opts)

      refute_received {:delete_documents, _, _, _}
      refute_received {:oban_insert, _}
    end
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

  test "mix project keeps Oban optional" do
    oban_dep =
      Scrypath.MixProject.project()[:deps]
      |> Enum.find(fn
        {:oban, _requirement, _opts} -> true
        _other -> false
      end)

    assert {:oban, "~> 2.21", opts} = oban_dep
    assert Keyword.get(opts, :optional) == true
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

  defp maybe_put_oban(opts, :oban) do
    Keyword.merge(opts, oban: EnqueueOban, oban_queue: :search_sync)
  end

  defp maybe_put_oban(opts, _mode), do: opts
end
