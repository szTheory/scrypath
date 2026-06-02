# Research Summary: Scrypath Demo App & Admin UI Proof (v1.28)

## Executive Summary

The Scrypath Demo App (v1.28) serves as the definitive proof-of-concept for integrating the Scrypath search library and its operations dashboard (`scrypath_ops`) into a real-world Elixir application. Experts build this type of reference architecture by eschewing trivial domains (like a simple blog) in favor of a Multi-tenant B2B E-commerce Marketplace. This complex domain naturally stresses advanced features like multitenancy, related-data propagation, and high-cardinality faceting.

The recommended architectural approach is to strictly isolate the demo app in an `examples/scrypath_ecommerce` directory with its own dependency tree, preventing dependency bloat in the core library. Crucially, `scrypath_ops` must be refactored from a standalone sidecar application into a mountable router engine (similar to `Oban.Web` or `Phoenix.LiveDashboard`). This allows adopters to embed the operations UI directly within their own Phoenix routers, natively utilizing their host application's authentication and Ecto connections.

The key risks involve test isolation and CI stability when proving this integration. End-to-end testing with Playwright (Node.js `@playwright/test`) running against a live Meilisearch instance in CI provides the ultimate validation. Mitigating these risks requires careful configuration of the Ecto SQL Sandbox in shared mode for browser tests, utilizing ephemeral ports, and ensuring reliable Docker service healthchecks in GitHub Actions.

## Key Findings

### Stack
- **Core:** Phoenix & LiveView (1.8+/1.1+) for the host app and embedded admin UI; Ecto (3.13+) for the strict source of truth.
- **Database & Search:** PostgreSQL (15+) as primary datastore; real Meilisearch container in CI (mocking is explicitly discouraged for this milestone).
- **Testing:** ExUnit + LiveViewTest for fast UI state verification, augmented by standard Node.js `@playwright/test` for robust, cross-browser E2E testing.

### Features
- **Table Stakes:** Ecto + Oban background sync integration, an integrated `scrypath_ops` dashboard, true multitenant search isolation, and CI tests against real Meilisearch.
- **Differentiators:** E2E tests covering zero-downtime index swapping, related-data propagation (e.g., category name changes reflecting on products), and operator triage simulation (diagnosing failed syncs via UI).
- **Anti-Features:** Do not build custom UI component libraries, avoid trivial domains, and strictly avoid synchronous indexing defaults.

### Architecture
- **Mountable Admin UI:** `scrypath_ops` should expose a router macro (`scrypath_ops "/search", schemas: [...]`) rather than running as an independent Phoenix app.
- **Component Boundaries:** The host app (`scrypath_ecommerce`) handles auth, routing, and schemas; `scrypath` handles core Ecto/Meilisearch sync; `scrypath_ops` handles observability.
- **CI/CD Pipeline:** A dedicated `e2e_playwright_smoke` GitHub Actions job running Postgres and Meilisearch natively via `services:` with robust caching.

### Pitfalls
- **Dependency Bloat:** Modifying the root `mix.exs` with demo dependencies. (Fix: Isolate in `examples/`).
- **Ecto Sandbox Mismatches:** Playwright making requests outside the ExUnit transaction. (Fix: Use shared sandbox mode via headers/cookies).
- **Port Clashes & CI Timeouts:** Hardcoded Phoenix ports and unready Meilisearch containers. (Fix: Use `port: 0` for testing and add GitHub Actions healthchecks for Meilisearch).
- **Asset Races:** Launching browser tests before esbuild finishes. (Fix: Explicit Mix aliases for test setup).

## Implications for Roadmap

Based on architectural dependencies, the milestone should be divided into the following phases:

1. **Phase 1: Admin UI Router Engine Refactor**
   - **Rationale:** The admin dashboard must be converted into a library/engine before the demo app can embed it.
   - **Delivers:** Refactored `scrypath_ops` exposing a macro for `router.ex`.
   - **Features:** Integrated `scrypath_ops` dashboard.
   - **Pitfalls Avoided:** Sidecar application friction; double DB connection pools.

2. **Phase 2: E-Commerce Host App Foundation**
   - **Rationale:** Establishes the isolated environment and complex domain model needed to stress the search integration.
   - **Delivers:** Standalone Phoenix app in `examples/scrypath_ecommerce` with multi-tenant Ecto schemas (Tenant, Category, Product, Variant).
   - **Features:** Tenant-safe data modeling; Ecto truth boundaries.
   - **Pitfalls Avoided:** Core library dependency bloat.

3. **Phase 3: Search Integration & Operations Proof**
   - **Rationale:** Integrates Scrypath and mounts the admin UI within the established host app.
   - **Delivers:** Oban async sync, related-data propagation hooks, and secured `/admin/search` routing.
   - **Features:** Zero-downtime reindex flow, related-data propagation, facet value search UI.
   - **Pitfalls Avoided:** Synchronous indexing defaults.

4. **Phase 4: Hermetic E2E Pipeline**
   - **Rationale:** Validates the entire system works end-to-end without CI flakiness.
   - **Delivers:** Playwright test suite and GitHub Actions `e2e_playwright_smoke` workflow.
   - **Features:** Operator triage simulation, Real Meilisearch CI Integration.
   - **Pitfalls Avoided:** Ecto Sandbox mismatches, port clashes, Meilisearch boot timeouts, asset compilation races.

### Research Flags
- **Needs Research:** Phase 4 (Specifically, configuring standard `@playwright/test` to work flawlessly with Elixir's `Ecto.Adapters.SQL.Sandbox` shared mode without relying on heavy third-party wrappers).
- **Standard Patterns:** Phase 1 (Elixir router mounting), Phase 2 (Phoenix contexts and domain modeling).

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Excellent alignment with idiomatic Elixir/Phoenix testing and deployment practices. |
| Features | HIGH | E-commerce domain perfectly stresses the advanced capabilities of the library. |
| Architecture | HIGH | The mountable engine pattern resolves massive DX and deployment friction for adopters. |
| Pitfalls | HIGH | Identifies classic pain points with browser-based testing in Phoenix (sandbox, ports, assets). |

**Gaps to Address:** Determining the exact mechanism for passing the Sandbox checkout token from standard Node Playwright to the Phoenix Endpoint during Phase 4.

## Sources
- `.planning/research/STACK.md`
- `.planning/research/FEATURES.md`
- `.planning/research/ARCHITECTURE.md`
- `.planning/research/PITFALLS.md`
