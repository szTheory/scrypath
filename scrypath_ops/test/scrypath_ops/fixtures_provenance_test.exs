defmodule ScrypathOps.FixturesProvenanceTest do
  @moduledoc false
  # Phase 196: the rules that keep the fixtures honest about where they come from and what they are
  # made of. Each rule has a planted failure on a real temporary file (or a changed bulk sample) that
  # asserts exactly its own problem, beside a positive control that the same shape is clean.
  #
  #   * labels: every registered scenario says "(fictional)";
  #   * `:raw_format_char`: a bidirectional control, zero-width or other invisible formatting
  #     character or byte-order mark anywhere in the project (Trojan Source); the character is built
  #     from its code point, never typed here;
  #   * `:impure_source`: a wall-clock, random, unique-id, operating-system, file-system or repository
  #     call in `lib/` (`Check.impure_tokens/0`; a token without a plant here fails the coverage test);
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
    # One code point of each class, written as a number: this file holds none of them itself.
    # Where a class is a range, its first and last member and a notable one are named.
    @planted_codepoints [
      {0x00AD, "soft hyphen"},
      {0x061C, "Arabic letter mark"},
      {0x180E, "Mongolian vowel separator"},
      {0x200B, "zero-width space"},
      {0x200D, "zero-width joiner"},
      {0x200F, "right-to-left mark"},
      {0x202A, "left-to-right embedding"},
      {0x202E, "right-to-left override"},
      {0x2060, "word joiner"},
      {0x2061, "function application"},
      {0x2064, "invisible plus"},
      {0x2066, "left-to-right isolate"},
      {0x2069, "pop directional isolate"},
      {0xFE00, "variation selector 1"},
      {0xFE0F, "variation selector 16"},
      {0xFEFF, "byte-order mark"},
      {0xE0000, "first tag character"},
      {0xE0001, "language tag"},
      {0xE007F, "cancel tag"}
    ]

    test "a control character in a project file is reported with its code point", %{dir: dir} do
      for {codepoint, name} <- @planted_codepoints do
        path = write!(dir, "raw-#{codepoint}.txt", "a" <> <<codepoint::utf8>> <> "b")

        assert {:error, [{:source, {:raw_format_char, ^path, ^codepoint}}]} =
                 run_source([path]),
               "U+#{Integer.to_string(codepoint, 16)} (#{name}) was not reported"
      end
    end

    test "the list names every planted class, and no listed code point is a printable one" do
      listed = MapSet.new(Check.format_codepoints())

      for {codepoint, name} <- @planted_codepoints do
        assert codepoint in listed, "#{name} is not in Check.format_codepoints/0"
      end

      # every listed code point is a valid scalar, and none is a letter, a digit or a symbol
      for codepoint <- listed do
        printable = <<codepoint::utf8>> =~ ~r/[\p{L}\p{N}\p{P}\p{S}]/u
        refute printable, "U+#{Integer.to_string(codepoint, 16)} looks printable"
      end
    end

    test "every listed code point in one file is one problem each", %{dir: dir} do
      listed = Check.format_codepoints()
      content = for codepoint <- listed, into: "", do: <<codepoint::utf8>>
      path = write!(dir, "all.txt", content)

      assert {:error, problems} = run_source([path])
      assert Enum.sort(problems) == Enum.sort(for(cp <- listed, do: raw(path, cp)))
    end

    test "two different characters in one file are two problems", %{dir: dir} do
      path = write!(dir, "two.txt", <<0xE2, 0x80, 0xAE, ?x, 0xE2, 0x80, 0x8B>>)

      assert {:error, problems} = run_source([path])

      assert Enum.sort(problems) ==
               Enum.sort([
                 {:source, {:raw_format_char, path, 0x200B}},
                 {:source, {:raw_format_char, path, 0x202E}}
               ])
    end

    test "positive control: plain text, an escape written as text and the neighbours of each range are clean",
         %{dir: dir} do
      plain = write!(dir, "plain.txt", "item 2041, caf\u00E9, and a backslash escape \\u{202E}\n")
      assert {:ok, _summary} = run_source([plain])

      # visible or ordinary neighbours of every listed range: the Arabic semicolon and letter, the
      # hair space, the hyphen, the narrow no-break space, a superscript zero, the not sign and the
      # registered sign, the first code point after the variation selectors and after the tags
      neighbours = [
        0x061B,
        0x0627,
        0x200A,
        0x2010,
        0x202F,
        0x2070,
        0x00AC,
        0x00AE,
        0xFE10,
        0xE0080
      ]

      text = for codepoint <- neighbours, into: "", do: <<codepoint::utf8>>
      assert {:ok, _summary} = run_source([write!(dir, "neighbours.txt", text)])
    end
  end

  describe "impure_source" do
    # One call for every token `Check.impure_tokens/0` lists, each matching its own token and no
    # other. The coverage test below fails for a token with no entry, so the list cannot grow
    # without a plant.
    @impure_calls [
      {"DateTime.utc_now", "DateTime.utc_now()"},
      {"DateTime.now", ~S|DateTime.now!("Etc/UTC")|},
      {"NaiveDateTime.utc_now", "NaiveDateTime.utc_now()"},
      {"NaiveDateTime.local_now", "NaiveDateTime.local_now()"},
      {"Date.utc_today", "Date.utc_today()"},
      {"Time.utc_now", "Time.utc_now()"},
      {":erlang.system_time", ":erlang.system_time(:second)"},
      {":erlang.monotonic_time", ":erlang.monotonic_time()"},
      {":erlang.timestamp", ":erlang.timestamp()"},
      {":erlang.localtime", ":erlang.localtime()"},
      {":erlang.universaltime", ":erlang.universaltime()"},
      {":calendar.local_time", ":calendar.local_time()"},
      {":calendar.universal_time", ":calendar.universal_time()"},
      {"Process.sleep", "Process.sleep(10)"},
      {":timer.", ":timer.tc(fn -> :ok end)"},
      {"~U[", "~U[2026-01-01 00:00:00Z]"},
      {"~N[", "~N[2026-01-01 00:00:00]"},
      {"~D[", "~D[2026-01-01]"},
      {"~T[", "~T[00:00:00]"},
      {":rand.", ":rand.uniform(3)"},
      {"Enum.random", "Enum.random([1, 2])"},
      {"Enum.shuffle", "Enum.shuffle([1, 2])"},
      {"Enum.take_random", "Enum.take_random([1, 2], 1)"},
      {":crypto.strong_rand_bytes", ":crypto.strong_rand_bytes(4)"},
      {":erlang.unique_integer", ":erlang.unique_integer([:positive])"},
      {"UUID.generate", "Ecto.UUID.generate()"},
      {"UUID.bingenerate", "Ecto.UUID.bingenerate()"},
      {"UUID.uuid1", "UUID.uuid1()"},
      {"UUID.uuid4", "UUID.uuid4()"},
      {"System.", "System.os_time()"},
      {":os.", ":os.timestamp()"},
      {"File.", ~S|File.read!("x")|},
      {"Repo.", "MyApp.Repo.all(Thing)"}
    ]

    test "every token the check forbids has a planted call here, and no call names another token" do
      assert Enum.sort(Enum.map(@impure_calls, &elem(&1, 0))) == Enum.sort(Check.impure_tokens())
    end

    test "each impure call in lib source is reported with its own token", %{dir: dir} do
      for {token, call} <- @impure_calls do
        path = write!(dir, "lib/scrypath_fixtures/planted.ex", "def at, do: #{call}\n")

        assert {:error, [{:source, {:impure_source, ^path, ^token}}]} = run_source([path]),
               "#{token} was not reported on its own"
      end
    end

    test "positive controls: pure calls, and a word that only contains a token, are clean", %{
      dir: dir
    } do
      pure = [
        ~S|:crypto.hash(:sha256, "x")|,
        "DateTime.add(now, 5, :second)",
        "DateTime.diff(a, b)",
        "DateTime.to_iso8601(now)",
        "Calendar.strftime(now, \"%Y\")",
        "Enum.at([1, 2], 0)",
        "Enum.sort([2, 1])",
        ":erlang.phash2({1, 2}, 10)",
        # the token must start a word: these end in the same letters
        "Profile.read(x)",
        "Subsystem.call()",
        "MyTime.utc_now_fixed()",
        "MyProcess.sleep(1)"
      ]

      for call <- pure do
        path = write!(dir, "lib/scrypath_fixtures/planted.ex", "def at, do: #{call}\n")
        assert {:ok, _summary} = run_source([path]), "#{call} should be clean"
      end
    end

    test "positive controls: a whole-line comment may name a call, a comment after code is scanned",
         %{dir: dir} do
      comment = write!(dir, "lib/scrypath_fixtures/commented.ex", "# never DateTime.utc_now()\n")
      indented = write!(dir, "lib/scrypath_fixtures/indented.ex", "  \t# Enum.random([1])\n")
      assert {:ok, _summary} = run_source([comment, indented])

      # the documented limit: only whole-line comments are skipped
      trailing = write!(dir, "lib/scrypath_fixtures/trailing.ex", "x = 1 # Enum.random([1])\n")

      assert {:error, [{:source, {:impure_source, ^trailing, "Enum.random"}}]} =
               run_source([trailing])
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

    test "positive controls: the file system is read in the two modules built to read it, nowhere else",
         %{dir: dir} do
      read = ~S|def body, do: File.read!("x")| <> "\n"

      for module <- ["recordings", "check"] do
        path = write!(dir, "lib/scrypath_fixtures/#{module}.ex", read)
        assert {:ok, _summary} = run_source([path]), "#{module}.ex may read files"
      end

      for module <- ["scrypath_fixtures", "scrypath_fixtures/meili", "scrypath_fixtures/bulk"] do
        path = write!(dir, "lib/#{module}.ex", read)

        assert {:error, [{:source, {:impure_source, ^path, "File."}}]} = run_source([path]),
               "#{module}.ex may not read files"
      end
    end

    test "positive controls: recordings, the README and a script may name any call", %{dir: dir} do
      text = Enum.map_join(@impure_calls, "\n", &elem(&1, 1)) <> "\n"

      for relative <- [
            "recordings/meilisearch-v1.15/body.json",
            "recordings/record.sh",
            "README.md",
            "mix.exs",
            "test/some_test.exs"
          ] do
        path = write!(dir, relative, text)
        assert {:ok, _summary} = run_source([path]), "#{relative} is not lib source"
      end
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

  # The source lints need no scenario: with none, the run is only the files.
  defp run_source(files), do: Check.run(scenarios: [], source_files: files)

  defp raw(path, codepoint), do: {:source, {:raw_format_char, path, codepoint}}

  # Writes `content` under `dir` and returns the path.
  defp write!(dir, relative, content) do
    path = Path.join(dir, relative)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, content)
    path
  end
end
