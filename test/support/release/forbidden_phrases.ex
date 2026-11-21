# test_helper.exs requires test/support files in path order, and this one sorts before
# snippet_parity.ex; requiring it here (a no-op once loaded) keeps the compile warning-free under
# --warnings-as-errors.
Code.require_file("snippet_parity.ex", __DIR__)

defmodule Scrypath.Release.ForbiddenPhrases do
  @moduledoc false

  # GUARD-03 (Phase 193): one data table of wording the README and the guides must not use, and a
  # pure scanner over it. It is a test-only helper under test/support, so it is never packaged.
  #
  #   * The data is test/support/release/forbidden_phrases.json. It copies, and does not import,
  #     the do-not-say list of brand/BRAND.md, the avoid entries of GLOSSARY.md and the
  #     conventions of scrypath_ops/test/support/copy_rules.json (field names `id`, `rule`,
  #     `forbidden`, `text`, `match`, `case`, `not_covered`), plus the two lists the README tests
  #     kept before this table existed.
  #   * A `readme` rule applies to README.md only and must record a `reason`; a
  #     `readme_and_guides` rule applies to README.md and every `guides/` path. There is no
  #     allowlist: a shipped hit is reworded, never excused here.
  #   * Fenced code is masked (each character but a newline becomes a space), so line numbers stay
  #     true and code samples that name a real option or event are not read as prose. Fences are
  #     paired by `SnippetParity.fences/1` (any info string, indent or tilde fence), which raises on
  #     a fence that is never closed, so prose between two blocks is never silently skipped.
  #   * Every pattern is wrapped in word boundaries, so a phrase must begin and end with a word
  #     character. A literal's spaces match any run of blanks or one line break, so a hard-wrapped
  #     sentence is caught. A rule is `case` sensitive or insensitive as the table says.
  #   * `scan/2` is pure: in-memory `{path, text}` pairs in, sorted `{path, line, rule_id,
  #     matched}` out, so the planted cases in test/release/forbidden_phrases_contract_test.exs
  #     never edit a shipped file.
  #
  # Not covered: wording nobody listed, and whether the guides read in the brand voice.

  alias Scrypath.Release.SnippetParity

  @table_path Path.join(__DIR__, "forbidden_phrases.json")

  # A space inside a literal: blanks, or blanks around one line break.
  @gap "(?:[ \\t]+|[ \\t]*\\n[ \\t]*)"

  @type rule :: map()
  @type hit :: {Path.t(), pos_integer(), String.t(), String.t()}

  @doc "The decoded data table."
  @spec table() :: map()
  def table, do: @table_path |> File.read!() |> Jason.decode!()

  @doc "Every rule of the table."
  @spec rules() :: [rule()]
  def rules, do: Map.fetch!(table(), "rules")

  @doc "The rules with the given ids, in the order given. Raises on an unknown id."
  @spec rules([String.t()]) :: [rule()]
  def rules(ids) do
    by_id = Map.new(rules(), &{&1["id"], &1})

    Enum.map(ids, fn id ->
      Map.get(by_id, id) || raise ArgumentError, "no forbidden-phrase rule named #{inspect(id)}"
    end)
  end

  @doc "The brand book's terms as the table copies them, from every rule's `source_terms`."
  @spec brand_terms() :: [String.t()]
  def brand_terms, do: Enum.flat_map(rules(), &Map.get(&1, "source_terms", []))

  @doc "`{path, text}` for README.md and every `guides/` entry of the docs extras."
  @spec targets() :: [{Path.t(), String.t()}]
  def targets do
    extras = Scrypath.MixProject.project()[:docs][:extras]
    paths = ["README.md" | Enum.filter(extras, &String.starts_with?(&1, "guides/"))]
    for path <- paths, do: {path, File.read!(path)}
  end

  @doc """
  Sorted `{path, line, rule_id, matched}` for every phrase of `rules` found in prose of the
  `{path, text}` pairs. `line` is the 1-based line the phrase starts on.
  """
  @spec scan([{Path.t(), String.t()}], [rule()]) :: [hit()]
  def scan(files, rules) do
    compiled = for rule <- rules, do: {rule, Enum.map(rule["forbidden"], &compile/1)}

    hits =
      for {path, text} <- files,
          masked = mask(path, text),
          {rule, regexes} <- compiled,
          applies?(rule["scope"], path),
          regex <- regexes,
          [{start, length}] <- Regex.scan(regex, masked, return: :index, capture: :first),
          do:
            {path, newlines(binary_part(masked, 0, start)) + 1, rule["id"],
             binary_part(masked, start, length)}

    Enum.sort(hits)
  end

  @doc "Scan of README.md and every guide in extras against every rule."
  @spec violations() :: [hit()]
  def violations, do: scan(targets(), rules())

  defp applies?("readme", path), do: path == "README.md"
  defp applies?("readme_and_guides", path), do: path == "README.md" or guide?(path)

  defp guide?(path), do: String.starts_with?(path, "guides/")

  defp compile(%{"text" => text, "match" => match, "case" => case_rule}) do
    source = if match == "literal", do: literal(text), else: text
    flags = if case_rule == "insensitive", do: "iu", else: "u"
    Regex.compile!("\\b(?:" <> source <> ")\\b", flags)
  end

  defp literal(text) do
    text |> String.split(~r/\s+/) |> Enum.map_join(@gap, &Regex.escape/1)
  end

  # Every character of a fenced block except a newline becomes a space. The byte length is kept,
  # so offsets and line numbers of the prose stay true. A fence that is never closed raises, with
  # the path, instead of masking prose it should have scanned.
  defp mask(path, text) do
    fences =
      try do
        SnippetParity.fences(text)
      rescue
        error in ArgumentError ->
          reraise ArgumentError, "#{path}: #{error.message}", __STACKTRACE__
      end

    Enum.reduce(Enum.reverse(fences), text, fn fence, acc ->
      binary_part(acc, 0, fence.start) <>
        blank(binary_part(acc, fence.start, fence.stop - fence.start)) <>
        binary_part(acc, fence.stop, byte_size(acc) - fence.stop)
    end)
  end

  defp blank(chunk),
    do: for(<<byte <- chunk>>, into: "", do: if(byte == ?\n, do: "\n", else: " "))

  defp newlines(text), do: text |> :binary.matches("\n") |> length()
end
