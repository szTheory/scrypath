defmodule Scrypath.Release.SnippetParity do
  @moduledoc false

  # GUARD-03 (Phase 193): the README quick path and the golden path repeat the same schema and
  # config snippets, and one shared definition decides whether they still match. It is a
  # test-only helper under test/support, so it is never packaged.
  #
  #   * The schema snippet is the first Elixir fence whose body contains `use Scrypath,` (comma
  #     included); the config snippet is the first Elixir fence containing `config :scrypath`.
  #   * The two bodies must be byte-identical, unless a reason-carrying marker sits directly above
  #     either fence: an HTML comment `scrypath:snippet-intentionally-differs: <reason>`, with
  #     blank lines tolerated between the comment and the fence. A marker without a reason, the
  #     old bare form included, is an error. The comment renders invisibly in the ExDoc build.
  #   * Every function is pure: in-memory text in, plain terms out, so the planted cases in
  #     test/release/snippet_parity_contract_test.exs never edit a shipped file.
  #
  #   * Fences are paired line by line, as CommonMark does. An opening line is any indent, three or
  #     more backticks or tildes, then any info string (`html+eex`, `json5`, `elixir title="a.ex"`);
  #     its `lang` is the first word of that string. The block closes at the first line holding
  #     only the same character, at least as many times. A fence that is never closed raises, so a
  #     mis-paired file fails loudly instead of masking the prose between two blocks (WR-01 of the
  #     Phase 193 review: the old matcher saw only plain lowercase info strings, so one other
  #     opening line inverted the pairing for the rest of the file).
  #
  # Not covered: how hex.pm renders the marker comment, and the website's code block, which is
  # not an Elixir fence. A fence inside a blockquote or after a list marker is not recognised;
  # the real-file test in test/release/forbidden_phrases_contract_test.exs counts such lines.

  # An opening line: any indent, three or more backticks or tildes, then the info string.
  @fence_open ~r/\A[ \t]*(`{3,}|~{3,})(.*)\z/

  # The marker, as the last thing before a fence once trailing whitespace is trimmed. The reason
  # is everything after the colon up to the closing `-->`; it never spans another comment.
  @marker_pattern ~r/<!--\s*scrypath:snippet-intentionally-differs(?:\s*:((?:(?!-->).)*))?\s*-->\z/s

  @type fence :: %{
          lang: String.t(),
          body: String.t(),
          start: non_neg_integer(),
          stop: non_neg_integer()
        }
  @type side :: :readme | :golden
  @type result ::
          :identical
          | {:marked, side(), String.t()}
          | {:error, :differs | :empty_reason | {:missing_fence, side()}}

  @doc """
  `%{lang, body, start, stop}` for every fenced code block, with its byte offsets: `start` is the
  start of the opening line, `stop` the end of the closing line (before its line break), and
  `body` the lines between them. Raises `ArgumentError` for a fence that is never closed.
  """
  @spec fences(String.t()) :: [fence()]
  def fences(text) do
    {lines, _next} =
      text
      |> String.split("\n")
      |> Enum.with_index(1)
      |> Enum.map_reduce(0, fn {line, number}, offset ->
        {{offset, line, number}, offset + byte_size(line) + 1}
      end)

    collect_fences(lines, text, [])
  end

  defp collect_fences([], _text, found), do: Enum.reverse(found)

  defp collect_fences([{offset, line, number} | rest], text, found) do
    case fence_open(line) do
      nil ->
        collect_fences(rest, text, found)

      {marker, info} ->
        case Enum.split_while(rest, fn {_, candidate, _} ->
               not fence_close?(candidate, marker)
             end) do
          {_inside, []} ->
            raise ArgumentError, "the code fence opened on line #{number} is never closed"

          {_inside, [{close, closing, _} | after_close]} ->
            body = offset + byte_size(line) + 1

            fence = %{
              lang: info |> String.split(~r/\s+/, parts: 2) |> hd(),
              body: binary_part(text, body, close - body),
              start: offset,
              stop: close + byte_size(closing)
            }

            collect_fences(after_close, text, [fence | found])
        end
    end
  end

  # `{marker, info}` for an opening line. A backtick fence's info string holds no backtick, so a
  # line that starts with an inline code span is prose.
  defp fence_open(line) do
    with [_whole, marker, info] <- Regex.run(@fence_open, line),
         info = String.trim(info),
         false <- String.starts_with?(marker, "`") and String.contains?(info, "`") do
      {marker, info}
    else
      _ -> nil
    end
  end

  # A closing line holds only the opening character, at least as many times as the opening line.
  defp fence_close?(line, marker) do
    closing = String.trim(line)

    byte_size(closing) >= byte_size(marker) and
      closing == String.duplicate(String.first(marker), byte_size(closing))
  end

  @doc "The Elixir fences of a text."
  @spec elixir_fences(String.t()) :: [fence()]
  def elixir_fences(text), do: Enum.filter(fences(text), &(String.downcase(&1.lang) == "elixir"))

  @doc "The text with fenced code removed."
  @spec prose(String.t()) :: String.t()
  def prose(text) do
    Enum.reduce(Enum.reverse(fences(text)), text, fn fence, acc ->
      binary_part(acc, 0, fence.start) <>
        binary_part(acc, fence.stop, byte_size(acc) - fence.stop)
    end)
  end

  @doc "The first Elixir fence whose body contains `use Scrypath,`, or nil."
  @spec schema_fence(String.t()) :: fence() | nil
  def schema_fence(text), do: Enum.find(elixir_fences(text), &(&1.body =~ "use Scrypath,"))

  @doc "The first Elixir fence whose body contains `config :scrypath`, or nil."
  @spec config_fence(String.t()) :: fence() | nil
  def config_fence(text), do: Enum.find(elixir_fences(text), &(&1.body =~ "config :scrypath"))

  @doc """
  The marker directly above a fence: `:none`, `{:ok, reason}` or `{:error, :empty_reason}` (the
  bare marker, or a blank reason).
  """
  @spec marker(String.t(), fence()) :: :none | {:ok, String.t()} | {:error, :empty_reason}
  def marker(text, fence) do
    text
    |> binary_part(0, fence.start)
    |> String.trim_trailing()
    |> then(&Regex.run(@marker_pattern, &1))
    |> marker_result()
  end

  defp marker_result(nil), do: :none
  defp marker_result([_whole]), do: {:error, :empty_reason}

  defp marker_result([_whole, reason]) do
    case String.trim(reason) do
      "" -> {:error, :empty_reason}
      trimmed -> {:ok, trimmed}
    end
  end

  @doc """
  Compares the snippet of `kind` (`:schema` or `:config`) in the README text and the golden path
  text.

  Returns `:identical`; `{:marked, side, reason}` when the bodies differ and a marker with a
  reason sits above the fence on `side`; or an error: `{:missing_fence, side}`, `:empty_reason`
  (a malformed marker on either side, whatever the bodies) or `:differs`.
  """
  @spec check(String.t(), String.t(), :schema | :config) :: result()
  def check(readme_text, golden_text, kind) when kind in [:schema, :config] do
    with {:ok, readme} <- side(readme_text, kind, :readme),
         {:ok, golden} <- side(golden_text, kind, :golden) do
      decide(readme, golden)
    end
  end

  defp side(text, kind, side) do
    fence = if kind == :schema, do: schema_fence(text), else: config_fence(text)

    case fence do
      nil -> {:error, {:missing_fence, side}}
      fence -> with {:ok, reason} <- marker_or_none(text, fence), do: {:ok, {side, fence, reason}}
    end
  end

  defp marker_or_none(text, fence) do
    case marker(text, fence) do
      :none -> {:ok, nil}
      {:ok, reason} -> {:ok, reason}
      {:error, _} = error -> error
    end
  end

  defp decide({_, readme, readme_reason}, {_, golden, golden_reason}) do
    cond do
      readme.body == golden.body -> :identical
      is_binary(readme_reason) -> {:marked, :readme, readme_reason}
      is_binary(golden_reason) -> {:marked, :golden, golden_reason}
      true -> {:error, :differs}
    end
  end
end
