---
gsd_state_version: "1.0"
milestone: v1.40
milestone_name: Readiness Evidence Closure
current_phase: 166
current_phase_name: Host Tenant and Repair Evidence
current_plan: Not started
status: planning
stopped_at: Phase 165 complete, ready to plan Phase 166
last_updated: "2026-09-26T22:54:32Z"
last_activity: 2026-09-26
last_activity_desc: Phase 165 complete, transitioned to Phase 166
state_head: 384c8839db2f021db421d0dbeff096ee439fd721
progress:
  total_phases: 3
  completed_phases: 1
  total_plans: 2
  completed_plans: 2
  percent: 33
---

# Project State

## Project Reference

**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.
**Current Focus:** Phase 166 — Host Tenant and Repair Evidence

## Current Position

Phase: 166 (Host Tenant and Repair Evidence) — PLANNING
Current Plan: Not started
Total Plans in Phase: TBD
Plan: None — phase planning has not started
Plans: 0/TBD summarized
Status: Ready to plan Phase 166
Last activity: 2026-09-26 — Phase 165 complete, transitioned to Phase 166

Progress: [███░░░░░░░] 33% of milestone phases complete

## Milestone Context

**Goal:** Close decision-relevant adopter evidence gaps for tenant-safe search and bounded repair, reuse valid delete and release receipts, and make a fresh six-condition readiness decision without starting operator UI work.

**Scope boundary:** Verify existing public tenant-scope and facet-value input contracts, correct only confirmed compatible defects, prove one representative host-owned tenant search workflow and one bounded manual repair-to-visible-search workflow, and reconcile condition 3/6 evidence. Host authentication, membership policy, trusted tenant selection, and database response scoping remain application-owned. No public backend abstraction, broad endpoint/version matrix, operator UI, new required CI lane, or forced Hex release is included.

**Gate:** Preserve the Phase 164 assessment unchanged: it records conditions 3 and 6 as UNKNOWN and readiness as **NOT READY**. The new assessment is separately dated, evaluates all six conditions independently, and may truthfully remain **NOT READY**. A passing assessment only recommends a later ScrypathOps focus.

## Recent Evidence

- v1.39's final exact-SHA closeout run `36257182675` passed on `dc400b2b57aec0ca6b0ef16c9477d266fd41a433`; annotated tag `v1.39` resolves to that commit. This receipt supports only its recorded claims and source.
- Scrypath 0.3.13 has package-backed Phoenix, exact-SHA, post-merge, Hex/HexDocs, consumer-compilation, and parity receipts from v1.38. They do not broaden the selected v1.40 workflow claims.
- v1.40 research identifies C10-R1 and C11-R1 as unexecuted public-entry hypotheses. No suspected flaw is a reproduced defect or a pass before Phase 165's independent probes.
- Phase 165 Plan 02 at `a883958c73d7f102a7404a317e0d13b7c15ccbd9` reproduced raw keyword-filter tuple serialization failing before HTTP and corrected it through the existing filter renderer. Req.Test and local gates pass; live Meilisearch and package behavior for this exact scenario remain a Phase 166 handoff.
- Phase 165 candidate `384c8839db2f021db421d0dbeff096ee439fd721` passed exact-SHA hosted closeout run `36277023698`; the five required jobs, advisory coverage, and closeout attestation succeeded with immutable artifacts. The final tracking SHA still requires its own closeout.
- C-16 requires one representative ID-scoped manual repair through terminal task success to visible search. C-09 can be reused only after a relevant-path freshness comparison; otherwise its bounded claim needs targeted evidence or UNKNOWN.

## Accumulated Context

### Decisions

- Keep missing evidence, a confirmed defect, and a successful contract reproduction distinct.
- Preserve host ownership of actor authentication, membership policy, trusted tenant derivation, and response scoping; Scrypath evidence proves supplied-scope composition within the named workflow only.
- Use the existing Phoenix path/package harness and current advisory scenario posture. A required advisory scenario pass is acceptance evidence for its exact SHA; it does not become a required merge gate.
- Bound manual repair by an Ecto ID predicate, never by a query limit, and await the returned backend task before claiming visible repair.
- Keep release/package/support identities distinct from the v1.39 planning tag. Reconcile named metadata and release-reference debt explicitly without silently rewriting historical records or deleting unrelated local state.
- Keep the current task's exact-final-SHA closeout separate from reused historical receipts, and do not edit tracked planning files merely to record that external final receipt.
- Keep validated tenant_scope predicates in search options while excluding the search-only key from strict runtime configuration in Single, Many, and FacetValues.
- Treat recorder evidence as library filter-composition proof; host identity, membership, trusted tenant selection, authorization, and database response scoping remain host-owned.
- [Phase 165]: Keep tenant_scope in the validated filter and remove it from all three runtime configuration inputs. — Public recorder probes reproduced strict runtime-config rejection in Single, Many, and FacetValues after schema-aware validation had composed the declared tenant field into filter. Dropping only this search-only key preserves strict runtime validation and the public input shape.
- [Phase 165]: Treat recording-backend tenant evidence as filter-composition proof only. — The tests prove supplied-scope composition and rejection before backend dispatch. Actor identity, membership, trusted tenant derivation, authorization, and database response scoping remain host-owned; this is not live-service or package evidence.
- [Phase 165]: Keep defaults and keyword-filter outcomes separate; retain a targeted live/package follow-up for the reproduced facet serializer defect. — Defaults passed their encoded request probe without correction. The keyword probe failed in Jason before HTTP; the correction now emits the existing filter grammar. This local proof does not establish live parser behavior or package loading. It also does not claim interruption or parallel execution semantics (EA-02).

### Pending Todos

None yet.

### Blockers/Concerns

- The final readiness result is not predetermined. Any insufficient condition or unresolved gate-rank finding leaves the new assessment NOT READY.
- Historical evidence can be reused only after source-identity and relevant-path comparisons; unavailable or invalidated evidence is recorded with its precise limit rather than inferred.
- Phase 165 local implementation, goal verification, and candidate closeout are complete. No live Meilisearch service variables were available locally; final tracking-SHA closeout and Phase 166's scenario-specific path/package service proof remain outstanding.

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| product scope | Operator UI, brand/design work, authentication product, public backend abstraction, and broad compatibility matrices | Deferred; requires a separate evidence-backed scope decision |
| release | Hex publication, retagging, and version bump | Only if a confirmed compatible code fix warrants the existing release train |
| verification topology | New required service lane | Deferred; retain the existing required/advisory split |

## Performance Metrics

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 165. Public Tenant and Facet Contracts | 2/2 | 25 min | 12.5 min |
| 166. Host Tenant and Repair Evidence | TBD | - | - |
| 167. Dated Readiness and Closeout | TBD | - | - |
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 165 P01 | 9 min | 2 tasks | 4 files |
| Phase 165 P02 | 16 min | 2 tasks | 3 files |

## Session Continuity

Last session: 2026-09-26T22:54:32Z
Stopped at: Phase 165 complete, ready to plan Phase 166
Resume file: None

## Operator Next Steps

- Plan Phase 166 with the scenario-specific live/package facet filter proof included.
