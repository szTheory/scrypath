# Phase 146: ScrypathOps Web/Client Remediation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-24
**Phase:** 146-scrypathops-web-client-remediation
**Areas discussed:** Fixed-compatible manifest bounds, Production-shaped Swoosh/Req proof, Web/LiveView/database compatibility proof, Gate order/evidence/stop conditions

---

## Fixed-compatible manifest bounds

| Option | Description | Selected |
|--------|-------------|----------|
| Bounded fixed-compatible floors | Three-part pessimistic requirements at each recorded fixed floor, with transitive ownership preserved. | ✓ |
| Lock-only refresh | Keep the current broad manifest requirements and rely on the checked lock. | |
| Exact pins/direct transitive floors | Pin exact versions or directly constrain every vulnerable transitive package. | |

**User's choice:** Follow the recommended option automatically.
**Notes:** Auto-selected Phoenix `~> 1.8.9`, LiveView `~> 1.1.33`, Bandit `~> 1.12.1`, Swoosh `~> 1.26.3`, Postgrex `~> 0.22.4`, and retained Req `~> 0.6.1`. Live Hex plus EEF CNA evidence satisfies the Postgrex stable-publication guard as of 2026-08-24; execution must re-check it.

---

## Production-shaped Swoosh/Req proof

| Option | Description | Selected |
|--------|-------------|----------|
| Real client with Req.Test | Test the actual `Swoosh.ApiClient.Req` wire/error contract without network or provider credentials. | ✓ |
| Live provider delivery | Configure a provider and send a real email over the network. | |
| Configuration-only assertion | Assert only that production names `Swoosh.ApiClient.Req`. | |

**User's choice:** Follow the recommended option automatically.
**Notes:** Preserve the suite-wide Swoosh test adapter and disabled API client. The focused contract covers required option precedence, request forwarding, raw response handling, tuple normalization, and transport errors.

---

## Web, LiveView, and database compatibility proof

| Option | Description | Selected |
|--------|-------------|----------|
| Existing comprehensive Ops gate | Use `mix verify.opsui` and add only demonstrated causal gap tests. | ✓ |
| New browser/protocol lane | Add browser, fragmented-WebSocket, or exploit-reproduction infrastructure. | |
| Resolution-only proof | Treat fixed lock versions as sufficient without running the application suite. | |

**User's choice:** Follow the recommended option automatically.
**Notes:** The existing gate already owns standalone dependency fetch, Postgres create/migrate, application/route/LiveView behavior, full ExUnit, and accessibility. Fixed selection plus unsuppressed audit proves upstream remediation; Phase 147 retains mounted ecommerce/browser proof.

---

## Gate order, evidence, and stop conditions

| Option | Description | Selected |
|--------|-------------|----------|
| Deterministic gates then detached audit | Explain the causal diff, run Ops/root gates, then exact-commit lockless resolution and unsuppressed audit. | ✓ |
| Audit first | Run only advisory evidence before application compatibility gates. | |
| In-place lock deletion or reviewed-lock only | Mutate the primary lock for fresh proof or skip independent fresh resolution. | |

**User's choice:** Follow the recommended option automatically.
**Notes:** One isolated ScrypathOps remediation commit; compact evidence only; failures, unavailable live evidence, out-of-range versions, unrelated lock churn, or scope expansion force a stop.

## the agent's Discretion

- Exact focused Swoosh test filename and isolation technique.
- Exact targeted dependency-update command sequence producing the locked causal result.
- Exact ordering of individual named root gates where dependency prerequisites dictate it.

## Deferred Ideas

- Ecommerce remediation, mounted browser proof, final four-graph audit evidence, and todo closure remain Phase 147.
- Permanent dependency/security automation and broad modernization require separate approval.
