# Roadmap: Scrypath

## Milestones

- [x] **v1.25 shipped + archived in-repo** (**2026-05-26**) — *Tenant-Safe Search Access* — phases **92–94** — [archive](milestones/v1.25-ROADMAP.md)

*(For older milestones v1.0 through v1.24, see the `.planning/milestones/` directory.)*

## Current Milestone

**v1.26 — Facet Value Vocabulary Search** — *active* — opened 2026-05-26

## Phases

- [ ] **Phase 95: API Contract and Execution** - Introduce `Scrypath.search_facet_values/4` and handle payload building, index aliasing, and response parsing. Update documentation and guides.
- [ ] **Phase 96: Verification Gate** - Add `mix verify.phase96` (or `95`) hermetic gate covering the facet value search request/response structures and contract tests.

## Phase Details

### Phase 95: API Contract and Execution

**Goal**: Developers can call `Scrypath.search_facet_values/4` to perform high-cardinality facet type-ahead searches and receive a clean Elixir response.
**Depends on**: Nothing (first phase of v1.26)
**Requirements**: FACET-UX-01, FACET-UX-02, FACET-UX-03, DOC-01, DOC-02
**Success Criteria**:
  1. The function exists and correctly routes to the `/facet-search` endpoint.
  2. The response is parsed into an idiomatic Elixir map or struct (`facetHits`).
  3. Documentation is updated.

**Plans:** 2 plans
- [ ] 95-01-PLAN.md — Introduce backend contract and Meilisearch provider implementation
- [ ] 95-02-PLAN.md — Wire up Scrypath facade and Scrypath.Search logic

### Phase 96: Verification Gate

**Goal**: All new facet value search surfaces are regression-guarded by a single hermetic task.
**Depends on**: Phase 95
**Requirements**: TEST-01, TEST-02
**Success Criteria**:
  1. `mix verify.phase96` runs without errors.
  2. The gate is registered in the CI `quality` job.

**Plans**: TBD

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 95. API Contract and Execution | 2/2 | Complete | 2026-05-26 |
| 96. Verification Gate | 0/? | Not started | - |