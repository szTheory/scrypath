# Requirements: Scrypath v1.4

**Defined:** 2026-04-17  
**Milestone:** v1.4 "Public package parity & operator depth"  
**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## v1.4 Requirements

Additive over `scrypath 0.3.0` / v1.3 planning surface; no breaking changes to `%SearchResult{}`, `%Query{}`, or `%FailedWork{}` `@enforce_keys`.

### Release & Hex parity (prefix: SHIP)

Ship the accumulated library surface on Hex with the same mechanical gates used for `0.3.0`.

- [x] **SHIP-01**: Semver **0.3.1** was cut through the documented Release Please path; published tarball matches git tag **`v0.3.1`** (Actions publish job, 2026-04-17).
- [x] **SHIP-02**: README + ExDoc + `mix.exs` package metadata reference **`@version "0.3.1"`** / `@source_ref` for the shipped release.
- [x] **SHIP-03**: `mix verify.phase11`, `mix verify.workspace_clean`, and `mix verify.release_parity 0.3.1` ran on the release publish path in CI (post-publish steps green on merge to `main`).

### Relevance — hot apply (prefix: TUNE14)

Narrow implementation of the deferred hot path (research id **TUNE-V14-01**).

- [x] **TUNE14-01**: `Scrypath.Meilisearch.Settings.hot_apply/3` applies **only** `synonyms`, `stop_words`, and `typo_tolerance` to the **live** index via Meilisearch-supported partial update APIs; returns structured errors on unsupported keys or backend failure; `mix scrypath.settings.hot_apply`; curated live coverage in `mix verify.meilisearch_smoke` (Phase 25).
- [x] **TUNE14-02**: Guide + docs contract: when to prefer managed `reindex/2` vs `hot_apply/3`, and explicit non-goals (no ranking_rules hot apply in v1.4) — `guides/relevance-tuning.md`, `guides/operator-mix-tasks.md`, CHANGELOG (Phase 25).

### Operator observability (prefix: OPS14)

- [x] **OPS14-01**: `failed_sync_work/2` (or the documented operator entry point) exposes **rollup counts** grouped by `reason_class` so operators see pileup shape without ad-hoc scripting (Phase 26; gate **`mix verify.phase26`**).

## v1.5+ Requirements (Deferred)

Carried from research / backlog; not committed in v1.4.

### Relevance

- **TUNE-V15-01**: Per-query setting overrides (still incompatible with managed pipeline contract until designed).

### Faceting

- **FACET-V14-01**: Hierarchical / nested facet declarations.
- **FACET-V14-02**: First-class disjunctive facet counts (guide-only in v1.3).
- **FACET-V14-03**: `search_within_facet/4`.

### Multi-index

- **MULTI-V14-01** … **MULTI-V14-03**: Federation relevance normalization, custom weighting, `:all`-schema wildcard.

### Operator

- **OPS-V14-02**: `reason_class`-driven branching inside `reconcile_sync/2` — **out** until report-first discipline is revisited at milestone level.

## Out of Scope (v1.4)

| Feature | Reason |
|---------|--------|
| Second public backend | Locked non-goal until adoption pressure. |
| Vector / hybrid / semantic search | Locked non-goal. |
| Ranking rules / distinct / stop_words **beyond** the TUNE14-01 allow-list via `hot_apply` | Keeps hot path narrow and reviewable. |
| `OPS-V14-02` reconcile branching | Violates report-first operator discipline from v1.2/v1.3. |
| Postgres-native search as product surface | Product boundary. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SHIP-01 | Phase 24 | Complete |
| SHIP-02 | Phase 24 | Complete |
| SHIP-03 | Phase 24 | Complete |
| TUNE14-01 | Phase 25 | Complete |
| TUNE14-02 | Phase 25 | Complete |
| OPS14-01 | Phase 26 | Complete |

**Coverage:** v1.4 requirements: **6** — mapped: **6** — unmapped: **0**

| Phase | Requirements | Count |
|-------|----------------|-------|
| Phase 24 — Public Hex release & parity gates | SHIP-01..03 | 3 |
| Phase 25 — Settings hot apply (narrow) | TUNE14-01, TUNE14-02 | 2 |
| Phase 26 — Operator failure rollups | OPS14-01 | 1 |

---
*Requirements defined: 2026-04-17 — `/gsd-new-milestone` (research skipped; gsd-roadmapper inlined as maintainer-authored roadmap)*
