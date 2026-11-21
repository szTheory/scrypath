# Roadmap: Scrypath

## Milestones

- 🚧 **v1.49 Catalog foundation** — Phases 195–198 (4 phases, about 15 plans, 23 requirements; opened 2026-11-21; Phase 198 is cut by default and sized after Pause 1; no Hex release) — scope: [catalog-prep/SYNTHESIS.md](research/catalog-prep/SYNTHESIS.md)
- ✅ **v1.48 Discovery and onboarding** — Phases 192–193 (2 phases, 6 plans, 13 of 16 requirements; Phase 194 and SITE-07 to SITE-09 cut at the entry-point checkpoint; shipped to `main` 2026-11-21 via PRs #160, #163, #164; `tech_debt`; Hex 0.3.20 carries Phase 192, the Phase 193 regroup waits for the next release) — [archive](milestones/v1.48-ROADMAP.md)
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

v1.49 Catalog foundation is the active milestone (opened 2026-11-21): a thin, dev-only storybook for ScrypathOps on Scrypath-owned fictional adopter data, with one job (JOB-03, unhealthy verdict to verified retry) taken end to end. Scope is the maintainer's adoption of [catalog-prep/SYNTHESIS.md](research/catalog-prep/SYNTHESIS.md) on top of the recorded 2026-10-25 decision ([ADR 0001](adr/0001-phoenix-storybook-for-scrypath-ops.md)). The run pauses twice: after Phase 197 (the maintainer's first storybook look sizes Phase 198) and at milestone end before the audit. No Hex release is part of this milestone; Hex 0.3.20 (2026-11-21) is the latest release, and the next one needs the maintainer's explicit yes.

v1.48 Discovery and onboarding is archived ([audit](milestones/v1.48-MILESTONE-AUDIT.md), `tech_debt`, no unsatisfied requirement; the optional website phase was cut at the entry-point checkpoint, see [research/v1.48-prep/CHECKPOINT.md](research/v1.48-prep/CHECKPOINT.md)).

`deep-quality` stays an advisory red with one known cause (cloak and cloak_ecto via optional sigra) until sigra ships without a hard `cloak_ecto` requirement; the audit stays fail-closed. The v1.45 archive keeps its documented debt and historical verification overrides.

## Phases

**Phase numbering continues from v1.48 (the first v1.49 phase is 195).** Plan cap is 5 per phase; the milestone stops and re-asks at 20 plans.

- [ ] **Phase 195: Mount and prove** - phoenix_storybook mounted dev/test-only with real styling, boundary tests made non-vacuous, and a measured go/no-go recorded (3 plans)
- [ ] **Phase 196: Fixtures and three adopters** - a `fixtures/scrypath_fixtures` project of pure builders and three Scrypath-owned fictional adopters with named states (4 plans)
- [ ] **Phase 197: Pilot JOB-03, unhealthy verdict to verified retry** - mounted journey first, safe extraction into shared components, catalog contract test, stable storybook on 4003; ends with Pause 1 (5 plans)
- [ ] **Phase 198: Scale** - remaining small screens, Clinicly and Chatly sets, a local browser check; cut by default and sized after Pause 1; ends with Pause 2 (at most 4 plans)

## Phase Details

### Standing rules (every phase)

FLOW-01, FLOW-02, FLOW-03 and FLOW-04 are not deliverables of one phase. They are mapped to Phase 195 for traceability and **stand for every phase** in v1.49 (as GATE-02 did in v1.47):

- FLOW-01: no Hex release or release PR; every PR title is `docs`, `chore`, `test` or `ci`, never `feat` or `fix` (release-please has one root package, so a `feat:` or `fix:` touching `scrypath_ops/` opens a release PR).
- FLOW-02: at most 5 plans per phase; stop and re-ask at 20. Ask-first: an ADR 0001 trigger or no-go, a new required CI context or branch-protection change, root `lib/` behavior (F1, F2), copying from the six sibling brand repos, a runtime dependency beyond the storybook subtree.
- FLOW-03: never stage `.planning/config.json`, `.planning/state.json` or `.impeccable/config.json`; name commit paths explicitly; run the local mirror of each required lane before a push, with a recorded reason for any skipped one.
- FLOW-04: findings F1, F2, D2 and the test-hygiene items are recorded and handed to the maintainer, not fixed, unless the maintainer says so.

### Phase 195: Mount and prove
**Goal**: The storybook mounts in ScrypathOps for dev and test only, renders with the real styling and hooks, can never reach a production graph or the Hex tarball, and a measured go/no-go says whether the milestone continues.
**Depends on**: Nothing (first phase of v1.49; the pre-work PRs #169 and #170 are already merged)
**Requirements**: MOUNT-01, MOUNT-02, MOUNT-03, MOUNT-04, FLOW-01, FLOW-02, FLOW-03, FLOW-04 (FLOW-01 to FLOW-04 stand for every phase)
**Success Criteria** (what must be TRUE; each is an executable check or a recorded decision):
  1. The dependency-boundary test asserts `phoenix_storybook ~> 1.5` is present with `only: [:dev, :test]`, a planted loosening (dependency in prod, or removed) fails it, `PhoenixStorybook` and `MDEx` are absent from every mounted and direct-prod scratch consumer and from the prod-image `verify-dependency-boundaries.sh` lists, and `package_metadata_test` refutes `fixtures` and `storybook` in the Hex tarball.
  2. A test proves the production route table has no `/storybook` path, with a planted case that fails when the environment guard (kept outside the `quote`) is removed; the route is loopback-bound and never mounted in the ecommerce host's production image.
  3. A render-all test loads every variation of the five primitive stories through the real iframe route with `css_path` at the built `/assets/css/app.css` and the `storybook.js` hooks, fails on empty output or `data-phx-error`, and a planted failing story proves it can fail.
  4. `GO-NO-GO.md` records cold and warm `ops-ui` timings from a hosted run, Rust NIF fetch time, lock growth and advisory status, ADR 0001 is amended with those numbers, and each ADR 0001 trigger is explicitly evaluated; continue is pre-authorized unless a trigger trips, in which case the run stops and asks the maintainer.
**Plans**: 1/3 plans executed (cap 5; re-cut from the 2 estimated so the hosted measurement runs on the full phase code and the one decision checkpoint sits in its own plan):
**Wave 1**
- [x] 195-01-PLAN.md — dependency, lock, dev/test route macro with the guard outside the `quote`, boundary row flipped to real, route-guard and loopback proofs, production-graph and Docker-image absence probes, tarball refutes

**Wave 2** *(blocked on Wave 1 completion)*
- [ ] 195-02-PLAN.md — `css_path` and `storybook.js` (separate esbuild profile, tracked bundle), render-all through the real iframe route with a planted failing tree, five primitive stories, hook parity

**Wave 3** *(blocked on Wave 2 completion)*
- [ ] 195-03-PLAN.md — local mirror of every lane, the phase PR as the hosted cold/warm `ops-ui` measurement, `GO-NO-GO.md`, ADR 0001 amendment, stop-and-ask checkpoint when a trigger trips (cold `ops-ui` over 548 s included) or warm is over +60 s, squash-merge on a go, then the record in a planning-only docs PR
**Gate**: go/no-go at the end of the phase (MOUNT-04). A tripped trigger or a no-go stops the milestone for the maintainer.
**UI hint**: yes

### Phase 196: Fixtures and three adopters
**Goal**: Realistic, reachable-state-only fixture data exists for three Scrypath-owned fictional adopters, built so the real `Operator.Status`, `FailedWork` and `Posture` code does the normalizing.
**Depends on**: Phase 195 (a go decision; fixtures still pay off on a no-go, but the run stops there for the maintainer)
**Requirements**: FIX-01, FIX-02, FIX-03, FIX-04
**Success Criteria** (what must be TRUE; each is an executable check or a recorded decision):
  1. The Logistify tracer bullet passes first: a builder in `fixtures/scrypath_fixtures` takes `now`, emits raw Meilisearch task maps and Oban job maps, and a test drives them through the fake client to a rendered posture with a deep queue and nothing failed; the recorded exit rule folds the project into `scrypath_ops/` if no second consumer appears by Phase 197.
  2. Real Meilisearch task payload shapes were recorded once from a task-scoped Docker run (container removed afterward), every fixture failure string comes from a closed table whose entries carry a `source:` pointing at a real Meilisearch error code or Scrypath path, hostile text is stored as escapes, and no failure the library cannot produce is present.
  3. Shopadelic (journey and settings drift), Logistify (deep queue, nothing failed) and Wikily (empty install) each have named states, ordinary data separate from stress variations, and nothing copied from the six sibling brand repos.
  4. The DB-free `check_fixtures` task runs first in its consumers' `test` alias and a planted failing case fails it; two renders with different `now` differ only in time-derived text; `package_metadata_test` asserts `fixtures/` never ships in the Hex tarball; the CI path classifier and `package_contents_test` decisions are recorded; the host's `phase173` fixtures and `?scenario=` branches remain with a recorded deletion trigger.
**Plans**: 4 estimated (cap 5)

### Phase 197: Pilot JOB-03, unhealthy verdict to verified retry
**Goal**: One job (Search health row, to Failed sync prefilled, to retry, to return) is covered by a mounted journey test, extracted into components shared with the story, shown in a stable seeded storybook, and held by one catalog contract test; then the run pauses for the maintainer's look.
**Depends on**: Phase 196
**Requirements**: PILOT-01, PILOT-02, PILOT-03, PILOT-04, PILOT-05, PILOT-06, PILOT-07
**Success Criteria** (what must be TRUE; each is an executable check or a recorded decision):
  1. The mounted `Phoenix.LiveViewTest` journey was written first and passes on current code: Search health row to Failed sync prefilled with the same index and run (asserted in elements and URL params), retry (changed field text, exactly one insert), return link with the same context; denial through the schema allowlist and through stale sudo each has a positive control and an absence check for protected fixture values, and the stale-sudo test at `failed_sync_live_test.exs:540` now renders the row.
  2. The stale-sudo `return_to` defect (D1) is fixed in `scrypath_ops` with its own test and no root `lib/` change, under a `chore` or `test` PR title that says plainly it fixes a defect.
  3. After extraction into pure view-models and shared function components (Search health first, then Failed sync and recovery), a before and after rendered-HTML parity capture shows no unintended change and the step-1 journey stays green unmodified.
  4. `catalog_contract_test.exs` carries render-all, route and component coverage (no hard-coded counts, literal `@no_story` map with reasons), no-identical-variations, copy lint and DOM hygiene checks, each with one planted failing input, runs inside the existing `ops-ui` job as required-gate ledger row 11 of 12 with a deletion trigger recorded in `CONTRIBUTING.md`, and creates no new required CI context.
  5. A seeded storybook runs on 127.0.0.1:4003 with a `storybook` block in `.planning/UI-PREVIEW.json` and a landing page showing `main@sha`, `npm run ui:preflight` checks it, AGENTS.md "UI work" matches, and stories live in the `primitives/ patterns/ areas/ surfaces/ jobs/` tiers with JOB ids in paths, adopter as a variation dimension, both themes shown, and descriptions claiming no more than their linked test proves.
**Plans**: 5 estimated (cap 5): Search health slice first, then Failed sync and recovery, then the contract test and preview wiring.
**Gate (Pause 1)**: the run stops after this phase. The maintainer looks at the storybook on 4003; the feedback is recorded verbatim in a dated note under `.planning/research/` as rows of storybook path, variation id, theme and viewport (or "unknown"), and it sizes Phase 198 as cut, shrink or run (PILOT-07). The run does not continue to 198 on its own.
**UI hint**: yes

### Phase 198: Scale
**Goal**: The catalog covers the remaining small screens and the two further adopters on real states only, with a local browser check; this phase is cut by default and its size is set by the Pause 1 feedback.
**Depends on**: Phase 197 and Pause 1 (the maintainer's feedback sizes, shrinks or cuts this phase)
**Requirements**: SCALE-01, SCALE-02, SCALE-03, FLOW-05 (FLOW-05 also runs after Phase 197 if 198 is cut)
**Success Criteria** (what must be TRUE; each is an executable check or a recorded decision):
  1. Stories exist for the remaining small screens (Control room, help, the failed-sync remainder), each covered by the existing `catalog_contract_test.exs` checks with no new gate; Search and Sync-and-index are added only if the Pause 1 feedback asks.
  2. The Clinicly set shows only denials the product really has (schema allowlist, stale sudo) and the Chatly set shows a reindex swap and CJK text; the decision to proceed with real denials rather than a never-index headline is recorded.
  3. A local browser check over at most 10 fixed iframe URLs (375 and 1280 wide; light, dark, system-dark) fails on serious or critical axe findings, page-level horizontal overflow, and a theme probe that proves the sandbox applies the theme; an ExUnit test asserts every listed URL resolves to a story; it is not a required gate.
  4. The milestone-end review (FLOW-05) is performed: the storybook is refreshed to current `main`, what UI changed and where to look is stated, the run stops (Pause 2) and waits, and the feedback note is recorded for the v1.50 input before the audit.
**Plans**: at most 4 estimated (cap 5); cut by default. If cut, the milestone-end review (Pause 2) happens after Phase 197 and the cut is recorded with the reason.
**Gate (Pause 2)**: milestone-end storybook review before the audit, complete and cleanup steps.
**UI hint**: yes

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 195. Mount and prove | 1/3 | In Progress | - |
| 196. Fixtures and three adopters | 0/4 | Not started | - |
| 197. Pilot JOB-03 | 0/5 | Not started | - |
| 198. Scale | 0/4 | Not started (cut by default) | - |


<details>
<summary>✅ v1.48 Discovery and onboarding (Phases 192-193) — SHIPPED 2026-11-21</summary>

- [x] Phase 192: Docs truth and README (4/4 plans) — PR #160, Hex 0.3.20
- [x] Phase 193: HexDocs regroup and guards (2/2 plans) — PR #163
- [x] Checkpoint: entry-point signal — PR #164 (cut Phase 194)
- [~] Phase 194: Website content — cut at the checkpoint; SITE-07 to SITE-09 moved to the backlog

Archive: [v1.48-ROADMAP.md](milestones/v1.48-ROADMAP.md), [audit](milestones/v1.48-MILESTONE-AUDIT.md).

</details>

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
