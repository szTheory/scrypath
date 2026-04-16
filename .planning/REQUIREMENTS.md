# Requirements: Scrypath

**Defined:** 2026-04-16
**Milestone:** v1.2 Public Release Trust and Operator Visibility
**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## v1.2 Requirements

### Release Trust

- [x] **REL-01**: Maintainer can publish Scrypath from the canonical GitHub release flow with aligned tag, changelog, manifest, package version, and Hex artifact state.
- [x] **REL-02**: Maintainer can verify the published package from a clean consumer flow that confirms install, docs availability, and basic runtime usability.
- [x] **REL-03**: Maintainer can recover from common release failures using documented runbooks for tag/version drift, failed publish, and published-artifact mismatch.

### Operator Visibility

- [ ] **OPS-01**: Operator can inspect current Scrypath sync status for a schema, including pending work, failed work, and last successful activity where available.
- [ ] **OPS-02**: Operator can inspect and retry failed async or manual work through explicit Scrypath APIs and thin Mix tasks instead of backend-specific spelunking.
- [ ] **OPS-03**: Operator can run an explicit reconcile or recovery workflow that makes drift and reindex state legible without pretending automatic healing.
- [ ] **OPS-04**: Operator can understand sync-mode-specific operational behavior from first-class guides covering inline, Oban, and manual workflows.

### Internal Operations Boundary

- [x] **SEAM-01**: Scrypath exposes operator primitives through Scrypath-owned structs and APIs rather than direct Meilisearch task payloads or Oban-only assumptions.
- [x] **SEAM-02**: Scrypath's internal sync and reindex flows depend on a backend/admin operations seam that preserves the existing Meilisearch-first public contract while making future backend work safer.
- [ ] **SEAM-03**: Backend-native search power remains clearly namespaced and does not widen the common `Scrypath.search/3` contract in this milestone.

## v1.3+ Requirements

### Backend Breadth

- **BACK-03**: Developer can use Scrypath with an additional public backend without weakening the Ecto-first common contract.

### Richer Search Power

- **SRCH-07**: Developer can access more backend-native search capabilities where they materially improve real application search UX.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Second public backend in v1.2 | The first real public release and operator model need to prove the existing Meilisearch-first contract before widening API promises. |
| Universal advanced search DSL across future backends | It would force fake portability exactly where backend behavior diverges most. |
| Built-in dashboard or Phoenix-only operator UI | Scrypath should expose APIs, structs, telemetry, and Mix tasks; presentation belongs to host applications. |
| Vector, hybrid, analytics, or recommendation features | They widen product scope before release trust and operator clarity are settled. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| REL-01 | Phase 11 | Complete |
| REL-02 | Phase 11 | Complete |
| REL-03 | Phase 11 | Complete |
| SEAM-01 | Phase 12 | Complete |
| SEAM-02 | Phase 12 | Complete |
| OPS-01 | Phase 13 | Pending |
| OPS-02 | Phase 13 | Pending |
| OPS-03 | Phase 13 | Pending |
| OPS-04 | Phase 14 | Pending |
| SEAM-03 | Phase 14 | Pending |

**Coverage:**
- v1.2 requirements: 10 total
- Mapped to phases: 10
- Unmapped: 0

---
*Requirements defined: 2026-04-16*
*Last updated: 2026-04-16 after v1.2 roadmap creation*
