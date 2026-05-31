# Roadmap: Scrypath

## Milestones

- ✅ **v1.28 Realistic Demo App & Admin UI Proof** — Phases 102-105 (shipped 2026-05-31) — see `milestones/v1.28-ROADMAP.md`
- ◆ **v1.29 Contract Repair and Proof Hardening** — Phases 106-108 (active)

## Phases

- ✅ **v1.28 Realistic Demo App & Admin UI Proof** — Phases 102-105 shipped on 2026-05-31; full roadmap archived at `milestones/v1.28-ROADMAP.md`
- ○ **Phase 106: Fan-Out Reflection Contract Repair** — Generate and verify `__scrypath__(:fan_outs)` for `use Scrypath, fan_outs:` while preserving hand-written reflection compatibility. Requirements: FAN-01, FAN-02.
- ○ **Phase 107: Ecommerce Readiness Regression Guard** — Prove `/dev/e2e/search-visible` keeps tenant scope when category readiness filtering is present. Requirement: E2E-01.
- ○ **Phase 108: Truth Alignment and Closeout Proof** — Reconcile related-data docs, roadmap/JTBD truth, and verification posture without promoting `phase105-e2e` or adding new breadth. Requirement: TRUTH-01.

## Phase Details

### Phase 106: Fan-Out Reflection Contract Repair

**Goal:** Generate and verify `__scrypath__(:fan_outs)` for `use Scrypath, fan_outs:` while preserving hand-written reflection compatibility.
**Depends on:** Phase 105
**Requirements:** FAN-01, FAN-02
**Success Criteria** (what must be TRUE):
  1. Schemas using `use Scrypath, fan_outs:` expose fan-out metadata through `__scrypath__(:fan_outs)`.
  2. Existing schemas with hand-written fan-out reflection remain compatible.
  3. The repair does not introduce deferred public fan-out helper APIs or broader validation tightening.
**Plans:** 1/1 plans complete
- [x] 106-01-PLAN.md — Fan-out reflection contract repair

### Phase 107: Ecommerce Readiness Regression Guard

**Goal:** Prove `/dev/e2e/search-visible` keeps tenant scope when category readiness filtering is present.
**Depends on:** Phase 106
**Requirements:** E2E-01
**Success Criteria** (what must be TRUE):
  1. Ecommerce readiness probes preserve tenant scope while applying category readiness filtering.
  2. Regression coverage proves the known filter-merge issue without expanding into deeper cross-tenant Playwright fixtures.
**Plans:** 1 plan
- [ ] 107-01-PLAN.md — Ecommerce readiness tenant-scope regression guard

### Phase 108: Truth Alignment and Closeout Proof

**Goal:** Reconcile related-data docs, roadmap/JTBD truth, and verification posture without promoting `phase105-e2e` or adding new breadth.
**Depends on:** Phase 107
**Requirements:** TRUTH-01
**Success Criteria** (what must be TRUE):
  1. Related-data docs describe the repaired fan-out reflection contract accurately.
  2. Planning and JTBD truth keep deferred breadth out of v1.29.
  3. Verification posture remains explicit and does not promote `phase105-e2e` to required CI.
**Plans:** 1 plan
- [ ] 108-01-PLAN.md — Truth alignment and closeout proof

## Progress

| Milestone | Phases | Plans Complete | Status | Shipped |
|-----------|--------|----------------|--------|---------|
| v1.28 Realistic Demo App & Admin UI Proof | 102-105 | 15/15 | Complete | 2026-05-31 |
| v1.29 Contract Repair and Proof Hardening | 106-108 | 0/3 | Active | — |

## Historical Contract Anchors

- [PHASE97-SCOPE-GUARD] Phase 97/98/99 reject runtime breadth expansion unless reopen policy conditions are met. See `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-SCOPE-GUARD.md`.

## Next

Active milestone: **v1.29 Contract Repair and Proof Hardening**. After this repair closeout, return to maintenance, release/support truth, and outside-adopter evidence. Broader feature work still requires outside-adopter evidence or a concrete production bug.
