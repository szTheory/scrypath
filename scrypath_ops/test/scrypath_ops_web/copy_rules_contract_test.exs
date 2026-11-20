defmodule ScrypathOpsWeb.CopyRulesContractTest do
  @moduledoc false
  # COPY-03: the copy rules table (`test/support/copy_rules.json`) is data; this is the one test
  # that enforces it. It validates the table, scans each row's `source_scope` in the tracked
  # files, and renders each registered surface (an existing fixture state of a screen).
  #
  # The planted-failure tests drive the same `ScrypathOps.Test.CopyRules` functions the real
  # tests use, so a guard that cannot fail would show up here. Planted forbidden strings are
  # built by concatenation so this file never spells a phrase a row forbids.

  use ScrypathOpsWeb.ConnCase, async: false

  alias ScrypathOps.Test.CopyRules
  alias ScrypathOps.Test.CopySurfaces

  setup_all do
    root = CopyRules.repo_root!()
    rules = CopyRules.load!()
    paths = CopyRules.tracked_paths(root, rules["exempt_paths"])

    %{root: root, rules: rules, paths: paths}
  end

  describe "the real table" do
    test "validates against the glossary and the registered surfaces", %{root: root, rules: rules} do
      assert_valid(rules, root)
    end

    test "every source_scope glob matches a tracked file", %{rules: rules, paths: paths} do
      assert CopyRules.unmatched_scopes(rules["rules"], paths) == []
    end

    test "no row's source scope holds forbidden text", %{root: root, rules: rules, paths: paths} do
      violations =
        for row <- rules["rules"],
            violation <- CopyRules.scan_source(row, root, paths),
            do: violation

      assert_no_violations(violations)
    end

    test "every registered surface reaches its state and satisfies its rows", %{
      conn: conn,
      rules: rules
    } do
      violations =
        for id <- CopySurfaces.ids(),
            violation <-
              CopyRules.check_surface(
                rules["rules"],
                id,
                CopySurfaces.anchor(id),
                CopySurfaces.render(id, %{conn: conn})
              ),
            do: violation

      assert_no_violations(violations)
    end
  end

  describe "planted failures are caught by the same helpers, and their accept cases pass" do
    test "forbidden text in a file inside a row's scope", %{rules: rules} do
      row = row!(rules, "searchable-observation-only")
      path = "scrypath_ops/lib/planted.ex"

      planted = temp_tree!(%{path => ~s(label: "#{not_searchable()}"\n)})
      clean = temp_tree!(%{path => ~s(label: "Not used for search"\n)})
      outside = temp_tree!(%{"docs/planted.md" => not_searchable() <> "\n"})

      assert [%{kind: :forbidden, row: "searchable-observation-only", path: ^path, line: 1} = hit] =
               CopyRules.scan_source(row, planted, [path])

      assert hit.text == not_searchable()
      assert CopyRules.format_violation(hit) =~ "searchable-observation-only"
      assert CopyRules.scan_source(row, clean, [path]) == []
      assert CopyRules.scan_source(row, outside, ["docs/planted.md"]) == []
    end

    test "the whole-tree scope reads any file, and exempt paths are never scanned", %{
      rules: rules,
      paths: paths
    } do
      row = row!(rules, "control-room-casing")
      path = "docs/planted.md"

      planted = temp_tree!(%{path => "See the " <> title_case_label() <> " page.\n"})
      clean = temp_tree!(%{path => "See the Control room page.\n"})

      assert [%{kind: :forbidden, row: "control-room-casing", path: ^path, text: text}] =
               CopyRules.scan_source(row, planted, [path])

      assert text == title_case_label()
      assert CopyRules.scan_source(row, clean, [path]) == []

      refute Enum.any?(paths, &String.starts_with?(&1, ".planning/"))
      refute Enum.any?(paths, &String.starts_with?(&1, "brand/"))
      refute "scrypath_ops/test/support/copy_rules.json" in paths
      assert "GLOSSARY.md" in paths
    end

    test "the Last succeeded and Clear rows catch their old forms and pass their new ones", %{
      rules: rules
    } do
      last = row!(rules, "last-succeeded")
      absence = row!(rules, "last-succeeded--absence")
      clear = row!(rules, "clear-needs-observation")
      path = "scrypath_ops/lib/planted.ex"

      for old <- ["Last " <> "success", "last " <> "successful"] do
        root = temp_tree!(%{path => ~s(label: "#{old}"\n)})
        assert [%{row: "last-succeeded", text: ^old}] = CopyRules.scan_source(last, root, [path])

        html = "<dt>" <> old <> "</dt>"
        assert [%{kind: :forbidden, text: ^old}] = CopyRules.evaluate_surface(absence, "x", html)
      end

      # Underscored identifiers are not copy: the pattern needs the space.
      ident = temp_tree!(%{path => "last_success_refs = source_last_success_label\n"})
      assert CopyRules.scan_source(last, ident, [path]) == []

      assert CopyRules.evaluate_surface(absence, "x", "<dt>Last succeeded</dt>") == []

      assert [%{kind: :forbidden, text: "Clear"}] =
               CopyRules.evaluate_surface(clear, "x", "<span>Clear</span>")

      assert CopyRules.evaluate_surface(clear, "x", "<span>Cleared</span> no status word") == []
    end

    test "a retained degraded observation must keep its Failed word and must not read Clear", %{
      rules: rules
    } do
      clear = row!(rules, "clear-needs-observation")
      kept = row!(rules, "clear-needs-observation--failed-word-kept")
      surface = "control_room.refresh_retained_degraded"

      word = fn text -> ~s(<span class="ops-sync-status__word">#{text}</span>) end

      # The nav link reads "Failed sync work": the bare word is on every page, so the row must
      # key on the status word's own element.
      nav = ~s(<a href="/ops/failed-sync">Failed sync work</a>)

      assert CopyRules.evaluate_surface(kept, surface, nav <> word.("Failed")) == []
      assert CopyRules.evaluate_surface(clear, surface, nav <> word.("Failed")) == []

      assert [%{kind: :required_missing, row: "clear-needs-observation--failed-word-kept"}] =
               CopyRules.evaluate_surface(
                 kept,
                 surface,
                 nav <> "<p>1 Meilisearch task failed</p>"
               )

      assert [%{kind: :required_missing}] =
               CopyRules.evaluate_surface(kept, surface, nav <> word.("Clear"))

      assert [%{kind: :forbidden, row: "clear-needs-observation", text: "Clear"}] =
               CopyRules.evaluate_surface(clear, surface, nav <> word.("Clear"))

      # Through the surface check: the anchor alone, with no Failed word, fails the row.
      anchor = CopySurfaces.anchor(surface)

      violated =
        rules["rules"]
        |> CopyRules.check_surface(surface, anchor, "<p>" <> anchor <> "</p>")
        |> Enum.map(& &1.row)

      assert "clear-needs-observation--failed-word-kept" in violated
    end

    test "the pending rows catch their old forms and pass their new ones", %{rules: rules} do
      aggregate = row!(rules, "pending-aggregate")
      count = row!(rules, "pending-count")
      caught_up = row!(rules, "pending-caught-up")
      reason = row!(rules, "pending-promotion-reason")
      path = "scrypath_ops/lib/planted.ex"

      for old <- [
            "1 job " <> "queued",
            "3 jobs " <> "queued",
            "Nothing " <> "queued, retrying or failed",
            "wait for " <> "queued work to finish"
          ] do
        root = temp_tree!(%{path => ~s(label: "#{old}"\n)})

        assert [%{kind: :forbidden, row: "pending-aggregate"}] =
                 CopyRules.scan_source(aggregate, root, [path])

        assert [%{kind: :forbidden}] =
                 CopyRules.evaluate_surface(aggregate, "x", "<p>" <> old <> "</p>")
      end

      for new <- [
            "1 job pending",
            "2 jobs pending, 1 scheduled retry",
            "Pending work",
            "a jobs list"
          ] do
        root = temp_tree!(%{path => ~s(label: "#{new}"\n)})
        assert CopyRules.scan_source(aggregate, root, [path]) == []
        assert CopyRules.evaluate_surface(aggregate, "x", "<p>" <> new <> "</p>") == []
      end

      assert CopyRules.evaluate_surface(count, "x", "<p>Pending, 1 job pending</p>") == []
      assert CopyRules.evaluate_surface(count, "x", "<p>12 jobs pending</p>") == []

      assert [%{kind: :required_missing}] =
               CopyRules.evaluate_surface(count, "x", "<p>1 job " <> "queued</p>")

      assert [%{kind: :required_missing}] =
               CopyRules.evaluate_surface(count, "x", "<p>jobs pending</p>")

      assert CopyRules.evaluate_surface(
               caught_up,
               "x",
               "Caught up. Nothing pending, retrying or failed."
             ) ==
               []

      assert [%{kind: :required_missing}] =
               CopyRules.evaluate_surface(
                 caught_up,
                 "x",
                 "Caught up. Nothing " <> "queued, retrying or failed."
               )

      assert CopyRules.evaluate_surface(reason, "x", "Wait for pending sync work to finish.") ==
               []

      assert [%{kind: :required_missing}] =
               CopyRules.evaluate_surface(reason, "x", "Wait for " <> "queued work to finish.")
    end

    test "the queued and accepted rows catch their old forms and pass their new ones", %{
      rules: rules
    } do
      retry = row!(rules, "retry-queued-not-accepted")
      no_accepted = row!(rules, "retry-surfaces-no-accepted")
      meili = row!(rules, "accepted-is-meilisearch-only")
      queued = row!(rules, "queued-host-queue-outcome")
      path = "scrypath_ops/lib/planted.ex"
      accepted = "accep" <> "ted"

      for old <- [
            "Retry " <> accepted,
            "A retry for job 4 is already " <> accepted,
            "The queue " <> accepted <> " this retry",
            "observes the " <> accepted <> " operation",
            "Acceptance" <> " alone does not confirm recovery"
          ] do
        root = temp_tree!(%{path => ~s(label: "#{old}"\n)})

        assert [%{kind: :forbidden, row: "retry-queued-not-accepted"}] =
                 CopyRules.scan_source(retry, root, [path])

        assert [%{kind: :forbidden}] =
                 CopyRules.evaluate_surface(retry, "x", "<p>Retry queued: " <> old <> "</p>")
      end

      clean = temp_tree!(%{path => ~s(label: "A retry for job 4 is already queued."\n)})
      assert CopyRules.scan_source(retry, clean, [path]) == []
      assert CopyRules.evaluate_surface(retry, "x", "<p>Retry queued · queue job 4</p>") == []

      assert [
               %{kind: :required_missing, text: "Retry queued"},
               %{kind: :forbidden, text: "Retry sent"}
             ] = CopyRules.evaluate_surface(retry, "x", "<p>Retry sent</p>")

      # The word-level row reads rendered text only, and only whole words.
      assert [%{kind: :forbidden, text: ^accepted}] =
               CopyRules.evaluate_surface(no_accepted, "x", "<p>" <> accepted <> "</p>")

      assert [%{kind: :forbidden, text: "Acceptance"}] =
               CopyRules.evaluate_surface(no_accepted, "x", "<p>Acceptance</p>")

      assert CopyRules.evaluate_surface(no_accepted, "x", "<p>Retry queued, unacceptable</p>") ==
               []

      assert CopyRules.scan_source(no_accepted, clean, [path]) == []

      # The Meilisearch uses survive: the row requires the swap title.
      assert CopyRules.evaluate_surface(meili, "x", "<h3>Index swap accepted</h3>") == []

      assert [%{kind: :required_missing, text: "Index swap accepted"}] =
               CopyRules.evaluate_surface(meili, "x", "<h3>Index swap queued</h3>")

      assert CopyRules.evaluate_surface(queued, "x", "<p>Retry queued</p>") == []

      assert [%{kind: :required_missing}] =
               CopyRules.evaluate_surface(queued, "x", "<p>Retry " <> accepted <> "</p>")

      assert [%{kind: :required_missing}] =
               CopyRules.evaluate_surface(queued, "x", "<p>dequeued</p>")
    end

    # 190 review WR-04: the forbidden lists cover the variants the glossary Avoid lists name,
    # not only the old strings, and the Q-2 flash is pinned by a positive assertion.
    test "the widened forbidden lists catch the glossary's variants and pass the real wording", %{
      rules: rules
    } do
      aggregate = row!(rules, "pending-aggregate")
      retry = row!(rules, "retry-queued-not-accepted")
      searchable = row!(rules, "searchable-observation-only")
      healthy = row!(rules, "clear-not-healthy")
      path = "scrypath_ops/lib/planted.ex"
      accepted = "accep" <> "ted"

      forbidden = fn row, text ->
        root = temp_tree!(%{path => ~s(label: "#{text}"\n)})
        scanned = CopyRules.scan_source(row, root, [path])
        rendered = CopyRules.evaluate_surface(row, "x", "<p>" <> text <> "</p>")

        {Enum.filter(scanned, &(&1.kind == :forbidden)),
         Enum.filter(rendered, &(&1.kind == :forbidden))}
      end

      for {row, texts} <- [
            {aggregate,
             [
               "2 queued " <> "jobs",
               "3 " <> "queued",
               "2 jobs are " <> "queued",
               "Nothing is " <> "queued"
             ]},
            {retry,
             [
               "Queue " <> accepted <> " this retry",
               "The retry was " <> accepted,
               "Accepted" <> " retry",
               "Retry " <> "sent",
               "Retry was " <> "sent"
             ]},
            {searchable,
             ["not " <> "searchable", "Not " <> "searched yet", "not searched " <> "yet"]},
            {healthy, ["Healthy", "All " <> "good", "all good"]}
          ],
          text <- texts do
        assert {[_ | _], [_ | _]} = forbidden.(row, text), "#{row["id"]} missed #{inspect(text)}"
      end

      # What the screens say today stays clean.
      for {row, texts} <- [
            {aggregate,
             [
               "1 job pending",
               "A retry for job 4 is already queued.",
               "Retry queued · queue job 991",
               "Nothing pending, retrying or failed"
             ]},
            {retry,
             [
               "A retry for job 4 is already queued.",
               "Retry queued · queue job 991",
               "A queued retry is a new operation",
               "The backend " <> accepted <> " this swap"
             ]},
            {searchable,
             ["Used for search", "Not used for search yet.", "documents are searchable yet"]},
            {healthy, ["Clear", "Search health", "No sync failures found"]}
          ],
          text <- texts do
        assert {[], []} = forbidden.(row, text), "#{row["id"]} flagged #{inspect(text)}"
      end

      # The one developer doc that says an accepted retry is excused by its exact phrase only.
      doc =
        "# Private, bounded correlation of an " <>
          accepted <> " retry with its own Meilisearch task.\n"

      excused_root = temp_tree!(%{path => doc})
      stray_root = temp_tree!(%{path => "# an " <> accepted <> " retry elsewhere\n"})

      assert CopyRules.scan_source(retry, excused_root, [path]) == []
      assert [%{kind: :forbidden}] = CopyRules.scan_source(retry, stray_root, [path])
    end

    test "the retry flash must name its queue job", %{rules: rules} do
      row = row!(rules, "retry-queued-not-accepted--flash")
      surface = "failed_sync.after_retry"

      assert CopyRules.evaluate_surface(row, surface, "<p>Retry queued · queue job 991</p>") == []

      # The receipt title alone is also "Retry queued": it must not satisfy the flash row.
      for text <- [
            "<h3>Retry queued</h3>",
            "<p>Retry " <> "sent · queue job 991</p>",
            "<p>Retry queued · queue job</p>"
          ] do
        assert [%{kind: :required_missing, row: "retry-queued-not-accepted--flash"}] =
                 CopyRules.evaluate_surface(row, surface, text)
      end
    end

    test "a Status wording term that no row cites fails, and the real table cites them all", %{
      root: root,
      rules: rules
    } do
      terms = CopyRules.status_terms(root)

      assert Enum.sort(terms) ==
               Enum.sort([
                 "Searchable",
                 "Pending",
                 "Queued",
                 "Retry queued",
                 "Accepted",
                 "Last succeeded",
                 "Clear"
               ])

      assert_valid(rules, root)

      # Dropping the only row that cites Queued leaves six of the seven terms cited.
      six =
        Map.update!(rules, "rules", fn rows ->
          Enum.reject(rows, &(&1["id"] == "queued-host-queue-outcome"))
        end)

      assert {:error, [message]} = validate(six, root)
      assert message == "glossary term \"Queued\" (Status wording) is cited by no row"
    end

    test "a rendered surface with the title-case label fails the casing row", %{rules: rules} do
      row = row!(rules, "control-room-casing")
      surface = "control_room.default"

      assert [
               %{kind: :required_missing, text: "Control room"},
               %{kind: :forbidden, text: text}
             ] = CopyRules.evaluate_surface(row, surface, "<h1>" <> title_case_label() <> "</h1>")

      assert text == title_case_label()
      assert CopyRules.evaluate_surface(row, surface, "<h1>Control room</h1>") == []
    end

    # 190 review WR-03: a hand-wrapped template splits a phrase across lines, and a rendered text
    # node keeps its newline and indentation. Matching collapses whitespace on both sides.
    test "a phrase wrapped across lines is caught in source and in rendered html", %{
      rules: rules
    } do
      path = "scrypath_ops/lib/planted.ex"
      accepted = "accep" <> "ted"

      cases = [
        {"retry-queued-not-accepted", "Retry" <> "\n   " <> accepted, "Retry " <> accepted},
        {"last-succeeded", "Last" <> "\n  " <> "success", "Last success"},
        {"control-room-casing", "Control" <> "\n " <> "Room", title_case_label()}
      ]

      for {id, wrapped, collapsed} <- cases do
        row = row!(rules, id)
        root = temp_tree!(%{path => "# one\n# two\n" <> wrapped <> "\n"})

        # Reported at the line where the match starts, in the original file.
        assert [%{kind: :forbidden, row: ^id, path: ^path, line: 3, text: ^collapsed}] =
                 CopyRules.scan_source(row, root, [path])

        html = "<p>" <> wrapped <> "</p>"

        assert [%{kind: :forbidden, row: ^id, text: ^collapsed} | _] =
                 Enum.filter(
                   CopyRules.evaluate_surface(row, "x", html),
                   &(&1.kind == :forbidden)
                 )
      end

      # A tab and a run of blank lines collapse too.
      row = row!(rules, "control-room-casing")
      root = temp_tree!(%{path => "Control" <> "\t\n\n  " <> "Room\n"})

      assert [%{kind: :forbidden, line: 1}] = CopyRules.scan_source(row, root, [path])

      # The same words on one line, and words that only look alike, are not caught.
      clean = temp_tree!(%{path => "Control room\nControl\n  rooms\n"})
      assert CopyRules.scan_source(row, clean, [path]) == []
    end

    test "a required phrase that a template reflows still satisfies its row", %{rules: rules} do
      row = row!(rules, "searchable-settings-row")

      reflowed = "Used for search, Not used for\n      search, Not used for\n  search yet."

      assert CopyRules.evaluate_surface(row, "x", "<td>" <> reflowed <> "</td>") == []

      assert [%{kind: :required_missing, text: "Not used for search yet."}] =
               CopyRules.evaluate_surface(row, "x", "Used for search, Not used for search")
    end

    test "an allowed_in phrase still excuses its own text across a wrap" do
      row = %{
        "id" => "sample",
        "forbidden" => [%{"text" => "beta", "match" => "literal", "case" => "sensitive"}],
        "required" => [],
        "allowed_in" => ["beta release"],
        "source_scope" => [],
        "surfaces" => ["x"]
      }

      assert CopyRules.evaluate_surface(row, "x", "ship the beta\n  release") == []

      assert [%{text: "beta"}] =
               CopyRules.evaluate_surface(row, "x", "ship the beta\n  release, then beta")
    end

    test "forbidden text in a rendered surface", %{rules: rules} do
      row = row!(rules, "searchable-observation-only")
      surface = "sync_drift.settings_missing_field"

      assert [%{kind: :forbidden, row: "searchable-observation-only", surface: ^surface} = hit] =
               CopyRules.evaluate_surface(row, surface, "<td>" <> not_searchable() <> "</td>")

      assert hit.text == not_searchable()
      assert CopyRules.format_violation(hit) =~ surface
      assert CopyRules.evaluate_surface(row, surface, "<td>Not used for search</td>") == []
    end

    test "a required entry absent from the rendered surface", %{rules: rules} do
      row = row!(rules, "searchable-settings-row")
      surface = "sync_drift.settings_missing_field"

      assert [%{kind: :required_missing, text: "Not used for search yet."}] =
               CopyRules.evaluate_surface(row, surface, "Used for search, Not used for search")

      assert CopyRules.evaluate_surface(
               row,
               surface,
               "Used for search, Not used for search, Not used for search yet."
             ) == []
    end

    test "a surface whose html lacks its state anchor evaluates no row", %{rules: rules} do
      surface = "sync_drift.settings_missing_field"
      anchor = CopySurfaces.anchor(surface)
      rows = rules["rules"]
      stale = "<p>" <> not_searchable() <> "</p>"

      assert [%{kind: :anchor_missing, surface: ^surface, text: ^anchor}] =
               CopyRules.check_surface(rows, surface, anchor, stale)

      reached =
        ~s(<td data-missing="true">Used for search, Not used for search, Not used for search yet.</td>)

      assert CopyRules.check_surface(rows, surface, anchor, reached) == []
    end

    test "a row with a missing field", %{root: root, rules: rules} do
      for field <- ~w(id rule glossary forbidden required allowed_in source_scope surfaces) do
        planted = replace_row(rules, "searchable-observation-only", &Map.delete(&1, field))

        assert {:error, messages} = validate(planted, root)
        assert Enum.any?(messages, &(&1 =~ "missing field #{field}")), inspect(messages)
      end

      assert_valid(rules, root)
    end

    test "a row with an empty surfaces list", %{root: root, rules: rules} do
      planted = replace_row(rules, "searchable-observation-only", &Map.put(&1, "surfaces", []))

      assert {:error, messages} = validate(planted, root)
      assert Enum.any?(messages, &(&1 =~ "surfaces must be a non-empty list"))
    end

    test "a row that names an unregistered surface", %{root: root, rules: rules} do
      planted =
        replace_row(
          rules,
          "searchable-observation-only",
          &Map.put(&1, "surfaces", ["nowhere.page"])
        )

      assert {:error, messages} = validate(planted, root)
      assert Enum.any?(messages, &(&1 =~ ~s(surface "nowhere.page" is not registered)))
    end

    test "a registered surface that no row uses, or that has no anchor", %{
      root: root,
      rules: rules
    } do
      terms = CopyRules.glossary_terms(root)

      unused = Map.put(CopySurfaces.anchors(), "extra.surface", "anchor text")

      assert {:error, unused_messages} =
               CopyRules.validate(rules, glossary_terms: terms, surfaces: unused)

      assert Enum.any?(unused_messages, &(&1 =~ "surface extra.surface is registered but no row"))

      no_anchor = Map.put(CopySurfaces.anchors(), "sync_drift.settings_missing_field", "")

      assert {:error, anchor_messages} =
               CopyRules.validate(rules, glossary_terms: terms, surfaces: no_anchor)

      assert Enum.any?(anchor_messages, &(&1 =~ "has no state anchor"))
    end

    test "a state anchor that carries a phrase a row requires", %{root: root, rules: rules} do
      terms = CopyRules.glossary_terms(root)

      tainted =
        Map.put(CopySurfaces.anchors(), "sync_drift.settings_missing_field", "Used for search")

      assert {:error, messages} =
               CopyRules.validate(rules, glossary_terms: terms, surfaces: tainted)

      assert Enum.any?(messages, &(&1 =~ "state anchor contains text"))
    end

    test "a glossary value that is not a glossary term", %{root: root, rules: rules} do
      planted =
        replace_row(rules, "searchable-observation-only", &Map.put(&1, "glossary", "Searchably"))

      assert {:error, messages} = validate(planted, root)
      assert Enum.any?(messages, &(&1 =~ "is not a bold term in GLOSSARY.md"))
    end

    test "a row with neither forbidden nor required, an unknown field or a bad entry", %{
      root: root,
      rules: rules
    } do
      empty =
        replace_row(rules, "searchable-observation-only", fn row ->
          row |> Map.put("forbidden", []) |> Map.put("required", [])
        end)

      assert {:error, messages} = validate(empty, root)
      assert Enum.any?(messages, &(&1 =~ "needs a non-empty forbidden or required list"))

      extra = replace_row(rules, "searchable-observation-only", &Map.put(&1, "surface", "x"))
      assert {:error, extra_messages} = validate(extra, root)
      assert Enum.any?(extra_messages, &(&1 =~ "unknown field surface"))

      bad_entry =
        replace_row(rules, "searchable-observation-only", fn row ->
          Map.put(row, "forbidden", [%{"text" => "x", "match" => "regex"}])
        end)

      assert {:error, entry_messages} = validate(bad_entry, root)
      assert Enum.any?(entry_messages, &(&1 =~ "missing case"))

      bad_regex =
        replace_row(rules, "searchable-observation-only", fn row ->
          Map.put(row, "forbidden", [%{"text" => "(", "match" => "regex", "case" => "sensitive"}])
        end)

      assert {:error, regex_messages} = validate(bad_regex, root)
      assert Enum.any?(regex_messages, &(&1 =~ "does not compile"))
    end

    test "a duplicate id, an empty not_covered list and a glob that is not a supported shape", %{
      root: root,
      rules: rules
    } do
      duplicate = Map.update!(rules, "rules", fn rows -> rows ++ [hd(rows)] end)
      assert {:error, duplicate_messages} = validate(duplicate, root)
      assert Enum.any?(duplicate_messages, &(&1 =~ "duplicate id"))

      assert {:error, uncovered_messages} = validate(Map.put(rules, "not_covered", []), root)
      assert Enum.any?(uncovered_messages, &(&1 =~ "not_covered"))

      for glob <- ["lib/*.ex", "scrypath_ops/**/lib", "*"] do
        planted =
          replace_row(rules, "searchable-observation-only", &Map.put(&1, "source_scope", [glob]))

        assert {:error, glob_messages} = validate(planted, root)
        assert Enum.any?(glob_messages, &(&1 =~ "is not ** or a literal directory"))
      end
    end

    test "a row whose source_scope matches no tracked file", %{rules: rules, paths: paths} do
      row = row!(rules, "searchable-observation-only")
      planted = Map.put(row, "source_scope", ["scrypath_ops/nowhere/**"])

      assert [%{row: "searchable-observation-only", globs: ["scrypath_ops/nowhere/**"]}] =
               CopyRules.unmatched_scopes([planted], paths)

      assert CopyRules.unmatched_scopes([row], paths) == []
    end

    test "allowed_in excuses its own phrase but not a neighbouring hit" do
      row = %{
        "id" => "sample",
        "forbidden" => [%{"text" => "beta", "match" => "literal", "case" => "sensitive"}],
        "required" => [],
        "allowed_in" => ["beta release"],
        "source_scope" => [],
        "surfaces" => ["x"]
      }

      assert [%{kind: :forbidden, text: "beta"}] =
               CopyRules.evaluate_surface(row, "x", "ship the beta release, then beta")

      assert CopyRules.evaluate_surface(row, "x", "ship the beta release") == []
      assert [%{text: "beta"}] = CopyRules.evaluate_surface(row, "x", "betamax and beta release")
    end

    test "an empty tracked-file list raises instead of passing", %{root: root} do
      assert_raise RuntimeError, ~r/yielded no scannable files/, fn ->
        CopyRules.tracked_paths(root, [""])
      end
    end
  end

  # Helpers ---------------------------------------------------------------------------------

  # Built by concatenation: this file must not spell the phrase the table forbids.
  defp not_searchable, do: "Not " <> "searchable"
  defp title_case_label, do: "Control " <> "Room"

  defp row!(rules, id), do: Enum.find(rules["rules"], &(&1["id"] == id)) || flunk("no row #{id}")

  defp replace_row(rules, id, fun) do
    Map.update!(rules, "rules", fn rows ->
      Enum.map(rows, fn
        %{"id" => ^id} = row -> fun.(row)
        row -> row
      end)
    end)
  end

  defp validate(rules, root) do
    CopyRules.validate(rules,
      glossary_terms: CopyRules.glossary_terms(root),
      status_terms: CopyRules.status_terms(root),
      surfaces: CopySurfaces.anchors()
    )
  end

  defp assert_valid(rules, root) do
    case validate(rules, root) do
      :ok -> :ok
      {:error, messages} -> flunk("copy_rules.json is invalid:\n" <> Enum.join(messages, "\n"))
    end
  end

  defp assert_no_violations([]), do: :ok

  defp assert_no_violations(violations) do
    flunk(
      "copy rules violated:\n" <> Enum.map_join(violations, "\n", &CopyRules.format_violation/1)
    )
  end

  defp temp_tree!(files) do
    root =
      Path.join(System.tmp_dir!(), "copy-rules-#{System.unique_integer([:positive])}")

    for {path, content} <- files do
      full = Path.join(root, path)
      File.mkdir_p!(Path.dirname(full))
      File.write!(full, content)
    end

    on_exit(fn -> File.rm_rf(root) end)
    root
  end
end
