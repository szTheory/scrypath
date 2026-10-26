defmodule Scrypath.Oban.WorkerTelemetryTest do
  # Telemetry handlers are global, so this file runs alone.
  use ExUnit.Case, async: false

  alias Scrypath.Oban.DeleteWorker
  alias Scrypath.Oban.UpsertWorker
  alias Scrypath.TestSupport.FakeRepo
  alias Scrypath.TestSupport.ObanTelemetryScenarios, as: Scenarios
  alias Scrypath.TestSupport.ObanTelemetryScenarios.GoneLoaderPost
  alias Scrypath.TestSupport.ObanTelemetryScenarios.LoaderPost
  alias Scrypath.TestSupport.ObanTelemetryScenarios.RaisingBackend
  alias Scrypath.TestSupport.ObanTelemetryScenarios.RecordingBackend
  alias Scrypath.TestSupport.TelemetryCapture

  @delete_start [:scrypath, :oban, :delete, :start]
  @delete_stop [:scrypath, :oban, :delete, :stop]
  @delete_exception [:scrypath, :oban, :delete, :exception]
  @upsert_start [:scrypath, :oban, :upsert, :start]
  @upsert_stop [:scrypath, :oban, :upsert, :stop]
  @upsert_exception [:scrypath, :oban, :upsert, :exception]
  @missing_removed [:scrypath, :oban, :upsert, :missing_removed]

  setup do
    FakeRepo.reset()
    :ok
  end

  defp capture(fun) do
    capture = TelemetryCapture.attach(Scenarios.worker_event_names())
    result = fun.()
    events = TelemetryCapture.collect(capture)
    TelemetryCapture.detach(capture)
    {result, events}
  end

  defp names(events), do: Enum.map(events, & &1.name)

  defp without_span_context(metadata), do: Map.delete(metadata, :telemetry_span_context)

  describe "delete worker span" do
    test "emits one start and one stop with the job's tags and outcome" do
      args = Scenarios.delete_args(QueryablePost, RecordingBackend, [1, 2, 3])
      job = Scenarios.job(args, attempt: 2, max_attempts: 8)

      {result, events} = capture(fn -> DeleteWorker.perform(job) end)

      assert result == :ok
      assert names(events) == [@delete_start, @delete_stop]

      start = TelemetryCapture.find_event(events, @delete_start)
      stop = TelemetryCapture.find_event(events, @delete_stop)

      assert without_span_context(start.metadata) == %{
               schema: QueryablePost,
               backend: :recording,
               index: "tenant_queryable_post",
               sync_mode: :oban,
               attempt: 2,
               max_attempts: 8,
               document_count: 3
             }

      assert without_span_context(stop.metadata) ==
               Map.put(without_span_context(start.metadata), :outcome, :ok)

      for key <- [:error_kind, :cancel_reason, :result_kind] do
        refute Map.has_key?(stop.metadata, key)
      end
    end

    test "an empty id list still reports one start and stop with document_count 0" do
      job = Scenarios.job(Scenarios.delete_args(QueryablePost, RecordingBackend, []))

      {result, events} = capture(fn -> DeleteWorker.perform(job) end)

      assert result == :ok
      assert names(events) == [@delete_start, @delete_stop]
      stop = TelemetryCapture.find_event(events, @delete_stop)
      assert stop.metadata.document_count == 0
      assert stop.metadata.outcome == :ok
    end

    test "1,001 ids sent as two backend chunks still emit exactly one start and stop" do
      ids = Enum.to_list(1..1001)
      job = Scenarios.job(Scenarios.delete_args(QueryablePost, RecordingBackend, ids))

      {result, events} = capture(fn -> DeleteWorker.perform(job) end)

      assert result == :ok
      assert_received {:delete_documents, QueryablePost, _first, _config}
      assert_received {:delete_documents, QueryablePost, _second, _config}
      assert names(events) == [@delete_start, @delete_stop]

      for event <- events, do: assert(event.metadata.document_count == 1001)
    end

    test "the final attempt is reported unchanged" do
      args = Scenarios.delete_args(QueryablePost, RecordingBackend, [1])
      job = Scenarios.job(args, attempt: 8, max_attempts: 8)

      {:ok, events} = capture(fn -> DeleteWorker.perform(job) end)

      assert length(events) == 2

      for event <- events do
        assert event.metadata.attempt == 8
        assert event.metadata.max_attempts == 8
      end
    end

    test "repeated ids are counted once on start and stop" do
      args = Scenarios.delete_args(QueryablePost, RecordingBackend, [1, 1, 2])

      {:ok, events} = capture(fn -> DeleteWorker.perform(Scenarios.job(args)) end)

      assert length(events) == 2
      for event <- events, do: assert(event.metadata.document_count == 2)
    end

    test "a backend error is reported as outcome :error with its error_kind" do
      {result, events} = Scenarios.run(:delete_error)

      assert result == {:error, :timeout}
      stop = TelemetryCapture.find_event(events, @delete_stop)
      assert stop.metadata.outcome == :error
      assert stop.metadata.error_kind == :timeout
      refute Map.has_key?(stop.metadata, :cancel_reason)
    end

    test "a raising backend emits one :exception, no :stop, and the error propagates" do
      job = Scenarios.job(Scenarios.delete_args(QueryablePost, RaisingBackend, [1]))

      capture = TelemetryCapture.attach(Scenarios.worker_event_names())
      assert_raise RuntimeError, "backend exploded", fn -> DeleteWorker.perform(job) end
      events = TelemetryCapture.collect(capture)

      assert names(events) == [@delete_start, @delete_exception]
      exception = TelemetryCapture.find_event(events, @delete_exception)
      start = TelemetryCapture.find_event(events, @delete_start)

      assert exception.metadata.kind == :error
      assert %RuntimeError{} = exception.metadata.reason
      assert is_list(exception.metadata.stacktrace)

      assert Map.drop(exception.metadata, [:kind, :reason, :stacktrace]) == start.metadata
    end

    test "a job that fails decode emits no worker event" do
      args =
        QueryablePost
        |> Scenarios.delete_args(RecordingBackend, [1])
        |> Map.put("schema", "MissingSchema")

      {result, events} = capture(fn -> DeleteWorker.perform(Scenarios.job(args)) end)

      assert {:cancel, {:invalid_job, _tag}} = result
      assert events == []
    end
  end

  describe "upsert worker span" do
    test "a loaded job reports its plan and outcome on stop" do
      {result, events} = Scenarios.run(:upsert_ok)

      assert result == :ok
      assert names(events) == [@upsert_start, @upsert_stop]

      start = TelemetryCapture.find_event(events, @upsert_start)
      stop = TelemetryCapture.find_event(events, @upsert_stop)

      assert without_span_context(start.metadata) == %{
               schema: LoaderPost,
               backend: :recording,
               index: "tenant_queryable_post",
               sync_mode: :oban,
               repo: FakeRepo,
               attempt: 1,
               max_attempts: 8,
               document_count: 2
             }

      assert without_span_context(stop.metadata) ==
               Map.merge(without_span_context(start.metadata), %{
                 outcome: :ok,
                 source: :loaded,
                 upserted_count: 2,
                 missing_count: 0
               })

      refute Map.has_key?(stop.metadata, :result_kind)
    end

    test "a legacy snapshot job reports source :legacy_snapshot" do
      {result, events} = Scenarios.run(:upsert_legacy)

      assert result == :ok
      stop = TelemetryCapture.find_event(events, @upsert_stop)
      assert stop.metadata.outcome == :ok
      assert stop.metadata.source == :legacy_snapshot
      assert stop.metadata.upserted_count == 1
      assert stop.metadata.missing_count == 0
      refute Map.has_key?(stop.metadata, :repo)
    end

    # The load produced a plan before the write failed: counts describe the plan and the
    # outcome says it was not carried out.
    test "a backend error reports outcome :error and keeps the planned counts" do
      {result, events} = Scenarios.run(:upsert_error)

      assert result == {:error, :timeout}
      stop = TelemetryCapture.find_event(events, @upsert_stop)
      assert stop.metadata.outcome == :error
      assert stop.metadata.error_kind == :timeout
      assert stop.metadata.source == :loaded
      assert stop.metadata.upserted_count == 1
      assert stop.metadata.missing_count == 0
      refute Map.has_key?(stop.metadata, :cancel_reason)
    end

    test "a non-list search_records/2 result is cancelled through the span" do
      {result, events} = Scenarios.run(:upsert_cancel)

      assert result == {:cancel, {:invalid_job, :invalid_search_records}}
      stop = TelemetryCapture.find_event(events, @upsert_stop)
      assert stop.metadata.outcome == :cancel
      assert stop.metadata.cancel_reason == :invalid_search_records
      refute_plan_keys(stop.metadata)
      refute Map.has_key?(stop.metadata, :error_kind)
    end

    test "a job with no repo and no snapshot is cancelled with :repo_required" do
      args =
        QueryablePost
        |> Scenarios.upsert_args(RecordingBackend, [1])
        |> Map.delete("repo")

      {result, events} = capture(fn -> UpsertWorker.perform(Scenarios.job(args)) end)

      assert result == {:cancel, {:invalid_job, :repo_required}}
      stop = TelemetryCapture.find_event(events, @upsert_stop)
      assert stop.metadata.outcome == :cancel
      assert stop.metadata.cancel_reason == :repo_required
      refute_plan_keys(stop.metadata)
    end

    test "an uncastable id is cancelled with the atom head of the tag" do
      args = Scenarios.upsert_args(QueryablePost, RecordingBackend, [1, "abc"])

      {result, events} = capture(fn -> UpsertWorker.perform(Scenarios.job(args)) end)

      assert result == {:cancel, {:invalid_job, {:invalid_arg, "document_ids"}}}
      stop = TelemetryCapture.find_event(events, @upsert_stop)
      assert stop.metadata.cancel_reason == :invalid_arg
      refute_plan_keys(stop.metadata)
    end

    test "a job that fails decode emits no worker event" do
      {result, events} = Scenarios.run(:decode_failure)

      assert {:cancel, {:invalid_job, _tag}} = result
      assert events == []
    end

    test "a raising backend emits one :exception, no :stop, and the error propagates" do
      args = Scenarios.upsert_args(LoaderPost, RaisingBackend, [1])

      capture = TelemetryCapture.attach(Scenarios.worker_event_names())

      assert_raise RuntimeError, "backend exploded", fn ->
        UpsertWorker.perform(Scenarios.job(args))
      end

      events = TelemetryCapture.collect(capture)

      assert names(events) == [@upsert_start, @upsert_exception]
      exception = TelemetryCapture.find_event(events, @upsert_exception)
      start = TelemetryCapture.find_event(events, @upsert_start)

      assert exception.metadata.kind == :error
      assert %RuntimeError{} = exception.metadata.reason
      assert Map.drop(exception.metadata, [:kind, :reason, :stacktrace]) == start.metadata
    end

    test "the raise scenario returns the exception for shared callers" do
      assert {{:raised, %RuntimeError{}}, events} = Scenarios.run(:upsert_raise)
      assert names(events) == [@upsert_start, @upsert_exception]

      assert {{:raised, %RuntimeError{}}, events} = Scenarios.run(:delete_raise)
      assert names(events) == [@delete_start, @delete_exception]
    end
  end

  describe "job independence" do
    test "performing the same job twice emits two independent spans" do
      job = Scenarios.job(Scenarios.upsert_args(LoaderPost, RecordingBackend, [1, 2]))

      {_result, events} =
        capture(fn ->
          :ok = UpsertWorker.perform(job)
          :ok = UpsertWorker.perform(job)
        end)

      assert names(events) == [@upsert_start, @upsert_stop, @upsert_start, @upsert_stop]

      [first, second] =
        events
        |> TelemetryCapture.events_named(@upsert_start)
        |> Enum.map(&without_span_context(&1.metadata))

      assert first == second
    end

    test "concurrent jobs each report their own count and attempt" do
      capture = TelemetryCapture.attach(Scenarios.worker_event_names())

      jobs = [
        Scenarios.job(Scenarios.upsert_args(LoaderPost, RecordingBackend, [1, 2]), attempt: 1),
        Scenarios.job(Scenarios.upsert_args(LoaderPost, RecordingBackend, [1, 2, 3]), attempt: 3)
      ]

      jobs
      |> Enum.map(fn job -> Task.async(fn -> UpsertWorker.perform(job) end) end)
      |> Task.await_many()
      |> Enum.each(&assert(&1 == :ok))

      events = TelemetryCapture.collect(capture)
      assert length(events) == 4

      by_context = Enum.group_by(events, & &1.metadata.telemetry_span_context)
      assert map_size(by_context) == 2

      pairs =
        for {_context, pair} <- by_context do
          assert Enum.map(pair, & &1.name) == [@upsert_start, @upsert_stop]
          [start, stop] = pair
          assert start.metadata.document_count == stop.metadata.document_count
          assert start.metadata.attempt == stop.metadata.attempt
          {start.metadata.document_count, start.metadata.attempt}
        end

      assert Enum.sort(pairs) == [{2, 1}, {3, 3}]
    end
  end

  describe "missing_removed event" do
    test "fires once with the distinct missing count and the span's start metadata" do
      {result, events} = Scenarios.run(:upsert_missing)

      assert result == :ok
      assert names(events) == [@upsert_start, @missing_removed, @upsert_stop]

      start = TelemetryCapture.find_event(events, @upsert_start)
      removed = TelemetryCapture.find_event(events, @missing_removed)
      stop = TelemetryCapture.find_event(events, @upsert_stop)

      assert removed.measurements == %{count: 1}
      assert removed.metadata == without_span_context(start.metadata)

      assert stop.metadata.outcome == :ok
      assert stop.metadata.source == :loaded
      assert stop.metadata.upserted_count == 1
      assert stop.metadata.missing_count == 1
      assert stop.metadata.document_count == 2
      assert stop.metadata.attempt == 2
    end

    test "does not fire when every record still exists" do
      {:ok, events} = Scenarios.run(:upsert_ok)

      assert TelemetryCapture.events_named(events, @missing_removed) == []
    end

    test "fires once for 1,500 missing ids deleted in two chunks" do
      {result, events} = Scenarios.run(:upsert_missing_many)

      assert result == :ok
      assert_received {:delete_documents, GoneLoaderPost, _first, _config}
      assert_received {:delete_documents, GoneLoaderPost, _second, _config}
      refute_received {:delete_documents, GoneLoaderPost, _third, _config}

      assert [removed] = TelemetryCapture.events_named(events, @missing_removed)
      assert removed.measurements == %{count: 1500}
      assert is_integer(removed.measurements.count)
    end

    test "counts a missing id repeated in the job args once" do
      args = Scenarios.upsert_args(LoaderPost, RecordingBackend, [404, 404, 1])

      {:ok, events} = capture(fn -> UpsertWorker.perform(Scenarios.job(args)) end)

      assert [removed] = TelemetryCapture.events_named(events, @missing_removed)
      assert removed.measurements == %{count: 1}
    end

    test "does not fire when a delete chunk fails" do
      {result, events} = Scenarios.run(:upsert_missing_chunk_fail)

      assert result == {:error, {:timeout, :second_chunk}}
      assert TelemetryCapture.events_named(events, @missing_removed) == []

      stop = TelemetryCapture.find_event(events, @upsert_stop)
      assert stop.metadata.outcome == :error
      assert stop.metadata.error_kind == :timeout
    end

    test "does not fire on the legacy snapshot path" do
      {:ok, events} = Scenarios.run(:upsert_legacy)

      assert TelemetryCapture.events_named(events, @missing_removed) == []
    end
  end

  describe "metadata cardinality" do
    # Tags must be atoms, integers, modules or the index string: never ids or tuples.
    test "no worker event carries a tuple or list value outside the exempt keys" do
      events = Enum.flat_map(Scenarios.scenarios(), fn s -> elem(Scenarios.run(s), 1) end)

      assert Enum.any?(events, &(&1.name == @missing_removed))
      assert Enum.any?(events, &(List.last(&1.name) == :exception))

      for event <- events, {key, value} <- event.metadata, key not in exempt_keys(event) do
        refute is_tuple(value) or is_list(value),
               "#{inspect(event.name)} carries #{inspect(key)} => #{inspect(value)}"
      end
    end
  end

  defp exempt_keys(%{name: name}) do
    case List.last(name) do
      :exception -> [:telemetry_span_context, :reason, :stacktrace]
      _other -> [:telemetry_span_context]
    end
  end

  defp refute_plan_keys(metadata) do
    for key <- [:source, :upserted_count, :missing_count] do
      refute Map.has_key?(metadata, key), "unexpected #{inspect(key)} in #{inspect(metadata)}"
    end
  end
end
