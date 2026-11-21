defmodule Scrypath.ReadmeContractTest do
  # Deliberately untagged: README and owner-map drift fails the default `mix test` and the
  # `core` lane, following the backfill_contract_docs_test precedent. Plain file reads only (no
  # network, no docs build). The quick path tests (README-02) are here; the README shape tests
  # (README-01) join them in the trim commit.
  use ExUnit.Case, async: true

  alias Scrypath.Release.ShippedDocs
  alias Scrypath.Release.SnippetParity

  @owner_map ".planning/reference/CLAIM-OWNER-MAP.md"
  @readme_path "README.md"
  @golden_path "guides/golden-path.md"

  # Phrases that make the quick path honest, kept as data so the list is reviewable. A phrase is
  # matched case-insensitively. The prerequisite and the eventual-consistency statement must both
  # appear before the README's first code block and before the quick path's first code block.
  @prerequisite_phrases ["needs a running Meilisearch server", "Start a Meilisearch server first"]
  @consistency_phrases ["eventually consistent"]

  # Words a README sentence must not use to promise a time. Matched on word boundaries,
  # case-insensitively, in prose only (fenced code is skipped).
  @time_promises [
    "in five minutes",
    "in 5 minutes",
    "in minutes",
    "in a few minutes",
    "in seconds",
    "quickly",
    "instantly",
    "in no time",
    "under five minutes",
    "just works"
  ]

  # README budget. The numbers are chosen, not measured; the README budget section of the owner map
  # records the same values and the word cap test compares them.
  @word_cap 800
  # A stub guard: it fails an accidentally emptied README. The 600 to 800 range is the owner-map
  # target and @word_cap is its top, so this floor is deliberately lower than the range.
  @word_floor 400
  @fence_line_cap 60
  @onward_link_cap 3

  # Hosts, with a path prefix where one is needed, that a README link may target. Every README
  # link is absolute: the README is read on GitHub, hex.pm and HexDocs, and a relative link
  # resolves differently on each.
  @allowed_hosts [
    "github.com/szTheory/scrypath",
    "hexdocs.pm/scrypath",
    "hex.pm/packages/scrypath",
    "img.shields.io",
    "raw.githubusercontent.com/szTheory/scrypath",
    "sztheory.github.io/scrypath"
  ]

  # A link to a repository path (Plan 03's definition, copied from shipped_docs_contract_test.exs):
  # blob or tree, a ref, then a path. Captures: kind, ref, path.
  @repo_path_link ~r/^https:\/\/github\.com\/szTheory\/scrypath\/(blob|tree)\/([^\/#?]+)(?:\/([^#?]*))?(?:\?[^#]*)?(?:#(.*))?$/

  # The "Do not say" words of brand/BRAND.md, matched on word boundaries in README prose.
  @brand_do_not_say [
    "magic",
    "effortless",
    "it just stays in sync",
    "real-time",
    "federated",
    "hydration",
    "playbook",
    "AI-powered"
  ]

  # The level-2 headings the README has, in order: fit, does not fit, installation, one quick path,
  # and the onward links.
  @section_shape [
    "When Scrypath Fits",
    "When It Does Not",
    "Installation",
    "Quick Path",
    "Next Steps"
  ]

  # The last quick-path code block ends in a three-argument search call and its result:
  # a module, a quoted query, a non-empty keyword list written without brackets, then a
  # `result.` line.
  @search_call ~r/Scrypath\.search\(\s*([A-Z][\w.]*)\s*,\s*"([^"\n]+)"\s*,\s*([a-z_]+:\s.+?)\s*\)\s*\n\s*result\.[a-z_]+\s*\z/s

  @required_claims ~w(
    what-it-is
    fit
    non-fit
    install-line
    sync-modes
    support-policy
    operator-ui-status
  )

  # The whole Owner cell, after trimming and removing surrounding backticks: exactly one owner.
  @owner_cell ~r/\A(README|website|retired|guide:[a-z0-9-]+|doc:[A-Za-z0-9_.\/-]+)\z/

  # One Pinned-by entry: backticked repo path, the word `has`, backticked token.
  @entry ~r/\A`([^`]+)`\s+has\s+`([^`]+)`\z/

  describe "claim owner map" do
    test "the claim owner map names exactly one owning surface for each required claim" do
      rows = owner_rows()
      extras = Scrypath.MixProject.project()[:docs][:extras]

      assert length(rows) >= 30,
             "the owner map has only #{length(rows)} rows; the table parse may have gone vacuous"

      ids = Enum.map(rows, & &1.id)
      assert ids == Enum.uniq(ids), "duplicate claim ids: #{inspect(ids -- Enum.uniq(ids))}"

      for id <- @required_claims do
        assert Enum.count(rows, &(&1.id == id)) == 1,
               "required claim #{id} must appear exactly once in the owner map"
      end

      for row <- rows do
        owner = String.trim(row.owner, "`")

        assert Regex.match?(@owner_cell, owner),
               "claim #{row.id}: owner cell #{inspect(row.owner)} must name exactly one owner " <>
                 "(README, guide:<slug>, doc:<path>, website or retired)"

        case owner do
          "guide:" <> slug ->
            assert "guides/#{slug}.md" in extras,
                   "claim #{row.id}: guide:#{slug} is not a docs extra in mix.exs"

          "doc:" <> path ->
            assert File.regular?(path), "claim #{row.id}: doc:#{path} does not exist"

          _other ->
            :ok
        end
      end

      assert String.contains?(section(File.read!(@owner_map), "## README budget"), "800"),
             "the README budget section does not record the 800-word cap"
    end

    test "every owner-map Pinned-by token is present in its named file" do
      for row <- owner_rows() do
        owner = String.trim(row.owner, "`")

        if owner == "retired" do
          assert Regex.match?(~r/\Areason:\s*\S/, row.pinned_by),
                 "claim #{row.id}: a retired row needs `reason:` and a reason in Pinned by"
        else
          entries = parse_entries(row)

          assert entries != [],
                 "claim #{row.id}: a non-retired row needs at least one Pinned-by entry"

          own = owner_file(owner)

          if own do
            assert Enum.any?(entries, fn {path, _token} -> path == own end),
                   "claim #{row.id}: no Pinned-by entry names the owner's own file #{own}"
          end

          for {path, token} <- entries do
            assert File.regular?(path),
                   "claim #{row.id}: Pinned-by path #{path} does not exist"

            assert String.contains?(File.read!(path), token),
                   "claim #{row.id}: #{path} no longer contains #{inspect(token)}"
          end
        end
      end
    end

    test "CONTRIBUTING carries the same-PR rule for public-surface claims" do
      contributing = File.read!("CONTRIBUTING.md")

      assert contributing =~ "Same-PR rule", "CONTRIBUTING.md lost its Same-PR rule bullet"
      assert contributing =~ "same PR", "the Same-PR rule no longer says to update in the same PR"

      assert contributing =~ "https://github.com/szTheory/scrypath/blob/main/#{@owner_map}",
             "the Same-PR rule no longer links the claim owner map"

      assert File.regular?(@owner_map), "#{@owner_map} does not exist"
    end
  end

  describe "quick path" do
    test "the quick path states the Meilisearch prerequisite and eventual consistency before the first code block" do
      readme = File.read!(@readme_path)
      quick = quick_path(readme)

      assert_states_both(before_first_fence(readme), "README, before its first code block")
      assert_states_both(before_first_fence(quick), "Quick Path, before its first code block")
    end

    test "the quick path ends in a Scrypath.search/3 call and its result" do
      quick = quick_path(File.read!(@readme_path))
      elixir = SnippetParity.elixir_fences(quick)

      assert length(elixir) >= 4,
             "the Quick Path has #{length(elixir)} elixir fences; expected schema, config, sync and search"

      last = List.last(elixir)

      captures = Regex.run(@search_call, last.body)

      assert captures,
             "the last Quick Path code block must end in " <>
               "`Scrypath.search(Module, \"query\", opts)` followed by a `result.` line; got:\n#{last.body}"

      [_all, module, _query, opts_text] = captures
      {opts, _binding} = Code.eval_string("[" <> opts_text <> "]")

      assert Keyword.keyword?(opts) and opts != [],
             "the search call needs an explicit, non-empty opts list; got #{opts_text}"

      page = Scrypath.Options.validate_search_page(Keyword.fetch!(opts, :page))

      assert match?({:ok, _page}, page),
             "the page option in the Quick Path is not one Scrypath accepts: #{opts_text}"

      assert Enum.any?(elixir, &String.contains?(&1.body, "defmodule #{module} do")),
             "the searched module #{module} is not the schema the Quick Path declares"
    end

    test "the quick path syncs a record inline before it searches" do
      elixir = SnippetParity.elixir_fences(quick_path(File.read!(@readme_path)))

      sync =
        Enum.find_index(elixir, &(&1.body =~ ~r/Scrypath\.sync_record\(.*sync_mode: :inline/))

      search = Enum.find_index(elixir, &(&1.body =~ "Scrypath.search("))

      assert sync, "the Quick Path has no Scrypath.sync_record/3 call with sync_mode: :inline"
      assert search, "the Quick Path has no Scrypath.search/3 call"
      assert sync < search, "the Quick Path must sync a record before it searches"

      assert search == length(elixir) - 1,
             "the search call must be the Quick Path's last code block"
    end

    test "the quick path schema snippet is identical to the golden path" do
      assert_snippet_parity(:schema)
    end

    for path <- [@readme_path, @golden_path] do
      test "#{path} config snippet resolves through Scrypath's runtime options" do
        fence = SnippetParity.config_fence(File.read!(unquote(path)))

        assert fence, "#{unquote(path)} has no elixir fence containing `config :scrypath`"

        assert config_apps(fence.body) == ["scrypath"],
               "#{unquote(path)} config must be keyed on :scrypath, the application Scrypath.Config " <>
                 "reads, not on the host app; got #{inspect(config_apps(fence.body))}"

        options = Scrypath.Options.validate_runtime_options!(evaluate_defaults(fence.body))

        assert options[:backend] == Scrypath.Meilisearch
        assert is_binary(options[:meilisearch_url])
      end
    end

    test "the README config snippet matches the golden path config snippet" do
      assert_snippet_parity(:config)
    end

    test "no README sentence promises a time" do
      prose = SnippetParity.prose(File.read!(@readme_path))

      assert String.length(prose) > 1_000, "the prose extraction looks vacuous"

      found =
        for phrase <- @time_promises, Regex.match?(word_pattern(phrase), prose), do: phrase

      assert found == [],
             "README prose promises a time with #{inspect(found)}; say what happens, not how fast"
    end

    test "the quick path links the golden path" do
      assert ShippedDocs.links_to_guide?(quick_path(File.read!(@readme_path)), "golden-path"),
             "the Quick Path must link the golden path guide"
    end
  end

  describe "README shape" do
    test "README stays within the recorded word cap" do
      readme = File.read!(@readme_path)
      words = word_count(readme)

      assert words >= @word_floor,
             "README has #{words} words, under the #{@word_floor} word floor"

      assert words <= @word_cap,
             "README has #{words} words; the cap is #{@word_cap}. Move a claim to its owner " <>
               "(#{@owner_map}) instead of raising the cap"

      budget = section(File.read!(@owner_map), "## README budget")
      assert budget_number(budget, "Word cap", ~r/(\d+)\s+words/) == @word_cap
      assert budget_number(budget, "Floor", ~r/(\d+)\s+words/) == @word_floor
      assert budget_number(budget, "Fenced code", ~r/(\d+)\s+lines/) == @fence_line_cap
      assert budget_number(budget, "Onward links", ~r/at most\s+(\d+)/) == @onward_link_cap

      fence_lines =
        readme
        |> SnippetParity.fences()
        |> Enum.map(&(&1.body |> String.trim_trailing("\n") |> String.split("\n") |> length()))
        |> Enum.sum()

      assert fence_lines in 1..@fence_line_cap//1,
             "README has #{fence_lines} fenced code lines; the cap is #{@fence_line_cap}"
    end

    test "at most three onward links follow the quick path" do
      readme = File.read!(@readme_path)
      last_fence = readme |> SnippetParity.fences() |> List.last()
      {from, to} = h2_range(readme, "Quick Path")

      assert last_fence, "README has no fenced code block"

      assert last_fence.start > from and last_fence.stop <= to,
             "the README's last code block must be the Quick Path's last code block"

      onward = binary_part(readme, last_fence.stop, byte_size(readme) - last_fence.stop)
      assert onward =~ "\n## ", "no onward section follows the Quick Path's last code block"

      links = ShippedDocs.markdown_links(onward)

      assert length(links) <= @onward_link_cap,
             "#{length(links)} links follow the Quick Path's last code block " <>
               "(cap #{@onward_link_cap}): #{inspect(Enum.map(links, &elem(&1, 1)))}"
    end

    test "the README has no route block and keeps the fixed section shape" do
      readme = File.read!(@readme_path)

      headings =
        ~r/^## (.+)$/m
        |> Regex.scan(SnippetParity.prose(readme), capture: :all_but_first)
        |> List.flatten()

      assert headings == @section_shape,
             "README level-2 headings are #{inspect(headings)}; expected #{inspect(@section_shape)}"

      refute readme =~ "## Choose a route"
    end

    test "every README link is absolute and targets an allowed host" do
      links = readme_links()

      assert length(links) >= 10,
             "only #{length(links)} README links found; the scan may be vacuous"

      for {line, target} <- links do
        assert String.starts_with?(target, "https://"),
               "README.md:#{line} link #{inspect(target)} is not an absolute https URL"

        location =
          target
          |> String.replace_prefix("https://", "")
          |> String.split(~r/[?#]/, parts: 2)
          |> hd()

        assert Enum.any?(@allowed_hosts, &under_prefix?(location, &1)),
               "README.md:#{line} link #{target} is not on an allowed host #{inspect(@allowed_hosts)}"
      end
    end

    test "repo-path links use blob/main and the path exists" do
      repo_links =
        for {line, target} <- readme_links(),
            [_all, _kind, ref, path | _fragment] <- [Regex.run(@repo_path_link, target)],
            do: {line, target, ref, path}

      assert length(repo_links) >= 2,
             "README has #{length(repo_links)} repo-path links; expected at least 2"

      for {line, target, ref, path} <- repo_links do
        assert ref == "main", "README.md:#{line} #{target} must use the main ref, not #{ref}"

        assert path != "" and File.exists?(path),
               "README.md:#{line} #{target}: #{path} does not exist"
      end
    end

    test "HexDocs links target an existing extra or module page" do
      extras = Scrypath.MixProject.project()[:docs][:extras]
      pages = for extra <- extras, do: extra |> Path.basename(".md") |> String.downcase()

      hexdocs =
        for {line, target} <- readme_links(),
            [_all, page] <- [
              Regex.run(~r{^https://hexdocs\.pm/scrypath/([^/#?]+)\.html(?:[#?].*)?$}, target)
            ],
            do: {line, target, page}

      assert length(hexdocs) >= 4,
             "README has #{length(hexdocs)} HexDocs page links; expected at least 4"

      for {line, target, page} <- hexdocs do
        assert String.downcase(page) in pages or documented_module?(page),
               "README.md:#{line} #{target}: #{page}.html is neither a docs extra nor a documented module"
      end
    end

    test "the README names no repo-only task outside a source-checkout qualifier" do
      readme = File.read!(@readme_path)

      assert ShippedDocs.scan(
               [{@readme_path, readme}],
               ShippedDocs.repo_only_tasks(),
               ShippedDocs.shipped_tasks()
             ) == []

      for unit <- ShippedDocs.units(readme), unit.text =~ "mix verify." do
        assert ShippedDocs.unit_qualified?(unit),
               "README.md:#{unit.line} names a `mix verify.` task without the source-checkout qualifier"
      end
    end

    test "the README avoids the brand's do-not-say words" do
      prose = SnippetParity.prose(File.read!(@readme_path))
      found = for word <- @brand_do_not_say, Regex.match?(word_pattern(word), prose), do: word

      assert found == [],
             "README prose uses words from the brand's do-not-say list: #{inspect(found)}"
    end

    test "the README states the operator UI lives in the source checkout and is not in the Hex package" do
      mentions =
        for unit <- ShippedDocs.units(File.read!(@readme_path)),
            unit.text =~ "operator UI",
            do: unit

      assert mentions != [], "the README never mentions the operator UI"

      assert Enum.any?(mentions, &ShippedDocs.qualified?(&1.text)),
             "no README sentence about the operator UI says it lives in the source checkout and " <>
               "is not in the Hex package"
    end
  end

  # One map per table row: the seven cells by name, backticks on the id removed.
  defp owner_rows do
    @owner_map
    |> File.read!()
    |> section("## Owner map")
    |> String.split("\n")
    |> Enum.filter(&String.starts_with?(&1, "|"))
    |> Enum.map(&split_row/1)
    |> Enum.reject(fn [id | _] -> id == "Claim id" or Regex.match?(~r/\A[-: ]+\z/, id) end)
    |> Enum.map(fn cells ->
      assert length(cells) == 7,
             "owner-map row has #{length(cells)} cells, expected 7: #{inspect(cells)}"

      [id, claim, owner, readme, hexdocs, website, pinned_by] = cells

      %{
        id: String.trim(id, "`"),
        claim: claim,
        owner: owner,
        readme: readme,
        hexdocs: hexdocs,
        website: website,
        pinned_by: pinned_by
      }
    end)
  end

  defp split_row(line) do
    line
    |> String.trim()
    |> String.trim_leading("|")
    |> String.trim_trailing("|")
    |> String.split("|")
    |> Enum.map(&String.trim/1)
  end

  defp parse_entries(row) do
    row.pinned_by
    |> String.split("; ")
    |> Enum.map(fn entry ->
      case Regex.run(@entry, String.trim(entry)) do
        [_all, path, token] ->
          {path, token}

        nil ->
          flunk("claim #{row.id}: Pinned-by entry #{inspect(entry)} must be `path` has `token`")
      end
    end)
  end

  defp owner_file("README"), do: "README.md"
  defp owner_file("guide:" <> slug), do: "guides/#{slug}.md"
  defp owner_file("doc:" <> path), do: path
  defp owner_file(_other), do: nil

  # Text between a level-2 heading and the next level-2 heading.
  defp section(text, heading) do
    case String.split(text, "\n" <> heading <> "\n", parts: 2) do
      [_before, rest] ->
        rest |> String.split(~r/^## /m, parts: 2) |> hd()

      _missing ->
        flunk("#{@owner_map} has no #{inspect(heading)} section")
    end
  end

  # Text from the `## Quick Path` heading to the next level-2 heading.
  defp quick_path(readme) do
    {from, to} = h2_range(readme, "Quick Path")
    binary_part(readme, from, to - from)
  end

  defp before_first_fence(text), do: text |> String.split("```", parts: 2) |> hd()

  # README and golden path snippets are the same, or a marker with a reason says why not. The
  # comparison itself is the shared definition in Scrypath.Release.SnippetParity.
  defp assert_snippet_parity(kind) do
    case SnippetParity.check(File.read!(@readme_path), File.read!(@golden_path), kind) do
      :identical ->
        :ok

      {:marked, _side, reason} ->
        assert String.trim(reason) != "", "the snippet marker carries no reason"

      other ->
        flunk(
          "the README #{kind} snippet and #{@golden_path} do not match (#{inspect(other)}); make " <>
            "them identical or put <!-- scrypath:snippet-intentionally-differs: <reason> --> " <>
            "directly above either snippet"
        )
    end
  end

  defp word_pattern(phrase), do: Regex.compile!("\\b" <> Regex.escape(phrase) <> "\\b", "i")

  defp assert_states_both(text, where) do
    assert mentions_any?(text, @prerequisite_phrases),
           "#{where}: no Meilisearch prerequisite phrase from #{inspect(@prerequisite_phrases)}"

    assert mentions_any?(text, @consistency_phrases),
           "#{where}: no eventual-consistency phrase from #{inspect(@consistency_phrases)}"
  end

  defp mentions_any?(text, phrases) do
    lowered = String.downcase(text)
    Enum.any?(phrases, &String.contains?(lowered, String.downcase(&1)))
  end

  # The application names a config fence configures: `config :scrypath, ...` gives "scrypath".
  defp config_apps(body) do
    ~r/^\s*config\s+:(\w+)/m
    |> Regex.scan(body, capture: :all_but_first)
    |> List.flatten()
    |> Enum.uniq()
  end

  # Reads a config fence the way Mix reads config/*.exs and returns the :scrypath :defaults list.
  defp evaluate_defaults(body) do
    source = if body =~ "import Config", do: body, else: "import Config\n\n" <> body
    name = "readme-config-#{System.pid()}-#{System.unique_integer([:positive])}.exs"
    path = Path.join(System.tmp_dir!(), name)
    File.write!(path, source)

    try do
      path |> Config.Reader.read!() |> Keyword.fetch!(:scrypath) |> Keyword.fetch!(:defaults)
    after
      File.rm(path)
    end
  end

  # Whitespace-separated tokens after the header block, prose, links and fences included.
  defp word_count(text) do
    text
    |> String.replace(~r/<p align="center">.*?<\/p>/s, "")
    |> String.split(~r/\s+/, trim: true)
    |> length()
  end

  # `{from, to}` byte range of a level-2 section, from its heading line to the next level-2 heading.
  defp h2_range(text, heading) do
    case :binary.match(text, "\n## " <> heading <> "\n") do
      {at, length} ->
        rest_from = at + length
        rest = binary_part(text, rest_from, byte_size(text) - rest_from)

        case Regex.run(~r/^## /m, rest, return: :index) do
          [{offset, _size}] -> {at, rest_from + offset}
          nil -> {at, byte_size(text)}
        end

      :nomatch ->
        flunk("README.md has no `## #{heading}` section")
    end
  end

  defp budget_number(budget, label, pattern) do
    row = budget |> String.split("\n") |> Enum.find(&String.starts_with?(&1, "| #{label} |"))
    assert row, "the owner-map README budget has no #{label} row"
    [_all, number] = Regex.run(pattern, row)
    String.to_integer(number)
  end

  defp readme_links, do: @readme_path |> File.read!() |> ShippedDocs.markdown_links()

  defp under_prefix?(location, prefix) do
    location == prefix or String.starts_with?(location, prefix <> "/")
  end

  # A page name the docs build writes for a module: a module of the compiled application whose
  # name matches and that is not hidden from the docs.
  defp documented_module?(page) do
    :scrypath
    |> Application.spec(:modules)
    |> Enum.filter(&(inspect(&1) == page))
    |> Enum.any?(fn module ->
      match?(
        {:docs_v1, _anno, _lang, _format, moduledoc, _meta, _docs} when moduledoc != :hidden,
        Code.fetch_docs(module)
      )
    end)
  end
end
