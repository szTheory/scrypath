defmodule Scrypath.Release.ShippedDocs do
  @moduledoc false

  # TRUTH-01 invariant (Phase 192): no file shipped in the Hex package tells an adopter to run
  # a repository-only Mix task, unless the sentence says it runs from a source checkout and is
  # not in the Hex package.
  #
  #   * The repo-only task list is derived on every run: the task names found under the three
  #     source trees in @task_source_globs, minus the names the shipped lib/ tree defines.
  #     No task name is written down in this module.
  #   * The scanned files are every file expanded from the `files:` entries of mix.exs, the same
  #     data source test/release/package_contents_test.exs copies into its tarball fixture.
  #   * `scan/2` is pure: in-memory `{path, text}` pairs in, sorted `{path, line, name}` out, so
  #     the planted cases in test/release/shipped_docs_contract_test.exs never edit a shipped file.
  #
  # This module lives under test/support, so it is never packaged and its own wording cannot
  # ship. Scope facts the exemptions rely on:
  #
  #   * @registration_line matches only quoted keyword entries (a double-quoted dotted task name
  #     followed by `: :test`). The unquoted entries in preferred_envs (the bare verify task, and
  #     the credo and dialyzer dependency tasks) are not blanked and stay scanned; they are not
  #     reported because they carry no `mix ` prefix, which `mentions/2` requires for an
  #     undotted name, and credo and dialyzer are dependency tasks, not repo-only ones.
  #   * LICENSE is in the package files but has no text extension, so @text_exts leaves it out on
  #     purpose: it is license text and cannot name a task.

  alias Scrypath.Release.PackageContract

  # Task source trees (planning-time decision: scrypath_ops and the examples are included
  # because a shipped guide tells adopters to run an ops task that lives under scrypath_ops/).
  @task_source_globs [
    "dev/mix/tasks/**/*.ex",
    "scrypath_ops/lib/mix/tasks/**/*.ex",
    "examples/*/lib/mix/tasks/**/*.ex"
  ]

  @shipped_task_glob "lib/**/*.ex"

  # Locked by the phase context: maintainer-facing files where naming a repo-only task is the
  # point of the file.
  @allowlist ~w(CONTRIBUTING.md docs/releasing.md)

  # One preferred_envs keyword entry alone on its line.
  @registration_line ~r/^\s*"[a-z0-9_]+(?:\.[a-z0-9_]+)+":\s*:test,?\s*$/

  # Exactly two named exemptions outside the locked allowlist. Each records a reason and a
  # revisit trigger; the contract test fails if the set grows or a field is empty.
  @exempt %{
    "CHANGELOG.md" => %{
      scope: :whole_file,
      reason:
        "Generated release history owned by release-please. workflow_wiring_test requires " <>
          "two historical task mentions in it, so the file cannot be edited to green.",
      revisit:
        "Revisit when the release-please changelog configuration changes, when a " <>
          "hand-written CHANGELOG entry starts telling adopters to run a command, or when the " <>
          "workflow_wiring_test two-mention requirement is removed."
    },
    "mix.exs" => %{
      scope: {:lines, @registration_line},
      reason:
        "Code that registers task environments in preferred_envs, not adopter instructions. " <>
          "Only the registration lines are exempt; any other mix.exs mention is scanned.",
      revisit:
        "Revisit when task-environment registration moves out of cli/0 preferred_envs, or " <>
          "when mix.exs gains a docstring or comment that names a repo-only task (that line " <>
          "is scanned and fails today)."
    }
  }

  # LICENSE (no extension) and local binaries such as lib/.DS_Store are not text.
  @text_exts ~w(.md .ex .exs)

  # Sentence boundary, kept as data: a `.`, `!` or `?` (plus any closing quote, bracket or
  # emphasis marks), then whitespace (a newline counts), then a character that can start a
  # sentence (a blockquote marker `>` counts, so a quoted line is its own sentence). Matched on
  # text where code spans and link targets are masked, so a task name in backticks or a link
  # target never splits a sentence. Over-splitting (after an abbreviation, say) only makes the
  # check stricter, never a false pass: each half is judged on its own. Under-splitting is the
  # laxer direction, so a new way to start a sentence belongs in this class.
  @sentence_boundary ~r/([.!?][)\]"'*_]*)\s+(?=[A-Z0-9`*_\[("'“‘>])/u

  # The qualifier, kept as data: all three must match inside one unit. The phrases allow a
  # line wrap between the two words.
  @qualifier_patterns [
    ~r/source\s+checkout/i,
    ~r/hex\s+package/i,
    ~r/\bnot\b/i
  ]

  # Canonical short qualifier for doc edits and planted cases.
  @qualifier_example "(source checkout only; not in the Hex package)"

  # Line classifiers for units/1.
  @fence_open ~r/^\s*(`{3,}|~{3,})/
  @table_row ~r/^\s*\|/
  @heading ~r/^\s{0,3}[#]{1,6}\s/
  @list_item ~r/^\s*(?:[-*+]|\d+[.)])\s+\S/

  # Masks (interior only, same byte length) so boundary offsets map back to the original.
  @code_span ~r/`[^`]*`/
  @link_target ~r/\]\([^)\s]*\)/

  # Mention patterns. NAMES is replaced with an alternation of escaped task names.
  #   * dotted names: bounded, optional `mix ` prefix, not a longer dotted name or file path;
  #   * undotted names (the bare verify task): the `mix ` prefix is required, so the English
  #     word does not match;
  #   * glob and brace forms: the literal prefix of `mix <prefix>*`, `mix <prefix>{a,b}` and the
  #     backticked dotted `<prefix>*` (the prefix may end in a dot, as in `mix verify.*`, or stop
  #     mid-name, as in `mix verify.phase*`). It is a mention of the family when some repo-only
  #     name starts with the prefix and no shipped task name does, so `mix scrypath.*` (which
  #     names the shipped operator tasks) is not one while `mix scrypath_ops.*` is. A `*` that
  #     closes a bold span (`**mix verify.all**`) is not a glob. The report names the prefix
  #     without its trailing dot.
  @dotted_template ~S/(?<![\w.])(?:mix\s+)?(NAMES)(?![\w]|\.[\w*])/
  @undotted_template ~S/(?<![\w.])mix\s+(NAMES)(?![\w]|\.\w)/
  @glob_form ~r/(?:(?<![\w.])mix\s+|`(?=[a-z0-9_]+\.))([a-z0-9_]+(?:\.[a-z0-9_]+)*\.?)(?:\*(?!\*)|\{)/

  @type unit :: %{line: pos_integer(), text: String.t(), lead_in: String.t() | nil}
  @type violation :: {Path.t(), pos_integer(), String.t()}

  @doc "Names of the tasks the shipped lib/ tree defines, derived from its source files."
  @spec shipped_tasks() :: [String.t()]
  def shipped_tasks, do: task_names(@shipped_task_glob)

  @doc "Names of the tasks defined outside the shipped lib/ tree, derived from the source trees."
  @spec repo_only_tasks() :: [String.t()]
  def repo_only_tasks do
    shipped = shipped_tasks()

    @task_source_globs
    |> Enum.flat_map(&task_names/1)
    |> Enum.uniq()
    |> Kernel.--(shipped)
    |> Enum.sort()
  end

  defp task_names(glob) do
    glob
    |> Path.wildcard()
    |> Enum.sort()
    |> Enum.map(&{&1, File.read!(&1)})
    |> PackageContract.collect_task_modules()
    |> Enum.map(&elem(&1, 0))
  end

  @doc "Sorted relative paths of the text files expanded from the mix.exs package `files:`."
  @spec shipped_files() :: [Path.t()]
  def shipped_files do
    files =
      for entry <- Scrypath.MixProject.project()[:package][:files],
          path <- Path.wildcard(entry, match_dot: true),
          file <- expand(path),
          text_file?(file),
          uniq: true,
          do: file

    Enum.sort(files)
  end

  defp expand(path) do
    if File.dir?(path),
      do: Path.wildcard(Path.join(path, "**/*"), match_dot: true),
      else: [path]
  end

  defp text_file?(file) do
    File.regular?(file) and Path.extname(file) in @text_exts and valid_utf8?(file)
  end

  defp valid_utf8?(file) do
    case File.read(file) do
      {:ok, contents} -> String.valid?(contents)
      {:error, _reason} -> false
    end
  end

  @spec allowlist() :: [Path.t()]
  def allowlist, do: @allowlist

  @spec exempt() :: %{Path.t() => map()}
  def exempt, do: @exempt

  @spec qualifier_patterns() :: [Regex.t()]
  def qualifier_patterns, do: @qualifier_patterns

  @spec qualifier_example() :: String.t()
  def qualifier_example, do: @qualifier_example

  @doc "True when every qualifier pattern matches the text."
  @spec qualified?(String.t()) :: boolean()
  def qualified?(text), do: Enum.all?(@qualifier_patterns, &Regex.match?(&1, text))

  @doc """
  True when the unit carries the qualifier itself, or (fences and tables only) when the
  sentence directly above it does. The two texts are never combined.
  """
  @spec unit_qualified?(unit()) :: boolean()
  def unit_qualified?(%{text: text, lead_in: lead_in}) do
    qualified?(text) or (is_binary(lead_in) and qualified?(lead_in))
  end

  # The qualifier unit (locked by the tightened qualifier-unit decision):
  #
  #   * a plain paragraph is split into one unit per sentence (@sentence_boundary), so the
  #     qualifier must sit in the same sentence as the mention; a sibling sentence does not count;
  #   * each list item (continuation lines included) is one unit, never split into sentences;
  #   * each heading is one unit;
  #   * each table row is one unit, and a fenced code block is one unit (fence-open line to its
  #     close). Both carry `lead_in`: the last sentence of the paragraph directly above (only
  #     blank lines between), else nil. A fence or table is therefore qualified through the
  #     sentence directly above it, never through an earlier sentence of the same paragraph.
  #
  # `line` is the 1-based line on which the unit starts.
  @doc "Splits text into qualifier units. See the unit rule in the comment above."
  @spec units(String.t()) :: [unit()]
  def units(text) do
    text
    |> blocks()
    |> Enum.reduce(%{units: [], lead: nil, prev: :blank}, &add_block/2)
    |> Map.fetch!(:units)
    |> Enum.reverse()
  end

  # Pass 1: group lines into blocks (kind, start line, text).
  defp blocks(text) do
    text
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.reduce(%{blocks: [], fence: nil}, &read_line/2)
    |> Map.fetch!(:blocks)
    |> Enum.reverse()
  end

  defp read_line({line, _number}, %{fence: marker, blocks: [fence | rest]} = acc)
       when is_binary(marker) do
    closed? = line |> String.trim_leading() |> String.starts_with?(marker)
    %{acc | blocks: [append(fence, line) | rest], fence: if(closed?, do: nil, else: marker)}
  end

  defp read_line({line, number}, acc) do
    case classify(line) do
      {:fence, marker} -> %{push(acc, :fence, number, line) | fence: marker}
      :text -> continue_or_push(acc, number, line)
      kind -> push(acc, kind, number, line)
    end
  end

  defp classify(line) do
    case Regex.run(@fence_open, line, capture: :all_but_first) do
      [marker] -> {:fence, marker}
      nil -> classify_other(line)
    end
  end

  defp classify_other(line) do
    cond do
      String.trim(line) == "" -> :blank
      Regex.match?(@table_row, line) -> :table_row
      Regex.match?(@heading, line) -> :heading
      Regex.match?(@list_item, line) -> :list_item
      true -> :text
    end
  end

  defp push(acc, kind, number, line) do
    %{acc | blocks: [%{kind: kind, line: number, text: line} | acc.blocks]}
  end

  # A plain line continues an open paragraph or list item; anything else starts a paragraph.
  defp continue_or_push(%{blocks: [%{kind: kind} = head | rest]} = acc, _number, line)
       when kind in [:paragraph, :list_item] do
    %{acc | blocks: [append(head, line) | rest]}
  end

  defp continue_or_push(acc, number, line), do: push(acc, :paragraph, number, line)

  defp append(block, line), do: %{block | text: block.text <> "\n" <> line}

  # Pass 2: turn blocks into units, tracking the lead-in sentence for fences and tables.
  defp add_block(block, acc) do
    place(block, leave_table(acc, block.kind))
  end

  # A table ends at the first block that is not another row; its lead-in must not leak.
  defp leave_table(%{prev: :table_row} = acc, kind) when kind != :table_row,
    do: %{acc | lead: nil}

  defp leave_table(acc, _kind), do: acc

  defp place(%{kind: :blank}, acc), do: %{acc | prev: :blank}

  defp place(%{kind: :paragraph} = block, acc) do
    sentences = sentence_units(block)
    last = List.last(sentences)
    %{acc | units: Enum.reverse(sentences, acc.units), lead: last.text, prev: :paragraph}
  end

  defp place(%{kind: kind} = block, acc) when kind in [:list_item, :heading] do
    %{acc | units: [unit(block, nil) | acc.units], lead: nil, prev: kind}
  end

  defp place(%{kind: :fence} = block, acc) do
    %{acc | units: [unit(block, acc.lead) | acc.units], lead: nil, prev: :fence}
  end

  defp place(%{kind: :table_row} = block, acc) do
    %{acc | units: [unit(block, acc.lead) | acc.units], prev: :table_row}
  end

  defp unit(block, lead_in), do: %{line: block.line, text: block.text, lead_in: lead_in}

  defp sentence_units(%{line: line, text: text}) do
    masked = mask(text)

    {from, ranges} =
      @sentence_boundary
      |> Regex.scan(masked, return: :index)
      |> Enum.reduce({0, []}, fn [{start, len}, {punct_start, punct_len}], {from, acc} ->
        {start + len, [{from, punct_start + punct_len - from} | acc]}
      end)

    [{from, byte_size(text) - from} | ranges]
    |> Enum.reverse()
    |> Enum.map(fn {offset, length} ->
      %{
        line: line + newlines(binary_part(text, 0, offset)),
        text: text |> binary_part(offset, length) |> String.trim(),
        lead_in: nil
      }
    end)
  end

  # Replace code-span and link-target interiors with `x`, keeping delimiters and byte length.
  defp mask(text) do
    text
    |> then(&Regex.replace(@code_span, &1, fn span -> fill(span, 1, 1) end))
    |> then(&Regex.replace(@link_target, &1, fn target -> fill(target, 2, 1) end))
  end

  defp fill(span, lead, trail) do
    size = byte_size(span)

    binary_part(span, 0, lead) <>
      String.duplicate("x", size - lead - trail) <> binary_part(span, size - trail, trail)
  end

  defp newlines(text), do: text |> :binary.matches("\n") |> length()

  @doc """
  Repo-only names mentioned in a unit text, deduplicated, in order of first appearance.

  A glob or brace spelling (`mix verify.*`, `mix verify.phase{11,14}`, backticked `verify.*`)
  counts as a mention of its literal prefix (`verify`, `verify.phase`) when some repo-only name
  starts with that prefix and no name in `shipped` does. `shipped` defaults to none, which
  reports every such prefix (the stricter reading).
  """
  @spec mentions(String.t(), [String.t()], [String.t()]) :: [String.t()]
  def mentions(text, names, shipped \\ []) do
    text |> mention_hits(matchers(names, shipped)) |> Enum.map(&elem(&1, 0))
  end

  # Each matcher is `{regex, name_for}`: the regex captures one group, and `name_for.(capture)`
  # is the reported name, or nil when the capture is not a mention.
  defp matchers(names, shipped) do
    {undotted, dotted} = Enum.split_with(names, &(not String.contains?(&1, ".")))

    [
      matcher(dotted, @dotted_template),
      matcher(undotted, @undotted_template),
      glob_matcher(names, shipped)
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp matcher([], _template), do: nil

  defp matcher(names, template) do
    alternation =
      names
      |> Enum.sort_by(&{-String.length(&1), &1})
      |> Enum.map_join("|", &Regex.escape/1)

    {template |> String.replace("NAMES", alternation) |> Regex.compile!(), & &1}
  end

  defp glob_matcher([], _shipped), do: nil

  defp glob_matcher(names, shipped) do
    name_for = fn prefix ->
      if Enum.any?(names, &String.starts_with?(&1, prefix)) and
           not Enum.any?(shipped, &String.starts_with?(&1, prefix)),
         do: String.trim_trailing(prefix, ".")
    end

    {@glob_form, name_for}
  end

  # `{name, byte_index}` pairs, first appearance per name, in text order.
  defp mention_hits(text, matchers) do
    matchers
    |> Enum.flat_map(fn {regex, name_for} ->
      for [{start, len}] <- Regex.scan(regex, text, capture: :all_but_first, return: :index),
          name = name_for.(binary_part(text, start, len)),
          do: {name, start}
    end)
    |> Enum.sort_by(&elem(&1, 1))
    |> Enum.uniq_by(&elem(&1, 0))
  end

  @doc """
  Scans `{path, text}` pairs for unqualified mentions of the given repo-only names.

  Allowlisted paths and the whole-file exemption are skipped; the line-scoped exemption has its
  matching lines blanked first (line numbers stay true). Returns sorted
  `{path, line, name}` tuples, one per unit and name, at the line where the name first
  appears in the unit. `shipped` is as in `mentions/3`.
  """
  @spec scan([{Path.t(), String.t()}], [String.t()], [String.t()]) :: [violation()]
  def scan(files, repo_only, shipped \\ []) do
    matchers = matchers(repo_only, shipped)

    files
    |> Enum.flat_map(fn {path, text} -> scan_file(path, text, matchers) end)
    |> Enum.sort()
  end

  defp scan_file(path, text, matchers) do
    case prepare(path, text) do
      :skip -> []
      prepared -> file_violations(path, prepared, matchers)
    end
  end

  defp prepare(path, text) do
    if path in @allowlist, do: :skip, else: apply_exemption(Map.get(@exempt, path), text)
  end

  defp apply_exemption(nil, text), do: text
  defp apply_exemption(%{scope: :whole_file}, _text), do: :skip
  defp apply_exemption(%{scope: {:lines, pattern}}, text), do: blank_lines(text, pattern)

  defp blank_lines(text, pattern) do
    text
    |> String.split("\n")
    |> Enum.map_join("\n", fn line -> if Regex.match?(pattern, line), do: "", else: line end)
  end

  # Cheap whole-file prefilter: a mention cannot sit in a unit unless it sits in the file.
  defp file_violations(path, text, matchers) do
    if Enum.any?(matchers, fn {regex, _name_for} -> Regex.match?(regex, text) end) do
      for unit <- units(text),
          not unit_qualified?(unit),
          {name, index} <- mention_hits(unit.text, matchers) do
        {path, unit.line + newlines(binary_part(unit.text, 0, index)), name}
      end
    else
      []
    end
  end

  @doc "Scan of the real shipped files against the derived repo-only names."
  @spec violations() :: [violation()]
  def violations do
    files = for path <- shipped_files(), do: {path, File.read!(path)}
    scan(files, repo_only_tasks(), shipped_tasks())
  end

  # TRUTH-03 link helpers (Phase 192). A shipped markdown file is read in two places: on GitHub,
  # where a relative link means a path in the repository, and on HexDocs, where ExDoc turns a
  # relative `.md` link into the page of the extra with that file name, and any `README.md`
  # basename into the Scrypath landing page. A repository file outside the package therefore has to
  # be linked by absolute URL, under this base.
  @repo_blob_base "https://github.com/szTheory/scrypath/blob/main/"

  # An inline link or image target: the text after `](` up to whitespace or the closing
  # parenthesis, so an optional title is left out. Reference-style definitions and autolinks do
  # not occur in the shipped markdown. HTML attributes (`src`, `srcset`, `href` in the README
  # header block, which a brand test pins to a commit) are not markdown links and are not seen.
  @inline_link ~r/\]\(\s*([^)\s]*)/

  # The text of an ATX heading, without its marker and closing marks.
  @heading_text ~r/^\s{0,3}[#]{1,6}\s+(.*?)\s*[#]*\s*$/

  @doc "The base URL repository files outside the package are linked by."
  @spec repo_blob_base() :: String.t()
  def repo_blob_base, do: @repo_blob_base

  @doc """
  `{line, target}` for every inline markdown link and image target, outside fenced code blocks
  and code spans. `line` is the 1-based line the target sits on (the line of the `](`).
  """
  @spec markdown_links(String.t()) :: [{pos_integer(), String.t()}]
  def markdown_links(text) do
    text
    |> blocks()
    |> Enum.reject(&(&1.kind in [:fence, :blank]))
    |> Enum.flat_map(&block_links/1)
  end

  defp block_links(%{line: line, text: text}) do
    masked = Regex.replace(@code_span, text, fn span -> fill(span, 1, 1) end)

    for [{start, _length}, {from, size}] <- Regex.scan(@inline_link, masked, return: :index) do
      {line + newlines(binary_part(text, 0, start)), binary_part(text, from, size)}
    end
  end

  @doc """
  True when the markdown text links the guide with this slug (the file name without `.md`): by
  its relative `guides/<slug>.md` form, as a README read on GitHub links it, or by its
  `https://hexdocs.pm/scrypath/<slug>.html` form, as the trimmed README links it. A fragment
  after the target is ignored. A plain mention outside a link does not count.
  """
  @spec links_to_guide?(String.t(), String.t()) :: boolean()
  def links_to_guide?(text, slug) do
    forms = ["guides/#{slug}.md", "https://hexdocs.pm/scrypath/#{slug}.html"]

    text
    |> markdown_links()
    |> Enum.any?(fn {_line, target} -> hd(String.split(target, "#", parts: 2)) in forms end)
  end

  @doc """
  The anchor GitHub gives a heading: lowercase, every character other than a letter, a digit, a
  connector such as an underscore, a space or a hyphen dropped, spaces to hyphens.
  """
  @spec github_slug(String.t()) :: String.t()
  def github_slug(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^\p{L}\p{M}\p{N}\p{Pc} -]/u, "")
    |> String.replace(" ", "-")
  end

  @doc """
  The anchors of the ATX headings in a markdown text, in order, outside fenced code. A repeated
  anchor gets `-1`, `-2` and so on, as on GitHub.
  """
  @spec heading_slugs(String.t()) :: [String.t()]
  def heading_slugs(text) do
    text
    |> blocks()
    |> Enum.filter(&(&1.kind == :heading))
    |> Enum.map(&(&1.text |> heading_title() |> github_slug()))
    |> number_repeats()
  end

  # Link markup inside a heading counts by its text, as in the rendered heading.
  defp heading_title(line) do
    [title] = Regex.run(@heading_text, line, capture: :all_but_first)
    Regex.replace(~r/\[([^\]]*)\]\([^)]*\)/, title, "\\1")
  end

  defp number_repeats(slugs) do
    {numbered, _seen} =
      Enum.map_reduce(slugs, %{}, fn slug, seen ->
        count = Map.get(seen, slug, 0)
        {if(count == 0, do: slug, else: "#{slug}-#{count}"), Map.put(seen, slug, count + 1)}
      end)

    numbered
  end
end
