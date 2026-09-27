---
gsd_state_version: "1.0"
milestone: v1.40
milestone_name: Readiness Evidence Closure
current_phase: 167
current_phase_name: Dated Readiness and Closeout
current_plan: Not started
status: executing
stopped_at: Phase 167 context gathered
last_updated: "2026-09-27T17:45:17.216Z"
last_activity: 2026-09-27
last_activity_desc: Phase 166 complete, transitioned to Phase 167
state_head: 74c2b3277a045f254db1dadc11d1c2d06d4e106f
progress:
  total_phases: 3
  completed_phases: 2
  total_plans: 8
  completed_plans: 5
---

# Project State

## Project Reference

**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.
**Current Focus:** Phase 167 — Dated Readiness and Closeout

## Current Position

Phase: 167 (Dated Readiness and Closeout) — READY TO EXECUTE
Current Plan: Not started
Total Plans in Phase: 3
Plan: —
Plans: 0/3
Status: Ready to execute
Next command: `$gsd-execute-phase 167`
Last activity: 2026-09-27 — Phase 166 complete, transitioned to Phase 167

Progress: [███████░░░] 67% of milestone phases complete

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
- Phase 166 candidate `50d5c12d36ec560525e245bcb992c40e5927854f` passed exact-SHA workflow-dispatch closeout run `36321613553` at attempt 1. Required jobs, coverage, and closeout attestation succeeded; Phoenix advisory job `108626420623` and backend job `108626420717` both contain the named successful Phase 166 scenario receipts.
- Phase 166's historical C-09 receipt is reusable only for its bounded ecommerce raw-hit hard-delete claim; the receipt-to-assessment comparison accounts for all 16 changed relevant paths.

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
- [Phase 166]: Derive tenant scope from the persisted host membership before search or facet dispatch. — A host-owned persisted authorization boundary prevents caller-supplied tenant selections from becoming trusted library scope.
- [Phase 166]: Keep raw search output and host hydration distinct; constrain hydration by tenant and returned IDs. — Separate assertions make raw-hit privacy visible and prevent database filtering from concealing foreign search results.
- [Phase 166]: Use a fixed paginated live query and explicit primary key for exact counts and deterministic Meilisearch setup. — The live evidence requires an exact count and tenant_id makes automatic Meilisearch primary-key inference ambiguous.
- [Phase 166]: Treat the repair report's mismatch as a known fixture precondition. — reconcile_sync reports task and reindex visibility; request telemetry and complete task snapshots establish its read-only behavior without claiming source-row/index-row discovery.

### Pending Todos

None yet.

### Blockers/Concerns

- The final readiness result is not predetermined. Any insufficient condition or unresolved gate-rank finding leaves the new assessment NOT READY.
- Historical evidence can be reused only after source-identity and relevant-path comparisons; unavailable or invalidated evidence is recorded with its precise limit rather than inferred.
- Phase 166's service and candidate-source receipts are complete. Phase 167 owns the separate six-condition assessment; the 11 probe rows and six descriptor-less prohibitions remain unresolved.

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
| 166. Host Tenant and Repair Evidence | 3/3 | Duration unmeasured | - |
| 167. Dated Readiness and Closeout | TBD | - | - |
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 165 P01 | 9 min | 2 tasks | 4 files |
| Phase 165 P02 | 16 min | 2 tasks | 3 files |
| Phase 166 P01 | 24 min | 2 tasks | 6 files |
| Phase 166 P02 | 14 min | 2 tasks | 1 files |
| Phase 166 P03 | Unmeasured | 2 tasks | 11 files |

## Session Continuity

Last session: 2026-09-27T16:26:09.561Z
Stopped at: Phase 167 context gathered
Resume file: .planning/phases/167-dated-readiness-and-closeout/167-CONTEXT.md

## Operator Next Steps

- Begin Phase 167: prepare a separate dated six-condition readiness assessment using the exact-source receipts and their stated claim limits.
