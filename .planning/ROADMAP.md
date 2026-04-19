# Roadmap: Scrypath

## Milestones

- [x] `v1.0` shipped on 2026-04-16 — 7 phases, 25 plans — [archive](milestones/v1.0-ROADMAP.md)
- [x] `v1.1` shipped on 2026-04-16 — 3 phases, 9 plans — [archive](milestones/v1.1-ROADMAP.md)
- [x] `v1.2` shipped on 2026-04-17 — 7 phases, 13 plans — [archive](milestones/v1.2-ROADMAP.md)
- [x] `v1.3` shipped on 2026-04-17 — 6 phases (18–23), 18 plans — [archive](milestones/v1.3-ROADMAP.md) · [requirements](milestones/v1.3-REQUIREMENTS.md)
- [x] **`v1.4` shipped on 2026-04-17** — 3 phases (24–26), 8 plans — [archive](milestones/v1.4-ROADMAP.md) · [requirements](milestones/v1.4-REQUIREMENTS.md)
- [x] **`v1.5` shipped in-repo** (2026-04-18) — 2 phases (27–28), 5 plans — [archive](milestones/v1.5-ROADMAP.md) · [requirements](milestones/v1.5-REQUIREMENTS.md) — *Operator drift and schema-diff tooling*
- [ ] **`v1.6` in progress** — **7** phases (29–35): **29–34** complete in-repo (phase **34** gap closure 2026-04-19); **35** closes remaining [milestone audit](v1.6-MILESTONE-AUDIT.md) flow gap — [requirements](REQUIREMENTS.md) — *Adoption-grade integration and trust*

## Next milestone

**v1.6 — Adoption-grade integration and trust** — phases **29–35** · [REQUIREMENTS.md](REQUIREMENTS.md)

| # | Phase | Goal | Requirements | Success criteria |
|---|-------|------|--------------|------------------|
| 29 | Golden path and adoption documentation | One install→search golden path; sync-mode guidance; upgrade/versioning clarity | ADPT-01, ADPT-02, ADPT-03 | 3 (see REQUIREMENTS.md) |
| 30 | Consumer example and smoke depth | Second consumer-shaped proof; example smoke runbook | EXAM-01, EXAM-02 | 2 |
| 31 | Verification story for adopters | Verify tasks ↔ guarantees; default CI vs integration | VRFY-01, VRFY-02 | 2 |
| 32 | Planning and state hygiene | Triage v1.5 deferred STATE rows | AUDT-01 | 1 |
| 33 | Example smoke paths and doc contracts | Root-facing docs and tests agree on **cwd** for `scripts/smoke.sh` and example integration smoke; extend `docs_contract_test` for implied paths where appropriate | ADPT-01, EXAM-02, VRFY-02, AUDT-01 | 2 (see REQUIREMENTS.md) |
| 34 | Golden path, README, and CI alignment | One canonical first-schema story (README ↔ golden path); golden-path narrative matches **`phoenix-example-integration`** on PRs | ADPT-01, ADPT-02, ADPT-03, VRFY-01 | 2 (see REQUIREMENTS.md) |
| 35 | Sync guide lifecycle parity | README “authority” claims for sync lifecycle match depth in **`guides/sync-modes-and-visibility.md`** (or README narrows the claim) | ADPT-02, ADPT-03 | 1 (see REQUIREMENTS.md) |

**Gap closure (33–35):** Addresses **`v1.6-MILESTONE-AUDIT.md`** `gaps.integration` / `gaps.flows`. Optional later: Nyquist **`VALIDATION.md`** for phases **30–31** and plan **`SUMMARY`** backfill — **deferred** until after these doc fixes unless policy hard-requires the three-source matrix.

## Phases (history)

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

**Active milestone:** **v1.6** — **Phases 29–34** verified in-repo (phase **34**: README ↔ golden-path schema + **`phoenix-example-integration`** narrative, 2026-04-19). **Phase 35** (sync guide parity) is **next**; then **`/gsd-audit-milestone v1.6`** before milestone complete. Shipped **v1.5** tables: **`milestones/v1.5-ROADMAP.md`**.

## Backlog (post–v1.5 candidates)

- Hierarchical facets, first-class disjunctive facet counts, `search_within_facet/4`.
- Multi-index federation scoring / weighting / `:all` wildcard.
- Per-query relevance overrides once pipeline semantics are designed.

---
*Last updated: 2026-04-19 — **v1.6** phase **34** complete; **35** remaining gap closure*
