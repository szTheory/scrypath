---
gsd_state_version: "1.0"
milestone: v1.40
milestone_name: Readiness Evidence Closure
current_phase: 167
current_plan: Complete
status: completed
stopped_at: Phase 167 tracking complete — external final-source gate before milestone audit
last_updated: "2026-09-27T21:19:58Z"
last_activity: 2026-09-27
last_activity_desc: Phase 167 verified; final tracking prepared for external attestation
state_head: cd83fe703a2a18d3a91ecdd3eacc6d78e367d2b6
progress:
  total_phases: 3
  completed_phases: 3
  total_plans: 8
  completed_plans: 8
  percent: 100
---

# Project State

## Project Reference

**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.
**Current Focus:** v1.40 final-source acceptance, then milestone audit

## Current Position

Phase: 167 (Dated Readiness and Closeout) — verified; final-source continuation follows tracking
Current Plan: Complete
Total Plans in Phase: 3
Plan: 3 of 3
Plans: 3/3
Status: All phase implementation and tracking complete; external final-source acceptance required
Next command: `$gsd-audit-milestone` after the external final-source gate succeeds
Last activity: 2026-09-27 — Phase 167 verified and tracking finalized before exact-SHA attestation

Progress: [██████████] 100% of milestone phases complete

## Milestone Context

**Goal:** Close decision-relevant adopter evidence gaps for tenant-safe search and bounded repair, reuse valid delete and release receipts, and make a fresh six-condition readiness decision without starting operator UI work.

**Scope boundary:** Verify existing public tenant-scope and facet-value input contracts, correct only confirmed compatible defects, prove one representative host-owned tenant search workflow and one bounded manual repair-to-visible-search workflow, and reconcile condition 3/6 evidence. Host authentication, membership policy, trusted tenant selection, and database response scoping remain application-owned. No public backend abstraction, broad endpoint/version matrix, operator UI, new required CI lane, or forced Hex release is included.

**Gate:** Preserve the Phase 164 assessment unchanged: it records conditions 3 and 6 as UNKNOWN and readiness as **NOT READY**. The new assessment is separately dated, evaluates all six conditions independently, and may truthfully remain **NOT READY**. A passing assessment only recommends a later ScrypathOps focus.

## Recent Evidence

- Phase 167's dated assessment at `2026-09-27T19:39:00Z` is NOT READY: conditions 1/3/4/5 PASS, 2 FAIL, 6 UNKNOWN. The consumer Mint 1.9.3 High advisory is unresolved; later CI does not revise this cutoff.
- Phase 167 candidate `441a7e75367e3d354a2da66261850530363cf1f4` passed run `36347716269`; named advisory Phoenix path/package scenarios each passed 16 tests. One earlier mounted-readiness failure remains recorded. Final exact-SHA acceptance must follow all tracking commits and be reported externally with no later tracked write.
- Phase 167 verification passed all three roadmap criteria; 22 focused tests, complete structural checker, L1 mitigation audit, and Nyquist coverage pass. Local Elixir regression passed 4 properties/591 tests with 84 exclusions. These checks do not claim readiness or future final-source CI success.
- v1.39's final exact-SHA closeout run `36257182675` passed on `dc400b2b57aec0ca6b0ef16c9477d266fd41a433`; annotated tag `v1.39` resolves to that commit. This receipt supports only its recorded claims and source.
- Scrypath 0.3.13 has package-backed Phoenix, exact-SHA, post-merge, Hex/HexDocs, consumer-compilation, and parity receipts from v1.38. They do not broaden the selected v1.40 workflow claims.
- v1.40 research began with C10-R1 and C11-R1 as unexecuted hypotheses; Phase 165 independently reproduced the bounded tenant/runtime and facet-serialization defects and corrected them.
- Phase 165 Plan 02 at `a883958c73d7f102a7404a317e0d13b7c15ccbd9` corrected raw keyword-filter tuple serialization through the existing renderer. Phase 166 subsequently proved the named live path/package scenario at its measured source.
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
- [Phase 167]: Keep the eight milestone software claims separate by named scenario and measured source; workflow success is not blanket evidence.
- [Phase 167]: Keep planning tag v1.39, closeout run, published release scrypath-v0.3.13, and the Phase 166 local artifact as distinct identities.
- [Phase 167]: Reuse C-09 only for its bounded claim after every relevant changed path has a semantic disposition; the checker does not decide whether those reasons are true.
- [Phase 167]: Phase 167 Plan 02: keep readiness NOT READY because the Phoenix consumer lock has an unresolved High Mint advisory; no owner acceptance or dependency change is inferred.
- [Phase 167]: Phase 167 Plan 02: preserve unresolved inherited probes and keep final tracking/attestation pending at the dated cutoff.

### Pending Todos

None yet.

### Blockers/Concerns

- [Phase 167] The assessment is NOT READY: Phoenix consumer Mint 1.9.3 has an unresolved High advisory with no owner acceptance; condition 6 was UNKNOWN at the assessment cutoff.
- Historical evidence can be reused only after source-identity and relevant-path comparisons; unavailable or invalidated evidence is recorded with its precise limit rather than inferred.
- [Phase 167] Release-reference mismatch and three accepted archived planning debts remain bounded carry-forwards. Seven Phase 167 assumptions, eleven inherited Phase 166 probes, and six descriptor-less prohibitions remain unresolved constraints.
- [Phase 167] Final-source receipt must be external and match unchanged clean HEAD after every tracking commit. This saved state is the pre-attestation snapshot by design; consult the external run before accepting final completion.

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
| 167. Dated Readiness and Closeout | 3/3 | 125 min executor work; orchestrator/final CI separate | - |
| 167 | 3 | - | - |
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 165 P01 | 9 min | 2 tasks | 4 files |
| Phase 165 P02 | 16 min | 2 tasks | 3 files |
| Phase 166 P01 | 24 min | 2 tasks | 6 files |
| Phase 166 P02 | 14 min | 2 tasks | 1 files |
| Phase 166 P03 | Unmeasured | 2 tasks | 11 files |
| Phase 167 P01 | 36min | 2 tasks | 4 files |
| Phase 167 P02 | 47min | 2 tasks | 6 files |
| Phase 167 P03 | 42min | 2 tasks | 7 files |

## Session Continuity

Last session: 2026-09-27T21:19:58Z
Stopped at: Phase 167 tracking complete; external exact-SHA closeout, then milestone audit
Resume file: None

## Operator Next Steps

- Complete the already authorized external final-source continuation at the committed tracking HEAD. If it fails, repair only the observed cause and attest any new source; no routine human UAT is needed.
- After acceptance, audit v1.40 with `$gsd-audit-milestone`, then choose archive/closure. Do not start operator UI or dependency remediation implicitly.
