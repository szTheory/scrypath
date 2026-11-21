---
phase: 192-docs-truth-and-readme
verified: 2026-11-21T11:02:38Z
status: passed
score: 5/5 must-haves verified
covered_files:
  - ".planning/phases/192-docs-truth-and-readme/192-01-PLAN.md"
  - ".planning/phases/192-docs-truth-and-readme/192-01-SUMMARY.md"
  - ".planning/phases/192-docs-truth-and-readme/192-02-PLAN.md"
  - ".planning/phases/192-docs-truth-and-readme/192-02-SUMMARY.md"
  - ".planning/phases/192-docs-truth-and-readme/192-03-PLAN.md"
  - ".planning/phases/192-docs-truth-and-readme/192-03-SUMMARY.md"
  - ".planning/phases/192-docs-truth-and-readme/192-04-PLAN.md"
  - ".planning/phases/192-docs-truth-and-readme/192-04-SUMMARY.md"
  - "CONTRIBUTING.md"
  - "README.md"
  - "docs/jtbd-gap-map.md"
  - "docs/local-demo-docker-dx.md"
  - "docs/operator-support.md"
  - "docs/search-backend-sre.md"
  - "guides/drift-recovery.md"
  - "guides/faceted-search-with-phoenix-liveview.md"
  - "guides/golden-path.md"
  - "guides/operator-mix-tasks.md"
  - "guides/outside-adopter-intake.md"
  - "guides/overview.md"
  - "guides/request-edge-search.md"
  - "guides/support-and-compatibility.md"
  - "test/mix/tasks/dependency_boundary_contract_test.exs"
  - "test/release/package_metadata_test.exs"
  - "test/release/shipped_docs_contract_test.exs"
  - "test/scrypath/backfill_contract_docs_test.exs"
  - "test/scrypath/docs_contract_test.exs"
  - "test/scrypath/phase110_contract_test.exs"
  - "test/scrypath/phase112_contract_test.exs"
  - "test/scrypath/phase98_contract_test.exs"
  - "test/scrypath/phase99_contract_test.exs"
  - "test/scrypath/readiness_contract_test.exs"
  - "test/scrypath/readme_contract_test.exs"
  - "test/support/release/shipped_docs.ex"
covered_digest: "v4:sha256:d7c4ff190a76ea8a79651a28d088a575a63d28b56d759307c9c8b40241e73f2d"
behavior_unverified: 0
overrides_applied: 0
re_verification: false
---

# Phase 192: Docs truth and README Verification Report

**Phase Goal:** No Hex-shipped doc instructs an adopter to run a repo-only task, the contract text and the check agree, and the README (the GitHub front page, hex.pm page and HexDocs landing page) does one job and its links resolve.
**Verified:** 2026-11-21T11:02:38Z
**Status:** passed
**Re-verification:** No, initial verification
**Branch / head:** `gsd/phase-192-docs-truth-and-readme` at `8fd40d67` (phase base `1d7573e5`, 24 commits, nothing pushed)

Every ROADMAP success criterion was confirmed by an executable check that I ran in this session against the real tree, not by reading the plan or summary claims. Nothing is left for human verification.

## Goal Achievement

### Observable Truths (the 5 ROADMAP success criteria)

| # | Truth | Status | Evidence (what I ran) |
|---|-------|--------|-----------------------|
| 1 | The invariant fails on a planted unqualified `mix verify.adopter` line in a shipped guide, passes on a planted source-checkout-qualified line, and derives the repo-only task list from `dev/mix/tasks/`, not a hand-kept list | VERIFIED | `mix test test/release/shipped_docs_contract_test.exs`: 49 tests with `readme_contract_test.exs`, 0 failures. I probed `Scrypath.Release.ShippedDocs` directly: unqualified line gives `[{"guides/x.md",1,"verify.adopter"}]`; qualified line gives `[]`; sibling-sentence qualifier, blockquote sibling, qualifier-only-in-heading, unqualified list item and table row are all reported; allowlisted `CONTRIBUTING.md` passes; prose "verify" passes; `mix verify` and `mix verify.phase*` and `mix scrypath_ops.*` globs are reported; shipped `mix scrypath.*` passes. The name list is derived: `repo_only_tasks/0` returns 60 names from `dev/mix/tasks/**`, `scrypath_ops/lib/mix/tasks/**` and `examples/*/lib/mix/tasks/**` minus the 8 `lib/` tasks (no literal task list in `test/support/release/shipped_docs.ex`). Real shipped set (133 files) has `violations() == []`. In-memory mutation of the real files (qualifier wording removed) produced 26 violations across 7 files, so the zero is not vacuous. Scratch-overlay mutation: appending an unqualified `mix verify.adopter` to `guides/golden-path.md` failed the real-file test with `guides/golden-path.md:172 verify.adopter`. |
| 2 | Every previous assertion that pinned `verify.adopter` or shipped-docs wording is in the phase inventory (claim or wiring, where the intent lives now); none deleted without a stronger replacement; the `PROJECT.md` Canonical Adopter Contract text changed in the same commit | VERIFIED | I diffed `1d7573e5..HEAD` for removed assertion lines in `docs_contract_test`, `readiness_contract_test`, `phase98/99/110/112`, `backfill_contract_docs_test` and `dependency_boundary_contract_test`; every removed line maps to a row in `192-PIN-INVENTORY.md` (Table B rows B1 to B13, Table C README ledger, C2 owner moves, Fate log). Verify.adopter guide pins were rewritten to a stronger "mention exists and every mention is qualified" assertion; README task demands were replaced by the invariant; CONTRIBUTING halves are unchanged. `git show --stat 4b45ccbc` shows `.planning/PROJECT.md`, `test/release/shipped_docs_contract_test.exs`, and the `readiness`/`phase98`/`phase99` pin rewrites in one commit; it is the only commit that touched `PROJECT.md`. A contract-agreement test ("states the same rule the invariant enforces") reads the contract section and fails if it names `verify.adopter` without the qualifier, omits the allowlist/exemptions or the enforcing test, or keeps the stale "0.3.17 still contains" claim. Spot check at 5 intermediate commits (`4b45ccbc`, `790cee11`, `722a6ee8`, `29ff8916`, `f4d5a2c6`) via clean `git archive` overlays: the 12 to 13 doc-pin files were green at each, the only failure being the header-pin test that needs a `.git` directory the overlay lacks (it passes in the real tree). |
| 3 | The built docs have no self-link and no unresolved extras link (scan with a planted failing case), and the README header pin test is green | VERIFIED | `mix test test/release/package_metadata_test.exs`: 29 tests, 0 failures, including "extras pages have no self-link, unresolved link or dead anchor", the planted self-link / unresolved / dead-anchor test (plus own-docs HexDocs absolute links), and "README.md header uses commit-pinned raw URLs whose bytes match the committed files". I built the docs myself (`MIX_ENV=test mix docs --warnings-as-errors`, clean) and scanned all 35 extras pages and all 34 module pages with an independent Python script (relative, same-page and unversioned `hexdocs.pm/scrypath` links; file and anchor existence): 0 problems. Scratch-overlay mutations: a `[README](README.md)` appended to the real README failed with `readme.html -> readme.html (:self_link)`; a guide link `../README.md#no-such-heading` failed with `golden-path.html -> readme.html#no-such-heading (:dead_anchor)`; a relative `../examples/phoenix_meilisearch/README.md` guide link (the old basename-collision case) failed the source-level link rule. |
| 4 | README within the recorded word cap, at most three onward links after the quick path, no "Choose a route", Meilisearch prerequisite and eventual consistency before the first code block, quick path ends in a `Scrypath.search/3` result, a test fails any time-promise phrase | VERIFIED | Independent measurements of `README.md`: 603 words raw, 590 without the header block (cap 800, floor 400, recorded in the owner map as chosen not measured; the old README was 1,479); 10 fence lines (cap 60); zero relative links; zero `mix verify` strings; zero hits for the time-promise list and "Choose a route"; header lines 1 to 7 intact (2 `src`/`srcset` attributes only). Prerequisite (line 12, "needs a running Meilisearch server") and "eventually consistent" appear before the first fence (line 42) and again before the quick path's first fence (line 60). Last quick-path fence is `{:ok, result} = Scrypath.search(MyApp.Blog.Post, "ecto", page: [size: 10])` then `result.records`; `Scrypath.search/3` exists (`@spec search(module(), String.t(), keyword())`, `lib/scrypath.ex:258`) and the README config shape `config :scrypath, :defaults` is the one `Scrypath.Config.resolve!/1` reads (`lib/scrypath/config.ex:13`). Exactly 3 links follow the last code block (golden path, support, overview). Scratch-overlay mutations of a copy of the README, each caught by the intended test: "in five minutes" (time-promise test), a 4th onward link (link-cap test), 400 filler words (990 words > 800), a re-added `## Choose a route` (shape test), an unqualified `mix verify.adopter` (repo-only-task test), the eventual-consistency sentences removed (quick-path test), a relative `guides/overview.md` link (absolute-link test). Control run: 20 tests, 0 failures. |
| 5 | The owner map note exists and names one owning surface for each claim | VERIFIED | `.planning/reference/CLAIM-OWNER-MAP.md` exists (65 lines, 31 claim rows). My parse: every `Owner` cell is exactly one of `README`, `guide:<slug>`, `doc:<path>` or `retired` (none bad); all seven claims the CONTEXT names have one owner each (`what-it-is`, `fit`, `non-fit`, `install-line`, `operator-ui-status` = README; `sync-modes` = `guide:sync-modes-and-visibility`; `support-policy` = `guide:support-and-compatibility`); every "Pinned by" token is a literal substring of its named file today (0 missing). The default test run enforces the same ("the claim owner map names exactly one owning surface for each required claim", "every owner-map Pinned-by token is present in its named file"). The README budget (800 / 600 to 800 / 400 / 60 / 3) is recorded there as chosen, not measured, and the word-cap test compares it to the constants. |

**Score:** 5/5 truths verified (0 present-but-behavior-unverified).

### Plan-level must-haves (spot-checked beyond the ROADMAP contract)

| Plan truth | Status | Evidence |
|-----------|--------|----------|
| Scanner reads every file expanded from `mix.exs` `package.files`; exactly two named exemptions (`CHANGELOG.md`, `mix.exs` registration lines) with reason and revisit trigger | VERIFIED | `test/support/release/shipped_docs.ex` `@exempt`; 133 shipped files expanded; tests "allowlisted and exempt paths are in package files and the exempt set has exactly two entries" and "each exemption records a reason and a revisit trigger" pass |
| Qualifier unit is the sentence (or list item or table row; fence or table only via the sentence directly above); a sibling sentence does not qualify | VERIFIED | Probes above (sibling sentence, blockquote sibling, heading-only qualifier all reported) |
| README and golden-path config snippets use the shape `Scrypath.Config` reads | VERIFIED | `lib/scrypath/config.ex:13` reads `Application.get_env(:scrypath, :defaults, [])`; `guides/golden-path.md` diff replaces the unread `config :my_app, :scrypath`; `readme_contract_test` evaluates both snippets through `Scrypath.Options.validate_runtime_options!/1` |
| README schema snippet identical to the golden path's | VERIFIED | test "the quick path schema snippet is identical to the golden path" passes |
| The 16 wrong-target repo-path links, 3 unresolved links and 2 dead anchors fixed at the source | VERIFIED | `git diff` shows absolute `https://github.com/szTheory/scrypath/blob/main/...` URLs in `CONTRIBUTING.md`, guides and docs; my built-docs scan finds 0 problems; source link-rule test passes |

### Deferred Items

None. Nothing identified as a gap maps to a later phase.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `test/support/release/shipped_docs.ex` | `Scrypath.Release.ShippedDocs`: derivation, expansion, sentence-level unit splitter, qualifier data, `scan/3`, `violations/0`, link helpers | VERIFIED | 574 lines, derives names via `PackageContract.collect_task_modules/1`, no literal task names; used by 5 test files |
| `test/release/shipped_docs_contract_test.exs` | Invariant, planted cases, contract agreement, link rule | VERIFIED | 631 lines, 30 tests, passing |
| `test/release/package_metadata_test.exs` (`BuiltDocsBrandTest`) | Built-docs link scan inside the one existing docs build | VERIFIED | +219 lines, 29 tests passing, floors `@min_author_hrefs 500` and per-extra page-name check |
| `test/scrypath/readme_contract_test.exs` | README-01/02 and owner-map shape tests | VERIFIED | 647 lines, 20 tests passing; mutation-sensitive (7 of 7 mutations caught) |
| `README.md` | Trimmed landing page | VERIFIED | 590 words, five H2 sections, header lines 1 to 7 byte-identical |
| `guides/golden-path.md` | Config snippet in the shape `Scrypath.Config` reads; search result keys | VERIFIED | Diff reviewed |
| `guides/drift-recovery.md` | Receives the moved README drift/backfill/reindex claims | VERIFIED | +44 lines; owner-map pins pass |
| `.planning/reference/CLAIM-OWNER-MAP.md` | One owner per claim | VERIFIED | See truth 5 |
| `.planning/phases/192-docs-truth-and-readme/192-PIN-INVENTORY.md` | Tables A to D, mention inventory, fate log | VERIFIED | 334 lines; sections confirmed |
| `.planning/PROJECT.md` | Canonical Adopter Contract rewritten | VERIFIED | `4b45ccbc` |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `shipped_docs.ex` | `package_contract.ex` | `PackageContract.collect_task_modules/1` | WIRED | `task_names/1` |
| `shipped_docs.ex` | `mix.exs` | `Scrypath.MixProject.project()[:package][:files]` | WIRED | `shipped_files/1` default |
| `shipped_docs_contract_test.exs` | `.planning/PROJECT.md` | contract-section extraction plus `unit_qualified?/1`, `allowlist/0`, `exempt/0` | WIRED | "states the same rule the invariant enforces" |
| `readiness`, `phase98`, `phase99` pin tests | `ShippedDocs` | `units/1`, `mentions/2`, `unit_qualified?/1`, `links_to_guide?/2` | WIRED | Pin rewrites call the shared helpers |
| `readme_contract_test.exs` | `guides/golden-path.md` | schema fence equality, config fence evaluation | WIRED | Passing |
| `readme_contract_test.exs` | `lib/scrypath/options.ex` | `validate_runtime_options!/1`, `validate_search_page/1` | WIRED | Passing |
| `readme_contract_test.exs` | owner map | `@word_cap` equals recorded cap; table parse | WIRED | Passing |
| `package_metadata_test.exs` | `mix.exs` | docs extras list as the floor for scanned pages | WIRED | `missing_extra_pages/2` |

### Data-Flow Trace (Level 4)

Not applicable in the usual sense: the phase ships documentation and tests, no rendered dynamic data. The equivalent trace is that each test reads the real file or the real docs build, not a fixture: the invariant reads `Scrypath.MixProject.project()[:package][:files]` and the task source trees; the link scan reads the `mix docs` output built in `setup_all`; the README tests read `README.md`, `guides/golden-path.md` and the owner map. The invariant's non-vacuity floors (name count, shipped file count, href count, own-docs link count) are asserted in the tests.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Invariant and README tests | `mix test test/release/shipped_docs_contract_test.exs test/scrypath/readme_contract_test.exs` | 49 tests, 0 failures | PASS |
| Doc-pin set (docs, readiness, 98, 99, 110, 112, backfill, telemetry x2, dependency boundary, readme, shipped docs) | `mix test` over those 12 files | 213 tests, 0 failures | PASS |
| Built-docs scan and header pin | `mix test test/release/package_metadata_test.exs` (one docs build, run alone) | 29 tests, 0 failures | PASS |
| Docs build | `MIX_ENV=test mix docs --output <scratch> --warnings-as-errors` | clean | PASS |
| Independent built-docs link scan (all pages) | Python scan of the scratch build | 0 problems on 35 extras and 34 module pages | PASS |
| Formatting | `mix format --check-formatted` on the 12 changed test files | clean | PASS |
| Scanner derivation and planted cases | direct `ShippedDocs` probes (see truth 1) | as expected | PASS |
| README mutations (7) and invariant/built-docs mutations (4), in scratch overlays | copy-aside README and guides, `mix test` | each caught by the intended test; overlay controls differ only by the two git-dependent tests (no `.git` in the overlay; both pass in the real tree) | PASS |
| Informational live check of the README's absolute links | `curl` GET of each URL (fragments stripped) | HexDocs (5 pages and root), GitHub CHANGELOG and LICENSE, hex.pm package, website: all HTTP 200 | PASS (informational; not a must-have) |

### Probe Execution

No `probe-*.sh` scripts are declared by the phase plans or exist under `scripts/*/tests/`. Skipped.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| TRUTH-01 | 192-01, 192-02 | No `package.files` file tells an adopter to run a repo-only task; derived invariant with planted cases; pin inventory | SATISFIED | Truths 1 and 2 |
| TRUTH-02 | 192-02 | `PROJECT.md` Canonical Adopter Contract and the invariant agree, same commit | SATISFIED | Truth 2; commit `4b45ccbc`; agreement test |
| TRUTH-03 | 192-03, 192-04 | README links resolve; built docs scanned for self-links and unresolved links with a planted case; header pin green | SATISFIED | Truth 3 |
| README-01 | 192-04 | One job, word cap, at most three onward links, absolute URLs, no unqualified `mix verify.*`, route block gone | SATISFIED | Truth 4 |
| README-02 | 192-04 | Quick path ends in `Scrypath.search/3` result, prerequisite and eventual consistency first, no time promises, schema parity | SATISFIED | Truth 4 |
| README-03 | 192-02 | Owner map note, one owner per claim | SATISFIED | Truth 5 |

All six IDs appear in PLAN frontmatter (`requirements:` across plans 01 to 04, and `requirements-completed` in the four SUMMARYs) and in REQUIREMENTS.md; `grep "Phase 192"` finds no other requirement mapped to this phase, so there are no orphaned requirements.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (none) | - | `TBD`, `FIXME`, `XXX` scan over all 26 non-planning files the phase modified, whole file and added lines | - | None; `TODO`/`HACK`/`PLACEHOLDER` also absent from added lines |

### Deferred issues check (known, not regressions)

`git diff 1d7573e5..HEAD --stat` over `scrypath_ops`, `scripts`, `examples`, `website`, `brand`, `lib`, `dev`, `config`, `mix.exs`, `mix.lock` and `.github` is empty: the phase touched none of the files behind the two `ui_literal_policy` node-test failures (the `scrypath_ops/assets/css/app.css` mutation target string is absent at the phase base `1d7573e5` as well as at HEAD) or the `ui_contrast` timeout. They are pre-existing and not caused by Phase 192.

### Human Verification Required

None.

The fixer marked WR-02 and WR-06 "requires human verification". I judge neither to be a real unautomatable item:

- **WR-02** (glob and brace spellings of repo-only task families; shipped families such as `mix scrypath.*` are excluded): this is a matching-rule design choice, and its behavior is exercised. Planted cases (`mix verify.phase*`, `mix verify.phase{11,14}`, `mix verify.{all,core}`, `mix scrypath_ops.*`, backticked forms) are reported; `mix scrypath.*`, a glob with no matching prefix and a bold span are not; the same cases without the shipped-names argument are reported; and the real shipped files stay at zero violations. I re-ran representative cases myself.
- **WR-06** (absolute HexDocs links are read as pages of the local build): the limitation is version skew (HexDocs serves the last published version, so a fragment added since the last release is checked against the local build, not the live site). That is a stated bound on what the check proves, already scheduled for the Phase 193 checkpoint (live-link behavior recorded once), not an unverified behavior in a must-have. As a one-off, I fetched the README's absolute links live and all returned 200.

### Observations (non-blocking, for the record)

1. **Pre-existing, out of scope:** `lib/mix/tasks/scrypath.settings.diff.ex:124` prints "run `mix scrypath.reindex ...`" in runtime output, and no task by that name exists in `lib/` or any task tree. The invariant cannot see it (it only knows repo-only names), the file was not touched by this phase, and it is not a repo-only task, so TRUTH-01 is unaffected. Worth a backlog item (another task or a docs-truth sweep); the code reviewer noted the same.
2. **Recorded accepted gap (by design):** the three README route-index pins (jtbd guide, request-edge guide, composing guide) and the route block pin were replaced by "the guide is a docs extra" assertions, and the README's intake-guide pin was retired because the README no longer lists those routes (locked decision, three-link cap). The inventory states the gap: extras membership proves the guide ships, not that the sidebar groups it; Phase 193 (DOCS-01) owns the grouping. This follows from the locked README shape and is not a pin weakened to reach green.
3. **Wording nit:** the README says ":inline for the first-hour path". It is not on the time-promise list and does not promise a duration; the list is data in the test if the maintainer wants it added.
4. **Review info items IN-01 to IN-05** were not in the fix scope and remain open (module pages not scanned by the built-docs test, repo-path regex copy drift, duplicated `verify.adopter` unit filter, one unused allowed host, one unused accessor). IN-01 is moot today: my scan of the 34 module pages found 0 problems.
5. **Bookkeeping for the orchestrator:** `.planning/REQUIREMENTS.md` still shows the six requirements as unchecked and "Pending" in the traceability table, and the ROADMAP plan checkboxes for Phase 192 are unchecked; close-out should update them.
6. **Environment note:** two tests (`every Mix task source outside lib/ and test/ is read by the derivation`, and the README header byte-equality pin) need a git checkout; they pass in the real tree and fail only in a `.git`-less copy. Hosted CI runs from a checkout.

### What this does not prove (per the ROADMAP)

That the new README reads better to a newcomer or that time to first search improved; that the quick path was run against a live Meilisearch (no live run exists); brand fit; live hex.pm and HexDocs rendering of the README (Phase 193 checkpoint); that the owner assignments are the right ones (the test proves each owner carries the token that pins it). The required hosted lanes (`core`, `package`, `repository-contracts`, `backend`, `ecommerce-mounted`, `ops-ui`) were not run by this verification; the orchestrator runs lane mirrors before the PR.

### Gaps Summary

No gaps. All five roadmap success criteria hold against the real tree, each confirmed by a test I ran and by planted-failure or mutation evidence that the check can fail. All six requirement IDs are accounted for. No blocker, no warning on a must-have, no human verification item.

---

_Verified: 2026-11-21T11:02:38Z_
_Verifier: Claude (gsd-verifier)_
