# Roadmap: Scrypath

## Milestones

- 🚧 **v1.40 Readiness Evidence Closure** — Phases 165–167 (approved, planning)
- ✅ **v1.39 Pre-Operator UI Quality Readiness Ratchet** — Phases 162–164 (shipped 2026-09-26) — [archive](milestones/v1.39-ROADMAP.md)
- ✅ **v1.38 Packaged Adopter Proof** — Phases 160–161 (shipped 2026-09-25) — `scrypath 0.3.13`; audit: `milestones/v1.38-MILESTONE-AUDIT.md`
- ✅ **v1.37 Code Quality Ratchet** — Phases 148–159 (shipped 2026-08-26) — see `milestones/v1.37-ROADMAP.md`
- ✅ **v1.36 Dependency Security Remediation** — Phases 144–147 (shipped 2026-08-25) — see `milestones/v1.36-ROADMAP.md`
- ✅ **v1.35 Brand System & Logo Identity** — Phases 137–143 (shipped 2026-06-24) — see `milestones/v1.35-ROADMAP.md`
- ✅ **v1.34 Both-Themes Perfection — Dark Signature + AA Gate** — Phases 128–136 (shipped 2026-06-29) — see `milestones/v1.34-ROADMAP.md`

## Current Posture

v1.40 is approved to close bounded condition-3 and condition-6 evidence gaps. It reproduces existing public tenant and facet input contracts, proves one host-owned tenant workflow and one ID-scoped repair-to-visible-search outcome, then makes a separate dated six-condition decision. Phase 164's historical **NOT READY** result remains unchanged. The milestone introduces no authentication product, UI or brand work, public backend abstraction, broad endpoint/version matrix, forced release, or required CI lane.

## Phases

- [x] **Phase 165: Public Tenant and Facet Contracts** - Reproduce existing public inputs and correct only confirmed compatible failures. (completed 2026-09-26)
- [x] **Phase 166: Host Tenant and Repair Evidence** - Prove one host-owned tenant workflow, bounded repair visibility, and valid delete-receipt reuse. (completed 2026-09-27)
- [ ] **Phase 167: Dated Readiness and Closeout** - Reconcile evidence and make a fresh, source-bounded six-condition decision.

## Phase Details

### Phase 165: Public Tenant and Facet Contracts

**Goal**: Consumers can rely on Scrypath's existing public tenant-scope and facet-value input contracts, with corrections only for reproduced compatible defects.
**Depends on**: Phase 164 (completed)
**Requirements**: API-01, API-02
**Success Criteria** (what must be TRUE):

  1. A consumer can use `tenant_scope:` through `search/3`, `search_many/2`, and `search_facet_values/4`; the declared tenant criterion combines with ordinary filters, while conflicting or undeclared tenant input fails before backend dispatch.
  2. A consumer can use documented public filter options, defaults, and keyword filtering with `search_facet_values/4` and receive an endpoint-valid Meilisearch v1.15 request; a reproduced supported-contract failure receives only a compatible correction and focused regression.

**Plans**: 2/2 plans executed

Plans:
**Wave 1**

- [x] 165-01-PLAN.md — Public tenant composition and rejection through an independent recording backend.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 165-02-PLAN.md — Public facet defaults, keyword requests and compatible error behavior through Req.Test.

### Phase 166: Host Tenant and Repair Evidence

**Goal**: A Phoenix host can demonstrate one authorized tenant-search workflow and one bounded repair through visible search without broadening product or CI scope.
**Depends on**: Phase 165
**Requirements**: HOST-01, HOST-02, PKG-04, REPAIR-01, REPAIR-02, DELETE-01
**Success Criteria** (what must be TRUE):

  1. The named host context derives search scope from a trusted actor with valid membership and rejects missing membership, forged tenant selection, and caller-controlled tenant overrides before search; the host retains ownership of authentication and policy.
  2. In the selected mixed-tenant workflow, an authorized tenant receives only permitted IDs and requested metadata, while a separately authorized second tenant is a positive control and no foreign marker appears in raw hits, hydrated records, counts, or facets.
  3. The named tenant workflow succeeds through both the repository-path dependency and freshly built Scrypath package artifact in the existing Phoenix consumer harness; the v1.39 C-09 hard-delete receipt is reused only after a relevant-path freshness comparison, otherwise targeted evidence or an explicit UNKNOWN records its bounded claim.
  4. An operator can inspect a known source/index mismatch without mutation, then choose a manual backfill constrained by an explicit Ecto ID predicate; records outside that selected set remain unchanged.
  5. The exact returned Meilisearch task reaches terminal success on the expected index, and the same Scrypath search returns the repaired raw ID and projected value while control records retain their expected visibility.

**Plans**: 3/3 plans executed

Plans:
**Wave 1**

- [x] 166-01-PLAN.md — Prove host-owned membership authorization, tenant-safe search, hydration, and facets.
- [x] 166-02-PLAN.md — Prove read-only mismatch reporting and ID-bounded repair through visible search.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 166-03-PLAN.md — Record exact-source host and repair evidence and disposition C-09 freshness.

### Phase 167: Dated Readiness and Closeout

**Goal**: Maintainers can make a fresh, source-bounded readiness decision and reconcile task-owned closeout truth without altering historical evidence.
**Depends on**: Phase 166
**Requirements**: GATE-04, CLOSE-03, VERIFY-02
**Success Criteria** (what must be TRUE):

  1. A uniquely dated assessment evaluates all six conditions with linked evidence and claim limits, preserves Phase 164's condition 3/6 UNKNOWN rows and overall NOT READY decision, and records its own truthful PASS, FAIL, or UNKNOWN outcome without starting operator UI work.
  2. Archived v1.39 closeout, package/release, and support evidence are traceable to exact source identities; the release-reference mismatch, accepted planning metadata debt, and only current task-owned cleanup are explicitly dispositioned.
  3. Every v1.40 software acceptance claim has automated, scenario-specific evidence tied to its exact source SHA, with routine human UAT unnecessary; the relevant advisory-lane scenario must pass for its recorded source while remaining distinct from the existing required merge-gate topology, and no broad matrix or new required service lane is added.

**Plans**: 3 plans

**Wave 1**

- [ ] 167-01-PLAN.md — Reconcile bounded scenario evidence, release identities and C-09 freshness.

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 167-02-PLAN.md — Record the dated six-condition assessment and task-owned closeout truth.

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 167-03-PLAN.md — Complete candidate acceptance and the external final-SHA closeout.

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 165. Public Tenant and Facet Contracts | 2/2 | Complete    | 2026-09-26 |
| 166. Host Tenant and Repair Evidence | 3/3 | Complete    | 2026-09-27 |
| 167. Dated Readiness and Closeout | 0/TBD | Not started | - |
