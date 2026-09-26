---
gsd_state_version: "1.0"
milestone: v1.40
milestone_name: Readiness Evidence Closure
current_phase: 165
current_phase_name: 1 of 3, Public Tenant and Facet Contracts
status: "Phase context gathered; next command: `$gsd-plan-phase 165`."
stopped_at: Phase 165 context gathered
last_updated: "2026-09-26T19:07:42.919Z"
last_activity: 2026-09-26
last_activity_desc: Created the v1.40 three-phase roadmap and mapped all approved requirements.
state_head: c04079ffa1508c1b9f2928c77fa5e441fa71284e
progress:
  total_phases: 3
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
---

# Project State

## Project Reference

**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.
**Current Focus:** v1.40 Readiness Evidence Closure is approved and roadmaped. Phase 165 will classify existing public tenant and facet contracts before the representative host and repair evidence phase.

## Current Position

Phase: 165 (1 of 3, Public Tenant and Facet Contracts)
Plan: Not planned
Status: Phase context gathered; next command: `$gsd-plan-phase 165`.
Last activity: 2026-09-26 — Created the v1.40 three-phase roadmap and mapped all approved requirements.

Progress: [░░░░░░░░░░] 0%

## Milestone Context

**Goal:** Close decision-relevant adopter evidence gaps for tenant-safe search and bounded repair, reuse valid delete and release receipts, and make a fresh six-condition readiness decision without starting operator UI work.

**Scope boundary:** Verify existing public tenant-scope and facet-value input contracts, correct only confirmed compatible defects, prove one representative host-owned tenant search workflow and one bounded manual repair-to-visible-search workflow, and reconcile condition 3/6 evidence. Host authentication, membership policy, trusted tenant selection, and database response scoping remain application-owned. No public backend abstraction, broad endpoint/version matrix, operator UI, new required CI lane, or forced Hex release is included.

**Gate:** Preserve the Phase 164 assessment unchanged: it records conditions 3 and 6 as UNKNOWN and readiness as **NOT READY**. The new assessment is separately dated, evaluates all six conditions independently, and may truthfully remain **NOT READY**. A passing assessment only recommends a later ScrypathOps focus.

## Recent Evidence

- v1.39's final exact-SHA closeout run `36257182675` passed on `dc400b2b57aec0ca6b0ef16c9477d266fd41a433`; annotated tag `v1.39` resolves to that commit. This receipt supports only its recorded claims and source.
- Scrypath 0.3.13 has package-backed Phoenix, exact-SHA, post-merge, Hex/HexDocs, consumer-compilation, and parity receipts from v1.38. They do not broaden the selected v1.40 workflow claims.
- v1.40 research identifies C10-R1 and C11-R1 as unexecuted public-entry hypotheses. No suspected flaw is a reproduced defect or a pass before Phase 165's independent probes.
- C-16 requires one representative ID-scoped manual repair through terminal task success to visible search. C-09 can be reused only after a relevant-path freshness comparison; otherwise its bounded claim needs targeted evidence or UNKNOWN.

## Accumulated Context

### Decisions

- Keep missing evidence, a confirmed defect, and a successful contract reproduction distinct.
- Preserve host ownership of actor authentication, membership policy, trusted tenant derivation, and response scoping; Scrypath evidence proves supplied-scope composition within the named workflow only.
- Use the existing Phoenix path/package harness and current advisory scenario posture. A required advisory scenario pass is acceptance evidence for its exact SHA; it does not become a required merge gate.
- Bound manual repair by an Ecto ID predicate, never by a query limit, and await the returned backend task before claiming visible repair.
- Keep release/package/support identities distinct from the v1.39 planning tag. Reconcile named metadata and release-reference debt explicitly without silently rewriting historical records or deleting unrelated local state.
- Keep the current task's exact-final-SHA closeout separate from reused historical receipts, and do not edit tracked planning files merely to record that external final receipt.

### Pending Todos

None yet.

### Blockers/Concerns

- The final readiness result is not predetermined. Any insufficient condition or unresolved gate-rank finding leaves the new assessment NOT READY.
- Historical evidence can be reused only after source-identity and relevant-path comparisons; unavailable or invalidated evidence is recorded with its precise limit rather than inferred.
- The approved roadmap and research reports govern Phase 165 planning. No implementation, test execution, CI dispatch, or release has occurred during milestone setup.

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| product scope | Operator UI, brand/design work, authentication product, public backend abstraction, and broad compatibility matrices | Deferred; requires a separate evidence-backed scope decision |
| release | Hex publication, retagging, and version bump | Only if a confirmed compatible code fix warrants the existing release train |
| verification topology | New required service lane | Deferred; retain the existing required/advisory split |

## Performance Metrics

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 165. Public Tenant and Facet Contracts | TBD | - | - |
| 166. Host Tenant and Repair Evidence | TBD | - | - |
| 167. Dated Readiness and Closeout | TBD | - | - |

## Session Continuity

Last session: 2026-09-26T19:04:16.512Z
Stopped at: Phase 165 context gathered
Resume file: .planning/phases/165-public-tenant-and-facet-contracts/165-CONTEXT.md

## Operator Next Steps

- Run `$gsd-plan-phase 165` to create the first implementation plan for Phase 165.
