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
- [x] **`v1.9` shipped in-repo** (2026-04-20) — *Per-query relevance & tuning pipeline* — phases **42–43**, **5** plans — [archive](milestones/v1.9-ROADMAP.md) · [requirements](milestones/v1.9-REQUIREMENTS.md) · [audit](milestones/v1.9-MILESTONE-AUDIT.md)
- [ ] **`v1.10` in progress** (opened 2026-04-20) — *Operator admin UI (OPSUI)* — phases **44–47** — [requirements](REQUIREMENTS.md) · [research summary](research/SUMMARY.md)

## Current milestone: v1.10 — Operator admin UI (OPSUI)

**Goal:** Ship an optional **Phoenix LiveView** operator admin (**outside** the core Hex package) prioritized by **personas / jobs-to-be-done**, **conventional** Phoenix patterns, and **least surprise**—with **struct-faithful** views over **`Scrypath.*`** visibility, **telemetry discipline** ([`docs/search-backend-sre.md`](../docs/search-backend-sre.md)), and **federation-shaped `search_many/2`** results.

| Phase | Name | Requirements | Success criteria (observable) |
|-------|------|--------------|-------------------------------|
| **44** | **OPSUI foundations** | **OPSUI-09**, **OPSUI-06**, **OPSUI-07**, **OPSUI-08** | OPSUI app/package boots from documented instructions; **persona/JTBD** doc exists and **primary nav** matches it; **LiveView layout** follows boring Phoenix conventions; **security model** documented in README or operator doc (dev vs prod). |
| **45** | **Posture & failure triage** | **OPSUI-01**, **OPSUI-02**, **OPSUI-03** | **Landing** shows real per-schema/index posture from library APIs; **failed sync work** view matches **`failed_sync_work/2`** rollups; **sync/drift** screens are read-only and link to existing Mix/docs paths for actions. |
| **46** | **Search & federation honesty** | **OPSUI-04**, **OPSUI-05** | **Bounded** search playground with explicit non-prod warnings; **multi-search** inspector shows **merge order**, **weights**, **partial failures**, and **`:all` expansion** consistent with shipped guides and structs—no misleading “single merged index” illusion. |
| **47** | **Verification & hardening** | **OPSUI-10** | **CI** runs a maintainer verification slice for OPSUI (for example **`LiveViewTest`** or thin smoke); critical copy/structure pinned so federation and failure views cannot silently drift. |

### Phase 44: OPSUI foundations

**Requirements:** OPSUI-09, OPSUI-06, OPSUI-07, OPSUI-08

**Goal:** OPSUI app/package boots from documented instructions; persona/JTBD doc exists and primary nav matches it; LiveView layout follows boring Phoenix conventions; security model documented in README or operator doc (dev vs prod).

### Phase 45: Posture & failure triage

**Requirements:** OPSUI-01, OPSUI-02, OPSUI-03

**Goal:** Landing shows real per-schema/index posture from library APIs; failed sync work view matches `failed_sync_work/2` rollups; sync/drift screens are read-only and link to existing Mix/docs paths for actions.

### Phase 46: Search & federation honesty

**Requirements:** OPSUI-04, OPSUI-05

**Goal:** Bounded search playground with explicit non-prod warnings; multi-search inspector shows merge order, weights, partial failures, and `:all` expansion consistent with shipped guides and structs.

### Phase 47: Verification & hardening

**Requirements:** OPSUI-10

**Goal:** CI runs a maintainer verification slice for OPSUI (for example `LiveViewTest` or thin smoke); critical copy/structure pinned so federation and failure views cannot silently drift.

## Phases (history)

<details>
<summary>✅ v1.9 — Phases 42–43 — SHIPPED 2026-04-20 · in-repo · Hex <code>scrypath 0.3.3</code></summary>

- [x] **Phase 42: Per-query tuning pipeline spec** — **`guides/per-query-tuning-pipeline.md`**, precedence vs defaults, Meilisearch mapping, non-goals, implementation checklist, **`docs_contract_test`** anchors, **`Scrypath.search/3`** / **`search_many/2`** `@doc` — **TUNE-PIPE-01**..**TUNE-PIPE-04**.
- [x] **Phase 43: Per-query relevance runtime** — Allowlisted **`:per_query`**, **`%Query{}`**, Meilisearch projection (ranking score knobs), **`search_many/2`** inner merge, telemetry metadata, **`mix verify.phase43`** in CI — **TUNE-PQ-01**..**TUNE-PQ-03** / backlog **`TUNE-01`**.

Full detail: [milestones/v1.9-ROADMAP.md](milestones/v1.9-ROADMAP.md).

</details>

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

**`v1.10` active** — phases **44–47** mapped to **`OPSUI-01`..`OPSUI-10`** in **[REQUIREMENTS.md](REQUIREMENTS.md)**; **`.planning/phases/`** cleared for this milestone. Prior **`v1.9`** archived **2026-04-20** (see **`milestones/v1.9-REQUIREMENTS.md`**).

**Next:** **`/gsd-discuss-phase 44`** (or **`/gsd-plan-phase 44`**) to start **OPSUI foundations**.

## Backlog (post–v1.10 ideas)

- **`OPSUI-FUT-*`** — saved operator playbooks, deeper Meilisearch vendor-style panels — see **[REQUIREMENTS.md](REQUIREMENTS.md)** § v2+ until promoted.
- **Core library features** — continue to follow **`.planning/PROJECT.md`** *Out of Scope* until a future milestone explicitly widens the contract.

---
*Last updated: 2026-04-20 — **`v1.10` OPSUI** milestone opened (phases **44–47**)*
