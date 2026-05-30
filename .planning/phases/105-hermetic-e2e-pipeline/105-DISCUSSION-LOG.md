# Phase 105: Hermetic E2E Pipeline - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-30
**Phase:** 105-hermetic-e2e-pipeline
**Areas discussed:** E2E Harness Boundary, Data and Index Readiness, CI Gate Placement, Operator Workflow Proof Shape, Failure Injection Strategy

---

## E2E Harness Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Playwright owns Phoenix boot | Use Playwright `webServer.command` as the lifecycle owner. Convenient local DX, but hides Elixir/Phoenix boot and readiness concerns behind Node orchestration. | |
| Mix/GitHub Actions own boot | CI/Mix own services, DB setup, app boot, and readiness; Playwright only drives the browser. Clearer Phoenix-native ownership and failure attribution. | ✓ |
| Hybrid wrapper | Playwright invokes a Mix wrapper. Better local convenience, but introduces dual-runtime lifecycle ownership. | |

**User's choice:** Approved the recommendation set.
**Notes:** Research favored operational clarity over convenience. This matches Phoenix/Ecto conventions and Scrypath's operational-honesty posture.

---

## Data and Index Readiness

| Option | Description | Selected |
|--------|-------------|----------|
| Deterministic harness | Seed deterministic fixture, explicitly drain Oban, poll Meilisearch task/search visibility, then assert UI with Playwright retrying expectations. | ✓ |
| Real-worker integration lane | Let Oban workers run naturally and poll until visible. More production-like, but slower and more prone to CI flake. | |
| Two-lane strategy | Deterministic lane first, real-worker canary later once stability is proven. | ✓ |

**User's choice:** Approved the recommendation set.
**Notes:** The locked path is deterministic first, with a later real-worker canary deferred until the browser lane is stable.

---

## CI Gate Placement

| Option | Description | Selected |
|--------|-------------|----------|
| Required `phase105` PR check immediately | Strong protection but high flake blast radius and branch-protection drift risk. | |
| Advisory PR / main-monitor lane | Preserves lean required gates while proving real browser + service behavior continuously. | ✓ |
| Fold into existing live-example lane | Reuses existing infrastructure but makes failures noisier and harder to triage. | |

**User's choice:** Approved the recommendation set.
**Notes:** Promotion to a required check is deferred until stable runtime, low flake rate, artifact quality, and job naming are proven.

---

## Operator Workflow Proof Shape

| Option | Description | Selected |
|--------|-------------|----------|
| UI-only browser proof | Assert admin-visible state only. Resilient but can create false confidence if backend side effects fail. | |
| Hybrid UI + stable backend truths | Assert operator-visible UI and a small set of durable backend/index outcomes. | ✓ |
| Full internals proof | Assert queue payloads, DB rows, raw task JSON, and UI. Maximum coverage but brittle and slow. | |

**User's choice:** Approved the recommendation set.
**Notes:** Browser tests should stay user-outcome oriented while helper probes prove stable operational truth.

---

## Failure Injection Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Bad backend/config state | Real transport/auth failure path, but can be flaky and globally disruptive. | |
| Bad document/settings mismatch | Deterministic backend rejection, but can overfit to one Meilisearch error shape. | |
| Direct Meilisearch task rejection | Good backend task decoding proof, but may bypass the real app write path. | |
| Dev/test-only one-shot failure hook | Deterministic scenario-scoped failure through existing E2E route pattern, shaped like real sync/backend failure. | ✓ |

**User's choice:** Approved the recommendation set.
**Notes:** The hook must remain dev/test-only and must not become a public Scrypath runtime API.

---

## The Agent's Discretion

- Exact Playwright spec/helper file split.
- Exact stable selector names where user-visible selectors are insufficient.
- Exact readiness helper implementation, provided it uses observable state rather than fixed sleeps.
- Whether the Phase 105 CI lane is a new workflow or a dedicated job in `ci.yml`, provided advisory/monitoring semantics are explicit.

## Deferred Ideas

- Required PR branch-protection promotion for Phase 105 E2E after stability is proven.
- Production-like real-worker canary lane after deterministic harness stability.
- Broader operator UI expansion and reusable UI widgets.
