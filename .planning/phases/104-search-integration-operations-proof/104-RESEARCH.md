# Phase 104: Search Integration & Operations Proof - Research

**Researched:** 2026-05-30
**Domain:** Elixir/Phoenix Integration, Search Operations, UI Architecture
**Confidence:** HIGH

## Summary

This phase proves the Scrypath library's integration in a realistic host application (`examples/scrypath_ecommerce`). The integration covers mounting the admin operations dashboard (`scrypath_ops`), implementing Oban-backed search indexing on the `Product` schema, cascading updates from related data (`Category`), and providing a zero-JS, URL-driven LiveView storefront for search and faceting.

**Primary recommendation:** Use Ecto.Multi + Oban for durable, outbox-pattern indexing within bounded Contexts; construct the LiveView search UI strictly around URL query parameters using `push_patch` and a unified debounced form.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** **LiveView Instant Search with URL Sync (`push_patch`)**. We will use `phx-change` on a form with debounced inputs (`phx-debounce="300"`). This emphasizes a "zero-JS" search implementation that stays completely within the LiveView idiom while keeping the URL shareable.
- **D-02:** **Sidebar facets with auto-apply**. A unified `phx-change` form encompassing the search input and all facet checkboxes. Text inputs will be debounced, but checkboxes will trigger immediately for responsive e-commerce UX.
- **D-03:** **Nested mounting at `/admin/search`**. The `scrypath_ops` dashboard will be mounted inside an existing admin scope in the router, demonstrating how the host app applies its own authentication/authorization pipeline to the engine.
- **D-04:** **Hand-crafted specific product hierarchies**. We will use explicit, deterministic seed data (e.g., specific tech product categories and variants) to guarantee stable E2E testing in Phase 105 and clearly demonstrate related-data propagation when a category name changes.

### the agent's Discretion
All recommendations were generated autonomously by deep-researching project best practices and the ecosystem.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INT-01 | Mount `scrypath_ops` inside the `scrypath_ecommerce` router. | Confirmed pattern for nested mounting within `pipeline :browser`. |
| INT-02 | Implement Scrypath indexing for the `Product` schema using `tenant_field` and Oban sync. | Outbox pattern via Ecto.Multi + Oban verified as best practice for eventual consistency. |
| INT-03 | Implement related-data propagation (Category name changes update associated Products). | Ecto Context boundary updates using multi to touch related projections. |
| INT-04 | Build a LiveView storefront with facet-driven search and tenant-safe access. | LiveView unified forms + URL-driven state via `handle_params`. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Search UI & URL State | Browser / Client | Frontend Server (SSR) | URL query parameters act as the source of truth for shareable, reproducible search UI state. |
| Search Rendering | Frontend Server (SSR) | API / Backend | LiveView coordinates component rendering via `handle_params` and function components. |
| Tenant Isolation | API / Backend | Database / Storage | Scoped queries and Multi operations must happen at the context boundary (backend). |
| Data Sync (Indexing) | Background Worker | API / Backend | Oban background workers provide resilient retry loops and offload HTTP latencies from web requests. |
| Admin Dashboard | Frontend Server (SSR) | API / Backend | `scrypath_ops` acts as an embedded Phoenix LiveView engine sharing host DB. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix LiveView | ~> 1.0 / 1.1 | Search UI components | Provides real-time URL syncing and forms without custom JS. |
| Oban | ~> 2.17 | Async Search Sync | Standard background job engine for Ecto, perfect for outbox sync. |
| Scrypath | (Local) | Search Integration | The library under test, used for defining `Scrypath.Index`. |
| Meilisearch | v1.x.y | Search Engine | The backend index store. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Ecto.Multi | (Built-in) | Transactional sync | Use when persisting domain objects and queuing indexing events together. |

**Installation:** (All already available in `scrypath_ecommerce` / `scrypath_ops`)

## Architecture Patterns

### System Architecture Diagram
```
[Browser Client]
       │ (URL params via push_patch)
       ▼
[Phoenix LiveView (Storefront)] ──(queries)──▶ [Meilisearch] (Search results)
       │ (Hydration)                                 ▲
       ▼                                             │ (Tasks: Add/Update Docs)
[Phoenix Contexts (Catalog)]                         │
       │ (Domain changes)                            │
       ▼                                             │
[Ecto.Multi (Transaction)] ──────(Oban Queue)──▶ [Sync Worker]
       │
       ▼
[PostgreSQL Database] (Source of truth)
```

### Pattern 1: URL-Driven Search State
**What:** Storing facet selections and search queries in the URL via `push_patch` and responding to them in `handle_params/3`.
**When to use:** Whenever building a filterable list, search interface, or faceted navigation where copy-pasting the URL should reproduce the exact same UI state.
**Example:**
```elixir
# In LiveView
def handle_event("search", params, socket) do
  # Translate form params to query string params
  query_params = build_query_params(params)
  {:noreply, push_patch(socket, to: ~p"/products?#{query_params}")}
end

def handle_params(params, _uri, socket) do
  # URL is the source of truth
  results = Catalog.search_products(params)
  {:noreply, assign(socket, form: to_form(params), results: results)}
end
```

### Pattern 2: Context-Driven Sync
**What:** Performing database writes and background job enqueueing in a single `Ecto.Multi` transaction.
**When to use:** Whenever updating a domain model that is indexed in Meilisearch, to ensure eventual consistency without DB/index divergence.
**Example:**
```elixir
def update_category(category, attrs) do
  Ecto.Multi.new()
  |> Ecto.Multi.update(:category, Category.changeset(category, attrs))
  |> Ecto.Multi.insert(:sync_job, fn %{category: cat} ->
    # Propagate to all products belonging to this category
    MyApp.Oban.SearchWorker.new(%{type: "category_update", id: cat.id})
  end)
  |> Repo.transaction()
end
```

### Anti-Patterns to Avoid
- **Implicit Sync in Controllers/LiveViews:** Do not fire off `Scrypath.upsert` directly in a LiveView `handle_event`. Always push this to a background job queued transactionally in the Context.
- **Client-Side Authoritative State:** Do not store facet choices in an internal LiveView assign if they aren't also synced to the URL.
- **Ignoring Multi-tenant Isolation:** Searching directly against Meilisearch without applying a tenant filter or tenant API key.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Client-side debounce | Custom JS timers | `phx-debounce="300"` | Built natively into LiveView, automatically avoids race conditions. |
| Complex form state tracking | Ad-hoc map assigns | `.form` and `to_form/1` | Phoenix HTML handles diffs and input recovery seamlessly. |
| Admin routing protection | Custom plug chains | Host app's `pipeline :admin` | The `scrypath_ops` dashboard mounts into the existing Phoenix router pipeline, leveraging its standard auth. |

## Common Pitfalls

### Pitfall 1: Event Cycle Feedback Loops
**What goes wrong:** `push_patch` updates the URL, triggering `handle_params`, which overrides the user's ongoing input.
**Why it happens:** Debounced text inputs in LiveView can clash with aggressive server-side patches if not handled properly.
**How to avoid:** Map the URL parameters gracefully to a single server-side form. Ensure that text fields correctly use `phx-debounce`.

### Pitfall 2: Async Indexing Lag
**What goes wrong:** A user edits a product name, the frontend redirects to search, but the old name still appears.
**Why it happens:** Meilisearch processing is asynchronous. The Oban worker creates a task, which takes milliseconds/seconds to complete.
**How to avoid:** For UI flows requiring immediate write-after-read consistency, hydrate critical data from Postgres, using Meilisearch only for document ordering, or display a UI state acknowledging processing. For this phase's demo, hydrating from DB on search or accepting eventual consistency is acceptable.

### Pitfall 3: Incomplete Related-Data Sync
**What goes wrong:** Changing a Category name doesn't update the searchable representation of its Products.
**Why it happens:** Missing the Ecto boundary propagation hook.
**How to avoid:** Implement a clear `Oban` worker that fans out to `Product` updates when a `Category` changes.

## Code Examples

### Unified Search Form
```elixir
<.form for={@form} phx-change="search" class="flex gap-4">
  <div class="sidebar">
    <h4>Categories</h4>
    <.input type="checkbox" field={@form[:category_id]} checked_value="1" label="Coffee Makers" />
    <.input type="checkbox" field={@form[:category_id]} checked_value="2" label="Accessories" />
  </div>

  <div class="main">
    <.input type="text" field={@form[:q]} phx-debounce="300" placeholder="Search products..." />
  </div>
</.form>
```

### Mountable Engine Routing
```elixir
# lib/scrypath_ecommerce_web/router.ex
pipeline :admin do
  plug :browser
  # plug :require_authenticated_admin
end

scope "/admin", ScrypathEcommerceWeb do
  pipe_through :admin

  import ScrypathOps.Router
  scrypath_ops_routes("/search")
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom JS `fetch` for search | LiveView `phx-change` + URL params | LiveView 0.16+ | Eliminates client-side logic; URL acts as robust state. |
| Global Hooks for Sync | Ecto.Multi + Oban Outbox | Best Practice | Fixes race conditions and provides observability. |
| Standalone Endpoint engines | Router-mounted engines | Phase 102 | Inherits host authentication and session securely. |

## Open Questions (RESOLVED)

1. **Category to Product Fan-out Strategy** RESOLVED: A single Oban job (`CategoryUpdateWorker`) will iterate over its child Products and push a batch update to Meilisearch.
   - What we know: Requirement INT-03 states Category changes must update Products.
   - What's unclear: Should the fan-out happen synchronously inside Oban (e.g., fetching 100 products and updating Meilisearch), or should it spawn N product-specific Oban jobs?
   - Recommendation: For the scope of the demo app, a single Oban job (`CategoryUpdateWorker`) that iterates over its child Products and pushes a batch update to Meilisearch is simpler and effective.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PostgreSQL | Ecto/Oban/App | ✓ | — | — |
| Meilisearch | Scrypath Engine | ✓ | — | — |
| Docker | Running Meilisearch | ✓ | — | — |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit & Playwright (for Phase 105) |
| Config file | `mix.exs`, `test/test_helper.exs` |
| Quick run command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INT-01 | Mount Ops Dashboard | Unit/Router | `mix test test/scrypath_ecommerce_web/controllers/page_controller_test.exs` | ❌ (To be built) |
| INT-02 | Scrypath indexing config | Unit | `mix test` on Context | ❌ (To be built) |
| INT-03 | Related data propagation | Unit | `mix test` on Context | ❌ (To be built) |
| INT-04 | Facet Storefront | Unit/LiveView | `mix test` on LiveView | ❌ (To be built) |

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V4 Access Control | yes | Router pipeline `pipe_through :admin` for `scrypath_ops` |
| V5 Input Validation | yes | Ecto Changesets and LiveView `to_form` |
| V7 Tenant Isolation | yes | Scrypath query options `tenant_field` enforcement |

### Known Threat Patterns for Phoenix/LiveView
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-tenant data leakage | Information Disclosure | Explicitly pass `tenant_id` to `Scrypath.search` queries; hydrate from Ecto using tenant scoping. |
| Insecure Admin Dashboard | Elevation of Privilege | Ensure `scrypath_ops` routes sit behind standard Phoenix plug authentication pipeline. |

## Sources

### Primary (HIGH confidence)
- `prompts/phoenix-live-view-best-practices-deep-research.md` - URL state, streams, and component structure.
- `prompts/elixir-search-lib-deep-research.md` - Outbox sync pattern and Meilisearch specifics.
- `prompts/meileisearch best practices for scrypath deep research.md` - Operational truths, eventual consistency, projection definitions.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Core Elixir/Phoenix ecosystem norms verified against 2026 guidelines.
- Architecture: HIGH - Adheres to LiveView 1.1 `handle_params` logic and strictly bounds Ecto domains.
- Pitfalls: HIGH - Synchronous write assumptions are a heavily documented Meilisearch gotcha.

**Research date:** 2026-05-30
**Valid until:** 2026-06-30
