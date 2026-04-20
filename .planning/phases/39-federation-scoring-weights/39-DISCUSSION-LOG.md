# Phase 39: Federation scoring & weights - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `39-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-04-20
**Phase:** 39 — Federation scoring & weights
**Areas discussed:** Per-entry weight API, Defaults/validation/errors, Merged ordering surface, Sequential backend fallback

**Mode:** User selected **all** areas; **parallel subagent research** + **one-shot synthesis**; user then confirmed **write CONTEXT + log + commit**.

---

## 1) Federation weight API shape

| Option | Description | Selected |
|--------|-------------|----------|
| A | Per-entry `federation_weight:` on tuple opts | ✓ |
| B | Parallel `federation_weights: […]` in shared_opts | |
| C | `federation_weights: %{Module => float}` | |
| D | Hybrid defaults + per-entry override (optional later) | Partial (D-04 only as optional follow-up) |

**User's choice:** **A** — co-located with `{schema, text, opts}`; maps 1:1 to Meilisearch **`queries[].federationOptions`**; safe with Phase 21 duplicate schemas.

**Notes:** Searchkick-style multi-search and Meilisearch clients favor **per-query** options bodies, not parallel arrays or module-keyed maps for non-unique modules.

---

## 2) Defaults, validation, semver, errors

| Topic | Recommendation | Selected |
|-------|----------------|----------|
| Default on wire | Omit `weight` when caller omits option | ✓ |
| Validation | Finite numbers; reject NaN/Inf; no sum-to-1 | ✓ |
| Semver | Additive minor | ✓ |
| Invalid weight | `{:invalid_options, {:federation_weight, detail}}` | ✓ |
| Strip before schema opts validation | Yes | ✓ |

**User's choice:** Adopted — matches **`Entries`** / **`Options`** / **`Config`** layering from subagent review.

---

## 3) Merged ordering on `%MultiSearchResult{}`

| Option | Description | Selected |
|--------|-------------|----------|
| A | Duplicate `merged_hits` payloads on struct | |
| B | Reference list `{schema, id}` merge trace + optional helper | ✓ |
| C | Metadata-only (insufficient alone) | |
| D | Standalone `to_merged_view/1` only | Partial (helper **plus** B trace) |

**User's choice:** **B + helper** — canonical hits stay in **`%SearchResult{}`**; trace is O(n) references; **`nil`** when undefined/misleading.

**Notes:** Enables omnibox + future **OPSUI-01** without two sources of truth for hit payloads.

---

## 4) Sequential `search_many` fallback

| Option | Description | Selected |
|--------|-------------|----------|
| A/D | `{:error, {:invalid_options, …}}` if merge-only opts and no `search_many/2` | ✓ |
| B | Silently ignore weights | |
| C | Client-side merge in Elixir | |

**User's choice:** **Fail fast** with **`federation_merge_requires_native_search_many`** (exact inner shape: implementation discretion per CONTEXT).

**Notes:** Preserves honest semantics for **`FakeBackend`** tests and production adapters.

---

## Claude's Discretion

Exact public field name for merge trace, exact error map shape, `federation_weight:` vs nested `federation:` keyword, optional `queriesPosition` in trace for debugging.

## Deferred Ideas

- Phase 40 **`:all`** expansion; Phase 41 full doc contracts; **OPSUI-01** operator UI.
