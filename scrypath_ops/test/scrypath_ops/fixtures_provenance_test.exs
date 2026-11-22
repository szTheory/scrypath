defmodule ScrypathOps.FixturesProvenanceTest do
  @moduledoc false
  # Phase 196: the rules that keep the fixtures honest about where they come from and what they are
  # made of. Each rule has a planted failure on a real temporary file (or a changed bulk sample) that
  # asserts exactly its own problem, beside a positive control that the same shape is clean.
  #
  #   * labels: every registered scenario says "(fictional)";
  #   * `:raw_format_char`: a bidirectional control, zero-width character or byte-order mark anywhere
  #     in the project (Trojan Source); the character is built from its bytes, never typed here;
  #   * `:impure_source`: a wall-clock, random, operating-system or repository call in `lib/`;
  #   * `:denylisted_word`: a compliance claim or the sibling canon id in a label, scenario data, the
  #     README or `lib/` source. The words appear in this file only because it is a test; the
  #     fixtures project itself never lists them outside the check;
  #   * `:provenance_missing`: an adopter module or schema without its fictional-provenance line;
  #   * `:bulk_digest`: the bulk sample no longer hashes to the golden digest.
  #
  # Pure: no application env and no database, so it runs async. Temporary files live under a
  # per-test directory that `on_exit` removes.
  use ExUnit.Case, async: true

  alias ScrypathFixtures.Bulk
  alias ScrypathFixtures.Check
  alias ScrypathFixtures.Scenarios

  @now ScrypathFixtures.preview_epoch()

  @provenance_line "Fictional adopter: Scrypath-owned data, no records copied from any other project."

  setup do
    dir =
      Path.join(
        System.tmp_dir!(),
        "scrypath-fixtures-provenance-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)

    # One cheap Logistify scenario and one Wikily one: they decide which adopters exist, so an
    # adopter file for either is recognised without running the whole registry for every plant.
    %{
      dir: dir,
      deep: Scenarios.get!(:logistify_deep_queue, @now),
      wiki: Scenarios.get!(:wikily_unconfigured, @now)
    }
  end

  describe "labels" do
    test "every registered scenario label says it is fictional" do
      for scenario <- Scenarios.all(@now) do
        assert scenario.label =~ "(fictional)", "#{scenario.id} does not say (fictional)"
      end
    end

    test "the real tree is clean for all five rules" do
      expected = length(Scenarios.ids())
      assert {:ok, %{scenarios: ^expected}} = Check.run()
    end
  end

  describe "raw_format_char" do
    test "a control character in a project file is reported with its code point", %{
      dir: dir,
      deep: deep
    } do
      # right-to-left override, zero-width space, left-to-right isolate, closing isolate, BOM
      for codepoint <- [0x202E, 0x200B, 0x2066, 0x2069, 0xFEFF] do
        path = write!(dir, "raw-#{codepoint}.txt", "a" <> <<codepoint::utf8>> <> "b")

        assert {:error, [{:source, {:raw_format_char, ^path, ^codepoint}}]} =
                 Check.run(scenarios: [deep], source_files: [path]),
               "U+#{Integer.to_string(codepoint, 16)} was not reported"
      end
    end

    test "two different characters in one file are two problems", %{dir: dir, deep: deep} do
      path = write!(dir, "two.txt", <<0xE2, 0x80, 0xAE, ?x, 0xE2, 0x80, 0x8B>>)

      assert {:error, problems} = Check.run(scenarios: [deep], source_files: [path])

      assert Enum.sort(problems) ==
               Enum.sort([
                 {:source, {:raw_format_char, path, 0x200B}},
                 {:source, {:raw_format_char, path, 0x202E}}
               ])
    end

    test "positive control: plain text and an escape written as text are clean", %{
      dir: dir,
      deep: deep
    } do
      plain = write!(dir, "plain.txt", "item 2041, caf\u00E9, and a backslash escape \\u{202E}\n")
      assert {:ok, _summary} = Check.run(scenarios: [deep], source_files: [plain])
    end
  end

  describe "impure_source" do
    test "each impure call in lib source is reported with its own token", %{dir: dir, deep: deep} do
      calls = [
        {"DateTime.utc_now", "DateTime.utc_now()"},
        {"NaiveDateTime.utc_now", "NaiveDateTime.utc_now()"},
        {"Date.utc_today", "Date.utc_today()"},
        {":rand.", ":rand.uniform(3)"},
        {"System.", "System.os_time()"},
        {":os.", ":os.timestamp()"},
        {"Repo.", "MyApp.Repo.all(Thing)"},
        {"~U[", "~U[2026-01-01 00:00:00Z]"}
      ]

      for {token, call} <- calls do
        path = write!(dir, "lib/scrypath_fixtures/planted.ex", "def at, do: #{call}\n")

        assert {:error, [{:source, {:impure_source, ^path, ^token}}]} =
                 Check.run(scenarios: [deep], source_files: [path]),
               "#{token} was not reported on its own"
      end
    end

    test "positive controls: the epoch literal is allowed in its one file, nothing is allowed elsewhere in lib",
         %{dir: dir, deep: deep} do
      epoch = write!(dir, "lib/scrypath_fixtures.ex", "@e ~U[2026-11-20 14:00:00Z]\n")
      assert {:ok, _summary} = Check.run(scenarios: [deep], source_files: [epoch])

      # the same literal in that file is the only exemption: a clock call there is still reported
      clock = write!(dir, "lib/scrypath_fixtures.ex", "def at, do: DateTime.utc_now()\n")

      assert {:error, [{:source, {:impure_source, ^clock, "DateTime.utc_now"}}]} =
               Check.run(scenarios: [deep], source_files: [clock])

      # only lib source is held to purity: notes outside lib may mention a call
      notes = write!(dir, "notes.txt", "never call DateTime.utc_now here\n")
      assert {:ok, _summary} = Check.run(scenarios: [deep], source_files: [notes])
    end
  end

  describe "denylisted_word" do
    test "each compliance word and the canon id in a label is reported as spelled in the list", %{
      deep: deep
    } do
      id = deep.id

      for word <- ~w(HIPAA GDPR PCI SOX compliant certified LGX-0417-DE) do
        labels = [{id, "Logistify shipments, #{word} ready (fictional)"}]

        assert {:error, [{^id, {:denylisted_word, {:label, ^id}, ^word}}]} =
                 Check.run(scenarios: [deep], labels: labels),
               "#{word} was not reported"
      end
    end

    test "matching ignores case and respects word boundaries", %{deep: deep} do
      shouting = [{deep.id, "hipaa READY (fictional)"}]
      assert {:error, [{_id, {:denylisted_word, _where, "HIPAA"}}]} = run_labels(deep, shouting)

      # a longer word that merely contains one is not a claim
      assert {:ok, _summary} = run_labels(deep, [{deep.id, "PCIe adapter (fictional)"}])
      assert {:ok, _summary} = run_labels(deep, [{deep.id, "Compliance desk (fictional)"}])
      assert {:ok, _summary} = run_labels(deep, [{deep.id, "Logistify shipments (fictional)"}])
    end

    test "a word inside scenario data is reported against the scenario", %{deep: deep} do
      planted =
        update_in(deep.scrypath_opts[:oban_jobs], fn [job | rest] ->
          [put_in(job, [:args, "document_ids"], ["GDPR-1"]) | rest]
        end)

      id = deep.id

      assert {:error, [{^id, {:denylisted_word, {:scenario, ^id}, "GDPR"}}]} =
               Check.run(scenarios: [planted])
    end

    test "a word in the README or in lib source is reported against the file", %{
      dir: dir,
      deep: deep
    } do
      readme = write!(dir, "README.md", "This catalog is Certified for audits.\n")
      lib = write!(dir, "lib/scrypath_fixtures/planted.ex", "# SOX notes\n")

      assert {:error, [{:source, {:denylisted_word, {:file, ^readme}, "certified"}}]} =
               Check.run(scenarios: [deep], source_files: [readme])

      assert {:error, [{:source, {:denylisted_word, {:file, ^lib}, "SOX"}}]} =
               Check.run(scenarios: [deep], source_files: [lib])
    end

    test "positive controls: the check's own attribute is the one exemption, other files are not",
         %{dir: dir, deep: deep} do
      check = write!(dir, "lib/scrypath_fixtures/check.ex", "@denied ~w(HIPAA GDPR)\n")
      assert {:ok, _summary} = Check.run(scenarios: [deep], source_files: [check])

      # a recording or a script is not text the rule reads
      recording = write!(dir, "recordings/body.json", ~s({"message":"certified"}))
      assert {:ok, _summary} = Check.run(scenarios: [deep], source_files: [recording])
    end
  end

  describe "provenance_missing" do
    test "an adopter schema without the provenance line is reported", %{dir: dir, wiki: wiki} do
      path =
        write!(dir, "lib/scrypath_fixtures/wikily/page.ex", """
        defmodule Planted do
          @moduledoc "A wiki page schema."
        end
        """)

      assert {:error, [{:source, {:provenance_missing, ^path}}]} =
               Check.run(scenarios: [wiki], source_files: [path])
    end

    test "an adopter module is held to it too", %{dir: dir, wiki: wiki} do
      path = write!(dir, "lib/scrypath_fixtures/wikily.ex", "defmodule Planted do\nend\n")

      assert {:error, [{:source, {:provenance_missing, ^path}}]} =
               Check.run(scenarios: [wiki], source_files: [path])
    end

    test "the line must say fictional, Scrypath-owned and no records, each on its own", %{
      dir: dir,
      wiki: wiki
    } do
      lines = [
        "Scrypath-owned data, no records copied.",
        "Fictional adopter, no records copied.",
        "Fictional adopter, Scrypath-owned data."
      ]

      for line <- lines do
        path = write!(dir, "lib/scrypath_fixtures/wikily/page.ex", "# #{line}\n")

        assert {:error, [{:source, {:provenance_missing, ^path}}]} =
                 Check.run(scenarios: [wiki], source_files: [path]),
               "#{inspect(line)} should not be enough"
      end
    end

    test "positive controls: the line makes it clean, and a file of another kind is not held to it",
         %{dir: dir, wiki: wiki} do
      path = write!(dir, "lib/scrypath_fixtures/wikily/page.ex", "# #{@provenance_line}\n")
      assert {:ok, _summary} = Check.run(scenarios: [wiki], source_files: [path])

      other = write!(dir, "lib/scrypath_fixtures/helper.ex", "defmodule Helper do\nend\n")
      assert {:ok, _summary} = Check.run(scenarios: [wiki], source_files: [other])

      # an adopter nobody registered is not a Wikily file
      elsewhere = write!(dir, "lib/scrypath_fixtures/nobody/page.ex", "defmodule N do\nend\n")
      assert {:ok, _summary} = Check.run(scenarios: [wiki], source_files: [elsewhere])
    end
  end

  describe "bulk data" do
    test "the golden digest is the digest of the sample as it is today" do
      assert Bulk.sample_digest() == Bulk.golden_digest()
      assert Bulk.golden_digest() =~ ~r/\A[0-9a-f]{64}\z/
    end

    test "a changed sample is reported with its own digest", %{deep: deep} do
      changed =
        Keyword.update!(Bulk.sample(), :shipment, fn [first | rest] ->
          [%{first | lane: "Rotterdam to Nowhere"} | rest]
        end)

      got = Bulk.digest(changed)
      refute got == Bulk.golden_digest()

      assert {:error, [{:bulk, {:bulk_digest, ^got}}]} =
               Check.run(scenarios: [deep], bulk_sample: changed)
    end

    test "pick, row and rows are deterministic and agree with each other" do
      list = ~w(a b c d e f g)
      assert Bulk.pick(list, 196, 7, :tag) == Bulk.pick(list, 196, 7, :tag)
      assert Bulk.pick(list, 196, 7, :tag) == Enum.at(list, :erlang.phash2({196, 7, :tag}, 7))

      for kind <- [:product, :shipment, :page] do
        rows = Bulk.rows(kind, 196, 25)
        assert rows == Bulk.rows(kind, 196, 25)
        assert length(rows) == 25
        assert Enum.at(rows, 6) == Bulk.row(kind, 196, 7)
        assert length(Enum.uniq_by(rows, & &1.id)) == 25
        # a different seed picks different records
        refute rows == Bulk.rows(kind, 197, 25)
      end
    end

    test "rows are capped at 5,000 and the kinds are closed" do
      assert length(Bulk.rows(:product, 196, 5_000)) == 5_000
      assert Bulk.rows(:page, 196, 0) == []

      assert_raise ArgumentError, ~r/0 to 5000/, fn -> Bulk.rows(:product, 196, 5_001) end
      assert_raise ArgumentError, fn -> Bulk.rows(:shipment, 196, -1) end
      assert_raise FunctionClauseError, fn -> Bulk.rows(:invoice, 196, 3) end
    end

    test "every record says it is fictional where it has a name" do
      assert Enum.all?(Bulk.rows(:product, 196, 100), &(&1.title =~ "(fictional)"))
      assert Enum.all?(Bulk.rows(:shipment, 196, 100), &(&1.carrier =~ "(fictional)"))
      assert Enum.all?(Bulk.rows(:page, 196, 100), &(&1.title =~ "(fictional)"))
    end
  end

  # -- helpers -------------------------------------------------------------------------------

  defp run_labels(scenario, labels), do: Check.run(scenarios: [scenario], labels: labels)

  # Writes `content` under `dir` and returns the path.
  defp write!(dir, relative, content) do
    path = Path.join(dir, relative)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, content)
    path
  end
end
