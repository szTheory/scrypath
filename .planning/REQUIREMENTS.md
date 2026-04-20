# Requirements: Scrypath v1.7

**Defined:** 2026-04-19  
**Milestone:** v1.7 — *Facet depth and catalog search UX*  
**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

**Planning note:** Scope follows the post–v1.6 ROI plan: **facet depth first** on existing Meilisearch faceting; **multi-index federation** and **per-query relevance overrides** are explicitly **not** in v1.7. Relevance work is gated on a **design prerequisite** (**`TUNE-PIPE-01`**) before any implementation milestone.

## v1.7 Requirements

### Faceting (prefix: FACET)

- [ ] **FACET-01**: **Hierarchical facets** — Adopters can model **nested facet paths** (within what Meilisearch supports for the index) through declarative schema/settings, and `Scrypath.search/3` (or documented equivalent) returns **stable, documented** facet keys and counts for those paths.

- [ ] **FACET-02**: **Disjunctive facet counts** — The library exposes a **clear contract** for **OR-style** facet selection vs conjunctive filters, including how facet **counts** behave under disjunctive filters; edge cases are documented and covered by tests.

- [ ] **FACET-03**: **`search_within_facet/4`** — A public entry (this name unless planning renames it) lets callers run a **text search scoped to a facet bucket**, composing filters consistently with existing `search/3` / facet filter behavior.

- [ ] **FACET-04**: **Facet depth documentation and contracts** — At least one **guide or major doc section** plus **`docs_contract_test.exs`** (or equivalent) anchors for new/changed public facet APIs so root README / ExDoc paths do not drift.

## Future requirements

### Multi-index (prefix: MULTI) — target post–v1.7

- **MULTI-01**: Federation **scoring / weighting** across `search_many/2` entries with predictable merge semantics.

- **MULTI-02**: **`:all` wildcard** (or equivalent) for multi-search with documented limits, caps, and timeout behavior.

### Relevance / tuning (prefix: TUNE)

- **TUNE-PIPE-01** (**design milestone prerequisite**): Produce an **authoritative spec** for any future **per-query relevance / settings override pipeline** — ordering, precedence vs schema defaults, Meilisearch request mapping, and explicit non-goals. **No runtime implementation** in v1.7; this REQ tracks the **design artifact** only when that milestone is opened.

- **TUNE-01** (**implementation**, blocked): Per-query relevance or settings overrides in application code — **blocked on `TUNE-PIPE-01`** and a follow-on implementation milestone.

## Out of Scope (v1.7)

| Item | Reason |
|------|--------|
| `MULTI-*` federation scoring, weighting, `:all` wildcard | Reserved for a **multi-index** milestone after facet depth ships. |
| `TUNE-01` per-query relevance / overrides (runtime) | **Sharp edges** without **`TUNE-PIPE-01`** pipeline semantics; defer per ROI plan. |
| Public multi-backend abstraction | Product boundary unchanged. |
| Vector / hybrid / personalization search | Still deferred (see `PROJECT.md` Out of Scope). |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| FACET-01 | Phase 36 | Pending |
| FACET-02 | Phase 37 | Pending |
| FACET-03 | Phase 38 | Pending |
| FACET-04 | Phase 38 | Pending |

**Coverage:** v1.7 requirements: **4** — mapped: **4** — unmapped: **0**.
