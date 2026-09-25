# Phase 111: Advisory Proof Stability Decision - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-05-31
**Phase:** 111-Advisory Proof Stability Decision
**Areas discussed:** Evidence window and source of truth, Stability threshold, Failure artifact standard, Gate posture decision

---

## Evidence Window and Source of Truth

| Option | Description | Selected |
|--------|-------------|----------|
| PR-only rolling window | Last N PR runs of `phase105-e2e`; direct merge-risk signal but narrow and sample-size sensitive. | |
| Default-branch workflow-run ledger | Main/scheduled run history as canonical source; stable for release trust but weaker for PR merge-risk. | |
| Dual-window scorecard | Use main/scheduled runs for canonical stability and PR runs for merge-risk, with retry/flaky signal included. | x |

**User's choice:** User asked the agent to consider all areas using subagent-backed research and produce one cohesive recommendation set. The synthesized recommendation selected the dual-window scorecard.
**Notes:** Advisor research emphasized GitHub Actions run/ref scoping, avoiding local-branch-ahead confusion, and preserving lean required gates while building promotion-grade evidence.

---

## Stability Threshold

| Option | Description | Selected |
|--------|-------------|----------|
| Stay advisory with explicit stability SLOs | Keeps gates lean while evidence matures, but risks advisory drift without owner follow-through. | |
| Graduated promotion | Advisory to shadow-required to required after objective thresholds and rollback criteria are satisfied. | x |
| Promote now | Strong enforcement but high risk of merge friction, flake amplification, and branch-protection churn. | |
| Scoped required check | Required only for high-risk paths; balances speed but creates trigger and false-negative risks. | |

**User's choice:** User delegated the decision to researched synthesis. The synthesized recommendation selected graduated promotion.
**Notes:** Thresholds should include stable job identity, low flake including retry-pass classification, bounded runtime, actionable artifacts, owner response, and explicit trigger rules.

---

## Failure Artifact Standard

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal proof-of-failure bundle | Playwright report, test-results, and Phoenix log only; low overhead but often ambiguous. | |
| Layered actionable triage bundle | Playwright report/trace/results, Phoenix log, Meilisearch health/tasks, and readiness/data snapshot. | x |
| Full diagnostic pack | Adds broad infra/container/DB dumps; maximum depth but noisy, expensive, and contributor-hostile. | |

**User's choice:** User delegated the decision to researched synthesis. The synthesized recommendation selected a layered actionable triage bundle.
**Notes:** "Actionable" means maintainers can classify product regression versus infra/readiness noise without immediate rerun. Collection should remain bounded and avoid sensitive/noisy dumps.

---

## Gate Posture Decision

| Option | Description | Selected |
|--------|-------------|----------|
| Remain advisory as-is | No friction but no stronger evidence and risk of stale confidence. | |
| Harden advisory with evidence collection | Builds promotion-grade evidence without increasing required-check friction. | x |
| Prepare future promotion path | Defines criteria and trigger rules without promoting now. | x |
| Promote now | Strong enforcement but unsupported by current visible evidence and risky for branch protection. | |
| Remove or replace | Simplifies CI but loses true browser/live-services proof. | |

**User's choice:** User approved creating context with the synthesized recommendation.
**Notes:** The locked posture combines hardening advisory evidence with a future promotion path. `phase105-e2e` remains advisory in Phase 111 and branch protection is unchanged.

---

## the agent's Discretion

- User explicitly asked the agent and subagents to research all areas and provide a one-shot coherent recommendation set.
- Planner may choose exact artifact implementation and threshold wording as long as the result stays lightweight, explicit, and aligned with the advisory posture.

## Deferred Ideas

- Required-check promotion for `phase105-e2e`.
- Scoped/path-based required promotion.
- Full diagnostic artifact dumps.
- Replacing `phase105-e2e` with another proof lane.
- Any new runtime API, product-surface expansion, backend broadening, autocomplete/suggestions, vector/hybrid, or unrelated website truth work.
