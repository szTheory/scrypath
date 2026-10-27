# Roadmap: Scrypath

## Milestones

- **v1.45 Foundation and CI** — Phases 182–185 (approved 2026-10-26; 21 confirmed requirements; Phase 182 planned and ready to execute)
- ✅ **v1.44 Sync correctness** — Phases 178–181 (4 phases, 17 plans, 45 tasks; archived locally 2026-10-26; `tech_debt` carried forward; PR #122 merge/publication pending) — [archive](milestones/v1.44-ROADMAP.md)
- ✅ **v1.43 ScrypathOps UI refinement** — Phases 173–177 (5 phases, 21 plans; archived 2026-10-25; first shipped in `scrypath` 0.3.16) — [archive](milestones/v1.43-ROADMAP.md)
- ✅ **v1.42 ScrypathOps operator/admin UI** — Phase172 (1 phase, 8 plans; archived2026-10-04) — [archive](milestones/v1.42-ROADMAP.md)
- ✅ **v1.41 Readiness Gate Follow-Through** — Phases 168–171 (4 phases, 19 plans; archived 2026-10-02; `tech_debt` accepted; original Phase 170 decision remains NOT READY at its cutoff; later separate readiness assessment is READY) — [archive](milestones/v1.41-ROADMAP.md)
- ✅ **v1.40 Readiness Evidence Closure** — Phases 165–167 (archived locally 2026-09-27; no Hex release; assessment remains NOT READY) — [archive](milestones/v1.40-ROADMAP.md)
- ✅ **v1.39 Pre-Operator UI Quality Readiness Ratchet** — Phases 162–164 (archived locally 2026-09-26) — [archive](milestones/v1.39-ROADMAP.md)
- ✅ **v1.38 Packaged Adopter Proof** — Phases 160–161 (shipped 2026-09-25; `scrypath 0.3.13`) — [archive](milestones/v1.38-ROADMAP.md)
- ✅ **v1.37 Code Quality Ratchet** — Phases 148–159 (shipped 2026-08-26) — [archive](milestones/v1.37-ROADMAP.md)
- ✅ **v1.36 Dependency Security Remediation** — Phases 144–147 (shipped 2026-08-25) — [archive](milestones/v1.36-ROADMAP.md)
- ✅ **v1.35 Brand System & Logo Identity** — Phases 137–143 (shipped 2026-06-24) — [archive](milestones/v1.35-ROADMAP.md)
- ✅ **v1.34 Both-Themes Perfection — Dark Signature + AA Gate** — Phases 128–136 (shipped 2026-06-29) — [archive](milestones/v1.34-ROADMAP.md)

## Current Posture

**Phase 182 is in final phase-goal verification (2026-10-27).** All eight plans and four reviewed repairs are merged. The corrected frozen source has local full189/189 and six eligible hosted189/189 receipts, with the initial ineligible cache producer preserved. The actual repair documentation head passed all required CI jobs, coverage, attestation and full browser proof. Phase completion has not been called.

Continue `$gsd-execute-phase 182` from `/Users/jon/projects/scrypath`, branch `planning/v1.45-foundation-ci`, through mandatory hooks, goal verification and final ROOT-SHA closeout. Preserve unrelated config and retained-preview data. Current source-bound details and limits are in the acceptance records; older receipts remain historical.

The v1.44 archive, its 19 debt items and deferrals remain intact. PR #122 merge/Hex publication remain separate; known dependency-audit debt remains Phase184. This does not complete v1.45 or claim every advisory job is green.

## v1.45 Foundation and CI

**Milestone Goal:** Make browser verification complete and reliable, keep
maintainer tooling out of Hex, reduce dependency overhead, and establish
executable UI quality foundations for v1.46.

**Scope authority:** [confirmed requirements](REQUIREMENTS.md), section 3 of
[the rolling roadmap](reference/ROLLING-ROADMAP.md), and the saved
[UI-engine recommendations](research/ui-quality-engine/RECOMMENDATIONS.md).
Phases 178–181 are complete; numbering continues at 182. v1.46–v1.47 retain
the UI engine, stories, extraction and polish; v1.48 retains adopter features.

## Phases

- [ ] **Phase 182: Reliable full browser verification and CI caches** — Contributors can exercise the full intended browser inventory in an isolated stack with reusable, safe caches.
- [ ] **Phase 183: Maintainer tooling outside the Hex package** — Contributors retain verification commands while adopters receive only supported library/operator surfaces.
- [ ] **Phase 184: Explicit and lean dependency graphs** — Adopters resolve supported dependencies without unused optional-app overhead, and maintainers receive reconciled lockfiles and audit results.
- [ ] **Phase 185: Executable UI quality foundations** — Contributors get token, contrast and drift enforcement while operators retain the current supported appearance.

## Phase Details

### Phase 182: Reliable full browser verification and CI caches

**Goal**: Contributors can run every intended mounted/standalone browser scenario through the canonical full verifier, with a successful bounded hosted run and safe cache reuse.
**Depends on**: Nothing within v1.45; starts from the completed v1.44 source, without implying its merge/publication.
**Requirements**: BROW-01, BROW-02, BROW-03, CACHE-01, CACHE-02
**Success Criteria** (what must be TRUE):
1. The canonical full Docker command starts health-checked mounted and standalone targets, exercises both, preserves isolated cleanup/artifacts and leaves focused verification's service scope intact. (BROW-01)
2. Docker executes the intended follow-up/iteration-3 cases; guards reject the retained local preview, and a collected case inventory reconciles historical counts and intentional skips. (BROW-02)
3. An exact-source scheduled/manual full browser run succeeds within the 30-minute job budget with complete artifacts, no unexplained skips and no retry counted as clean; reconciled assertions reflect current behavior without replacing an unreviewed baseline. (BROW-03)
4. Repeated Docker verification builds restore/export a buildx GHA cache, and the same build succeeds without a cache. (CACHE-01)
5. BEAM jobs safely restore fallback caches across appropriate version/environment keys, invalidate changed-lock inputs and succeed from a cold cache. (CACHE-02)

**Plans**: 8/8 plans merged across 7 waves; final phase-goal verification pending.

Plans:

**Wave 1**

- [x] 182-01-PLAN.md — Full-stack readiness tracer and owned lifecycle (wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 182-02-PLAN.md — Safe Docker browser targets and current assertions (wave 2)
- [x] 182-03-PLAN.md — Strict inventory, attempts and one evidence authority (wave 2)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 182-04-PLAN.md — Run-owned evidence and bounded hosted orchestration (wave 3)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 182-05-PLAN.md — Checked Compose/Bake image handoff and GHA cache reuse (wave 4)

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 182-06-PLAN.md — Compatible download fallback and strict BEAM cache namespaces (wave 5)

**Wave 6** *(blocked on Wave 5 completion)*

- [x] 182-07-PLAN.md — Executable hosted acceptance collector and cache probes (wave 6)

**Wave 7** *(blocked on Wave 6 completion)*

- [x] 182-08-PLAN.md — Real warm/cold and exact-source full-browser acceptance (wave 7)

### Phase 183: Maintainer tooling outside the Hex package

**Goal**: Contributors retain their verification workflow, and installed consumers receive a clean package without repository-only tooling or missing development-path dependencies.
**Depends on**: Phase 182 (working full verification and hosted proof path).
**Requirements**: PKGH-01, PKGH-02, PKGH-03
**Success Criteria** (what must be TRUE):
1. An audited task/support-module inventory lives under the unpackaged `dev/mix/tasks` tree; neither the archive nor a compiled consumer contains repository-only verifier modules. (PKGH-01)
2. Documented canonical/historical source-checkout commands remain callable in their intended environments, and an unpacked package compiles with no development tree. (PKGH-02)
3. The package/parity gate inspects actual archive/consumer behavior, fails if maintainer tooling leaks back into the package, and proves supported public operator tasks remain usable. (PKGH-03)

**Plans**: TBD during phase planning.

### Phase 184: Explicit and lean dependency graphs

**Goal**: Adopters receive explicit, compatible dependencies and a lighter mounted Ops app, with truthful upgrade and security evidence across the affected graphs.
**Depends on**: Phase 183 (unpacked-consumer and command-parity proof).
**Requirements**: DEP-01, DEP-02, DEP-03, DEP-04, DEP-05, DEP-06, DEP-07
**Success Criteria** (what must be TRUE):
1. The root directly declares `telemetry ~> 1.0`; instrumentation and focused HTTP/consumer checks pass with each admitted Req line (`~> 0.6.1` and `~> 0.7`). (DEP-01, DEP-02)
2. ScrypathOps runs without Swoosh/Mailer and builds/runs in test/production without esbuild/Tailwind Mix dependencies; the development asset workflow remains usable. (DEP-03, DEP-05)
3. A mounted adopter does not load standalone/development dashboard or polling/metrics dependencies, while supported standalone/development diagnostics and core telemetry still work. (DEP-04)
4. The relaxed compatible Sigra range passes optional-integration/auth checks, and audit failures are reported rather than suppressed. (DEP-06)
5. Affected manifests/lockfiles form one verified update set with supported-stack checks, recorded dispositions for the roadmap's referenced Dependabot updates and explicit remaining advisory results. (DEP-07)

**Plans**: TBD during phase planning.

### Phase 185: Executable UI quality foundations

**Goal**: Contributors can enforce one token/contrast contract using existing required lanes, with no new paid-review path and no unintended visible UI change.
**Depends on**: Phase 184 (stable dependency and asset-build boundaries); uses Phase 182's working browser proof and Phase 183's relocated contracts.
**Requirements**: UIF-01, UIF-02, UIF-03, UIF-04, UIF-05, UIF-06
**Success Criteria** (what must be TRUE):
1. Required static checks reject every new prohibited literal outside explicit token authorities; the legacy violation baseline cannot grow or exchange an old violation for a new one. (UIF-01)
2. Built/rendered light/dark evidence preserves supported appearance and operator routes after the colour-namespace reset and generator-home removal, with required daisyUI black/white and spacing/type defaults retained. (UIF-02, UIF-03)
3. The canonical required repository-contract command executes light/dark AA contrast checks, including focus/adjacent-background pairs at 3:1, and executable negative cases prove failures block it. (UIF-04)
4. Valid DTCG Ops light/dark tokens match the live CSS themes, and changing either side to diverge fails the drift test. (UIF-05)
5. The old judge entrypoints, environment wiring and docs offer no paid OpenAI request or mock assumed-pass path; they truthfully identify the remaining deterministic checks and deferred agent-run review. (UIF-06)

**Plans**: TBD during phase planning.

## Verification and delivery boundaries

- Keep the existing five required jobs and advisory/path-scoped posture. New
  deterministic checks run in existing lanes; full browser remains advisory.
- Follow CONTRIBUTING.md for changed-scope checks and exact-SHA phase/milestone
  closeout. No manual UAT, simulated independent reviewer or paid judge.
- UI-related implementation must read the named preview checkout, run preflight
  there, preserve its data and follow the maintained review protocol. Disposable
  verification stacks and the retained preview have separate lifecycles.
- Preserve current supported UI; unexpected visual differences need reconciliation
  or a maintainer decision before implementation proceeds. Do not auto-update a
  baseline to obtain a pass.
- Reconcile the base with merged main before implementation as needed; the local
  v1.44 ancestor and PR #122 are distinct from current public delivery evidence.
- Do not silently absorb the rest of v1.44's debt or deferred feature milestones.

## Progress

**Execution Order:** 182 → 183 → 184 → 185. Phase 182 is planned; execution has not started.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 182. Reliable full browser verification and CI caches | 8/8 | In Progress | — |
| 183. Maintainer tooling outside the Hex package | 0/TBD | Not started | — |
| 184. Explicit and lean dependency graphs | 0/TBD | Not started | — |
| 185. Executable UI quality foundations | 0/TBD | Not started | — |

**Coverage:** 21/21 confirmed requirements map to exactly one phase; none are complete.
