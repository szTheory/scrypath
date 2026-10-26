defmodule Scrypath.Oban.WorkerTelemetryTest do
  # Telemetry handlers are global, so this file runs alone.
  use ExUnit.Case, async: false

  alias Scrypath.Oban.DeleteWorker
  alias Scrypath.TestSupport.FakeRepo
  alias Scrypath.TestSupport.ObanTelemetryScenarios, as: Scenarios
  alias Scrypath.TestSupport.ObanTelemetryScenarios.RecordingBackend
  alias Scrypath.TestSupport.TelemetryCapture

  @delete_start [:scrypath, :oban, :delete, :start]
  @delete_stop [:scrypath, :oban, :delete, :stop]

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
  end
end
