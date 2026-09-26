# Requirements: Scrypath — v1.40 Readiness Evidence Closure

**Defined:** 2026-09-26
**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## v1 Requirements

These requirements close selected condition 3 evidence gaps and produce a new, source-bounded review of condition 6. Missing evidence remains distinct from a defect. Confirmed failures in existing supported contracts are corrected within the approved scope; no new product capability is implied.

### Public Search Contracts

- [ ] **API-01**: A Scrypath consumer can use the documented `tenant_scope:` option through each supported public search path (`search/3`, `search_many/2`, and `search_facet_values/4`); the declared tenant criterion is combined with ordinary filters, and conflicting or undeclared tenant inputs fail before backend dispatch.
- [ ] **API-02**: A Scrypath consumer can pass documented public filter options to `search_facet_values/4` and receive an endpoint-valid Meilisearch v1.15 request; defaults and keyword filters are checked at the public input boundary, with a compatible correction and focused regression if a defect is reproduced.

### Host Tenant Search

- [ ] **HOST-01**: A Phoenix host context derives tenant scope from an explicitly trusted actor with valid membership; missing membership, forged tenant selection, and caller-controlled tenant overrides are rejected before search. The evidence is bounded to the example host policy and does not claim Scrypath provides authentication.
- [ ] **HOST-02**: In a mixed-tenant fixture, an authorized tenant search exposes only its permitted record IDs and requested metadata; a separately authorized second tenant is a positive control, and no foreign marker appears in the selected workflow's raw hits, hydrated records, counts, or facets.
- [ ] **PKG-04**: The named host tenant workflow succeeds against both the repository path dependency and the freshly built Scrypath package artifact using the existing Phoenix consumer harness, without adding a separate package matrix or required CI lane.

### Bounded Repair Visibility

- [ ] **REPAIR-01**: An operator can inspect a known source/index mismatch without a mutation, then select a manual backfill bounded by an explicit Ecto ID predicate; a query `limit` is not treated as the repair bound, and records outside the selected ID set remain unchanged.
- [ ] **REPAIR-02**: After the selected backfill is submitted, the exact returned Meilisearch task reaches terminal success on the expected index and the same Scrypath search returns the exact repaired raw ID and expected projected value while control records retain their expected visibility.

### Evidence, Readiness, and Closeout

- [ ] **DELETE-01**: A new condition 3 assessment can reuse the exact-SHA v1.39 hard-delete-to-visible-search receipt when a comparison finds no relevant source invalidator; otherwise it requires targeted fresh evidence or records the bounded claim as UNKNOWN.
- [ ] **GATE-04**: A maintainer can make a separate, uniquely dated assessment of all six readiness conditions using linked evidence and explicit claim limits, while preserving Phase 164's historical condition 3/6 UNKNOWN statuses and overall NOT READY decision.
- [ ] **CLOSE-03**: A maintainer can trace archived v1.39 closeout, package/release and support evidence to their exact source identities, explicitly disposition the observed release-reference mismatch and accepted planning metadata debt, and record current task-owned cleanup without treating unrelated state as debt.
- [ ] **VERIFY-02**: Every v1.40 software acceptance claim has automated evidence tied to its scenario and exact source SHA, routine human UAT is not required, and verification reuses existing CI lanes without adding a new required service lane or broad compatibility matrix.

## Future Requirements

- **OPUI-01**: Begin a separate ScrypathOps milestone only after a new readiness assessment passes all six conditions and maintainer availability supports the work; a passing assessment recommends the focus but does not start it.

## Out of Scope

| Feature | Reason |
|---------|--------|
| ScrypathOps operator/admin UI, visual audit, brand or design-system work | Current jobs are library API, host-policy composition, recovery proof, and readiness reconciliation; UI work remains gated on readiness and maintainer availability. |
| Authentication framework, session design, or generic tenant authorization in Scrypath | Identity, membership, trusted tenant selection, and database response scoping belong to the host application. |
| New public API semantics, public multi-backend support, tenant-token helpers, or backend abstraction | The milestone verifies existing supported contracts and makes only evidence-backed compatible corrections. |
| Broad settings/facet/multi-search package coverage or a backend/version cross-product | Historical opt-outs alone do not establish important workflows; proof is limited to the selected tenant job and confirmed contract defects. |
| Full proof of inline, manual, and Oban deletion/recovery permutations, concurrency ordering, exactly-once processing, or production latency | The selected receipts prove specific paths; broader operational guarantees need separate adopter or incident evidence. |
| New required CI jobs, routine human UAT, or broad reruns of passing suites | Use the cheapest reliable proof layer and current lanes; recurring CI cost must be justified by recurring decision value. |
| Forced Hex publication, retagging, or version bump | A planning milestone is separate from a package release; publish only if a confirmed code fix warrants a release under the existing train. |

## Traceability

The roadmapper will map each v1 requirement to exactly one phase after this requirements set is approved.

| Requirement | Phase | Status |
|-------------|-------|--------|
| API-01 | Pending roadmap | Pending |
| API-02 | Pending roadmap | Pending |
| HOST-01 | Pending roadmap | Pending |
| HOST-02 | Pending roadmap | Pending |
| PKG-04 | Pending roadmap | Pending |
| REPAIR-01 | Pending roadmap | Pending |
| REPAIR-02 | Pending roadmap | Pending |
| DELETE-01 | Pending roadmap | Pending |
| GATE-04 | Pending roadmap | Pending |
| CLOSE-03 | Pending roadmap | Pending |
| VERIFY-02 | Pending roadmap | Pending |

**Coverage:**

- v1 requirements: 11 total
- Mapped to phases: 0
- Unmapped: 11 (roadmap pending)

---
*Requirements defined: 2026-09-26*
*Last updated: 2026-09-26 after v1.40 requirements approval*
