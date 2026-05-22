# Requirements: Scrypath — Milestone v1.21

**Defined:** 2026-05-22  
**Milestone:** v1.21 — *Query Toolkit And Phoenix Edge Helpers*  
**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## Milestone goal

Ship a narrow-balanced public edge contract for request-shaped search params: a framework-light query-param toolkit plus thin optional Phoenix URL/form/LiveView helpers over the existing `Scrypath.search/3` runtime, while keeping contexts as the application boundary and avoiding public exposure of current internal query structs.

## v1.21 Requirements

### Public query toolkit

- [ ] **QTK-01**: Apps can cast browser-shaped request params into a stable plain-data search-args shape without exposing `%Scrypath.Query{}` or other current internal query structs as public API.
- [ ] **QTK-02**: The public toolkit normalizes text, filters, sort, pagination, facets, and facet-filter input once at the edge while preserving explicit defaults and limits.
- [ ] **QTK-03**: Invalid edge input returns structured, field-scoped errors that host apps can render directly instead of relying on ad hoc controller or LiveView branching.
- [ ] **QTK-04**: Toolkit output feeds the existing `Scrypath.search/3` path cleanly and does not create a second runtime or move orchestration out of contexts or context-owned search modules.

### Optional Phoenix edge helpers

- [ ] **PHX-01**: Optional Phoenix helpers support URL and form round-tripping over the toolkit without introducing a hard Phoenix dependency in runtime core.
- [ ] **PHX-02**: Optional LiveView helpers support param-driven search flows and error display while keeping URL params as the shareable UI state.

### Docs and verification

- [ ] **DOC-01**: Guides and examples make the boundary explicit: contexts stay canonical, helpers are wrappers, and no schema-generated runtime verbs or UI layer ship in this milestone.
- [ ] **VRFY-01**: Tests and contract coverage fail on drift around plain-data toolkit output, field-scoped errors, helper optionality, and canonical runtime delegation.

## Future requirements

- [ ] **CMP-01**: Reusable composition presets and scopes over the query-toolkit layer once real app pressure proves the common patterns are worth freezing.
- [ ] **CMP-02**: Stronger UI metadata exposure for declared filters, sorts, facets, and paging once the public query-param contract has settled in real apps.

## Out of scope

- Public `%Scrypath.Query{}` or other current internal normalization structs as semver-stable contract — that would freeze implementation detail too early and compound API-regret risk.
- Schema-generated runtime search verbs, controller/LiveView macros, or any helper that turns Scrypath into a framework façade — contexts must remain the application boundary.
- Reusable UI widgets, search-page scaffolds, or form-builder layers — this milestone stops at request-edge helpers, not UI abstractions.
- Broader composition/preset systems — those belong to `v1.22`-shaped pressure, not this narrow slice.
- Public backend-expansion work or adapter-surface widening — `v1.21` is ergonomics work over the existing defended runtime, not a backend strategy change.

## Traceability

| Requirement | Planned phase | Status |
|-------------|---------------|--------|
| QTK-01 | Phase 80 | Planned |
| QTK-02 | Phase 81 | Planned |
| QTK-03 | Phase 81 | Planned |
| QTK-04 | Phase 80 | Planned |
| PHX-01 | Phase 81 | Planned |
| PHX-02 | Phase 81 | Planned |
| DOC-01 | Phase 82 | Planned |
| VRFY-01 | Phase 82 | Planned |

---

*Last updated: 2026-05-22 — opened `v1.21` and locked the milestone to a narrow-balanced public query-param toolkit plus thin optional Phoenix edge helpers.*
