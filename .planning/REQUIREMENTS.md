# Requirements: Scrypath

**Defined:** 2026-04-16
**Milestone:** v1.1 Release Hardening and Public Launch Readiness
**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## v1.1 Requirements

### Reliability Hardening

- [ ] **HARD-01**: Developer can rely on inline Meilisearch task waiting to report success, timeout, cancellation, malformed payloads, and backend failure through stable explicit result shapes.
- [ ] **HARD-02**: Developer can run shared sync and delete batch entrypoints with empty inputs and receive a defined no-op result instead of ambiguous behavior.
- [ ] **HARD-03**: Developer can trust the Meilisearch-backed workflow tests to cover the edge cases that previously left release confidence in doubt.

### Public Docs Safety

- [x] **DOCS-01**: Phoenix developer can install Scrypath from the README without copying unnecessary direct dependencies or misleading setup steps.
- [x] **DOCS-02**: Phoenix developer can copy the JSON controller pagination example and get safe handling for invalid page params instead of a 500-prone example.
- [x] **DOCS-03**: Phoenix developer can copy the LiveView and context examples knowing the fixture-backed docs tests model real Phoenix string-keyed parameter shapes.

### Launch Confidence

- [x] **SHIP-01**: Maintainer can verify the release path from CI/package checks through GitHub Actions Hex publishing with canonical source and package metadata.
- [ ] **SHIP-02**: Maintainer can point to current verification artifacts for the hardening work and the remaining launch-readiness surface without milestone bookkeeping gaps.

## v1.2+ Requirements

### Backend Breadth

- **BACK-03**: Developer can use Scrypath with an additional public backend without weakening the Ecto-first common contract.

### Richer Search Power

- **SRCH-07**: Developer can access more backend-native search capabilities where they materially improve real application search UX.

### Operator Tooling

- **OPER-06**: Operator can inspect and manage sync drift, failed work, and recovery status with deeper first-class tooling.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Public multi-backend support in v1.1 | The library needs stronger public trust on the existing Meilisearch-first surface before widening API promises. |
| Advanced relevance features such as vector, hybrid, or analytics work | They add breadth before the core public adoption path is hardened. |
| New Phoenix feature surfaces beyond safety/polish fixes | This milestone is about making the existing adoption story dependable, not expanding the product boundary. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| HARD-01 | Phase 8 | Pending |
| HARD-02 | Phase 8 | Pending |
| HARD-03 | Phase 8 | Pending |
| DOCS-01 | Phase 9 | Complete |
| DOCS-02 | Phase 9 | Complete |
| DOCS-03 | Phase 9 | Complete |
| SHIP-01 | Phase 10 | Complete |
| SHIP-02 | Phase 10 | Pending |

**Coverage:**
- v1.1 requirements: 8 total
- Mapped to phases: 8
- Unmapped: 0

---
*Requirements defined: 2026-04-16*
*Last updated: 2026-04-16 after completing Phase 10 Plan 01*
