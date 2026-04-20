# Roadmap: Scrypath

## Milestones

- [x] `v1.0` shipped on 2026-04-16 — 7 phases, 25 plans — [archive](milestones/v1.0-ROADMAP.md)
- [x] `v1.1` shipped on 2026-04-16 — 3 phases, 9 plans — [archive](milestones/v1.1-ROADMAP.md)
- [x] `v1.2` shipped on 2026-04-17 — 7 phases, 13 plans — [archive](milestones/v1.2-ROADMAP.md)
- [x] `v1.3` shipped on 2026-04-17 — 6 phases (18–23), 18 plans — [archive](milestones/v1.3-ROADMAP.md) · [requirements](milestones/v1.3-REQUIREMENTS.md)
- [x] **`v1.4` shipped on 2026-04-17** — 3 phases (24–26), 8 plans — [archive](milestones/v1.4-ROADMAP.md) · [requirements](milestones/v1.4-REQUIREMENTS.md)
- [x] **`v1.5` shipped in-repo** (2026-04-18) — 2 phases (27–28), 5 plans — [archive](milestones/v1.5-ROADMAP.md) · [requirements](milestones/v1.5-REQUIREMENTS.md) — *Operator drift and schema-diff tooling*
- [x] **`v1.6` shipped in-repo** (2026-04-19) — 7 phases (29–35), 7 plans — [archive](milestones/v1.6-ROADMAP.md) · [requirements](milestones/v1.6-REQUIREMENTS.md) · [audit](milestones/v1.6-MILESTONE-AUDIT.md) — *Adoption-grade integration and trust*
- [x] **`v1.7` shipped in-repo** (2026-04-20) — 3 phases (36–38), 7 plans — [archive](milestones/v1.7-ROADMAP.md) · [requirements](milestones/v1.7-REQUIREMENTS.md) · [audit](milestones/v1.7-MILESTONE-AUDIT.md) — *Facet depth and catalog search UX*
- [x] **`v1.8` shipped in-repo** (2026-04-20) — *Multi-index federation* — phases **39–41**, **6** plans — [archive](milestones/v1.8-ROADMAP.md) · [requirements](milestones/v1.8-REQUIREMENTS.md) · [audit](milestones/v1.8-MILESTONE-AUDIT.md)
- [ ] **`v1.9` active** (2026-04-20) — *Per-query relevance & tuning pipeline* — phases **42–43** — [requirements](REQUIREMENTS.md)

## Next milestone

**v1.9 — Per-query relevance & tuning pipeline** is **open** (**phases 42–43**). See **`.planning/REQUIREMENTS.md`** for **`TUNE-PIPE-*`** and **`TUNE-PQ-*`** (the latter implements the v1.7 backlog label **`TUNE-01`**). **`OPSUI-01`** remains in **Backlog** below.

## Phases (v1.9 — active)

| # | Phase | Goal | Requirements | Success criteria (summary) |
|---|-------|------|----------------|----------------------------|
| **42** ✅ | **Per-query tuning pipeline spec** | Publish the authoritative **`TUNE-PIPE-*`** specification: precedence vs defaults, Meilisearch mapping, non-goals, errors/telemetry expectations, and an implementation gate checklist. | **TUNE-PIPE-01** … **TUNE-PIPE-04** | **Shipped 2026-04-20** — **`guides/per-query-tuning-pipeline.md`**, ExDoc + README/guides cross-links, **`docs_contract_test`** anchors, **`Scrypath.search/3`** / **`search_many/2`** `@doc`. |
| **43** ✅ | **Per-query relevance runtime** | Ship **`TUNE-PQ-*`** per locked spec (**implements v1.7 backlog `TUNE-01`**). | **TUNE-PQ-01** … **TUNE-PQ-03** | **Shipped 2026-04-20** — `:per_query` allowlist + `%Query{}` + Meilisearch projection + `search_many` inner merge + telemetry + **`mix verify.phase43`** + public `@doc`. |

## Phases (history)

<details>
<summary>✅ v1.8 — Phases 39–41 — SHIPPED 2026-04-20 · in-repo · Hex <code>scrypath 0.3.3</code></summary>

- [x] **Phase 39: Federation scoring & weights** — **`federation_weight:`**, Meilisearch **`federationOptions.weight`**, **`merge_hit_order`** / **`Scrypath.MultiSearchResult.merge_projection/1`**, guide **`## Federation weights`**, tests — **FED-01**.
- [x] **Phase 40: `:all` expansion** — **`Scrypath.MultiSearch.AllExpansion`**, **`global_schemas:`** / **`:scrypath_global_search_schemas`**, post-expansion **`max_schemas`**, explicit **`{:invalid_options, {:all_expansion, _}}`** — **FED-02**.
- [x] **Phase 41: Federation docs & contracts** — **`guides/multi-index-search.md`**, README / golden-path pointers, **`docs_contract_test.exs`**, **`mix verify.phase41`** in CI — **FED-03**.

Full detail: [milestones/v1.8-ROADMAP.md](milestones/v1.8-ROADMAP.md).

</details>

<details>
<summary>✅ v1.7 — Phases 36–38 — SHIPPED 2026-04-20 · in-repo · Hex <code>scrypath 0.3.3</code></summary>

- [x] **Phase 36: Hierarchical facets** — Declarative nested facet paths, Meilisearch settings alignment, stable dotted facet keys in **`%SearchResult{}`**, **`mix verify.phase36`**; **FACET-01**.
- [x] **Phase 37: Disjunctive facet counts** — **`Scrypath.Facets.Disjunctive.merge_distributions/2`**, guide **`## Disjunctive facet counts`**, **`mix verify.phase37`** + regression **`mix verify.phase36`**; **FACET-02**.
- [x] **Phase 38: Search within facet + docs** — **`search_within_facet/4`**, telemetry metadata, LiveView guide sections for scoped search + composition, **`mix verify.phase38`**, README / module-doc pointers; **FACET-03**, **FACET-04**.

Full detail: [milestones/v1.7-ROADMAP.md](milestones/v1.7-ROADMAP.md).

</details>

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

**v1.9 (2026-04-20):** Milestone opened — **`TUNE-PIPE-01`..`TUNE-PIPE-04`** in **Phase 42** (**✅ complete 2026-04-20**); **`TUNE-PQ-01`..`TUNE-PQ-03`** in **Phase 43** (next). Prior **`FED-01`..`FED-03`** work is archived under **`milestones/v1.8-REQUIREMENTS.md`**.

## Backlog (beyond v1.9)

- **OPSUI-01 — Operator dashboard (LiveView)** — optional product surface (example app or separate package) over existing `Scrypath.*` visibility, telemetry, and **federation-shaped** `search_many/2` results; **follow v1.8** so the UI can represent cross-index ordering and expansion honestly. See also [`docs/search-backend-sre.md`](../docs/search-backend-sre.md).

---
*Last updated: 2026-04-20 — **v1.9** opened (phases **42–43**); **`TUNE-PIPE-*` / `TUNE-PQ-*`** in **`.planning/REQUIREMENTS.md`***
