---
phase: 193-hexdocs-regroup-and-guards
reviewed: 2026-11-21T14:24:08Z
depth: standard
files_reviewed: 19
files_reviewed_list:
  - CONTRIBUTING.md
  - README.md
  - docs/releasing.md
  - guides/overview.md
  - lib/scrypath.ex
  - mix.exs
  - scrypath_ops/test/support/copy_rules.json
  - test/release/forbidden_phrases_contract_test.exs
  - test/release/install_line_contract_test.exs
  - test/release/package_metadata_test.exs
  - test/release/shipped_docs_contract_test.exs
  - test/release/snippet_parity_contract_test.exs
  - test/scrypath/docs_contract_test.exs
  - test/scrypath/readme_contract_test.exs
  - test/support/release/forbidden_phrases.ex
  - test/support/release/forbidden_phrases.json
  - test/support/release/install_line.ex
  - test/support/release/shipped_docs.ex
  - test/support/release/snippet_parity.ex
findings:
  critical: 0
  warning: 3
  info: 4
  total: 7
  necessity: 0
status: issues_found
---

# Phase 193: Code Review Report

**Reviewed:** 2026-11-21T14:24:08Z
**Depth:** standard
**Files Reviewed:** 19
**Status:** issues_found

## Summary

Reviewed the Phase 193 source diff (`origin/main...HEAD`, `.planning/` excluded) file by file, read each support module and its contract test side by side, and compared every removed assertion against where it went. I ran the five new or rewired contract files (91 tests) and `package_metadata_test.exs` plus `docs_contract_test.exs` (109 tests): all green. I also ran throwaway probes (scratchpad scripts, no source edited) to test regexes and scanners on inputs the planted tests do not cover.

No Critical findings. The regroup, the shrunk overview and the shipped-doc claims are sound: no stale "table of contents" or "indexes every guide" claim remains, and the `CONTRIBUTING.md` sentence about the `package` lane is true (`ci.yml` runs `mix verify.package`, which runs `docs_contract_test.exs`; `core` excludes it).

Assertion accounting versus `origin/main`: nothing was dropped or weakened.
- The `Operations` verbatim pin became a sorted-membership pin on `"Operate and recover"`, and list order is pinned by `@sidebar_groups` and the extras-order test.
- The multitenancy registration test got stronger (it now reads `project()[:docs]`).
- The README `@time_promises` (10) and `@brand_do_not_say` (8) lists moved into the table. The new regexes are supersets (`effortless(ly)?`, `real[- ]?time`, `magic(al|ally)?`, `federat(ed|ion)`, `hydrat(...)`), and a test plants all 18 old phrases.
- The README parity tests now return an error instead of crashing on a missing fence, and now require a reason on any marker.

The three Warnings are guards that can pass vacuously or fail wrongly on foreseeable input, none of which occurs in the repo today. The Info items are brittleness and scope notes.

## Warnings

### WR-01: Fence matcher can invert fence pairing, so the phrase scan silently skips prose between code blocks

**File:** `test/support/release/snippet_parity.ex:20` (regex), consumed by `test/support/release/forbidden_phrases.ex:114-120` (`mask/1`) and `snippet_parity.ex:59-64` (`prose/1`)

**Issue:** `@fence` only recognises an opening fence whose info string is `[a-z]*` (nothing else on the line) and a closing fence of exactly three backticks. Any other opening line is invisible to it: `html+eex`, `json5`, `ex_unit`, `Elixir`, `elixir title="a.ex"`, or an indented fence inside a list item. When that happens the block's own closing ` ``` ` line is matched as an opening fence, and pairing is inverted for the rest of the file: prose between blocks is treated as fenced and masked (never scanned), and code is scanned as prose.

This helper used to read only the README. Phase 193 makes `ForbiddenPhrases.mask/1` apply it to 26 more files (every guide), where `html+eex` or titled fences are far more plausible (the Phoenix guides).

Failure scenario, confirmed with a probe against the real modules:
- `Search is effortless and ready in five minutes.` placed between a ` ```html+eex ` block and an ` ```elixir ` block: `ForbiddenPhrases.scan/2` returns `[]`.
- The same sentence between two plain ` ```elixir ` blocks: reported as `brand-hype`, line 7.
- An ` ```elixir title="a.ex" ` fence gives the same silent miss.

Today the guard is not wrong: every fence line in `README.md` and the 26 guides is plain, with no indentation and an even count (checked with grep). No planted case uses a non-standard fence, so nothing would catch the regression.

**Fix:** Pair fences line by line (open: up to 3 spaces of indent, 3 or more backticks or tildes, any info string; close: the same character, at least as long) and use the first word of the info string as `lang`. Or, minimally, relax the regex to `~r/^```([^\n`]*)\n(.*?)^```[ \t]*$/ms` and compare `lang` on its first word. Either way, fail loudly instead of mis-masking by asserting that the number of lines matching `^\s*(```|~~~)` equals twice the number of fences found, in `ForbiddenPhrases.mask/1` or in the real-file test. Add a planted case with an `html+eex` fence and a titled fence between two prose lines.

### WR-02: Phrase table scans guides listed in `extras`, not the `guides/` directory, and nothing ties the two together

**File:** `test/support/release/forbidden_phrases.ex:63-69` (`targets/0`), `test/support/release/forbidden_phrases.json:12` (`not_covered` states the scope as "README.md plus guides/*.md"), `test/release/forbidden_phrases_contract_test.exs:44-55`

**Issue:** `targets/0` takes guide paths from `Scrypath.MixProject.project()[:docs][:extras]`. `mix.exs` `package.files` ships the whole `guides` directory. The sidebar tests (`docs_group_problems/3`, `sidebar_group_problems/2`) are also extras-driven. I searched `test/` and `dev/` and found no test that requires every `guides/*.md` to be an extra (the only `guides/**` wildcard is in `telemetry_contract_test.exs`, for a different purpose). The floor `length(targets) == 1 + guides` (line 54) is a tautology, because both sides are computed from the same extras list.

Failure scenario: a contributor adds `guides/new-thing.md` containing "effortless" or "in five minutes" and forgets `mix.exs` `extras`. The file ships in the Hex tarball. The phrase guard stays green (the file is never scanned), the sidebar guard stays green (the file is not an extra), and HexDocs silently omits the page. That is the drift GUARD-03 exists to stop, and the table's own `not_covered` text claims `guides/*.md` as scope. The install-line and own-docs guards do read it (they use `package.files`), so coverage is inconsistent between guards.

**Fix:** Build guide targets from `Path.wildcard("guides/*.md")` and add a test that `Path.wildcard("guides/*.md") -- extras == []`, so a guide that is not an extra fails by name. Replace the tautological floor with a comparison against the directory listing.

### WR-03: Install-line "series" rule is the 0.x convention and would fail a correct line at every 1.x minor

**File:** `test/support/release/install_line.ex:105-116` (the comparison at line 112); user-facing claim at `docs/releasing.md:153`

**Issue:** `check_numbers/3` requires the requirement's integers to equal the same-length prefix of `[major, minor, patch]`. For 0.x the minor is the breaking axis, so `~> 0.3` is the right line. From 1.0.0 on, `~> 1.0` is the correct line, is satisfied by every 1.x release, and is what adopters expect. Probe results: `~> 1.0` at `1.2.3` gives `{:error, :series_mismatch}`, `~> 1.2` at `1.2.3` is `:ok`, and `~> 1.0` at `1.0.5` is `:ok`. So after the 1.0 release every minor release PR would go red on an install line that is right. The new `docs/releasing.md` subsection ("A minor bump ... leaves those lines on the old series") would then send the maintainer to edit lines that need no edit.

This is latent today (version is 0.3.20, and `release-please-config.json` keeps pre-1.0 minor bumps rare), but the trigger is a known milestone and the module doc never says the rule is pre-1.0 only.

**Fix:** Make the expected prefix depend on the major. For `major == 0` keep the current rule. For `major >= 1` require only that the first number equals the major and let `Version.match?/2` decide the rest. Add planted cases: `~> 1.0` at `1.2.3` is `:ok`, and `~> 0.3` at `1.0.0` is `:series_mismatch`. If you prefer to defer, add a comment with a revisit trigger ("revisit at the first 1.0 release") to the module doc and to the `docs/releasing.md` subsection so the failure is not misread.

## Info

### IN-01: Hard-coded counts and triplicated lists add friction to edits the plan calls cheap

**File:** `test/release/forbidden_phrases_contract_test.exs:59` and `:54`; `test/release/package_metadata_test.exs:209`, `:213-219`, `:639`

**Issue:** `assert length(time["forbidden"]) == 10` fails when an eleventh time-promise phrase is added, although CONTEXT says "table rows are edits" and the no-weakening test does not need the exact count (use `>= 10`). In `package_metadata_test.exs` the first group's five paths appear in `mix.exs`, in `@sidebar_groups`, in the `first_group == [...]` assertion and (ids) at line 639, and `length(groups) == 6` repeats what `@sidebar_groups` already pins. Adding one guide therefore needs synchronized edits in `mix.exs` (extras and group) and the test literal. The literal-equality test is a deliberate lock, so this is cost, not a bug.

**Fix:** Use `>= 10` for the phrase floor. Derive the first-group assertion and the group-count floor from `@sidebar_groups` instead of repeating the lists.

### IN-02: Own-docs URL extraction captures trailing markup and reports a false `:not_a_page`

**File:** `test/support/release/shipped_docs.ex:543-546`

**Issue:** The URL ends only at whitespace, `)`, `]`, quotes, a backtick or angle brackets, and only `. , ; :` are trimmed. Probe results: `*https://hexdocs.pm/scrypath/overview.html*` yields `.../overview.html*`, and `_..._`, `**` and `}` behave the same, so `own_docs_kind/1` returns `:not_a_page` (the `.html` is no longer the end). The "root, page, fragment and other-package forms pass" test has no emphasis or brace case. Nothing in the shipped files triggers it today, so this is a loud false positive waiting for the first emphasised link, not a missed bug.

**Fix:** Add `*`, `_`, `}` and `\` to the character class that ends a URL (or to `@own_docs_trailing`), and add one planted passing case with emphasis.

### IN-03: The ops copy-rules exemption removes the whole file from every `**`-scoped rule to hide two strings

**File:** `scrypath_ops/test/support/copy_rules.json:7` (reader: `scrypath_ops/test/support/copy_rules.ex:88`, a `String.starts_with?/2` prefix match)

**Issue:** `test/support/release/forbidden_phrases.json` is exempt from all ops copy rules, but it only needs to hide two occurrences of the title-case name (JSON lines 64 and 68). Today only `control-room-casing` has `source_scope: ["**"]`, so the practical loss is small, but any future `**`-scoped ops rule will silently skip this file. The exemption is also a prefix, so any path beginning with that string is exempt, and the change drags a `scrypath_ops` edit (and the `ops-ui` lane) into a root docs phase. The table-file precedent makes this acceptable, hence Info.

**Fix:** Write the data entry as `"Control Room"` (Jason decodes it to the same string and the file bytes no longer contain the banned name) and reword the `rule` sentence so it does not spell the name. Then drop the exemption and keep the ops scan covering the table. Keep the exemption if you prefer the explicit precedent, and record the revisit trigger as already done in the inventory.

### IN-04: `CHANGELOG.md` is read by both new source guards and the own-docs foot-gun is not recorded

**File:** `test/support/release/shipped_docs.ex:162-173` (`shipped_files/1` includes `CHANGELOG.md` through `package.files`), `:621-624`; `test/support/release/install_line.ex:69-76`

**Issue:** The changelog is built from squash-commit subjects on the bot-authored release PR. A subject that quotes a stale install tuple or a versioned `hexdocs.pm/scrypath/<version>` URL turns that release PR red. The inventory records this foot-gun for the install-line guard only. The own-docs source rule reads the same file and has no such note, and `docs/releasing.md` does not mention either.

**Fix:** Add one sentence to `docs/releasing.md` ("a PR title that quotes an install tuple or a versioned own-docs URL fails the guards on the release PR; reword the title") and extend the inventory note to cover the own-docs rule.

---

_Reviewed: 2026-11-21T14:24:08Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
