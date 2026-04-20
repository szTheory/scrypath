# Phase 37: Disjunctive facet counts - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `37-CONTEXT.md`.

**Date:** 2026-04-20
**Phase:** 37 — Disjunctive facet counts
**Areas discussed:** Facet count semantics; API vocabulary; Reference scenario & docs; Hierarchical interaction

**Mode:** User selected all recommended gray areas (1–4) and requested **parallel subagent research** plus **one-shot synthesized recommendations** (minimal interactive Q&A).

---

## Facet count semantics

| Option | Description | Selected |
|--------|-------------|----------|
| A — Engine counts only | Single search; document `facetDistribution` as returned | Partial |
| B — Document + recipe/helper | Honest single-search semantics + documented multi-search merge pattern | ✓ |
| C — Automatic multi-query | Opt-in wrapper with visible fan-out | Optional (gated) |

**User's choice:** **B** as default FACET-02 delivery; **A** as the semantic baseline for one response; **C** only explicit/opt-in with operational visibility.

**Notes:** Meilisearch documents disjunctive *counts* as multi-search; Algolia/InstantSearch established the same pattern. Subagent noted modern Meilisearch filter array semantics; repo still encodes **`facetFilters`** — semantics are locked; wire key verified at implementation time.

---

## API / vocabulary

| Option | Description | Selected |
|--------|-------------|----------|
| Infer OR from list values | `[genre: [a, b]]` under `facet_filter` | ✓ |
| Parallel `:disjunctive_facets` for filters | Second source of truth for same OR | ✗ |
| Reserve “disjunctive” naming | For count/multi-search features only | ✓ |

**User's choice:** Keep current **keyword-list** encoding; add new options only for **count** behavior helpers.

**Notes:** NimbleOptions-style validation + `Keyword.keyword?/1` range guard praised as idiomatic.

---

## Reference scenario & docs

| Option | Description | Selected |
|--------|-------------|----------|
| New `##` in primary guide | Normative disjunctive + count semantics | ✓ |
| Appendix only | | ✗ |
| `docs_contract_test` | 3–5 minimal substrings Phase 37 | ✓ |

**User's choice:** **`guides/faceted-search-with-phoenix-liveview.md`** — main section + appendix misconceptions; scenario **Genre OR + year AND**; small contract anchors now, FACET-04 breadth in Phase 38.

---

## Hierarchical × disjunctive

| Option | Description | Selected |
|--------|-------------|----------|
| Phase 37 core | Flat facet groups + documented multi-search counts | ✓ |
| Productized hierarchical OR | Parent counts, multi-branch tree | ✗ (non-goals) |

**User's choice:** **Scope lock** — FACET-02 proves flat disjunctive count story + caveats for hierarchical keys; no Algolia hierarchicalMenu parity in core.

---

## Claude's Discretion

Exact helper API placement, telemetry naming, and whether automatic orchestration ships in 37 vs later, subject to planner sizing.

## Deferred Ideas

See `<deferred>` in `37-CONTEXT.md`.
