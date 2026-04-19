# Scrypath

## What This Is

Scrypath is an open-source Elixir library for declarative, Ecto-native search indexing and search orchestration. It helps Phoenix and Ecto teams add search to existing schemas with a small amount of code while handling synchronization, reindexing, and operational workflows in a way that feels native to the Elixir ecosystem.

## Core Value

Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## Current Milestone: v1.6 Adoption-grade integration and trust

**Goal:** Make Scrypath easier to adopt and justify in production by strengthening real-Meilisearch integration proof, consumer-shaped examples, and documentation for the sync paths teams actually run.

**Target features:**

- Golden-path documentation from install through first successful search, with explicit inline vs Oban vs manual sync tradeoffs.
- Deeper consumer-shaped proof (example app and/or smoke) for at least one additional realistic scenario beyond the current Phoenix smoke.
- Maintainer verify tasks and CI documented in adopter-relevant terms so regressions are obvious before Hex.
- Triage of v1.5-close deferred planning items in `STATE.md` (resolve, re-file, or explicitly defer with reason).

## Requirements

### Validated

- [x] Schema metadata declarations, projection, runtime reflection, and the internal backend seam validated in v1.0.
- [x] Meilisearch-backed sync for insert, update, delete, inline, manual, and Oban-backed workflows validated in v1.0.
- [x] Common search, validated filter/sort/page handling, raw-hit access, and explicit hydration validated in v1.0.
- [x] Backfill, managed reindex, settings application, and recovery guidance validated in v1.0.
- [x] Phoenix docs, examples, release automation, and package trust signals validated in v1.0.
- [x] Launch-readiness hardening for Meilisearch edge cases, copied Phoenix docs safety, and milestone-close release evidence validated in v1.1.
- [x] The first real public release path, operator visibility surface, Mix task ergonomics, and the internal operations seam validated in v1.2.
- [x] Meilisearch-native search depth for growth-stage Phoenix teams — relevance tuning, faceted search, multi-index `search_many/2`, plus operator polish and drift recovery guidance — validated in planning milestone **v1.3** (2026-04-17).
- [x] Release-parity gates (`verify.workspace_clean`, `verify.release_parity`) and CI runtime hygiene (Node pin uplift) validated in v1.3.
- [x] v1.2 Nyquist validation debt (phases 13–15 evidence) closed in v1.3.
- [x] **v1.4** (2026-04-17): Hex **`scrypath 0.3.1`** with Release Please + post-publish `release_publish` / `release_parity` gates; narrow `hot_apply/3` for synonyms / stop words / typo tolerance; operator failure rollups by `reason_class` (`mix verify.phase26`).
- [x] **v1.5** (2026-04-18): **Phases 27–28** — read-only **index contract drift** (`Scrypath.index_contract_drift/2`, `IndexContractDrift.Report`), optional **`include_index_contract_drift`** on `reconcile_sync/2`, **`mix scrypath.index.contract_drift`**, operator doc refresh, auth-free **`mix verify.phase28`** — satisfies **DRIFT15-01..02**, **OPS15-01..04** (see **`milestones/v1.5-REQUIREMENTS.md`**).
- [x] **Phase 29** (2026-04-18): **`guides/golden-path.md`** (install → inline sync → `Scrypath.search/3`), ExDoc registration, README adoption wayfinding (sync heuristics + **`guides/sync-modes-and-visibility.md`** authority, **Versioning and upgrades**, `{:scrypath, "~> 0.3"}`), releasing + CHANGELOG cross-links — **ADPT-01, ADPT-02, ADPT-03**.
- [x] **Phase 33** (2026-04-18): Root-facing **README** / **CONTRIBUTING** / **`guides/golden-path.md`** agree on **cwd** for Phoenix example **`scripts/smoke.sh`**; **`docs_contract_test.exs`** locks filesystem + ordering — **ADPT-01**, **EXAM-02**, **VRFY-02**, **AUDT-01** (gap-closure slice).
- [x] **Phase 34** (2026-04-19): README **Quick Path** ↔ **`guides/golden-path.md`** canonical **`field :status, :string`**; golden path **Integration smoke** matches **`phoenix-example-integration`** on PRs + **`main`**; contract tests — **ADPT-01**, **ADPT-02**, **ADPT-03**, **VRFY-01** (audit gap-closure slice).

### Active

- [ ] **v1.6 (phases 29–35)** — Adoption-grade integration and trust; **29–34** verified in-repo. **35** closes remaining **`v1.6-MILESTONE-AUDIT.md`** sync-guide parity gap; related **REQ** checkboxes stay **pending** until phase **35** verifies and traceability is closed. Then **re-audit** and milestone complete. Feature backlog (facets depth, multi-index scoring, per-query relevance) stays deferred unless explicitly pulled into a later milestone.

### Out of Scope

- Postgres-native full-text search as a first-class v1 product surface - it muddies the product boundary and competes with a different problem space.
- Public multi-backend support before real adoption pressure proves the common contract deserves to widen.
- Advanced relevance features such as vector search, hybrid retrieval, personalization, or analytics before the operational core and public release story settle.

## Context

The project exists to fill a gap in the Elixir ecosystem: there are low-level API clients and partial integrations for search engines, but no category-defining library that gives Ecto and Phoenix developers a Searchkick or Laravel Scout level experience. The strongest initial wedge is Meilisearch because the Elixir ecosystem gap is larger there than for Typesense, while the long-term architecture should still preserve an internal adapter seam so the public API is not painted into a corner.

Scrypath is intended primarily for Phoenix applications using Ecto, with Ecto-first APIs and Phoenix-friendly features layered on top. The library emphasizes least surprise, operational honesty, and high-quality developer experience. Search synchronization acknowledges eventual consistency where it exists, supports Oban naturally, and documents tradeoffs clearly in README and guides so users understand who the library is for and who it is not for.

The repository has **six** archived planning milestones (`v1.0`–`v1.5`) plus **v1.6** in progress; see `.planning/milestones/v*-ROADMAP.md`, `.planning/ROADMAP.md`, and `MILESTONES.md`.

- `v1.0` shipped the Meilisearch-first Ecto-native indexing core, search/hydration path, Oban support, reindex workflows, public Phoenix docs, and release automation baseline.
- `v1.1` shipped release hardening, docs-safety fixes, `mix verify.phase10`, and the launch-readiness evidence chain.
- `v1.2` shipped the first live public release as `scrypath 0.3.0`, the internal operations seam, operator visibility APIs, thin Mix tasks, and milestone-close verification/bookkeeping repairs.
- `v1.3` shipped planning-track delivery of relevance tuning, faceted search, multi-index search, operator polish + drift recovery guide, release-parity gates, and v1.2 Nyquist validation closure (archived 2026-04-17).
- `v1.4` shipped **Hex `scrypath 0.3.1`**, the bounded live-index `hot_apply/3` path, and operator failure rollups — archived 2026-04-17 (`milestones/v1.4-ROADMAP.md`, `milestones/v1.4-REQUIREMENTS.md`).

The current public line on Hex is **`scrypath 0.3.3`**. Planning milestone **v1.5** (**drift / schema-diff operator tooling**, phases **27–28**) is complete in-repo. **v1.6** focuses on adoption, integration proof, and verification clarity—not net-new search algorithms.

## Constraints

- **Tech stack**: Elixir OSS library with Ecto-first APIs and Phoenix-friendly integrations - the ecosystem fit is central to adoption.
- **Backend strategy**: Public v1 should target Meilisearch first, while preserving an internal adapter seam - avoid premature public abstraction without causing API damage later.
- **Write-path support**: v1 should support inline, Oban-backed, and manual synchronization flows - different apps need different consistency and operational tradeoffs.
- **Developer experience**: Minimal setup and great Phoenix ergonomics are the top priority, with correctness close behind - product decisions should optimize for low friction without hiding reality.
- **Operational clarity**: Eventual consistency, delete semantics, backfills, and reindex workflows must be explicit - search sync failures are operational issues, not minor edge cases.
- **Release quality**: Public release is now proven, but future milestone choices should still favor product coherence over breadth for its own sake.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Use `Scrypath` as the project and package identity | The name is available on Hex and matches the intended brand posture | Retained through v1.2 public release |
| Position the product as the missing Searchkick or Scout for Ecto and Phoenix | The real gap is the integration and sync layer, not another thin HTTP client | Reinforced by shipped API, docs, and first public release |
| Start with Meilisearch as the public v1 backend | The market gap is stronger and it keeps v1 focused while preserving an internal adapter seam | Validated across v1.0-v1.2 |
| Keep the core Ecto-first and Phoenix-friendly | Ecto is the stable architectural center, while Phoenix ergonomics are critical for adoption | Validated in shipped API and docs |
| Support inline, Oban, and manual sync modes in v1 | Teams need a simple local path, a production queue path, and an explicit escape hatch | Validated in v1.0 and clarified in v1.2 operator guides |
| Expose operator visibility through Scrypath-owned APIs and thin Mix tasks, not a dashboard product | Early adopters need explicit operational visibility without a second product surface | Shipped and validated in v1.2 |
| Defer public multi-backend support and advanced relevance features until real adoption pressure appears | Premature abstraction and feature breadth would increase API risk before the core is proven | Still deferred after the first public release |
| Ship v1.4 as additive Hex + ops depth (`0.3.1`) without widening backend or reconcile forks | Keeps the public story honest while closing the package parity gap | ✓ Good — shipped 2026-04-17 |
| Narrow `hot_apply/3` to synonym / stop-word / typo-tolerance keys only | Prevents silent widening into ranking rules and other managed-pipeline settings | ✓ Good — TUNE14-01/02 |
| Operator rollups as additive metadata on `failed_sync_work/2` | Report-first discipline; no new recovery verbs | ✓ Good — OPS14-01 / `mix verify.phase26` |

## Current State

Scrypath has **six archived planning milestones** (`v1.0`–`v1.5`). **Hex:** `scrypath` **`0.3.3`**. The v1.3-era Meilisearch-native surface (relevance, facets, multi-index, operator polish) plus v1.4’s **hot_apply** subset and **failure rollups** are on the default install line. **v1.5** adds **`Scrypath.index_contract_drift/2`**, **`mix scrypath.index.contract_drift`**, **`mix verify.phase28`**, and operator doc cross-links for **contract** vs **settings** drift. Release-parity gates (`mix verify.workspace_clean`, `mix verify.release_parity`) and `mix verify.phase11` remain the mechanical trust chain documented in **`docs/releasing.md`**.

**Planning:** **v1.6** is open — **`.planning/REQUIREMENTS.md`**, **`.planning/ROADMAP.md`**, phases **29–35**. **Phases 29–34** are verified in-repo; **35** is the remaining **gap closure** from the v1.6 milestone audit. **Re-audit** then **milestone complete** closes v1.6. Deferred feature ideas remain in **`.planning/ROADMAP.md` § Backlog**.

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `$gsd-transition`):
1. Requirements invalidated? -> Move to Out of Scope with reason
2. Requirements validated? -> Move to Validated with phase reference
3. New requirements emerged? -> Add to Active
4. Decisions to log? -> Add to Key Decisions
5. "What This Is" still accurate? -> Update if drifted

**After each milestone** (via `$gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check - still the right priority?
3. Audit Out of Scope - reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-19 — Phase **34** complete; Hex `0.3.3` current*
