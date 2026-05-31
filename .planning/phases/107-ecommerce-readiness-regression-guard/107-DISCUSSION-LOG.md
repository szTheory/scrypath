# Phase 107: Ecommerce Readiness Regression Guard - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-05-31
**Phase:** 107-ecommerce-readiness-regression-guard
**Areas discussed:** Proof boundary, Verification gate, Probe semantics

---

## Proof Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Focused controller/probe regression proof | Assert `/dev/e2e/search-visible` preserves both `tenant_id` and `category_id` at the `Scrypath.Query` boundary. | yes |
| Broader Playwright/cross-tenant fixture expansion | Add browser-level cross-tenant negative assertions and broader fixtures. | |
| Hybrid controller proof plus browser sentinel | Keep deterministic controller proof and add a minimal browser assertion without new cross-tenant fixtures. | |

**User's choice:** Asked to discuss all areas with subagent-backed research and produce a cohesive recommendation.
**Notes:** Recommendation selected focused controller/probe proof because it directly targets the known filter-merge regression, preserves Phase 107 scope, and avoids expanding deferred ecommerce E2E breadth.

---

## Verification Gate

| Option | Description | Selected |
|--------|-------------|----------|
| Focused `mix verify.phase107` gate | Add a fast, deterministic, service-free phase gate for the controller regression. | yes |
| Existing example controller tests only | Rely on coverage already present in the example app test suite without a named root gate. | |
| Extend `phase105-e2e` live/advisory proof | Add or depend on full Phoenix/Postgres/Meilisearch/Playwright proof. | |

**User's choice:** Asked for the agent to decide after research.
**Notes:** Recommendation selected a focused `mix verify.phase107` gate because it matches recent Phase 106 and Phase 94 proof posture while avoiding live-service flake and CI lane promotion.

---

## Probe Semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Keep explicit filter merge | Preserve explicit `filter: [tenant_id: tenant_id, category_id: category_id]` semantics for this regression guard. | yes |
| Switch probe to `tenant_scope:` | Use Scrypath's public tenant-safety primitive plus category filter. | |
| Extract shared search-options helper | Centralize storefront and probe tenant/category search option construction. | |

**User's choice:** Asked for the agent to decide after research.
**Notes:** Recommendation selected explicit filter merge because Phase 107 is proving the historical explicit-filter merge bug. `tenant_scope:` remains the stronger adopter-facing safety primitive, but switching now would prove a different path.

---

## the agent's Discretion

- Exact test names, helper names, and assertion shape.
- Exact verify task self-test shape.
- Whether implementation needs a tiny helper inside the controller test, provided the public proof remains direct.

## Deferred Ideas

- Broader cross-tenant Playwright fixtures.
- Switching `/dev/e2e/search-visible` to `tenant_scope:`.
- Shared storefront/probe search-options extraction.
- Promoting `phase105-e2e` to required CI.
