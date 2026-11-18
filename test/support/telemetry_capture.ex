defmodule Scrypath.TestSupport.TelemetryCapture do
  @moduledoc false

  # Captures telemetry events by FULL event name and sends them to the test process that
  # attached the capture.
  #
  #     capture = TelemetryCapture.attach([[:scrypath, :oban, :delete, :start]])
  #     ... run the code under test ...
  #     events = TelemetryCapture.collect(capture)
  #
  # The handler is global: it forwards matching events from EVERY process, including
  # other tests running at the same time. Use it only in `async: false` test modules.
  # Because it is not process-scoped, events from Tasks the test starts arrive too. The
  # handler is detached on test exit; call detach/1 earlier to stop capturing.

  import ExUnit.Assertions, only: [flunk: 1]

  @type capture :: %{id: String.t(), ref: reference()}
  @type event :: %{name: [atom()], measurements: map(), metadata: map()}

  @spec attach([[atom()]]) :: capture()
  def attach(event_names) when is_list(event_names) do
    ref = make_ref()
    id = "scrypath-capture-#{System.unique_integer([:positive])}"

    :ok = :telemetry.attach_many(id, event_names, &__MODULE__.handle_event/4, {self(), ref})
    ExUnit.Callbacks.on_exit(fn -> :telemetry.detach(id) end)

    %{id: id, ref: ref}
  end

  @spec detach(capture()) :: :ok
  def detach(%{id: id}) do
    _ = :telemetry.detach(id)
    :ok
  end

  @doc false
  def handle_event(name, measurements, metadata, {pid, ref}) do
    send(pid, {ref, %{name: name, measurements: measurements, metadata: metadata}})
  end

  # Drains this capture's events in emit order, waiting 50 ms for stragglers.
  @spec collect(capture()) :: [event()]
  def collect(%{ref: ref}), do: collect(ref, [])

  defp collect(ref, acc) do
    receive do
      {^ref, event} -> collect(ref, [event | acc])
    after
      50 -> Enum.reverse(acc)
    end
  end

  @spec events_named([event()], [atom()]) :: [event()]
  def events_named(events, name), do: Enum.filter(events, &(&1.name == name))

  @spec find_event([event()], [atom()]) :: event()
  def find_event(events, name) do
    Enum.find(events, &(&1.name == name)) ||
      flunk("expected event #{inspect(name)}, got #{inspect(Enum.map(events, & &1.name))}")
  end
end
