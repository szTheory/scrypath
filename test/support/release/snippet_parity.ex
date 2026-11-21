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
  # Not covered: how hex.pm renders the marker comment, and the website's code block, which is
  # not an Elixir fence.

  @fence ~r/^```([a-z]*)[ \t]*\n(.*?)^```[ \t]*$/ms

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

  @doc "`%{lang, body, start, stop}` for every fenced code block, with its byte offsets."
  @spec fences(String.t()) :: [fence()]
  def fences(text) do
    @fence
    |> Regex.scan(text, return: :index)
    |> Enum.map(fn [{start, length}, {lang, lang_size}, {body, body_size}] ->
      %{
        lang: binary_part(text, lang, lang_size),
        body: binary_part(text, body, body_size),
        start: start,
        stop: start + length
      }
    end)
  end

  @doc "The Elixir fences of a text."
  @spec elixir_fences(String.t()) :: [fence()]
  def elixir_fences(text), do: Enum.filter(fences(text), &(&1.lang == "elixir"))

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
