# Requirements: Scrypath v1.48 Discovery and onboarding

**Defined:** 2026-11-21
**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

Scope source: the maintainer's instruction of 2026-11-21 to open v1.48 exactly as recommended in `reference/ROLLING-ROADMAP.md` ("Post-v1.47 proposal") and `research/v1.48-prep/` (note D is the tie-breaker; A and C supply the detail). Three phases (192, 193, an optional 194) around one checkpoint, with a cut line after 193. The catalog foundation is v1.49. The housekeeping PRs (#157, #158, Dependabot #129, #150, #151) are not part of this milestone's requirements.

Every criterion below is an executable check, a recorded number or a recorded decision stated as such. Nothing here claims that a page "reads well", that the design is approved, or that anyone reviewed it; those stay explicitly unproven (Phase 185 correction in AGENTS.md).

## v1 Requirements

### Docs truth (Phase 192)

- [x] **TRUTH-01**: No file shipped in the Hex package (`package.files` in `mix.exs`) tells an adopter to run a repo-only task. One invariant test replaces the old pins: it derives the repo-only tasks from `dev/mix/tasks/` (tasks not in the shipped `lib/mix/tasks/`), scans every `package.files` file, and allows a mention only in an explicit allowlist (`CONTRIBUTING.md`, `docs/releasing.md`) or in a sentence that says it runs from a source checkout and is not in the Hex package. A planted-violation case (a shipped guide line with an unqualified `mix verify.adopter`) fails it, and a planted qualified line passes. Phase 192 starts with an inventory of every assertion that pins `verify.adopter` or the shipped-docs wording (`readiness_contract_test`, `docs_contract_test`, `phase108`/`110`/`112` tests), recording for each whether it pins a claim or wiring and how its intent is carried into the invariant; no pin is weakened to reach green.
- [x] **TRUTH-02**: The `PROJECT.md` "Canonical Adopter Contract" text and the new invariant say the same thing. The contract says the adopter proof spine is a maintainer task that runs from a source checkout and is not runnable from the Hex package; the change to `PROJECT.md` lands in the same commit as the pin change, so the check never enforces a claim the contract denies.
- [x] **TRUTH-03**: Every link in the README resolves to the intended target on GitHub, hex.pm and HexDocs. The built docs (`mix docs`) are scanned for self-links (a link whose target is the page it sits on, such as the old `readme.html` case) and for unresolved extras links, extending `test/release/package_metadata_test.exs` or its sibling; the scan has a planted failing case. Repo paths in the README are absolute GitHub URLs (done for the examples and `scrypath_ops` links in #158; the scan keeps it that way); guide links are relative or absolute-HexDocs consistently. The README header pin test stays green.

### README (Phase 192)

- [x] **README-01**: The README does one job: what Scrypath is, when it fits and does not fit, how to install it, one quick path, and at most three onward links. A small test (about 1 second) enforces a word cap (target 600 to 800 words, set from the owner map and recorded, not a measured optimum), at most three onward links after the quick path, absolute GitHub URLs for repo paths, and no `mix verify.*` string outside a source-checkout qualifier. The seven-bullet "Choose a route" block is gone; its destinations are reachable from the HexDocs sidebar (Phase 193).
- [x] **README-02**: The README's quick path ends in a `Scrypath.search/3` call and its result, and states the Meilisearch prerequisite and eventual consistency before the first code block. No sentence promises a time ("in five minutes"); a test fails any such phrase. The quick path's schema snippet is textually identical to the one in `guides/golden-path.md` or is marked as intentionally different (the parity guard in GUARD-03 reads this).
- [x] **README-03**: One short reference note records the owner map: for each claim (what it is, fit and non-fit, install line, sync modes, support policy, the operator UI's status) which surface owns it (README, HexDocs guide, website) and where the others link. It is the input to Phase 193 and to the Phase 194 decision.

### HexDocs structure (Phase 193)

- [ ] **DOCS-01**: The HexDocs sidebar is regrouped in `mix.exs` `groups_for_extras` with at most five items in the first group, named by job (for example Getting started, Guides by task, Operate and recover, Project policy, Maintainers), one start page (the golden path) and `getting-started.md` linking to it. No guide is renamed, merged or deleted in this milestone (filenames are HexDocs URLs). `mix docs` builds with no warnings and a test asserts every extra appears in exactly one group.
- [ ] **DOCS-02**: The fate of `guides/overview.md` (a 22-row table that duplicates the sidebar) is decided and recorded: shrink to half a page or drop it from `extras`; if dropped from `extras`, no shipped link points at its old page.

### Upkeep guards (Phase 193)

- [ ] **GUARD-01**: A link check runs over the built HexDocs output and the README: every internal target and every `hexdocs.pm/scrypath` target exists in the build, and self-links fail. It runs where the docs build already runs (no new required gate unless the ledger row is justified, with a deletion trigger).
- [ ] **GUARD-02**: The install line (`{:scrypath, "~> 0.3"}`) is generated or asserted equal to the version in `mix.exs` wherever it appears (README, golden path, website source if present), so a version bump cannot leave a stale line.
- [ ] **GUARD-03**: Duplicated blocks are guarded by data, not discipline: the schema snippet in the README, golden path and (if Phase 194 runs) website is identical or carries an explicit marker saying it intentionally differs; a forbidden-phrase table (starting from the glossary and brand voice rules, shared with `copy_rules.json` conventions where that is cheap) fails README and guide text that uses banned wording. A CONTRIBUTING rule says a public-surface change updates the other owning surfaces in the same PR.

### Entry-point checkpoint (after Phase 193)

- [ ] **SIGNAL-01**: At the checkpoint the following are recorded once in `research/v1.48-prep/CHECKPOINT.md` with the date: GitHub traffic referrers, popular paths, views and clones (`gh api repos/szTheory/scrypath/traffic/*`; the data keeps only 14 days, so it is read at the checkpoint and not reconstructed later), hex.pm downloads (all time, last 7 days; `hex.pm/api/packages/scrypath`), the live hex.pm and HexDocs README link behavior, and whether any issue or adopter report arrived. The record ends with the decision: run Phase 194, or cut the milestone after 193 and go to v1.49. If traffic is effectively nil, the default is to cut.

### Website content (Phase 194, optional, cuttable at the checkpoint)

- [ ] **SITE-07**: The website's Docs page and every guide link point at HexDocs (released truth), not `blob/main`; a one-paragraph stub keeps old `docs/` URLs from 404ing. The website static contract fails a `blob/main/guides` link.
- [ ] **SITE-08**: Home, Evaluate and Operate are rewritten for content and information architecture on the existing v1.47 token pipeline (no new CSS framework, no dependency): what it is, one real run (output from the example app, not a claim), honest limits, one install block whose line comes from `mix.exs`. Checks: the forbidden-phrase table, contrast, computed style, axe, link and the existing token checks on every changed page. The PR says plainly that this is not a design review; how the pages read, Safari and real screen readers stay recorded as unproven.
- [ ] **SITE-09**: Outward-facing claims need evidence: no comparison, performance or "time to first search" statement is written without a sourced or measured basis recorded in the phase notes, and any such claim goes to the maintainer as a decision, not a merge.

### Standing guardrails

- [ ] **GATE-03**: Every phase honors the standing rules: squash titles are `docs(...)` or `chore(...)` (no `feat` or `fix`, because no library behavior changes), one full gate run per commit SHA, no new required gate beyond the ledger budget (10 of 12 used; each new gate names a deletion trigger), cheap local checks before pushing (`scripts/ci/pre_push.sh` plus each required lane's local mirror), a fix to a snapshot-based gate is committed before the gate reruns, and the Hex 0.3.20 release PR waits for the maintainer's explicit yes. No Hex release happens in this milestone without that yes.

## v2 Requirements

Deferred; not in this roadmap.

- **CAT-01**: phoenix_storybook catalog foundation (v1.49): spike with a go/no-go on the ADR 0001 triggers (also records the Actions cache effect), fixtures and copy-stub consolidation, rendered-text lint ingesting `copy_rules.json`, storybook route dev-only and loopback-bound, retained-preview refresh as plan 1 of the first rendered-evidence phase, pilot read-only and retry halves. Phase numbers renumbered at its opening (195 onward).
- **SCRN-01**: Screens, flows and full catalog (after v1.49).
- **ADOPT-01**: Adopter features: testing kit, indexable predicate, highlighting passthrough, hit and facet limits, backfill and reindex tasks (grill the API shapes first; revisit at the checkpoint).

## Out of Scope

| Feature | Reason |
|---------|--------|
| Merging, renaming or deleting guides | Filenames are HexDocs URLs; any merge needs adopter evidence (scope guard) |
| A Hex release inside this milestone without the maintainer's yes | Hex releases are the maintainer's explicit decision; 0.3.20 follows Phase 192 |
| Website visual redesign or new design system | v1.47 shipped the identity; Phase 194 is content and information architecture only |
| Named-competitor comparison pages | Every fact would need a source; deferred until there is evidence of demand |
| "Time to first search" or performance claims | No measured newcomer run exists; the example smoke script proves the example path only |
| A merge queue or any branch-protection change | The maintainer's call; not recommended now |
| Catalog, storybook, fixtures, preview refresh | v1.49 |
| New analytics on the site or in HexDocs | Signal comes from GitHub traffic and hex.pm downloads only |
| Claims of independent or aesthetic approval | No person or independent reviewer is simulated |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| TRUTH-01 | Phase 192 | Complete |
| TRUTH-02 | Phase 192 | Complete |
| TRUTH-03 | Phase 192 | Complete |
| README-01 | Phase 192 | Complete |
| README-02 | Phase 192 | Complete |
| README-03 | Phase 192 | Complete |
| DOCS-01 | Phase 193 | Pending |
| DOCS-02 | Phase 193 | Pending |
| GUARD-01 | Phase 193 | Pending |
| GUARD-02 | Phase 193 | Pending |
| GUARD-03 | Phase 193 | Pending |
| SIGNAL-01 | Checkpoint (after Phase 193) | Pending |
| SITE-07 | Phase 194 (optional) | Pending |
| SITE-08 | Phase 194 (optional) | Pending |
| SITE-09 | Phase 194 (optional) | Pending |
| GATE-03 | Standing (every phase) | Pending |

**Coverage:**
- v1 requirements: 16 total
- Mapped to phases: 16
- Unmapped: 0 ✓

---
*Requirements defined: 2026-11-21*
*Last updated: 2026-11-21 after opening v1.48*
