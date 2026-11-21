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

  alias Scrypath.Release.ShippedDocs

  @guide "guides/planted.md"
  @unqualified_bullet "- Run `mix verify.adopter` before you ship."

  @project_file ".planning/PROJECT.md"
  @contract_heading "\n## Canonical Adopter Contract\n"
  @owner_docs ~w(guides/support-and-compatibility.md guides/outside-adopter-intake.md docs/operator-support.md)

  setup_all do
    %{names: ShippedDocs.repo_only_tasks(), files: ShippedDocs.shipped_files()}
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
    test "mix.exs is exempt only for its preferred_envs registration lines", %{names: names} do
      assert %{scope: {:lines, pattern}} = ShippedDocs.exempt()["mix.exs"]
      mix_exs = File.read!("mix.exs")

      assert ShippedDocs.scan([{"mix.exs", mix_exs}], names) == []

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

    test "allowlisted files may name repo-only tasks", %{names: names} do
      for path <- ShippedDocs.allowlist() ++ ["CHANGELOG.md"] do
        assert ShippedDocs.scan([{path, @unqualified_bullet}], names) == []
      end
    end
  end
end
