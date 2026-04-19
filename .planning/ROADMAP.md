# Roadmap: Scrypath

## Milestones

- [x] `v1.0` shipped on 2026-04-16 — 7 phases, 25 plans — [archive](milestones/v1.0-ROADMAP.md)
- [x] `v1.1` shipped on 2026-04-16 — 3 phases, 9 plans — [archive](milestones/v1.1-ROADMAP.md)
- [x] `v1.2` shipped on 2026-04-17 — 7 phases, 13 plans — [archive](milestones/v1.2-ROADMAP.md)
- [x] `v1.3` shipped on 2026-04-17 — 6 phases (18–23), 18 plans — [archive](milestones/v1.3-ROADMAP.md) · [requirements](milestones/v1.3-REQUIREMENTS.md)
- [x] **`v1.4` shipped on 2026-04-17** — 3 phases (24–26), 8 plans — [archive](milestones/v1.4-ROADMAP.md) · [requirements](milestones/v1.4-REQUIREMENTS.md)
- [x] **`v1.5` shipped in-repo** (2026-04-18) — 2 phases (27–28), 5 plans — [archive](milestones/v1.5-ROADMAP.md) · [requirements](milestones/v1.5-REQUIREMENTS.md) — *Operator drift and schema-diff tooling*
- [x] **`v1.6` shipped in-repo** (2026-04-19) — 7 phases (29–35), 7 plans — [archive](milestones/v1.6-ROADMAP.md) · [requirements](milestones/v1.6-REQUIREMENTS.md) · [audit](milestones/v1.6-MILESTONE-AUDIT.md) — *Adoption-grade integration and trust*

## Next milestone

**Post–v1.6** — No active numbered phase after **35** in this file. Open the next planning cycle with **`/gsd-new-milestone`** (fresh `REQUIREMENTS.md`, roadmap slice, and version target). Backlog product ideas remain under **§ Backlog** below.

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

**v1.6** archived 2026-04-19 — phases **29–35** shipped in-repo (adoption golden path, consumer proof depth, verification story, planning hygiene, doc contracts **33–35**). **Next:** **`/gsd-new-milestone`** when you are ready to define **v1.7+** scope. Summary: **`MILESTONES.md`**, **`milestones/v1.6-ROADMAP.md`**.

## Backlog (post–v1.6 candidates)

- Hierarchical facets, first-class disjunctive facet counts, `search_within_facet/4`.
- Multi-index federation scoring / weighting / `:all` wildcard.
- Per-query relevance overrides once pipeline semantics are designed.

---
*Last updated: 2026-04-19 — **v1.6** milestone archived; post–v1.6 planning via `/gsd-new-milestone`*
