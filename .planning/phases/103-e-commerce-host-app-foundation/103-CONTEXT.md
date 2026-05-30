# Phase 103: E-Commerce Host App Foundation - Context

**Gathered:** 2026-05-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Scaffold the e-commerce testbed with multi-tenant Ecto schemas (Tenant, Category, Product, Variant) and configure the Ecto Sandbox for shared mode to support external Playwright browser processes.
</domain>

<decisions>
## Implementation Decisions

### Tenant Isolation Strategy
- **D-01:** Put `tenant_id` on EVERY model (Tenant, Category, Product, Variant).
- **D-02:** Adopt a strict "scoped context" pattern where the Context API always requires a tenant or scope struct. Utilize Ecto's `prepare_query/3` repo hook to enforce that every query has a `tenant_id` filter applied by default, ensuring zero cross-tenant leakage.

### Variant Modeling
- **D-03:** Model Product as the logical container and Variant as the strictly sellable unit. A cart or order line item should always reference a `Variant`, never a `Product`.
- **D-04:** Product Schema: `id`, `tenant_id`, `name`, `description`, `category_id`.
- **D-05:** Variant Schema: `id`, `tenant_id`, `product_id`, `sku`, `price_cents`, `currency`, `inventory_count`, and an `options` map (JSONB) for dynamic traits like size/color.
- **D-06:** Search Context: Index the Product as the primary search document, but project the Variant data into it (array of SKUs, min/max price calculated from variants).

### Seed Data Strategy
- **D-07:** Use pure Elixir function factories (`*Fixtures` modules) as the single source of truth for generating data, instead of ExMachina or Mix tasks.
- **D-08:** For Operator UI / Local Dev: Create a Mix task (`mix scrypath.seed`) that leverages fixture functions to generate a rich catalog, ending by invoking the Scrypath indexer.
- **D-09:** For Playwright E2E: Expose `Phoenix.Ecto.SQL.Sandbox` in the endpoint. Configure Playwright to use it. Add a hidden back-office endpoint (`POST /dev/e2e/seed`) that uses the fixture functions to seed just the specific data needed for that test inside its isolated transaction.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scrypath Directives
- `.planning/ROADMAP.md` — Goals and Phase boundaries for Phase 103.
- `.planning/REQUIREMENTS.md` — APP-01, APP-02, APP-03 requirement details.
- `prompts/ecto-best-practices-deep-research.md` — Best practices for Ecto tenancy and migrations.
- `prompts/elixir-best-practices-deep-research.md` — Elixir code organization, context design.
- `prompts/phoenix-best-practices-deep-research.md` — Phoenix sandbox configuration for E2E tests.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog.ex`: Existing catalog context to extend with `Variant` and `Tenant` scoping.
- `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog/product.ex`: Existing product schema to modify.
- `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog/category.ex`: Existing category schema to modify.

### Established Patterns
- Existing code uses standard Phoenix Context patterns (`list_brands`, `get_brand!`, etc.), which must be updated to accept a `tenant` scope.

### Integration Points
- `Phoenix.Ecto.SQL.Sandbox` plug must be integrated into `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/endpoint.ex`.
- `mix scrypath.seed` task must integrate with the new `ScrypathEcommerce.CatalogFixtures`.

</code_context>

<specifics>
## Specific Ideas

- The user requested a perfect set of cohesive, one-shot recommendations based on deep research that emphasizes developer ergonomics, UX/DX, and the principle of least surprise. The research concluded that denormalizing `tenant_id` to all models and using `Phoenix.Ecto.SQL.Sandbox` via a hidden seed endpoint for Playwright are the most robust, idiomatic solutions.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 103-E-Commerce Host App Foundation*
*Context gathered: 2026-05-30*