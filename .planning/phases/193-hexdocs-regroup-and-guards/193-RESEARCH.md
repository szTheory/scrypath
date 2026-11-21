# Phase 193: HexDocs regroup and guards - Research

**Researched:** 2026-11-21
**Domain:** ExDoc sidebar grouping (`mix.exs` `groups_for_extras`), shrinking a guide that many contract pins read, and four mechanical docs guards (link check, install line, snippet parity, forbidden phrases) built as ExUnit contract tests. No library behavior changes.
**Confidence:** HIGH for in-repo facts (every file below was opened this session, scans and builds were run, ExDoc behavior was read from the pinned dependency source and reproduced with probe builds); MEDIUM for the guard designs (prototyped for the install line and the phrase table, not yet written as Elixir test code); LOW only where tagged `[ASSUMED]`.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Sidebar grouping (DOCS-01)**
- Groups, in sidebar order: Getting started, Guides by task, Phoenix, Operate and recover, Project policy, Maintainers. The names are the maintainer's own examples in DOCS-01, extended by keeping the existing Phoenix group as its own job-named group.
- First group (Getting started, five items): `README.md`, `guides/golden-path.md`, `guides/getting-started.md`, `guides/overview.md`, `guides/meilisearch-concepts.md`. The golden path is the one start page; `getting-started.md` already links to it and a test pins that link.
- Guides by task: jtbd-and-user-flows, request-edge-search, composing-real-app-search, related-data-and-reindexing, multitenancy, common-mistakes.
- Phoenix: unchanged six guides.
- Operate and recover: sync-modes-and-visibility, drift-recovery, meilisearch-operations, operator-mix-tasks, relevance-tuning, per-query-tuning-pipeline, telemetry, ARCHITECTURE.md.
- Project policy: support-and-compatibility, scope-and-reopen-policy, outside-adopter-intake.
- Maintainers: unchanged five files.
- `extras` order is left alone except where ExDoc needs nothing; no guide is renamed, merged or deleted. — **Reversibility:** costly — group membership is cheap to edit, but renaming or removing a guide changes a public HexDocs URL, so this phase does neither.

**guides/overview.md fate (DOCS-02)**
- Shrink it to about half a page and keep it in `extras`: drop the 22-row table (the sidebar is the index) and keep the recommended reading order and the two example links. The file name and page URL stay. — **Reversibility:** one-way for the alternative: dropping it from `extras` ends the `overview.html` page in future HexDocs versions, and the README, the `Scrypath` moduledoc, the owner map and eleven contract assertions point at it. Shrinking keeps every inbound link live.
- Plan 01 starts with an inventory of every assertion that pins overview content (`docs_contract_test`, `phase112_contract_test`, `package_metadata_test`, the owner-map rows `guide-routes` and `examples`, the README onward link). Each pin is carried to the shrunk page, moved to the guide that now owns the claim, or retired with a recorded reason; none is weakened to reach green.
- The decision and its reason are recorded in the phase artifacts and in `CLAIM-OWNER-MAP.md`.

**Link check (GUARD-01)**
- Extend the existing built-docs scan in `test/release/package_metadata_test.exs` (TRUTH-03; one docs build in `setup_all`, runs in `core` and `mix verify.package`). No new job, no new required check, no second docs build. The README is already scanned because it is the `readme.html` extras page.
- Plan 01 or 02 first checks which of the success-criterion cases the scan already proves (a planted self-link, a planted dead target, a dead anchor) and adds only what is missing, with in-memory planted cases. The non-vacuity floor stays.

**Install line (GUARD-02)**
- A small pure scanner under `test/support/release/` (the `ShippedDocs` and `PackageContract` pattern) reads every `{:scrypath, "~> ..."}` occurrence in the files of `mix.exs` `package.files` plus the website source if present, and asserts each requirement is a prefix of the `mix.exs` version series (so `~> 0.2` fails at 0.3.x) and that the version satisfies it. It reads `mix.exs` at test time, so a Release Please bump cannot leave a stale line. In-memory planted cases prove it can fail.
- Reversible: a test and its support module only.

**Duplicated blocks and banned wording (GUARD-03)**
- Schema snippet parity: compare the first Elixir fence containing `use Scrypath,` in `README.md` and `guides/golden-path.md` byte for byte, unless the later one carries an explicit `intentionally differs` marker with a reason (an HTML comment immediately above the fence). Plan 02 checks that the marker survives the ExDoc build before using it; if it does not, the marker lives in a visible sentence.
- Forbidden-phrase table: a small data file under `test/support/` plus one test that scans `README.md` and every guide in `extras`. It starts from `brand/BRAND.md`, the glossary and `scrypath_ops/test/support/copy_rules.json`, copied, not imported (a small copy beats a cross-project dependency). The table starts green: a phrase already in shipped text is fixed in the same plan by rewording, never allowlisted silently. In-memory planted phrases prove it can fail in README and in a guide.
- CONTRIBUTING.md gets a short same-PR rule: a change to a public-surface claim updates the other owning surfaces named in `.planning/reference/CLAIM-OWNER-MAP.md` in the same PR. A test pins that the rule text exists.
- `CLAIM-OWNER-MAP.md` rows that said "Phase 193 guards this" are updated to name the guard.

**Shipping and verification**
- Docs-only plus tests; no `lib/` change. PR-first; the orchestrator ships (push, PR, squash-merge on green required checks). No Hex release in this phase.
- Pre-push mirrors: `scripts/ci/pre_push.sh`, `mix format --check-formatted`, the focused test files, `mix docs --warnings-as-errors`, `mix verify.core --exclude integration --exclude docs_contract`, the `docs_contract`-tagged files that pin overview and the sidebar, and `mix verify.package`. The Docker browser lanes read none of `guides/`, `mix.exs` groups or these tests, so a local mirror of them is optional with the reason recorded (CI-EFFICIENCY finding 22). `mix.exs` is outside the classifier allowlist, so hosted CI runs every lane; budget about 14 to 19 minutes.

**Decided autonomously (recorded in CONTEXT)**
- [Sidebar] Q: "Where does ARCHITECTURE.md go?" → Selected: "Operate and recover, where it already sits under Operations" — one-line edit to undo
- [Sidebar] Q: "Keep Phoenix as its own group?" → Selected: "Yes, six guides, already job-named" — group membership is one edit in mix.exs
- [Sidebar] Q: "Which fifth item fills the first group?" → Selected: "meilisearch-concepts, because the README says a Meilisearch server is required" — swapping an item is one edit and one test line
- [Link check] Q: "New test file or extend the TRUTH-03 scan?" → Selected: "Extend the existing scan so the docs build runs once" — moving a test is cheap
- [Guards] Q: "Where does the scanner code live?" → Selected: "test/support/release/ as pure functions with in-memory planted cases" — test-only code, nothing public
- [Guards] Q: "Forbidden-phrase table format?" → Selected: "a small data file read by one test, copied from the brand and copy-rules sources" — test-only, edit in place
- [Install line] Q: "Compare to the exact version or the series?" → Selected: "the series prefix plus a satisfies check" — a test assertion only

### Claude's Discretion
Exact wording of the shrunk overview, the CONTRIBUTING rule and the banned-phrase list (subject to the brand voice sources); the test file and module names; whether the GUARD-01 gap fill needs any change at all once the existing scan is read.

### Deferred Ideas (OUT OF SCOPE)
- Website content and the website's own install line and snippet parity (Phase 194, cut at the checkpoint if traffic is near zero).
- Merging or renaming guides (needs adopter evidence; filenames are URLs).
- A Hex release carrying the regroup (maintainer's explicit yes).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOCS-01 | Sidebar regrouped, first group at most five, named by job, golden path is the one start page, no guide renamed/merged/deleted, `mix docs` no warnings, every extra in exactly one group (tested) | "ExDoc behavior (verified)" (group order, within-group order = `extras` order, missing/duplicate/dangling are silent); "Group-shape pins"; probe of the planned groups: 33 extras, 33 unique members, built with `--warnings-as-errors`, no group empty; "Validation Architecture" tests T1-T3 |
| DOCS-02 | Fate of `guides/overview.md` decided and recorded; no shipped link to a dead page | "Overview pin inventory" (11 assertion calls plus 4 non-test inbound references, each with a fate); shrunk-page skeleton; the one-line `lib/scrypath.ex` conflict with "no lib/ change" (Open Question 2) |
| GUARD-01 | Link check over built docs and README; self-links fail | "What TRUTH-03 already proves" (all three planted cases and the README are covered with line references); remaining gap is small and optional |
| GUARD-02 | Install line equals the `mix.exs` version wherever it appears | "Install line occurrences" (4 shipped + 1 website script + 1 placeholder); prototype run; `Version.match?("0.3.20", "~> 0.2")` is `true`, so the prefix check is required |
| GUARD-03 | Duplicated blocks guarded by data; forbidden-phrase table; CONTRIBUTING same-PR rule | "Snippet parity" (already byte-identical and already tested in `readme_contract_test.exs`; marker survives the ExDoc build); "Forbidden-phrase seed table" (green today, offenders listed); CONTRIBUTING rule draft |
</phase_requirements>

## Summary

Most of what Phase 193 asks for is a small delta on top of Phase 192, and three facts change the plan. (1) The GUARD-01 link check already exists and already proves every success-criterion case: `test/release/package_metadata_test.exs` scans every extras page of the one docs build, plants a self-link, a dead page, a dead anchor, and the HexDocs-URL forms of each into `readme.html`, and has non-vacuity floors. The real build has zero problems on extras, module and task pages. GUARD-01 therefore needs a traceability record and, at most, optional hardening; no new test is required to satisfy the criterion. (2) The README half of GUARD-03 also already exists in `test/scrypath/readme_contract_test.exs`: a schema-snippet parity test with an `intentionally differs` marker (no reason field, README side only), a time-promise list, and the brand "do not say" list scoped to README prose. Plan 02's real work is to move those lists and the fence helpers into one shared data table and pure module, extend them to the guides, add the reason requirement, and add planted cases. (3) ExDoc builds in the shipped `mix.exs` order: the sidebar order inside a group is the `extras` list order, not the `groups_for_extras` list order (verified by build). With `extras` untouched, the first group renders as README, Guides, Getting Started, Golden path, Meilisearch concepts, so the golden path ("the one start page") appears fourth; in "Guides by task", `common-mistakes` renders before `jtbd-and-user-flows`. ExDoc emits no warning for an extra in no group (it lands in an unnamed group at the top of the sidebar), an extra in two groups (first group wins) or a group entry that names no extra, so the exact-one-membership test is the only guard.

The overview shrink is safe if its pins are carried, and all but one pin carry unchanged. Eleven assertion calls in three test files read `guides/overview.md`; the shrunk page keeps their tokens if it keeps the reading order (nine existing items plus one new "Common mistakes" item so the jtbd-before-common-mistakes order pin stays verbatim) and the two example links. One inbound claim goes false with the shrink and is outside the test net: `lib/scrypath.ex:13` calls the page a "table of contents for every published guide", and `README.md:111` says it "indexes every guide". Both need a one-line reword; the first is a moduledoc line, which sits in tension with "no `lib/` change" (Open Question 2).

Nothing needs a new dependency, a new CI job or a new gate-ledger row. New untagged tests ride `core`; tests added to `package_metadata_test.exs` also ride `package`.

**Primary recommendation:** Plan 01: inventory first, then regroup `mix.exs` (and reorder `extras` to match the group lists, Open Question 1) with the config-shape test, a built-sidebar test and the `package_metadata_test` pin edits in one commit; then shrink overview with its carried pins, the README and moduledoc rewords and the owner-map rows in a second commit. Plan 02: record that GUARD-01 is already met, add `Scrypath.Release.InstallLine` (series prefix plus `Version.match?/2`, reads `website/scripts/build.mjs` because the website source only holds `{{CANONICAL_INSTALL}}`), generalize the existing README parity and phrase tests into shared pure modules with planted cases, add the CONTRIBUTING rule, and update the three owner-map rows that mention Phase 193.

## Project Constraints (from CLAUDE.md)

No `CLAUDE.md` exists; `AGENTS.md` is the project instruction file and carries the same authority. Actionable directives for this phase:

- Run `mix` with `export ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5` (project memory and every probe below).
- Squash titles are `docs(...)` or `chore(...)`, never `feat` or `fix` (GATE-03); no new required gate (ledger stands at 10 of 12, `CONTRIBUTING.md` "Budget used: 10 of 12."); no Hex release without the maintainer's explicit yes.
- Pre-push confidence: before pushing, run each required lane's local mirror on the committed head and record which part could not run and why; cheap consistency checks first; a fix to a snapshot-based gate is committed before the gate reruns.
- No human UAT: every success criterion is an executable check; never claim more than the automated evidence proves (the grouping matching how readers look for things stays unproven; AGENTS.md "Phase 185 verification correction").
- Prefer a small copy over a new dependency; keep dependency trees flat (no package is added here).
- Plans must not contain the three human-verification markers named in `test/scrypath/no_human_gates_contract_test.exs:4-8` (the test scans every incomplete `*-PLAN.md` in the `repository-contracts` lane).
- Unrelated dirty `.planning/config.json` and `.planning/state.json` edits stay out of owned commits (STATE.md "Blockers/Concerns").
- Update `.planning/PROJECT.md` only when product scope or shipped claims intentionally change; this phase changes neither.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Sidebar structure (which page is in which group) | `mix.exs` `docs/0` (`extras`, `groups_for_extras`) | built `dist/sidebar_items-*.js` | ExDoc reads only these two keys; the build output is the proof of what a reader sees |
| Exactly-one membership, group order, first-group cap | Test layer, `Scrypath.Release.PackageMetadataTest` (config shape, pure) | `Scrypath.Release.BuiltDocsBrandTest` (built sidebar, reuses the one docs build) | ExDoc warns about none of the failure modes; the config test is fast, the built-sidebar test proves ExDoc's actual outcome and also covers regex group patterns |
| Link integrity of built docs and README | Existing TRUTH-03 scan in `BuiltDocsBrandTest` | `ShippedDocs` source-level link rule | Already complete for extras; the README is the `readme.html` extras page |
| Install line parity | New pure scanner in `test/support/release/` + one contract test (`core`) | `mix.exs` version read at test time | A release bump changes `@version` only, so the check must read it live |
| Schema snippet parity and the "intentionally differs" marker | Pure helper in `test/support/release/` + contract test | `readme_contract_test.exs` (existing README-02 tests become callers) | One definition of "first Elixir fence containing `use Scrypath,`" instead of two copies |
| Forbidden wording | Data file in `test/support/release/` + pure scanner + one contract test | `brand/BRAND.md` drift check | Data, not discipline; the table records its source and scope per rule |
| Claim ownership and the same-PR rule | `CONTRIBUTING.md` text + owner-map row pinned by the existing owner-map shape test | `.planning/reference/CLAIM-OWNER-MAP.md` | The map machinery already fails the default run if an owner stops carrying its token |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ExUnit (Elixir 1.19.0 / OTP 28.5 via asdf) | stdlib | All guards are contract tests | Whole repo; `mix test` printed `242 tests, 0 failures` on the 13 existing doc-pin files [VERIFIED: run] |
| ExDoc | 0.40.4 | Source of grouping behavior and the build the tests scan | `mix.lock:16` `"ex_doc": {:hex, :ex_doc, "0.40.4", ...` [VERIFIED: mix.lock:16] |
| `Version` (Elixir stdlib) | stdlib | `Version.match?/2` for the satisfies half of GUARD-02 | `Version.match?("0.3.20", "~> 0.2")` returned `true`; `Version.match?("0.4.0", "~> 0.3")` returned `true` [VERIFIED: run] |
| Jason | `{:jason, "~> 1.4"}` (runtime dependency) | Decode the forbidden-phrase JSON data file and the built sidebar JS payload | `mix.exs:124` [VERIFIED: mix.exs:124]; already used by tests |
| `Scrypath.Release.ShippedDocs` | in repo (574 lines) | `shipped_files/0`, `markdown_links/1`, `units/1`, `links_to_guide?/2` | `test/support/release/shipped_docs.ex`; reuse, do not duplicate |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Regex`, `Path`, `File`, `String` | stdlib | Scans | Same method as the existing built-docs scan |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Regex over built HTML and markdown | Floki, `lazy_html`, Earmark | New dependency; house rule is copy over dependency; the existing scan already uses regex successfully on 1,360 extras hrefs |
| Reimplement ExDoc group matching in the config test | Read the built `sidebar_items-*.js` | The built payload also covers regex group patterns and cannot disagree with ExDoc; keep a small config test for speed and planted cases |
| JSON data file | Elixir `.exs` data | JSON matches `copy_rules.json` field names (`text`, `match`, `case`) so a later shared lint (CAT-01) can read both; `.exs` avoids backslash escaping |

**Installation:** none. No package is added.
**Version verification:** no new package; ExDoc 0.40.4 read from `mix.lock`; Jason from `mix.exs`.

## Package Legitimacy Audit

No external packages are installed or recommended by this phase. Nothing to audit.

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
mix.exs docs/0
  extras (33 paths, build order)            groups_for_extras (6 named groups, keyword order)
        |                                              |
        +----------------------+-----------------------+
                               v
              ExDoc 0.40.4  (Extras.build: match_extra -> group | nil;
                             stable sort by group index; nil -> -1 = first, unnamed)
                               |
            +------------------+-------------------+
            v                                      v
   built pages (extras: data-type="extras")   dist/sidebar_items-*.js  (id, title, group per extra)
            |                                      |
   TRUTH-03 link scan (existing, GUARD-01)    NEW built-sidebar test (every extra in its configured group,
   self-link / unresolved / dead anchor        none in group "" except api-reference, first group <= 5)
   own-docs HexDocs URLs read as build pages

   MIX_PROJECT config (pure)                  repo files (pure reads, no build)
        |                                          |
   NEW config-shape test                  +--------+----------+-----------------------+
   names+order, first group <= 5,         v                   v                       v
   exactly-one, no dangling,        InstallLine scanner  SnippetParity helper  ForbiddenPhrases scanner
   planted problems                 (package.files +     (README vs golden      (README + guides/*.md extras;
                                    website/scripts/     path; marker + reason) data: JSON table)
                                    build.mjs; Version)
                                            |                   |                       |
                                            +---------- contract tests (untagged -> `core`) ----------+
                                            package_metadata_test additions also run in `package`
```

### Recommended Project Structure
```
mix.exs                                            # groups_for_extras (+ extras order, Open Q1)
guides/overview.md                                 # shrunk: reading order + two example links
test/release/package_metadata_test.exs             # config-shape + built-sidebar tests (replace :108-125 pins)
test/release/install_line_contract_test.exs        # NEW, GUARD-02 (name is discretionary)
test/release/forbidden_phrases_contract_test.exs   # NEW, GUARD-03 phrases (name is discretionary)
test/support/release/install_line.ex               # NEW pure scanner, Scrypath.Release.InstallLine
test/support/release/snippet_parity.ex             # NEW pure helper (fence finder + marker + parity)
test/support/release/forbidden_phrases.ex          # NEW pure scanner
test/support/release/forbidden_phrases.json        # NEW data table
test/scrypath/readme_contract_test.exs             # existing README-02 tests become callers of the shared modules
CONTRIBUTING.md                                    # same-PR rule
.planning/reference/CLAIM-OWNER-MAP.md             # guard names, overview decision
.planning/phases/193-hexdocs-regroup-and-guards/193-PIN-INVENTORY.md   # Plan 01 task 1 (draft below)
```
Support `.ex` files under `test/support/` are required by `test_helper.exs` (`"test/support/**/*.ex" |> Path.wildcard() |> Enum.each(&Code.require_file/1)`), so a new module needs no registration. A `.json` file there is not loaded and is not a test file (`support_file?/1` in `mix.exs` ignores non-`_test.exs` files under `test/support/`) [VERIFIED: test/test_helper.exs, mix.exs:189-191].

### Pattern 1: Config-shape check as a pure function with planted problems
**What:** `docs_group_problems(extras, groups)` returns a list of `{kind, detail}`; the real test asserts `[]`, planted tests assert each kind.
**Kinds:** `:missing_from_groups` (an extra in no group), `:in_several_groups`, `:dangling_member` (a group entry that is not an extra), `:first_group_too_long`, `:group_order`, `:non_string_member` (regex patterns are not supported by the pure check; the built-sidebar test covers them).
**Example:**
```elixir
# Sketch (not yet written). Source of the data: Scrypath.MixProject.project()[:docs]
defp docs_group_problems(extras, groups) do
  members = Enum.flat_map(groups, fn {_name, list} -> list end)
  freq = Enum.frequencies(members)

  for(extra <- extras, not Map.has_key?(freq, extra), do: {:missing_from_groups, extra}) ++
    for({path, n} <- freq, n > 1, do: {:in_several_groups, path}) ++
    for(path <- Map.keys(freq), path not in extras, do: {:dangling_member, path})
end
```

### Pattern 2: Built-sidebar test inside the one existing docs build
**What:** read `dist/sidebar_items-*.js` from the `setup_all` build, strip the `sidebarNodes=` prefix, `Jason.decode!`, and assert per extra that the rendered `group` equals the configured group and that only `api-reference` has group `""`. The probe in this research used exactly that parse [VERIFIED: probe run; the file is `dist/sidebar_items-43C9376C.js` in the scratch build].
**Why:** it catches the three silent ExDoc failures end to end, also proves group names with spaces survive, and costs no extra build (`BuiltDocsBrandTest` `setup_all` at `package_metadata_test.exs:262-278`).

### Pattern 3: Pure scanners with in-memory planted cases (house pattern)
`ShippedDocs.scan/3` and `shipped_docs_contract_test.exs` ("planted cases (in-memory strings only)", `:257`) are the template: pure function, real-file zero assertion, planted failing and passing strings, non-vacuity floors, no shipped file edited.

### Anti-Patterns to Avoid
- **Asserting only list equality for groups.** `==` on a list (as `package_metadata_test.exs:108-125` does) pins an order that does not affect rendering and says nothing about missing, duplicate or dangling entries.
- **A hand-copied matcher for ExDoc grouping.** Use the built sidebar for the end-to-end proof.
- **Scanning module pages for self-links.** ExDoc autolinks a module name inside its own docs (4 legitimate hits on module pages) [VERIFIED: scan run over the scratch build].
- **Allowlisting a banned phrase silently.** CONTEXT: reword, or scope the rule with a recorded reason in the data file.
- **A second `Mix.Tasks.Docs.run/1` in the same VM.** Put every built-docs test in `BuiltDocsBrandTest` (Phase 192 Pitfall 8).

## ExDoc behavior (verified)

All from `deps/ex_doc` (0.40.4) and probe builds into the scratch directory with `Mix.Tasks.Docs.run(["--output", out, "--warnings-as-errors"], modified_config)` [VERIFIED: runs]:

| Question | Answer | Evidence |
|----------|--------|----------|
| Group order in the sidebar | The keyword order of `groups_for_extras`. | `deps/ex_doc/lib/ex_doc/extras.ex:28` `\|> Enum.sort_by(fn extra -> Config.index(groups, extra.group) end)`; `config.ex:233-235` `Enum.find_index(groups, fn {k, _v} -> k == group end) \|\| -1`; probe order matched the keyword order |
| Order of pages inside a group | The `extras` list order (stable sort), not the order of the group's own list. | Probe with the planned groups: "Getting started" rendered `readme, overview, getting-started, golden-path, meilisearch-concepts`; "Guides by task" rendered `common-mistakes, request-edge-search, composing-real-app-search, jtbd-and-user-flows, related-data-and-reindexing, multitenancy`; the group lists in CONTEXT order them differently |
| Group names with spaces | Fine. A quoted keyword key becomes the atom, ExDoc does `to_string/1`. | `config.ex:126-128` `for {k, v} <- groups, do: {to_string(k), v}`; probe sidebar JSON carried `"Getting started"`, `"Guides by task"`, `"Operate and recover"`, `"Project policy"` |
| An extra in no group | Builds without warning; `group` is `nil`, index `-1`, so it sorts before every named group and renders under an empty group name just after "API Reference". | Probe "missing" (removed `guides/multitenancy.md` from every group): sidebar `[""] api-reference`, `[""] multitenancy`, then the named groups; build result `""` (no error) with `--warnings-as-errors` |
| An extra in two groups | First group in keyword order wins, no warning. | `config.ex:263-268` `Enum.find_value(group_patterns, fn {group, patterns} -> ... Enum.any?(patterns, matcher) && group end)`; probe "dup": `support-and-compatibility` rendered only under "Getting started" |
| A group entry that names no extra | Silently ignored. | Probe "dangling" built clean (34 sidebar entries) |
| Link to a `.md` whose basename is not an extra | Warning `documentation references file "<link>" but it does not exist`; fatal under `--warnings-as-errors`. Resolution is by **basename**. | `autolink.ex:222` `file = config.extras[Path.basename(path)] ->`; `autolink.ex:605` `message = "documentation references file \"#{original_text}\" but it does not exist"`; the probe with a reduced extras list produced dozens of these warnings |

Consequences: (a) dropping `overview.md` from `extras` would turn the `lib/scrypath.ex:13` moduledoc link into a fatal warning and the README's `https://hexdocs.pm/scrypath/overview.html` link into an `:unresolved` finding of the existing scan, so the shrink decision is also the safe one; (b) the basename rule is the origin of the `README.md` collision (any `…/README.md` relative link resolves to the root README page); the Phase 192 source-level rule in `shipped_docs_contract_test.exs:470-533` keeps repo READMEs absolute.

## Group-shape pins (what must change with the regroup)

| Where | What it pins today | Fate |
|-------|--------------------|------|
| `test/release/package_metadata_test.exs:108-117` | `assert docs[:groups_for_extras][:Operations] == [ "ARCHITECTURE.md", "guides/drift-recovery.md", "guides/meilisearch-operations.md", "guides/operator-mix-tasks.md", "guides/relevance-tuning.md", "guides/per-query-tuning-pipeline.md", "guides/telemetry.md", "guides/sync-modes-and-visibility.md" ]` (verbatim). The key `:Operations` disappears. | Replace with the config-shape test; the same eight members live under `"Operate and recover"` (compare as sorted lists, since list order does not drive rendering) |
| `package_metadata_test.exs:119-125` | `assert docs[:groups_for_extras][:Maintainers] == [ "CONTRIBUTING.md", "docs/releasing.md", "docs/operator-support.md", "docs/search-backend-sre.md", "docs/local-demo-docker-dx.md" ]` (verbatim) | Stays true unchanged (Maintainers is unchanged); keep it, it is the only pin that survives as written |
| `package_metadata_test.exs:98-106` | `assert "<path>" in docs[:extras]` for 9 paths | stays (extras unchanged) |
| `test/scrypath/docs_contract_test.exs:1409-1412` | Title says "registered in ExDoc extras and Getting Started group (TNNT-01)" but the body is only `assert String.contains?(mix_exs, ~s("guides/multitenancy.md"))` | Retitle and make it assert the guide is in group `"Guides by task"` (it currently proves nothing about a group) |
| `docs_contract_test.exs:150` and `:259` | Comments: "Accepted gap: extras membership proves the guide ships, not that the sidebar groups it" | The new membership test closes this gap; update both comments |
| `guides/getting-started.md` h1 `# Getting Started`, pins `docs_contract_test.exs:532` (`Getting Started](getting-started.md)`) and `:658` (`Golden path](golden-path.md)`) | Page title and link text, not the group label | Unaffected: only the group label changes case; the page title stays |

No other reader of `groups_for_extras` exists: a repo-wide grep (excluding `node_modules`, `_build`, `deps`, archived milestones) found only `mix.exs:248` and the two `package_metadata_test.exs` lines, plus the test title above [VERIFIED: grep run]. Nothing in `scrypath_ops/`, `examples/`, `website/scripts/` or `scripts/ci/` reads group names or `overview`; the only `overview` hits outside the root are unrelated (`scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex:1717` a UI hint, `examples/phoenix_meilisearch/README.md:107` Phoenix's own page). Outside code does read guide **file names** (`scrypath_ops/lib/scrypath_ops/posture.ex:417` reads `guides/operator-mix-tasks.md` at runtime; `doc_resolver.ex`, `help_live.ex` link several guides; `website/src/pages/docs.html` links 12 by `blob/main/guides/<name>.md`), which is one more reason no guide may be renamed.

## Overview pin inventory (DOCS-02, Plan 01 task 1)

Eleven assertion calls in three files read `guides/overview.md` (CONTEXT's "eleven"), plus four inbound references that no test reads. Lines are current at HEAD `4c88ba8c`. Type: claim = asserts what the page says; wiring = asserts it is registered or exists.

| # | Where | What it pins (verbatim tokens) | Type | Fate after the shrink |
|---|-------|--------------------------------|------|-----------------------|
| O1 | `test/release/package_metadata_test.exs:103` | `assert "guides/overview.md" in docs[:extras]` | wiring | Stays. The page and URL stay |
| O2 | `test/scrypath/phase112_contract_test.exs:11,26`, consumed at `:98-101` | `@overview File.read!("guides/overview.md")`; `{"guides/overview.md", @overview}` in `@all_surfaces`; `assert_absent_patterns(content, @misleading_patterns, path)` for every surface | claim hygiene (no "AI-powered", "always current", "immediately searchable" ...) | Stays; re-run after the shrink (the new text is clean by construction) |
| O3 | `test/scrypath/docs_contract_test.exs:55` feeding `:96-121` | `"guides/overview.md"` in `@guide_paths` and so in `@published_markdown_for_hygiene`; no planning/task IDs in published markdown | hygiene | Stays |
| O4 | `docs_contract_test.exs:649-650` | `Enum.each(@guide_paths, &assert(File.exists?(&1), "expected guide #{&1} to exist"))` | wiring | Stays (file stays) |
| O5 | `docs_contract_test.exs:155-158` | overview contains `"[JTBD and user flows](jtbd-and-user-flows.md)"` and `"Canonical mental model"` (case-sensitive `String.contains?`) | claim: the overview exposes the jtbd guide as a first-class entry point | **Carry unchanged.** Keep reading-order item 2 as the existing row text: `[JTBD and user flows](jtbd-and-user-flows.md)` with the sentence starting `Canonical mental model: ...` (capital C) |
| O6 | `docs_contract_test.exs:160-164` | `ordered?(overview, "[JTBD and user flows](jtbd-and-user-flows.md)", "[Common mistakes](common-mistakes.md)")` | claim: mental model is listed before pitfalls | **Carry unchanged** by adding a tenth reading-order item `[Common mistakes](common-mistakes.md)` after the nine (the `Scrypath` moduledoc already lists it under "Read next"). Alternative: re-point to a structural assertion, but `extras` order puts `common-mistakes` before `jtbd-and-user-flows` today (see Open Question 1), so the alternative only works after the extras reorder |
| O7 | `docs_contract_test.exs:187` | overview contains `"[Request-edge search](request-edge-search.md)"` | claim | Carry (reading-order item 4) |
| O8 | `docs_contract_test.exs:219-223` | `ordered?(overview, "[Request-edge search](request-edge-search.md)", "[Composing real-app search](composing-real-app-search.md)")` | claim | Carry (items 4 then 5; keep the relative order) |
| O9 | `docs_contract_test.exs:262` | `assert_docs_extras([... "guides/overview.md" ...])` (list of 18 paths) | wiring | Stays |
| O10 | `docs_contract_test.exs:292` | overview contains `"examples/phoenix_meilisearch/README.md"` | claim (owner-map row `examples`) | Carry: keep the example paragraph; its absolute GitHub URL contains the token |
| O11 | `docs_contract_test.exs:293` | overview contains `"examples/scrypath_ecommerce/README.md"` | claim (owner-map row `examples`) | Carry (same paragraph) |

Owner map [VERIFIED: `.planning/reference/CLAIM-OWNER-MAP.md:35,46`]: row `guide-routes` has Owner `guide:overview` and Pinned by `guides/overview.md has drift-recovery.md` (still satisfied by reading-order item 9); row `examples` has Owner `guide:overview` and two overview tokens (satisfied by the kept example links). The owner-map shape test also requires `"guides/overview.md" in extras` for any `guide:overview` owner (`readme_contract_test.exs:130-133`). Recommended edit: `guide-routes` Owner becomes `doc:mix.exs` (the sidebar is the route index) pinned by `mix.exs has Guides by task`, and a new row `reading-order` (Owner `guide:overview`, pinned by `guides/overview.md has Recommended reading order`) keeps the page owning what it still says. The `doc:` owner check only needs `File.regular?("mix.exs")` and a literal substring (`readme_contract_test.exs:135-137,167-173`).

Inbound references no test reads:

| Where | Text today (verbatim) | Problem after the shrink | Action |
|-------|-----------------------|--------------------------|--------|
| `lib/scrypath.ex:13` | `- [guides/overview.md](guides/overview.md) — table of contents for every published guide.` | False: the page is a reading order, not a table of contents | One-line moduledoc reword (Open Question 2). No test pins the old wording (grep for "table of contents for every published guide" finds only this line) |
| `README.md:111` | `- The [guides overview](https://hexdocs.pm/scrypath/overview.html) indexes every guide, from sync modes to drift recovery.` | "indexes every guide" is false; the wording is not pinned | Reword, keep the link (the README caps onward links at 3, `readme_contract_test.exs:322-340`): for example "gives a recommended reading order; the sidebar lists every guide, grouped by job" |
| `mix.exs:217` and `:251` | `"guides/overview.md",` in `extras` and in the first group | none | stays in both |
| `.planning/reference/CLAIM-OWNER-MAP.md:3,21,26,35` | text naming "Phase 193" | stale after the phase | Update the three rows (see GUARD-02/03 sections) |

Content decisions for the page [`[ASSUMED]` wording, recommended]: keep `# Guides` (the sidebar title is the h1; changing it changes the sidebar label), a one-sentence purpose, `## Recommended reading order` with 10 items, the two-example paragraph, and one sentence that the sidebar groups every guide by job. Retire the "Crash Course" four-layer list and the 22-row table with recorded reasons: the layer claims are owned by `ARCHITECTURE.md` and `guides/getting-started.md` (owner-map rows `public-surface`, `quick-path`) and nothing pins them (grep for `declaration:`, `four layers`, `Crash Course` found no test hit) [VERIFIED: grep run]. Current size is 584 words; a target of about 250 words matches "about half a page" and is a chosen number, not a measured one. The shrunk page must keep passing the Phase 192 source-level link rule (relative targets resolve to extras; repo paths absolute).

## What TRUTH-03 already proves (GUARD-01)

Success criterion 3 asks that the link check passes on built docs and README and fails a planted self-link and a planted dead target. All cases exist in `test/release/package_metadata_test.exs` (module `Scrypath.Release.BuiltDocsBrandTest`, one `Mix.Tasks.Docs.run` in `setup_all` at `:262-278`):

| Case | Where proven (line) | Detail |
|------|---------------------|--------|
| Real build has no self-link, unresolved link or dead anchor | `:312-342` | scans `extras_pages(out)`; floor `@min_author_hrefs 500` (asserted `:322`; the build reads about 1,360) and at least 4 own-docs HexDocs links (`:332`) |
| README is covered | `:314-315` asserts a built page exists for every configured extra (README.md maps to `readme.html`); planted cases are inserted into `readme.html` (`:363,367`) | `README.md` is the first entry of `extras` (`mix.exs:214`) |
| Planted self-link | `:370` `planted.("readme.html") == [{"readme.html", "readme.html", :self_link}]`; HexDocs form `:394` | |
| Planted dead target | `:371` `no-such-page.html` is `:unresolved`; `:377` `../readme.html` (leaves the build) is `:unresolved`; HexDocs form `:391-392` | |
| Planted dead anchor | `:373-374` `golden-path.html#no-such-anchor` is `:dead_anchor`; HexDocs form `:388-389` | |
| Controls (must pass) | `:380-382`, `:395-397` | other page, real anchor, web link, another project's HexDocs page |
| Region discipline | `:399-404` a self-link after `</main>` is chrome; `:407` a `<link>` tag is not an `<a>`; `:410-412` a page without the extras region raises | |
| Missing extra page named | `:344-360` | |
| Unversioned own-docs URLs read as build pages | `@own_docs_href ~r{^https://hexdocs\.pm/scrypath/([^/]+\.html(?:[?#].*)?)$}` (`:248`) | verbatim |

Measured on a fresh test-env build (35 extras pages, 36 task pages, 34 module pages): 0 unresolved, 0 dead anchors on any page type; the only self-links are the 4 legitimate ones on module pages [VERIFIED: Python scan of the scratch build].

**Remaining gap (small, all optional):**
1. The own-docs matcher reads only `https://hexdocs.pm/scrypath/<page>.html[#frag]`. Shapes it does not read: `http://`, a version segment (`/scrypath/0.3.20/...`), and the bare root. The shipped files contain exactly: 7 page links (all in `README.md`), 1 bare root (`README.md:8` badge, `mix.exs:7`, `website/src/layout.html:73`), and 2 `X.Y.Z` placeholders in `docs/releasing.md:78,254` [VERIFIED: scan run]. Nothing today can hide behind the gap. A cheap hardening is a source-level rule in `shipped_docs_contract_test.exs` ("every `hexdocs.pm/scrypath` URL in README and extras is the root or `https://hexdocs.pm/scrypath/<page>.html`") with a planted versioned URL; skip it unless the maintainer wants it.
2. Module and task pages are not scanned (0 problems today; ExDoc already warns on broken module and extras references under `--warnings-as-errors`). Skip.
3. Non-extras shipped files (`docs/jtbd-gap-map.md`, `CHANGELOG.md`, `SECURITY.md`) hold no HexDocs links to extras pages [VERIFIED: scan]. Skip.

**Recommendation:** GUARD-01 needs no new code. Plan 02 records this table in the phase artifacts as the GUARD-01 evidence (criterion mapped to test and line) and says so plainly. DOCS-02's "no shipped link points at a dead page" is also already guarded for README and extras by the same scan.

## Install line occurrences (GUARD-02)

Prototype run: `{:scrypath,\s*"([^"]*)"\s*}` over `ShippedDocs.shipped_files()` (133 files) plus `website/scripts/build.mjs` and `website/src/**` [VERIFIED: run]:

```
version=0.3.20
README.md:45 "~> 0.3" -> {true, true}
docs/releasing.md:78 "~> X.Y.Z" -> :non_numeric
guides/golden-path.md:20 "~> 0.3" -> {true, true}
guides/outside-adopter-intake.md:21 "~> 0.3" -> {true, true}
guides/support-and-compatibility.md:17 "~> 0.3" -> {true, true}
website/scripts/build.mjs:139 "~> 0.3" -> {true, true}
```
(`{prefix_matches, Version.match?}`.) Findings:
- The website **source** (`website/src/pages/index.html:20`) holds `<code>{{CANONICAL_INSTALL}}</code>`; the literal lives in `website/scripts/build.mjs:139`: `const canonicalInstall = '{:scrypath, "~> 0.3"}';` [VERIFIED: website/scripts/build.mjs:139]. The scanner must read that file or the website is not covered. The same script already reads `@version` from `mix.exs` (`build.mjs:131-137`); making `canonicalInstall` derive from it would be a website code change (Phase 194 territory); asserting it from the test satisfies GUARD-02 now.
- `docs/releasing.md:78` has the placeholder `{:scrypath, "~> X.Y.Z"}`; the scanner must treat a non-numeric requirement explicitly (an exact placeholder allowlist keyed by path, with a reason), never skip silently, and fail on any other unparseable requirement. `dev/mix/tasks/verify.release_publish.ex:153` has `{:scrypath, "~> #{version}"}` but `dev/` is not in `package.files`.
- Prose that also states the series: `guides/golden-path.md:25` "The minor-flexible range matches published **0.3.x** releases"; historical upgrade notes (`guides/related-data-and-reindexing.md:259-261` "0.3.17", `guides/sync-modes-and-visibility.md:146` "0.3.15") must NOT be checked. The `**0.3.x**` phrase is an optional second pattern (`\*\*(\d+\.\d+)\.x\*\*`), flagged for the planner; the locked decision covers only `{:scrypath, "~> ..."}`.
- Semantics, verified: `Version.match?("0.3.20", "~> 0.2")` is `true` and `Version.match?("0.4.0", "~> 0.3")` is `true`, so satisfies alone neither catches `~> 0.2` nor forces an update at a minor bump. Rule: segments of the requirement number must equal the same-length prefix of `Version.parse!(version)` segments, and `Version.match?(version, requirement)` must hold. At a 0.3 to 0.4 bump this goes red on four shipped files plus `build.mjs` in the release PR; the release PR is bot-authored and has no CI until a human-authored event (AGENTS.md, ROADMAP guardrails), so the fix commit belongs in that PR. Given the patch-first pre-1.0 posture (`docs/releasing.md:12`, `release-please-config.json` `"bump-minor-pre-major": true`) a minor bump is rare; record it as the intended behavior (Open Question 7).
- Non-vacuity floors for the real scan: at least 4 shipped numeric occurrences, and at least 1 website occurrence when `website/` exists.

Planted cases (in-memory, house style): a guide line with `{:scrypath, "~> 0.2"}` fails (prefix); `~> 0.3` at version `0.4.0` fails; `~> 0.3` at `0.3.20` passes; `~> 0.3.20` at `0.3.20` passes; `~> X.Y.Z` in `docs/releasing.md` passes only through the named placeholder entry, in any other file it fails.

## Snippet parity (GUARD-03)

- **Today:** the first Elixir fence containing `use Scrypath,` is byte-identical in `README.md` (fence opens at line 60) and `guides/golden-path.md` (line 61): 275 bytes each [VERIFIED: Python comparison]. The config fence is also identical and already compared.
- **Already implemented in Phase 192** (`test/scrypath/readme_contract_test.exs`): `"the quick path schema snippet is identical to the golden path"` (`:234-247`), `"the README config snippet matches the golden path config snippet"` (`:266-274`), and the marker `@differs_marker "<!-- scrypath:snippet-intentionally-differs -->"` (`:37`, verbatim), applied by `differs_marked?/2` (`:544-549`: text before the fence, `String.trim_trailing`, `String.ends_with?(@differs_marker)`). Limits: the marker has no reason, only the README side may carry it, and no test proves the parity check can fail (it reads real files only). The helpers `fences/1`, `schema_fence/1`, `prose/1`, `word_pattern/1` are private to that file.
- **Marker survives the ExDoc build (the CONTEXT precondition):** a probe extra with `<!-- scrypath-parity: intentionally differs from README.md: shorter on purpose -->` directly above a fence, and a second comment with a blank line before the fence, appended to the real 33 extras and built with `--warnings-as-errors` (clean: no warning, no error): both comments appear in the HTML as `<!-- ... -->` immediately before `<pre><code class="makeup elixir">`, and both fences render as code blocks (no swallowed fence) [VERIFIED: probe build, ExDoc 0.40.4]. The comment text is present in the page source and in the `.md` and `llms.txt` outputs but is not visible text. So the CONTEXT marker (an HTML comment immediately above the fence) is usable; no visible-sentence fallback is needed. How hex.pm renders it is not verified (`[ASSUMED]`: a standard Markdown renderer hides HTML comments; the README already carries an HTML `<picture>` block that hex.pm handles).
- **Recommended shape:** one pure module (`Scrypath.Release.SnippetParity`) exposing `schema_fence/1` (first `elixir` fence whose body contains `use Scrypath,`), `config_fence/1`, `marker/2` (reads the text before the fence, tolerating blank lines as the current helper does) and `check(readme, golden)` returning `:ok` or `{:differs, why}`. Marker form: `<!-- scrypath:snippet-intentionally-differs: <reason> -->` with a non-empty reason, allowed above either fence. Change `differs_marked?/2` and `@differs_marker` in the same commit so the existing README tests become callers. Planted cases: identical passes; different without marker fails; different with marker and reason passes; marker with empty reason fails; marker with a blank-line gap still counts (or does not, whichever is decided, but state it); a fence without `use Scrypath,` is not the schema fence.
- **Website:** `website/src/pages/index.html:41-56` already holds a `use Scrypath,` block (the first four lines equal the schema's options) inside a `<pre><code>` that also shows search and sync calls; it is not an Elixir fence, so the parity guard does not apply. Phase 194 decides (CONTEXT: deferred).

## Forbidden-phrase seed table (GUARD-03)

**Sources read:** `brand/BRAND.md` "Do not say" (verbatim): `Magic, effortless, “it just stays in sync”, real-time (unless you measured it), federated, hydration, playbook, or “AI-powered”.` [VERIFIED: brand/BRAND.md "about scrypath: approved descriptions"]; `GLOSSARY.md` "Avoid" entries (`Sync and drift (former name)`, `hydration (in UI copy)`, `federated results, merged results`, `Playbook (except as the API and file-format name)`, UI status words); `scrypath_ops/test/support/copy_rules.json` (rows `control-room-casing` with `"source_scope": ["**"]`, others scoped to `scrypath_ops/lib/**`); and the two lists Phase 192 already put in `test/scrypath/readme_contract_test.exs`: `@time_promises` (`"in five minutes"`, `"in 5 minutes"`, `"in minutes"`, `"in a few minutes"`, `"in seconds"`, `"quickly"`, `"instantly"`, `"in no time"`, `"under five minutes"`, `"just works"`, `:22-33`) and `@brand_do_not_say` (`"magic"`, `"effortless"`, `"it just stays in sync"`, `"real-time"`, `"federated"`, `"hydration"`, `"playbook"`, `"AI-powered"`, `:65-74`), both applied to README prose only (`:276-286`, `:427-433`).

**Existing banned-phrase test elsewhere:** `phase112_contract_test.exs:98-101` runs `@misleading_patterns` (`ai-powered`, `ai search`, `vector search`, `hybrid search`, `automatic callbacks`, `always current`, `immediately searchable`, `public multi-backend support`, `:42-51`) over README, five website pages and eight guides or docs, with a `strip_allowed_negations/1` list (`:158-174`). It is a positioning check and stays as is.

**Scan result (prose outside fences, README plus all 26 `guides/*.md`; also with fences included):**

| Candidate | README | guides | Verdict |
|-----------|--------|--------|---------|
| time promises (the 10 phrases above) | 0 | 0 | seed, scope README + guides |
| `effortless(ly)`, `just stays in sync`, `real-time`/`realtime`, `AI-powered`, `playbook` | 0 | 0 | seed, scope README + guides |
| `Control Room` (case-sensitive, glossary and `copy_rules.json` `control-room-casing`), `Sync and drift` (glossary former name) | 0 | 0 | seed, scope README + guides |
| `magic`, `magical` | 0 | 6, all negations or non-goals: `guides/jtbd-and-user-flows.md:264` ("not \"one magical global index.\""), `guides/related-data-and-reindexing.md:16,79,498`, `guides/scope-and-reopen-policy.md:27`, `guides/sync-modes-and-visibility.md:3` | README-only scope |
| `federated`, `federation` | 0 | 26 (`guides/multi-index-search.md` 11, `guides/per-query-tuning-pipeline.md` 9, `common-mistakes.md` 2, one each in `drift-recovery.md:70`, `golden-path.md:7`, `jtbd-and-user-flows.md:261`, `overview.md:37`); the public option is `federation_weight:` | README-only scope |
| `hydration`, `hydrated` | 0 | 21 (`jtbd-and-user-flows.md` 4, `drift-recovery.md` 2, `meilisearch-concepts.md` 2, `telemetry.md:3,26`, others one each); `telemetry.md:26` documents the event `` `[:scrypath, :hydration]` `` | README-only scope |
| `last successful` (glossary rule `last-succeeded`, scope `scrypath_ops/lib/**` only) | 0 | 1: `guides/operator-mix-tasks.md:28` | not a docs rule; record as a candidate, not seeded |
| `accepted work` | pinned across README and guides by contract tests | | never ban (e.g. `docs_contract_test.exs:143` pins "Accepted work is not the same thing as search visibility") |

The proposed table (verified green: 0 hits scanned with and without fences) is:

| Rule id | Phrases (`match`, `case`) | Scope | Source |
|---------|---------------------------|-------|--------|
| `time-promise` | the ten phrases, literal, insensitive, word-bounded | README + guides | `readme_contract_test.exs` list (README-02) |
| `brand-hype` | `effortless(ly)?`, `just\s+stays?\s+in\s+sync`, `real[- ]?time`, `AI[- ]powered`, `playbook` (regex, insensitive) | README + guides | `brand/BRAND.md` Do not say |
| `brand-technical-readme-only` | `magic(al|ally)?`, `federat(ed|ion)`, `hydrat(e|ed|es|ion|ing)` (regex, insensitive) | README only, with a recorded `reason`: guides use them for the `[:scrypath, :hydration]` event, the `federation_weight:` option and explicit negations | `brand/BRAND.md` Do not say; `GLOSSARY.md` scopes "hydration" to UI copy |
| `glossary-names` | `Control Room` (literal, sensitive), `Sync and drift` (literal, insensitive) | README + guides | `GLOSSARY.md`; `copy_rules.json` `control-room-casing` |

Design: data in `test/support/release/forbidden_phrases.json` using `copy_rules.json`'s field names (`id`, `rule`, `forbidden: [{text, match, case}]`, plus `scope`, `source`, optional `reason`), decoded with Jason; a pure `scan([{path, text}], table)` returning `{path, line, rule_id, matched}`; fenced code is skipped as in the README test; scope is `:readme` or `:readme_and_guides`; `guides` means the `guides/*.md` entries of `docs[:extras]`. Existing offenders for the recommended scopes: none. Offenders if the three technical terms were scoped to guides: the 6 + 26 + 21 lines above; rewording them would change a public option name's prose, a telemetry contract page and `docs_contract_test.exs:551-559`-style pins, so the README-only scope is recommended (Open Question 4). Plus a faithfulness check: every brand-sourced term must appear in `brand/BRAND.md`'s Do-not-say paragraph, so the copy cannot silently diverge from its source. Move `@time_promises` and `@brand_do_not_say` out of `readme_contract_test.exs` so there is one table; the README tests keep their names and become callers, so nothing weakens.

Planted cases (in-memory): `"Search in five minutes."` in a README path fails; the same in `guides/planted.md` fails; `"magic"` fails in README, passes in a guide (scope); a phrase inside a fenced block passes; a word-boundary near miss (`"magical"` against `magic` literal, if the rule uses literals) is decided and tested.

Excluded on purpose (record in the data file's `not_covered`): UI-only status words (`Searchable`, `Last success`, `Healthy`, `Pending` vs `queued`, `Retry accepted`), because their `source_scope` is `scrypath_ops/lib/**` and the guides use `accepted` as a contract term; unsourced marketing words (`seamless`, `blazing`, `powerful`) have no source in the three named files and are `[ASSUMED]` candidates only.

## CONTRIBUTING same-PR rule (GUARD-03)

- Place it in the first section "First hour and canonical docs" (`CONTRIBUTING.md:3-11`), which already says to keep guides authoritative "instead of turning this file into a second matrix".
- Draft (about 60 words, `[ASSUMED]` wording): "**Same-PR rule for public-surface claims.** When a change moves something the README, a guide, the website or the operator UI says about Scrypath (what it is, when it fits, the install line, sync modes, support policy, the operator UI's status), update every surface that owns or repeats that claim in the same PR. The [claim owner map](https://github.com/szTheory/scrypath/blob/main/.planning/reference/CLAIM-OWNER-MAP.md) names the owner and the others."
- `CONTRIBUTING.md` ships in the Hex package and is an extra, so the Phase 192 link rule applies: the map must be linked by absolute `blob/main` URL (the path exists, which the rule checks) or named in a code span without a link. It may name repo-only tasks (allowlisted) but should not.
- Pin it two ways at no new gate: a row in the owner map (`same-pr-rule`, Owner `doc:CONTRIBUTING.md`, Pinned by `CONTRIBUTING.md has Same-PR rule`; the existing shape test then fails the default run if the sentence goes) and one explicit assertion for the tokens `same PR` and `CLAIM-OWNER-MAP`.
- Defect found in the same file: `CONTRIBUTING.md:11` says the docs contract suite "is no longer part of the default CI and release gates". It is part of the required `package` lane: `mix verify.package` runs `test/scrypath/docs_contract_test.exs` (`dev/mix/tasks/verify.phase11.ex:30-33`; `ci.yml:163` `run: mix verify.package`) [VERIFIED: files read]. No test pins that sentence; fixing it while touching the file is cheap and is a docs-truth correction (Open Question 8).

## Which lane runs what, and the local mirrors

**Tags:** `docs_contract` is applied by exactly one file, `test/scrypath/docs_contract_test.exs:3` `@moduletag :docs_contract` (verbatim); `backfill_contract_docs_test.exs:3` says it is deliberately not tagged. The `core` lane is `run: mix verify.core --exclude integration --exclude docs_contract` (`.github/workflows/ci.yml:98`), so `docs_contract_test.exs` never runs there; it runs in the required `package` lane through `mix verify.package` -> `Verify.Phase11.run_without_docs`, which runs `test/release/package_metadata_test.exs`, `package_contents_test.exs`, `consumer_smoke_test.exs` and `test/scrypath/docs_contract_test.exs` (`verify.phase11.ex:30-33`), and when run by hand. New untagged files run in `core` only; tests added to `package_metadata_test.exs` run in both.

**Required checks:** `core`, `package`, `repository-contracts`, `backend`, `ecommerce-mounted`, `ops-ui (path-scoped)` (`CONTRIBUTING.md` ledger). `repository-contracts` runs `phase99_contract_test`, `phase111_contract_test`, `no_human_gates_contract_test`, `dependency_boundary_contract_test`, `workflow_wiring_test` and others (`dev/mix/tasks/verify.phase99.ex` `@focused_tests`); several read `CONTRIBUTING.md` and the support guide.

**Path triggers for a change touching `guides/`, `mix.exs`, `test/`, `CONTRIBUTING.md`, `README.md`, `.planning/` (and optionally `lib/scrypath.ex`):**
- Browser lanes: `scripts/ci/ecommerce_path_classifier.cjs:23` `const SKIPPABLE_PATTERN = new RegExp(String.raw\`^(\.planning/|docs/|[^/]+\.md$)\`);` skips only when every path matches; `guides/x.md` (has a slash) and `mix.exs` do not, so `ecommerce-mounted` and the Node half of `repository-contracts` run.
- `ops-ui (path-scoped)`: `ci.yml:440` regex includes `test/release/`, `mix\.exs` and `lib/`; it runs (every path-scoped trigger is already met by `mix.exs`).
- Advisory `compatibility`: `compat_path_classifier.cjs` `RELEVANT_PATTERN` includes `test/`, `lib/`, `mix\.exs$`; runs (advisory).
- `website.yml` (not required) triggers on `README.md`, `guides/**`, `docs/**`, `mix.exs` and `website/**` on pull request and push; merging to `main` redeploys the site. STATE.md records the standing rule from Phase 189: merge only after `build-and-check` is green on the exact head (check with `gh api`) because that job is not required. This phase's PR triggers it. `test/**` and `.planning/**` do not.
- Budget: about 14 to 19 minutes hosted (CONTEXT; CI-EFFICIENCY measured rows).

**Local mirrors, cheapest first** (run on the committed head; commit before running snapshot-based gates):

| # | Command | Measured / budget | Covers |
|---|---------|-------------------|--------|
| 1 | `export ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5` then `scripts/ci/pre_push.sh` | about 1 min (CI-EFFICIENCY row; finding 22 measured 68 s) | actionlint, format, lock checks, compile warnings-as-errors, credo strict, workspace_clean, wiring and namespace tests, Node classifier tests |
| 2 | `mix format --check-formatted` | seconds | format (also in 1) |
| 3 | The doc-pin set: `mix test test/release/package_metadata_test.exs test/release/shipped_docs_contract_test.exs test/scrypath/readme_contract_test.exs test/scrypath/docs_contract_test.exs test/scrypath/phase112_contract_test.exs test/scrypath/phase99_contract_test.exs test/scrypath/readiness_contract_test.exs test/scrypath/phase98_contract_test.exs test/scrypath/phase110_contract_test.exs test/scrypath/backfill_contract_docs_test.exs test/scrypath/telemetry_test.exs test/scrypath/telemetry_contract_test.exs test/mix/tasks/dependency_boundary_contract_test.exs` plus the new files | **242 tests, 0 failures, 2.9 s** at HEAD [VERIFIED: run] | everything that reads README, guides, CONTRIBUTING or the extras, including the `docs_contract`-tagged file (it runs when named) |
| 4 | `mix test test/scrypath/phase99_contract_test.exs test/scrypath/phase111_contract_test.exs test/scrypath/no_human_gates_contract_test.exs test/mix/tasks/dependency_boundary_contract_test.exs test/mix/tasks/workflow_wiring_test.exs` | **142 tests, 0 failures, 12.1 s** [VERIFIED: run] | the CONTRIBUTING- and plan-reading part of `repository-contracts` |
| 5 | `mix docs --warnings-as-errors` | about 1 s warm; dev env passed at HEAD, test env passed at HEAD [VERIFIED: run] | success criterion 1 |
| 6 | `mix verify.core --exclude integration --exclude docs_contract` | about 6 min (CI-EFFICIENCY) | `core` |
| 7 | `mix verify.package` | hosted 110 s; not measured locally | `package` (run on a committed tree; whether the consumer smoke needs network for dependency fetches was not checked, `[ASSUMED]` it may; a local clone has history, a hosted shallow checkout does not) |
| 8 | `mix verify.repository_contracts` (mix half about 6 min; Node half 587 s) | optional with the reason recorded | the rest of `repository-contracts`; no input in the Node half changes |
| 9 | `backend`, `ecommerce-mounted`, `ops-ui` | not run | no input of these lanes changes (`examples/`, `scrypath_ops/`, Docker files, `scripts/ci/` untouched); record "not run: no input changed" per CI-EFFICIENCY finding 22 |
| 10 | Website: `cd website && npm ci && npm run build && npm run check` | about 64 s hosted | only because `guides/**` and `mix.exs` trigger `website.yml`; it reads `@version` from `mix.exs` and no guide |

Gate budget: add no row; record "no gate added" (A7 from Phase 192 still holds; `workflow_wiring_test.exs` fails above 12 rows).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| What ExDoc did with the groups | A reimplementation of `match_extra` | The built `dist/sidebar_items-*.js` from the one existing docs build | Covers regex patterns, name spacing, the unnamed group and cannot drift from ExDoc |
| Version comparison | A regex or tuple compare for `~>` | `Version.match?/2` plus a segment-prefix check | `~> 0.2` satisfies 0.3.20, so the prefix check is the only extra logic |
| Shipped file set | A second copy of `package.files` | `Scrypath.Release.ShippedDocs.shipped_files/0` | One data source; already UTF-8 guarded |
| Markdown fences, links, prose | A markdown parser | `ShippedDocs.markdown_links/1` and the README test's fence regex, moved into one shared module | The README test's `fences/1` and `prose/1` already work; a third copy is the risk |
| JSON data | A hand parser | `Jason.decode!/1` | Runtime dependency already present |
| Link scan of built docs | A new scan or a second docs build | The existing `link_problems/3`, `plant/5` in `BuiltDocsBrandTest` | Already complete (above) |
| Docs build in tests | A second `mix docs` | The existing `setup_all` | Concurrency hazard and cost |

**Key insight:** every piece of machinery exists; Phase 193 composes it, moves two private lists into shared data and closes the "silent ExDoc" gaps with one config test and one built-sidebar test.

## Runtime State Inventory

The regroup renames sidebar group labels (`Getting Started` to `Getting started`, `Operations` to `Operate and recover`); no page URL changes (ExDoc pages are named by the extra's id, not its group; the sidebar payload carries `id`, `title`, `group` separately [VERIFIED: probe sidebar JSON]).

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None. Group labels exist only in `mix.exs` and the tests above | none, verified by grep |
| Live service config | HexDocs and hex.pm for 0.3.20 keep the old group names until a release publishes new docs (docs ship only through a Hex release, which needs the maintainer's yes and is out of scope) | none now; record in the phase notes |
| OS-registered state | None | none |
| Secrets and env vars | None | none |
| Build artifacts | `doc/` at the repo root is git-ignored build output (`.gitignore:4:/doc/`), stale after the change | none; the test build writes to `System.tmp_dir!()` |

## Common Pitfalls

### Pitfall 1: Sidebar order is `extras` order
**What goes wrong:** the group lists in CONTEXT read as sidebar order, but the sidebar follows `extras`; with `extras` untouched the golden path renders fourth in the first group and `common-mistakes` renders before `jtbd-and-user-flows`. **Avoid:** decide Open Question 1; if `extras` is reordered, add a test that the per-group subsequence of `extras` equals the group list. **Warning sign:** a pin that compares group list order passes while the built sidebar differs.

### Pitfall 2: ExDoc is silent about every grouping mistake
Missing, duplicate and dangling entries all build clean under `--warnings-as-errors`. **Avoid:** the config test and the built-sidebar test; a planted case per kind.

### Pitfall 3: An `==` pin on a list that no longer exists
`docs[:groups_for_extras][:Operations]` returns `nil` after the regroup; `nil == [...]` fails with an unhelpful diff. Replace in the same commit as `mix.exs`.

### Pitfall 4: The `docs_contract` blind spot
`docs_contract_test.exs` holds nine of the eleven overview assertion calls and is excluded from `core` and from `pre_push.sh`; run it by hand (it is in mirror row 3) every time `guides/overview.md`, `mix.exs` or the extras change.

### Pitfall 5: Case-sensitive pin tokens in the shrunk page
`String.contains?` pins are case-sensitive: `Canonical mental model` needs the capital C, link text must read `[JTBD and user flows](jtbd-and-user-flows.md)` exactly, and order pins compare byte offsets.

### Pitfall 6: Marker form change breaks the README test
Changing `@differs_marker` to the reason-carrying form must land in the same commit as `differs_marked?/2` and any README or golden-path use of the marker (none exists today).

### Pitfall 7: Placeholder and template install lines
`docs/releasing.md:78` `~> X.Y.Z` is non-numeric by design; `dev/.../verify.release_publish.ex:153` is not shipped. Handle by an exact, reasoned placeholder entry, not by skipping unparseable requirements.

### Pitfall 8: Scope of "every guide in extras"
`docs/*.md`, `ARCHITECTURE.md` and `CONTRIBUTING.md` are also extras. Scanning them breaks on `ARCHITECTURE.md:142` ("instantly visible", a negation) and `docs/jtbd-gap-map.md:210` ("quickly"; that file is shipped but is not an extra). Keep the scope to README plus `guides/*.md`, as CONTEXT words it.

### Pitfall 9: Repo-only task names in `mix.exs` comments
The Phase 192 invariant scans every `mix.exs` line except `preferred_envs` registration lines for repo-only task names. A helpful comment near `groups_for_extras` that names a verify task fails `core`.

### Pitfall 10: Credo strict and format on new test code
`.credo.exs` includes `test/` and `.formatter.exs` includes `{config,lib,dev,test}/**/*`; `core` runs `mix test --warnings-as-errors`, so an unused variable in a planted case fails the lane. Keep helpers small.

### Pitfall 11: The three plan-marker strings
Plans must not contain the markers listed in `no_human_gates_contract_test.exs:4-8`; that test runs in `repository-contracts`.

### Pitfall 12: Guide file names are read outside the root
`posture.ex:417` reads `guides/operator-mix-tasks.md` at runtime and `website/src/pages/docs.html` links 12 guides by name; this phase renames nothing, so a verification step should prove it: `git diff --diff-filter=DR --name-only origin/main...HEAD -- guides docs ARCHITECTURE.md CONTRIBUTING.md README.md` must print nothing.

## Code Examples

### Shrunk overview skeleton (structure and tokens; wording is the planner's)
```markdown
# Guides

<one sentence: a short reading order; the sidebar groups every guide by job>

## Recommended reading order

1. [Golden path](golden-path.md) — ...
2. [JTBD and user flows](jtbd-and-user-flows.md) — Canonical mental model: what jobs Scrypath serves, the main user flows, and what "success" honestly means in each one.
3. [Meilisearch concepts](meilisearch-concepts.md) — ...
4. [Request-edge search](request-edge-search.md) — ...
5. [Composing real-app search](composing-real-app-search.md) — ...
6. [Phoenix walkthrough](phoenix-walkthrough.md) — ...
7. [Sync modes and visibility](sync-modes-and-visibility.md) — ...
8. [Related data and reindexing](related-data-and-reindexing.md) — ...
9. [Drift recovery](drift-recovery.md) — ...
10. [Common mistakes](common-mistakes.md) — ...

<example paragraph: both examples by absolute https://github.com/szTheory/scrypath/blob/main/examples/... URLs>
```
Every token pinned in O5 to O11 and in the owner map is present. [Source: this research; pins quoted in the overview inventory]

### Reading ExDoc's built sidebar (sketch, parse proven in the probe)
```elixir
[js] = Path.wildcard(Path.join(out, "dist/sidebar_items-*.js"))
json = js |> File.read!() |> String.split("sidebarNodes=", parts: 2) |> List.last() |> String.trim() |> String.trim_trailing(";")
extras = Jason.decode!(json)["extras"]          # [%{"id" => "readme", "group" => "Getting started", ...}, ...]
```

### Install-line scan (prototype that ran)
```elixir
re = ~r/\{:scrypath,\s*"([^"]*)"\s*\}/
case Regex.run(~r/^~>\s*(\d+(?:\.\d+)*)$/, req) do
  [_, nums] ->
    segs = String.split(nums, ".")
    segs == Enum.take(String.split(version, "."), length(segs)) and Version.match?(version, req)
  nil -> :non_numeric   # placeholder allowlist or failure, never a silent skip
end
```

### Planted built-docs cases that already exist
See `package_metadata_test.exs:362-413` (`plant/5`); no new planted built-docs case is required.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| One 14-item "Getting Started" group | Six job-named groups, first group at most five | this phase | the sidebar stops being a link farm; labels change, URLs do not |
| `overview.md` as a 22-row table duplicating the sidebar | A reading order of about 250 words plus two example links | this phase | every inbound link stays live; one claim sentence in `lib/scrypath.ex` and one in the README must be reworded |
| README-only parity and phrase checks with private lists | Shared data and pure modules with planted cases, scanning guides too | this phase | one table to edit, failure proven by in-memory cases |
| Link rule proven only on real files | Already has in-memory planted cases (Phase 192 Plan 03) | 2026-11-21 | GUARD-01 is a traceability record |

**Deprecated/outdated:** `CONTRIBUTING.md:11` (docs contract suite "no longer part of the default CI and release gates") is stale; the group label `Operations`; the owner-map phrases "Phase 193 guards this".

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Reordering `extras` to match the group lists is within the intent of the locked "extras order is left alone" bullet | Open Question 1, Pitfall 1 | If the maintainer wants `extras` untouched, the golden path renders fourth and the jtbd order pin cannot move to the sidebar; costs one reorder to undo |
| A2 | A one-line `lib/scrypath.ex:13` moduledoc edit is acceptable under "no `lib/` change" (CONTEXT lists the moduledoc link as an integration point) | Overview inventory, Open Question 2 | If declined, a shipped moduledoc keeps calling the page a table of contents |
| A3 | A target of about 250 words for the shrunk overview | Overview inventory | A chosen number; constant in prose only, no test |
| A4 | README-only scope for `magic`, `federated`, `hydration` in the phrase table | Forbidden-phrase table | If the maintainer wants guide scope, 6 + 26 + 21 lines must be reworded in the same plan and pins at `docs_contract_test.exs` moved |
| A5 | hex.pm hides an HTML comment above a fence like GitHub and ExDoc do (ExDoc verified) | Snippet parity | If hex.pm shows it, a marker would be visible on the package page the day someone uses it; none is used today |
| A6 | JSON (not `.exs`) for the phrase table | Standard Stack | Format only; reversible |
| A7 | No gate-ledger row is added | Local mirrors | A row needs a deletion trigger and brings the ledger to 11 of 12 |
| A8 | `guide-routes` owner moves to `doc:mix.exs` and a `reading-order` row owns the page | Overview inventory | Owner-map shape is reversible; test passes either way as long as tokens exist |
| A9 | Seed phrases beyond the three named sources (`seamless`, `blazing`, `powerful`) are out of the table | Forbidden-phrase table | Adding unsourced words widens scope without a source |
| A10 | The optional prose pattern `**0.3.x**` in `guides/golden-path.md:25` is not required by GUARD-02 | Install line | A stale series phrase could survive a bump |

## Open Questions

1. **Reorder `extras` so the sidebar matches the group lists? (recommended: yes)**
   - What we know: sidebar order in a group is the `extras` order (verified); the locked bullet says `extras` order is left alone "except where ExDoc needs nothing" (ambiguous).
   - What's unclear: whether the maintainer wants the golden path to render second in the first group (the CONTEXT list order) and jtbd first in "Guides by task".
   - Recommendation: reorder the 33-entry `extras` list to follow the group lists; it changes no URL, is one reversible edit, and makes the group lists true; add a test that each group's subsequence of `extras` equals its list. If the maintainer prefers the locked bullet literally, keep `extras` and retitle the claim (the golden path is the start page by content and links, not by position) and move O6 to a retire-with-reason.
2. **`lib/scrypath.ex:13` versus "no `lib/` change".** Recommendation: edit the one moduledoc line (docs-only, no behavior change, no new lane: `mix.exs` already triggers every lane that `lib/` would); record it as the only `lib/` touch.
3. **Retire the "Crash Course" and table content with recorded reasons?** Recommendation: yes (owners are `ARCHITECTURE.md` and `getting-started.md`; no pin reads them).
4. **Phrase-table scope for the three technical terms.** Recommendation: README-only with a reason in the data file.
5. **Marker form and side.** Recommendation: `<!-- scrypath:snippet-intentionally-differs: <reason> -->` above either fence.
6. **GUARD-01.** Recommendation: record as already met; add only the optional versioned-URL source rule if wanted.
7. **Minor-bump behavior of the install guard.** It makes the release PR red until the five install lines move; intended, pre-1.0 patch-first makes it rare. Confirm it is acceptable that the fix lands as a commit on the release PR.
8. **Fix `CONTRIBUTING.md:11` while editing the file?** Recommendation: yes, one sentence, no pin reads it.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/OTP via asdf env vars | all `mix` commands | yes | 1.19.0 / OTP 28.5 | none needed |
| ExDoc in `_build/test` and `_build/dev` | docs build, built-sidebar test | yes | 0.40.4 | none needed |
| Node | `scripts/ci/pre_push.sh` Node tests | yes | v26.10.0 | pre_push reports SKIPPED if missing |
| `actionlint`, `gh`, `act`, `docker` | pre-push lint, merge, optional mirrors | yes (`/opt/homebrew/bin/actionlint`, `/opt/homebrew/bin/gh`, `/opt/homebrew/bin/act`, `/usr/local/bin/docker`) | not probed | rows skipped with a recorded reason |
| `python3 -I` | ad hoc scans in this research only | yes | not needed by the plan | the scans are reproducible in Elixir |
| Network (hex.pm, hexdocs.pm) | live link behavior | not needed in CI | - | Checkpoint (SIGNAL-01) |

Machine load at research time: load averages about 7 (CI-EFFICIENCY finding 22 warns that load 20+ makes timing-sensitive local tests flaky; check `uptime` before the long mirrors).
**Missing dependencies with no fallback:** none. **With fallback:** none.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19.0), `async: true` contract files |
| Config file | `test/test_helper.exs` (excludes `:integration`, `:requires_clean_workspace`, `:postgres` by default; loads `test/support/**/*.ex`) |
| Quick run command | `mix test test/release/package_metadata_test.exs test/release/install_line_contract_test.exs test/release/forbidden_phrases_contract_test.exs test/scrypath/readme_contract_test.exs` (names of new files are discretionary) |
| Full suite command | `mix verify.core --exclude integration --exclude docs_contract`, then `mix verify.package`; the doc-pin set in row 3 for the tagged file |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DOCS-01 | Group names and order; first group at most five and exactly the five listed; every extra in exactly one group; no dangling entry; planted missing, duplicate, dangling and oversize-first-group fail | unit, pure on `MixProject.project()[:docs]` | `mix test test/release/package_metadata_test.exs` | extend (replace `:108-125` pins) |
| DOCS-01 | Built sidebar: each extra rendered under its configured group; only `api-reference` has group `""` | built-docs test in the existing `setup_all` | same | extend `BuiltDocsBrandTest` |
| DOCS-01 | `mix docs` no warnings | existing `setup_all` (`--warnings-as-errors`) and `mix docs --warnings-as-errors` | same + `mix docs --warnings-as-errors` | exists |
| DOCS-01 | `getting-started.md` links the golden path | `docs_contract_test.exs:658` (`Golden path](golden-path.md)`) | `mix test test/scrypath/docs_contract_test.exs` | exists (package lane only) |
| DOCS-01 | No guide renamed or deleted | verification command (not a test): `git diff --diff-filter=DR --name-only origin/main...HEAD -- guides docs ARCHITECTURE.md CONTRIBUTING.md README.md` prints nothing | shell | Wave 0 (plan verify step) |
| DOCS-02 | Overview stays an extra; every carried pin passes (O1-O11); README and moduledoc rewords; owner-map rows | existing pins plus owner-map shape test | the doc-pin set (row 3) | exists; edit O6 only if the alternative is chosen |
| DOCS-02 | No shipped link to a dead page | existing TRUTH-03 scan (`overview.html` own-docs link in `readme.html`) and ExDoc's fatal warning for the moduledoc link | `mix test test/release/package_metadata_test.exs`; `mix docs --warnings-as-errors` | exists |
| GUARD-01 | Passes on built docs and README; fails planted self-link, dead target, dead anchor | `package_metadata_test.exs:312-342, 362-413` | `mix test test/release/package_metadata_test.exs` | exists (no change required) |
| GUARD-02 | Every `{:scrypath, "~> ..."}` in the shipped files and `website/scripts/build.mjs` is a prefix of the `mix.exs` version series and satisfied by it; planted `~> 0.2`, wrong series and placeholder cases | unit, pure + real-file zero | `mix test test/release/install_line_contract_test.exs` | Wave 0 |
| GUARD-03 parity | README and golden path first `use Scrypath,` fence identical or marked with a reason; planted differ, marker with and without reason | unit, pure + real-file | `mix test test/scrypath/readme_contract_test.exs` plus the new helper's test | Wave 0 (helper) / extend |
| GUARD-03 phrases | Table is green on README and `guides/*.md`; planted phrase fails in README and in a guide; scope and fence cases; faithfulness to `brand/BRAND.md` | unit, pure + real-file | `mix test test/release/forbidden_phrases_contract_test.exs` | Wave 0 |
| GUARD-03 rule | CONTRIBUTING carries the same-PR rule; owner-map row pins it | owner-map shape test + one assertion | `mix test test/scrypath/readme_contract_test.exs` | extend |

### What each check does NOT prove
- DOCS-01: that the grouping matches how readers look for things; live HexDocs rendering (docs publish only through a release); the within-group order if `extras` stays unchanged (Open Question 1).
- DOCS-02: that the shrunk page reads well; that the retired Crash Course text is not missed.
- GUARD-01: external link liveness, version-pinned HexDocs links, module and task pages beyond ExDoc's own warnings, live hex.pm and HexDocs behavior (recorded at the Checkpoint).
- GUARD-02: prose phrases such as `**0.3.x**`; the website's rendered install block (only the build script literal is read).
- GUARD-03: that unlisted wording is fine; that guides read in the brand voice; how hex.pm renders the marker.

### Sampling Rate
- **Per task commit:** the new and edited test files plus `mix format --check-formatted`.
- **Per wave / before each push:** `scripts/ci/pre_push.sh`, mirror rows 3 to 5, then rows 6 and 7 on the committed head; rows 8 and 9 recorded as run or not run with the reason.
- **Phase gate:** all required hosted lanes green on the exact head SHA, and `website.yml` `build-and-check` green on that head before the squash merge (it deploys on merge).

### Wave 0 Gaps
- [ ] `test/support/release/install_line.ex` and `test/release/install_line_contract_test.exs` - GUARD-02
- [ ] `test/support/release/snippet_parity.ex` (+ its planted-case test) - GUARD-03 parity; `readme_contract_test.exs` rewired
- [ ] `test/support/release/forbidden_phrases.ex`, `forbidden_phrases.json`, `test/release/forbidden_phrases_contract_test.exs` - GUARD-03 phrases; README lists moved out of `readme_contract_test.exs`
- [ ] Config-shape and built-sidebar tests in `test/release/package_metadata_test.exs` - DOCS-01
- [ ] `193-PIN-INVENTORY.md` - the overview and group-shape tables above, finalized, with a fate log
- Framework install: none.

## Security Domain

`security_enforcement` is absent in `.planning/config.json` (treated as enabled). The phase edits documentation, `mix.exs` docs metadata and test code; no input handling, auth, sessions or network access is added.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication / V3 Session / V4 Access Control | no | - |
| V5 Input Validation | marginal | Scanners read only repository files and `package.files` expansions; no shelling out except what existing tests already do |
| V6 Cryptography | no | - |
| V14 Configuration / supply chain | yes | No new dependency; the install-line guard keeps a published dependency line from pointing at a series the package no longer matches; the README host allowlist (Phase 192) is untouched |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| An adopter copies a stale install line and resolves a different series | Spoofing of guidance | GUARD-02 asserts every occurrence against `mix.exs` at test time |
| A guard that cannot fail (vacuous scan) gives false assurance | Repudiation of evidence | Non-vacuity floors plus in-memory planted failures per guard |
| A silent ExDoc grouping mistake hides a guide from the sidebar | Information disclosure (loss) | Exact-one membership test plus built-sidebar test |

## Sources

### Primary (HIGH confidence, opened or run this session)
- Repo: `.planning/phases/193-hexdocs-regroup-and-guards/193-CONTEXT.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/ROADMAP.md` (Phase 193, guardrails), `AGENTS.md`, `.planning/phases/192-docs-truth-and-readme/192-RESEARCH.md` and `192-PIN-INVENTORY.md`, `.planning/reference/CLAIM-OWNER-MAP.md`, `.planning/reference/CI-EFFICIENCY.md` (finding 22 and the local-mirror table)
- Source: `mix.exs` (docs, package, deps), `guides/overview.md`, `guides/golden-path.md`, `README.md`, `CONTRIBUTING.md:1-60`, `lib/scrypath.ex:1-45`, `brand/BRAND.md`, `GLOSSARY.md`, `scrypath_ops/test/support/copy_rules.json`, `website/scripts/build.mjs:120-170`, `website/src/pages/index.html`
- Tests: `test/release/package_metadata_test.exs` (whole), `test/release/shipped_docs_contract_test.exs`, `test/support/release/shipped_docs.ex`, `test/scrypath/readme_contract_test.exs` (whole), `test/scrypath/docs_contract_test.exs` (overview, extras, group and getting-started pins), `test/scrypath/phase112_contract_test.exs`, `test/scrypath/no_human_gates_contract_test.exs`, `test/test_helper.exs`
- CI: `.github/workflows/ci.yml` (jobs, triggers, `core_verify`, `ops-ui-path` regex), `.github/workflows/website.yml` (paths), `scripts/ci/ecommerce_path_classifier.cjs`, `scripts/ci/compat_path_classifier.cjs`, `scripts/ci/pre_push.sh`, `dev/mix/tasks/verify.phase11.ex`, `verify.phase99.ex`, `verify/capability.ex`
- ExDoc 0.40.4 source: `deps/ex_doc/lib/ex_doc/extras.ex`, `config.ex`, `autolink.ex`, `formatter/html/templates.ex`, `lib/ex_doc.ex` (Groups section)
- Runs: `mix docs --warnings-as-errors` in test and dev env (clean); probe builds with modified `groups_for_extras` (planned, missing, duplicate, dangling) and with an HTML-comment marker extra; Python scans of the built output, of README and guides (phrases, install lines, HexDocs URL shapes, fence parity); the 13-file doc-pin set (242 tests, 0 failures, 2.9 s) and the 5-file repository-contracts subset (142 tests, 0 failures, 12.1 s); install-line prototype against the real shipped files

### Secondary (MEDIUM confidence)
- Phase 192 research claims reused only where re-verified above (lane tables, header pin)

### Tertiary (LOW confidence)
- hex.pm's rendering of an HTML comment (`[ASSUMED]`); unsourced marketing words (`[ASSUMED]`)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new packages; versions read from `mix.lock` and `mix.exs`.
- Architecture: HIGH for ExDoc grouping, the existing scan and the pin inventory (read and reproduced); MEDIUM for the three new guards (designs prototyped, Elixir not yet written).
- Pitfalls: HIGH where tied to a quoted file and line or a probe; the extras-order question is a decision, not a fact gap.

**Research date:** 2026-11-21
**Valid until:** 2026-12-05 (re-run the scans if `README.md`, `guides/`, `mix.exs` docs config or `test/scrypath/readme_contract_test.exs` change on `main`)
