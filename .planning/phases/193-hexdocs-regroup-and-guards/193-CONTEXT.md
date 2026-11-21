# Phase 193: HexDocs regroup and guards - Context

**Gathered:** 2026-11-21
**Status:** Ready for planning

<domain>
## Phase Boundary

A reader in the HexDocs sidebar finds the right guide by job from a short first group, and mechanical guards keep README, guides and (later) the site from drifting. Requirements: DOCS-01, DOCS-02, GUARD-01, GUARD-02, GUARD-03. Two plans: (1) regroup `groups_for_extras` and settle `guides/overview.md`; (2) the guards and the CONTRIBUTING same-PR rule.

Out of scope: renaming, merging or deleting any guide (filenames are HexDocs URLs); the website (Phase 194, optional); a Hex release (the maintainer's explicit yes; docs reach HexDocs only through a release); any new required CI check.

What this does not prove: that the grouping matches how readers look for things. Only structure (counts, membership, links, parity) is automated.

</domain>

<decisions>
## Implementation Decisions

### Sidebar grouping (DOCS-01)
- Groups, in sidebar order: Getting started, Guides by task, Phoenix, Operate and recover, Project policy, Maintainers. The names are the maintainer's own examples in DOCS-01, extended by keeping the existing Phoenix group as its own job-named group.
- First group (Getting started, five items): `README.md`, `guides/golden-path.md`, `guides/getting-started.md`, `guides/overview.md`, `guides/meilisearch-concepts.md`. The golden path is the one start page; `getting-started.md` already links to it and a test pins that link.
- Guides by task: jtbd-and-user-flows, request-edge-search, composing-real-app-search, related-data-and-reindexing, multitenancy, common-mistakes.
- Phoenix: unchanged six guides.
- Operate and recover: sync-modes-and-visibility, drift-recovery, meilisearch-operations, operator-mix-tasks, relevance-tuning, per-query-tuning-pipeline, telemetry, ARCHITECTURE.md.
- Project policy: support-and-compatibility, scope-and-reopen-policy, outside-adopter-intake.
- Maintainers: unchanged five files.
- `extras` order is left alone except where ExDoc needs nothing; no guide is renamed, merged or deleted. — **Reversibility:** costly — group membership is cheap to edit, but renaming or removing a guide changes a public HexDocs URL, so this phase does neither.

### guides/overview.md fate (DOCS-02)
- Shrink it to about half a page and keep it in `extras`: drop the 22-row table (the sidebar is the index) and keep the recommended reading order and the two example links. The file name and page URL stay. — **Reversibility:** one-way for the alternative: dropping it from `extras` ends the `overview.html` page in future HexDocs versions, and the README, the `Scrypath` moduledoc, the owner map and eleven contract assertions point at it. Shrinking keeps every inbound link live.
- Plan 01 starts with an inventory of every assertion that pins overview content (`docs_contract_test`, `phase112_contract_test`, `package_metadata_test`, the owner-map rows `guide-routes` and `examples`, the README onward link). Each pin is carried to the shrunk page, moved to the guide that now owns the claim, or retired with a recorded reason; none is weakened to reach green.
- The decision and its reason are recorded in the phase artifacts and in `CLAIM-OWNER-MAP.md`.

### Link check (GUARD-01)
- Extend the existing built-docs scan in `test/release/package_metadata_test.exs` (TRUTH-03; one docs build in `setup_all`, runs in `core` and `mix verify.package`). No new job, no new required check, no second docs build. The README is already scanned because it is the `readme.html` extras page.
- Plan 01 or 02 first checks which of the success-criterion cases the scan already proves (a planted self-link, a planted dead target, a dead anchor) and adds only what is missing, with in-memory planted cases. The non-vacuity floor stays.

### Install line (GUARD-02)
- A small pure scanner under `test/support/release/` (the `ShippedDocs` and `PackageContract` pattern) reads every `{:scrypath, "~> ..."}` occurrence in the files of `mix.exs` `package.files` plus the website source if present, and asserts each requirement is a prefix of the `mix.exs` version series (so `~> 0.2` fails at 0.3.x) and that the version satisfies it. It reads `mix.exs` at test time, so a Release Please bump cannot leave a stale line. In-memory planted cases prove it can fail.
- Reversible: a test and its support module only.

### Duplicated blocks and banned wording (GUARD-03)
- Schema snippet parity: compare the first Elixir fence containing `use Scrypath,` in `README.md` and `guides/golden-path.md` byte for byte, unless the later one carries an explicit `intentionally differs` marker with a reason (an HTML comment immediately above the fence). Plan 02 checks that the marker survives the ExDoc build before using it; if it does not, the marker lives in a visible sentence.
- Forbidden-phrase table: a small data file under `test/support/` plus one test that scans `README.md` and every guide in `extras`. It starts from `brand/BRAND.md`, the glossary and `scrypath_ops/test/support/copy_rules.json`, copied, not imported (a small copy beats a cross-project dependency). The table starts green: a phrase already in shipped text is fixed in the same plan by rewording, never allowlisted silently. In-memory planted phrases prove it can fail in README and in a guide.
- CONTRIBUTING.md gets a short same-PR rule: a change to a public-surface claim updates the other owning surfaces named in `.planning/reference/CLAIM-OWNER-MAP.md` in the same PR. A test pins that the rule text exists.
- `CLAIM-OWNER-MAP.md` rows that said "Phase 193 guards this" are updated to name the guard.

### Shipping and verification
- Docs-only plus tests; no `lib/` change. PR-first; the orchestrator ships (push, PR, squash-merge on green required checks). No Hex release in this phase.
- Pre-push mirrors: `scripts/ci/pre_push.sh`, `mix format --check-formatted`, the focused test files, `mix docs --warnings-as-errors`, `mix verify.core --exclude integration --exclude docs_contract`, the `docs_contract`-tagged files that pin overview and the sidebar, and `mix verify.package`. The Docker browser lanes read none of `guides/`, `mix.exs` groups or these tests, so a local mirror of them is optional with the reason recorded (CI-EFFICIENCY finding 22). `mix.exs` is outside the classifier allowlist, so hosted CI runs every lane; budget about 14 to 19 minutes.

### Decided autonomously
- [Sidebar] Q: "Where does ARCHITECTURE.md go?" → Selected: "Operate and recover, where it already sits under Operations" — one-line edit to undo
- [Sidebar] Q: "Keep Phoenix as its own group?" → Selected: "Yes, six guides, already job-named" — group membership is one edit in mix.exs
- [Sidebar] Q: "Which fifth item fills the first group?" → Selected: "meilisearch-concepts, because the README says a Meilisearch server is required" — swapping an item is one edit and one test line
- [Link check] Q: "New test file or extend the TRUTH-03 scan?" → Selected: "Extend the existing scan so the docs build runs once" — moving a test is cheap
- [Guards] Q: "Where does the scanner code live?" → Selected: "test/support/release/ as pure functions with in-memory planted cases" — test-only code, nothing public
- [Guards] Q: "Forbidden-phrase table format?" → Selected: "a small data file read by one test, copied from the brand and copy-rules sources" — test-only, edit in place
- [Install line] Q: "Compare to the exact version or the series?" → Selected: "the series prefix plus a satisfies check" — a test assertion only

### Claude's Discretion
Exact wording of the shrunk overview, the CONTRIBUTING rule and the banned-phrase list (subject to the brand voice sources); the test file and module names; whether the GUARD-01 gap fill needs any change at all once the existing scan is read.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `test/release/package_metadata_test.exs`: one `mix docs` build in `setup_all`, `extras_pages/1`, `link_problems/3`, `plant/5` (planted snippet helper), non-vacuity floors.
- `test/support/release/shipped_docs.ex` and `test/release/shipped_docs_contract_test.exs`: the pure-scanner plus planted-in-memory pattern from Phase 192, and the repository-path link regex.
- `test/scrypath/readme_contract_test.exs`: README word cap, link rules, and the owner-map reader (`.planning/reference/CLAIM-OWNER-MAP.md`).
- `scrypath_ops/test/support/copy_rules.json`: existing banned-wording conventions.

### Established Patterns
- Contract tests that read files only are untagged and run in the default suite and `core`; `docs_contract`-tagged tests are excluded from `core` and run elsewhere.
- Planted-failure tests prove each guard can fail; no shipped file is edited to prove a check.
- `mix.exs` `docs/0` holds `extras` and `groups_for_extras`; `package_metadata_test` pins `groups_for_extras[:Operations]` and `[:Maintainers]` and must change in the same commit as the regroup.

### Integration Points
- `mix.exs` docs config; `guides/overview.md`; `README.md` onward link to `overview.html`; `lib/scrypath.ex` moduledoc link to `guides/overview.md`; `CLAIM-OWNER-MAP.md`; `CONTRIBUTING.md`; `.planning/reference/CI-EFFICIENCY.md` only if a measured finding appears.

</code_context>

<specifics>
## Specific Ideas

No specific requirements beyond the roadmap and the requirement text; open to standard approaches.

</specifics>

<deferred>
## Deferred Ideas

- Website content and the website's own install line and snippet parity (Phase 194, cut at the checkpoint if traffic is near zero).
- Merging or renaming guides (needs adopter evidence; filenames are URLs).
- A Hex release carrying the regroup (maintainer's explicit yes).

</deferred>
