# Phase 165: Public Tenant and Facet Contracts - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves how the discussion was handled.

**Date:** 2026-09-26
**Phase:** 165-Public Tenant and Facet Contracts
**Areas discussed:** None; the approved requirements and v1.40 research already settle the meaningful choices.

---

## Gray-area assessment

No unresolved preference or product-behavior decisions remained after reviewing the approved v1.40 requirements, roadmap, research reports, prior phase decisions, project constraints, and current code paths. The public routes, expected tenant/filter behavior, facet request boundary, evidence layers, and compatible-fix-only rule are already explicit. No question was repeated and no new ecosystem research or test run was needed for discussion.

## Decisions carried forward

- Reproduce the existing tenant contract through `search/3`, `search_many/2`, and `search_facet_values/4`.
- Reproduce public facet defaults and keyword filters through `search_facet_values/4` and verify endpoint-valid request construction.
- Treat C10-R1 and C11-R1 as unconfirmed until public-entry probes establish behavior; correct only a reproduced compatible contract failure.
- Keep host authorization outside Scrypath and keep Phase 165 proof on deterministic contract seams unless a confirmed issue makes service proof relevant.

## the agent's Discretion

- Choose the smallest test layout that uses existing helpers and verification lanes while making each probe independently diagnosable.
- Consider generated/property tests only when a concrete invariant justifies them.

## Deferred Ideas

- Broader tenant authorization, backend/version matrices, operator UI, new required CI lanes, and unrelated product capabilities remain deferred under the approved milestone boundaries.
