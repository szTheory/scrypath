# Phase 40: `:all` expansion - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in **40-CONTEXT.md** — this log preserves the alternatives considered.

**Date:** 2026-04-20
**Phase:** 40 — `:all` expansion
**Areas discussed:** Expansion call-site shape; resolution / registry; cardinality & errors; timeouts & failure boundaries

**Mode:** User selected **all** gray areas and requested **parallel subagent research** + **one-shot synthesis** into a single coherent recommendation set (no interactive Q&A turns).

---

## 1) Expansion call-site shape

| Option | Description | Selected |
|--------|-------------|----------|
| A | Pseudo-schema module in tuple slot |  |
| B | `:all` atom replaces schema in `{schema, text, opts}` |  |
| C | Shared-only `schemas: :all` / `expand: :all` |  |
| D | Separate `search_all_schemas/2` |  |
| E | Tagged list element `{:all, text, opts}` spliced into `entries` | ✓ |

**User's choice:** **E** (synthesis of research) — preserves Phase **21** tuple spine and Phase **39** per-entry **`federation_weight:`** story; avoids second top-level verb (D) and shared-opt ambiguity (C).

**Notes:** Ecosystem parallels (Scout per-model composition, Algolia/Typesense “explicit query list”) favor **expanding to a real list** over magic globals.

---

## 2) Resolution / registry

| Option | Description | Selected |
|--------|-------------|----------|
| 1 | `Application` config allowlist | ✓ (default) |
| 2 | Compile-time-only list |  |
| 3 | Reflection / scan codebase | ✗ (explicit reject) |
| 4 | Behaviour “catalog” module | ○ (doc pattern only) |
| 5 | Hybrid config + per-call override | ✓ |

**User's choice:** **Config allowlist** + **`global_schemas:`** (name TBD) **replaces** config when passed; **declared, never discovered**.

**Notes:** Searchkick / Meilisearch-Rails / Scout converge on **explicit per-model opt-in**; global search is app-authored orchestration.

---

## 3) Cardinality & errors

| Outcome | Tuple | Selected |
|---------|-------|----------|
| Expanded length > `max_schemas` | `{:too_many_schemas, count, max}` | ✓ |
| Registry resolves to zero | `{:invalid_options, {:all_expansion, :empty_registry}}` | ✓ |
| Ambiguous resolution | `{:invalid_options, {:all_expansion, {:ambiguous, metadata}}}` | ✓ (reserved if needed) |
| Caller passed `[]` | `:empty_schema_list` | ✓ (unchanged) |

**User's choice:** Hybrid — reuse **`too_many_schemas`** for count rail; new **`all_expansion`** details only under **`invalid_options`**.

---

## 4) Timeouts & failure boundaries

| Topic | Decision | Selected |
|-------|----------|----------|
| Resolution vs HTTP | Registry / expansion / max count errors → `{:error, _}` before HTTP | ✓ |
| Timeout split | Keep **`federation_timeout`** + per-schema **`hydration_timeout`** | ✓ |
| Per-slot option validation | Stay **fail-fast** `{:validation_failed, …}` like today | ✓ |
| Partial envelope | Hydration / sequential / MULTI-07 paths unchanged | ✓ |

**User's choice:** **No** single merged timeout; **no** silent drop of invalid opts slots in Phase 40 (would diverge from shipped validation).

---

## Claude's Discretion

- Final names: **`global_schemas:`**, config key examples, **`{:ambiguous, metadata}`** key set.

## Deferred Ideas

- Shared-only sugar with strict lowering; soft validation / drop-slot semantics as a future contract milestone.
