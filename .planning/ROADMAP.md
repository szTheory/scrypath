# Roadmap: Scrypath

## Milestones

- 🚧 **v1.41 Readiness Gate Follow-Through** — Phases 168–170 (planning)
- ✅ **v1.40 Readiness Evidence Closure** — Phases 165–167 (completed/archived locally 2026-09-27; no Hex release; assessment remains NOT READY) — [archive](milestones/v1.40-ROADMAP.md)
- ✅ **v1.39 Pre-Operator UI Quality Readiness Ratchet** — Phases 162–164 (completed/archived locally 2026-09-26) — [archive](milestones/v1.39-ROADMAP.md)
- ✅ **v1.38 Packaged Adopter Proof** — Phases 160–161 (shipped 2026-09-25; `scrypath 0.3.13`) — [archive](milestones/v1.38-ROADMAP.md)
- ✅ **v1.37 Code Quality Ratchet** — Phases 148–159 (shipped 2026-08-26) — [archive](milestones/v1.37-ROADMAP.md)
- ✅ **v1.36 Dependency Security Remediation** — Phases 144–147 (shipped 2026-08-25) — [archive](milestones/v1.36-ROADMAP.md)
- ✅ **v1.35 Brand System & Logo Identity** — Phases 137–143 (shipped 2026-06-24) — [archive](milestones/v1.35-ROADMAP.md)
- ✅ **v1.34 Both-Themes Perfection — Dark Signature + AA Gate** — Phases 128–136 (shipped 2026-06-29) — [archive](milestones/v1.34-ROADMAP.md)

## Current Posture

v1.41's nine requirements and three-phase roadmap below were approved on 2026-09-28 after the requested specialist review. The tenant/facet corrections are on public `main` through PR #85 and exact-SHA post-merge CI run [36644133759](https://github.com/szTheory/scrypath/actions/runs/36644133759). Phase 170's selected documentation and factual tooling are on refreshed public `main` through merged PR #87; exact-main run [36795877117](https://github.com/szTheory/scrypath/actions/runs/36795877117) succeeded, with the path-scoped ecommerce E2E job skipped. PR #83 proposes 0.3.14 but remains blocked by the required approving review; the latest published release is 0.3.13. Issue [#86](https://github.com/szTheory/scrypath/issues/86) is the sole terminal-decision authority. Its six maintainer judgments and final source attestation remain pending. See [review synthesis](research/v1.41/SUMMARY.md).

The historical v1.40 assessment at `2026-09-27T19:39:00Z` remains NOT READY (conditions 1/3/4/5 PASS, 2 FAIL, 6 UNKNOWN). New findings and later receipts belong to a new decision. No new API/backend capability or UI implementation is selected. A terminal READY result recommends later ScrypathOps focus; maintainer availability and a separate scope decision still govern its start.

## Phases

### 🚧 v1.41 Readiness Gate Follow-Through

**Milestone Goal:** Deliver evidenced security and existing contract corrections, improve their recurring verification and adopter guidance, and finish a current six-condition readiness decision without an endless closeout cycle.

- [x] **Phase 168: Dependency Security and Reliable Verification** — Deliver four-graph Mint remediation, the mounted-readiness correction, and economical protection against graph/proof omissions. (completed 2026-09-28)
- [x] **Phase 169: Library Fix Delivery and PR Triage** — Deliver the known tenant/facet corrections, reconcile owned unpublished work, and disposition a finite bot PR cohort. (completed 2026-09-29)
- [ ] **Phase 170: Documentation and Readiness Closeout** — Deliver focused docs cleanup and the warranted patch, then make the terminal readiness decision from final evidence.

## Phase Details

### Phase 168: Dependency Security and Reliable Verification

**Goal**: Maintained repository graphs no longer resolve known affected Mint, and reliable automated evidence proves the actual graphs delivered to public `main`.
**Depends on**: Phase 167 (completed locally); refreshed public-main base and ownership inventory before implementation, not bulk history import.
**Requirements**: MINT-01, MINT-02, MINT-03, DELIV-01
**Upstream input**: [synthesis](research/v1.41/SUMMARY.md), [security review](research/v1.41/SECURITY-REVIEW.md), [delivery review](research/v1.41/DELIVERY-REVIEW.md).
**Success Criteria** (what must be TRUE):

1. Root, Phoenix, ecommerce and standalone Ops resolve an available Mint 1.11.0+ verified against refreshed advisories, with only necessary compatible subtree changes; remediation does not rely on an advisory ignore or imply adopter locks were updated.
2. The mounted startup-readiness correction is delivered with its focused regression and mounted behavior proof; selected PRs originate from a clean current public-main base and preserve unrelated local changes.
3. Root/backend, both Phoenix modes, mounted ecommerce and standalone Ops have passing source-specific evidence for the changed graphs. Phoenix package staging identifies actual resolved Hex dependencies and rejects unexpected graph drift; a Git tag or green required-job badge alone is insufficient.
4. The existing advisory audit path checks all four maintained graphs, surfaces each result/ignore/incomplete scan, preserves locks, and catches a missing graph in its explicit inventory. Incremental fetch/runtime cost is recorded; no new required job, service matrix or duplicate root audit is introduced.
5. Selected changes are merged with required candidate checks and green post-merge `main`; named advisory/path-selected evidence also passes for its source. A blocked merge remains explicit rather than completing delivery.

Planning sequences the mounted-readiness correction first, then four-graph lock remediation, parallel Phoenix graph proof and recurring audit work, and a joined security delivery gate. Do not delay the security correction for bulk planning-history reconciliation or bot triage.

**Plans**: 5/5 plans executed

Plans:
**Wave 1**

- [x] 168-01-PLAN.md — Correct mounted startup readiness and deliver the focused fix from a clean public-main base.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 168-02-PLAN.md — Resolve fixed Mint and necessary HPAX versions in all four maintained graphs.

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 168-03-PLAN.md — Verify Phoenix path and package proofs against actual resolved Hex graphs.
- [x] 168-04-PLAN.md — Audit all maintained dependency graphs in the existing advisory lane.

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 168-05-PLAN.md — Join source-specific proofs, measured audit cost and protected public-main delivery.

### Phase 169: Library Fix Delivery and PR Triage

**Goal**: The known public-contract corrections become available on verified public `main`, and a finite inventory accounts for remaining owned local work and dependency PRs.
**Depends on**: Phase 168
**Requirements**: DELIV-02, TRIAGE-01
**Upstream input**: [synthesis](research/v1.41/SUMMARY.md), [delivery review](research/v1.41/DELIVERY-REVIEW.md).
**Success Criteria** (what must be TRUE):

1. A dated comparison against refreshed public `main` identifies selected runtime, regression/adopter, documentation and planning changes; every owned remainder has a coherent delivery path or evidence-backed disposition. The accumulated local branch is never pushed as the delivery unit.
2. The tenant-option and facet keyword-filter corrections, with their coherent regression and selected host/repair proof, are merged and verified on `main`. Historical semantic evidence is reused only after relevant-source comparison; candidate, PR merge-ref and squash-main receipts remain distinct.
3. Each PR in the cohort frozen at phase start has a keep/update/close/defer disposition with current decision evidence and a revisit trigger where relevant. Recheck selected heads/bases before action; new routine bot PRs do not extend the milestone automatically.
4. The normal patch release rationale for the integrated library corrections is recorded for Phase 170. Selected code left unmerged is blocked delivery unless an explicit maintainer decision changes scope; planning-only archives and low-value bot churn do not hold unrelated fixes hostage.

### Phase 170: Documentation and Readiness Closeout

**Goal**: Adopters receive concise and accurate guidance with the delivered fixes, and maintainers can make a final, source-bounded non-UI readiness decision.
**Depends on**: Phase 169
**Requirements**: DOC-03, GATE-05, CLOSE-04
**Upstream input**: [synthesis](research/v1.41/SUMMARY.md), [adoption review](research/v1.41/ADOPTION-REVIEW.md), [delivery review](research/v1.41/DELIVERY-REVIEW.md).
**Success Criteria** (what must be TRUE):

1. README retains a short first-result route and acceptance/visibility caveat; detailed semantics and return contracts route to their guide/API owners. Duplicate JTBD positioning/navigation is merged without losing unique routes. Directly related wording and obsolete copy assertions are corrected; applicable existing docs checks pass.
2. Final selected docs/code edits are merged with current post-merge proof. The warranted patch uses the existing Release Please, publication and consumer/parity gates; a blocked publication is reported precisely or explicitly deferred by the maintainer, never described as published.
3. Live readiness authority/navigation matches current scope and archived evidence. The seven-dimension/24-claim baseline, named important workflows and new concrete source invalidators bound the review; unchanged passing scenarios are not broadly rerun, and historical assessment bodies remain unchanged.
4. A separately dated terminal record combines all six condition judgments with final source/attestation and delivery receipts. It reports READY only when all six pass, otherwise NOT READY with specific blockers/revisit triggers. Final tracked inputs precede attestation; the terminal record is retained outside the tested tree with durable, discoverable provenance, avoiding another tracked-write/attestation cycle.
5. Task-owned branches, worktrees, services, artifacts and verification debt are cleaned or explicitly dispositioned. Accepted historical limits and unrelated local state are not hidden or deleted. READY recommends later UI focus; it does not initiate it.

Phase 170 has delivered DOC-03 and established the finite readiness inputs, factual validator and terminal-record location. Its final source is being frozen before the exact-source attestation; the terminal decision remains external and must be supplied by the actual maintainer. Existing CI attestation proves job/artifact outcomes, not semantic six-condition readiness; seven-day artifacts alone are insufficient retention.

**Plans**: 7/8 plans executed

Plans:
**Wave 1**

- [x] 170-01-PLAN.md — Refine first-result documentation and consolidate job routes.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 170-02-PLAN.md — Add factual attestation collection and terminal-record validation.

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 170-03-PLAN.md — Bound the evidence set and establish the durable terminal-record pointer.

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 170-04-PLAN.md — Deliver selected docs and tooling changes through the existing PR gates.

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 170-05-PLAN.md — Evaluate and complete the warranted patch release or explicit deferral.

**Wave 6** *(blocked on Wave 5 completion)*

- [x] 170-06-PLAN.md — Reconcile delivered source, readiness evidence and preterminal reports.

**Wave 7** *(blocked on Wave 6 completion)*

- [x] 170-07-PLAN.md — Finish tracked bookkeeping, cleanup and final-source freeze.

**Wave 8** *(blocked on Wave 7 completion)*

- [ ] 170-08-PLAN.md — Attest the frozen source and publish the maintainer's terminal decision.

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 168. Dependency Security and Reliable Verification | 5/5 | Complete    | 2026-09-28 |
| 169. Library Fix Delivery and PR Triage | 5/5 | Complete    | 2026-09-29 |
| 170. Documentation and Readiness Closeout | 7/8 | In Progress|  |

**Next action:** `$gsd-execute-phase 170` — run Plan 08 through exact-source attestation, then stop at the actual maintainer decision checkpoint.

---
_Current requirements: `.planning/REQUIREMENTS.md`. Research entrypoint: `.planning/research/SUMMARY.md`. Historical milestones remain under `.planning/milestones/`._
