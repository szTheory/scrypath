# Requirements: Scrypath

**Defined:** 2026-05-07
**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## v1.20 Requirements

### Search module declaration and runtime boundary

- [ ] **SMOD-01**: Library consumers can define a context-owned `Scrypath.SearchModule` that declares schema, backend, repo, preload, and request-param rules without adding runtime search verbs to the schema itself.
- [ ] **SMOD-02**: A declared search module exposes `search/2`, `search!/2`, and `search_args/2` that delegate into the existing `Scrypath.search/3` path instead of introducing a second search runtime.
- [ ] **SMOD-03**: Search-module runtime defaults and per-call overrides merge predictably so contexts can keep ownership of backend, repo, preload, and explicit search options.

### Param normalization and errors

- [ ] **SMOD-04**: Search modules accept browser-shaped text, filter, sort, page, facets, and facet-filter params and normalize them into one stable Scrypath-facing shape.
- [ ] **SMOD-05**: Declared filters, sorts, facets, and pagination rules reject undeclared or invalid request input with structured `Scrypath.SearchModule.ParamError` details that identify the failing field.
- [ ] **SMOD-06**: Pagination defaults, limits, and declared facet/filter behavior stay explicit and testable so host apps do not need to duplicate param-casting logic in controllers or LiveViews.

### Docs and verification

- [ ] **SMOD-07**: Guides and examples show the intended Phoenix/Ecto context boundary for search modules, including what the layer does and what it intentionally does not abstract away.
- [ ] **SMOD-08**: Regression tests and doc-contract coverage fail if thin-delegation behavior, param-error semantics, or the primary search-module guide drift from the defended v1.20 contract.

## v2 Requirements

### Search-module depth beyond the foundation

- **SMODX-01**: Public Phoenix-facing helpers for URL, form, and LiveView round-tripping on top of the search-module layer.
- **SMODX-02**: Reusable composition helpers such as presets, scopes, or `search_many/2`-aligned helpers beyond the foundation contract.
- **SMODX-03**: Stronger metadata exposure for declared filters, sorts, facets, and paging intended for UI generation.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Schema-generated runtime search APIs | The schema stays metadata-only; application contexts remain the runtime boundary. |
| Public Phoenix dependency in the core layer | The milestone should improve Phoenix ergonomics without coupling core Scrypath abstractions to Phoenix itself. |
| Public multi-backend expansion or unrelated search-depth bets | v1.20 is a thin ergonomics layer over the existing Meilisearch-first runtime, not a scope-widening milestone. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SMOD-01 | Phase 77 | Pending |
| SMOD-02 | Phase 77 | Pending |
| SMOD-03 | Phase 77 | Pending |
| SMOD-04 | Phase 78 | Pending |
| SMOD-05 | Phase 78 | Pending |
| SMOD-06 | Phase 78 | Pending |
| SMOD-07 | Phase 79 | Pending |
| SMOD-08 | Phase 79 | Pending |

**Coverage:**
- v1.20 requirements: 8 total
- Mapped to phases: 8
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-07*
*Last updated: 2026-05-07 after opening v1.20 Search Module Foundation*
