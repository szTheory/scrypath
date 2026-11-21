defmodule Scrypath.Release.ShippedDocsContractTest do
  # Deliberately untagged: drift in the shipped-docs invariant fails the default `mix test`
  # and the `core` lane, following the backfill_contract_docs_test precedent. It reads files
  # only (no network, no docs build).
  #
  # This file proves the scanner can fail and can pass, using in-memory strings only. It never
  # edits a shipped file to prove a check. The real-file zero assertion is added in a later
  # plan, in the same commit as the contract text edit.
  use ExUnit.Case, async: true

  alias Scrypath.Release.ShippedDocs

  @guide "guides/planted.md"
  @unqualified_bullet "- Run `mix verify.adopter` before you ship."

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

    test "every violation names a shipped path and a derived repo-only name",
         %{names: names, files: files} do
      for {path, line, name} <- ShippedDocs.violations() do
        assert path in files
        assert is_integer(line) and line >= 1
        assert name in names
      end
    end
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
