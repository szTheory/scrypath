# Roadmap: Scrypath

## Milestones

- 🚧 **v1.48 Discovery and onboarding** — Phases 192–193, an entry-point checkpoint, then an optional 194 (active; about 7 plans; docs truth and README, HexDocs regroup and guards, website content only if the checkpoint supports it; cut line after 193)
- ✅ **v1.47 Brand completion** — Phases 188.1, 189–191 (4 phases, 8 plans, 18 of 18 requirements; shipped to `main` 2026-11-20 via PRs #149, #152, #153, #154; `tech_debt`; not released to Hex; website deployed) — [archive](milestones/v1.47-ROADMAP.md)
- ✅ **v1.46 Brand foundation and re-skin** — Phases 186–188 (3 phases, 16 plans, 27 of 29 requirements; shipped to `main` 2026-11-19 via PRs #137, #138, #139, #143; `tech_debt`; not released to Hex; Phases 189 and 190 landed in v1.47) — [archive](milestones/v1.46-ROADMAP.md)
- ✅ **v1.45 Foundation and CI** — Phases 182–185 (archived locally 2026-11-01; qualified `tech_debt` closeout; final-source acceptance external; merge/publication separate) — [archive](milestones/v1.45-ROADMAP.md)
- ✅ **v1.44 Sync correctness** — Phases 178–181 (4 phases, 17 plans, 45 tasks; archived locally 2026-10-26; `tech_debt` carried forward; PR #122 merge/publication pending) — [archive](milestones/v1.44-ROADMAP.md)
- ✅ **v1.43 ScrypathOps UI refinement** — Phases 173–177 (5 phases, 21 plans; archived 2026-10-25; first shipped in `scrypath` 0.3.16) — [archive](milestones/v1.43-ROADMAP.md)
- ✅ **v1.42 ScrypathOps operator/admin UI** — Phase 172 (1 phase, 8 plans; archived2026-10-04) — [archive](milestones/v1.42-ROADMAP.md)
- ✅ **v1.41 Readiness Gate Follow-Through** — Phases 168–171 (4 phases, 19 plans; archived 2026-10-02; `tech_debt` accepted; original Phase 170 decision remains NOT READY at its cutoff; later separate readiness assessment is READY) — [archive](milestones/v1.41-ROADMAP.md)
- ✅ **v1.40 Readiness Evidence Closure** — Phases 165–167 (archived locally 2026-09-27; no Hex release; assessment remains NOT READY) — [archive](milestones/v1.40-ROADMAP.md)
- ✅ **v1.39 Pre-Operator UI Quality Readiness Ratchet** — Phases 162–164 (archived locally 2026-09-26) — [archive](milestones/v1.39-ROADMAP.md)
- ✅ **v1.38 Packaged Adopter Proof** — Phases 160–161 (shipped 2026-09-25; `scrypath 0.3.13`) — [archive](milestones/v1.38-ROADMAP.md)
- ✅ **v1.37 Code Quality Ratchet** — Phases 148–159 (shipped 2026-08-26) — [archive](milestones/v1.37-ROADMAP.md)
- ✅ **v1.36 Dependency Security Remediation** — Phases 144–147 (shipped 2026-08-25) — [archive](milestones/v1.36-ROADMAP.md)
- ✅ **v1.35 Brand System & Logo Identity** — Phases 137–143 (shipped 2026-06-24) — [archive](milestones/v1.35-ROADMAP.md)
- ✅ **v1.34 Both-Themes Perfection — Dark Signature + AA Gate** — Phases 128–136 (shipped 2026-06-29) — [archive](milestones/v1.34-ROADMAP.md)

## Current Posture

v1.48 Discovery and onboarding is the active milestone (opened 2026-11-21 exactly as recommended in [reference/ROLLING-ROADMAP.md](reference/ROLLING-ROADMAP.md) "Post-v1.47 proposal"; prep notes in [research/v1.48-prep/](research/v1.48-prep/), note D is the tie-breaker). The housekeeping that preceded it is merged: PRs #157 (axe accessible names, the vacuous e2e regex, two qualified doc lines) and #158 (README self-links); Dependabot #129, #150 and #151 follow on green. Requirements are defined (16) and mapped below. Next: `/gsd-discuss-phase 192`. v1.47 is complete and archived ([audit](milestones/v1.47-MILESTONE-AUDIT.md), `tech_debt`, no unsatisfied requirement). Hex 0.3.19 (2026-11-20) is the latest release; Hex 0.3.20 is expected to follow Phase 192 and needs the maintainer's explicit yes. The catalog foundation is v1.49.

`deep-quality` stays an advisory red with one known cause (cloak and cloak_ecto via optional sigra) until sigra ships without a hard `cloak_ecto` requirement; the audit stays fail-closed. The v1.45 archive keeps its documented debt and historical verification overrides.

## v1.48 Discovery and onboarding

**Milestone goal:** The README, HexDocs and (if the checkpoint supports it) the website tell a first-time reader the same true thing, once, and keep doing so: no shipped doc names a repo-only task, the README does one job, the HexDocs sidebar is grouped by job, and guards keep the surfaces from drifting.

**Inputs:** [REQUIREMENTS.md](REQUIREMENTS.md); [ROLLING-ROADMAP.md](reference/ROLLING-ROADMAP.md) "Post-v1.47 proposal"; prep notes [A discovery and onboarding](research/v1.48-prep/A-discovery-and-onboarding-milestone.md), [B catalog readiness](research/v1.48-prep/B-catalog-milestone-readiness.md), [C sequencing, release and CI](research/v1.48-prep/C-sequencing-release-and-ci.md), [D adversarial pass and synthesis](research/v1.48-prep/D-adversarial-and-synthesis.md) (D wins where notes conflict); [DISCOVERY-AND-ONBOARDING-JOURNEY.md](reference/DISCOVERY-AND-ONBOARDING-JOURNEY.md), [SEED-004](seeds/SEED-004-website-refresh.md) and the README todo. D's corrections apply: the README HexDocs self-links were the strongest defect (fixed in #158); the support guide bullets already carry a source-checkout qualifier, so the remaining unqualified `verify.adopter` mentions are narrower than note A says; the invariant must change together with the `PROJECT.md` Canonical Adopter Contract text.

**Verification default:** no human UAT. Every success criterion is an executable check (docs contract tests, a built-docs link and self-link scan, word and link counts, a forbidden-phrase table, snippet and install-line parity, and for Phase 194 the existing contrast, computed-style, axe and link checks) or a recorded number or decision stated as such. Each phase record carries a "what this does not prove" line: whether the pages read clearly, brand fit, Safari, real screen readers and whether Elixir developers find them are unproven, and nothing here claims aesthetic or independent-review approval.

**Cut line and checkpoint:** after Phase 193 the entry-point numbers are recorded (SIGNAL-01) and decide Phase 194. If traffic is effectively nil, stop after 193 and complete the milestone as a docs-truth milestone, then go to v1.49 (or to adopter features, per the grilling held at the checkpoint).

**Guardrails (GATE-03, standing):** `docs(...)` or `chore(...)` squash titles; one full gate run per commit SHA; the required-gate ledger stands at 10 of 12 and any new gate names its deletion trigger; local mirrors of each required lane run before every push (`scripts/ci/pre_push.sh` plus the lane commands); guide-, test-, `mix.exs`- or website-touching PRs cost about 19 minutes of wall time, README-only PRs about 7 minutes; a snapshot-based gate is rerun only after its fix is committed. The Hex 0.3.20 release PR (and its changelog hand-edit) needs the maintainer's explicit yes; a release-please PR needs the close and reopen (or `gh pr update-branch`) nudge before its CI runs.

## Phases

**Phase Numbering:**
- Integer phases 192-194 continue from v1.47 (ended at 191). The catalog milestone that earlier notes numbered 192-196 is renumbered at its opening (v1.49); the old numbers appear only in planning text.

- [x] **Phase 192: Docs truth and README** - A reader of any shipped doc is never told to run a task they cannot run, and the README does one job with working links (about 3 plans; Hex 0.3.20 follows, needs a yes) (completed 2026-11-21)
- [ ] **Phase 193: HexDocs regroup and guards** - The HexDocs sidebar is grouped by job with a short first group, and link, install-line, snippet and wording guards keep the surfaces from drifting (about 2 plans)
- [ ] **Checkpoint: entry-point signal** - GitHub traffic, hex.pm downloads and live-link behavior are recorded once and decide whether Phase 194 runs (0 plans)
- [ ] **Phase 194: Website content (optional)** - Home, Evaluate and Operate carry the same owned claims and Docs points at HexDocs, on the existing token pipeline (about 2 plans; cut if the checkpoint shows almost no traffic)

## Phase Details

### Phase 192: Docs truth and README

**Goal**: No Hex-shipped doc instructs an adopter to run a repo-only task, the contract text and the check agree, and the README (the GitHub front page, hex.pm page and HexDocs landing page) does one job and its links resolve.
**Depends on**: Nothing (the HexDocs self-links and the `docs/` qualifiers were fixed in #157 and #158 before the milestone opened).
**Requirements**: TRUTH-01, TRUTH-02, TRUTH-03, README-01, README-02, README-03
**Success Criteria** (what must be TRUE):
  1. The invariant test fails on a planted unqualified `mix verify.adopter` line in a shipped guide and passes on a planted source-checkout-qualified line, and it derives the repo-only task list from `dev/mix/tasks/` rather than a hand-kept list.
  2. Every previous assertion that pinned `verify.adopter` or the shipped-docs wording is accounted for in the phase inventory (claim or wiring, and where its intent now lives); none is deleted without a stronger replacement, and the `PROJECT.md` Canonical Adopter Contract text changed in the same commit.
  3. The built docs have no self-link and no unresolved extras link (scan with a planted failing case), and the README header pin test is green.
  4. The README is within the recorded word cap, has at most three onward links after the quick path, no "Choose a route" block, the Meilisearch prerequisite and eventual consistency before its first code block, and a quick path that ends in a `Scrypath.search/3` result; a test fails any time-promise phrase.
  5. The owner map note exists and names one owning surface for each claim.
**Plans**: 4/4 plans complete (sequential waves; split from about 3 because the contract-and-pin commit must stand alone and the README must be rewritten last)

Plans:
- [x] 192-01-PLAN.md — Derived repo-only scanner with planted cases, pin inventory, and in-place qualifiers so the shipped set is clean
- [x] 192-02-PLAN.md — Invariant switched on with the PROJECT.md contract edit and the guide-pin rewrites in one commit; removed-claim inventory with the claim moves to the drift guide and golden path; claim owner map with checked Pinned-by entries
- [x] 192-03-PLAN.md — Built-docs link scan (self-link, unresolved, dead anchor) with planted cases; 16 repo-path links made absolute; source-level link rule
- [x] 192-04-PLAN.md — Quick path and golden-path config fix, README route and section pins re-pointed to owners against the old README, README trimmed in its own commit with the README contract tests; full local lane mirrors

**What this does not prove**: that the new README reads better to a newcomer; time to first search.

### Phase 193: HexDocs regroup and guards

**Goal**: A reader in the HexDocs sidebar finds the right guide by job from a short first group, and mechanical guards keep README, guides and (later) the site from drifting.
**Depends on**: Phase 192 (the owner map and the README quick path).
**Requirements**: DOCS-01, DOCS-02, GUARD-01, GUARD-02, GUARD-03
**Success Criteria** (what must be TRUE):
  1. `mix docs` builds with no warnings, the first sidebar group has at most five items, every extra is in exactly one group, and no guide was renamed, merged or deleted.
  2. The fate of `guides/overview.md` is recorded and, if it left `extras`, no shipped link points at its old page.
  3. The link check passes on the built docs and README and fails a planted self-link and a planted dead target.
  4. The install line equals the `mix.exs` version in every place it appears, and the schema snippet is identical across README and golden path or carries an explicit "intentionally differs" marker.
  5. The forbidden-phrase table fails a planted banned phrase in README and guide text, and `CONTRIBUTING.md` carries the same-PR rule for public-surface changes.
**Plans**: about 2 (regroup and the overview decision; guards and the CONTRIBUTING rule)
**What this does not prove**: that the grouping matches how readers look for things.

### Checkpoint: entry-point signal

**Goal**: Decide whether Phase 194 runs on numbers rather than hope, and keep the 14-day GitHub traffic window from expiring unrecorded.
**Depends on**: Phase 193.
**Requirements**: SIGNAL-01
**Success Criteria** (what must be TRUE):
  1. `research/v1.48-prep/CHECKPOINT.md` records, with the date, GitHub traffic referrers, popular paths, views and clones, hex.pm downloads (all time and last 7 days), the live hex.pm and HexDocs README link behavior and any issue or adopter report.
  2. It ends with the decision (run 194, or cut after 193) and, if the milestone is cut, whether v1.49 is the catalog or adopter features.
**Plans**: 0 (a recorded check)

### Phase 194: Website content (optional)

**Goal**: A visitor to the website gets the same owned claims as the README and HexDocs, with Docs pointing at released truth.
**Depends on**: The checkpoint decision (cuttable).
**Requirements**: SITE-07, SITE-08, SITE-09
**Success Criteria** (what must be TRUE):
  1. No website link points at `blob/main/guides`; the Docs page and guide links go to HexDocs and a stub keeps old `docs/` URLs alive (static contract).
  2. Home, Evaluate and Operate pass the forbidden-phrase table, contrast, computed-style, axe and link checks, and the install line comes from `mix.exs`.
  3. Every outward claim has a recorded source or measurement; any comparison, performance or time-to-first-search claim is raised as a maintainer decision.
**Plans**: about 2 (information architecture and Docs routing with the contract; content pages with the checks)
**What this does not prove**: how the pages read, Safari, real screen readers; not a design review.

<details>
<summary>✅ v1.47 Brand completion (Phases 188.1, 189-191) — SHIPPED 2026-11-20</summary>

- [x] Phase 188.1: CI path classifier (1/1 plans) — PR #149
- [x] Phase 189: Website re-skin (3/3 plans) — PR #152
- [x] Phase 190: Wording that does not need the catalog (2/2 plans) — PR #153
- [x] Phase 191: Cleanup (2/2 plans) — PR #154

Archive: [v1.47-ROADMAP.md](milestones/v1.47-ROADMAP.md), [audit](milestones/v1.47-MILESTONE-AUDIT.md).

</details>

<details>
<summary>✅ v1.46 Brand foundation and re-skin (Phases 186-188) — SHIPPED 2026-11-19</summary>

See [v1.46-ROADMAP.md](milestones/v1.46-ROADMAP.md).

</details>

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 192. Docs truth and README | 4/4 | Complete    | 2026-11-21 |
| 193. HexDocs regroup and guards | 0/2 | Not started | - |
| Checkpoint: entry-point signal | 0/0 | Not started | - |
| 194. Website content (optional) | 0/2 | Not started | - |
