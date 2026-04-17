# Phase 22: Operator Polish + Drift Recovery Guide - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `22-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-04-17
**Phase:** 22 — Operator Polish + Drift Recovery Guide
**Areas discussed:** Telemetry payload (OPS-10), Drift guide cross-links (OPS-09), `metadata.discard_reason`, Classifier test strategy (OPS-06)

**Mode:** User requested all four gray areas in one pass with parallel subagent research and a synthesized “no further user decisions” recommendation set.

---

## Telemetry payload (OPS-10)

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal only | `reason_class`, `schema`, `mode` + `count` only | Partial |
| Rich default | Add `id`, freeform `source`, raw errors | No |
| Bounded optional | Required three + optional `operation`, `retryable?`; no high-cardinality defaults | ✓ |

**User's choice:** Research-led synthesis — **D-01..D-05** in `22-CONTEXT.md`.

**Notes:** Aligns with Elixir ecosystem pattern (Oban/Ecto emit wide maps but handlers filter); Scrypath explicitly avoids cardinality/PII footguns while improving triage vs strictly three keys.

---

## Drift guide cross-links (OPS-09)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Footer only | Self-contained scenarios; single Related guides | Partial |
| B — Inline-heavy | Deep links throughout each scenario | No |
| Hybrid | Self-contained bodies + ≤1 disambiguation link per scenario + top map + bottom Related | ✓ |

**User's choice:** Research-led synthesis — **D-06..D-09**.

**Notes:** Matches Kubernetes/Elastic/Oban triage doc patterns; optimizes stressed-operator DX.

---

## `metadata.discard_reason` for `:queue_exhausted`

| Option | Description | Selected |
|--------|-------------|----------|
| Ship in v1.3 | Optional `:exhausted \| :explicit` in metadata | No |
| Defer | Rely on Oban state + attempt/max_attempts + reason | ✓ |

**User's choice:** Research-led synthesis — **D-10, D-11** (narrow polish; Oban modern `:cancel` path reduces need).

---

## Classifier verification (OPS-06)

| Option | Description | Selected |
|--------|-------------|----------|
| Integration-heavy | Live backends, large snapshots | No |
| Golden tables only | Strings matched everywhere | Partial |
| Normalize→classify + tables + thin contracts | Unit tables on normalized input; few boundary tests | ✓ |

**User's choice:** Research-led synthesis — **D-12..D-15**.

---

## Claude's Discretion

Exact test grouping, Guide map copy, and whether any contract test hits live Meilisearch — left to planner/implementer within CONTEXT bounds.

## Deferred Ideas

See `<deferred>` in `22-CONTEXT.md` (`discard_reason`, richer telemetry defaults, heavy property fuzz).
