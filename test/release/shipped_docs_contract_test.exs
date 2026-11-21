defmodule Scrypath.Release.ShippedDocsContractTest do
  # Deliberately untagged: drift in the shipped-docs invariant fails the default `mix test`
  # and the `core` lane, following the backfill_contract_docs_test precedent. It reads files
  # only (no network, no docs build).
  #
  # This file proves the scanner can fail and can pass, using in-memory strings only. It never
  # edits a shipped file to prove a check. It also holds the real-file zero assertion and the
  # agreement test between the PROJECT.md Canonical Adopter Contract and this invariant: the
  # two change in the same commit (TRUTH-02), and this file is where they cannot drift apart.
  use ExUnit.Case, async: true

  alias Scrypath.MixProject
  alias Scrypath.Release.ShippedDocs

  # What counts as a repository-path link: a `blob/<ref>/<path>` (file) or `tree/<ref>/<path>`
  # (directory) URL on this repository, capturing kind, ref, path and fragment. Every other link
  # on the repository host (the CI badge, issue templates) is not a repository-path link.
  # Plan 04's README link test uses the same definition.
  @repo_path_link ~r{^https://github\.com/szTheory/scrypath/(blob|tree)/([^/#?]+)(?:/([^#?]*))?(?:\?[^#]*)?(?:#(.*))?$}
  @absolute_link ~r{^(?:[a-z][a-z0-9+.-]*:|//)}i

  @guide "guides/planted.md"
  @unqualified_bullet "- Run `mix verify.adopter` before you ship."

  @project_file ".planning/PROJECT.md"
  @contract_heading "\n## Canonical Adopter Contract\n"
  @owner_docs ~w(guides/support-and-compatibility.md guides/outside-adopter-intake.md docs/operator-support.md)

  setup_all do
    %{
      names: ShippedDocs.repo_only_tasks(),
      shipped: ShippedDocs.shipped_tasks(),
      files: ShippedDocs.shipped_files()
    }
  end

  describe "derivation and expansion guards" do
    test "repo-only task names are derived from the task directories, not a hand-kept list",
         %{names: names} do
      assert Enum.all?(names, &is_binary/1)
      assert length(names) >= 50, "the repo-only derivation went vacuous: #{length(names)} names"
      assert "verify.adopter" in names
      assert "scrypath_ops.saved_searches.validate" in names
      refute "scrypath.status" in names
      assert names == names |> Enum.uniq() |> Enum.sort()
    end

    test "the shipped file set is expanded from mix.exs package files and is not empty",
         %{files: files} do
      assert length(files) >= 100, "the shipped-file expansion went vacuous: #{length(files)}"

      for anchor <-
            ~w(README.md guides/golden-path.md docs/operator-support.md CHANGELOG.md mix.exs) do
        assert anchor in files, "#{anchor} is missing from the expanded shipped set"
      end
    end

    test "allowlisted and exempt paths are in package files and the exempt set has exactly two entries",
         %{files: files} do
      for path <- ShippedDocs.allowlist() ++ Map.keys(ShippedDocs.exempt()) do
        assert path in files, "#{path} is allowlisted or exempt but is not in package files"
      end

      assert ShippedDocs.allowlist() == ["CONTRIBUTING.md", "docs/releasing.md"]
      assert map_size(ShippedDocs.exempt()) == 2

      assert Enum.sort(Map.keys(ShippedDocs.exempt())) == ["CHANGELOG.md", "mix.exs"]
    end

    test "each exemption records a reason and a revisit trigger" do
      for {path, entry} <- ShippedDocs.exempt() do
        assert is_binary(entry.reason) and String.trim(entry.reason) != "",
               "#{path} has no recorded reason"

        assert is_binary(entry.revisit) and String.trim(entry.revisit) != "",
               "#{path} has no recorded revisit trigger"
      end
    end
  end

  describe "the real shipped files" do
    test "no Hex-shipped file names a repo-only task outside a qualified block" do
      violations = ShippedDocs.violations()

      listing =
        Enum.map_join(violations, "\n", fn {path, line, name} -> "  #{path}:#{line} #{name}" end)

      assert violations == [], """
      #{length(violations)} Hex-shipped mention(s) of a repo-only task sit outside a qualified unit:
      #{listing}
      Fix: add the source-checkout qualifier in the same sentence or list item, for example
      #{ShippedDocs.qualifier_example()}, or move the text to CONTRIBUTING.md or docs/releasing.md.
      """
    end

    test "owner docs name the adopter proof spine only with the source-checkout qualifier",
         %{names: names} do
      for path <- @owner_docs do
        units = adopter_units(File.read!(path), names)

        assert units != [],
               "#{path} no longer names mix verify.adopter, so it stopped documenting the fast/live split"

        for unit <- units do
          assert ShippedDocs.unit_qualified?(unit),
                 "#{path}:#{unit.line} names mix verify.adopter without saying it runs from a source checkout and is not in the Hex package"
        end
      end
    end
  end

  describe "the Canonical Adopter Contract in PROJECT.md" do
    test "states the same rule the invariant enforces", %{names: names} do
      section = contract_section()

      assert String.trim(section) != "", "the Canonical Adopter Contract section is empty"

      mentioning = adopter_units(section, names)

      assert mentioning != [],
             "the Canonical Adopter Contract no longer names mix verify.adopter"

      for unit <- mentioning do
        assert ShippedDocs.unit_qualified?(unit),
               "the contract unit starting at section line #{unit.line} names mix verify.adopter without the source-checkout qualifier"
      end

      for path <- ShippedDocs.allowlist() ++ Map.keys(ShippedDocs.exempt()) do
        assert String.contains?(section, path),
               "the contract does not name #{path}, which the invariant allowlists or exempts"
      end

      assert String.contains?(section, "test/release/shipped_docs_contract_test.exs"),
             "the contract does not name the test that enforces it"

      refute Regex.match?(~r/0\.3\.17\s+still\s+contains/, section),
             "the contract still carries the stale published-0.3.17 claim"
    end
  end

  # Units of `text` that name the adopter proof task (any form the scanner recognises).
  defp adopter_units(text, names) do
    text
    |> ShippedDocs.units()
    |> Enum.filter(fn unit -> "verify.adopter" in ShippedDocs.mentions(unit.text, names) end)
  end

  # Text between the Canonical Adopter Contract heading and the next level-2 heading.
  defp contract_section do
    project = File.read!(@project_file)

    assert [_before, rest] = String.split(project, @contract_heading),
           "#{@project_file} must carry exactly one Canonical Adopter Contract heading"

    [section | _] = String.split(rest, ~r/^## /m, parts: 2)
    section
  end

  describe "mix.exs scope" do
    test "mix.exs is exempt only for its preferred_envs registration lines",
         %{names: names, shipped: shipped} do
      assert %{scope: {:lines, pattern}} = ShippedDocs.exempt()["mix.exs"]
      mix_exs = File.read!("mix.exs")

      assert ShippedDocs.scan([{"mix.exs", mix_exs}], names, shipped) == []

      registration_lines =
        mix_exs |> String.split("\n") |> Enum.count(&Regex.match?(pattern, &1))

      assert registration_lines >= 40,
             "the registration-line exemption went vacuous: #{registration_lines} lines"

      planted =
        ~s|        "verify.adopter": :test,\n        # run mix verify.adopter before you ship\n|

      assert [{"mix.exs", 2, "verify.adopter"}] = ShippedDocs.scan([{"mix.exs", planted}], names)
    end
  end

  describe "planted cases (in-memory strings only)" do
    test "an unqualified repo-only task line in a shipped guide fails the scan", %{names: names} do
      text = "# Title\n\n#{@unqualified_bullet}\n"

      assert [{@guide, 3, "verify.adopter"}] = ShippedDocs.scan([{@guide, text}], names)
    end

    test "a source-checkout qualified line passes the scan", %{names: names} do
      qualified =
        "- Run `mix verify.adopter` before you ship #{ShippedDocs.qualifier_example()}."

      assert ShippedDocs.scan([{@guide, "# Title\n\n#{qualified}\n"}], names) == []
    end

    test "a qualifier in a sibling sentence does not qualify the mention", %{names: names} do
      sibling =
        "# Title\n\nRun `mix verify.adopter` before shipping.\n" <>
          "This task runs from a source checkout and is not in the Hex package.\n"

      assert [{@guide, 3, "verify.adopter"}] = ShippedDocs.scan([{@guide, sibling}], names)

      one_sentence =
        "# Title\n\nRun `mix verify.adopter` before shipping; it runs from a source checkout " <>
          "and is not in the Hex package.\n"

      assert ShippedDocs.scan([{@guide, one_sentence}], names) == []
    end

    test "a qualifier in a sibling blockquote sentence does not qualify the mention",
         %{names: names} do
      sibling =
        "> Run `mix verify.adopter`.\n" <>
          "> It runs from a source checkout and is not in the Hex package.\n"

      assert [{@guide, 1, "verify.adopter"}] = ShippedDocs.scan([{@guide, sibling}], names)

      one_sentence =
        "> Run `mix verify.adopter`; it runs from a source checkout and is not in the Hex package.\n"

      assert ShippedDocs.scan([{@guide, one_sentence}], names) == []
    end

    test "prose use of the word verify is not a mention", %{names: names} do
      prose = "Settings verify skipped is a temporary flag. We verify the result by hand.\n"

      assert ShippedDocs.scan([{@guide, prose}], names) == []
      assert ShippedDocs.mentions("We verify the result.", names) == []
    end

    test "a fenced block or table is judged only with the sentence directly above it",
         %{names: names} do
      fence = "```bash\nmix verify.adopter\n```\n"

      unqualified_lead = "# Title\n\nRun the gate before merging:\n\n#{fence}"

      assert [{@guide, 6, "verify.adopter"}] =
               ShippedDocs.scan([{@guide, unqualified_lead}], names)

      qualified_lead =
        "# Title\n\nThese gates run from a source checkout and are not in the Hex package:\n\n#{fence}"

      assert ShippedDocs.scan([{@guide, qualified_lead}], names) == []

      # Only the last sentence of the paragraph above counts, not an earlier one.
      two_sentence_lead =
        "# Title\n\nThese gates run from a source checkout and are not in the Hex package.\n" <>
          "Run the gate before merging:\n\n#{fence}"

      assert [{@guide, 7, "verify.adopter"}] =
               ShippedDocs.scan([{@guide, two_sentence_lead}], names)

      table = "| Gate | Command |\n| --- | --- |\n| adopter | `mix verify.adopter` |\n"

      assert [{@guide, 5, "verify.adopter"}] =
               ShippedDocs.scan([{@guide, "Gate overview:\n\n#{table}"}], names)

      qualified_table_lead =
        "These gates run from a source checkout and are not in the Hex package.\n\n#{table}"

      assert ShippedDocs.scan([{@guide, qualified_table_lead}], names) == []
    end

    test "a fence or table does not borrow a qualifier from a heading or a list item",
         %{names: names} do
      fence = "```bash\nmix verify.adopter\n```\n"

      heading_lead =
        "## From a source checkout, not in the Hex package\n\n#{fence}"

      assert [{@guide, 4, "verify.adopter"}] = ShippedDocs.scan([{@guide, heading_lead}], names)

      list_lead =
        "- These run from a source checkout and are not in the Hex package.\n\n#{fence}"

      assert [{@guide, 4, "verify.adopter"}] = ShippedDocs.scan([{@guide, list_lead}], names)
    end

    test "a qualified paragraph does not reach a fence across a heading or past a table",
         %{names: names} do
      qualified = "These gates run from a source checkout and are not in the Hex package.\n\n"
      fence = "```bash\nmix verify.adopter\n```\n"

      across_heading = qualified <> "## Gates\n\n" <> fence
      assert [{@guide, 6, "verify.adopter"}] = ShippedDocs.scan([{@guide, across_heading}], names)

      table = "| Gate | Command |\n| --- | --- |\n| adopter | `mix verify.adopter` |\n"

      # The first table is qualified through its lead-in; a second table after a blank line
      # starts a new block and must not inherit it.
      two_tables = qualified <> table <> "\n" <> table

      assert [{@guide, 9, "verify.adopter"}] = ShippedDocs.scan([{@guide, two_tables}], names)

      # A second fence is a new block: the qualified paragraph above the first fence does
      # not reach it.
      two_fences = qualified <> fence <> "\n" <> fence
      assert [{@guide, 8, "verify.adopter"}] = ShippedDocs.scan([{@guide, two_fences}], names)

      fence_after_table = qualified <> table <> fence

      assert [{@guide, 7, "verify.adopter"}] =
               ShippedDocs.scan([{@guide, fence_after_table}], names)
    end

    test "each list item is its own unit", %{names: names} do
      items =
        "- Run `mix verify.adopter` #{ShippedDocs.qualifier_example()}.\n" <>
          "- Run `mix verify.adopter --live` before release.\n"

      assert [{@guide, 2, "verify.adopter"}] = ShippedDocs.scan([{@guide, items}], names)
    end

    test "a code span with sentence-like text does not split a qualified sentence",
         %{names: names} do
      sentence =
        "From a source checkout, run `mix verify.adopter -e 'a. B'`, which is not in the Hex package.\n"

      assert length(ShippedDocs.units(sentence)) == 1
      assert ShippedDocs.scan([{@guide, sentence}], names) == []

      dotted = "Run `mix verify.adopter` #{ShippedDocs.qualifier_example()}.\n"
      assert ShippedDocs.scan([{@guide, dotted}], names) == []
    end

    test "the family form mix verify.* in an unqualified paragraph is reported", %{names: names} do
      family = "Other root `mix verify.*` commands are maintainer tools.\n"
      assert [{@guide, 1, "verify"}] = ShippedDocs.scan([{@guide, family}], names)

      backticked = "Other `verify.*` commands are maintainer tools.\n"
      assert [{@guide, 1, "verify"}] = ShippedDocs.scan([{@guide, backticked}], names)

      qualified =
        "Other root `mix verify.*` commands run from a source checkout and are not in the Hex package.\n"

      assert ShippedDocs.scan([{@guide, qualified}], names) == []
    end

    test "a glob or brace spelling of a repo-only task family is reported",
         %{names: names, shipped: shipped} do
      scan = fn text -> ShippedDocs.scan([{@guide, text}], names, shipped) end

      assert [{@guide, 1, "verify.phase"}] = scan.("Run the `mix verify.phase*` gates.\n")
      assert [{@guide, 1, "verify.phase"}] = scan.("Run the `verify.phase*` gates.\n")
      assert [{@guide, 1, "verify.phase"}] = scan.("Run `mix verify.phase{11,14}` first.\n")
      assert [{@guide, 1, "verify"}] = scan.("Run `mix verify.{all,core}` first.\n")
      assert [{@guide, 1, "verify"}] = scan.("Run `mix verify*` first.\n")
      assert [{@guide, 1, "scrypath_ops"}] = scan.("Run `mix scrypath_ops.*` in the app.\n")
      assert [{@guide, 1, "scrypath_ops"}] = scan.("Run the `scrypath_ops.*` tasks.\n")

      qualified =
        "The `mix verify.phase*` gates run from a source checkout and are not in the Hex package.\n"

      assert scan.(qualified) == []
      assert [{@guide, 3, "scrypath_ops"}] = scan.("# Title\n\n- Run `mix scrypath_ops.*`.\n")
    end

    test "a glob that names only shipped tasks, or no task, is not a mention",
         %{names: names, shipped: shipped} do
      scan = fn text -> ShippedDocs.scan([{@guide, text}], names, shipped) end

      assert "scrypath.status" in shipped
      assert scan.("The `mix scrypath.*` operator tasks ship with the package.\n") == []
      assert scan.("Run `mix scrypath.{status,failed}` against the index.\n") == []
      assert scan.("Run `mix verify.nothing*` or `mix zzz.*` first.\n") == []

      # A `*` that closes a bold span is emphasis, not a glob.
      assert scan.("Read **mix scrypath_ops** in the app guide.\n") == []

      # Without the shipped names the same text is reported (the stricter reading).
      assert [{@guide, 1, "scrypath"}] =
               ShippedDocs.scan([{@guide, "The `mix scrypath.*` tasks ship.\n"}], names)
    end

    test "allowlisted files may name repo-only tasks", %{names: names} do
      for path <- ShippedDocs.allowlist() ++ ["CHANGELOG.md"] do
        assert ShippedDocs.scan([{path, @unqualified_bullet}], names) == []
      end
    end
  end

  # TRUTH-03, source side. The built-docs scan in package_metadata_test.exs cannot see this class:
  # ExDoc maps any `README.md` basename to the landing page, so `../examples/x/README.md` becomes
  # a working-looking link to the wrong page. The rule is therefore on the markdown source:
  #
  #   * a relative link target must be another docs extra;
  #   * a link to a repository path outside the package is an absolute `blob/main` (file) or
  #     `tree/main` (directory) URL whose path exists in the working tree and whose fragment, on
  #     a markdown file, is a heading of that file;
  #   * any other absolute link (the CI badge, issue templates, external sites) is checked for
  #     nothing beyond being absolute.
  #
  # The README header images and links are HTML attributes pinned to a commit by
  # package_metadata_test.exs, not markdown links, so `markdown_links/1` does not see them.
  describe "links in shipped markdown" do
    test "shipped markdown links to repo paths outside the package use absolute GitHub URLs",
         %{files: files} do
      extras = MixProject.project()[:docs][:extras]
      pages = for file <- files, file in extras, do: {file, File.read!(file)}

      links =
        for {file, text} <- pages, link <- ShippedDocs.markdown_links(text), do: {file, link}

      repo_links =
        Enum.count(links, fn {_file, {_line, target}} -> Regex.match?(@repo_path_link, target) end)

      # Non-vacuity: a scan that read no links, or found no repository link, proves nothing.
      assert length(links) > 50, "the link scan went vacuous: #{length(links)} links"
      assert repo_links >= 16, "the repo-path link check went vacuous: #{repo_links} links"

      failures = Enum.flat_map(pages, fn {file, text} -> link_failures(file, text, extras) end)

      assert failures == [],
             "#{length(failures)} shipped markdown link(s) break the rule:\n" <>
               Enum.join(failures, "\n")
    end

    test "the link rule reports planted cases and passes the allowed forms" do
      extras = MixProject.project()[:docs][:extras]
      base = ShippedDocs.repo_blob_base()
      check = fn target -> link_failures("guides/planted.md", "[x](#{target})\n", extras) end

      # Planted failures, one message each, naming file, line and target.
      relative = "../examples/phoenix_meilisearch/README.md"
      assert [message] = check.(relative)
      assert message =~ "guides/planted.md:1 #{relative}"
      assert message =~ "not a docs extra"

      assert [_] = check.("../.github/workflows/ci.yml")
      assert [_] = check.("../../outside.md")
      assert [_] = check.(base <> "no/such/file.md")
      assert [_] = check.(base <> "scrypath_ops/README.md#no-such-heading")
      assert [_] = check.(base <> "examples")
      assert [_] = check.("https://github.com/szTheory/scrypath/tree/main/mix.exs")
      assert [message] = check.("https://github.com/szTheory/scrypath/blob/v0.3.17/README.md")
      assert message =~ "must use main"

      # Allowed forms.
      assert check.("golden-path.md") == []
      assert check.("golden-path.md#some-heading") == []
      assert check.("../README.md") == []
      assert check.("#same-page-anchor") == []
      assert check.(base <> "scrypath_ops/README.md#production") == []
      assert check.(base <> "mix.exs#L10") == []
      assert check.("https://github.com/szTheory/scrypath/tree/main/examples") == []

      assert check.("https://github.com/szTheory/scrypath/actions/workflows/ci.yml/badge.svg") ==
               []

      assert check.("https://github.com/szTheory/scrypath/issues/new?template=adopter.yml") ==
               []

      assert check.("https://hexdocs.pm/scrypath/golden-path.html") == []

      # Links in fenced code and in code spans are not links.
      fenced = "```markdown\n[x](#{relative})\n```\n\nUse `[x](#{relative})` in your README.\n"
      assert link_failures("guides/planted.md", fenced, extras) == []
    end

    test "markdown_links returns line and target for inline and image links outside code" do
      text = """
      # Title

      See [one](a.md) and [two](https://example.com/x "a title"), plus ![logo](img/logo.svg).
      A wrapped sentence with a [link
      across lines](b.md#frag).

      ```sh
      [skipped](c.md)
      ```

      `[also skipped](d.md)` but [`code text`](e.md) counts.
      """

      assert ShippedDocs.markdown_links(text) == [
               {3, "a.md"},
               {3, "https://example.com/x"},
               {3, "img/logo.svg"},
               {5, "b.md#frag"},
               {11, "e.md"}
             ]
    end

    test "github_slug and heading_slugs follow GitHub's anchor rule" do
      assert ShippedDocs.github_slug("Mounted host app assets") == "mounted-host-app-assets"
      assert ShippedDocs.github_slug("Production") == "production"
      assert ShippedDocs.github_slug("What's `mix verify`? (v2)") == "whats-mix-verify-v2"
      assert ShippedDocs.github_slug("Snake_case and kebab-case") == "snake_case-and-kebab-case"

      text =
        "# Same\n\n## Same ##\n\n## [Linked](x.md) heading\n\n```sh\n# not a heading\n```\n\n## Same\n"

      assert ShippedDocs.heading_slugs(text) == ["same", "same-1", "linked-heading", "same-2"]
    end
  end

  defp link_failures(file, text, extras) do
    for {line, target} <- ShippedDocs.markdown_links(text),
        reason = link_failure(file, target, extras),
        do: "#{file}:#{line} #{target} - #{reason}"
  end

  defp link_failure(file, target, extras) do
    case Regex.run(@repo_path_link, target, capture: :all_but_first) do
      [kind, ref | rest] -> repo_path_failure(kind, ref, rest)
      nil -> other_link_failure(file, target, extras)
    end
  end

  defp other_link_failure(file, target, extras) do
    if Regex.match?(@absolute_link, target), do: nil, else: relative_failure(file, target, extras)
  end

  defp repo_path_failure(kind, ref, rest) do
    path = Enum.at(rest, 0, "")
    fragment = Enum.at(rest, 1, "")

    cond do
      ref != "main" ->
        "the link uses ref #{ref}; a repository link must use main"

      not repo_path?(kind, path) ->
        "#{inspect(path)} is not #{if kind == "tree", do: "a directory", else: "a file"} in the working tree"

      fragment != "" and Path.extname(path) == ".md" and
          fragment not in ShippedDocs.heading_slugs(File.read!(path)) ->
        "#{path} has no heading with the anchor ##{fragment}"

      true ->
        nil
    end
  end

  defp repo_path?("tree", path), do: File.dir?(path)
  defp repo_path?("blob", path), do: File.regular?(path)

  defp relative_failure(file, target, extras) do
    path = target |> String.split(["#", "?"], parts: 2) |> hd()
    resolved = resolve(file, path)

    if path == "" or resolved in extras do
      nil
    else
      "relative target resolves to #{resolved}, which is not a docs extra; link a repository " <>
        "path by absolute URL, #{ShippedDocs.repo_blob_base()}<path>"
    end
  end

  # The repository-relative path a relative link means, read from the file that holds it. A link
  # that climbs above the repository root stays absolute and is never an extra.
  defp resolve(file, path) do
    root = "/repository-root"
    base = Path.join(root, Path.dirname(file))
    path |> Path.expand(base) |> Path.relative_to(root)
  end
end
