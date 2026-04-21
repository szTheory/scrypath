# Phase 46: Search & federation honesty - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in **46-CONTEXT.md**.

**Date:** 2026-04-21
**Phase:** 46 — Search & federation honesty
**Areas discussed:** Default bounds & config source; Initial single vs multi mode; Inspector layout & disclosure; Schema allowlist for search

**Method:** User selected **all** gray areas and requested deep comparative research. Four parallel **`generalPurpose`** subagents produced pros/cons, ecosystem analogues, and draft recommendations; orchestrator synthesized into a single coherent policy in **46-CONTEXT.md**.

---

## Default bounds and config source

| Approach | Description | Selected |
|----------|-------------|----------|
| A — Code only | Fixed defaults, no host tuning | |
| B — Config/env only, no floor | Flexible but unsafe if unset | |
| C — Hybrid | Code floors + host overrides within library ceilings | ✓ |
| D — UI silent clamp | Hide over-limit by coercing | ✗ (violates UI-SPEC) |

**User's choice:** **Hybrid (C)** — default **`page.size` 15**, max **50** aligned with **`Scrypath.MultiSearch.Entries`**, **`max_schemas`** aligned with library default **10** with host option to **lower**; structured **`:scrypath_ops`** config + documented env; hard errors not silent clamps; low-cardinality telemetry.

**Notes:** Analogues (Sidekiq Web, Horizon, Kibana, Meilisearch admin) favor explicit ceilings and operator-tool framing over open-ended analytics.

---

## Initial single vs multi mode

| Approach | Description | Selected |
|----------|-------------|----------|
| Default multi | Immediate federation inspector | |
| Default single | Bounded first paint; multi opt-in | ✓ |
| URL `?mode=` | Bookmarkable mode | ✓ (with `push_patch`) |

**User's choice:** **Default single** + static honesty copy + **`?mode=multi`** + optional session memory; **no auto-run** on mount.

**Notes:** Aligns with Postman collection runner / GraphQL playground patterns — heavy paths are explicit.

---

## Inspector layout and disclosure

| Approach | Description | Selected |
|----------|-------------|----------|
| Expanded merge/weights | Maximum visibility on load | |
| Collapsed details, L1 summaries | Progressive disclosure | ✓ |

**User's choice:** Inverted-pyramid ops IA — honesty caption and aggregate **always visible**; merge order and weights **collapsed by default** with strong summaries; partial failures → **banner + `aria-live="polite"`** + **`<details>`** for verbose diagnostics; hard errors outside `<details>` only.

**Notes:** Aligns with DevTools Network / Sentry-style progressive disclosure.

---

## Schema allowlist

| Approach | Description | Selected |
|----------|-------------|----------|
| One list | `Schemas.allowlist/0` for everything | ✓ |
| Two lists | Search subset | Deferred (**46-CONTEXT** D-19) |

**User's choice:** **Single `:schema_allowlist`** for search targets in v1.10; subset only later with **boot-time subset validation**.

**Notes:** Avoids drift between triage and search; matches phase 45 explicit-wiring philosophy.

---

## Claude's Discretion

Exact env key spellings for playground bounds; optional canonicalizing default URL for `mode`; microcopy for merge trace control.

## Deferred Ideas

- Second search-only allowlist without strong subset rules — deferred per **46-CONTEXT.md**.
