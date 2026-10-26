defmodule Scrypath.TestSupport.TelemetryContract do
  @moduledoc false

  # Pure helpers for the telemetry drift contract (test/scrypath/telemetry_contract_test.exs).
  #
  # Every function takes strings or `{path, source}` tuples and does no file I/O, so the
  # negative proofs run on in-memory fixtures and never touch repo files.
  #
  # Guide grammar (guides/telemetry.md):
  #
  #     | Event | Kind | Measurements | Start metadata | Stop-only metadata | When |
  #     | `[:scrypath, :x]` | span | standard span measurements | `a`, `b` (optional) | — | ... |
  #
  # A key with the literal " (optional)" suffix is optional; every other backticked key is
  # required. An em dash or prose without backticks lists no keys.

  @row_pattern ~r/^\| `\[:scrypath/
  @key_pattern ~r/`([a-z_]+\??)`( \(optional\))?/

  @type key_set :: %{required: MapSet.t(atom()), optional: MapSet.t(atom())}
  @type row :: %{
          kind: :span | :event,
          measurements: key_set(),
          start: key_set(),
          stop: key_set()
        }
  @type source :: {Path.t(), String.t()}

  @doc """
  Parses every catalog row in the guide markdown into a map keyed by event name.

  Raises `ArgumentError` on a malformed row, an unknown kind, or a duplicate event.
  """
  @spec parse_guide(String.t()) :: %{[atom()] => row()}
  def parse_guide(markdown) when is_binary(markdown) do
    markdown
    |> String.split("\n")
    |> Enum.filter(&Regex.match?(@row_pattern, &1))
    |> Enum.reduce(%{}, fn line, acc ->
      {name, row} = parse_row(line)

      if Map.has_key?(acc, name) do
        raise ArgumentError, "duplicate telemetry guide row for #{inspect(name)}"
      end

      Map.put(acc, name, row)
    end)
  end

  defp parse_row(line) do
    cells =
      line
      |> String.trim()
      |> String.trim_leading("|")
      |> String.trim_trailing("|")
      |> String.split("|")
      |> Enum.map(&String.trim/1)

    case cells do
      [event, kind, measurements, start, stop, _when] ->
        {parse_event(event, line),
         %{
           kind: parse_kind(kind, line),
           measurements: parse_keys(measurements),
           start: parse_keys(start),
           stop: parse_keys(stop)
         }}

      _other ->
        raise ArgumentError,
              "telemetry guide row must have 6 cells, got #{length(cells)}: #{line}"
    end
  end

  defp parse_event(cell, line) do
    with [_, literal] <- Regex.run(~r/^`(\[.*\])`$/, cell),
         [:scrypath | rest] = name when rest != [] <- Code.string_to_quoted!(literal),
         true <- Enum.all?(name, &is_atom/1) do
      name
    else
      _ -> raise ArgumentError, "telemetry guide row has no [:scrypath, ...] event: #{line}"
    end
  end

  defp parse_kind("span", _line), do: :span
  defp parse_kind("event", _line), do: :event

  defp parse_kind(kind, line),
    do: raise(ArgumentError, "telemetry guide kind must be span or event, got #{kind}: #{line}")

  defp parse_keys(cell) do
    @key_pattern
    |> Regex.scan(cell)
    |> Enum.reduce(%{required: MapSet.new(), optional: MapSet.new()}, fn
      [_, key, " (optional)"], acc -> Map.update!(acc, :optional, &MapSet.put(&1, key_atom(key)))
      [_, key | _], acc -> Map.update!(acc, :required, &MapSet.put(&1, key_atom(key)))
    end)
  end

  # Keys come from the repo's own guide (a small, reviewed vocabulary), not user input.
  # String.to_existing_atom/1 would depend on which modules happen to be loaded yet.
  defp key_atom(key), do: String.to_atom(key)

  @doc """
  Collects every `[:scrypath, ...]` list literal (head `:scrypath`, all atoms, non-empty
  tail) in the given sources. Doc text is a binary in the AST and never matches.
  """
  @spec scan_event_names([source()]) :: MapSet.t([atom()])
  def scan_event_names(sources) when is_list(sources) do
    Enum.reduce(sources, MapSet.new(), fn {path, source}, acc ->
      {_ast, acc} = Macro.prewalk(quote_source!(path, source), acc, &collect_name/2)
      acc
    end)
  end

  defp collect_name([:scrypath | rest] = node, acc) when rest != [] do
    if Enum.all?(rest, &is_atom/1), do: {node, MapSet.put(acc, node)}, else: {node, acc}
  end

  defp collect_name(node, acc), do: {node, acc}

  defp quote_source!(path, source) do
    case Code.string_to_quoted(source, file: path, columns: true) do
      {:ok, ast} -> ast
      {:error, error} -> raise ArgumentError, "could not parse #{path}: #{inspect(error)}"
    end
  end

  @doc """
  Set difference in both directions, each side sorted.
  """
  @spec diff(Enumerable.t(), Enumerable.t()) :: %{
          documented_only: [[atom()]],
          emitted_only: [[atom()]]
        }
  def diff(documented, emitted) do
    documented = MapSet.new(documented)
    emitted = MapSet.new(emitted)

    %{
      documented_only: documented |> MapSet.difference(emitted) |> Enum.sort(),
      emitted_only: emitted |> MapSet.difference(documented) |> Enum.sort()
    }
  end

  @doc """
  Compares documented and emitted names. Returns `:ok` only when both sets are non-empty
  and equal, so an empty guide or an empty scan can never pass vacuously.
  """
  @spec compare(Enumerable.t(), Enumerable.t()) :: :ok | {:error, String.t()}
  def compare(documented, emitted) do
    documented = MapSet.new(documented)
    emitted = MapSet.new(emitted)
    %{documented_only: doc_only, emitted_only: emit_only} = diff(documented, emitted)

    cond do
      MapSet.size(documented) == 0 ->
        {:error, "no events parsed from the telemetry guide table"}

      MapSet.size(emitted) == 0 ->
        {:error, "no [:scrypath, ...] event names found in the scanned sources"}

      doc_only == [] and emit_only == [] ->
        :ok

      true ->
        {:error,
         """
         telemetry guide and emitted events differ.
         documented but not emitted: #{inspect(doc_only)}
         emitted but not documented: #{inspect(emit_only)}
         """}
    end
  end
end
