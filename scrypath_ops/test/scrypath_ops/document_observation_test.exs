defmodule ScrypathOps.DocumentObservationTest do
  use ExUnit.Case, async: true

  alias ScrypathOps.DocumentObservation

  @index "articles"
  @base_url "http://meili.example.test:7700"

  test "returns running for enqueued or processing tasks without making requests" do
    for status <- ["enqueued", "processing"] do
      result = DocumentObservation.check(receipt(), task(status), [])

      assert {:ok, %{state: :running, reason: :task_in_progress, checked_at: %DateTime{}}} =
               result
    end
  end

  test "returns failed for a failed task and unknown for unrecognized status" do
    assert {:ok, %{state: :failed, reason: :task_failed}} =
             DocumentObservation.check(receipt(), task("failed"), [])

    assert {:ok, %{state: :unknown, reason: :unknown_task_status}} =
             DocumentObservation.check(receipt(), task("canceled"), [])
  end

  test "accepts atom keyed task payloads" do
    assert {:ok, %{state: :failed, reason: :task_failed}} =
             DocumentObservation.check(receipt(), %{uid: 42, status: :failed}, [])
  end

  test "verifies exact projected JSON, including a configured document id field" do
    stub = stub_name("ExactProjection")

    Req.Test.stub(stub, fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/indexes/articles/documents/a%2Fb%20%3F%23"
      assert Plug.Conn.get_req_header(conn, "x-meili-api-key") == ["secret"]
      json(conn, 200, %{"slug" => "a/b ?#", "title" => "Hello", "nested" => %{"enabled" => true}})
    end)

    doc_receipt =
      receipt(
        operation: :upsert,
        expected: [%{id: "a/b ?#", data: %{title: "Hello", nested: %{enabled: true}}}]
      )

    assert {:ok, %{state: :verified, reason: nil, evidence: %{expected_count: 1}}} =
             DocumentObservation.check(
               doc_receipt,
               task("succeeded"),
               opts(stub, document_id_field: :slug)
             )
  end

  test "marks an exact-field mismatch and missing upsert document as failed" do
    mismatch_stub = stub_name("Mismatch")

    Req.Test.stub(mismatch_stub, fn conn ->
      json(conn, 200, %{"id" => 1, "title" => "stale", "extra" => true})
    end)

    assert {:ok, %{state: :failed, reason: :document_mismatch}} =
             DocumentObservation.check(
               receipt(expected: [%{id: 1, data: %{title: "new"}}]),
               task("succeeded"),
               opts(mismatch_stub)
             )

    missing_stub = stub_name("Missing")
    Req.Test.stub(missing_stub, fn conn -> json(conn, 404, %{"code" => "document_not_found"}) end)

    assert {:ok, %{state: :failed, reason: :document_not_found}} =
             DocumentObservation.check(
               receipt(expected: [%{id: 1, data: %{title: "new"}}]),
               task("succeeded"),
               opts(missing_stub)
             )
  end

  test "permits backend managed fields while comparing every expected projected value" do
    stub = stub_name("ManagedFields")

    Req.Test.stub(stub, fn conn ->
      json(conn, 200, %{"id" => 1, "title" => "Hello", "_formatted" => %{}})
    end)

    assert {:ok, %{state: :verified}} =
             DocumentObservation.check(
               receipt(expected: [%{id: 1, data: %{title: "Hello"}}]),
               task("succeeded"),
               opts(stub)
             )
  end

  test "distinguishes missing index from missing document for delete proof" do
    missing_index = stub_name("MissingIndex")

    Req.Test.stub(missing_index, fn conn ->
      assert conn.request_path == "/indexes/articles"
      json(conn, 404, %{"code" => "index_not_found"})
    end)

    assert {:ok, %{state: :unknown, reason: :index_not_found}} =
             DocumentObservation.check(
               receipt(operation: :delete, expected: ["gone"]),
               task("succeeded"),
               opts(missing_index)
             )

    missing_document = stub_name("MissingDocument")

    Req.Test.stub(missing_document, fn conn ->
      case conn.request_path do
        "/indexes/articles" -> json(conn, 200, %{"uid" => "articles"})
        "/indexes/articles/documents/gone" -> json(conn, 404, %{"code" => "document_not_found"})
      end
    end)

    assert {:ok, %{state: :verified, reason: nil}} =
             DocumentObservation.check(
               receipt(operation: :delete, expected: ["gone"]),
               task("succeeded"),
               opts(missing_document)
             )
  end

  test "an unrelated task cannot verify expected delete absence" do
    stub = stub_name("UnrelatedDeleteTask")
    owner = self()

    Req.Test.stub(stub, fn conn ->
      send(owner, :unexpected_document_read)
      json(conn, 200, %{"id" => "gone"})
    end)

    assert {:ok, %{state: :unknown, reason: :task_uid_mismatch}} =
             DocumentObservation.check(
               receipt(operation: :delete, expected: ["gone"]),
               task("succeeded", 43),
               opts(stub)
             )

    refute_received :unexpected_document_read
  end

  test "percent encodes index path segments before observing delete effects" do
    stub = stub_name("EncodedIndex")

    Req.Test.stub(stub, fn conn ->
      case conn.request_path do
        "/indexes/catalog%2Flegacy%20%3F" ->
          json(conn, 200, %{"uid" => "catalog/legacy ?"})

        "/indexes/catalog%2Flegacy%20%3F/documents/a%2Fb" ->
          json(conn, 404, %{"code" => "document_not_found"})
      end
    end)

    assert {:ok, %{state: :verified}} =
             DocumentObservation.check(
               receipt(operation: :delete, index: "catalog/legacy ?", expected: ["a/b"]),
               task("succeeded"),
               opts(stub)
             )
  end

  test "does not treat index_not_found, unexpected 404s, or a present document as delete proof" do
    index_not_found_on_document = stub_name("IndexNotFoundOnDocument")

    Req.Test.stub(index_not_found_on_document, fn conn ->
      case conn.request_path do
        "/indexes/articles" -> json(conn, 200, %{"uid" => "articles"})
        _ -> json(conn, 404, %{"code" => "index_not_found"})
      end
    end)

    assert {:ok, %{state: :unknown, reason: :index_not_found}} =
             DocumentObservation.check(
               receipt(operation: :delete, expected: ["gone"]),
               task("succeeded"),
               opts(index_not_found_on_document)
             )

    unexpected = stub_name("Unexpected404")

    Req.Test.stub(unexpected, fn conn ->
      case conn.request_path do
        "/indexes/articles" -> json(conn, 200, %{"uid" => "articles"})
        _ -> json(conn, 404, %{"code" => "permission_denied"})
      end
    end)

    assert {:ok, %{state: :unknown, reason: :document_observation_http_error}} =
             DocumentObservation.check(
               receipt(operation: :delete, expected: ["gone"]),
               task("succeeded"),
               opts(unexpected)
             )

    present = stub_name("Present")

    Req.Test.stub(present, fn conn ->
      case conn.request_path do
        "/indexes/articles" -> json(conn, 200, %{"uid" => "articles"})
        _ -> json(conn, 200, %{"id" => "gone"})
      end
    end)

    assert {:ok, %{state: :failed, reason: :document_still_present}} =
             DocumentObservation.check(
               receipt(operation: :delete, expected: ["gone"]),
               task("succeeded"),
               opts(present)
             )
  end

  test "enforces expected count and serialized byte bounds before any request" do
    empty = receipt(operation: :delete, expected: [])
    oversized_count = receipt(operation: :delete, expected: Enum.to_list(1..51))
    oversized_bytes = receipt(operation: :delete, expected: [String.duplicate("x", 65_537)])

    assert {:ok, %{state: :unknown, reason: :expected_effects_out_of_bounds}} =
             DocumentObservation.check(oversized_count, task("succeeded"), [])

    assert {:ok, %{state: :unknown, reason: :expected_effects_out_of_bounds}} =
             DocumentObservation.check(oversized_bytes, task("succeeded"), [])

    assert {:ok, %{state: :unknown}} = DocumentObservation.check(empty, task("succeeded"), [])
  end

  test "malformed expected documents remain unknown without a backend read" do
    malformed = receipt(operation: :upsert, expected: [%{id: nil, data: %{title: "Hello"}}])

    assert {:ok, %{state: :unknown}} = DocumentObservation.check(malformed, task("succeeded"), [])
  end

  test "preserves transport options while fixing configured origin, path, and authentication" do
    stub = stub_name("SafeOptions")
    owner = self()

    Req.Test.stub(stub, fn conn ->
      send(
        owner,
        {:observed_request, conn.host, conn.port, conn.request_path, conn.query_params,
         Plug.Conn.get_req_header(conn, "x-meili-api-key")}
      )

      assert conn.host == "meili.example.test"
      assert conn.port == 7700
      assert conn.request_path == "/indexes/articles/documents/1"
      assert conn.query_params == %{"trace" => "kept"}
      assert Plug.Conn.get_req_header(conn, "x-meili-api-key") == ["configured-secret"]
      json(conn, 200, %{"id" => 1, "title" => "Hello"})
    end)

    req_opts = [
      plug: {Req.Test, stub},
      retry: false,
      base_url: "http://attacker.invalid/other",
      headers: [{"x-meili-api-key", "attacker-secret"}],
      params: [trace: "kept"]
    ]

    runtime_opts = [
      meilisearch_url: @base_url,
      meilisearch_api_key: "configured-secret",
      req_options: req_opts
    ]

    result =
      DocumentObservation.check(
        receipt(expected: [%{id: 1, data: %{title: "Hello"}}]),
        task("succeeded"),
        runtime_opts
      )

    assert_receive {:observed_request, _, _, _, _, _}
    assert {:ok, %{state: :verified}} = result
  end

  test "invalid task identity and transport failures remain unknown" do
    assert {:ok, %{state: :unknown, reason: :task_uid_mismatch}} =
             DocumentObservation.check(receipt(), task("succeeded", 43), opts())

    stub = stub_name("Transport")
    Req.Test.stub(stub, fn conn -> Req.Test.transport_error(conn, :timeout) end)

    assert {:ok, %{state: :unknown, reason: :document_observation_transport_error}} =
             DocumentObservation.check(
               receipt(expected: [%{id: 1, data: %{title: "Hello"}}]),
               task("succeeded"),
               opts(stub)
             )
  end

  defp receipt(overrides \\ []) do
    Map.merge(
      %{
        operation: :upsert,
        index: @index,
        expected: [%{id: 1, data: %{title: "Hello"}}],
        task_uid: 42,
        handle: nil
      },
      Map.new(overrides)
    )
  end

  defp task(status, uid \\ 42), do: %{"uid" => uid, "status" => status}

  defp opts(stub \\ nil, overrides \\ []) do
    [
      meilisearch_url: @base_url,
      meilisearch_api_key: "secret",
      req_options: if(stub, do: [plug: {Req.Test, stub}], else: [retry: false])
    ]
    |> Keyword.merge(overrides)
  end

  defp stub_name(suffix), do: Module.concat(__MODULE__, suffix)

  defp json(conn, status, body) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(status, Jason.encode!(body))
  end
end
