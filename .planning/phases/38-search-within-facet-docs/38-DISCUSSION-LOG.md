# Phase 38: Search within facet + docs - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `38-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-04-20
**Phase:** 38 — Search within facet + docs
**Areas discussed:** Public API surface, Within-bucket semantics, Wire behavior & parity, FACET-04 documentation strategy

**Mode:** User selected **all** gray areas and requested **parallel subagent research** + **one-shot synthesis** (no interactive Q&A per area).

---

## 1) Public API surface

| Option | Description | Selected |
|--------|-------------|----------|
| A | Dedicated `search_within_facet/4` as primary API | ✓ (as public name; see hybrid) |
| B | Extend `search/3` only (`:within_facet` / `:facet_scope`) | Partially (internal pipeline / optional future sugar) |
| C | `Scrypath.Search.within_facet/4` without top-level export | |

**User's choice:** Delegated to synthesis — **Hybrid (A + B philosophy):** public **`search_within_facet/4`** for FACET-03 naming and grep-ability; **thin delegate** into the same stack as **`search/3`** (single validation + query path), avoiding divergent HTTP implementations.

**Notes:** Pure B-only would bury discoverability; pure duplicate stacks would drift. Searchkick/Scout/Meilisearch clients favor **one search with composed filters**; named wrapper matches REQ wording.

---

## 2) Within-bucket semantics

| Model | Description | Selected |
|-------|-------------|----------|
| A | Bucket = extra AND facet refinement composed with `filter:` / other `facet_filter:` | ✓ |
| B | “Scoped q only” — misleading name vs engine | |
| C | Bucket implies disjunctive / multi-search count context | |

**User's choice:** **Model A** — Meilisearch-aligned intersection semantics; hierarchical atoms are flat engine keys; Phase 37 disjunctive merge stays separate.

**Notes:** Document **LiveView** double-application (URL + opts) as normalization concern; library **rejects** same-attribute `facet_filter:` + bucket (CONTEXT D-06).

---

## 3) Wire behavior & parity

| Topic | Recommendation | Selected |
|-------|----------------|----------|
| Opts subset | Same as `search/3` where valid | ✓ |
| Same-key `facet_filter:` | Reject with `ArgumentError` | ✓ |
| Default transport | Single Meilisearch search POST | ✓ |
| Telemetry | Distinct event or extended metadata | ✓ (implementation discretion) |

**User's choice:** Adopted research recommendation for **operational honesty** and **Req.Test** continuity.

---

## 4) FACET-04 documentation

| Topic | Recommendation | Selected |
|-------|----------------|----------|
| README | Minimal line + link to guide | ✓ |
| Guide | Two new `##` sections, full semantics | ✓ |
| `docs_contract_test.exs` | 2–4 heading/short-line anchors | ✓ |
| ExDoc | Enrich `Scrypath` / `search/3` docs; keep `Scrypath.Search` private | ✓ |
| `mix verify.phase38` | Yes, mirror phase 36/37 | ✓ |

**User's choice:** Adopted — avoids dual-contract README prose churn.

---

## Claude's Discretion

Exact `facet_bucket` type spelling, bang naming timing, telemetry shape choice, final section heading strings (within D-13 intent).

## Deferred Ideas

- Option-only public surface without `search_within_facet/4` name
- Publicizing `Scrypath.Search` module documentation in this phase
