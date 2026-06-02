# Feature Landscape: Realistic Demo App & Admin UI Proof (v1.28)

**Domain:** OSS Elixir Search Library Demo & Admin UI E2E Testing
**Researched:** 2026-05-30
**Overall confidence:** HIGH

## Executive Summary

To effectively prove out `scrypath_ops` and the core Scrypath library contract, the demo app must transcend a trivial "blog" example and embrace a domain that naturally stresses search synchronization, relational data, and operator observability. An **E-commerce (Multi-tenant Marketplace)** domain is the perfect fit. It naturally requires complex faceting, related-data propagation (e.g., stock updates affecting product visibility), and tenant-isolation. 

The demo app must integrate `scrypath_ops` to show how operators diagnose indexing drift, failed Oban jobs, and Meilisearch task backlogs. E2E testing with Playwright must validate both the end-user search experience and the admin UI's operational honesty, running against a real Meilisearch instance in CI.

## Table Stakes

Features expected of a production-grade Elixir search library demo app.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Phoenix + Ecto + Oban Integration** | Proves the core architectural thesis: Ecto as source of truth, Oban for durable async sync. | Medium | The demo must not use synchronous HTTP calls for primary data mutations. |
| **Integrated `scrypath_ops` Dashboard** | Demonstrates how operators inspect the state of the search cluster and background jobs without leaving the Phoenix app. | Low | Mount the LiveView dashboard in the demo app's router under an admin scope. |
| **Real Meilisearch CI Integration** | The E2E tests must run against a real Meilisearch container, not a mock, to prove actual task lifecycle and latency handling. | Medium | Requires Docker service containers in the GitHub Actions workflow. |
| **Playwright E2E Test Suite** | Validates the actual browser experience (LiveView typing -> search results) and admin UI state. | High | Must handle eventual consistency (waiting for Meilisearch tasks to complete before asserting). |
| **Tenant-Safe Search Access** | Proves the library's multitenancy guide is accurate in a real-world scenario. | Medium | Use `tenant_field` and `tenant_scope` to ensure data isolation. |

## Differentiators

Features that set this demo apart as a definitive reference architecture.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Zero-Downtime Reindex Flow** | Shows operators how to change index settings (e.g., adding a new facet) using the temp-index + swap pattern via `scrypath_ops`. | High | Requires E2E test to assert search remains available during a schema migration. |
| **Related-Data Propagation** | Demonstrates `Scrypath.sync_related/3`. E.g., updating a category name automatically updates all products in that category in the search index. | Medium | Critical for proving the library handles complex Ecto associations safely. |
| **Facet Value Search UI** | Utilizes `search_facet_values/4` for high-cardinality facets (e.g., searching for a specific brand among 1,000s in a sidebar). | Medium | Demonstrates the latest v1.26 capabilities in a real LiveView context. |
| **Operator Triage Simulation** | An E2E test that intentionally breaks sync (e.g., invalid document), uses Playwright to navigate to `scrypath_ops`, and asserts the failure is visible and actionable. | High | Proves the "operational honesty" mandate of the library. |

## Anti-Features

Features to explicitly NOT build in this demo.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Custom UI Component Library** | Scrypath is framework-agnostic at the view layer. Building a reusable "SearchBox" widget distracts from the core integration. | Use standard Phoenix/LiveView markup. Keep the UI functional but unopinionated. |
| **Synchronous Indexing Default** | Violates the core thesis that indexing should be async and batch-oriented to prevent slowing down web requests. | Always use Oban/outbox for standard mutations. Use synchronous indexing only for explicit test setup. |
| **Trivial "Blog Post" Domain** | Does not stress faceting, related data, or tenant isolation enough to prove the library's advanced features. | Use an E-commerce/Marketplace domain. |

## One-Shot Recommendation: The Demo App Architecture

**Domain: B2B E-commerce Marketplace**
An application where multiple distinct vendors (Tenants) sell products. 

**Data Model:**
- `Tenant` (id, name)
- `Category` (id, name)
- `Product` (id, tenant_id, category_id, name, description, price, status)
- `Variant` (id, product_id, sku, color, stock_level)

**Why this domain?**
1. **Multitenancy:** A user searching on Vendor A's storefront must never see Vendor B's products.
2. **Related Data:** If a `Variant` stock level drops to 0, the parent `Product` document in Meilisearch needs updating to reflect "out of stock".
3. **Facets:** Products require rich faceting by Category, Color, and Price Range.

**Flows to E2E Test (Playwright):**

1. **The Happy Path (Consumer):**
   - User navigates to storefront, types in a search bar.
   - LiveView updates search results instantly.
   - User clicks a facet (e.g., "Category: Electronics") and results filter correctly.
2. **The Related Data Sync (Admin):**
   - Admin changes the name of a `Category` in the Postgres database.
   - Playwright waits for background jobs to process (simulating eventual consistency).
   - Playwright asserts that searching for the *new* category name surfaces the associated products.
3. **The Operator UI Proof (Operator):**
   - System intentionally enqueues a malformed product document.
   - Playwright logs in as Operator, navigates to `/admin/scrypath_ops`.
   - Playwright asserts the UI displays a "Failed Task" with the correct Meilisearch error message.
   - Playwright clicks "Reindex" on the broken index and asserts the UI reflects the building state.
4. **The Zero-Downtime Swap (Operator):**
   - Operator initiates a settings change (e.g., making a new field filterable) via the UI.
   - Playwright asserts that a consumer on another page can *still* successfully search the old index while the new one builds.
   - Playwright asserts the swap completes and the new facet is available.

## Sources
- `.planning/PROJECT.md` (Library mandates: Ecto-native, Oban sync, explicit operator visibility, framework-agnostic view layer)
- `prompts/meileisearch best practices for scrypath deep research.md` (Emphasizes settings as migrations, async tasks, and the need for observable operator tools)
- `prompts/search-lib-use-cases-deep-research.md` (Highlights the importance of tenant-safe access, related-data propagation, and recovery workflows)