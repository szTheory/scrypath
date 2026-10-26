defmodule Scrypath.TelemetryContractTest do
  # Drift contract between guides/telemetry.md and the events lib/ emits. Deliberately
  # untagged so the core CI lane runs it; do not add a module tag that a lane excludes.
  use ExUnit.Case, async: false

  alias Scrypath.TestSupport.ObanTelemetryScenarios
  alias Scrypath.TestSupport.TelemetryContract

  @guide_path "guides/telemetry.md"
  @external_resource @guide_path

  # Number of events in the catalog. Change it only together with a guide row.
  @event_count 17

  # The only call sites allowed to pass a computed event name: the span/3 wrapper, whose
  # callers are themselves checked for literal names.
  @allowlist [{"lib/scrypath/telemetry.ex", :span, 3}]

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

  describe "literal event names" do
    test "every telemetry call in lib uses a literal event name" do
      sites = TelemetryContract.non_literal_sites(lib_sources())

      offending = Enum.reject(sites, &allowlisted?/1)

      assert offending == [],
             "telemetry calls with a computed event name (use a [:scrypath, ...] literal):\n" <>
               Enum.map_join(offending, "\n", &format_site/1)

      stale = Enum.reject(@allowlist, fn entry -> Enum.any?(sites, &(site_key(&1) == entry)) end)

      assert stale == [],
             "allowlist entries that no longer match a call site: #{inspect(stale)}"
    end

    test "a computed name passed to :telemetry.execute is reported with its line" do
      source = ~S'''
      defmodule Computed do
        @prefix [:scrypath, :thing]

        def emit do
          :telemetry.execute(@prefix ++ [:x], %{}, %{})
        end
      end
      '''

      assert [site] = TelemetryContract.non_literal_sites([{"computed.ex", source}])
      assert site.path == "computed.ex"
      assert site.line == 5
      assert site.function == {:emit, 0}
      assert site.call == ":telemetry.execute"
      assert site.argument == "@prefix ++ [:x]"
    end

    test "a variable name passed to Telemetry.span or Scrypath.Telemetry.span is reported" do
      source = ~S'''
      defmodule Variable do
        alias Scrypath.Telemetry

        def run(name, meta, fun) when is_list(name), do: Telemetry.span(name, meta, fun)
        defp other(name), do: Scrypath.Telemetry.span(name, %{}, fn -> {:ok, %{}} end)
      end
      '''

      assert [
               %{function: {:run, 3}, call: "Telemetry.span", argument: "name"},
               %{function: {:other, 1}, call: "Scrypath.Telemetry.span", argument: "name"}
             ] = TelemetryContract.non_literal_sites([{"variable.ex", source}])
    end

    test "literal names and unrelated Telemetry functions are not reported" do
      source = ~S'''
      defmodule Fine do
        alias Scrypath.Operator.FailedWork.Telemetry

        def run(row) do
          Telemetry.emit(row)
          :telemetry.execute([:scrypath, :fine], %{count: 1}, %{})
          Scrypath.Telemetry.span([:scrypath, :fine_span], %{}, fn -> {:ok, %{}} end)
        end
      end
      '''

      assert TelemetryContract.non_literal_sites([{"fine.ex", source}]) == []
    end
  end

  describe "single catalog" do
    test "guides/telemetry.md is the only event table" do
      offending =
        (Path.wildcard("guides/**/*.md") ++
           Path.wildcard("docs/**/*.md") ++ ["README.md", "ARCHITECTURE.md"])
        |> Enum.reject(&(&1 == @guide_path))
        |> Enum.filter(&Regex.match?(~r/^\| `\[:scrypath/m, File.read!(&1)))
        |> Enum.sort()

      assert offending == [],
             "only #{@guide_path} may hold a telemetry event table; found rows in: " <>
               Enum.join(offending, ", ")
    end
  end

  # Strict key checks cover the three Oban worker events only; the other catalog rows are
  # name-checked above.
  describe "worker event keys" do
    @worker_rows [
      [:scrypath, :oban, :upsert],
      [:scrypath, :oban, :delete],
      [:scrypath, :oban, :upsert, :missing_removed]
    ]

    @key_scenarios [
      :upsert_missing,
      :upsert_ok,
      :upsert_legacy,
      :upsert_error,
      :upsert_cancel,
      :upsert_raise,
      :delete_ok,
      :delete_error,
      :delete_raise
    ]

    test "every captured worker event matches its guide row" do
      guide = guide()

      observed =
        for scenario <- @key_scenarios,
            event <- elem(ObanTelemetryScenarios.run(scenario), 1),
            reduce: MapSet.new() do
          acc ->
            {row_name, phase} = TelemetryContract.resolve_event(guide, event.name)
            assert row_name in @worker_rows, "unexpected event #{inspect(event.name)}"

            row = Map.fetch!(guide, row_name)
            keys = Map.keys(event.metadata)

            assert TelemetryContract.key_check(row, phase, keys) ==
                     %{missing_required: [], undocumented: []},
                   "#{scenario}: #{inspect(event.name)} metadata keys drift from the guide: " <>
                     inspect(TelemetryContract.key_check(row, phase, keys))

            if phase == :event do
              assert MapSet.new(Map.keys(event.measurements)) == row.measurements.required,
                     "#{scenario}: #{inspect(event.name)} measurements drift from the guide"
            end

            MapSet.put(acc, {row_name, phase})
        end

      # A renamed or never-firing event cannot pass by producing nothing to check.
      expected =
        MapSet.new(
          for(
            row <- Enum.take(@worker_rows, 2),
            phase <- [:start, :stop, :exception],
            do: {row, phase}
          ) ++
            [{[:scrypath, :oban, :upsert, :missing_removed], :event}]
        )

      assert MapSet.difference(expected, observed) == MapSet.new(),
             "worker events never observed: #{inspect(Enum.sort(MapSet.difference(expected, observed)))}"
    end

    test "resolve_event maps span phases and point events to guide rows" do
      guide = guide()

      assert TelemetryContract.resolve_event(guide, [:scrypath, :oban, :upsert, :stop]) ==
               {[:scrypath, :oban, :upsert], :stop}

      assert TelemetryContract.resolve_event(guide, [:scrypath, :oban, :upsert, :missing_removed]) ==
               {[:scrypath, :oban, :upsert, :missing_removed], :event}

      assert TelemetryContract.resolve_event(guide, [:scrypath, :oban, :upsert, :bogus]) == :error
    end

    test "dropping a documented key or adding a required one is reported" do
      start = %{
        schema: X,
        backend: :recording,
        index: "i",
        sync_mode: :oban,
        attempt: 1,
        max_attempts: 8,
        document_count: 1,
        telemetry_span_context: make_ref()
      }

      upsert_row = fn guide -> Map.fetch!(guide, [:scrypath, :oban, :upsert]) end

      without_attempt =
        guide_rows()
        |> Enum.map(fn row ->
          if String.starts_with?(row, "| `[:scrypath, :oban, :upsert]`"),
            do: String.replace(row, "`attempt`, ", "", global: false),
            else: row
        end)
        |> fixture()
        |> TelemetryContract.parse_guide()

      assert TelemetryContract.key_check(upsert_row.(without_attempt), :start, Map.keys(start)) ==
               %{missing_required: [], undocumented: [:attempt]}

      with_bogus =
        guide_rows()
        |> Enum.map(fn row ->
          if String.starts_with?(row, "| `[:scrypath, :oban, :upsert]`"),
            do: String.replace(row, "`attempt`, ", "`attempt`, `bogus`, ", global: false),
            else: row
        end)
        |> fixture()
        |> TelemetryContract.parse_guide()

      assert TelemetryContract.key_check(upsert_row.(with_bogus), :start, Map.keys(start)) ==
               %{missing_required: [:bogus], undocumented: []}
    end

    test "exception allows kind, reason and stacktrace only on :exception" do
      row = Map.fetch!(guide(), [:scrypath, :oban, :delete])

      base = [:schema, :backend, :index, :sync_mode, :attempt, :max_attempts, :document_count]
      exception = base ++ [:telemetry_span_context, :kind, :reason, :stacktrace]

      assert TelemetryContract.key_check(row, :exception, exception) ==
               %{missing_required: [], undocumented: []}

      assert TelemetryContract.key_check(row, :start, exception).undocumented ==
               [:kind, :reason, :stacktrace]

      assert TelemetryContract.key_check(row, :stop, base).missing_required == [:outcome]
    end
  end

  defp allowlisted?(site), do: site_key(site) in @allowlist

  defp site_key(%{path: path, function: {name, arity}}), do: {path, name, arity}
  defp site_key(%{path: path, function: nil}), do: {path, nil, nil}

  defp format_site(site) do
    "  #{site.path}:#{site.line} #{site.call}(#{site.argument}, ...) in #{inspect(site.function)}"
  end
end
