---
phase: 192-docs-truth-and-readme
fixed_at: 2026-11-21T10:54:21Z
review_path: .planning/phases/192-docs-truth-and-readme/192-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 6
skipped: 0
status: all_fixed
---

# Phase 192: Code Review Fix Report

**Fixed at:** 2026-11-21T10:54:21Z
**Source review:** .planning/phases/192-docs-truth-and-readme/192-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 6 (WR-01 to WR-06; Info findings IN-01 to IN-05 are out of the `critical_warning` scope and were not touched)
- Fixed: 6
- Skipped: 0

**Where the fixes ran:** the main checkout on `gsd/phase-192-docs-truth-and-readme`, not an isolated worktree. The orchestrator's instructions named this checkout and asked for explicit-path staging so the maintainer's local `.planning/config.json` and `.planning/state.json` edits stay unstaged; a hand-rolled worktree also has no `deps/` or `_build/` for `mix`. No temp branch, sentinel or cleanup tail was involved. Nothing was pushed.

**How each fix was checked:** every commit ran `mix format`, `mix credo --strict` on the touched files, the touched test file, and then the whole doc-pin set (`test/release` plus the readme, docs, readiness, phase 98, 99, 110, 112 and backfill contract tests): 217 tests, 0 failures, 2 excluded, on the last run. Each tightened check also has a mutation proof: the file was copied aside, mutated so the new behaviour was off, the test was run and failed, then the file was copied back and compared byte for byte. The tree has no leftover edits apart from the maintainer's two `.planning` files.

## Fixed Issues

### WR-01: A blockquote hides the sentence boundary, so a sibling sentence qualifies a mention

**Files modified:** `test/support/release/shipped_docs.ex`, `test/release/shipped_docs_contract_test.exs`
**Commit:** d22e4980
**Applied fix:** Added `>` to the lookahead class of `@sentence_boundary`, so a quoted line after a sentence end is its own sentence. Planted case: `> Run \`mix verify.adopter\`.` followed by a `> It runs from a source checkout ...` line is reported; the one-sentence blockquote with the qualifier passes. Mutation proof: removing `>` makes the planted case fail.

### WR-02: Family and glob forms are only caught for roots that are themselves tasks

**Files modified:** `test/support/release/shipped_docs.ex`, `test/release/shipped_docs_contract_test.exs`, `test/scrypath/readme_contract_test.exs`
**Commit:** 1111f163
**Status:** fixed: requires human verification (new matching rule; the exclusion of shipped families is a judgment call)
**Applied fix:** Replaced the roots-with-children family rule by one glob rule. The literal prefix before a `*` or `{` (after `mix ` anywhere, or after a backtick when the prefix is dotted) is a mention of that prefix when some repo-only name starts with it and no shipped task name does. The report names the prefix without its trailing dot (`verify`, `verify.phase`, `scrypath_ops`), so the existing `mix verify.*` expectation still holds. A `*` followed by another `*` (a bold closer) is not a glob.

The shipped-name exclusion is what keeps `mix scrypath.*` quiet: it appears in `docs/operator-support.md`, `docs/jtbd-gap-map.md` and `CONTRIBUTING.md` and names the shipped operator tasks, while `scrypath.demo.seed` and `scrypath.seed` are repo-only. To carry that, `scan/2` and `mentions/2` gained an optional third argument (the shipped task names, default none, which is the stricter reading), `shipped_tasks/0` is new and `repo_only_tasks/0` reuses it, and `violations/0`, the README scan test and the real-file `mix.exs` assertion pass it.

Planted cases: `mix verify.phase*`, backticked `verify.phase*`, `mix verify.phase{11,14}`, `mix verify.{all,core}`, `mix verify*`, `mix scrypath_ops.*` and backticked `scrypath_ops.*` are reported; the same glob with the qualifier passes; `mix scrypath.*`, `mix scrypath.{status,failed}`, a glob with no matching prefix and a bold `**mix scrypath_ops**` are not mentions; without the shipped names `mix scrypath.*` is reported. The real shipped files stay at zero violations with no edits to any shipped file. Mutation proofs: dropping the shipped exclusion fails the planted case and the real-file zero assertion (3 real mentions appear); dropping `{`, the bold guard, or the backtick branch each fails its planted case.

### WR-03: The task-tree globs are hand-listed and only two of three are guarded against going empty

**Files modified:** `test/support/release/shipped_docs.ex`, `test/release/shipped_docs_contract_test.exs`
**Commit:** bd09014e
**Applied fix:** The derivation test now asserts one name per glob (`verify.adopter` and `brand.update` from `dev/mix/tasks`, `scrypath_ops.saved_searches.validate`, and `scrypath.seed` and `e2e.prepare_search` from the examples glob), each with a message naming the glob. A new test runs `git grep -lF --untracked "defmodule Mix.Tasks."` over `*.ex` and `*.exs` and fails when a file outside `lib/` and `test/` is not one the derivation reads (`ShippedDocs.task_source_files/0` is the new accessor). `git grep` honours `.gitignore`, so `deps/`, `_build/` and `node_modules/` are out without a hand list. An in-memory case proves the helper reports an unread tree and ignores read ones, `lib/` and `test/`. Mutation proofs: dropping the examples glob, dropping the `scrypath_ops` glob, breaking the helper, and planting an untracked `zz_probe192/mix/tasks/zz.probe.ex` (removed afterwards) each fail the matching test.

### WR-04: A text file that is unreadable or not valid UTF-8 silently drops out of the scanned set

**Files modified:** `test/support/release/shipped_docs.ex`, `test/release/shipped_docs_contract_test.exs`
**Commit:** 0dece578
**Applied fix:** `text_file?/1` now decides by regular file plus extension only. `shipped_files/0` reads every selected file after expansion and raises `"<file> is in the package but is not valid UTF-8; scan it or exclude it explicitly"` (an unreadable file raises from `File.read!`). No real shipped file needed the old exclusion: the set is 133 files before and after. `shipped_files/1` takes optional entries for the planted case, which builds a temp directory with a good `.md`, a `.DS_Store` of bad bytes (still excluded by extension) and a `bad.md` (raises). Mutation proof: making the check return true without raising fails the planted case. No unreadable-file (permission) case was planted, because `chmod` does not stop a root-run CI job from reading and the test would then fail for the wrong reason.

### WR-05: The built-docs link scan has a floor of one href and a two-page slack on page count

**Files modified:** `test/release/package_metadata_test.exs`
**Commit:** ae0a9e74
**Applied fix:** The href floor is now `@min_author_hrefs 500` (1,360 on the real build). The page-count assertion is replaced by `missing_extra_pages/2`, which asserts each configured extra has a built page named after its lowercased base name; the real build has all 33. An in-memory case shows a missing `docs/releasing.md` is reported even when `404.html` and `api-reference.html` pad the page count. Mutation proofs: a floor of 5000 fails with the measured count in the message; breaking the page-name derivation fails the real and the planted test; adding an unbuilt extra to the list fails with that extra named.

### WR-06: Absolute HexDocs links are never checked for a dead anchor

**Files modified:** `test/release/package_metadata_test.exs`
**Commit:** 91fd2b9d
**Status:** fixed: requires human verification (version-skew caveat below)
**Applied fix:** Feasible without network, so it was done rather than skipped. The built-docs scan now reads an unversioned `https://hexdocs.pm/scrypath/<page>.html[#fragment]` href (`@own_docs_href`) as the page of that name in the local build and runs the existing page and anchor check on it; other https links and other HexDocs projects stay unchecked. Planted cases cover a dead anchor, an unbuilt page, a real anchor, a plain page, an absolute self-link and another project's link. A non-vacuity floor asserts at least 4 own-docs links are read (7 on the build, 2 with a fragment, on 2 pages). Mutation proofs: treating own-docs links as external fails the planted case; renaming the `Scrypath.html#sync_record/3` fragment in the scanned HTML reports 10 dead anchors including `readme.html` and `sync-modes-and-visibility.html` through their absolute links.

Limitations worth knowing: HexDocs serves the last published version, so the local build holds the link to the pages about to be published (a fragment added since the last release passes here and is dead on HexDocs only until the release). GitHub `blob/main` links with a markdown fragment were already checked against heading slugs by the source-side rule in `shipped_docs_contract_test.exs`, so no change was needed there; a GitHub link to a non-markdown file with a `#L10` style fragment is still not checked. A versioned HexDocs URL (`/scrypath/0.3.17/...`) is left unchecked on purpose.

## Skipped Issues

None.

---

_Fixed: 2026-11-21T10:54:21Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
