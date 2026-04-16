defmodule Scrypath.TelemetryTest do
  use ExUnit.Case, async: false

  alias Scrypath.SearchResult
  alias Scrypath.TestSupport.FakeRepo
  alias Scrypath.Meilisearch.Client
  alias Scrypath.Meilisearch.Tasks

  defmodule RecordingBackend do
    @behaviour Scrypath.Backend

    @impl true
    def name, do: :recording

    @impl true
    def index_name(_schema_module, config) do
      Keyword.get(config, :index_name, "telemetry_posts")
    end

    @impl true
    def upsert_documents(_schema_module, documents, _config) do
      {:ok, %{document_ids: Enum.map(documents, & &1.id)}}
    end

    @impl true
    def delete_documents(_schema_module, document_ids, _config) do
      {:ok, %{document_ids: document_ids}}
    end

    @impl true
    def search(_schema_module, _query, _config) do
      {:ok,
       %{
         "hits" => [
           %{"id" => 2, "title" => "Second"},
           %{"id" => 1, "title" => "First"},
           %{"id" => 3, "title" => "Missing"}
         ],
         "page" => 1,
         "hitsPerPage" => 3,
         "totalHits" => 3
       }}
    end
  end

  defmodule SequencedClient do
    def task(task_uid, config) do
      agent = Keyword.fetch!(config, :task_responses)

      Agent.get_and_update(agent, fn
        [next | rest] -> {next, rest}
        [] -> {{:ok, %{"uid" => task_uid, "status" => "succeeded"}}, []}
      end)
    end
  end

  setup do
    FakeRepo.reset()
    {:ok, agent} = Agent.start_link(fn -> [] end)
    %{task_responses: agent}
  end

  test "common sync emits span-based upsert and delete events with stable low-cardinality metadata" do
    events = capture_events([[:scrypath, :sync, :upsert], [:scrypath, :sync, :delete]], fn ->
      assert {:ok, %{document_ids: [1, 2], mode: :manual, status: :accepted}} =
               Scrypath.sync_records(SearchablePost, [
                 %SearchablePost{id: 1, title: "One", body: "First"},
                 %SearchablePost{id: 2, title: "Two", body: "Second"}
               ], backend: RecordingBackend, sync_mode: :manual)

      assert {:ok, %{document_ids: ["post:1", "post:2"], mode: :manual, status: :accepted}} =
               Scrypath.delete_documents(SearchablePost, ["post:1", "post:2"],
                 backend: RecordingBackend,
                 sync_mode: :manual
               )
    end)

    assert_event(events, [:scrypath, :sync, :upsert, :start], %{schema: SearchablePost})
    assert_event(events, [:scrypath, :sync, :upsert, :stop], %{schema: SearchablePost})
    assert_event(events, [:scrypath, :sync, :delete, :start], %{schema: SearchablePost})
    assert_event(events, [:scrypath, :sync, :delete, :stop], %{schema: SearchablePost})

    upsert_stop = find_event(events, [:scrypath, :sync, :upsert, :stop])
    delete_stop = find_event(events, [:scrypath, :sync, :delete, :stop])

    assert upsert_stop.metadata.backend == :recording
    assert upsert_stop.metadata.sync_mode == :manual
    assert upsert_stop.metadata.index == "telemetry_posts"
    assert upsert_stop.metadata.document_count == 2
    assert delete_stop.metadata.document_count == 2

    refute Map.has_key?(upsert_stop.metadata, :task_uid)
    refute Map.has_key?(upsert_stop.metadata, :poll_count)
    refute Map.has_key?(upsert_stop.metadata, :request_id)
  end

  test "search execution and hydration emit separate workflow spans without backend-specific detail" do
    FakeRepo.put_records([
      %QueryablePost{id: 1, title: "First"},
      %QueryablePost{id: 2, title: "Second"}
    ])

    events = capture_events([[:scrypath, :search], [:scrypath, :hydration]], fn ->
      assert {:ok,
              %SearchResult{
                records: [%QueryablePost{id: 2}, %QueryablePost{id: 1}],
                missing_ids: [3]
              }} =
               Scrypath.search(QueryablePost, "ecto",
                 backend: RecordingBackend,
                 repo: FakeRepo
               )
    end)

    search_stop = find_event(events, [:scrypath, :search, :stop])
    hydration_stop = find_event(events, [:scrypath, :hydration, :stop])

    assert search_stop.metadata.schema == QueryablePost
    assert search_stop.metadata.backend == :recording
    assert search_stop.metadata.index == "telemetry_posts"
    assert search_stop.metadata.hit_count == 3

    assert hydration_stop.metadata.schema == QueryablePost
    assert hydration_stop.metadata.repo == FakeRepo
    assert hydration_stop.metadata.hit_count == 3
    assert hydration_stop.metadata.record_count == 2
    assert hydration_stop.metadata.missing_count == 1

    refute Map.has_key?(search_stop.metadata, :task_uid)
    refute Map.has_key?(search_stop.metadata, :poll_count)
  end

  test "public telemetry stays batch-oriented rather than record-by-record" do
    events = capture_events([[:scrypath, :sync, :upsert]], fn ->
      assert {:ok, %{document_ids: [1, 2], mode: :manual}} =
               Scrypath.sync_records(SearchablePost, [
                 %SearchablePost{id: 1, title: "One", body: "First"},
                 %SearchablePost{id: 2, title: "Two", body: "Second"}
               ], backend: RecordingBackend, sync_mode: :manual)
    end)

    stop_events =
      Enum.filter(events, fn event ->
        event.name == [:scrypath, :sync, :upsert, :stop]
      end)

    assert length(stop_events) == 1
    assert hd(stop_events).metadata.document_count == 2
  end

  test "meilisearch request and task wait emit backend-specific spans", %{task_responses: agent} do
    Agent.update(agent, fn _ ->
      [
        {:ok, %{"uid" => 101, "status" => "processing", "type" => "documentAdditionOrUpdate"}},
        {:ok,
         %{
           "uid" => 101,
           "status" => "succeeded",
           "type" => "documentAdditionOrUpdate",
           "indexUid" => "telemetry_posts"
         }}
      ]
    end)

    client_events =
      capture_events([[:scrypath, :meilisearch, :request]], fn ->
        assert {:ok, %{"taskUid" => 301, "status" => "enqueued"}} =
                 Client.upsert_documents(
                   "telemetry_posts",
                   [
                     %Scrypath.Document{
                       id: 1,
                       data: %{title: "One", body: "First"},
                       source: :fields
                     }
                   ],
                   meilisearch_url: "http://localhost:7700",
                   req_options: [plug: {Req.Test, req_stub()}]
                 )
      end)

    request_stop = find_event(client_events, [:scrypath, :meilisearch, :request, :stop])
    assert request_stop.metadata.method == :post
    assert request_stop.metadata.path == "/indexes/telemetry_posts/documents"
    assert request_stop.metadata.status_code == 202
    assert request_stop.metadata.index == "telemetry_posts"

    wait_events =
      capture_events([[:scrypath, :meilisearch, :task_wait]], fn ->
        assert {:ok, %{uid: 101, status: :succeeded}} =
                 Tasks.wait_for_task(
                   %{uid: 101, status: "enqueued", type: "documentAdditionOrUpdate"},
                   meilisearch_client: SequencedClient,
                   task_responses: agent,
                   inline_poll_interval: 1,
                   inline_timeout: 50
                 )
      end)

    wait_stop = find_event(wait_events, [:scrypath, :meilisearch, :task_wait, :stop])
    assert wait_stop.metadata.task_uid == 101
    assert wait_stop.metadata.poll_count == 2
    assert wait_stop.metadata.final_status == :succeeded
  end

  test "docs explain the sync mode matrix and async lifecycle contract" do
    readme = File.read!("README.md")
    architecture = File.read!("ARCHITECTURE.md")

    assert readme =~ "requested -> enqueued -> processing -> backend_accepted -> completed | retrying | discarded"
    assert readme =~ "`sync_mode: :oban` means durable enqueue accepted, not search visibility completed."
    assert readme =~ "retries, discarded jobs, stale deletes, and drift are normal operational realities"

    assert architecture =~ "| `:inline` | waits for terminal backend task success before returning |"
    assert architecture =~ "| `:manual` | returns accepted backend work immediately |"
    assert architecture =~ "| `:oban` | returns durable enqueue acceptance only |"
  end

  defp capture_events(prefixes, fun) do
    parent = self()
    ref = make_ref()
    handler_id = "scrypath-telemetry-test-#{System.unique_integer([:positive])}"

    event_names =
      for prefix <- prefixes,
          suffix <- [:start, :stop, :exception] do
        prefix ++ [suffix]
      end

    :ok = :telemetry.attach_many(handler_id, event_names, &__MODULE__.handle_event/4, {parent, ref})

    fun.()

    :telemetry.detach(handler_id)

    receive_events(ref, [])
  end

  defp receive_events(ref, events) do
    receive do
      {^ref, event} -> receive_events(ref, [event | events])
    after
      50 -> Enum.reverse(events)
    end
  end

  defp find_event(events, name) do
    Enum.find(events, fn event -> event.name == name end) ||
      flunk("expected event #{inspect(name)}, got #{inspect(Enum.map(events, & &1.name))}")
  end

  defp assert_event(events, name, expected_metadata) do
    event = find_event(events, name)

    Enum.each(expected_metadata, fn {key, value} ->
      assert Map.get(event.metadata, key) == value
    end)

    event
  end

  def handle_event(event_name, measurements, metadata, {parent, ref}) do
    send(parent, {ref, %{name: event_name, measurements: measurements, metadata: metadata}})
  end

  defp req_stub do
    stub = Module.concat(__MODULE__, "ReqStub#{System.unique_integer([:positive])}")

    Req.Test.stub(stub, fn conn ->
      case {conn.method, conn.request_path} do
        {"POST", path} ->
          [_, index_name, _] = String.split(path, "/", trim: true)

          conn
          |> Plug.Conn.put_status(202)
          |> Req.Test.json(%{
            "taskUid" => 301,
            "indexUid" => index_name,
            "status" => "enqueued",
            "type" => "documentAdditionOrUpdate"
          })

        {"GET", "/tasks/301"} ->
          Req.Test.json(conn, %{"uid" => 301, "status" => "succeeded"})
      end
    end)

    stub
  end
end
