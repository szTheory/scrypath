defmodule Scrypath.ReadmeContractTest do
  # Deliberately untagged: README and owner-map drift fails the default `mix test` and the
  # `core` lane, following the backfill_contract_docs_test precedent. Plain file reads only (no
  # network, no docs build). The quick path tests (README-02) are here; the README shape tests
  # (README-01) join them in the trim commit.
  use ExUnit.Case, async: true

  alias Scrypath.Release.ShippedDocs

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

  # Marker the Phase 193 parity guard reads: an HTML comment directly above a README snippet says
  # the snippet differs from the golden path on purpose.
  @differs_marker "<!-- scrypath:snippet-intentionally-differs -->"

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
      elixir = elixir_fences(quick)

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
      elixir = elixir_fences(quick_path(File.read!(@readme_path)))

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
      readme = File.read!(@readme_path)
      readme_fence = schema_fence(readme)
      golden_fence = schema_fence(File.read!(@golden_path))

      assert readme_fence, "README has no elixir fence containing `use Scrypath`"
      assert golden_fence, "the golden path has no elixir fence containing `use Scrypath`"

      unless differs_marked?(readme, readme_fence) do
        assert readme_fence.body == golden_fence.body,
               "the README schema snippet differs from #{@golden_path}; make them identical or put " <>
                 "#{@differs_marker} directly above the README snippet"
      end
    end

    for path <- [@readme_path, @golden_path] do
      test "#{path} config snippet resolves through Scrypath's runtime options" do
        fence = config_fence(File.read!(unquote(path)))

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
      readme = File.read!(@readme_path)
      readme_fence = config_fence(readme)

      unless differs_marked?(readme, readme_fence) do
        assert readme_fence.body == config_fence(File.read!(@golden_path)).body,
               "the README config snippet differs from #{@golden_path}"
      end
    end

    test "no README sentence promises a time" do
      prose = prose(File.read!(@readme_path))

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
    case String.split(readme, "\n## Quick Path\n", parts: 2) do
      [_before, rest] -> rest |> String.split(~r/^## /m, parts: 2) |> hd()
      _missing -> flunk("README.md has no `## Quick Path` section")
    end
  end

  defp before_first_fence(text), do: text |> String.split("```", parts: 2) |> hd()

  # `%{lang, body}` for every fenced code block, with its byte offsets in the text.
  defp fences(text) do
    ~r/^```([a-z]*)[ \t]*\n(.*?)^```[ \t]*$/ms
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

  defp elixir_fences(text), do: Enum.filter(fences(text), &(&1.lang == "elixir"))

  defp schema_fence(text), do: Enum.find(elixir_fences(text), &(&1.body =~ "use Scrypath"))

  defp config_fence(text), do: Enum.find(elixir_fences(text), &(&1.body =~ "config :scrypath"))

  # True when the marker is the last thing before the fence.
  defp differs_marked?(text, fence) do
    text
    |> binary_part(0, fence.start)
    |> String.trim_trailing()
    |> String.ends_with?(@differs_marker)
  end

  # Prose: the text with fenced code removed.
  defp prose(text) do
    Enum.reduce(Enum.reverse(fences(text)), text, fn fence, acc ->
      binary_part(acc, 0, fence.start) <>
        binary_part(acc, fence.stop, byte_size(acc) - fence.stop)
    end)
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
end
