# Roadmap: Scrypath

## Milestones

- [x] `v1.0` shipped on 2026-04-16 — 7 phases, 25 plans — [archive](milestones/v1.0-ROADMAP.md)
- [x] `v1.1` shipped on 2026-04-16 — 3 phases, 9 plans — [archive](milestones/v1.1-ROADMAP.md)
- [x] `v1.2` shipped on 2026-04-17 — 7 phases, 13 plans — [archive](milestones/v1.2-ROADMAP.md)
- [x] `v1.3` shipped on 2026-04-17 — 6 phases (18–23), 18 plans — [archive](milestones/v1.3-ROADMAP.md) · [requirements](milestones/v1.3-REQUIREMENTS.md)
- [x] **`v1.4` shipped on 2026-04-17** — 3 phases (24–26), 8 plans — [requirements](REQUIREMENTS.md)

## Active Milestone

### v1.4 Public package parity & operator depth

**Goal:** Publish the v1.3-era library surface on Hex with trusted release gates, ship a **narrow** Meilisearch `hot_apply` path for synonym/stop-word/typo settings, and give operators rollup visibility on failed sync work by `reason_class` — without widening non-goals.

**Non-goals:** No second backend, no vector search, no `reconcile_sync/2` behavior forks (`OPS-V14-02`), no per-query settings overrides, no hierarchical facets in v1.4.

## Phases

- [x] **Phase 24: Public Hex release & parity gates** — 2026-04-17 — **Hex `scrypath 0.3.1`**; Release Please + publish workflow + `release_parity` green on release ref (SHIP-01..03).
- [x] **Phase 25: Settings hot apply (narrow)** — 2026-04-17 — TUNE14-01 `hot_apply/3` + Mix task + integration; TUNE14-02 guides + CHANGELOG (verify `25-VERIFICATION.md`).
- [x] **Phase 26: Operator failure rollups** — 2026-04-17 — OPS14-01: `mix verify.phase26` + `26-VERIFICATION.md` / `26-UAT.md` (automated); rollups on `failed_sync_work/2`, reconcile, Mix/CLI.

<details>
<summary>✅ v1.3 — Phases 18–23 — SHIPPED 2026-04-17</summary>

- [x] Phase 18: Release-Parity Gate + Node 20 CI Cleanup — 7/7 plans
- [x] Phase 19: Relevance Tuning — 7/7 plans
- [x] Phase 20: Faceted Search + LiveView Guide — 4/4 plans
- [x] Phase 21: Multi-Index Search — 4/4 plans
- [x] Phase 22: Operator Polish + Drift Recovery Guide — 2/2 plans
- [x] Phase 23: v1.2 VALIDATION.md Closure — 1/1 plan

Details: `milestones/v1.3-ROADMAP.md`.

</details>

## Phase details (v1.4)

### Phase 24: Public Hex release & parity gates

**Goal:** Maintainers cut the next Hex release so adopters receive facets, relevance tuning, multi-index search, and operator polish through the normal package manager — with the same mechanical trust chain as `0.3.0`.

**Depends on:** Nothing (first v1.4 slice).

**Requirements:** SHIP-01, SHIP-02, SHIP-03

**Success criteria:**

1. A release PR or Release Please flow produces a tagged semver whose tarball matches `main` for packaged paths at the time of publish.
2. Docs and README read correctly on HexDocs for that version (version macro, links, extras list).
3. `mix verify.phase11`, `mix verify.workspace_clean`, and `mix verify.release_parity <new version>` succeed on the release pipeline inputs defined in `docs/releasing.md`.

**Plans:** `24-01` (Release Please pre-1.0 bumps + UAT-09), `24-02` (post-publish `release_parity` on publish workflows), `24-03` (releasing.md + README + UAT-06 releasing contract).

### Phase 25: Settings hot apply (narrow)

**Goal:** Operators can patch **only** synonym / stop-word / typo-tolerance settings on a live Meilisearch index when a full reindex is too heavy — with explicit errors for unsupported keys.

**Depends on:** Phase 24 (published contract baseline).

**Requirements:** TUNE14-01, TUNE14-02

**Success criteria:**

1. `hot_apply/3` succeeds for the allow-listed key subset against a real Meilisearch in integration tests.
2. Unsupported keys return `{:error, _}` without mutating remote settings.
3. Guide + docs contract describe hot vs managed reindex tradeoffs.

**Plans:** `25-01` (core `hot_apply/3` + unit tests + telemetry), `25-02` (Mix task + integration), `25-03` (TUNE14-02 docs + CHANGELOG).

### Phase 26: Operator failure rollups

**Goal:** Operators see **how many** failures exist per `reason_class` (and related keys) when inspecting failed sync work — no new recovery verb, additive metadata or function surface only.

**Depends on:** Phase 24 (release clarity); soft dependency on Phase 22 artifacts remaining stable.

**Requirements:** OPS14-01

**Success criteria:**

1. Documented API or Mix output exposes per-`reason_class` counts consistent with underlying failed-work sources.
2. Tests lock the shape and prevent silent omission of unknown classes into a misleading bucket.

**Plans:** `26-01` (rollup structs + `reason_class_counts/1` + `failed_sync_work/2` opt-in + tests), `26-02` (`%Reconcile{}` field + Mix/CLI + guides + CHANGELOG + docs contract).

## Progress

| Phase | Milestone | Plans | Status | Completed |
|-------|-----------|-------|--------|-----------|
| 24. Public Hex release & parity gates | v1.4 | 3/3 | Complete | 2026-04-17 |
| 25. Settings hot apply (narrow) | v1.4 | 3/3 | Complete (branch) | 2026-04-17 |
| 26. Operator failure rollups | v1.4 | 2/2 | Complete | 2026-04-17 |

## Backlog (post–v1.4 candidates)

- Hierarchical facets, first-class disjunctive facet counts, `search_within_facet/4`.
- Multi-index federation scoring / weighting / `:all` wildcard.
- Deeper drift/schema-diff operator tooling.
- Per-query relevance overrides once pipeline semantics are designed.

---
*Last updated: 2026-04-17 — Hex **0.3.1** published; Phase 24 closed*
