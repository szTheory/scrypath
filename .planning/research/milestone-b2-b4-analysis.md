# Milestone Research: B2 (Tenant-Safe Access) & B4 (Facet Value Search)

This document provides a comprehensive architectural analysis and recommendation for the next two candidate milestone themes for the Scrypath project: **Tier B2 (Tenant-safe search access story)** and **Tier B4 (Facet value vocabulary search)**.

---

## Theme 1: Tier B2 - Tenant-Safe Search Access Story

### Overview & Scope
The scope encompasses introducing a formal, tenant-safe search access model for shared-index SaaS applications. This involves updating `guides/multitenancy.md`, adding a declarative `tenant_field:` option to the schema projection, and reflecting this constraint via `schema_capabilities/1`. Crucially, this addresses a known silent data-leak footgun related to filter merge order.

### Pros/Cons of Implementation Approaches

**Approach 1: Per-Tenant Physical Indexes (Prefixing)**
*   **Pros:** Absolute physical data isolation. A leaked API key for Tenant A cannot read Tenant B's index.
*   **Cons:** Does not scale cleanly to 10,000+ B2B SaaS tenants without massive operational overhead (index management, settings duplication).
*   **Verdict:** Good for environment isolation (dev vs. prod), but poor as the default SaaS multi-tenancy model.

**Approach 2: Shared Index with Enforced Tenant Filters & Tokens (Recommended)**
*   **Pros:** Scales infinitely. Matches Meilisearch's official guidance for SaaS (tenant tokens with embedded filters). Less resource-intensive.
*   **Cons:** High risk of data leaks if the query filter merge order is flawed (the "silent data-leak footgun").
*   **Verdict:** The correct default for modern SaaS, provided the library enforces the boundary rigorously.

### Idiomatic Elixir/Plug/Ecto/Phoenix Patterns
*   **Declarative Schema:** Introduce a `tenant_field: :organization_id` option in the Ecto schema's search projection block.
*   **Context/Plug Enforcement:** In a Phoenix context or Plug pipeline, the current tenant (e.g., from `conn.assigns.current_tenant`) must be explicitly passed to search functions. 
*   **Runtime Reflection:** `schema_capabilities/1` should explicitly list the `tenant_field` so that higher-level abstractions (like `scrypath_ops`) can detect and enforce tenant context in administrative UI flows.
*   **Immutable Query Merging:** The search query builder must guarantee that the `tenant_field` filter is appended using an immutable `AND` operation at the outermost layer of the filter tree, preventing user-supplied filters from bypassing it.

### Lessons Learned from Other Ecosystems
*   **What they did right:** Libraries that offer robust multi-tenancy (like specialized Elasticsearch DSL wrappers) make the tenant context explicit rather than relying solely on hidden global state.
*   **The Footguns:** Do not market index prefixes alone as a multi-tenancy solution. Furthermore, naive filter concatenation (e.g., `user_filter OR tenant_id = X`) is a classic vulnerability. The library must own the AST/filter compilation to ensure the tenant constraint wraps all other conditions (`tenant_id = X AND (user_filter)`).

### Developer Ergonomics (DX) & Principle of Least Surprise
*   **DX:** A developer simply declares `tenant_field: :account_id` in their schema. When generating a frontend search token, the library should provide a helper that auto-embeds the tenant constraint into the JWT/token payload.
*   **Least Surprise:** If a schema declares a `tenant_field`, calling `Scrypath.search/3` without providing a tenant context (or explicitly opting into a global admin search) should raise a clear runtime error, preventing accidental cross-tenant queries.

---

## Theme 2: Tier B4 - Facet Value Vocabulary Search

### Overview & Scope
Wrapping Meilisearch's native `/facet-search` endpoint. This is a small, focused scope to address the UX pain point of searching through high-cardinality facets (e.g., finding a specific brand out of 200+ distinct values in a sidebar filter).

### Pros/Cons of Implementation Approaches

**Approach 1: Client-Side Filtering**
*   **Pros:** Zero backend changes.
*   **Cons:** Breaks down when facets exceed the default engine return limit (often 100). Horrible UX and bandwidth waste.

**Approach 2: Native Engine Facet Search API (Recommended)**
*   **Pros:** Fast, leverages Meilisearch's optimized `/facet-search` endpoint (stable since v1.3). Built exactly for this JTBD.
*   **Cons:** Requires a new dedicated function in the library's public API.

### Idiomatic Elixir/Plug/Ecto/Phoenix Patterns
*   **API Design:** Introduce `Scrypath.search_facet_values(index, facet_name, facet_query, opts \\ [])`. The signature should mirror the existing `Scrypath.search/3` ergonomics.
*   **Integration:** Can be cleanly wired into Phoenix LiveView components (e.g., an autocomplete dropdown for a specific facet) using standard `handle_event` callbacks.

### Lessons Learned from Other Ecosystems
*   **What they did right:** Searchkick handles high-cardinality data elegantly by providing specific autocomplete and facet exploration APIs.
*   **The Footguns:** Forgetting that facet search queries are distinct from document search queries. The returned payload shape is different (list of facet values and counts, not full documents). The library must parse this cleanly into a structured Elixir struct/map, not just dump raw JSON.

### Developer Ergonomics (DX) & Principle of Least Surprise
*   **DX:** The developer calls `Scrypath.search_facet_values(Product, "brand", "app")` and receives a predictable list of `%{value: "Apple", count: 42}` maps.
*   **Least Surprise:** The function should automatically handle index aliasing and prefixing under the hood, exactly like standard document search.

---

## Synthesis & Architectural Recommendation

### Sequencing Recommendation: Do NOT Combine Them

I recommend **executing Tier B2 first as a dedicated milestone (v1.25)**, followed by **Tier B4 as a separate milestone (v1.26)**.

**Rationale:**
1.  **Risk Profile:** B2 addresses a "silent data-leak footgun". Tenant isolation is a critical security boundary. Mixing this with a feature addition (B4) risks muddying the review process, diluting testing focus, and complicating the documentation narrative.
2.  **Milestone Integrity:** `.planning/milestone-candidates.md` strongly implies these are distinct steps. B2 is the "biggest remaining credibility gap for B2B Phoenix adopters." It requires deep focus on query AST merging and security testing.
3.  **Ship Cadence:** Shipping B2 alone delivers a massive, highly marketable credibility win for SaaS adopters. B4 is a fast follow-up "QoL/Delight" feature.

### Exact Proposed Architectural Design for B2 (Next Milestone)

1.  **Schema Declaration:**
    Update the `Scrypath.Searchable` macro (or equivalent) to accept `tenant_field: atom()`.
    ```elixir
    use Scrypath.Searchable,
      index: "documents",
      tenant_field: :account_id
    ```

2.  **Runtime Reflection:**
    Update `schema_capabilities/1` to return `%{tenant_field: :account_id}` so `scrypath_ops` and other reflection tools can enforce it in admin interfaces.

3.  **The Filter Merge Engine (The Fix):**
    Rewrite the internal query builder's filter merging logic. When a `tenant_field` is present, it must **never** be naively concatenated as a string. It must use a structured AST or safe wrapping:
    ```elixir
    # Internal logic pseudo-code
    safe_filter = "(#{user_provided_filter}) AND #{tenant_field} = '#{current_tenant_id}'"
    ```
    This guarantees that no `OR` clause injected by a user can break out of the tenant scope.

4.  **Token Generation API:**
    Provide a unified way to generate frontend search tokens that bake in this filter.
    ```elixir
    Scrypath.generate_tenant_token(Schema, account_id, opts \\ [])
    # Generates a Meilisearch tenant token with the filter pre-embedded.
    ```

5.  **Documentation (`guides/multitenancy.md`):**
    Write a definitive guide explicitly stating that Scrypath uses the **Shared Index + Tenant Token** architecture as its default SaaS posture, explaining *why* (resource efficiency, engine recommendations), and demonstrating how to safely pass the tenant context from a Phoenix Plug down to the search layer.
