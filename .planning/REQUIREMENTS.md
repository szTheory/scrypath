# Requirements: Scrypath v1.5

**Defined:** 2026-04-17  
**Milestone:** v1.5 "Operator drift and schema-diff tooling"  
**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## v1.5 Requirements

Additive over the current Hex line; **no breaking changes** to existing `@enforce_keys` on public operator structs unless explicitly called out in a phase plan. **Report-first:** new surfaces describe drift; they do **not** introduce silent auto-heal or new index mutation verbs beyond what v1.4 already allows.

### Schema and index contract (prefix: DRIFT15)

- [x] **DRIFT15-01**: Operator can obtain a **read-only** structured report for a given searchable schema that compares **declared** Scrypath metadata (at minimum: `fields:`, `filterable:`, `sortable:`, `faceting:` where present, and Meilisearch `settings:` keys the library applies) to the **live** Meilisearch index posture relevant to search and sync correctness. *(Phase 27, 2026-04-17)*

- [x] **DRIFT15-02**: The report **names dimensions** that differ (e.g. filterable set, sortable set, facet-related configuration, selected settings families) with enough specificity for an operator to decide **managed `reindex/2`**, **`hot_apply/3`**, or deeper investigation — without requiring raw Meilisearch JSON dumps as the only output. *(Phase 27, 2026-04-17)*

### Operator surface and verification (prefix: OPS15)

- [x] **OPS15-01**: The capability is reachable from **`Scrypath.*`** (or a single documented operator entry point that delegates to it) and preserves the same **report-first** posture as `reconcile_sync/2` — **no new recovery verbs** in v1.5. *(Phase 27, 2026-04-17)*

- [ ] **OPS15-02**: A thin **`mix scrypath.*`** task (or documented extension of an existing operator task) prints the same structured report for terminal use, with **`--json`** optional where it matches existing operator CLI conventions.

- [ ] **OPS15-03**: **`guides/drift-recovery.md`** and **`docs/operator-support.md`** explain when to use **schema/index drift** reporting versus **`mix scrypath.settings.diff`**, **`Scrypath.reconcile_sync/2`**, and managed **`reindex/2`**.

- [ ] **OPS15-04**: Auth-free **`mix verify.phase27`** (or the next free phase slot if renumbered) runs focused tests and **`mix docs --warnings-as-errors`**, locking the public contract for this milestone.

## v2+ Requirements (deferred)

Tracked for later milestones; not in v1.5 roadmap.

### Faceting

- **FACET-V14-01**: Hierarchical / nested facet declarations.  
- **FACET-V14-02**: First-class disjunctive facet counts.  
- **FACET-V14-03**: `search_within_facet/4`.

### Multi-index

- **MULTI-V14-01** … **MULTI-V14-03**: Federation relevance normalization, custom weighting, `:all`-schema wildcard.

### Relevance

- **TUNE-V15-01**: Per-query setting overrides (blocked on pipeline semantics design).

### Operator

- **OPS-V14-02**: `reason_class`-driven branching inside `reconcile_sync/2` — still **out** until report-first discipline is revisited.

## Out of Scope (v1.5)

| Item | Reason |
|------|--------|
| Automatic index repair or silent mutation from drift reports | Violates report-first operator discipline; keep recovery explicit. |
| Full document corpus diff / reprojection of every row by default | Operational cost and ambiguity; bounded sampling could be a later phase if needed. |
| Public multi-backend abstraction | Product boundary unchanged. |
| Vector / hybrid / semantic search | Explicit non-goal until core search ops are settled. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DRIFT15-01 | Phase 27 | Complete (2026-04-17) |
| DRIFT15-02 | Phase 27 | Complete (2026-04-17) |
| OPS15-01 | Phase 27 | Complete (2026-04-17) |
| OPS15-02 | Phase 28 | Pending |
| OPS15-03 | Phase 28 | Pending |
| OPS15-04 | Phase 28 | Pending |

**Coverage:** v1.5 requirements: **6** — mapped: **6** — unmapped: **0**

| Phase | Goal | Requirements |
|-------|------|----------------|
| **Phase 27** — Schema–index drift report (read-only) | Structured declared-vs-live comparison on `Scrypath.*` | DRIFT15-01, DRIFT15-02, OPS15-01 |
| **Phase 28** — Operator CLI, docs, and verify gate | Mix + guides + `mix verify.phase27` | OPS15-02, OPS15-03, OPS15-04 |

---
*Requirements defined: 2026-04-17 — v1.5 milestone kickoff (drift / schema-diff default pick)*
