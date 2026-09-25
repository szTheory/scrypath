# Roadmap: Scrypath

## Milestones

- 🚧 **v1.39 Pre-Operator UI Quality Readiness Ratchet** — Phases 162–164 (planned)
- ✅ **v1.38 Packaged Adopter Proof** — Phases 160–161 (shipped 2026-09-25) — `scrypath 0.3.13`; audit: `milestones/v1.38-MILESTONE-AUDIT.md`
- ✅ **v1.37 Code Quality Ratchet** — Phases 148–159 (shipped 2026-08-26) — see `milestones/v1.37-ROADMAP.md`
- ✅ **v1.36 Dependency Security Remediation** — Phases 144–147 (shipped 2026-08-25) — see `milestones/v1.36-ROADMAP.md`
- ✅ **v1.35 Brand System & Logo Identity** — Phases 137–143 (shipped 2026-06-24) — see `milestones/v1.35-ROADMAP.md`
- ✅ **v1.34 Both-Themes Perfection — Dark Signature + AA Gate** — Phases 128–136 (shipped 2026-06-29) — see `milestones/v1.34-ROADMAP.md`

## Current Posture

v1.39 is active planning work for an evidence-led whole-product non-UI readiness assessment. It establishes an auditable baseline, classifies and dispositions material findings, routes any qualifying remedy into separately bounded follow-up work, and evaluates the six-condition gate. It does not implement unspecified runtime, public API, dependency, backend, operator UI, visual-audit, or design-system changes.

Readiness remains **NOT READY** until every approved dimension and exit condition has adequate evidence, and no critical, high, or medium-leverage non-UI finding remains unresolved. A passing decision recommends ScrypathOps as the next strategic focus; it does not authorize UI work.

## Phases

### 🚧 v1.39 Pre-Operator UI Quality Readiness Ratchet

**Milestone Goal:** Assess Scrypath's non-UI quality and adopter readiness, close evidence-backed critical, high, and medium-leverage gaps in bounded milestones, and establish an auditable gate for when ScrypathOps can become the next strategic focus.

- [x] **Phase 162: Whole-Product Evidence Baseline** - Map the full non-UI adopter lifecycle to evidence, freshness, and claim limits. (completed 2026-09-25)
- [ ] **Phase 163: Findings and Bounded Follow-up** - Turn substantiated observations into explicit decisions and separately scoped, automation-backed follow-up candidates.
- [ ] **Phase 164: Readiness Gate and Reconciliation** - Reconcile readiness evidence and make the fail-closed strategic recommendation.

## Phase Details

### Phase 162: Whole-Product Evidence Baseline

**Goal**: Maintainers can evaluate the whole approved non-UI product surface through representative adopter and operator jobs, with claim-specific evidence and explicit limits.
**Depends on**: Phase 161 (completed)
**Requirements**: BASE-01, BASE-02, BASE-03
**Success Criteria** (what must be TRUE):

  1. A maintainer can inspect every approved readiness dimension and see whether each relevant claim is supported, insufficiently supported, or unknown.
  2. Every reused or newly gathered evidence item links to its source and result, dated provenance, applicable environment, claim boundary, freshness, and known limitations, so absent proof is never reported as a pass or a defect.
  3. The index covers first-hour setup, indexing, search, failure diagnosis, recovery, upgrade, and release for representative roles and integration boundaries while linking canonical evidence instead of duplicating it.

**Plans**: 3/3 plans executed

Plans:
**Wave 1**

- [x] 162-01-PLAN.md — Canonical baseline and first-hour package-to-search tracer

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 162-02-PLAN.md — Feature-owner lifecycle and operator diagnosis/recovery evidence

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 162-03-PLAN.md — Maintainer release/support evidence and whole-baseline integrity audit

### Phase 163: Findings and Bounded Follow-up

**Goal**: Maintainers can make evidence-led decisions about material readiness observations and define only qualifying future work with automated acceptance.
**Depends on**: Phase 162
**Requirements**: FIND-01, FIND-02, FIND-03, CLOSE-01, CLOSE-02
**Success Criteria** (what must be TRUE):

  1. A maintainer can distinguish a confirmed behavior defect from an evidence gap or product opportunity, with evidence provenance and the affected adopter or operator job visible.
  2. Every material finding has a qualitative rank covering impact, frequency, confidence, applicable risk, implementation and regression cost, recurring verification cost, and a rationale that does not allow cost to dilute severity.
  3. Each material finding is closed, accepted, deferred, or rejected with supporting evidence or rationale, an owner decision for accepted risk, and a revisit trigger where work is deferred; no critical, high, or medium-leverage finding lacks a disposition.
  4. Each qualifying finding is either defined as a separate bounded follow-up milestone with a user outcome, scope authority, and automated acceptance claims, or is recorded as not qualifying; v1.39 itself does not invent implementation scope.
  5. Each selected acceptance claim uses the cheapest reliable automated proof layer, and any CI promotion is justified by recurring confidence relative to runtime and maintenance cost without routine human UAT.

**Plans**: TBD

### Phase 164: Readiness Gate and Reconciliation

**Goal**: Maintainers can make an auditable, fail-closed readiness decision from reconciled whole-product evidence.
**Depends on**: Phase 163
**Requirements**: GATE-01, GATE-02, GATE-03
**Success Criteria** (what must be TRUE):

  1. Each of the six approved exit conditions is recorded as PASS, FAIL, or UNKNOWN with dated linked evidence and visible limits; the record remains NOT READY unless all six pass and no critical, high, or medium-leverage finding is unresolved.
  2. The final record reconciles release, package, support, CI, planning, and task-owned cleanup truth, leaving no hidden verification or cleanup debt behind the decision.
  3. Only a passing gate recommends ScrypathOps as the next strategic focus, and that recommendation does not start or authorize operator UI work.

**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 162. Whole-Product Evidence Baseline | 3/3 | Complete    | 2026-09-25 |
| 163. Findings and Bounded Follow-up | 0/TBD | Not started | - |
| 164. Readiness Gate and Reconciliation | 0/TBD | Not started | - |
