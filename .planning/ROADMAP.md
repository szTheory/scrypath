# Roadmap: v1.28 - Realistic Demo App & Admin UI Proof

## Phases

- [x] **Phase 102: Admin UI Router Engine Refactor** - Convert scrypath_ops into a mountable router engine (completed 2026-05-30)
- [x] **Phase 103: E-Commerce Host App Foundation** - Scaffold the e-commerce testbed with multi-tenant Ecto schemas (completed 2026-05-30)
- [x] **Phase 104: Search Integration & Operations Proof** - Embed the admin UI and implement LiveView storefront search (completed 2026-05-30)
- [ ] **Phase 105: Hermetic E2E Pipeline** - Validate integration with real Meilisearch and Playwright browser tests

## Phase Details

### Phase 102: Admin UI Router Engine Refactor
**Goal**: `scrypath_ops` is a mountable engine rather than a standalone application
**Depends on**: Nothing (first phase of v1.28)
**Requirements**: OPS-01, OPS-02
**Success Criteria** (what must be TRUE):
  1. Developers can mount `scrypath_ops` within their host application's Phoenix router
  2. The standalone endpoint and repo are removed from `scrypath_ops`
  3. The `scrypath_ops` dashboard functions rely on the host application for web and database dependencies
**Plans**: 3 plans
- [x] 102-01-PLAN.md — Prepare application tree and asset plug
- [x] 102-02-PLAN.md — Build router macro and dynamic configuration injection
- [x] 102-03-PLAN.md — Remove static verified routes and fix internal navigation

### Phase 103: E-Commerce Host App Foundation
**Goal**: A standalone multi-tenant e-commerce host app exists to demonstrate search capabilities
**Depends on**: Phase 102
**Requirements**: APP-01, APP-02, APP-03
**Success Criteria** (what must be TRUE):
  1. Developers can start the `scrypath_ecommerce` app and navigate its domain model
  2. The app stores and retrieves Tenant, Category, Product, and Variant data using Ecto
  3. Browser testing tools can safely run parallel tests utilizing Ecto's SQL sandbox in shared mode
**Plans**: 3 plans
- [x] 103-01-PLAN.md — Catalog Domain Model and Tenancy Foundation
- [x] 103-02-PLAN.md — Seeding Infrastructure
- [x] 103-03-PLAN.md — E2E Test Endpoints and Sandbox

### Phase 104: Search Integration & Operations Proof
**Goal**: The demo app integrates native search with multitenancy, related-data propagation, and an embedded admin UI
**Depends on**: Phase 103
**Requirements**: INT-01, INT-02, INT-03, INT-04
**Success Criteria** (what must be TRUE):
  1. Users can search and filter products via a facet-driven storefront UI
  2. Changing a category name automatically triggers related product search index updates
  3. Operators can access the embedded `scrypath_ops` admin dashboard to observe indexing activity
  4. Search queries strictly isolate data by the active tenant
**Plans**: 4 plans
- [x] 104-01-PLAN.md — Admin dashboard mount and product indexing setup
- [x] 104-02-PLAN.md — Related-data propagation via outbox worker
- [x] 104-03-PLAN.md — LiveView storefront search UI
- [x] 104-04-PLAN.md — Deterministic E2E scenario fixture
**UI hint**: yes

### Phase 105: Hermetic E2E Pipeline
**Goal**: The entire system is validated continuously via an automated end-to-end browser test pipeline against a live search backend
**Depends on**: Phase 104
**Requirements**: E2E-01, E2E-02, E2E-03, E2E-04, E2E-05, E2E-06
**Success Criteria** (what must be TRUE):
  1. CI passes a suite of Playwright browser tests asserting storefront search behaviors
  2. CI automatically validates operator workflows (triage and zero-downtime swaps) via the admin UI
  3. E2E tests assert that related-data changes eventually become visible in the search UI
  4. The testing pipeline relies on a real Meilisearch instance without flakiness or timeouts
**Plans**: 4 plans
- [x] 105-01-PLAN.md — E2E harness and Playwright scaffold
- [ ] 105-02-PLAN.md — Storefront search and related-data E2E proof
- [ ] 105-03-PLAN.md — Operator failed-sync triage E2E proof
- [ ] 105-04-PLAN.md — Zero-downtime swap proof and advisory CI lane

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 102. Admin UI Router Engine Refactor | 3/3 | Complete    | 2026-05-30 |
| 103. E-Commerce Host App Foundation | 4/4 | Complete    | 2026-05-30 |
| 104. Search Integration & Operations Proof | 4/4 | Complete    | 2026-05-30 |
| 105. Hermetic E2E Pipeline | 1/4 | In Progress|  |
