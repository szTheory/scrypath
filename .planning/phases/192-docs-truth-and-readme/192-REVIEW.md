---
phase: 192-docs-truth-and-readme
reviewed: 2026-11-21T10:30:00Z
depth: standard
files_reviewed: 12
files_reviewed_list:
  - test/support/release/shipped_docs.ex
  - test/release/shipped_docs_contract_test.exs
  - test/release/package_metadata_test.exs
  - test/scrypath/readme_contract_test.exs
  - test/scrypath/docs_contract_test.exs
  - test/scrypath/readiness_contract_test.exs
  - test/scrypath/phase98_contract_test.exs
  - test/scrypath/phase99_contract_test.exs
  - test/scrypath/phase110_contract_test.exs
  - test/scrypath/phase112_contract_test.exs
  - test/scrypath/backfill_contract_docs_test.exs
  - test/mix/tasks/dependency_boundary_contract_test.exs
findings:
  critical: 0
  warning: 6
  info: 5
  total: 11
  necessity: 1
status: issues_found
---

# Phase 192: Code Review Report

**Reviewed:** 2026-11-21T10:30:00Z
**Depth:** standard
**Files Reviewed:** 12
**Status:** issues_found

## Summary

I reviewed the shipped-docs scanner (`Scrypath.Release.ShippedDocs`), its contract test, the built-docs link scan, the README contract test and the re-pointed pins, against `192-PIN-INVENTORY.md`. Necessity rubric (`necessity-review.md`) was read and applied.

What I ran and what it showed:

- The 12 scoped test files pass (174 tests in the 10 contract files, plus 28 in `package_metadata_test.exs`, which builds the docs). `mix format --check-formatted` and `mix credo --strict` are clean on all 12 files. A full `mix test` stalled with no output for over four minutes on a test outside the scope and I killed it, so there is no full-suite claim here.
- The real-file zero assertion is not vacuous. I broke the qualifier wording in memory for every qualified unit that names a repo-only task in the real shipped corpus (outside the allowlist and exemptions); every mutation produced a violation, none went uncaught. The derived name set has 60 names, the shipped set 133 files, 263 links in docs extras.
- I compared every assertion removed from the pin files against its replacement. I found no removal that the pin inventory does not record. The weakened ones are all recorded: route-index pins reduced to docs-extras membership (accepted gap), `readiness_contract_test.exs` intake-guide README pin retired with already-existing assertions as the "replacement".

No blocker. All six warnings are latent: each is a path by which a check can pass, or stop scanning, without a failure today. Each was reproduced against the real source (probe scripts, not edits).

Out of scope, noted for the record: `lib/mix/tasks/scrypath.settings.diff.ex:124` tells adopters to run `mix scrypath.reindex`, and no task by that name exists in `lib/` or the three task trees. The invariant cannot see it (it only knows repo-only names). It is pre-existing and outside this phase's diff.

## Warnings

### WR-01: A blockquote hides the sentence boundary, so a sibling sentence qualifies a mention

**File:** `test/support/release/shipped_docs.ex:79`
**Issue:** `@sentence_boundary` requires the next sentence to start with `[A-Z0-9` + backtick, `*`, `_`, `[`, `(`, quote characters. A blockquote line starts with `>`, so `.` + newline + `> It ...` is not a boundary and the two sentences stay one unit. The module's own rule ("a sibling sentence does not count") then fails. Reproduced:

```elixir
SD.scan([{"guides/p.md", "> Run `mix verify.adopter`.\n> It runs from a source checkout and is not in the Hex package.\n"}], names)
# => []   (the same text without the "> " prefixes is reported, as the planted sibling-sentence test proves)
```

No shipped file has a blockquote today (grep of every package file), so this is latent. The `@sentence_boundary` comment says over-splitting only ever makes the check stricter; under-splitting is the direction that makes it laxer, and `>` is one way to get there.
**Fix:** Add `>` to the lookahead class and plant the case:

```elixir
@sentence_boundary ~r/([.!?][)\]"'*_]*)\s+(?=[A-Z0-9`*_\[("'“‘>])/u
```

```elixir
test "a qualifier in a sibling blockquote sentence does not qualify the mention", %{names: names} do
  text = "> Run `mix verify.adopter`.\n> It runs from a source checkout and is not in the Hex package.\n"
  assert [{@guide, 1, "verify.adopter"}] = ShippedDocs.scan([{@guide, text}], names)
end
```

### WR-02: Family and glob forms are only caught for roots that are themselves tasks

**File:** `test/support/release/shipped_docs.ex:352-353` (and `@family_template`, line 109)
**Issue:** `roots` is "names that have children", so only `verify` qualifies as a root. Reproduced against the real derived names:

- `` `mix verify.*` `` is reported (as `verify`).
- `` `mix verify.phase*` ``, `` `mix verify.phase{11,14}` `` and `` `mix scrypath_ops.*` `` return `[]` and pass unqualified.

`scrypath_ops` has children (`scrypath_ops.check_nav_contract`, `scrypath_ops.saved_searches.validate`) but is not a task, and `verify.phase` is a prefix, not a name. The module comment lists "family forms for every name that has children" as the coverage; that is narrower than an adopter-facing "run the `verify.phase*` gates" sentence. Currently only `mix verify.*` appears in shipped docs (`guides/support-and-compatibility.md:125`, qualified), so nothing is hidden today.
**Fix:** Compute roots from every dotted prefix of a repo-only name that is not also a prefix of a shipped task name (so `scrypath_ops` and `verify.phoenix_example` count, `scrypath` does not because `scrypath.status` ships), and add a tail form for a prefix followed by `*` or `{`. `scan/2` would need the shipped names, or `repo_only_tasks/0` could return the roots alongside the names. Plant `mix verify.phase*` and `mix scrypath_ops.*` cases in `shipped_docs_contract_test.exs`.

### WR-03: The task-tree globs are hand-listed and only two of three are guarded against going empty

**File:** `test/release/shipped_docs_contract_test.exs:36-41`, `test/support/release/shipped_docs.ex:31-35`
**Issue:** The derivation test asserts one name from `dev/mix/tasks` (`verify.adopter`) and one from `scrypath_ops` (`scrypath_ops.saved_searches.validate`). Nothing asserts a name from `examples/*/lib/mix/tasks/**` (`e2e.prepare_search`, `scrypath.demo.seed`, `scrypath.seed` are the three it contributes today). If that glob stopped matching, the set drops from 60 to 57, which clears the `>= 50` floor, and a shipped doc telling adopters to run `mix scrypath.seed` would pass. Separately, the three roots are the only place task trees are named; a new `defmodule Mix.Tasks.*` tree elsewhere (for example a second example app, or `scrypath_ops/dev/mix/tasks`) is invisible. Today the repo has no such tree (grep for `defmodule Mix.Tasks` outside `lib/`, `deps/`, `_build/` and `test/` finds exactly the three globs' directories), so this is latent.
**Fix:** Assert one name per glob, and add a coverage test that finds task definitions outside the globs:

```elixir
assert "scrypath.seed" in names
assert "e2e.prepare_search" in names
```

For coverage, walk the repository for files containing `defmodule Mix.Tasks.` (excluding `deps/`, `_build/`, `node_modules/`, `test/` and `lib/`) and assert each path matches one of `@task_source_globs`.

### WR-04: A text file that is unreadable or not valid UTF-8 silently drops out of the scanned set

**File:** `test/support/release/shipped_docs.ex:155-164`
**Issue:** `text_file?/1` ends with `valid_utf8?/1`, and `valid_utf8?/1` returns `false` for an invalid-UTF-8 file and for any `File.read` error. A `.md`, `.ex` or `.exs` file in the package that is mis-encoded or unreadable is excluded from `shipped_files/0` with no failure, so it is never scanned for repo-only tasks; the `>= 100` floor does not notice one missing file. The stated reason (`lib/.DS_Store` and local binaries are not text) is already handled by the extension filter: `Path.extname("lib/.DS_Store")` is `""` (verified), and both `.DS_Store` files in the package dirs are excluded by `@text_exts`. So the clause adds only the silent-skip path.
**Fix:** Delete `valid_utf8?/1` and let `File.read!/1` in `violations/0` raise, or keep it but fail loudly:

```elixir
defp text_file?(file) do
  File.regular?(file) and Path.extname(file) in @text_exts and
    (valid_utf8?(file) or raise "#{file} is in the package but is not valid UTF-8; scan it or exclude it explicitly")
end
```

### WR-05: The built-docs link scan has a floor of one href and a two-page slack on page count

**File:** `test/release/package_metadata_test.exs:307, 312`
**Issue:** `assert hrefs > 0` is the only guard that the author-region regex still reads real ExDoc markup (the planted-case test inserts its own `<a href>`, so it proves the regex works on a planted tag, not on ExDoc's output). On the current build the scan reads 1360 hrefs in 35 pages (280 external, 304 fragment-only); a markup change that left one match would pass. The source-side link test is calibrated at `> 50` of 263. `length(pages) >= length(extras)` has slack of two because `404.html` and `api-reference.html` also carry `data-type="extras"` (35 pages for 33 extras), so two real extras pages missing from the build would still pass.
**Fix:** Scale the floor to the content and check each configured extra by name:

```elixir
assert hrefs > 500, "the href scan went vacuous: #{hrefs} hrefs"

for extra <- MixProject.project()[:docs][:extras] do
  id = extra |> Path.basename(".md") |> String.downcase()
  assert "#{id}.html" in pages, "no built page for #{extra}"
end
```

### WR-06: Absolute HexDocs links are never checked for a dead anchor, and the README now uses only absolute links

**File:** `test/release/package_metadata_test.exs:244` (`@external_href`), `test/scrypath/readme_contract_test.exs:399`
**Issue:** `@external_href` skips every `https?:` href, so the built-docs scan cannot see `https://hexdocs.pm/scrypath/...` links. The README test that does read them (`HexDocs links target an existing extra or module page`) matches `...\.html(?:[#?].*)?$` and discards the fragment. After the trim every README link is absolute, so the built-docs anchor scan covers none of the README's own links, and `README.md:98` (`Scrypath.html#sync_record/3`, also `guides/sync-modes-and-visibility.md:17`) is the one fragment link in that class. The anchor exists today (`id="sync_record/3"` in the built `Scrypath.html`); a rename of the function would leave a dead link no check reports. `docs_contract_test.exs` pins only the URL string.
**Fix:** In the built-docs scan, map `https://hexdocs.pm/scrypath/<page>.html#<frag>` to `out/<page>.html` and run the existing anchor check on it; the version-skew caveat in the inventory still applies, but a local-build check is strictly better than none. Cheaper alternative in `readme_contract_test.exs`: for a `Scrypath.html#name/arity` fragment, assert `function_exported?(Scrypath, String.to_atom(name), arity)`.

## Info

### IN-01: Module pages are excluded from the built-docs scan as a whole, not only for self-links

**File:** `test/release/package_metadata_test.exs:245-250` (`@extras_region`)
**Issue:** The comment excludes `data-type="modules"` pages because they legitimately link to themselves. Only the `:self_link` kind needs that exemption. The 34 module pages carry 813 internal hrefs (for example the many `guides/*.md` links in `lib/scrypath.ex`) that no test reads for unresolved targets or dead anchors. I ran the same scan over them on a fresh build: 0 problems today.
**Fix:** Scan the modules region too and drop `:self_link` results for module pages.

### IN-02: README repo-path link test drops pathless links, and two floors equal the current count

**File:** `test/scrypath/readme_contract_test.exs:378, 381, 112`
**Issue:** `[_all, _kind, ref, path | _fragment] <- [Regex.run(@repo_path_link, target)]` needs four elements, but `Regex.run` drops trailing unmatched groups, so `https://github.com/szTheory/scrypath/tree/v0.3.17` returns three and is skipped (verified), bypassing both the `main` and the exists check. The copy in `shipped_docs_contract_test.exs:447` destructures `[kind, ref | rest]` and handles it. Impact is nil today because README is a docs extra and the plan-03 source rule covers it, but the two copies of the regex are already out of step. Also `length(repo_links) >= 2` equals the README's two repo links (LICENSE badge, CHANGELOG) and `length(rows) >= 30` is one under the 31 owner-map rows, so a legitimate edit fails with a misleading "went vacuous" message.
**Fix:** Expose one `@repo_path_link` and one destructuring in `ShippedDocs`; lower those two floors to a count that distinguishes "empty" from "one fewer".

### IN-03: The "units naming verify.adopter" filter is copied four times with different name lists

**File:** `test/scrypath/readiness_contract_test.exs:88`, `test/scrypath/phase98_contract_test.exs:68`, `test/scrypath/phase99_contract_test.exs:285`, `test/release/shipped_docs_contract_test.exs:138`
**Issue:** `assert_qualified_adopter_mention/2` is the same body in three files and passes `["verify.adopter"]` to `mentions/2`; `adopter_units/2` passes the full derived names. They can diverge in what counts as a mention (the three copies would not see a family form).
**Fix:** One `ShippedDocs.units_mentioning(text, name)` helper (and one assertion helper) next to `unit_qualified?/1`.

### IN-04: Necessity: allow-list entry for a host no README markdown link uses

**File:** `test/scrypath/readme_contract_test.exs:56`
**Category:** necessity
**Issue:** `raw.githubusercontent.com/szTheory/scrypath` in `@allowed_hosts` matches none of the README's 16 markdown links (probe of `ShippedDocs.markdown_links/1` on `README.md`); the only raw URLs are the header `srcset`/`src` HTML attributes, which `markdown_links/1` never sees (`shipped_docs.ex:448-451`) and the brand test pins separately. The entry only widens what a future README link may target. Info because a future raw link is plausible.
**Fix:** Remove the entry, or add it when a README link needs it.

### IN-05: `qualifier_patterns/0` has no caller

**File:** `test/support/release/shipped_docs.ex:172-173`
**Issue:** The public accessor and its `@spec` are unused anywhere in `test/`, `dev/` or `lib/` (grep); `qualified?/1` reads the attribute directly.
**Fix:** Delete it.

---

_Reviewed: 2026-11-21T10:30:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
