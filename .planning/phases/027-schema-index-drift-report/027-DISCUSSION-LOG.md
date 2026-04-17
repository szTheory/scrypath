# Phase 27: Schema–index drift report (read-only) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in **027-CONTEXT.md** — this log preserves the alternatives considered.

**Date:** 2026-04-17
**Phase:** 27 — Schema–index drift report (read-only)
**Areas discussed:** Public entry and return shape; Report carrier and versioning; Overlap with `settings.diff` / `verify_applied`; `%Reconcile{}` coupling
**Method:** User selected **all** areas; deep research via **four parallel general-purpose subagents**; principal assistant synthesized into locked decisions.

---

## 1. Public entry and return shape

| Option | Description | Selected |
|--------|-------------|----------|
| A — Top-level `Scrypath.*` delegate | Thin facade to `Operator`, `{:ok, report} \| {:error, _}` | ✓ |
| B — `Scrypath.Operator` only | Discoverability friction vs OPS15-01 | |
| C — Fold into `%Reconcile{}` / `drift_signals` | Semantic collision with operational `drift_signals` | |

**User's choice:** **A** as primary (with **B** as implementation layer), explicit rejection of **C** for contract drift semantics.
**Notes:** Searchkick-style separation of index definition introspection from reindex health; Laravel Scout-style explicit commands vs one mega-status API.

---

## 2. Report carrier and versioning

| Option | Description | Selected |
|--------|-------------|----------|
| Public structs + `version: 1` | Dialyzer, Jason.Encoder, OrderedObject, ExDoc | ✓ |
| Bare maps as public contract | Weak enforcement, ambiguous omission | |
| Sparse-only JSON | Ambiguous parity vs “not computed” | |
| Dense / explicit-status JSON | Stable for `jq` and Phase 28 `--json` | ✓ |

**User's choice:** Structs + root version + explicit per-axis or dense parity semantics for JSON; human output may stay sparse in Phase 28.
**Notes:** Aligns with `ReasonClassCounts` Phase 26 precedent.

---

## 3. Overlap with `settings.diff` / `verify_applied` / `compute_drift`

| Option | Description | Selected |
|--------|-------------|----------|
| Orchestrated report + pure compares + one snapshot | Single narrative, reuse `compute_drift/2` | ✓ |
| Two independent tools with duplicate GETs | Contradiction and cost risk | |
| Overload `verify_applied` for full contract | Blurs reindex gate / hot-apply story | |

**User's choice:** Single orchestration; settings slice uses same wire pair and **`compute_drift/2`**; keep **`verify_applied`** focused.

---

## 4. `%Reconcile{}` coupling

| Option | Description | Selected |
|--------|-------------|----------|
| Standalone API only | Focused cheap read | ✓ (primary) |
| Opt-in field on reconcile | One-glance snapshot when wanted | ✓ (optional add-on) |
| Always embed | Heavier default; blurs concerns | |

**User's choice:** Standalone report is canonical; **optional** reconcile attachment via keyword, **default off**, same builder as standalone.

---

## Claude's Discretion

Exact public names (`index_contract_drift` vs alternatives), struct module names, telemetry presence, bang variant — see CONTEXT.md.

## Deferred Ideas

Phase 28 Mix/docs/verify; possible future optimization of double `get_settings` on settings.diff drift path.
