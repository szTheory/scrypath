# Phase 144: Root HTTP Client Dependency Remediation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-21
**Phase:** 144-root-http-client-dependency-remediation
**Areas discussed:** Pending todo routing, cross-graph Req handoff, Req 0.6 behavior proof, fresh-resolution evidence, compatibility-fix boundary

---

## Pending Todo Routing

| Option | Description | Selected |
|--------|-------------|----------|
| Fold the root slice | Bring the pending advisory todo's root/shared HTTP-client work into Phase 144 while leaving milestone closure in Phase 147. | ✓ |
| Leave todo for Phase 147 | Treat the milestone-wide todo only as final closure input. | |

**User's choice:** Fold the root slice.
**Notes:** The todo remains open; only the Phase 144 portion is folded.

---

## Cross-graph Req Handoff

| Option | Description | Selected |
|--------|-------------|----------|
| Atomic shared Req-floor handoff | Align direct Req constraints and the necessary Req lock closure in all four independent graphs, then keep later non-Req remediations graph-local. | ✓ |
| Root-only Req bump | Preserve the written phase boundary but leave Ops/ecommerce constraints incompatible and the legacy lock stale. | |
| Temporary Req 0.5-or-0.6 bridge | Keep intermediate graphs resolvable by continuing to permit the vulnerable Req 0.5 line. | |
| Reorder/combine later batches | Move graph phases around or make one broad all-advisory upgrade. | |

**User's choice:** Approved the researched atomic shared-handoff recommendation.
**Notes:** Four advisor passes agreed that the literal root-only intermediate state conflicts with Mix path-dependency resolution and green-main. Planning must correct the roadmap/EVID-02 delivery wording before execution.

---

## Req 0.6 Behavior Proof

| Option | Description | Selected |
|--------|-------------|----------|
| Existing broad suite only | Trust incidental existing coverage without migration-specific gap analysis. | |
| Focused Req.Test gaps plus existing gates | Add causal transport/header/query/error-telemetry coverage and reuse existing JSON/sync/HTTP-error tests and deterministic gates. | ✓ |
| Live Meilisearch only | Use service-dependent integration proof as the primary compatibility signal. | |
| Prove Swoosh in Phase 144 | Pull Ops production API-client behavior into the root phase. | |

**User's choice:** Approved focused root proof with Swoosh deferred to its owning graph.
**Notes:** Live Meilisearch remains supplemental when available. Phase 146 owns `Swoosh.ApiClient.Req` proof because root has no Swoosh dependency.

---

## Fresh-resolution Evidence

| Option | Description | Selected |
|--------|-------------|----------|
| Delete/rebuild primary lock | Prove freshness by mutating the tracked evidence object in the maintainer checkout. | |
| Inspect committed lock only | Use deterministic graph inspection without proving lockless resolution. | |
| Permanent task or CI lane | Add lasting security-proof infrastructure for this maintenance milestone. | |
| Disposable exact-commit probe | Resolve without a lock in an isolated detached worktree, then run the live Hex advisory audit and retain compact results. | ✓ |

**User's choice:** Approved two-class deterministic and network-dependent evidence.
**Notes:** No advisory suppression, raw committed logs, permanent script, or new required lane. Phase 147 retains all-four clean advisory closure.

---

## Compatibility-fix Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Failure-driven narrow internal fix | Permit only the smallest source change proved necessary by Req 0.6 compile/test failure, with a focused regression. | ✓ |
| Proactive transport refactor | Modernize client structure or behavior while dependencies are changing. | |
| Defer every source fix | Refuse even a demonstrated compatibility repair. | |
| Broader dependency modernization | Use the advisory work to move to package heads or alter public behavior. | |

**User's choice:** Approved the failure-driven boundary and stop/re-plan rules.
**Notes:** Public APIs, tagged errors, request defaults, telemetry meaning, and consumer DX stay unchanged.

---

## Research and Recommendation Format

The user selected all four gray areas and requested parallel subagent research covering
Elixir/Hex/Plug/Phoenix idioms, ecosystem precedent, security/SRE/release engineering,
maintainer and adopter JTBD, developer ergonomics, local `prompts/` research, and a
single cohesive recommendation. Three focused advisor researchers and one adversarial
coherence reviewer were used. The user then selected **Approve and capture it**.

## the agent's Discretion

- Exact placement of the focused Req.Test additions.
- Exact targeted dependency-update commands per graph, subject to the approved lock-diff boundary.
- Which existing live Meilisearch command supplies supplemental evidence when services are available.

## Deferred Ideas

- Phase 145: legacy Phoenix/Bandit/Ecto/Decimal/Postgrex remediation.
- Phase 146: Ops web/client/Swoosh remediation and explicit `Swoosh.ApiClient.Req` proof.
- Phase 147: ecommerce remediation and dated all-four-graph advisory closure.
- Future milestone only: broader dependency modernization or permanent dependency-security automation.
