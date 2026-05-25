# AUTH-01 Research: Tenant-Safe Search Access

**Researched:** 2026-05-25
**Domain:** Multi-tenancy, Meilisearch tenant tokens, Elixir/Phoenix filter injection, SaaS search isolation
**Confidence:** HIGH (Meilisearch mechanism), HIGH (Elixir context patterns), MEDIUM (scope of library surface)

---

## What Tenant-Safe Search Actually Means

"Tenant-safe search" in a SaaS Phoenix app means: a search query executed on behalf of Tenant A must never return documents belonging to Tenant B. This is not optional in any real multi-tenant product — it is a correctness requirement with data-leak consequences.

There are four implementation strategies. They are not mutually exclusive but they sit at different layers.

---

## Strategy Comparison

### Option 1: Per-Tenant Meilisearch Index

Each tenant gets their own index (`posts_tenant_42`, `posts_tenant_99`).

**What it gives you:**
- Absolute hard isolation — wrong index = zero results
- Tenant-shaped settings (different filterable fields, synonyms, etc.)
- Clear operational story for tenants with large document volumes

**What it costs you:**
- Meilisearch processes tasks one index after another sequentially. The official docs state explicitly: "it's not recommended to create one index per company due to performance reasons" — index proliferation degrades indexing throughput for all tenants. [CITED: meilisearch.com/blog/multi-tenancy-guide]
- Operational complexity: backfill, reindex, settings drift, and index management multiply by tenant count
- Scrypath's `index_prefix:` option currently supports environment-level partitioning (e.g. `"staging_posts"`), not per-tenant dynamic routing at query time

**When it still makes sense:**
- Compliance requirements mandating physical data separation (GDPR data residency, regulatory audits)
- Very large tenants where isolation is worth the throughput cost
- Tenants with genuinely different schema/settings needs

**Verdict:** Not the default production model. Appropriate only for regulated or large-tenant cases. [CITED: meilisearch.com/docs/learn/security/multitenancy_tenant_tokens]

---

### Option 2: Shared Index + Application-Level Filter Injection (Context Layer)

All tenants share one index. The context layer appends `filter: [tenant_id: current_tenant_id]` to every `Scrypath.search/3` call.

**What it looks like today (no library support):**

```elixir
defmodule MyApp.Content do
  def search_posts(query, %Tenant{id: tenant_id}, opts \\ []) do
    Scrypath.search(Post, query,
      Keyword.merge([
        backend: Scrypath.Meilisearch,
        repo: Repo,
        filter: [tenant_id: tenant_id]   # host-owned, manually threaded
      ], opts)
    )
  end
end
```

The `tenant_id` field must appear in the schema's `filterable:` declaration AND in Meilisearch's `filterableAttributes` index setting. [CITED: specs.meilisearch.dev/specifications/text/0123-filterable-attributes-setting-api.html]

**What the schema declaration looks like:**

```elixir
defmodule MyApp.Blog.Post do
  use Scrypath,
    fields: [:title, :body, :status],
    filterable: [:status, :tenant_id],   # tenant_id must be declared here
    sortable: [:inserted_at]
end
```

**Sync path:** documents must include `tenant_id` in the projected document. If `tenant_id` is a field on the Ecto schema and it's in `fields:` or the projection, it gets synced automatically. If it lives on an association, it needs to be in the explicit projection.

**What it gives you:**
- Works today with no new Scrypath features
- Filter injection is visible in the context — easy to audit, easy to test
- No per-tenant operational surface

**What can go wrong:**
- Every search callsite must remember to pass the tenant filter. One omitted call = data leak.
- Nothing in Scrypath enforces the filter. It is convention, not contract.
- Composition patterns (e.g., `Scrypath.Composition`) don't carry tenant context today — each caller must re-inject it.

**Verdict:** This is what adopters should do today. The library can improve this story without owning policy. [ASSUMED based on standard SaaS filter-injection pattern; the specific Scrypath usage path is reasoned from the existing options.ex API, not a shipped guide]

---

### Option 3: Meilisearch Tenant Tokens (Server-Side Token Generation, Client-Side Search)

Meilisearch's native multi-tenancy mechanism. Introduced in v0.26.0 (~2022), production-stable across all v1.x releases as of 2026. [CITED: specs.meilisearch.dev/specifications/text/0089-tenant-tokens.html]

**Mechanism:**

A tenant token is a short-lived JWT generated server-side. The JWT payload embeds search rules (filter expressions) that Meilisearch enforces automatically on every search request that uses that token. The token is signed with a Meilisearch API key (the key's value, not the UID).

**JWT payload structure:**

```json
{
  "apiKeyUid": "at5cd97d-5a4b-4226-a868-2d0eb6d197ab",
  "searchRules": {
    "*": {
      "filter": "tenant_id = 42"
    }
  },
  "exp": 1646756934
}
```

`searchRules` supports wildcards (`"*"`), specific index names, and per-index filter expressions. An empty object `{}` grants full access to all documents in that index for the signing key's scope.

**Supported signing algorithms:** HS256, HS384, HS512 (HMAC). Signing key is the API key value (not the UID). [CITED: specs.meilisearch.dev/specifications/text/0089-tenant-tokens.html]

**Elixir token generation with Joken:**

```elixir
# mix.exs: {:joken, "~> 2.6"}
defmodule MyApp.Search.TenantToken do
  def generate(tenant_id, api_key_uid, api_key_value, ttl_seconds \\ 3600) do
    now = System.system_time(:second)
    claims = %{
      "apiKeyUid" => api_key_uid,
      "searchRules" => %{"*" => %{"filter" => "tenant_id = #{tenant_id}"}},
      "exp" => now + ttl_seconds
    }
    signer = Joken.Signer.create("HS256", api_key_value)
    {:ok, token, _} = Joken.encode_and_sign(claims, signer)
    token
  end
end
```

[CITED: hexdocs.pm/joken/Joken.Signer.html for Joken.Signer.create/2 and sign API]
[ASSUMED: the specific Joken encode_and_sign call shape — verify against Joken 2.x docs before implementation]

**Primary use case:** The frontend (LiveView or browser JS) receives the tenant token and calls Meilisearch directly for instant search UX — the backend never sees the raw query. This is the Algolia "secured API keys" pattern.

**Critical constraint:** Tenant tokens only restrict the search endpoint. They do not apply to index management, settings updates, or document access. Admin operations require API keys. [CITED: meilisearch.com/docs/learn/security/tenant_tokens]

**Revocation:** Tokens cannot be revoked individually. Invalidation requires deleting the signing API key, which invalidates all tokens signed with it. This is a significant operational consideration for token rotation. [CITED: specs.meilisearch.dev/specifications/text/0089-tenant-tokens.html]

**Verdict:** Production-ready and well-documented for the frontend-direct-to-Meilisearch pattern. Not needed when search runs server-side through Scrypath — in that case Option 2 (context filter injection) is the correct model. Tenant tokens become relevant if Scrypath adopters want to let the browser hit Meilisearch directly.

---

### Option 4: Per-Tenant API Keys (Scoped to Tenant's Index)

Meilisearch supports creating API keys scoped to specific index names and actions. A tenant gets a key scoped to `posts_tenant_42`. This is per-tenant index (Option 1) plus credential isolation.

**Verdict:** Same throughput problem as Option 1, plus per-tenant key management overhead. Only warranted in regulated/compliance scenarios. Not the default story.

---

## What Similar Libraries Do

### Searchkick (Ruby/Rails)

Searchkick has no built-in tenant isolation mechanism. The community approach is monkey-patching the `search` class method to merge `where: {tenant_id: current_tenant_id}` before dispatching to the underlying search engine. Per GitHub issue #268, this is explicitly host-app scope, not library scope. [CITED: github.com/ankane/searchkick/issues/268]

One approach per the GoRails community: override `searchkick_search` at the model level. Another: global scope with `unscope` for reindexing. No official `scope_by:` declaration exists in Searchkick.

**Lesson for Scrypath:** The Ruby ecosystem has not converged on a library-owned solution. Host-app filter injection is the dominant pattern.

### meilisearch-rails

Open GitHub issue #152 (June 2022, still unresolved as of research date) explicitly asks whether the gem should support tenant tokens and provide examples for `acts_as_tenant` and `Apartment`. The issue has "needs more info" and "enhancement" labels — no implementation, no merged PR, no decision. [CITED: github.com/meilisearch/meilisearch-rails/issues/152]

**Lesson for Scrypath:** Even the official Meilisearch Rails gem has not shipped tenant support. This confirms the pattern: no Rails/Ruby search library has cracked tenant-safe search as a first-class library feature. The space is genuinely open.

### Laravel Scout

The dominant pattern is: add `tenant_id` to `filterableAttributes`, use global model scopes or `searchableAs()` override to prepend tenant name to index names. `genealabs/laravel-tenancy-scout` wraps this as a trait. [CITED: medium.com/@bkintanar/how-to-implement-laravel-scout-with-tenancy-...]

The filter-injection approach remains host-app owned even with trait helpers. Index-prefix isolation (one index per tenant) is also common in the Laravel ecosystem, often paired with `Apartment`/multi-schema DB patterns.

### Hibernate Search (Java)

First-class multi-tenant support with mass indexing — tenant ID is a first-class parameter in the `MassIndexer` and `SearchSession`. Batch operations take tenant scope explicitly. This is the most mature reference implementation. [ASSUMED from training knowledge, not verified in this session]

---

## What "Tenant-Safe" Means at Each Layer for a Scrypath Adopter

| Layer | Responsibility | Current state |
|-------|---------------|---------------|
| Document sync | `tenant_id` field indexed in Meilisearch document | Host-owned today — must be in `fields:` or projection |
| Index settings | `tenant_id` in `filterable:` + Meilisearch `filterableAttributes` | Host-owned today — `filterable: [:tenant_id]` in schema |
| Search filter | `filter: [tenant_id: id]` injected at context layer | Host-owned today — no library enforcement |
| Composition | Tenant filter carried through `Scrypath.Composition` presets | Not carried today — gap |
| Token generation | Meilisearch tenant token for browser-direct search | Host-owned — outside library scope |

---

## Idiomatic Elixir/Phoenix Approach

The idiomatic pattern in the Elixir/Phoenix ecosystem for multi-tenancy is the **context layer as the enforcement boundary**. The process dictionary approach (storing tenant in process dict at plug layer) does not survive async boundaries (`Task.async`, `assign_async`) — a critical footgun documented in the community. [CITED: curiosum.com/blog/multitenancy-in-elixir]

The correct model for Scrypath:

1. **The context function is the unit of tenant enforcement.** `search_posts/3` takes a tenant struct or ID as a required parameter and injects it.
2. **Scrypath.search/3 is called with `filter:` that includes the tenant guard.** The filter is assembled in the context, not in the controller or LiveView.
3. **`tenant_id` field is declared in the schema's `filterable:` list.** This is a schema-declaration concern Scrypath owns.

```elixir
# Correct pattern — tenant is explicit, injected in context
defmodule MyApp.Content do
  def search_posts(query, %Tenant{id: tenant_id}, opts \\ []) do
    tenant_filter = [tenant_id: tenant_id]
    caller_filters = Keyword.get(opts, :filter, [])

    Scrypath.search(Post, query,
      Keyword.merge(opts, [
        backend: Scrypath.Meilisearch,
        repo: Repo,
        filter: tenant_filter ++ caller_filters
      ])
    )
  end
end
```

The risk with the current API: if a caller passes `filter:` in `opts` and the context does a naive `Keyword.merge`, caller-supplied filters will overwrite `tenant_filter` (Keyword.merge last-key-wins). The correct assembly is to merge explicitly — tenant filter first, caller filter appended — which Scrypath cannot do for the host today because it doesn't know which filters are "privileged."

---

## Concrete Code: Without Library Support vs. With Library Support

### Today (No Library Support)

```elixir
# Context — host must thread tenant everywhere manually
defmodule MyApp.Blog do
  def search_posts(text, tenant_id, opts \\ []) do
    # Host assembles filter, no library guardrail
    Scrypath.search(Post, text,
      backend: Scrypath.Meilisearch,
      repo: Repo,
      filter: [tenant_id: tenant_id] ++ Keyword.get(opts, :filter, [])
    )
  end

  def search_comments(text, tenant_id, opts \\ []) do
    # Must repeat this pattern at every search callsite
    Scrypath.search(Comment, text,
      backend: Scrypath.Meilisearch,
      repo: Repo,
      filter: [tenant_id: tenant_id] ++ Keyword.get(opts, :filter, [])
    )
  end
end

# Schema — must declare filterable manually
defmodule MyApp.Blog.Post do
  use Scrypath,
    fields: [:title, :body, :tenant_id],   # tenant_id must be in fields to sync
    filterable: [:tenant_id, :status]       # and in filterable for index settings
end
```

### With Library Support (Proposed)

Two distinct value-adds the library could provide:

**Value-add 1: Schema-level declaration of the tenant field**

```elixir
defmodule MyApp.Blog.Post do
  use Scrypath,
    fields: [:title, :body],
    filterable: [:status],
    tenant_field: :tenant_id        # new: declares the tenant isolation field
end
```

Scrypath auto-adds `tenant_id` to `filterable:`, ensures it's in the synced document, and exposes it via `schema_config/1` reflection so the context can discover it programmatically.

**Value-add 2: Composition carrying tenant context**

```elixir
defmodule MyApp.Blog do
  def search_posts(text, tenant_id, opts \\ []) do
    # tenant_scope: option in search/3 that Scrypath automatically
    # injects as a mandatory filter, not overridable by caller opts
    Scrypath.search(Post, text,
      backend: Scrypath.Meilisearch,
      repo: Repo,
      tenant_scope: tenant_id,     # new: privileged filter, not overridable
      filter: Keyword.get(opts, :filter, [])
    )
  end
end
```

The library composes `tenant_scope` as a filter expression that is always AND-combined with caller-supplied `filter:`, never overridable. The host still supplies the tenant identity — the library provides the composition guarantee.

---

## What "Done Enough" Looks Like

The minimal credible milestone for AUTH-01 is a guide + schema declaration + context-layer recipe, not a runtime enforcement system.

### Minimum credible slice (guide + declaration):

1. **A canonical multi-tenancy guide** (`guides/multitenancy.md`) that explains:
   - The shared-index + filter-injection model
   - Why per-tenant indexes are not the default (Meilisearch throughput constraint)
   - The correct context-layer pattern with explicit tenant parameter
   - A note on Meilisearch tenant tokens (when they apply: browser-direct search only)
   - Common failure mode: `filter:` merge order bug

2. **`tenant_field:` schema option** that adds the named field to `filterable:` automatically and includes it in document projection. This removes one class of "forgot to declare tenant_id filterable" errors.

3. **`Scrypath.Metadata.reflect_search/2` update** to surface `tenant_field` in `schema_capabilities` so contexts can reflect whether the schema has a declared tenant field.

### Stretch slice (runtime safety):

4. **`tenant_scope:` search option** on `Scrypath.search/3` that hard-injects the tenant filter at the library level, bypassing caller `filter:` composition risks. This provides a library-enforced invariant rather than a convention.

5. **Documentation of tenant token generation** (Joken, HS256, payload structure) for adopters who want browser-direct Meilisearch search. No library code needed — just the recipe.

### Out of scope for this milestone:

- Automatic tenant context extraction from process dictionary / plug assigns
- Per-tenant index routing
- Token generation helpers (pure JWT work, no Scrypath value-add)
- Tenant key management / rotation
- Any "magic" that hides the tenant identity from the context

---

## Realistic Scope Estimate

| Slice | Size | Risk |
|-------|------|------|
| Canonical guide only | 1–2 phases | Low — pure docs |
| Guide + `tenant_field:` schema option | 2–3 phases | Low — additive declaration |
| Guide + `tenant_field:` + `tenant_scope:` search option | 3–5 phases | Medium — runtime option + composition contract |
| All above + token generation recipe | +1 phase | Low (docs only) |

The minimum viable milestone that closes the SaaS credibility gap is: guide + `tenant_field:` option. That addresses the most common adopter failure mode (forgetting to declare the field filterable) and gives Scrypath a credible "we thought about tenants" story.

`tenant_scope:` is worth doing if adopter evidence shows people are shipping the filter-merge bug. Without evidence of that specific failure mode, it's premature.

---

## Footguns and Failure Modes

### 1. Filter merge order bug (HIGH risk, easy to ship)

```elixir
# WRONG — Keyword.merge last-key-wins: if opts has :filter, tenant filter is lost
Scrypath.search(Post, text, Keyword.merge([filter: [tenant_id: id]], opts))

# CORRECT — explicit merge, tenant filter cannot be shadowed
tenant_filter = [tenant_id: tenant_id]
Scrypath.search(Post, text, Keyword.merge(opts, [filter: tenant_filter ++ caller_filter]))
```

**What goes wrong:** A LiveView or controller passes `filter: [status: :published]` in opts. `Keyword.merge/2` with tenant filter as first arg silently drops the tenant guard. Result: cross-tenant data leaks in production queries scoped only to `[status: :published]`.

**How to avoid:** Explicit merge logic in the context. Library-level `tenant_scope:` option eliminates the risk entirely.

---

### 2. tenant_id missing from document projection (MEDIUM risk, silent)

If `tenant_id` is not in `fields:` and not added manually to the document projection, documents sync without the tenant field. Filter expressions against an unindexed field match nothing in Meilisearch — not an error, just empty results. This silently breaks search for all tenants in a surprising way.

**How to avoid:** Declare `tenant_field: :tenant_id` in the schema. Scrypath auto-includes it in the document projection.

---

### 3. tenant_id not in filterableAttributes (HIGH risk, silent)

If `tenant_id` is in the document but not in `filterable:`, Meilisearch ignores the filter expression silently. All tenants see all documents.

**How to avoid:** `tenant_field:` option auto-adds the field to `filterable:`. Without the option, the adopter must remember to declare `filterable: [:tenant_id]` alongside all other filterable fields.

---

### 4. Composition bypassing tenant filter (MEDIUM risk)

`Scrypath.Composition` preset functions build search opts. If a preset includes `filter:` for other fields, and the context assembles the final filter by merging preset output with tenant scope, the merge order bug (footgun #1) applies again.

**How to avoid:** `tenant_scope:` as a privileged option, combined at the library layer before any `filter:` opts are processed.

---

### 5. Per-tenant index proliferation degrading throughput (MEDIUM risk, ops)

An adopter reads "use index_prefix for isolation" and creates one index per tenant. With 100+ tenants, Meilisearch sequential task processing becomes a bottleneck — all indexing queues behind a single global task worker.

**How to avoid:** The canonical guide must explicitly say: shared index + `filterable: [:tenant_id]` is the production model. Per-tenant indexes are for compliance/isolation exceptions, not the default.

---

### 6. Tenant tokens used server-side instead of application-layer filter (LOW risk, architectural confusion)

Adopter reads about Meilisearch tenant tokens and generates one per request on the server, then passes it to Scrypath search. This creates unnecessary JWT generation overhead and adds an API key dependency to the hot search path.

Tenant tokens are for browser-direct search (the frontend hits Meilisearch directly). Server-side search through Scrypath should use `filter: [tenant_id: id]`, not tenant tokens.

**How to avoid:** The guide must explain the two models and when each applies.

---

### 7. Async boundary loses tenant context (LOW risk in Scrypath's model, HIGH in process-dict patterns)

Libraries that store tenant context in the process dictionary (common in Elixir multi-tenancy libs like Triplex) lose it across `Task.async`, `assign_async`, and Oban workers. Scrypath's explicit parameter model (tenant ID passed as argument) is immune to this — it's correct by construction.

**Implication for Scrypath:** The library should not be designed to read tenant context from process state. Explicit tenant parameter at the context layer is the right model.

---

## Recommended Approach for Scrypath

**Primary recommendation:**

Start with a guide-first milestone. The canonical guide closing the SaaS credibility gap is higher leverage than runtime enforcement, because the failure modes are in host-app code that Scrypath cannot see anyway.

Add `tenant_field:` as a schema declaration option. This is small, additive, and closes the "forgot to declare filterable" footgun at the declaration layer.

Defer `tenant_scope:` search option until adopter evidence shows the filter-merge bug is occurring in real code. It is the correct next step after the guide, but don't open that surface without evidence.

**Implementation approach:**

The host context owns tenant identity. Scrypath owns:
- The `tenant_field:` declaration (ensures the field is filterable and projected)
- The guide explaining the correct assembly pattern
- Metadata reflection (`schema_capabilities` surfacing `tenant_field`)

Scrypath does NOT own:
- Extracting tenant ID from conn/session/process state
- Generating or validating tenant tokens
- Enforcing that every search call passes a tenant scope

**Positioning:**

This is a "SaaS credibility gap" fix, not a security boundary. The real security enforcement lives in the context layer. Scrypath makes it easier to declare the tenant field correctly and documents the correct assembly pattern. The library positions as "makes the right thing easy, makes the wrong thing visible."

---

## Assumptions Log

| # | Claim | Risk if Wrong |
|---|-------|--------------|
| A1 | Joken 2.x `encode_and_sign/2` is the correct API for raw claims signing | Generates wrong token shape; would need Joken.sign/2 or different API |
| A2 | `filter:` in Scrypath.search/3 accepts mixed keyword lists like `[tenant_id: 42, status: :published]` | Filter assembly pattern breaks; adopters can't concatenate filters this way |
| A3 | The process-dict anti-pattern for tenant context is known to adopters | If not, the guide needs more prominent warning |
| A4 | Hibernate Search multi-tenant MassIndexer API shape | Not verified in this session; sourced from training knowledge |

---

## Sources

### PRIMARY (HIGH confidence — official docs, specifications)

- [CITED: meilisearch.com/docs/learn/security/tenant_tokens] — Tenant token mechanism, server/client roles, constraints
- [CITED: meilisearch.com/docs/learn/security/multitenancy_tenant_tokens] — Shared-index model, embedded filters, RLS analogy
- [CITED: specs.meilisearch.dev/specifications/text/0089-tenant-tokens.html] — JWT payload structure, signing algorithms (HS256/384/512), searchRules schema, revocation model, token cannot exceed signing key permissions
- [CITED: meilisearch.com/blog/multi-tenancy-guide] — Shared index recommended over per-tenant index, sequential task processing as the reason
- [CITED: meilisearch.com/blog/multi-tenancy] — Token generation code pattern (JS), searchRules structure
- [CITED: hexdocs.pm/joken/Joken.Signer.html] — Joken.Signer.create("HS256", secret), sign API, output format
- [CITED: curiosum.com/blog/multitenancy-in-elixir] — Process dictionary anti-pattern, async boundary loss

### SECONDARY (MEDIUM confidence — community docs, issue trackers)

- [CITED: github.com/meilisearch/meilisearch-rails/issues/152] — meilisearch-rails has not shipped tenant token support as of research date; host-app scope confirmed
- [CITED: github.com/ankane/searchkick/issues/268] — Searchkick leaves tenant scoping to host app
- [CITED: medium.com/@bkintanar/how-to-implement-laravel-scout-with-tenancy-...] — Laravel Scout tenant pattern: global scope + filter injection
- [CITED: specs.meilisearch.dev/specifications/text/0123-filterable-attributes-setting-api.html] — filterableAttributes must be configured for tenant filter to work

### CODEBASE (Direct inspection)

- `lib/scrypath/options.ex` — current runtime options; `filter:` option exists, no `tenant_scope:` today
- `lib/scrypath/metadata/resolve.ex` — `tenant_policy: :host_owned` already declared as a host-owned concern in metadata reflection
- `lib/scrypath.ex` — `@moduledoc` explicitly states "tenant authz and related-data propagation" are host-owned
- `guides/composing-real-app-search.md` — "no tenant/authz guarantees" in non-goals section
- `mix.exs` — no JWT/Joken dependency; Joken would be optional/host-app dep for tenant token generation

---

## Summary

**What it is:** Tenant-safe search is the requirement that a SaaS search query returns only the requesting tenant's documents. The mechanism for Meilisearch is: (a) shared index with `tenant_id` field in `filterableAttributes`, (b) context-layer filter injection at every `Scrypath.search/3` call.

**Recommended approach:** Guide-first. Add `tenant_field:` declaration option. Document the correct filter-injection pattern in the context. Defer `tenant_scope:` runtime enforcement until adopter evidence shows the merge bug occurring in real code.

**Scope estimate:** 2–3 phases for guide + `tenant_field:` declaration. 4–5 phases to add `tenant_scope:` runtime option.

**Done-enough criteria:**
1. Canonical `guides/multitenancy.md` exists with the shared-index model, correct context pattern, filter merge warning, and tenant token placement advice
2. `tenant_field:` schema option auto-adds the field to `filterable:` and document projection
3. `schema_capabilities/1` reflects `tenant_field` if declared
4. No new magic — tenant ID still passes as explicit argument through the context

**Footguns to avoid:**
1. Filter merge order bug (Keyword.merge last-key-wins silently drops tenant guard)
2. tenant_id not in `filterable:` (filter is ignored silently — all tenants see all docs)
3. tenant_id missing from document projection (filter matches nothing silently — no results for anyone)
4. Per-tenant index proliferation (Meilisearch sequential task processing degrades at scale)
5. Tenant tokens used server-side instead of application-layer filter injection
6. Process dictionary for tenant context (breaks across async boundaries)
