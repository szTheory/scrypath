defmodule Scrypath.TelemetryContractTest do
  # Drift contract between guides/telemetry.md and the events lib/ emits. Deliberately
  # untagged so the core CI lane runs it; do not add a module tag that a lane excludes.
  use ExUnit.Case, async: false

  alias Scrypath.TestSupport.TelemetryContract

  @guide_path "guides/telemetry.md"
  @external_resource @guide_path

  # Number of events in the catalog. Change it only together with a guide row.
  @event_count 17

  @header "| Event | Kind | Measurements | Start metadata | Stop-only metadata | When |\n|---|---|---|---|---|---|\n"

  defp guide, do: TelemetryContract.parse_guide(File.read!(@guide_path))

  defp lib_sources do
    "lib/**/*.ex"
    |> Path.wildcard()
    |> Enum.sort()
    |> Enum.map(&{&1, File.read!(&1)})
  end

  defp guide_rows do
    @guide_path
    |> File.read!()
    |> String.split("\n")
    |> Enum.filter(&String.starts_with?(&1, "| `[:scrypath"))
  end

  defp fixture(rows), do: @header <> Enum.join(rows, "\n") <> "\n"

  defp without_row(rows, event) do
    Enum.reject(rows, &String.starts_with?(&1, "| `#{event}`"))
  end

  describe "event names" do
    test "guide event names equal emitted event names" do
      documented = guide() |> Map.keys() |> MapSet.new()
      emitted = TelemetryContract.scan_event_names(lib_sources())

      case TelemetryContract.compare(documented, emitted) do
        :ok -> :ok
        {:error, message} -> flunk(message)
      end

      assert MapSet.size(documented) == @event_count,
             "expected #{@event_count} guide events, got #{MapSet.size(documented)}"
    end

    test "names inside doc text are not emitted names" do
      source = ~S'''
      defmodule DocOnly do
        @moduledoc "Emits `[:scrypath, :doc_only]` (not really)."
        @doc """
        See [:scrypath, :also_doc].
        """
        def run, do: :ok
      end
      '''

      assert TelemetryContract.scan_event_names([{"doc_only.ex", source}]) == MapSet.new()
    end

    test "scan finds multi-line and attribute literals" do
      source = ~S'''
      defmodule Emits do
        @event [:scrypath, :attr]
        def run do
          :telemetry.execute(
            [:scrypath, :multi, :line],
            %{count: 1},
            %{}
          )
        end
      end
      '''

      assert TelemetryContract.scan_event_names([{"emits.ex", source}]) ==
               MapSet.new([[:scrypath, :attr], [:scrypath, :multi, :line]])
    end

    test "a guide missing only the longer prefix-sharing name reports exactly that name" do
      emitted = TelemetryContract.scan_event_names(lib_sources())

      for longer <- [
            "[:scrypath, :oban, :upsert, :missing_removed]",
            "[:scrypath, :search_many, :partial]"
          ] do
        documented =
          guide_rows()
          |> without_row(longer)
          |> fixture()
          |> TelemetryContract.parse_guide()
          |> Map.keys()

        assert TelemetryContract.diff(documented, emitted) == %{
                 documented_only: [],
                 emitted_only: [Code.string_to_quoted!(longer)]
               }

        assert {:error, message} = TelemetryContract.compare(documented, emitted)
        assert message =~ "emitted but not documented: [#{longer}]"
      end
    end

    test "an extra guide row is reported as documented but not emitted" do
      extra = "| `[:scrypath, :nope]` | event | `count` | `schema` | — | never |"

      documented =
        (guide_rows() ++ [extra])
        |> fixture()
        |> TelemetryContract.parse_guide()
        |> Map.keys()

      emitted = TelemetryContract.scan_event_names(lib_sources())

      assert TelemetryContract.diff(documented, emitted) == %{
               documented_only: [[:scrypath, :nope]],
               emitted_only: []
             }

      assert {:error, message} = TelemetryContract.compare(documented, emitted)
      assert message =~ "documented but not emitted: [[:scrypath, :nope]]"
    end

    test "an empty guide, a single-row guide and an empty scan never pass" do
      emitted = TelemetryContract.scan_event_names(lib_sources())
      documented = guide() |> Map.keys()

      empty = TelemetryContract.parse_guide("# Telemetry\n\nNo table here.\n")
      assert empty == %{}
      assert {:error, message} = TelemetryContract.compare(Map.keys(empty), emitted)
      assert message =~ "no events parsed"

      single = guide_rows() |> Enum.take(1) |> fixture() |> TelemetryContract.parse_guide()
      assert map_size(single) == 1
      assert {:error, message} = TelemetryContract.compare(Map.keys(single), emitted)
      assert message =~ "emitted but not documented"
      assert length(TelemetryContract.diff(Map.keys(single), emitted).emitted_only) == 16

      assert TelemetryContract.scan_event_names([]) == MapSet.new()
      assert {:error, message} = TelemetryContract.compare(documented, MapSet.new())
      assert message =~ "no [:scrypath, ...] event names found"
    end

    test "comparison is set-based: shuffled rows parse to the same result" do
      rows = guide_rows()
      shuffled = rows |> Enum.reverse() |> fixture() |> TelemetryContract.parse_guide()

      assert shuffled == rows |> fixture() |> TelemetryContract.parse_guide()
      assert shuffled == guide()
    end

    test "diff sorts each difference set" do
      assert TelemetryContract.diff(
               [[:scrypath, :z], [:scrypath, :a], [:scrypath, :m]],
               [[:scrypath, :y], [:scrypath, :b]]
             ) == %{
               documented_only: [[:scrypath, :a], [:scrypath, :m], [:scrypath, :z]],
               emitted_only: [[:scrypath, :b], [:scrypath, :y]]
             }
    end

    test "malformed guide rows raise instead of being skipped" do
      duplicate = guide_rows() |> Enum.take(1) |> List.duplicate(2) |> List.flatten()

      assert_raise ArgumentError, ~r/duplicate/, fn ->
        duplicate |> fixture() |> TelemetryContract.parse_guide()
      end

      assert_raise ArgumentError, ~r/span or event/, fn ->
        fixture(["| `[:scrypath, :search]` | spam | — | — | — | x |"])
        |> TelemetryContract.parse_guide()
      end

      assert_raise ArgumentError, ~r/6 cells/, fn ->
        fixture(["| `[:scrypath, :search]` | span | — |"]) |> TelemetryContract.parse_guide()
      end
    end

    test "guide rows split required and optional keys" do
      row = Map.fetch!(guide(), [:scrypath, :oban, :upsert])

      assert row.kind == :span
      assert MapSet.member?(row.start.required, :attempt)
      assert MapSet.member?(row.start.optional, :repo)
      refute MapSet.member?(row.start.required, :repo)
      assert MapSet.member?(row.stop.required, :outcome)
      assert MapSet.member?(row.stop.optional, :cancel_reason)
      assert row.measurements.required == MapSet.new()

      event = Map.fetch!(guide(), [:scrypath, :oban, :upsert, :missing_removed])
      assert event.kind == :event
      assert event.measurements.required == MapSet.new([:count])
    end
  end
end
