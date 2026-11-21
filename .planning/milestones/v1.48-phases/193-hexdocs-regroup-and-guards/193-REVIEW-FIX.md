---
phase: 193-hexdocs-regroup-and-guards
fixed_at: 2026-11-21T14:45:00Z
review_path: .planning/phases/193-hexdocs-regroup-and-guards/193-REVIEW.md
iteration: 1
findings_in_scope: 7
fixed: 6
skipped: 0
accepted: 1
status: all_fixed
---

# Phase 193: Code Review Fix Report

**Fixed at:** 2026-11-21T14:45:00Z
**Source review:** `.planning/phases/193-hexdocs-regroup-and-guards/193-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 7 (WR-01, WR-02, WR-03, IN-01, IN-02, IN-03, IN-04)
- Fixed: 6
- Accepted as is, with the reason recorded: 1 (IN-03, as instructed)
- Skipped: 0

Worktree posture: `workflow.use_worktrees` is `false` in `.planning/config.json`, so the fixes were made and committed in the main checkout on `gsd/phase-193-hexdocs-regroup-and-guards`. No branch was switched, nothing was pushed. The four files the instructions named (`.planning/config.json`, `.planning/state.json`, `.planning/STATE.md`, `.impeccable/config.json`) were already modified before this run and were never staged. Every commit used explicit paths.

Verification ran in the main checkout (not an isolated worktree), so the numbers below are reproducible from the tree as it stands.

## Fixed Issues

### WR-01: Fence matcher can invert fence pairing, so the phrase scan silently skips prose between code blocks

**Status:** fixed: requires human verification (logic change in a scanner; planted cases and the real-file count below are the evidence)
**Files modified:** `test/support/release/snippet_parity.ex`, `test/support/release/forbidden_phrases.ex`, `test/release/forbidden_phrases_contract_test.exs`, `test/release/snippet_parity_contract_test.exs`
**Commit:** `3d8113ad`
**Applied fix:** `SnippetParity.fences/1` now pairs fences line by line as CommonMark does: any indent, three or more backticks or tildes, any info string (`html+eex`, `json5`, `elixir title="a.ex"`, `{.elixir}`), closed by the same character at least as many times; `lang` is the first word of the info string and `elixir_fences/1` compares it case-insensitively. A backtick fence whose info string holds a backtick is an inline span, not a fence. A fence that is never closed raises `ArgumentError` with the line it opened on, and `ForbiddenPhrases.mask/2` adds the file path, so a mis-paired file fails loudly instead of masking prose.
**Planted cases (all failed before the fix, pass now):**
- Prose between an `html+eex`, `json5`, `Elixir`, titled, `{.elixir}`, four-backtick, `~~~`, indented, or bare fence and a later `elixir` fence is reported (`brand-hype` at the true line); the review's probe returned `[]`.
- A phrase inside any of those fence kinds is still masked; a shorter fence line inside a longer fence is content.
- An unclosed fence raises, naming `guides/planted.md` and `line 3`.
- `SnippetParity` level: fence list with languages, bodies and offsets for mixed info strings, prose removal, unclosed-fence raise, and an inline code span at the start of a line is not a fence.
- Real-file test: every fence-looking line of README and the 26 guides (including lines after a `>` marker) belongs to a paired fence (`lines == 2 * fences` per file). All real fences are plain today, so no real result changed.

### WR-02: Phrase table scans guides listed in `extras`, not the `guides/` directory, and nothing ties the two together

**Status:** fixed
**Files modified:** `test/support/release/forbidden_phrases.ex`, `test/release/forbidden_phrases_contract_test.exs`
**Commit:** `0370cb19`
**Applied fix:** `ForbiddenPhrases.targets/1` now takes its guides from `Path.wildcard("guides/*.md")` (new `guide_paths/1`, with `root` defaulting to `.` for the planted cases). New `unlisted_guides/2` returns the guides that are not docs extras, and a real-file test asserts it is `[]` and names each offender. The tautological floor `length(targets) == 1 + guides-in-extras` now compares against the directory listing. I kept the test title "README and every guide in extras are free of forbidden phrases" because `193-02-SUMMARY.md` cites it by name; every guide is now an extra by the new test, so the title is still true.
**Planted cases:** a guide in a temporary directory under the system temp dir (not `@tag :tmp_dir`, which writes `tmp/` into the repo root) that is not in `extras` is listed by `unlisted_guides/2`, is read by `targets/1`, and its banned phrase is reported at line 3; a non-`.md` file in `guides/` is ignored. A throwaway probe (a real `guides/zz-wr02-probe.md` with "effortless", not in `extras`, removed afterwards) failed both the phrase test and the new extras test, where it passed both before.
**Note:** this commit was amended once, before the next finding was committed, to move the planted directory from `@tag :tmp_dir` to the system temp dir after I saw the tag created an untracked `tmp/` at the repo root.

### WR-03: Install-line "series" rule is the 0.x convention and would fail a correct line at every 1.x minor

**Status:** fixed: requires human verification (a version-comparison rule; the planted cases below are the evidence)
**Files modified:** `test/support/release/install_line.ex`, `test/release/install_line_contract_test.exs`, `docs/releasing.md`
**Commit:** `4870e346`
**Applied fix:** `check_numbers/3` now calls `same_series?/2`. For major 0 the rule is unchanged (same-length prefix of `[major, minor, patch]`). For major >= 1 only the first number must equal the major and `Version.match?/2` decides the rest. The module doc and the `:series_mismatch` kind doc say so. `docs/releasing.md` ("Minor version bumps and the install-line guard") said a minor bump always moves the lines; it now says that is the pre-1.0 rule and that from 1.0 a minor bump needs no edit and only a major bump moves them.
**Planted cases (the first failed before the fix):** `~> 1.0` at `1.2.3` is `:ok` (also through `problems/3`); `~> 1.0` at `1.0.5`, `~> 1.2` at `1.2.3`, `~> 1.2.3` at `1.2.3` are `:ok`; `~> 0.2` at `1.2.3` and `~> 0.3` at `1.0.0` are `:series_mismatch`; `~> 1.0` at `2.0.0` is `:series_mismatch`; `~> 1.3` and `~> 1.0.0` at `1.2.3` are `:unsatisfied`; the three existing 0.x cases are repeated and unchanged. The nine test files that read `docs/releasing.md` pass (run when that file changed: 381 tests, 0 failures).

### IN-01: Hard-coded counts and triplicated lists add friction to edits the plan calls cheap

**Status:** fixed
**Files modified:** `test/release/forbidden_phrases_contract_test.exs`, `test/release/package_metadata_test.exs`
**Commit:** `2f066db8`
**Applied fix:** the `time-promise` phrase count is `>= 10`. In `package_metadata_test.exs` the first-group literal and the group count are now read from `@sidebar_groups`. The `length(groups) == 6` was not a pure duplicate (nothing pinned `@sidebar_groups` itself to six), so the count "six" moved to one assertion, `length(@sidebar_groups) == 6`, in the test named for it, and the extras test asserts `length(groups) == length(@sidebar_groups)`. No pin was dropped. The ExDoc id pin near the built-sidebar test (`["readme", "golden-path"]`) is left as written on purpose: it pins ExDoc's real output ids, and deriving them would assume ExDoc's slug rule.
**Evidence:** with an eleventh phrase temporarily added to the table, the old `== 10` assertion failed and `>= 10` passed (file restored afterwards, no diff). Removing a phrase still fails the floor, and the no-weakening test still plants all ten.

### IN-02: Own-docs URL extraction captures trailing markup and reports a false `:not_a_page`

**Status:** fixed
**Files modified:** `test/support/release/shipped_docs.ex`, `test/release/shipped_docs_contract_test.exs`
**Commit:** `36861a3f`
**Applied fix:** the trailing-trim set is now `. , ; : ! ? * _ ~ } \`, so a link written as `*url*`, `**url**`, `_url_`, `__url__`, `~~url~~`, `{url}`, an escaped `url\"`, or followed by `?` or `!` yields the bare URL. I trimmed rather than ending the URL at `_` or `*`, because `_` is legal inside a fragment such as `Scrypath.html#sync_record/3`, and an existing test pins that form.
**Planted cases (failed before the fix):** each wrapper on a valid page URL yields exactly that URL and no problem; and trimming does not hide a bad URL: `**...0.3.20/readme.html**` is `:versioned`, `_http://...readme.html_` is `:insecure_scheme`, `*...api-reference*` is `:not_a_page`, each reported without the markup.

### IN-04: `CHANGELOG.md` is read by both new source guards and the own-docs foot-gun is not recorded

**Status:** fixed (a scope decision, made as instructed; recorded for visibility)
**Files modified:** `test/support/release/shipped_docs.ex`, `test/support/release/install_line.ex`, `test/release/shipped_docs_contract_test.exs`, `.planning/phases/193-hexdocs-regroup-and-guards/193-PIN-INVENTORY.md`
**Commit:** `740db154`
**Applied fix:** both guards read `CHANGELOG.md` through `package.files`. I excluded it from both source scans because the changelog is release-please history built from squash-commit subjects, and the remedy the review proposed (reword the PR title) does not hold: the subject is already on main when the release PR is created, and release-please regenerates the entry. The exclusion does not make either guard vacuous: the changelog holds no install tuple and no own-docs URL today (`grep -c` prints 0 for both), so no current result changes, and the non-vacuity floors are measured over the other files (install-line sources went from 140 to 139 files, own-docs sources from 133 to 132). It is one named entry, `ShippedDocs.history_files/0`, with a reason and a revisit trigger, shared by `InstallLine.sources/0` and the new `ShippedDocs.own_docs_url_sources/0`. It is separate from the locked two-entry `ShippedDocs.exempt/0` set of the TRUTH-01 command guard, which already exempts the same file for a similar reason, so the "exactly two exemptions" test is untouched.
**Tests:** the entry has a reason and a revisit trigger and still names a shipped file; `CHANGELOG.md` is the only shipped file left out of either scan; README, the golden path and `docs/releasing.md` are still in both; a planted stale tuple plus versioned URL fails under README and a guide path and is out of scope only under the changelog path. Mutation check (throwaway, reverted with `git checkout`): the same two lines appended to `CHANGELOG.md` left both guards green, appended to `guides/outside-adopter-intake.md` failed both.
**Inventory:** the old "known foot-gun, not pre-handled" note is replaced by the decision; the own-docs decisions, the file count and the series-rule text are updated. Because the review's suggested `docs/releasing.md` sentence ("a PR title that quotes an install tuple ... fails the guards") describes the non-excluded variant, I did not add it.

## Accepted as is

### IN-03: The ops copy-rules exemption removes the whole file from every `**`-scoped rule to hide two strings

**File:** `scrypath_ops/test/support/copy_rules.json:7`
**Status:** left as is, as instructed; the choice is recorded in the pin inventory as accepted
**Commit:** `6996c12b` (inventory only)
**Reason:** the exemption is path-scoped to one data file, on the same precedent as the sister table `scrypath_ops/test/support/copy_rules.json` and the `.planning/` and `brand/` entries already in `exempt_paths`; only `control-room-casing` has `source_scope: ["**"]` today. Escaping the banned name in the data file would hide it from the scan by trickery instead of by a recorded exemption. The inventory notes the prefix-match caveat and adds a revisit trigger (a second ops rule gains a `**` scope and should read the table). No `scrypath_ops` file was edited.

## Bookkeeping commit

`27270d7f` updates the pin inventory so its description of the phrase table matches the code after WR-01, WR-02 and IN-01 (fence pairing, guides-directory scope, floors). Documentation only.

## Verification

Run in the main checkout after the last commit, toolchain `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5`:

- `mix format --check-formatted`: clean.
- `MIX_ENV=test mix credo --strict` on the nine touched Elixir files: no issues.
- The doc-pin set (13 files named in plan 193-02's verification and the inventory, including `test/scrypath/docs_contract_test.exs`) plus `forbidden_phrases_contract_test.exs`, `install_line_contract_test.exs` and `snippet_parity_contract_test.exs`, with `--warnings-as-errors`: 304 tests, 0 failures. `docs_contract_test.exs` alone: 74 tests, 0 failures.
- The nine test files that read `docs/releasing.md` (including the consumer smoke test and the workflow wiring test), run right after the `docs/releasing.md` edit: 381 tests, 0 failures, 2 excluded by default tags.
- `mix docs --warnings-as-errors`: builds clean.
- Ops copy-rules test from `scrypath_ops/` (`CI=true MIX_ENV=test mix test test/scrypath_ops_web/copy_rules_contract_test.exs`, Postgres on 5432): 31 tests, 0 failures. None of the changed files spells the title-case name the ops rule forbids.

Not run, with reason: `mix verify.core`, `mix verify.package`, `mix verify.repository_contracts`, `scripts/ci/pre_push.sh`, and the Docker and browser lanes. The changes are confined to `test/support/release/*.ex`, five test files, one sentence in `docs/releasing.md` and the pin inventory; none changes `lib/`, `mix.exs` or `website/`. The hosted `website.yml` build also triggers on `docs/**`, so its `build-and-check` must be green on the exact head before the squash merge, as plan 193-02 already says. Known risk: low.

## Not changed

`193-REVIEW.md` frontmatter was not edited (its `status: issues_found` describes the review, and this report carries the fix status). This file is not committed; the orchestrator commits it.

---

_Fixed: 2026-11-21T14:45:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
