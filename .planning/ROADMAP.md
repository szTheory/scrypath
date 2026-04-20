# Roadmap: Scrypath

## Milestones

- [x] `v1.0` shipped on 2026-04-16 — 7 phases, 25 plans — [archive](milestones/v1.0-ROADMAP.md)
- [x] `v1.1` shipped on 2026-04-16 — 3 phases, 9 plans — [archive](milestones/v1.1-ROADMAP.md)
- [x] `v1.2` shipped on 2026-04-17 — 7 phases, 13 plans — [archive](milestones/v1.2-ROADMAP.md)
- [x] `v1.3` shipped on 2026-04-17 — 6 phases (18–23), 18 plans — [archive](milestones/v1.3-ROADMAP.md) · [requirements](milestones/v1.3-REQUIREMENTS.md)
- [x] **`v1.4` shipped on 2026-04-17** — 3 phases (24–26), 8 plans — [archive](milestones/v1.4-ROADMAP.md) · [requirements](milestones/v1.4-REQUIREMENTS.md)
- [x] **`v1.5` shipped in-repo** (2026-04-18) — 2 phases (27–28), 5 plans — [archive](milestones/v1.5-ROADMAP.md) · [requirements](milestones/v1.5-REQUIREMENTS.md) — *Operator drift and schema-diff tooling*
- [x] **`v1.6` shipped in-repo** (2026-04-19) — 7 phases (29–35), 7 plans — [archive](milestones/v1.6-ROADMAP.md) · [requirements](milestones/v1.6-REQUIREMENTS.md) · [audit](milestones/v1.6-MILESTONE-AUDIT.md) — *Adoption-grade integration and trust*
- [ ] **`v1.7` in progress** — 3 phases (36–38) — [requirements](REQUIREMENTS.md) — *Facet depth and catalog search UX*

## Next milestone

**v1.7 — Facet depth and catalog search UX** — phases **36–38** · [REQUIREMENTS.md](REQUIREMENTS.md)

| # | Phase | Goal | Requirements | Success criteria |
|---|-------|------|--------------|------------------|
| 36 | Hierarchical facets | Nested facet paths are declarative, applied to Meilisearch settings where supported, and reflected in search results with stable key/count semantics | FACET-01 | 1. Example schema + search demonstrates hierarchical facet keys end-to-end in integration tests. 2. Public docs describe supported shapes and Meilisearch limits. 3. No regression in existing non-hierarchical facet flows covered by CI. |
| 37 | Disjunctive facet counts | OR-style facet selection and facet counts are defined, implemented, and test-locked | FACET-02 | 1. Contract tests encode disjunctive vs conjunctive count behavior. 2. Edge cases (empty selection, single bucket) documented. 3. Operator-visible behavior matches docs for at least one reference scenario. |
| 38 | Search within facet + docs | `search_within_facet/4` (or approved name) ships with consistent filter composition; guides and `docs_contract_test` cover new APIs | FACET-03, FACET-04 | 1. Public API + typespecs merged with filter composition rules consistent with `search/3`. 2. Integration test covers scoped search within a facet bucket. 3. Guide or doc section + `docs_contract_test.exs` anchors updated. 4. README/ExDoc pointers updated where facet depth is discoverable. |

## Phases (history)

<details>
<summary>✅ v1.6 — Phases 29–35 — SHIPPED 2026-04-19 · in-repo · Hex <code>scrypath 0.3.3</code></summary>

- [x] **Phase 29: Golden path and adoption documentation** — `guides/golden-path.md`, README adoption wayfinding, sync-mode authority, versioning cross-links; ADPT-01..03.
- [x] **Phase 30: Consumer example and smoke depth** — Oban-shaped integration proof, example smoke runbook / env / CI mapping; EXAM-01..02.
- [x] **Phase 31: Verification story for adopters** — CONTRIBUTING verify matrix ↔ guarantees, default vs integration CI story; VRFY-01..02.
- [x] **Phase 32: Planning and state hygiene** — v1.5 deferred `STATE.md` rows triaged; AUDT-01.
- [x] **Phase 33: Example smoke paths and doc contracts** — Root vs example `smoke.sh` cwd, `docs_contract_test.exs`; ADPT-01, EXAM-02, VRFY-02, AUDT-01.
- [x] **Phase 34: Golden path, README, and CI alignment** — Canonical first-schema story, `phoenix-example-integration` parity; ADPT-01..03, VRFY-01.
- [x] **Phase 35: Sync guide lifecycle parity** — README authority ↔ `guides/sync-modes-and-visibility.md` operator lifecycle; ADPT-02..03.

Full detail: [milestones/v1.6-ROADMAP.md](milestones/v1.6-ROADMAP.md).

</details>

<details>
<summary>✅ v1.5 — Phases 27–28 — SHIPPED 2026-04-18 · in-repo · Hex <code>scrypath 0.3.3</code></summary>

- [x] **Phase 27: Schema–index drift report (read-only)** — `Scrypath.index_contract_drift/2`, `IndexContractDrift.Report`, optional reconcile attachment; DRIFT15-01..02, OPS15-01.
- [x] **Phase 28: Operator CLI, docs, and verify gate** — `mix scrypath.index.contract_drift`, drift-recovery + operator-support refresh, **`mix verify.phase28`**; OPS15-02..04.

Full detail: [milestones/v1.5-ROADMAP.md](milestones/v1.5-ROADMAP.md).

</details>

<details>
<summary>✅ v1.4 — Phases 24–26 — SHIPPED 2026-04-17 · Hex <code>scrypath 0.3.1</code></summary>

- [x] **Phase 24: Public Hex release & parity gates** — Release Please, publish + post-publish verify gates, README/docs contract (SHIP-01..03).
- [x] **Phase 25: Settings hot apply (narrow)** — `hot_apply/3`, `mix scrypath.settings.hot_apply`, guides + smoke CI.
- [x] **Phase 26: Operator failure rollups** — `failed_sync_work/2` rollups, `%Reconcile{}`, `mix verify.phase26`.

Full detail: [milestones/v1.4-ROADMAP.md](milestones/v1.4-ROADMAP.md).

</details>

<details>
<summary>✅ v1.3 — Phases 18–23 — SHIPPED 2026-04-17</summary>

- [x] Phase 18: Release-Parity Gate + Node 20 CI Cleanup — 7/7 plans
- [x] Phase 19: Relevance Tuning — 7/7 plans
- [x] Phase 20: Faceted Search + LiveView Guide — 4/4 plans
- [x] Phase 21: Multi-Index Search — 4/4 plans
- [x] Phase 22: Operator Polish + Drift Recovery Guide — 2/2 plans
- [x] Phase 23: v1.2 VALIDATION.md Closure — 1/1 plan

Details: [milestones/v1.3-ROADMAP.md](milestones/v1.3-ROADMAP.md).

</details>

## Progress

**v1.7** opened 2026-04-19 — **facet depth** track: phases **36–38** defined (hierarchical facets → disjunctive counts → search-within-facet + docs/contracts). **v1.6** remains archived (phases **29–35**). **Next:** **`/gsd-discuss-phase 36`** (or **`/gsd-plan-phase 36`**).

## Backlog (post–v1.7 candidates)

- Multi-index federation scoring / weighting / `:all` wildcard (`MULTI-*` in [REQUIREMENTS.md](REQUIREMENTS.md)).
- Per-query relevance overrides — **blocked** on design milestone **`TUNE-PIPE-01`** (pipeline semantics spec) before implementation (`TUNE-01`).

---
*Last updated: 2026-04-19 — **v1.7** milestone opened (phases **36–38**); backlog trimmed to post–facet items*
