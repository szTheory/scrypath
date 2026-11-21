---
phase: 193-hexdocs-regroup-and-guards
verified: 2026-11-21T15:20:00Z
status: passed
score: 20/20 must-haves verified
covered_files:
  - ".planning/phases/193-hexdocs-regroup-and-guards/193-01-PLAN.md"
  - ".planning/phases/193-hexdocs-regroup-and-guards/193-01-SUMMARY.md"
  - ".planning/phases/193-hexdocs-regroup-and-guards/193-02-PLAN.md"
  - ".planning/phases/193-hexdocs-regroup-and-guards/193-02-SUMMARY.md"
  - "CONTRIBUTING.md"
  - "README.md"
  - "docs/releasing.md"
  - "guides/overview.md"
  - "lib/scrypath.ex"
  - "mix.exs"
  - "scrypath_ops/test/support/copy_rules.json"
  - "test/release/forbidden_phrases_contract_test.exs"
  - "test/release/install_line_contract_test.exs"
  - "test/release/package_metadata_test.exs"
  - "test/release/shipped_docs_contract_test.exs"
  - "test/release/snippet_parity_contract_test.exs"
  - "test/scrypath/docs_contract_test.exs"
  - "test/scrypath/readme_contract_test.exs"
  - "test/support/release/forbidden_phrases.ex"
  - "test/support/release/forbidden_phrases.json"
  - "test/support/release/install_line.ex"
  - "test/support/release/shipped_docs.ex"
  - "test/support/release/snippet_parity.ex"
covered_digest: "v4:sha256:502261448563e466852fdf06195849fad9ebd203dd22b0bb97b84cbd270a86cf"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 193: HexDocs regroup and guards Verification Report

**Phase Goal:** A reader in the HexDocs sidebar finds the right guide by job from a short first group, and mechanical guards keep README, guides and (later) the site from drifting.
**Verified:** 2026-11-21T15:20:00Z
**Status:** passed
**Re-verification:** No, initial verification
**Branch / head:** `gsd/phase-193-hexdocs-regroup-and-guards` at `03580e78` (20 commits ahead of `origin/main`, which is the merge base)

## Verdict

The phase goal is achieved and every success criterion is backed by an executable check that I ran myself, not by the SUMMARY claims. Beyond running the shipped tests, I (a) read the ExDoc sidebar payload from my own docs build, (b) called each guard module directly with planted inputs, and (c) mutated real shipped files in a throwaway copy of the tree (the working tree was never touched) and confirmed the intended guard fails for each mutation.

## Goal Achievement

### Roadmap Success Criteria (the contract)

| # | Success criterion | Status | Evidence |
|---|-------------------|--------|----------|
| SC1 | `mix docs` builds with no warnings, the first sidebar group has at most five items, every extra is in exactly one group, no guide renamed, merged or deleted | VERIFIED | `MIX_ENV=test mix docs --warnings-as-errors -o <scratch>` exit 0. My own read of the built `dist/sidebar_items-*.js`: first named group `Getting started` has 5 ids `readme, golden-path, getting-started, overview, meilisearch-concepts`; six named groups in order; 33 extras = 33 unique group members, 0 missing, 0 dangling, 0 duplicated; `extras == concat(groups)`. `git ls-tree` of `guides/ docs/ ARCHITECTURE.md CONTRIBUTING.md README.md` is identical on `origin/main` and `HEAD`; `git diff --diff-filter=DR` prints nothing. Only four doc files are modified (CONTRIBUTING, README, docs/releasing, guides/overview). ExDoc's built-in `api-reference` page is the one ungrouped entry above the named groups, unchanged from before the phase and explicitly allowed by the test. |
| SC2 | Fate of `guides/overview.md` recorded; if it left `extras`, no shipped link points at its old page | VERIFIED | It stayed in `extras` and in the first group (2 occurrences in `mix.exs`), shrunk from 584 to 226 words, URL unchanged (`overview.html` exists in my build). The README link (`README.md:111`) and the `Scrypath` moduledoc link (`lib/scrypath.ex:13`) both still resolve and no longer call it an index of every guide. Decision and reason recorded in `.planning/reference/CLAIM-OWNER-MAP.md` under `## Recorded decisions` (dated 2026-11-21) and in `193-PIN-INVENTORY.md` (Overview pin inventory, Retired overview content, Fate log). |
| SC3 | Link check passes on built docs and README and fails a planted self-link and a planted dead target | VERIFIED | Existing `Scrypath.Release.BuiltDocsBrandTest` ran green (35 tests in `package_metadata_test.exs`, built-link tests executed, not excluded). I read the planted-link test (`package_metadata_test.exs:566-617`): it asserts exact `:self_link`, `:unresolved` and `:dead_anchor` tuples on real built `readme.html`, with controls, own-docs URL forms, and a vacuity guard. README is scanned as `readme.html`. No second docs build, no new gate or lane (`git diff` touches no `.github/` or `scripts/`). The new source-level own-docs URL rule (below) adds versioned, `http://` and non-page URL rejection. |
| SC4 | Install line equals the `mix.exs` version everywhere it appears; schema snippet identical across README and golden path or carries an explicit "intentionally differs" marker | VERIFIED | Real scan: 6 occurrences at `mix.exs` 0.3.20 (README:45, golden-path:20, outside-adopter-intake:21, support-and-compatibility:17, `website/scripts/build.mjs:139`, plus the one named `~> X.Y.Z` placeholder at `docs/releasing.md:78`), 0 violations. My independent `git grep` of every `{:scrypath, "` tuple finds the same set (the `dev/mix/tasks/verify.release_publish.ex` tuple interpolates the version, so it cannot drift). Direct calls: `~> 0.2` at 0.3.20 is `:series_mismatch`, `~> 0.3` at 0.4.0 is `:series_mismatch`, `~> 0.3` and `~> 0.3.20` at 0.3.20 pass. Real README vs golden-path schema and config fences: `:identical`. Planted: differing fences `{:error, :differs}`, bare marker and blank-reason marker `{:error, :empty_reason}`, marker with a reason `{:marked, :golden, "shorter on purpose"}`. |
| SC5 | Forbidden-phrase table fails a planted banned phrase in README and guide text, and `CONTRIBUTING.md` carries the same-PR rule | VERIFIED | Direct calls: "in five minutes" flagged in README (line 1) and in `guides/planted.md` (line 3); "effortless" flagged in a guide; "magic" flagged in README only (README-only scope works); a phrase inside a fence and the pinned eventual-consistency sentence are not flagged. Real files: 27 targets (README + 26 guides), 0 violations. `CONTRIBUTING.md` carries `**Same-PR rule for public-surface claims.**` with the claim-owner-map URL, pinned by test "CONTRIBUTING carries the same-PR rule for public-surface claims" and owner-map row `same-pr-rule`. The false "no longer part of the default CI" sentence was replaced with the true `package`-lane statement. |

### Plan-level truths (additions to the roadmap contract)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| P1-1 | Six job-named groups in the locked order | VERIFIED | Config and built payload both show `Getting started, Guides by task, Phoenix, Operate and recover, Project policy, Maintainers`. |
| P1-2 | First group is exactly the five locked pages, golden path directly after README | VERIFIED | Rendered ids `readme, golden-path, getting-started, overview, meilisearch-concepts`. `getting-started.md:5` links `golden-path.md` (DOCS-01 "getting-started.md linking to it"). |
| P1-3 | A planted missing, duplicated, dangling or oversized-first-group entry fails | VERIFIED | Real mutations in a scratch copy: M1 (extra in no group) 4 failures including `every docs extra is in exactly one sidebar group` and the built-sidebar test; M2 (6-item first group) 3 failures; M3 (dangling member) 5 failures; M4 (extra in two groups) config test fails and the docs build itself breaks; M5 (extras order moves golden path) 4 failures including the built-sidebar order test. |
| P1-4 | Built sidebar test proves what ExDoc rendered, only `api-reference` ungrouped | VERIFIED | `built_sidebar_extras/1` reads the real payload from the `setup_all` build; floors (entry count, all six group names, `readme` then `golden-path` first). My own payload read matches. |
| P1-5 | `mix docs --warnings-as-errors` exits 0, no doc file renamed or deleted | VERIFIED | Exit 0 (test env, scratch output dir); rename/delete check empty. |
| P1-6 | `overview.md` stays in `extras` at the same URL, 10-item reading order plus two example links, all 11 overview assertions pass unchanged | VERIFIED | File read in full: h1 `# Guides`, ten numbered items, item 2 carries `Canonical mental model`, item 10 `common-mistakes`, both example URLs, support link. Doc-pin set (13 files plus 3 new): 304 tests, 0 failures. |
| P1-7 | Decision recorded in inventory and owner map; README and moduledoc no longer call it an index | VERIFIED | See SC2. Rows `guide-routes` (owner `doc:mix.exs`) and `reading-order` present in the owner map. |
| P2-1 | Every install line checked against `mix.exs` version by series prefix plus `Version.match?/2` | VERIFIED | See SC4. Source reads `Scrypath.MixProject.project()[:version]` at test time. M6 (README `~> 0.2`), M7 (`@version "0.4.0"`), M8 (stale line only in `support-and-compatibility.md`) each fail `every install line in the shipped files and the website matches the mix.exs version series`. |
| P2-2 | Only non-numeric install line is the named `docs/releasing.md` placeholder, with reason and revisit; any other fails | VERIFIED | Placeholder at another path and `>= 0.3.0` both returned `:unsupported`. Test "each placeholder records a reason and a revisit trigger and still occurs" exists and passes. |
| P2-3 | Built-page GUARD-01 covered by the existing scan, mapped test by test, no second docs build | VERIFIED | Inventory section `## GUARD-01 evidence` maps each case to a test name and line; I read those tests and confirmed the mapping. One `Mix.Tasks.Docs.run` per VM preserved. |
| P2-4 | Source-level own-docs URL rule rejects versioned, `http://`, non-page; one named exception | VERIFIED | Direct calls return `:versioned`, `:insecure_scheme`, `:not_a_page`; valid page URL `[]`. Real files: 11 URLs read, 0 violations. M9 (planted versioned URL in a guide) fails `shipped files hold only unversioned https root or page links to the own docs`. |
| P2-5 | Schema snippet identical or reason-carrying marker; planted differ, empty-reason, old bare-marker fail | VERIFIED | See SC4. M12 (README fence diverges, no marker) fails `the quick path schema snippet is identical to the golden path`. |
| P2-6 | Phrase table green on README + every guide, fails planted phrase in README and guide, scopes magic/federated/hydration to README, never bans accepted work, brand rules equal the brand book | VERIFIED | See SC5. Rule ids `time-promise, brand-hype, brand-technical-readme-only, glossary-names`; brand terms equal the 8 terms in `brand/BRAND.md` (faithfulness test passes). M10 (planted "effortless" in a guide) and M11 (planted time promise in README) fail the real-file scan and the rewired README tests. |
| P2-7 | Every phrase the README tests banned before is still caught in README | VERIFIED | Test "each phrase the README tests banned before is still caught in README" present and passing (plants all 18 prior phrases). README tests now call `ForbiddenPhrases.scan/2`. |
| P2-8 | CONTRIBUTING same-PR rule names the owner map, pinned by a test and an owner-map row; lane sentence states the `package` lane | VERIFIED | `CONTRIBUTING.md` diff read. M13 (rule removed) fails `CONTRIBUTING carries the same-PR rule...` and the owner-map `Pinned-by` test. |

**Score:** 20/20 truths verified (5 roadmap criteria + 15 plan truths), 0 present-but-behavior-unverified, 0 overrides.

### Review-fix claims (193-REVIEW-FIX.md) checked against the code

| Finding | Claim | Result |
|---------|-------|--------|
| WR-01 fence pairing | Line-by-line CommonMark-style pairing; unclosed fence raises | CONFIRMED. Prose after `html+eex`, `json5`, titled, `~~~`, four-backtick, indented and bare fences is flagged at the true line; a phrase inside a fence is masked; an unclosed fence raises `guides/p.md: the code fence opened on line 3 is never closed`. |
| WR-02 directory scope | Guides come from `guides/*.md`, not `extras`; `unlisted_guides/2` ties the two | CONFIRMED. `unlisted_guides()` is `[]`; 26 guides on disk, 27 targets. |
| WR-03 1.x series | Major-only series rule from 1.0.0 | CONFIRMED. `~> 1.0` at 1.2.3 `:ok`, `~> 0.3` at 1.0.0 `:series_mismatch`, `~> 1.3` at 1.2.3 `:unsatisfied`; 0.x behavior unchanged. |
| IN-02 trailing markup | Emphasis, braces, escapes trimmed without hiding bad URLs | CONFIRMED. `**url**`, `_url_`, `{url}` yield no problem; `**.../0.3.20/readme.html**` is `:versioned`. |
| IN-04 CHANGELOG | Excluded from both source guards as one named entry with reason and revisit | CONFIRMED. `history_files/0` holds one entry; `CHANGELOG.md` is not in `InstallLine.sources/0`; the file has 0 install tuples and 0 own-docs URLs today. |
| IN-03 ops exemption | `copy_rules.json` exempts only the phrase data file | CONFIRMED. Diff adds one `exempt_paths` entry; the `control-room-casing` rule is intact; no other phase file spells the title-case name. |

The report labels WR-01 and WR-03 "requires human verification". I did not carry that forward: both are fully covered by automated planted cases that I re-ran directly, so no human item is warranted.

### Summary-claim cross-check

All 15 commit hashes cited in the two SUMMARYs and REVIEW-FIX exist and are ancestors of `HEAD`; subjects match the findings they claim to fix. Counts match: 6 install occurrences, 11 own-docs URLs, 27 phrase targets, 304 tests across the doc-pin set plus the three new files.

### Required Artifacts

| Artifact | Status | Details |
|----------|--------|---------|
| `mix.exs` six groups and reordered extras | VERIFIED | 33 extras, six groups, no rename. |
| `test/release/package_metadata_test.exs` config-shape and built-sidebar tests | VERIFIED | Real and planted tests present, run, and fail under mutation. |
| `guides/overview.md` | VERIFIED | 226 words, reading order, same URL. |
| `193-PIN-INVENTORY.md` | VERIFIED | All 10 sections present; fate-log commit column filled with real hashes. |
| `test/support/release/install_line.ex` + contract test | VERIFIED | Untagged (`@moduletag` count 0), runs in `core`. |
| `test/support/release/shipped_docs.ex` own-docs rule + tests | VERIFIED | Real-file zero plus planted cases. |
| `test/support/release/snippet_parity.ex` + contract test | VERIFIED | Untagged. |
| `test/support/release/forbidden_phrases.{ex,json}` + contract test | VERIFIED | Untagged; JSON rules carry id, scope, source. |
| `CONTRIBUTING.md` same-PR rule, `docs/releasing.md` minor-bump note, owner-map rows | VERIFIED | All present. |

### Key Link Verification

| From | To | Status |
|------|----|--------|
| `package_metadata_test.exs` | `mix.exs` `groups_for_extras` / `extras` | WIRED (config tests fail under M1-M5) |
| `package_metadata_test.exs` | ExDoc `dist/sidebar_items-*.js` | WIRED (built-sidebar test fails under M1, M3, M5) |
| `install_line.ex` | `mix.exs` version, `website/scripts/build.mjs` | WIRED (M7 version bump fails; `build.mjs` is in sources and yields an occurrence at line 139) |
| `readme_contract_test.exs` | `SnippetParity`, `ForbiddenPhrases` | WIRED (M11, M12 fail the README tests) |
| `forbidden_phrases.ex` | `brand/BRAND.md` | WIRED (faithfulness test; 8 terms equal) |
| `CLAIM-OWNER-MAP.md` | `CONTRIBUTING.md` | WIRED (M13 fails the Pinned-by test) |
| README / moduledoc | `overview.html` | WIRED (page built; TRUTH-03 scan resolves it) |

### Data-Flow Trace (Level 4)

Not applicable in the UI sense: nothing renders dynamic data. The equivalent check is that each guard reads real inputs rather than a constant. Each reads real files and real config at test time, and the mutation battery proves this: changing a real file in the copy flips the guard.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Focused phase test files | `mix test --warnings-as-errors` on 7 files (package_metadata, install_line, snippet_parity, forbidden_phrases, shipped_docs, readme_contract, docs_contract) | 214 tests, 0 failures | PASS |
| Doc-pin set (13 files) plus 3 new contract files | `mix test --warnings-as-errors ...` | 304 tests, 0 failures | PASS |
| CONTRIBUTING / releasing readers (8 files) | `mix test ...` | 231 tests, 0 failures | PASS |
| Built docs, rendered sidebar | `MIX_ENV=test mix docs --warnings-as-errors -o <scratch>` then read payload | exit 0; first group 5 items, golden path second | PASS |
| Guard modules with planted inputs | direct calls via `mix run -r ...` | every planted case fails as specified; real files 0 violations | PASS |
| Mutation battery M1-M13 on real files in a scratch copy | `mix test` per mutation | each mutation fails its intended guard | PASS |
| `mix format --check-formatted`; `mix credo --strict` on 11 touched Elixir files | | clean; 0 issues | PASS |

Mutation note: in the scratch copy (made with `git archive`, so no `.git`) two tests that read git history fail even before any mutation (`README.md header uses commit-pinned raw URLs...` and `every Mix task source outside lib/ and test/ is read by the derivation`). They pass in the real tree (214/0 above), so they are a copy artifact, not a phase issue. Mutation conclusions were drawn only from the additional failures. The scratch copy was deleted afterwards.

### Probe Execution

No shell probes are declared by the plans or summaries and the phase is not a probe-driven migration. Step skipped.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| DOCS-01 | 193-01 | Sidebar regrouped, at most five in first group, job-named, golden path start page, `getting-started.md` links it, nothing renamed, `mix docs` clean, test asserts exactly-one group | SATISFIED | SC1, P1-1 to P1-5 |
| DOCS-02 | 193-01 | Fate of `overview.md` decided and recorded; if dropped no link to old page | SATISFIED | SC2, P1-6, P1-7 (kept and shrunk; links live) |
| GUARD-01 | 193-02 | Link check over built docs and README, self-links fail, no new gate | SATISFIED | SC3, P2-3, P2-4 |
| GUARD-02 | 193-02 | Install line asserted equal to `mix.exs` version wherever it appears | SATISFIED | SC4, P2-1, P2-2 |
| GUARD-03 | 193-02 | Snippet parity or marker; forbidden-phrase table; CONTRIBUTING same-PR rule | SATISFIED | SC4, SC5, P2-5 to P2-8 |

All five IDs are declared in plan frontmatter (`193-01`: DOCS-01, DOCS-02; `193-02`: GUARD-01, GUARD-02, GUARD-03), appear in `REQUIREMENTS.md`, and are mapped to Phase 193 there. No orphaned requirements: grep of `REQUIREMENTS.md` for Phase 193 finds exactly these five, plus README-01 and README-03 cross-references that belong to Phase 192 and are already `[x]`.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (none) | | `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, `PLACEHOLDER` on lines added by the phase | none | The only substring hit is `TBD` inside the pre-existing acronym `JTBD` in `guides/overview.md` (a false positive). No skipped or disabled tests in the phase's test files. No stubs. |

### Not proven (explicit limits, recorded and not turned into human items)

Per AGENTS.md (zero human verification), these are known limits of what the automated evidence establishes. They do not block the phase and are not `human_needed`.

- That the grouping matches how readers look for things (the roadmap's stated limit).
- Live HexDocs and hex.pm rendering, including how hex.pm renders the snippet marker comment. HexDocs changes only through a Hex release, which needs the maintainer's explicit yes.
- How the shrunk overview reads (the tests prove its structure, links and pinned tokens, not its quality).
- External link liveness (no network call is made); own-docs URLs built by interpolation in `mix.exs` (versioned on purpose, pinned by the package-metadata test); the website's own HexDocs links (not shipped files).
- Prose that names a series without an install tuple (the golden path's minor-series sentence); the website's rendered install block.
- That unlisted wording is fine or that the guides read in the brand voice.
- That contributors follow the same-PR rule.
- Install-line behavior at a real minor bump: the guard intentionally goes red on the release PR at 0.3 to 0.4 (my M7 confirms), and `docs/releasing.md` records the one-commit fix. That is designed behavior, not a defect.

### Outstanding before merge (not goal gaps)

These are exact-SHA evidence and bookkeeping items for the orchestrator, outside the phase goal:

- Hosted lanes that were not or could not be run locally, with the reasons the plans recorded: cold `mix verify.ops_ui` builds, the Docker and browser half of `ecommerce-mounted`, `backend` (needs Meilisearch on 7700), the Node half of `repository-contracts`. `website.yml` `build-and-check` is not a required check but must be green on the exact head before the squash merge, because the merge deploys the site (it triggers on `mix.exs`, `README.md`, `guides/**`, `docs/**`).
- The summaries ran `mix verify.core`, `mix verify.package` and `mix verify.repository_contracts` on head `3ad98a12`; the follow-up commits (`054207d7` and the review fixes through `03580e78`) were verified with focused runs only. A separate process is running the heavy lanes on the current head now, so I did not duplicate or assert them.
- Close-out bookkeeping still unchecked: `REQUIREMENTS.md` DOCS-01, DOCS-02, GUARD-01, GUARD-02, GUARD-03 checkboxes and traceability rows still read `Pending`; `ROADMAP.md` Phase 193 plan lines are `[ ]` and the progress table still says `0/2 Not started`.
- Found issue outside this phase, confirmed and not fixed: `scrypath_ops/lib/scrypath_ops/posture.ex` `operator_mix_guide_path/0` resolves to `scrypath_ops/guides/operator-mix-tasks.md`, which does not exist, so the posture screen never reads the guide. This phase does not touch it.
- One watch item: the ops copy-rules exemption (`scrypath_ops/test/support/copy_rules.json`) excludes one whole data file from every `**`-scoped ops rule. It is path-scoped, follows an existing precedent, is recorded as accepted (IN-03) with a revisit trigger, and no ops rule was narrowed or removed.

### Gaps Summary

None. No truth failed, no artifact is a stub or unwired, no key link is broken, and no blocker anti-pattern exists. The phase goal is achieved: the sidebar presents six job-named groups with a five-item first group led by the golden path, the overview decision is recorded, and the install-line, own-docs URL, snippet-parity and forbidden-phrase guards plus the CONTRIBUTING same-PR rule each fail on planted or mutated input and pass on the real files.

---

_Verified: 2026-11-21T15:20:00Z_
_Verifier: Claude (gsd-verifier)_
