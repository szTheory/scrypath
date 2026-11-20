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
