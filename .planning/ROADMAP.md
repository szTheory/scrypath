# Roadmap: Scrypath

## Milestones

- [x] `v1.0` shipped on 2026-04-16 — 7 phases, 25 plans, and the full Meilisearch-first v1 surface archived in [.planning/milestones/v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md)
- [x] `v1.1` shipped on 2026-04-16 — 3 phases, 9 plans, release hardening and launch-readiness evidence archived in [.planning/milestones/v1.1-ROADMAP.md](milestones/v1.1-ROADMAP.md)
- [x] `v1.2` shipped on 2026-04-17 — 7 phases, 13 plans, public release trust, operator visibility, and the first live public release proof archived in [.planning/milestones/v1.2-ROADMAP.md](milestones/v1.2-ROADMAP.md)
- [x] `v1.3` shipped on 2026-04-17 — 6 phases (18–23), 18 plans, Meilisearch-native search power (relevance, facets, multi-index), operator polish + drift recovery, release-parity gates, and v1.2 Nyquist validation closure — archived in [.planning/milestones/v1.3-ROADMAP.md](milestones/v1.3-ROADMAP.md) and [.planning/milestones/v1.3-REQUIREMENTS.md](milestones/v1.3-REQUIREMENTS.md)

## Active Milestone

**None** — v1.3 planning milestone is closed. Define the next cycle with `/gsd-new-milestone` (new `REQUIREMENTS.md` + `ROADMAP.md` will be created there).

## Phases (v1.3 archive summary)

<details>
<summary>✅ v1.3 — Phases 18–23 — SHIPPED 2026-04-17</summary>

- [x] Phase 18: Release-Parity Gate + Node 20 CI Cleanup — 7/7 plans
- [x] Phase 19: Relevance Tuning — 7/7 plans
- [x] Phase 20: Faceted Search + LiveView Guide — 4/4 plans
- [x] Phase 21: Multi-Index Search — 4/4 plans
- [x] Phase 22: Operator Polish + Drift Recovery Guide — 2/2 plans
- [x] Phase 23: v1.2 VALIDATION.md Closure — 1/1 plan

Full narrative, success criteria, and plan titles: `milestones/v1.3-ROADMAP.md`.

</details>

## Progress (v1.3)

| Phase | Milestone | Plans | Status | Completed |
|-------|-----------|-------|--------|-----------|
| 18–23 | v1.3 | see archive | Complete | 2026-04-17 |

## Backlog

- Additional backend support after the release contract and operator surface prove the common path against real Meilisearch adoption (locked non-goal through v1.3).
- Hot-apply escape hatch `Scrypath.Meilisearch.Settings.hot_apply/3` for synonyms/stop_words/typo_tolerance — v1.3 ships the stub returning `:hot_apply_disabled`; real implementation deferred to v1.4.
- Hierarchical / nested facet declarations (`categories.lvl0`), disjunctive facet counts as a first-class opt, and `search_within_facet/4` in-facet value search — deferred to v1.4.
- Cross-schema ranking normalization, custom weighting / boost parameters, and `:all`-schema wildcard via registry for `search_many/2` — deferred to v1.4.
- Failure-class rollup counts on `failed_sync_work/2` and `reason_class`-driven recovery action branching inside `reconcile_sync/2` — deferred to v1.4 (narrow-polish discipline holds for v1.3).
- Deeper drift/schema-diff operator tooling — reserved for v1.4 once v1.3 feature work produces real-world recovery scenarios.

---
*Last updated: 2026-04-17 — v1.3 milestone archived; awaiting next milestone definition*
