# Requirements: Scrypath — v1.39 Pre-Operator UI Quality Readiness Ratchet

**Defined:** 2026-09-25
**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## v1.39 Requirements

Requirements for the whole-product non-UI readiness assessment. This milestone establishes the baseline, qualifies and dispositions findings, scopes worthwhile follow-up work, and evaluates the approved readiness gate. It does not implement unspecified product changes.

### Baseline

- [x] **BASE-01**: A maintainer can assess every approved non-UI readiness dimension against the relevant adopter or operator jobs and record whether each claim is supported, insufficiently supported, or unknown.
- [x] **BASE-02**: A maintainer can trace each reused or newly gathered evidence item to its source, result, date, commit or hosted run and environment where applicable, claim boundary, freshness, and limitations; missing evidence remains explicit rather than being inferred as a pass or defect.
- [x] **BASE-03**: A maintainer can review the adopter lifecycle from first-hour setup through indexing, search, failure diagnosis, recovery, upgrade, and release using a bounded set of representative roles and integration boundaries, without duplicating canonical evidence.

### Findings and Dispositions

- [x] **FIND-01**: A maintainer can distinguish confirmed behavior defects, evidence gaps, and product opportunities so that missing or stale proof is not mislabeled as a product defect.
- [x] **FIND-02**: A maintainer can rank each confirmed material finding with evidence provenance, affected job, impact and frequency, confidence, compatibility/security/privacy/data-integrity/operational risk, implementation and regression cost, recurring verification cost, and a concise qualitative rationale; severity cannot be averaged away by cost.
- [x] **FIND-03**: A maintainer can close, explicitly accept, defer, or reject each material finding with supporting evidence or rationale, owner decision when risk is accepted, and a revisit trigger when work is deferred; no critical, high, or medium-leverage finding is left without an explicit disposition.

### Bounded Follow-up and Automated Acceptance

- [x] **CLOSE-01**: A maintainer can identify which evidence-qualified findings warrant a separate bounded follow-up milestone with a clear user outcome, scope authority, and automated acceptance claims, or record why no finding qualifies; v1.39 does not invent implementation scope before the baseline establishes a need.
- [x] **CLOSE-02**: Each selected follow-up acceptance claim maps to the cheapest reliable automated evidence layer, with recurring CI promotion justified by confidence gained versus runtime and maintenance cost; routine human UAT is not used for software acceptance.

### Readiness Gate and Closeout

- [x] **GATE-01**: A maintainer can evaluate each of the six approved readiness exit conditions as PASS, FAIL, or UNKNOWN with dated, linked evidence and visible limits; readiness remains NOT READY unless all six pass and no critical, high, or medium-leverage finding remains unresolved.
- [x] **GATE-02**: A maintainer can reconcile release, package, support, CI, planning, and task-owned cleanup truth at closeout, with no verification or cleanup debt hidden by the readiness decision.
- [x] **GATE-03**: A passing readiness decision recommends ScrypathOps as the next strategic focus without automatically authorizing or starting operator UI work.

## Future Requirements

- **FUTURE-01**: Implement confirmed, worthwhile non-UI findings in separately scoped milestones with claim-specific automated verification.
- **FUTURE-02**: Begin a ScrypathOps operator UI milestone only after the readiness gate passes and maintainer availability supports the work.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Unspecified Scrypath runtime, public API, dependency, or backend changes | The baseline has not established a concrete gap; any later change needs evidence, compatibility analysis, and explicit scope review. |
| Autocomplete/suggestions, vector or hybrid retrieval, public multi-backend support, new runtime API categories, hosted search, or framework-facade behavior | These remain outside current scope authority and require a separate owner-approved scope change where applicable. |
| ScrypathOps UI implementation, visual audit, design-system work, or UI readiness claims | Operator UI is sequenced after this non-UI gate and maintainer availability. |
| Broad reruns of passing tests, live service proofs, or compatibility matrices | Repeat only when source drift, freshness, or an identified claim boundary makes existing evidence insufficient. |
| New required CI jobs, scorecards, coverage thresholds, or audit infrastructure without demonstrated decision value | Added recurring cost must be justified by measurable confidence and risk reduction. |
| Routine human verification or UAT for software behavior | Project policy requires machine-verifiable acceptance; human handoffs are reserved for irreducible decisions, credentials, permissions, or physical-world checks. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| BASE-01 | Phase 162 | Complete |
| BASE-02 | Phase 162 | Complete |
| BASE-03 | Phase 162 | Complete |
| FIND-01 | Phase 163 | Complete |
| FIND-02 | Phase 163 | Complete |
| FIND-03 | Phase 163 | Complete |
| CLOSE-01 | Phase 163 | Complete |
| CLOSE-02 | Phase 163 | Complete |
| GATE-01 | Phase 164 | Complete |
| GATE-02 | Phase 164 | Complete |
| GATE-03 | Phase 164 | Complete |

**Coverage:**

- v1.39 requirements: 11 total
- Mapped to phases: 11
- Unmapped: 0

---
*Requirements defined: 2026-09-25*
*Last updated: 2026-09-25 after v1.39 roadmap initialization*
