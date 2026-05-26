# Requirements: Scrypath v1.25 — Tenant-Safe Search

**Defined:** 2026-05-25
**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## v1.25 Requirements

Requirements for the Tenant-Safe Search milestone (AUTH-01). Each maps to roadmap phases.

### Multi-Tenancy Guide

- [x] **TNNT-01**: User can follow `guides/multitenancy.md` to implement tenant-safe search in a Phoenix SaaS app — guide covers the shared-index + filter-injection model, the correct context-layer pattern with explicit tenant parameter, the filter merge order footgun (wrong/correct code examples), the per-tenant index anti-pattern with the Meilisearch throughput reason, Meilisearch tenant token placement advice (browser-direct only, not for server-side Scrypath search), and the `search_document/1` custom hook edge case

### Schema Declaration

- [x] **TNNT-02**: User can declare `tenant_field: :field_name` in a Scrypath schema and have the named field automatically included in both `filterable:` and the synced document projection without requiring separate `filterable:` and `fields:` declarations

### Metadata Reflection

- [x] **TNNT-03**: User can call `Scrypath.Metadata.schema_capabilities/1` on a schema and inspect the `:tenant` key to discover whether a `tenant_field` is declared and which field it names (returns `nil` if not declared)

### Runtime Enforcement

- [x] **TNNT-04**: User can pass `tenant_scope: tenant_id` to `Scrypath.search/3` and have the library automatically AND-combine the tenant filter with any caller-supplied `filter:` opts — tenant filter is injected at the library layer and cannot be overridden or shadowed by caller filters

### Verification

- [ ] **TNNT-05**: User can run `mix verify.phaseN` to confirm that `guides/multitenancy.md` guide anchors, `tenant_field:` auto-merge behavior, `schema_capabilities/1` `:tenant` reflection, and `tenant_scope:` injection are all coherent and regression-guarded; gate is registered in the CI `quality` job and CONTRIBUTING guidance

## Future Requirements (deferred)

### Per-Tenant Isolation Variants

- **TNNT-FUT-01**: Per-tenant Meilisearch index routing at the library level — compliance/regulated use case; only relevant when physical data separation is required; Meilisearch throughput constraint makes this wrong for the general case
- **TNNT-FUT-02**: Tenant token generation helpers in Scrypath core — host-app concern; Joken recipe belongs in the guide only, not as a library dependency

## Out of Scope

| Feature | Reason |
|---------|--------|
| Automatic tenant context extraction from conn / plug assigns / process dict | Breaks across `Task.async`, `assign_async`, and Oban workers — the idiomatic Elixir pattern requires explicit tenant parameter at the context layer |
| Per-tenant Meilisearch index routing as the default model | Meilisearch processes tasks sequentially per index; index proliferation degrades indexing throughput for all tenants at scale |
| Tenant token generation in Scrypath core | Browser-direct search concern only; server-side Scrypath search uses `filter:` / `tenant_scope:`, not JWTs |
| Enforcing that every search callsite passes a tenant scope | Scrypath cannot see host-app code; context layer owns tenant enforcement; library provides the declaration + guide |
| Magic that hides tenant identity from the context | Explicit tenant parameter through the context layer is correct-by-construction for async boundaries |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| TNNT-01 | Phase 92 | Complete |
| TNNT-02 | Phase 92 | Complete |
| TNNT-03 | Phase 93 | Complete |
| TNNT-04 | Phase 93 | Complete |
| TNNT-05 | Phase 94 | Pending |

**Coverage:**
- v1.25 requirements: 5 total
- Mapped to phases: 5
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-25*
*Last updated: 2026-05-25 — traceability populated by roadmapper; all 5 TNNT-* requirements mapped across phases 92–94*
