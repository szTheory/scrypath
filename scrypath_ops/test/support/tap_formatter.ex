defmodule ScrypathOps.Test.TapFormatter do
  @moduledoc false
  use GenServer

  def init(_opts) do
    IO.puts("TAP version 13")
    {:ok, %{count: 0}}
  end

  def handle_cast({:test_finished, %{state: nil, name: name}}, state) do
    count = state.count + 1
    IO.puts("ok #{count} - #{tap_name(name)}")
    {:noreply, %{state | count: count}}
  end

  def handle_cast({:test_finished, %{state: {:failed, _failures}, name: name}}, state) do
    count = state.count + 1
    IO.puts("not ok #{count} - #{tap_name(name)}")
    {:noreply, %{state | count: count}}
  end

  def handle_cast({:test_finished, _test}, state), do: {:noreply, state}

  def handle_cast({:suite_finished, _times_us}, state) do
    IO.puts("1..#{state.count}")
    {:noreply, state}
  end

  def handle_cast(_event, state), do: {:noreply, state}

  defp tap_name(name), do: name |> to_string() |> String.replace(~r/[\r\n]+/, " ")
end
