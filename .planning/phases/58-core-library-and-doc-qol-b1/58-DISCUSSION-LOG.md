# Phase 58: Core library and doc QoL (B1) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`58-CONTEXT.md`**.

**Date:** 2026-04-22  
**Phase:** 58 — Core library and doc QoL (B1)  
**Areas discussed:** LIB-01 failure path + doc hop; LIB-02 non-macro clarity; LIB-03 doc-contract scope; PR / evidence packaging  
**Mode:** User selected **all** areas and requested parallel subagent research + one-shot coherent recommendations.

---

## LIB-01 — Error surface, success visibility, and doc hop

| Approach | Description | Selected |
|----------|-------------|----------|
| `{:error, _}` only | Richer tuple tags / messages | Partial — necessary, insufficient for EVID-57-01 |
| Bang exceptions only | Clearer `Exception.message/1` | Partial — keep for bangs; not primary for visibility |
| Both tuples + exceptions | Single normalized `reason` | ✓ |
| Map-only top-level errors | Rich metadata | ✗ — weak matching; avoid as sole shape |
| Tagged tuple + optional map tail | Matchable + metadata | ✓ |

**User's choice:** Adopt research synthesis: **primary** = success-path clarity + sync `@doc` + stable guide hops; **secondary** = tagged `{:error, _}` + shared formatter; bangs project same `reason`.  
**Notes:** Idiomatic Elixir library = tuples for control flow, exceptions as projection; telemetry over default Logger in library code.

---

## LIB-02 — Typespecs, docs, helpers (no new macros)

| Approach | Description | Selected |
|----------|-------------|----------|
| Public API churn | New macros / surface | ✗ |
| Internal `@typedoc` / `@spec` | Query + boundaries | ✓ |
| Nimble string matching | UX | ✗ — map to tagged errors (LIB-01) |
| `@opaque` everywhere | Hide representation | Deferred — hurts adapters |
| Private pure helpers | normalize_* | ✓ |

**User's choice:** **D-08–D-11** in CONTEXT — Query module honesty + Dialyzer-friendly boundary specs + NimbleOptions as schema.  
**Notes:** Searchkick/Scout macro magic traded for README grep; Scrypath trades for **typed pipeline + guides**.

---

## LIB-03 — Doc-contract anchors

| Approach | Description | Selected |
|----------|-------------|----------|
| Lock every string | Maximum drift detection | ✗ — editorial tax |
| Spine tokens + triads | Commands, paths, invariant lines | ✓ |
| Per-guide section tests | Long guides | Selective — already used for key guides |
| Playbook UI in core contract | Forward hooks | ✗ — defer to ops phases |

**User's choice:** Spine + triad + reconcile **extras** ∪ contract lists (**overview.md** gap).  
**Notes:** LIB-03 ties to EVID-57-01 but **separate PR** from LIB-01.

---

## PR packaging and traceability

| Approach | Description | Selected |
|----------|-------------|----------|
| One mega-PR | All LIB at once | ✗ |
| One PR per LIB-* | Clear bisect + changelog | ✓ |
| Stacked PRs | Dependency chains only | If needed |

**User's choice:** **Three PRs**; **LIB-01** and **LIB-03** both cite **EVID-57-01** in body but **separate merges**; patch semver default.

---

## Claude's Discretion

- Formatter module naming; optional **`Scrypath.Sync.Error`** introduction left to planner (**58-CONTEXT** D-22).

## Deferred Ideas

- CI regex evidence gate; playbook UI contracts in core; opaque struct boundary unless accessors ship.
