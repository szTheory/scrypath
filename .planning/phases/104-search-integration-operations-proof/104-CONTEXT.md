# Phase 104: Search Integration & Operations Proof - Context

**Gathered:** 2026-05-30
**Status:** Ready for planning

<domain>
## Phase Boundary

The demo app integrates native search with multitenancy, related-data propagation, and an embedded admin UI. We are proving the integration of the `scrypath` library in a realistic host app scenario (`examples/scrypath_ecommerce`).

</domain>

<decisions>
## Implementation Decisions

### UI Pattern
- **D-01:** **LiveView Instant Search with URL Sync (`push_patch`)**. We will use `phx-change` on a form with debounced inputs (`phx-debounce="300"`). This emphasizes a "zero-JS" search implementation that stays completely within the LiveView idiom while keeping the URL shareable.

### Facet Interaction
- **D-02:** **Sidebar facets with auto-apply**. A unified `phx-change` form encompassing the search input and all facet checkboxes. Text inputs will be debounced, but checkboxes will trigger immediately for responsive e-commerce UX.

### Admin UI Mounting
- **D-03:** **Nested mounting at `/admin/search`**. The `scrypath_ops` dashboard will be mounted inside an existing admin scope in the router, demonstrating how the host app applies its own authentication/authorization pipeline to the engine.

### Seeding Strategy
- **D-04:** **Hand-crafted specific product hierarchies**. We will use explicit, deterministic seed data (e.g., specific tech product categories and variants) to guarantee stable E2E testing in Phase 105 and clearly demonstrate related-data propagation when a category name changes.

### Claude's Discretion
All recommendations were generated autonomously by deep-researching project best practices and the ecosystem.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phoenix & LiveView Best Practices
- `prompts/phoenix-live-view-best-practices-deep-research.md` — LiveView UI architecture, component responsibilities, and URL state sync patterns.
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — Context boundaries and router mounting strategies.

### E-Commerce Search Patterns
- `prompts/elixir-search-lib-deep-research.md` — Common search patterns for high-cardinality facets and autocomplete UX.
- `prompts/meileisearch best practices for scrypath deep research.md` — Meilisearch specific indexing and tenant safety strategies.

### Project Roadmap
- `.planning/ROADMAP.md` — Phase 104 and 105 goals and requirements.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scrypath_ops` engine: Refactored in Phase 102, ready to be mounted in the `scrypath_ecommerce` router.
- `ScrypathEcommerce.CatalogFixtures`: Existing scenario creation helpers can be extended for the hand-crafted product hierarchies.

### Established Patterns
- **Mountable Engine**: `scrypath_ops` is no longer a standalone endpoint; it relies on the host app's Phoenix router and Repo.

### Integration Points
- `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/router.ex` — Where `scrypath_ops` will be mounted under `/admin`.
- `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog/product.ex` — Where the `use Scrypath` indexing configuration will be added.

</code_context>

<specifics>
## Specific Ideas

- The search UI should feel like a modern e-commerce experience (e.g., Amazon, Shopify) but implemented purely in LiveView without heavy client-side JavaScript.
- The mounting of the admin UI must prove that `scrypath_ops` can securely sit behind standard Phoenix plug-based authentication.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 104-Search Integration & Operations Proof*
*Context gathered: 2026-05-30*