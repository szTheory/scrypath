# Milestones

## v1.3 Search Power That Phoenix Teams Reach For (Shipped: 2026-04-17)

**Phases completed:** 6 phases (18–23), 18 plans

**Key accomplishments:**

- Release-parity mechanization: `mix verify.workspace_clean`, `mix verify.release_parity`, Node pin hygiene, and scheduled published-release drift checks (Phase 18)
- Declarative relevance tuning (synonyms, typo tolerance, ranking rules, distinct, stop words) with managed reindex pipeline, drift read-back, and `mix scrypath.settings.{diff,read}` (Phase 19)
- Faceted search on `Scrypath.search/3` with `%SearchResult.Facets{}`, validated facet filters, and a Phoenix LiveView guide (Phase 20)
- Federated `Scrypath.search_many/2` with native `/multi-search`, partial-failure envelope, telemetry, and multi-index guide (Phase 21)
- Operator polish on `%FailedWork{}` (`reason_class`, attempts, telemetry) plus `guides/drift-recovery.md` (Phase 22)
- v1.2 Nyquist validation closure: evidence under `milestones/v1.2/` and `v1.2-MILESTONE-AUDIT.md` → `compliant` (Phase 23)

**Known deferred items at close:** 2 quick-task stubs referenced by `audit-open` no longer exist on disk — recorded in `STATE.md` §Deferred Items.

**Archives:** `milestones/v1.3-ROADMAP.md`, `milestones/v1.3-REQUIREMENTS.md`

---

## v1.4 Public package parity & operator depth (Shipped + archived: 2026-04-17)

**Phases completed:** 3 phases (24–26), 8 plans

**Hex:** **`scrypath 0.3.1`** — https://hex.pm/packages/scrypath/0.3.1 — Release Please PR **#5**, Actions publish run **24589910084** (`release_publish` + `release_parity` green).

**Key accomplishments:** Release Please + post-publish parity on both publish workflows; README / `docs/releasing.md` / contract tests aligned; **`hot_apply/3`** + `mix scrypath.settings.hot_apply` + integration smoke; **`failed_sync_work/2`** rollups + `%Reconcile{}` + **`mix verify.phase26`**.

**Known deferred items at close:** 3 `audit-open` rows acknowledged (2 missing quick_task stubs + Phase 18 UAT noise) — see **`STATE.md` §Deferred Items**.

**Archives:** `milestones/v1.4-ROADMAP.md`, `milestones/v1.4-REQUIREMENTS.md`, `milestones/v1.4-MILESTONE-AUDIT.md` · **Git tag:** `v1.4` (planning milestone marker; package release tag is **`scrypath-v0.3.1`**).

---

## v1.2 Public Release Trust and Operator Visibility (Shipped: 2026-04-17)

**Phases completed:** 7 phases, 13 plans, 22 tasks

**Key accomplishments:**

- Version-anchored Hex package links and a canonical `mix verify.phase11` gate for Release Please, manifest, and local package alignment
- Clean-consumer compile proof and maintainer recovery runbooks enforced through the Phase 11 release gate
- Scrypath-owned task and result seam contracts for Meilisearch and Oban normalization without runtime rewiring
- Seam-owned Meilisearch and Oban operation references wired through sync while preserving the public Meilisearch-first sync contract
- Seam-owned backfill and reindex workflow references with the Meilisearch-first public boundary locked in docs and telemetry
- Root-level sync status reporting with Scrypath-owned backend and queue visibility across manual, inline, and Oban workflows
- Canonical Phase 13 operator verification evidence plus roadmap and requirement repairs grounded in a fresh `mix verify.phase13 --skip-integration` pass
- Canonical Phase 14 verification evidence, repaired milestone bookkeeping, and plan-index aliases grounded in a fresh `mix verify.phase14` pass
- Shipped the first real public Scrypath release as `0.3.0`, then verified the live GitHub release, Hex package, and HexDocs path

---

| Version | Date | Phases | Plans | Status | Notes |
|---------|------|--------|-------|--------|-------|
| `v1.0` | 2026-04-16 | 7 | 25 | Archived | Ecto-native Meilisearch-first indexing core, search, Oban, reindex, Phoenix docs, and repaired verification history. |
| `v1.1` | 2026-04-16 | 3 | 9 | Archived | Release hardening, docs-safety fixes, and launch-readiness evidence chain archived in `.planning/milestones/v1.1-ROADMAP.md`. |
| `v1.2` | 2026-04-17 | 7 | 13 | Archived | Public release trust, operator visibility, internal operations seam, and the first live public release proof archived in `.planning/milestones/v1.2-ROADMAP.md`. |
| `v1.3` | 2026-04-17 | 6 | 18 | Archived | Search power (relevance, facets, multi-index), operator polish + drift recovery, release-parity gates, v1.2 validation closure — `v1.3-ROADMAP.md` + `v1.3-REQUIREMENTS.md`. |
| `v1.4` | 2026-04-17 | 3 | 8 | Archived | Hex **0.3.1**; `v1.4-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`; milestone tag **`v1.4`**. |
