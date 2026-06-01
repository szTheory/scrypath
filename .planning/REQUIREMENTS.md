# Requirements: Scrypath v1.32 Admin UI/UX Design System Cleanup

**Defined:** 2026-06-01
**Status:** Active
**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## Milestone Intent

Scrypath is not reopening runtime product breadth. v1.32 exists to make the existing mounted `/admin/search/*` operator UI easier to understand, more polished, and more reliable as a demo/evidence surface.

## Requirements

### Asset and Theme Contract

- [x] **ASSET-01**: Mounted host apps have an explicit, tested path for loading ScrypathOps CSS/JS under `/admin/search/*`.
- [x] **TOKEN-01**: OPSUI uses Scrypath-owned operator tokens and no undefined spacing/type utility assumptions.
- [x] **BRAND-01**: OPSUI removes Phoenix-default visual residue and follows the Scrypath quiet ops console direction.

### Component System

- [x] **COMP-01**: Repeated admin UI primitives use shared Phoenix components for notices, metrics, empty states, tables, schema selects, toolbars, buttons, code blocks, and modals.
- [x] **A11Y-01**: Shared components provide visible focus, labelled icon controls, semantic headings, labelled fields, safe modals, and 40px minimum hit areas where applicable.

### Screen Cleanup

- [ ] **SCREEN-01**: Posture, failed sync, sync/drift, search/federation, and playbooks follow posture-first IA and clear content hierarchy.
- [ ] **SCREEN-02**: Search and playbook workflows follow natural order: run/inspect first, then save/replay/manage.
- [ ] **VERIFY-01**: Tests cover the asset contract, component semantics, key empty states, schema allowlist safety, and mounted admin smoke paths.

## Out of Scope

| Feature | Reason |
|---------|--------|
| New Scrypath runtime APIs | v1.32 is OPSUI polish, not runtime breadth. |
| Promoting `phase105-e2e` to required CI | Promotion still requires sustained stability evidence and explicit policy change. |
| Productizing ops UI beyond bounded demo/admin proof | Current work is for local evaluation and evidence, not a new commercial admin surface. |
| New search capabilities such as autocomplete, vector, hybrid, or public multi-backend | Existing scope guard still applies. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ASSET-01 | Phase 116 | Active |
| TOKEN-01 | Phase 116 | Active |
| BRAND-01 | Phase 116 | Active |
| COMP-01 | Phase 117 | Complete |
| A11Y-01 | Phase 117 | Complete |
| SCREEN-01 | Phase 118 | Pending |
| SCREEN-02 | Phase 118 | Pending |
| VERIFY-01 | Phase 118 | Pending |
