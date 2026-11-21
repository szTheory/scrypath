defmodule Scrypath.Release.ForbiddenPhrasesContractTest do
  # Deliberately untagged: wording drift in the README or a guide fails the default `mix test` and
  # the `core` lane. It reads files only (no network, no docs build).
  #
  # This file proves the phrase table can fail and can pass. The planted cases are in-memory
  # strings only; no shipped file is edited to prove a check. It also holds the real-file zero
  # assertion, the floors that keep the scan from going vacuous, and the faithfulness test that
  # ties the brand rules to brand/BRAND.md.
  use ExUnit.Case, async: true

  alias Scrypath.Release.ForbiddenPhrases

  @readme "README.md"
  @guide "guides/planted.md"

  # The two lists the README tests carried before the table existed, as they read then.
  @old_time_promises [
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
  @old_brand_do_not_say [
    "magic",
    "effortless",
    "it just stays in sync",
    "real-time",
    "federated",
    "hydration",
    "playbook",
    "AI-powered"
  ]

  defp scan(path, text), do: ForbiddenPhrases.scan([{path, text}], ForbiddenPhrases.rules())

  describe "the real files" do
    test "README and every guide in extras are free of forbidden phrases" do
      targets = ForbiddenPhrases.targets()
      rules = ForbiddenPhrases.rules()

      # Non-vacuity: a scan that read few files or few rules proves nothing. The guide count comes
      # from the directory listing, not from `extras`, so the two cannot agree by construction.
      assert length(targets) == 1 + length(Path.wildcard("guides/*.md"))
      assert length(targets) >= 20, "the phrase scan went vacuous: #{length(targets)} files"
      assert length(rules) >= 4, "the phrase table went vacuous: #{length(rules)} rules"

      time = Enum.find(rules, &(&1["id"] == "time-promise"))
      # A floor, not an exact count: the phrases the README tests banned before are 10, and the
      # no-weakening test plants each; a new row is an edit to the table, not to this test.
      assert length(time["forbidden"]) >= 10

      hits = ForbiddenPhrases.violations()

      assert hits == [],
             "#{length(hits)} forbidden phrase(s) in shipped prose:\n" <>
               Enum.map_join(hits, "\n", fn {path, line, id, matched} ->
                 "  #{path}:#{line} #{inspect(matched)} (#{id})"
               end)
    end

    # WR-02 (Phase 193 review): the scan reads the `guides/` directory, which `package.files` ships
    # whole, so a guide that is not a docs extra is scanned and named here instead of shipping
    # unlisted and unscanned.
    test "every guides/*.md file is a docs extra" do
      guides = ForbiddenPhrases.guide_paths()
      assert length(guides) >= 20, "the guide listing went vacuous: #{length(guides)} files"

      unlisted = ForbiddenPhrases.unlisted_guides()

      assert unlisted == [],
             "guide(s) #{inspect(unlisted)} are not in the docs extras of mix.exs; add each to " <>
               "`extras` and to a `groups_for_extras` group, or it ships but never reaches HexDocs"

      for guide <- guides, do: assert(guide in Scrypath.MixProject.project()[:docs][:extras])
    end

    # A fence the pairing does not recognise (inside a blockquote, after a list marker) would leave
    # its prose masked or its code scanned with no error, so every fence-looking line must belong to
    # a fence the scan found. `Scrypath.Release.SnippetParity.fences/1` itself raises on an
    # unclosed fence.
    test "every fence-looking line of README and the guides belongs to a paired fence" do
      fence_line = ~r/^[ \t>]*(?:`{3,}[^`\n]*|~{3,}.*)$/m

      for {path, text} <- ForbiddenPhrases.targets() do
        lines = fence_line |> Regex.scan(text) |> length()
        fences = text |> Scrypath.Release.SnippetParity.fences() |> length()

        assert lines == 2 * fences,
               "#{path} has #{lines} fence-looking lines but #{fences} paired fence(s): " <>
                 "a fence inside a blockquote or after a list marker is not recognised"
      end
    end

    test "the brand rules equal the brand book's do-not-say list" do
      [_before, rest] =
        "brand/BRAND.md" |> File.read!() |> String.split("\nDo not say\n", parts: 2)

      [paragraph | _] = rest |> String.trim_leading() |> String.split("\n\n", parts: 2)
      [sentence | _] = String.split(paragraph, ~r/\.\s/, parts: 2)

      book =
        sentence
        |> String.replace(~r/\([^)]*\)/, "")
        |> String.replace(["“", "”", "\""], "")
        |> String.split(~r/,\s*(?:or\s+)?/)
        |> Enum.map(&(&1 |> String.trim() |> String.downcase()))
        |> Enum.reject(&(&1 == ""))

      assert length(book) == 8, "the brand book's do-not-say sentence parsed to #{inspect(book)}"

      copied = Enum.map(ForbiddenPhrases.brand_terms(), &String.downcase/1)

      assert Enum.sort(copied) == Enum.sort(book),
             "the table's brand terms #{inspect(copied)} differ from brand/BRAND.md #{inspect(book)}"

      # Every copied term is caught by the rule that carries it, in the README.
      for rule <- ForbiddenPhrases.rules(), term <- Map.get(rule, "source_terms", []) do
        assert [_ | _] = ForbiddenPhrases.scan([{@readme, "Scrypath is #{term} here.\n"}], [rule]),
               "rule #{rule["id"]} does not catch its own source term #{inspect(term)}"
      end
    end

    test "every rule names its source and scope, and a README-only rule records why" do
      rules = ForbiddenPhrases.rules()
      ids = Enum.map(rules, & &1["id"])
      assert ids == Enum.uniq(ids), "duplicate rule ids"

      for rule <- rules do
        for field <- ["id", "rule", "source"] do
          assert is_binary(rule[field]) and String.trim(rule[field]) != "",
                 "rule #{rule["id"]} has no #{field}"
        end

        assert rule["scope"] in ["readme", "readme_and_guides"],
               "rule #{rule["id"]} has scope #{inspect(rule["scope"])}"

        assert rule["forbidden"] != [], "rule #{rule["id"]} forbids nothing"

        for entry <- rule["forbidden"] do
          assert entry["match"] in ["literal", "regex"]
          assert entry["case"] in ["sensitive", "insensitive"]
          assert String.trim(entry["text"]) != ""
        end

        for entry <- rule["forbidden"], entry["match"] == "literal" do
          assert entry["text"] =~ ~r/\A\w.*\w\z/u,
                 "literal #{inspect(entry["text"])} must start and end with a word character"
        end

        if rule["scope"] == "readme" do
          assert is_binary(rule["reason"]) and String.trim(rule["reason"]) != "",
                 "README-only rule #{rule["id"]} records no reason"
        end
      end

      assert is_list(ForbiddenPhrases.table()["not_covered"])
      assert ForbiddenPhrases.table()["not_covered"] != []
    end

    test "rules/1 raises on an unknown rule id" do
      assert [%{"id" => "time-promise"}] = ForbiddenPhrases.rules(["time-promise"])

      assert_raise ArgumentError, fn -> ForbiddenPhrases.rules(["no-such-rule"]) end
    end
  end

  describe "no weakening" do
    test "each phrase the README tests banned before is still caught in README" do
      for phrase <- @old_time_promises ++ @old_brand_do_not_say do
        text = "# Title\n\nScrypath gives you search #{phrase} for your app.\n"

        assert [{@readme, 3, id, _matched}] = scan(@readme, text),
               "#{inspect(phrase)} is no longer caught in README prose"

        assert id in ["time-promise", "brand-hype", "brand-technical-readme-only"]

        # Upper case and sentence case were caught before and still are.
        assert [_] = scan(@readme, String.upcase(text))
      end
    end
  end

  describe "planted cases (in-memory strings only)" do
    test "a planted time promise fails in README and in a guide" do
      text = "Search in five minutes.\n"

      assert [{@readme, 1, "time-promise", "in five minutes"}] = scan(@readme, text)
      assert [{@guide, 1, "time-promise", "in five minutes"}] = scan(@guide, text)
    end

    test "a README-only term fails in README and passes in a guide" do
      text = "Scrypath is magic.\n"

      assert [{@readme, 1, "brand-technical-readme-only", "magic"}] = scan(@readme, text)
      assert scan(@guide, text) == []

      for word <- ["federated", "federation", "hydration", "hydrate"] do
        assert [{@readme, 1, "brand-technical-readme-only", _}] =
                 scan(@readme, "It uses #{word} here.\n")

        assert scan(@guide, "It uses #{word} here.\n") == []
      end
    end

    test "a forbidden phrase inside a fenced block is not reported" do
      text = "Intro.\n\n```elixir\n# search in five minutes, effortless magic\n```\n\nOutro.\n"

      assert scan(@readme, text) == []
      assert scan(@guide, text) == []

      # Prose after the fence keeps its true line.
      after_fence = text <> "\nQuickly.\n"
      assert [{@guide, 9, "time-promise", "Quickly"}] = scan(@guide, after_fence)
    end

    # WR-02 (Phase 193 review): a new guide that nobody added to `extras` used to be neither scanned
    # nor reported. The directory under test is a temporary one under the system temp dir (not the
    # `:tmp_dir` tag, which writes `tmp/` into the repository root), so no shipped file is edited
    # and the workspace stays clean.
    test "a guide missing from extras is scanned and named" do
      root =
        Path.join(System.tmp_dir!(), "forbidden-phrases-#{System.unique_integer([:positive])}")

      on_exit(fn -> File.rm_rf!(root) end)

      File.mkdir_p!(Path.join(root, "guides"))
      File.write!(Path.join(root, "README.md"), "# Planted\n")
      File.write!(Path.join(root, "guides/new-thing.md"), "# New\n\nSearch is effortless here.\n")
      File.write!(Path.join(root, "guides/listed.md"), "# Listed\n")
      File.write!(Path.join(root, "guides/notes.txt"), "Search is effortless here.\n")

      extras = ["README.md", "guides/listed.md"]

      assert ForbiddenPhrases.guide_paths(root) == ["guides/listed.md", "guides/new-thing.md"]
      assert ForbiddenPhrases.unlisted_guides(root, extras) == ["guides/new-thing.md"]

      assert [
               {"README.md", _},
               {"guides/listed.md", _},
               {"guides/new-thing.md", "# New\n\nSearch is effortless here.\n"}
             ] = targets = ForbiddenPhrases.targets(root)

      assert [{"guides/new-thing.md", 3, "brand-hype", "effortless"}] =
               ForbiddenPhrases.scan(targets, ForbiddenPhrases.rules())

      assert ForbiddenPhrases.unlisted_guides(root, extras ++ ["guides/new-thing.md"]) == []
    end

    # WR-01 (Phase 193 review): a fence line the matcher did not recognise used to invert the pairing
    # for the rest of the file, so prose between two blocks was masked and never scanned.
    test "prose between fences with any info string, indent or marker is still scanned" do
      for opener <- [
            "```html+eex",
            "```json5",
            "```Elixir",
            "```elixir title=\"a.ex\"",
            "```{.elixir}",
            "````elixir",
            "~~~elixir",
            "  ```elixir",
            "```"
          ] do
        closer = opener |> String.trim() |> String.replace(~r/^(`+|~+).*$/, "\\1")

        text =
          "Intro.\n\n#{opener}\nx = 1\n#{closer}\n\nSearch is effortless here.\n\n" <>
            "```elixir\ny = 2\n```\n\nOutro.\n"

        assert [{@guide, 7, "brand-hype", "effortless"}] = scan(@guide, text),
               "prose after a #{inspect(opener)} block was not scanned"
      end

      # The same sentence between two plain fences, as before.
      plain = "```elixir\nx\n```\n\nSearch is effortless here.\n\n```elixir\ny\n```\n"
      assert [{@guide, 5, "brand-hype", "effortless"}] = scan(@guide, plain)
    end

    test "a phrase inside any kind of fenced block is not reported" do
      for opener <- ["```html+eex", "```json5", "```elixir title=\"a.ex\"", "~~~", "  ```sh"] do
        closer = opener |> String.trim() |> String.replace(~r/^(`+|~+).*$/, "\\1")
        text = "Intro.\n\n#{opener}\nsearch in five minutes, effortless\n#{closer}\n\nOutro.\n"

        assert scan(@guide, text) == [], "a #{inspect(opener)} block was read as prose"
      end

      # A shorter fence line inside a longer fence is content, not a close.
      nested = "````md\n```elixir\neffortless\n```\n````\n\nOutro.\n"
      assert scan(@guide, nested) == []
    end

    test "a code fence that is never closed fails loudly instead of mis-masking" do
      text = "Intro.\n\n```html+eex\n<p>x</p>\n\nSearch is effortless here.\n"

      error = assert_raise ArgumentError, fn -> scan(@guide, text) end
      assert error.message =~ "guides/planted.md"
      assert error.message =~ "line 3"
    end

    test "word boundaries and case are decided" do
      # A longer word is not the banned word; a listed inflection is.
      assert scan(@readme, "A magician appears.\n") == []
      assert [{@readme, 1, _, "magical"}] = scan(@readme, "A magical result.\n")
      assert scan(@guide, "Quickness is not a promise.\n") == []

      # Insensitive rules match any case; the glossary casing rule is case-sensitive.
      assert [{@readme, 1, "brand-hype", _}] = scan(@readme, "It is EFFORTLESS.\n")
      assert [{@readme, 1, "brand-hype", "real-time"}] = scan(@readme, "A real-time view.\n")
      assert [{@readme, 1, "brand-hype", "realtime"}] = scan(@readme, "A realtime view.\n")
      assert [{@readme, 1, "brand-hype", "real time"}] = scan(@readme, "A real time view.\n")

      # Built by concatenation, as the ops copy-rules test does, so this file never spells the
      # title-case name that scrypath_ops/test/support/copy_rules.json forbids across the tree.
      title_case = "Control" <> " Room"

      assert [{@guide, 1, "glossary-names", ^title_case}] =
               scan(@guide, "Open the #{title_case}.\n")

      assert scan(@guide, "Open the Control room.\n") == []

      assert [{@guide, 1, "glossary-names", "sync and drift"}] =
               scan(@guide, "The sync and drift page.\n")

      # A literal also matches across a line break inside a hard-wrapped sentence.
      assert [{@guide, 1, "time-promise", "in five\nminutes"}] =
               scan(@guide, "Search in five\nminutes.\n")
    end

    test "accepted work is never banned" do
      sentence = "Accepted work is not the same thing as search visibility.\n"

      assert scan(@readme, sentence) == []
      assert scan(@guide, sentence) == []

      table = "test/support/release/forbidden_phrases.json" |> File.read!() |> String.downcase()
      refute table =~ "accepted work"
    end

    test "the scan reports the line of the phrase" do
      text = "# Planted\n\nFirst line.\nThen it works instantly here.\n\nAnd just works there.\n"

      assert [
               {@guide, 4, "time-promise", "instantly"},
               {@guide, 6, "time-promise", "just works"}
             ] = scan(@guide, text)
    end
  end
end
