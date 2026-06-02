---
slug: scrypath-post-v1-28-next-step
title: Scrypath post-v1.28 next-step assessment
status: active
created: 2026-05-31
updated: 2026-05-31
---

# Scrypath post-v1.28 next-step assessment

## Current call

Scrypath is still near-done for its stated Meilisearch-first Phoenix/Ecto scope: **~92-94% done**.

The next useful pull is **Contract Repair and Proof Hardening**, not new product breadth.

## Why

v1.27 and v1.28 closed the prior top trust/proof wedges:

- adopter contract hardening, support/proof truth, and trust gates
- realistic ecommerce demo app
- mountable `scrypath_ops` admin proof
- storefront/operator E2E against real Meilisearch

Repo inspection after v1.28 found narrow but real remaining rough edges:

- `use Scrypath, fan_outs:` was validated as a schema option but needed explicit generated `__scrypath__(:fan_outs)` proof.
- v1.28 E2E readiness probes needed a regression guard to ensure category filtering preserves tenant filtering.
- post-v1.26 ranking docs still named already-shipped or resolved work as current next pull.

## Recommended order

1. Contract Repair and Proof Hardening.
2. Maintenance/evidence lane: release truth, outside-adopter evidence, and planning truth refresh.
3. Autocomplete/suggestions only with reviewed outside-adopter evidence.

## Explicit non-pulls

- Do not open broad OPSUI productization.
- Do not open multi-backend, vector, hybrid, personalization, or analytics breadth.
- Do not reopen SearchModule based on v1.20 archive wording; that mismatch was resolved as archive-correction.

## Graduation candidates

- **Contract repair default:** future milestone discovery should check whether shipped APIs still require workaround prose. If yes, repair the contract before adding adjacent features.
- **Proof honesty default:** E2E harnesses must preserve the same tenant/security filters as user-facing flows; test helpers are not allowed to weaken the product claim.
