# Phase 166: Host Tenant and Repair Evidence - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-26
**Phase:** 166-host-tenant-and-repair-evidence
**Areas discussed:** Named Phoenix host-policy fixture

---

## Named Phoenix host-policy fixture

| Option | Description | Selected |
|--------|-------------|----------|
| Extend phoenix_meilisearch with a minimal trusted actor/membership context | Reuse its existing Phoenix consumer suite for repository-path and freshly built package-artifact runs. | ✓ |
| Adapt scrypath_ecommerce and extend its package proof | Reuse tenant-aware models, but add membership policy and broaden package staging beyond its current workflow. | |
| Another fixture / preference | Freeform alternative. | |

**User's choice:** Approved the recommendation to extend phoenix_meilisearch.
**Notes:** Architecture/security, CI/package, and adversarial test-design reviews converged on this choice. Keep the actor synthetic and treat it as already authenticated; verify membership and derive tenant filters in the host context. Scope hydration by tenant and returned IDs, while checking raw hits and metadata independently. The decision does not claim production authentication or arbitrary adopter security.

---

## the agent's Discretion

- Choose the smallest existing-pattern Ecto schema, host context, and test helpers needed to represent trusted actors and persisted membership.
- Keep repairs independently tested in the root backend integration surface and preserve the existing advisory/required CI split.

## Deferred Ideas

- Production login/session authentication, ecommerce UI authorization, broader stale-index migration behavior, operator UI, and a new required service lane remain outside Phase 166.
