# Feature Landscape

**Domain:** Tenant-safe search for a multi-tenant Elixir/Phoenix SaaS search library (Scrypath v1.25 AUTH-01)
**Researched:** 2026-05-25
**Confidence:** HIGH (Meilisearch mechanism and shared-index pattern), HIGH (Elixir context-layer pattern), MEDIUM (stretch `tenant_scope:` surface — no adopter evidence yet)

> **Scope note:** This file covers only what is needed for AUTH-01. The existing
> `.planning/research/auth-01-tenant-research.md` is the deep reference; this file
> organises those findings into table-stakes / differentiators / anti-features for
> roadmap phase planning.

## Feature Landscape

### Table Stakes (Users Expect These)

Features multi-tenant Scrypath adopters assume will be addressed. Missing these = library has a credibility gap for SaaS Phoenix teams.

| Feature | Why Expected | Complexity | Dependencies | Notes |
|---------|--------------|------------|--------------|-------|
| Canonical `guides/multitenancy.md` | Every SaaS adopter will ask "how do I isolate tenants?" — no answer = silent data-leak risk | LOW | None (pure docs) | Must cover: shared-index model, why per-tenant indexes are not the default (Meilisearch sequential task throughput), the correct context-layer filter injection pattern, filter-merge order footgun, and when Meilisearch tenant tokens apply (browser-direct search only). Cite `JOB-4`. |
| `tenant_field:` schema declaration option | Adopters forget to declare the tenant field both in `fields:` (projection) and `filterable:` (index settings). Two separate omissions, both silent. The library should make this one declaration. | LOW–MEDIUM | Existing `filterable:` and document-projection machinery | Auto-adds the named field to `filterable:` and document projection. No runtime enforcement at search time — declaration only. Must compose cleanly with existing `filterable: [...]` lists. `JOB-4`. |
| `schema_capabilities/1` surfaces `tenant_field` | Contexts programmatically checking whether a schema has declared a tenant field need reflection support — otherwise they hard-code field names | LOW | `schema_capabilities/1` already exists; additive change | Extend the existing reflect surface. Return `%{tenant_field: :tenant_id}` or `nil` if not declared. Keeps the reflection API consistent with existing `filterable`, `sortable`, `fields` keys. |
| Guide section: correct context-layer filter injection pattern | Adopters must know where filter assembly lives (context function, not controller/LiveView) and why the context owns the tenant scope | LOW | Guide only | Must include the `Keyword.merge` footgun (last-key-wins drops tenant guard) and the correct explicit merge pattern. Must explain that `Scrypath.search/3` cannot know which filters are privileged without `tenant_scope:`. |
| Guide section: async-boundary safety | Adopters using `Task.async`, `assign_async`, or Oban workers need to know process-dictionary tenant context is lost across those boundaries | LOW | Guide only | The correct model (explicit tenant parameter through the context function) is already immune. The guide must name the anti-pattern explicitly and explain why Scrypath's explicit parameter model survives async boundaries. |

### Differentiators (Competitive Advantage)

Features that close the gap between Scrypath and the "nothing exists yet" state of Elixir/Phoenix SaaS search.

| Feature | Value Proposition | Complexity | Dependencies | Notes |
|---------|-------------------|------------|--------------|-------|
| `tenant_field:` as a single declaration vs. two manual steps | No Elixir search library (meilisearch-elixir, wayfarer, etc.) offers this. meilisearch-rails has an open issue from 2022, unresolved. Searchkick explicitly defers to the host app. Scrypath would be the first to make this one line. | LOW | Existing schema option parsing; `filterable:` registration path | The differentiator is not enforcement — it is reducing two error-prone manual steps (projection + filterable) to one declaration. |
| `schema_capabilities/1` reflection for `tenant_field` | Allows a context to discover programmatically which schemas declare a tenant field, enabling shared search utilities that don't hard-code field names | LOW | Existing `schema_capabilities/1` reflection | Small additive surface. Valuable for apps with many schemas. |
| `tenant_scope:` search option (stretch) | Hard-injects the tenant filter at the library level, AND-combined with `filter:`, not overridable. Closes the filter-merge-order footgun at the call site rather than relying on context discipline. | MEDIUM | `Scrypath.search/3` option parsing; filter composition in `%Scrypath.Query{}` build path | Only worth shipping if adopter evidence confirms the merge bug is occurring in real code. Without evidence: premature enforcement. Estimated 1–2 additional phases. |
| Named "why not per-tenant indexes" guidance | Meilisearch's sequential task processor makes per-tenant indexes a documented anti-pattern, but this is buried in Meilisearch's blog. Surfacing it in Scrypath's guide prevents a common adopter mistake that degrades throughput for all tenants. | LOW | Guide only | The guidance is a differentiator because it shows Scrypath understands production constraints, not just API mechanics. |
| Tenant token recipe for browser-direct search | Not a library feature — but a documented recipe (Joken, HS256, searchRules payload) for the subset of adopters who want the browser to hit Meilisearch directly. No Scrypath code involved, pure docs. | LOW | Guide only; host app adds Joken dep | Keeps Scrypath out of the JWT dependency business while still answering the question. Mark assumption A1 (Joken API shape) for validation before implementation. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Automatic tenant context from process dictionary / plug assigns | Seems convenient — "just store current_tenant in a plug and Scrypath reads it automatically" | Process dictionary does not survive `Task.async`, `assign_async`, or Oban workers. Silent cross-tenant data leak in async contexts. Libraries like Triplex use this pattern and require explicit propagation workarounds. | Explicit tenant parameter threaded through the context function. Document this as the correct pattern in the guide. |
| Per-tenant index routing (`index_prefix:` dynamic at query time) | Seems like hard isolation — wrong index = zero results | Meilisearch processes tasks sequentially per index. At 100+ tenants, all indexing throughput degrades. Operational complexity multiplies by tenant count. `Scrypath.index_prefix:` is environment-level, not per-tenant dynamic. | Shared index + `filterable: [:tenant_id]` + filter injection. Per-tenant indexes only for compliance/regulatory isolation requirements. |
| Library-level tenant ID extraction from `conn` / socket assigns | Seems ergonomic — "pass the conn and Scrypath figures out the tenant" | Couples the search library to Phoenix internals. Context functions are the correct ownership boundary. Breaks the library's Ecto-first, Phoenix-optional stance. | Context function takes tenant as an explicit argument. Phoenix controllers/LiveViews pass it from assigns. |
| Token generation helpers (Joken wrapper in Scrypath) | Adopters want one library to handle everything | Adds a JWT dependency to Scrypath core that most adopters doing server-side search never need. Token generation is three lines of Joken — not a library abstraction problem. | Document the recipe in the guide. Host app adds `{:joken, "~> 2.6"}` if needed. |
| `tenant_scope:` enforcement without adopter evidence | Seems like it closes a real footgun | Without adopter evidence that the filter-merge bug is occurring in real code, this is premature enforcement that widens the public API surface for no validated reason. | Ship the guide + `tenant_field:` declaration first. Let adopter evidence determine whether `tenant_scope:` is justified for a follow-on phase. |
| Automatic association walking to pull `tenant_id` from parent records | Seems helpful — Post has no `tenant_id`, but its Organization does | Deeply couples the library to Ecto association traversal. Breaks the "no automatic Ecto association walking" boundary established in v1.24. Creates hidden N+1 sync paths. | Document the explicit projection approach: include `tenant_id` via a custom document-build function or add a virtual field to the schema. |
| Per-tenant Meilisearch API key management | Seems like the "real" multi-tenancy solution | Per-tenant keys require per-tenant indexes (Option 4 in the research). Same throughput problem plus credential management overhead. Not the production model. | Shared index + server-side filter injection. Tenant tokens for browser-direct search only, and only for search (not admin ops). |

## Feature Dependencies

```
tenant_field: schema option
    └──requires──> existing filterable: registration machinery
    └──requires──> existing document projection machinery
    └──enables──> schema_capabilities/1 reflection for tenant_field

schema_capabilities/1 tenant_field reflection
    └──requires──> tenant_field: schema option (must exist before reflecting it)
    └──enhances──> context-layer code that discovers tenant fields programmatically

guides/multitenancy.md
    └──requires──> tenant_field: option (must exist to document it accurately)
    └──requires──> schema_capabilities/1 update (must exist to document it)
    └──standalone──> correct context-layer pattern, async safety, token recipe

tenant_scope: search option (stretch)
    └──requires──> tenant_field: schema option (natural pairing — schema declares, search enforces)
    └──requires──> filter composition in %Scrypath.Query{} build path (must AND-combine, not replace)
    └──conflicts with──> process-dictionary tenant context (explicit ID required, not auto-extracted)
    └──enhances──> guide section on filter-merge footgun (library now closes the gap)
```

### Dependency Notes

- **`tenant_field:` requires existing `filterable:` machinery:** The option is additive — it calls the same registration path that `filterable: [:field]` already calls. No new runtime path required.
- **`schema_capabilities/1` requires `tenant_field:`:** Reflection of a field that was never declared would be meaningless. The two ship together or the reflection returns `nil`.
- **`guides/multitenancy.md` must not precede `tenant_field:` in the phase plan:** The guide documents the feature; the feature must be at least designed before the guide can be accurate.
- **`tenant_scope:` conflicts with auto-extraction patterns:** If `tenant_scope:` is ever shipped, it must take an explicit value (not read from process state). Otherwise it introduces the same async-boundary footgun it is meant to prevent.

## MVP Definition

### Launch With (v1.25)

Minimum viable slice that closes the SaaS credibility gap.

- [ ] `guides/multitenancy.md` — shared-index model, context-layer pattern, filter-merge footgun, async safety, tenant token recipe for browser-direct search, explicit note against per-tenant indexes
- [ ] `tenant_field:` schema declaration option — auto-adds named field to `filterable:` + document projection in one declaration
- [ ] `schema_capabilities/1` update — surfaces `tenant_field` if declared

### Add After Validation (v1.25 stretch or v1.26)

Features to add if adopter evidence supports them.

- [ ] `tenant_scope:` search option on `Scrypath.search/3` — hard-injected tenant filter, AND-combined with `filter:`, not overridable by caller opts. Trigger: adopter report of the filter-merge bug occurring in production code.

### Future Consideration (Out of scope for v1.25+)

Features to permanently defer or reject.

- [ ] Automatic tenant context from process dictionary — wrong model; document the anti-pattern instead
- [ ] Per-tenant index routing at query time — throughput anti-pattern; document against it
- [ ] Token generation helpers in Scrypath core — recipe belongs in the guide, not the library
- [ ] Automatic association walking for `tenant_id` — breaks the no-auto-association-walking boundary

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| `guides/multitenancy.md` | HIGH — closes the #1 SaaS credibility gap | LOW — pure docs | P1 |
| `tenant_field:` schema option | HIGH — removes two silent failure modes in one declaration | LOW–MEDIUM — additive to existing option parsing | P1 |
| `schema_capabilities/1` `tenant_field` reflection | MEDIUM — useful for programmatic discovery; less critical than the declaration itself | LOW — additive to existing reflection | P1 (same phase as `tenant_field:`) |
| `tenant_scope:` search option | MEDIUM — closes filter-merge footgun at library level | MEDIUM — new option, filter composition change | P2 — defer until adopter evidence |
| Tenant token recipe (docs-only) | LOW–MEDIUM — applies only to browser-direct search adopters | LOW — documentation only | P2 — include in guide if space allows |

**Priority key:**
- P1: Must ship in v1.25
- P2: Ship when evidence justifies or time allows
- P3: Future consideration / reject

## Competitor Feature Analysis

| Feature | Searchkick (Ruby) | meilisearch-rails (Ruby) | Laravel Scout (PHP) | Hibernate Search (Java) | Scrypath approach |
|---------|-------------------|--------------------------|---------------------|------------------------|-------------------|
| Built-in tenant field declaration | None — host-app scope (issue #268 closed, won't fix) | None — open issue #152 since June 2022, unresolved | None — global model scope pattern, host-owned | First-class tenant ID parameter on `MassIndexer` and `SearchSession` | `tenant_field:` declaration option — first Elixir library to offer this |
| Schema-level filterable registration | Auto-registers searchkick fields | Manual `filterable_attributes` list | Manual `toSearchableArray` + Scout index configuration | Managed by mapping annotations | Auto-registration via `tenant_field:` — extends existing `filterable:` path |
| Tenant filter injection | Host app monkey-patches `search` class method | Host app owns filter injection | Host app adds `where()` clauses or global scopes | `SearchSession.search(...).filter().matching(tenantId)` | Host context owns injection; guide provides the correct pattern |
| Async boundary safety | Not documented | Not documented | N/A (sync framework) | Explicit session scoping | Explicit parameter model is immune by construction; guide names the process-dict anti-pattern |
| Tenant token / credential generation | None | None (issue #152 open) | None | API key scoping per tenant | Documented recipe (Joken) in guide; no library dep |
| Per-tenant index support | Via `index_name` override | Via `index_uid` override | Via `searchableAs()` override | Via tenant parameter on mass indexer | Documented anti-pattern in guide; `index_prefix:` is environment-level, not per-tenant |

## Sources

### Primary (HIGH confidence — verified in auth-01-tenant-research.md)

- Meilisearch multi-tenancy guide: https://meilisearch.com/blog/multi-tenancy-guide — shared-index recommendation, sequential task throughput constraint
- Meilisearch tenant token spec: https://specs.meilisearch.dev/specifications/text/0089-tenant-tokens.html — JWT payload, signing, searchRules, revocation model
- Meilisearch filterableAttributes spec: https://specs.meilisearch.dev/specifications/text/0123-filterable-attributes-setting-api.html — filter must be declared or silently ignored
- Joken hexdocs: https://hexdocs.pm/joken/Joken.Signer.html — HS256 signer API
- Curiosum Elixir multitenancy blog: https://curiosum.com/blog/multitenancy-in-elixir — process dictionary async boundary footgun
- meilisearch-rails issue #152: https://github.com/meilisearch/meilisearch-rails/issues/152 — no tenant support shipped as of research date
- searchkick issue #268: https://github.com/ankane/searchkick/issues/268 — explicitly host-app scope

### Codebase (Direct inspection)

- `lib/scrypath/options.ex` — `filter:` option exists; no `tenant_scope:` today
- `lib/scrypath/metadata/resolve.ex` — `tenant_policy: :host_owned` already declared
- `lib/scrypath.ex` — `@moduledoc` states tenant authz is host-owned
- `guides/composing-real-app-search.md` — "no tenant/authz guarantees" in non-goals

---
*Feature landscape for: Scrypath v1.25 AUTH-01 tenant-safe search*
*Researched: 2026-05-25*
