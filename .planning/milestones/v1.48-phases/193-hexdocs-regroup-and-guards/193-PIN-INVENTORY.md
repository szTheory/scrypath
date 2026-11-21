# Phase 193 Pin Inventory

Audit trail for DOCS-01 and DOCS-02: every assertion that pins the HexDocs sidebar group shape or the content of `guides/overview.md`, whether it pins a claim or wiring, and where its intent lives after the phase. No pin is weakened to reach green; a pin that changes is replaced by a stronger or equal one and the replacement is recorded in the Fate log.

Built in Plan 01 Task 1 from `193-RESEARCH.md` and re-verified by grep at HEAD `4b8e3b8b` (plan start). Line numbers shift as the plans edit, so re-locate by the quoted token. Plan 02 appends its guard sections below the Fate log.

## Legend and reproduction

- **claim**: asserts what a doc says. **wiring**: asserts that a file, extras entry or `mix.exs` key is hooked up. **hygiene**: asserts the absence of banned text across a set of files.
- Fate vocabulary: `stays`, `carry unchanged` (the page changes, the assertion does not), `replace (stronger)`, `retitle and strengthen`, `move claim to owner`, `retire with reason`.

Reproduce (toolchain: `export ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5`):

```bash
grep -rn 'groups_for_extras' test mix.exs
grep -rn 'overview' test
grep -rn 'overview' lib README.md .planning/reference/CLAIM-OWNER-MAP.md
# The doc-pin set (13 files). docs_contract_test.exs carries @moduletag :docs_contract, is excluded from
# `core` and from scripts/ci/pre_push.sh, and runs hosted only in the required `package` lane, so it is named by hand.
mix test test/release/package_metadata_test.exs test/release/shipped_docs_contract_test.exs test/scrypath/readme_contract_test.exs test/scrypath/docs_contract_test.exs test/scrypath/phase112_contract_test.exs test/scrypath/phase99_contract_test.exs test/scrypath/readiness_contract_test.exs test/scrypath/phase98_contract_test.exs test/scrypath/phase110_contract_test.exs test/scrypath/backfill_contract_docs_test.exs test/scrypath/telemetry_test.exs test/scrypath/telemetry_contract_test.exs test/mix/tasks/dependency_boundary_contract_test.exs
```

Baseline at plan start: `mix test test/release/package_metadata_test.exs test/scrypath/docs_contract_test.exs` reported 103 tests, 0 failures.

## Group-shape pins

Re-verified at HEAD `4b8e3b8b` by grepping each quoted token.

| # | Where | What it pins today | Type | Fate |
|---|-------|--------------------|------|------|
| G1 | `test/release/package_metadata_test.exs:108` `docs[:groups_for_extras][:Operations] == [...]` (eight paths, verbatim list order) | The old `Operations` group key and its member order. The key disappears with the regroup, so `nil == [...]` would fail with an unhelpful diff | wiring | replace (stronger): the eight members are the `"Operate and recover"` members, asserted as sorted lists (the old pin's intent, carried to the renamed group); list order is pinned separately by the extras-order test |
| G2 | `package_metadata_test.exs:119` `docs[:groups_for_extras][:Maintainers] == [...]` (five paths) | The Maintainers group, verbatim | wiring | stays, byte-identical (Maintainers is unchanged) |
| G3 | `package_metadata_test.exs:98-106` nine `assert "<path>" in docs[:extras]` | Nine paths are extras (CONTRIBUTING, releasing, operator-mix-tasks, operator-support, search-backend-sre, overview, per-query-tuning-pipeline, telemetry, drift-recovery) | wiring | stays, byte-identical (same 33 paths) |
| G4 | `test/scrypath/docs_contract_test.exs:1409` title "multitenancy guide is registered in ExDoc extras and Getting Started group (TNNT-01)" with body `String.contains?(mix_exs, ~s("guides/multitenancy.md"))` | Title claims a group; body only greps `mix.exs` for the path, so it proves neither extras membership nor a group | wiring | retitle and strengthen: assert through `Scrypath.MixProject.project()[:docs]` that the path is in extras and in the `:"Guides by task"` list |
| G5 | `docs_contract_test.exs:150` and `:259` comments "Accepted gap: extras membership proves the guide ships, not that the sidebar groups it" | Records a known gap, asserts nothing | comment | retire with reason: the config-shape and built-sidebar tests in `package_metadata_test.exs` close the gap; both comments now point at them |
| G6 | `docs_contract_test.exs:532` `Getting Started](getting-started.md)` and `:658` `Golden path](golden-path.md)` | Page title and link text in the getting-started guide; `:658` is the DOCS-01 proof that `getting-started.md` links the golden path | claim | stays: only the group label changes case, the page title and its link stay |

## Overview pin inventory

Eleven assertion calls in three files read `guides/overview.md`. Re-verified by grep at HEAD `4b8e3b8b`.

| # | Where | What it pins (verbatim tokens) | Type | Fate after the shrink |
|---|-------|--------------------------------|------|-----------------------|
| O1 | `package_metadata_test.exs:103` | `assert "guides/overview.md" in docs[:extras]` | wiring | stays: the page and URL stay |
| O2 | `test/scrypath/phase112_contract_test.exs:11,26`, consumed at `:98-101` | `@overview File.read!("guides/overview.md")` in `@all_surfaces`; `assert_absent_patterns(content, @misleading_patterns, path)` | hygiene (no "AI-powered", "always current", "immediately searchable" and the like) | stays; re-run after the shrink (the new text is clean by construction) |
| O3 | `docs_contract_test.exs:55` feeding the published-markdown hygiene test | `"guides/overview.md"` in `@guide_paths`; no planning or task IDs in published markdown | hygiene | stays |
| O4 | `docs_contract_test.exs:649-650` | `Enum.each(@guide_paths, &assert(File.exists?(&1), ...))` | wiring | stays: the file stays |
| O5 | `docs_contract_test.exs:155-158` | overview contains `[JTBD and user flows](jtbd-and-user-flows.md)` and `Canonical mental model` (case-sensitive) | claim: the overview exposes the jtbd guide as a first-class entry point | carry unchanged: reading-order item 2 keeps the link text and a clause that starts `Canonical mental model:` |
| O6 | `docs_contract_test.exs:160-164` | `ordered?(overview, "[JTBD and user flows](jtbd-and-user-flows.md)", "[Common mistakes](common-mistakes.md)")` | claim: mental model is listed before pitfalls | carry unchanged: a new tenth reading-order item `[Common mistakes](common-mistakes.md)` follows item 2 |
| O7 | `docs_contract_test.exs:187` | overview contains `[Request-edge search](request-edge-search.md)` | claim | carry unchanged (item 4) |
| O8 | `docs_contract_test.exs:219-223` | `ordered?(overview, "[Request-edge search](...)", "[Composing real-app search](composing-real-app-search.md)")` | claim | carry unchanged (items 4 then 5) |
| O9 | `docs_contract_test.exs:262` | `assert_docs_extras([... "guides/overview.md" ...])` (list of 18 paths) | wiring | stays |
| O10 | `docs_contract_test.exs:292` | overview contains `examples/phoenix_meilisearch/README.md` | claim (owner-map row `examples`) | carry unchanged: the example paragraph keeps its absolute GitHub URL |
| O11 | `docs_contract_test.exs:293` | overview contains `examples/scrypath_ecommerce/README.md` | claim (owner-map row `examples`) | carry unchanged (same paragraph) |

Result after the shrink (Plan 01 Task 2): the doc-pin set of 13 files reports 248 tests, 0 failures, and none of the eleven assertion calls was edited; O5 to O8, O10 and O11 pass against the new reading-order text as written.

Owner map rows that read the overview: `guide-routes` (Owner `guide:overview`, Pinned by `guides/overview.md has drift-recovery.md`) and `examples` (Owner `guide:overview`, two overview tokens). The owner-map shape test also requires `"guides/overview.md" in extras` for any `guide:overview` owner.

## Inbound references

References that no test reads, and what was done about each (Plan 01 Task 2).

| Where | Text before | Problem after the shrink | Fate |
|-------|-------------|--------------------------|------|
| `lib/scrypath.ex:13` | `[guides/overview.md](guides/overview.md) — table of contents for every published guide.` | False: the page becomes a reading order, not a table of contents | reworded to "a short recommended reading order; the HexDocs sidebar groups every guide by job." Docs only, no behavior change. This is the phase's only `lib/` touch |
| `README.md:111` | `The [guides overview](https://hexdocs.pm/scrypath/overview.html) indexes every guide, from sync modes to drift recovery.` | "indexes every guide" is false; the link must stay (the README caps onward links at 3) | reworded to "gives a recommended reading order; the HexDocs sidebar lists every guide, grouped by job"; link and link text unchanged, still one `overview.html` link, no link added |
| `mix.exs` entries (two) | `"guides/overview.md",` in `extras` and in the first group | none | stays in both |
| `.planning/reference/CLAIM-OWNER-MAP.md` rows `guide-routes` and `examples` | `guide-routes` owner `guide:overview`, "regrouped by Phase 193"; `examples` unchanged | `guide-routes` is now answered by the sidebar, not the page | `guide-routes` re-owned to `doc:mix.exs` (pinned by `mix.exs has Guides by task`); new row `reading-order` (owner `guide:overview`, pinned by `Recommended reading order` and `overview.html`); `examples` unchanged; the decision is recorded under `## Recorded decisions` in the map |

## Retired overview content

The shrink retired two blocks of `guides/overview.md`. Both stay in git history. No test read either block: `grep -rn 'four layers\|declaration:' test` prints nothing, and no assertion matches a table row of the old page (the eleven overview assertion calls above all read the reading order, the jtbd row text or the example links, which the shrunk page keeps).

| Retired block | Former claim | Owner of the claim now | Evidence no test read it |
|---------------|--------------|------------------------|--------------------------|
| "Crash Course" four-layer list (declaration, sync orchestration, search runtime, operator recovery) and the context-boundary sentence | Scrypath is easiest to think about as four layers; the app boundary is a Phoenix context | `ARCHITECTURE.md` (row `public-surface`) and `guides/getting-started.md` (row `quick-path`) | `grep -rn 'four layers\|declaration:' test` prints nothing |
| The 22-row guide table (guide, purpose) | Where each guide is, with a one-line purpose | The HexDocs sidebar, grouped by job in `groups_for_extras` (row `guide-routes`, owner `doc:mix.exs`); the ten-item reading order keeps the purpose clauses of the guides it lists | `grep -c '^| \[' guides/overview.md` prints 0; the jtbd row text is carried by reading-order item 2 (pin O5) |

## Fate log

One row per pin from both tables. Commit hashes are filled after the owning task commits.

| Pin | Type | Fate | Owner of the intent afterwards | Replaced by | Plan | Commit |
|-----|------|------|--------------------------------|-------------|------|--------|
| G1 | wiring | replace (stronger) | `"Operate and recover"` group | sorted-members assertion in "docs metadata keeps release guide and version-aware source links", plus the config-shape and extras-order tests | 01 Task 1 | `fb57e627` |
| G2 | wiring | stays | Maintainers group | none, byte-identical | 01 Task 1 | `fb57e627` |
| G3 | wiring | stays | extras list | none, byte-identical | 01 Task 1 | `fb57e627` |
| G4 | wiring | retitle and strengthen | `Guides by task` group | multitenancy registration test now asserts extras membership and the group | 01 Task 1 | `fb57e627` |
| G5 | comment | retire with reason | config-shape and built-sidebar tests | two comments reworded to name them | 01 Task 1 | `fb57e627` |
| G6 | claim | stays | getting-started guide | none | 01 Task 1 | `fb57e627` |
| O1 | wiring | stays | extras list | none | 01 Task 1 | `fb57e627` |
| O2 | hygiene | stays | phase 112 contract | none | 01 Task 2 | `517f428e` |
| O3 | hygiene | stays | docs contract | none | 01 Task 2 | `517f428e` |
| O4 | wiring | stays | docs contract | none | 01 Task 2 | `517f428e` |
| O5 | claim | carry unchanged | `guides/overview.md` reading-order item 2 | none | 01 Task 2 | `517f428e` |
| O6 | claim | carry unchanged | `guides/overview.md` reading-order items 2 and 10 | none | 01 Task 2 | `517f428e` |
| O7 | claim | carry unchanged | `guides/overview.md` reading-order item 4 | none | 01 Task 2 | `517f428e` |
| O8 | claim | carry unchanged | `guides/overview.md` reading-order items 4 and 5 | none | 01 Task 2 | `517f428e` |
| O9 | wiring | stays | extras list | none | 01 Task 1 | `fb57e627` |
| O10 | claim | carry unchanged | `guides/overview.md` example paragraph | none | 01 Task 2 | `517f428e` |
| O11 | claim | carry unchanged | `guides/overview.md` example paragraph | none | 01 Task 2 | `517f428e` |
| `install-line` owner-map HexDocs cell | claim | stays with owner `README`; the cell now names the guard | `test/release/install_line_contract_test.exs` | replaces "Phase 193 GUARD-02 guards parity" | 02 Task 1 | `dff73936` |
| built-docs link scan (TRUTH-03) | wiring | stays, no code change | `BuiltDocsBrandTest` (see GUARD-01 evidence) | none; the source rule beside it is new | 02 Task 1 | `dff73936` |
| README private snippet marker and fence helpers (`@differs_marker`, `fences`, `schema_fence`, `config_fence`, `differs_marked?`, `prose`) | wiring | move to shared module | `Scrypath.Release.SnippetParity`; the marker now needs a reason and is allowed above either fence | the two README parity tests keep their names and call `SnippetParity.check/3`; planted cases prove each failure | 02 Task 2 | `60be8948` |
| `CONTRIBUTING.md` sentence "no longer part of the default CI and release gates" | claim | replace (it was false) | `CONTRIBUTING.md` | the docs contract suite runs in the required `package` lane through `mix verify.package` and is excluded from `core` | 02 Task 2 | `60be8948` |
| README `@time_promises` list (10 phrases) | hygiene | move to data table | `time-promise` rule in `test/support/release/forbidden_phrases.json`, scope README and guides | "no README sentence promises a time" is now a caller; the no-weakening test plants all 10 | 02 Task 3 | `3ad98a12` |
| README `@brand_do_not_say` list (8 words) | hygiene | move to data table | `brand-hype` (scope README and guides) and `brand-technical-readme-only` (README only) rules | "the README avoids the brand's do-not-say words" is now a caller; the no-weakening test plants all 8; the faithfulness test ties the copy to `brand/BRAND.md` | 02 Task 3 | `3ad98a12` |

## GUARD-01 evidence

Success criterion 3: the link check passes on the built docs and README and fails a planted self-link and a planted dead target. All of it already exists in `test/release/package_metadata_test.exs`, module `Scrypath.Release.BuiltDocsBrandTest`, which runs one `Mix.Tasks.Docs.run` in `setup_all` (runs in `core` and in `mix verify.package`). Re-verified at plan start HEAD `bbe9891e` by reading each test and running the file (see the Plan 02 SUMMARY for the run). Lines shift as the file is edited, so re-locate by the quoted test name.

| Part of criterion 3 | Existing test | Line | What it asserts |
|---------------------|---------------|------|-----------------|
| Real build and README clean | "extras pages have no self-link, unresolved link or dead anchor" | 517 (problems assert 540-546) | `link_problems/3` over every page of `extras_pages(out)` is `[]` |
| README is covered | same test | 519-520 | a built page exists for every configured extra; `README.md` maps to `readme.html` and is the first extra, so it is scanned like any guide |
| Planted self-link | "the link scan reports a planted self-link, unresolved link and dead anchor" | 575 (HexDocs form 599) | `readme.html` linked from `readme.html` is `:self_link` |
| Planted dead target | same | 576 (`no-such-page.html`), 582 (`../readme.html`, leaves the build); HexDocs form 596 | `:unresolved` |
| Planted dead anchor | same | 578-579; HexDocs form 593-594 | `golden-path.html#no-such-anchor` is `:dead_anchor` |
| Controls that must pass | same | 585-587, 600-602 | another page, a real anchor, a web link and another project's HexDocs page report nothing |
| Non-vacuity floors | "extras pages have no self-link, unresolved link or dead anchor" | 527 (`@min_author_hrefs 500`), 537 (at least 4 own-docs links) | the scan read hundreds of hrefs and some own-docs links |
| A missing built page is named | "a configured extra with no built page is reported by name" | 549 | the scan cannot silently skip an extra |
| HexDocs URL forms | the two tests above, plus the new `describe "own HexDocs URLs in shipped files"` in `test/release/shipped_docs_contract_test.exs` | `@own_docs_href` 453; new describe after the links block | the built scan resolves unversioned `https://hexdocs.pm/scrypath/<page>.html` links and their fragments against the build; the new source rule rejects a versioned, `http://` or non-page own-docs URL in shipped file text |

No gap in the criterion cases was found, so no planted case was added and `package_metadata_test.exs` is not touched by this plan's Task 1.

Decisions recorded here so they are not re-litigated:

- No new docs build and no change to the built-scan code (CONTEXT, Link check). The one `setup_all` build stays the only one.
- The source rule lives in `Scrypath.Release.ShippedDocs` (`own_docs_url_problems/2`, `own_docs_urls/1`, `own_docs_url_violations/0`), rides `core` as an untagged test and adds no gate and no lane. It reads raw file text, fences and code spans included, so a versioned URL in a sample block is caught too.
- The rule has one named exception, the template URL in `docs/releasing.md` (reason and revisit trigger in the module; the contract test fails if the entry stops occurring).
- The rule does not read `CHANGELOG.md` (code review IN-04, decided in the review-fix pass): the changelog is release history that release-please builds from squash-commit subjects, so a subject that quotes an old install tuple or a versioned `hexdocs.pm/scrypath/<version>` URL is history, not a stale doc, and a commit already on main cannot be reworded to satisfy a guard. The file holds no own-docs URL and no install tuple today, so the exclusion changes no current result. It is one named entry (`ShippedDocs.history_files/0`, with a reason and a revisit trigger) shared with the install-line guard; a contract test fails if the entry empties or stops being a shipped file, and another planted case shows the same text still fails in README and a guide. It matches the existing whole-file `CHANGELOG.md` exemption of the TRUTH-01 command guard, which is a separate, locked set.
- A link wrapped in emphasis, braces or an escaped quote (`**url**`, `_url_`, `{url}`, `url\"`) is the bare URL: the extractor trims a trailing run of `. , ; : ! ? * _ ~ } \` (code review IN-02), and a planted case shows trimming does not hide a versioned, `http://` or non-page URL.

What the two together do not prove:

- External link liveness (no network call is made).
- Own-docs URLs built by interpolation, such as the versioned package links in `mix.exs` (`@release_docs_url`), which are versioned on purpose and pinned by the package-metadata test.
- The website's own HexDocs links: `website/` is not a shipped file.
- That a page's fragment exists for a link written in a non-extras shipped file (`docs/jtbd-gap-map.md` and `SECURITY.md` hold no HexDocs links to extras pages today; `CHANGELOG.md` is not read, see above).

## Install line occurrences

`Scrypath.Release.InstallLine` (GUARD-02) read 140 files (the shipped files plus the website sources that exist) at `mix.exs` version `0.3.20`; after the review-fix pass it reads 139, because `CHANGELOG.md` is excluded as release history (see the foot-gun note below). Real scan, plan start HEAD `bbe9891e`:

| Path | Line | Requirement | Result |
|------|------|-------------|--------|
| `README.md` | 45 | `~> 0.3` | ok |
| `docs/releasing.md` | 78 | `~> X.Y.Z` | named placeholder (template in the post-publish verification description) |
| `guides/golden-path.md` | 20 | `~> 0.3` | ok |
| `guides/outside-adopter-intake.md` | 21 | `~> 0.3` | ok |
| `guides/support-and-compatibility.md` | 17 | `~> 0.3` | ok |
| `website/scripts/build.mjs` | 139 | `~> 0.3` | ok |

Violations: none. The website page source holds only the `{{CANONICAL_INSTALL}}` slot, so the build script is the website's only literal.

Choices recorded:

- Before 1.0.0 a requirement must equal the same-length prefix of the version's `[major, minor, patch]` and `Version.match?/2` must hold. `~> 0.2` is satisfied by 0.3.20 and `~> 0.3` by 0.4.0, so satisfaction alone would catch neither. From 1.0.0 on (code review WR-03) only the major must match, because `~> 1.0` is the right line at every 1.x release; `Version.match?/2` decides the rest. Planted cases: `~> 1.0` at 1.2.3 and 1.0.5 pass, `~> 0.2` at 1.2.3 and `~> 0.3` at 1.0.0 are series mismatches, `~> 1.0` at 2.0.0 is a series mismatch, `~> 1.3` at 1.2.3 is unsatisfied; the 0.x rule is unchanged. `docs/releasing.md` says which rule applies when.
- The pattern also reads a tuple with trailing options, such as one with `only: :dev`, so a stale line cannot hide behind them.
- Minor-bump consequence (accepted, CONTEXT research resolution): at a bump from 0.3.x to 0.4.0 the contract test goes red on four shipped files plus `website/scripts/build.mjs` until the install lines move. The fix is one commit on the bot-authored release PR, written up under "Minor version bumps and the install-line guard" in `docs/releasing.md`.
- `CHANGELOG.md` is read by neither source guard (code review IN-04, decided in the review-fix pass; this replaces the earlier "known foot-gun, not pre-handled" note). It is a shipped file that release-please builds from squash-commit subjects. Left in scope, a subject quoting an old install tuple (or, for the own-docs rule, a versioned `hexdocs.pm/scrypath/<version>` URL) would turn the bot-authored release PR red, and the remedy would not hold: the subject is already on main and release-please regenerates the entry. Excluding it makes neither guard vacuous, because the file holds no install tuple and no own-docs URL today and the non-vacuity floors are measured over the other files. Mutation check: a stale tuple plus a versioned URL appended to `CHANGELOG.md` leaves both guards green; the same text appended to a guide fails both. Revisit trigger (recorded beside the entry in `ShippedDocs.history_files/0`): the release-please changelog configuration changes, a hand-written entry starts carrying an install line or own-docs link meant to be copied, or the file stops being generated.
- Not covered: prose that names a series without a tuple (the golden path's minor-series sentence) and the website's rendered install block.

## Snippet marker

Plan 02 Task 2 moved the README parity helpers into `Scrypath.Release.SnippetParity` and changed the marker. Facts and decisions:

- Form: an HTML comment `scrypath:snippet-intentionally-differs: <reason>` as the last thing before the fence, with blank lines between the comment and the fence tolerated. The reason is required. The old bare form (no reason) and a blank reason are an error even when the two bodies match, so nothing can use the marker as a silent switch.
- Side: allowed above either the README fence or the golden path fence (amends "the later one"; recorded in 193-CONTEXT.md, Plan-check resolutions). A sentence between the comment and the fence cancels it.
- Survives the build: the research probe appended a probe extra with the comment directly above a fence, and a second with a blank line before the fence, to the real 33 extras and ran the ExDoc 0.40.4 build with `--warnings-as-errors` (clean). Both comments appear in the HTML as `<!-- ... -->` immediately before `<pre><code class="makeup elixir">`, both fences render as code blocks, and the comment text is not visible. How hex.pm renders it is not verified (the README already carries an HTML `<picture>` block hex.pm handles, so a standard renderer is expected to hide comments).
- In use today: no marker ships. `grep -rn 'snippet-intentionally-differs' README.md guides` prints nothing; the schema and config fences are byte-identical in both files (`SnippetParity.check/3` returns `:identical` for both kinds).
- Proof it can fail: `test/release/snippet_parity_contract_test.exs` plants identical, different, marked on either side, empty-reason (bare, colon, blank), blank-line gap, a sentence between marker and fence, a fence without `use Scrypath,`, and a missing fence on each side. A mutation of the golden path in memory returned `{:error, :differs}`.
- Not proven: hex.pm rendering of the comment, and the website's code block, which is not an Elixir fence (Phase 194 decides).

## Forbidden-phrase seed

`test/support/release/forbidden_phrases.json` plus `Scrypath.Release.ForbiddenPhrases` (GUARD-03). Sources, copied and not imported: `brand/BRAND.md` (Do not say), `GLOSSARY.md` (avoid entries), `scrypath_ops/test/support/copy_rules.json` (field names and the `control-room-casing` row), and the two lists the README tests kept in Phase 192.

| Rule | Phrases | Scope | Source |
|------|---------|-------|--------|
| `time-promise` | the ten phrases of the old README list | README and guides | README-02 (Phase 192) |
| `brand-hype` | `effortless(ly)`, `just stays in sync`, `real-time`/`realtime`/`real time`, `AI-powered`, `playbook` | README and guides | `brand/BRAND.md` |
| `brand-technical-readme-only` | `magic`, `magical`, `federated`, `federation`, `hydration`, `hydrate` and kin | README only, with a recorded reason | `brand/BRAND.md`; `GLOSSARY.md` |
| `glossary-names` | `Control Room` (case-sensitive), `Sync and drift` | README and guides | `GLOSSARY.md`; `copy_rules.json` |

Result at the Task 3 commit: zero offenders over the 27 targets (README plus 26 guides, fences masked), the same as the research scan. Nothing was reworded and nothing was allowlisted; the table has no allowlist.

Excluded on purpose (also in the data file's `not_covered`):

- `magic`, `federated`, `hydration` in guides: 6, 26 and 21 prose lines of technical or negated use (the `[:scrypath, :hydration]` event, the `federation_weight:` option, "not one magical global index"). Scoping them to the README is the recorded decision; rewording would touch a public option's prose and a telemetry contract page.
- `accepted work`: never banned; contract tests pin it across README and guides, and a test fails if the data file ever lists it.
- `last successful` (glossary rule `last-succeeded`): its source scope is `scrypath_ops/lib/**`, and `guides/operator-mix-tasks.md:28` uses it, so it is not seeded.
- UI-only status words (Searchable, Last success, Healthy, Pending versus queued, Retry accepted): scoped to the operator UI source, not to docs.
- `docs/*.md`, `ARCHITECTURE.md` and `CONTRIBUTING.md` are extras but out of scope (Pitfall 8: `ARCHITECTURE.md` has "instantly visible" in a negation; `docs/jtbd-gap-map.md` has "quickly").
- Unsourced marketing words (`seamless`, `blazing`, `powerful`): no source in the three files.

Choices beyond the seed: a literal's spaces match a run of blanks or one line break, so a hard-wrapped sentence is caught; regex and literal patterns are both wrapped in word boundaries by the scanner; `rules/1` raises on an unknown id so a renamed rule cannot silently empty a caller's list; a faithfulness test splits the first sentence of the `Do not say` paragraph in `brand/BRAND.md` and requires the same eight terms as the table's `source_terms`.

Review-fix pass (code review WR-01, WR-02, IN-01):

- Fences are paired line by line in `Scrypath.Release.SnippetParity.fences/1` (WR-01): any indent, three or more backticks or tildes, any info string (`html+eex`, `json5`, a titled fence), closed by the same character at least as long; `lang` is the first word of the info string. The earlier matcher saw only a plain lowercase info string, so one other opening line inverted the pairing and the phrase scan silently skipped the prose between two blocks. A fence that is never closed now raises with the path and line, and a real-file test counts fence-looking lines (including after a blockquote marker) against the fences found. Not recognised, and caught by that count: a fence inside a blockquote or after a list marker.
- The phrase scan reads `Path.wildcard("guides/*.md")`, not the docs extras (WR-02), because `package.files` ships the whole `guides` directory; a test names any guide that is not a docs extra, and the non-vacuity floor compares the scan with the directory listing instead of a number computed from the same list.
- The `time-promise` phrase count is a floor (`>= 10`, IN-01); the no-weakening test still plants each of the ten phrases the README tests banned before. The first sidebar group and the group count read `@sidebar_groups`; the count "six" is pinned once, in the test named for it.

Interaction with the ops copy rules (found by the local ops-ui mirror, fixed in `054207d7`): `scrypath_ops/test/support/copy_rules.json` forbids the title-case `Control Room` name in every tracked file (`source_scope` `**`), and the phrase table has to carry that name as data. The data file joins `exempt_paths` beside the rule table itself (the table-file precedent from Phase 190), and the contract test builds the name by concatenation, as the ops copy-rules test does. Revisit when either table moves or the ops scan gains a different way to quote a banned phrase on purpose.

Accepted as is (code review IN-03, decided in the review-fix pass). The review suggested writing the data entry as `"Control Room"` (the JSON escape) and dropping the exemption, so the ops scan keeps covering the table. Kept the exemption instead, for these reasons: it is path-scoped to one data file, `exempt_paths` already holds the sister table `scrypath_ops/test/support/copy_rules.json` and whole directories (`.planning/`, `brand/`) on the same precedent, and today only `control-room-casing` has `source_scope: ["**"]`, so the practical loss is that one rule not reading this one file, whose two occurrences are the banned name quoted as data on purpose. An escaped name would hide the string from the scan by trickery instead of by a recorded exemption, and would make the table harder to read. The exemption is a prefix match (`String.starts_with?/2`), so a path that begins with the same string is exempt too; no such path exists. The revisit trigger above stands, with one addition: revisit when a second ops rule gains `source_scope: ["**"]` and should read the table.

Proof it can fail: planted time promise in README and in a guide; a README-only term fails in README and passes in a guide; a fenced phrase is not reported and later lines keep their true number; each of the 18 phrases the README tests banned before is planted in an in-memory README. A real-file mutation (a banned sentence appended to `README.md` and `guides/overview.md`, then reverted with `git checkout` of those two files) failed the real-file scan with `README.md:113` and `guides/overview.md:22` and failed both rewired README tests.

Not proven: that unlisted wording is fine, that the guides read in the brand voice, and that a phrase split by markup (a link or emphasis in the middle) is caught.
