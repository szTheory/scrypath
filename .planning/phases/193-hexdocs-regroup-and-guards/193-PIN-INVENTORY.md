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
| `install-line` owner-map HexDocs cell | claim | stays with owner `README`; the cell now names the guard | `test/release/install_line_contract_test.exs` | replaces "Phase 193 GUARD-02 guards parity" | 02 Task 1 | pending |
| built-docs link scan (TRUTH-03) | wiring | stays, no code change | `BuiltDocsBrandTest` (see GUARD-01 evidence) | none; the source rule beside it is new | 02 Task 1 | pending |

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

What the two together do not prove:

- External link liveness (no network call is made).
- Own-docs URLs built by interpolation, such as the versioned package links in `mix.exs` (`@release_docs_url`), which are versioned on purpose and pinned by the package-metadata test.
- The website's own HexDocs links: `website/` is not a shipped file.
- That a page's fragment exists for a link written in a non-extras shipped file (`docs/jtbd-gap-map.md`, `CHANGELOG.md`, `SECURITY.md` hold no HexDocs links to extras pages today).

## Install line occurrences

`Scrypath.Release.InstallLine` (GUARD-02) read 140 files (the shipped files plus the website sources that exist) at `mix.exs` version `0.3.20`. Real scan, plan start HEAD `bbe9891e`:

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

- A requirement must equal the same-length prefix of the version's `[major, minor, patch]` and `Version.match?/2` must hold. `~> 0.2` is satisfied by 0.3.20 and `~> 0.3` by 0.4.0, so satisfaction alone would catch neither.
- The pattern also reads a tuple with trailing options, such as one with `only: :dev`, so a stale line cannot hide behind them.
- Minor-bump consequence (accepted, CONTEXT research resolution): at a bump from 0.3.x to 0.4.0 the contract test goes red on four shipped files plus `website/scripts/build.mjs` until the install lines move. The fix is one commit on the bot-authored release PR, written up under "Minor version bumps and the install-line guard" in `docs/releasing.md`.
- Known foot-gun, not pre-handled: `CHANGELOG.md` is a shipped file. If release-please history ever quotes an old install tuple in a commit message, the guard fails on that line. Fix it by rewording the commit message or by adding a named exemption with a reason; no exemption was added in advance because none is needed today.
- Not covered: prose that names a series without a tuple (the golden path's minor-series sentence) and the website's rendered install block.
