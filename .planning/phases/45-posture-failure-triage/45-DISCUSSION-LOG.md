# Phase 45: Posture & failure triage - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in **45-CONTEXT.md** — this log preserves the alternatives considered.

**Date:** 2026-04-21
**Phase:** 45-posture-failure-triage
**Areas discussed:** Schema coverage & configuration; Posture landing signals/layout/refresh; Failed-work triage UX vs CLI parity; Sync/drift read-only surface
**Mode:** User selected **all** areas and requested one-shot research-backed recommendations; four parallel research agents synthesized into **45-CONTEXT.md** (no interactive Q/A loop).

---

## Schema coverage & configuration

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit allowlist in host config | Deterministic, reviewable, fails closed | ✓ |
| Runtime module discovery | Low boilerplate, unsafe/non-deterministic default | |
| Demo-only hardcoded | OK for samples, not production source of truth | |

**User's choice:** Locked to **explicit allowlist** (see **D-01**..**D-03** in CONTEXT).
**Notes:** Compared to Searchkick/Scout opt-in registration, Sidekiq/Horizon explicit connections, K8s-dashboard-style discovery as anti-pattern.

---

## Posture landing: signals, layout, refresh

| Option | Description | Selected |
|--------|-------------|----------|
| Hybrid table + expand | Fleet scan + per-schema backend/queue detail | ✓ |
| Cards-first | Rejected for multi-schema density | |
| Manual + optional slow poll while visible | Predictable load; avoids thundering herd | ✓ |
| Aggressive periodic poll | Rejected as default | |

**User's choice:** Research-default bundle adopted (**D-04**..**D-08**).
**Notes:** References Sidekiq/AWS Health/Grafana patterns; avoids Datadog-style cardinality in UI telemetry.

---

## Failed-work triage: UX vs CLI parity

| Option | Description | Selected |
|--------|-------------|----------|
| `%FailedSyncWorkInspection{}` default | Coherent rows + rollups in one API snapshot | ✓ |
| Raw list without counts in assigns | Rejected (harder to keep rollups honest) | |
| Paginate without labeling subset | Rejected (rollup footgun) | |

**User's choice:** **`reason_class_counts: true`** default; table/expand behavior per **D-09**..**D-14**.
**Notes:** Human CLI builds rollups separately; UI uses documented enriched return for structural honesty.

---

## Sync/drift read-only surface

| Option | Description | Selected |
|--------|-------------|----------|
| Reconcile without drift flag + lazy `index_contract_drift/2` | Cheap default; isolated drift failures | ✓ |
| `include_index_contract_drift: true` on every load | Rejected (couples failures + extra read) | |
| Tabs vs single scroll | Single scroll two sections preferred (**D-15**) | ✓ |

**User's choice:** **D-15**..**D-19**.
**Notes:** Terraform-plan-style read-only aggregate first; explicit second action for contract drift.

---

## Claude's Discretion

Exact config keys, optional ETS cache, auto-refresh numeric default when enabled, minor layout polish.

## Deferred Ideas

See **45-CONTEXT.md** `<deferred>` — phase 46–47 boundaries and optional combined reconcile+drift export.
