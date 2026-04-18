# Scrypath

## What This Is

Scrypath is an open-source Elixir library for declarative, Ecto-native search indexing and search orchestration. It helps Phoenix and Ecto teams add search to existing schemas with a small amount of code while handling synchronization, reindexing, and operational workflows in a way that feels native to the Elixir ecosystem.

## Core Value

Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

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
- [x] **v1.5 — Phase 27** (2026-04-17): Read-only **index contract drift** report (`Scrypath.index_contract_drift/2`, `IndexContractDrift.Report`), optional **`include_index_contract_drift`** on `reconcile_sync/2` — satisfies **DRIFT15-01**, **DRIFT15-02**, **OPS15-01** (see `.planning/REQUIREMENTS.md`).

### Active

- [ ] **v1.5 (2026-04-17)** — Remaining **Phase 28**: thin **`mix scrypath.*`** surfacing, **`guides/drift-recovery.md`** / **`docs/operator-support.md`**, auth-free **`mix verify.phase27`** (OPS15-02..04). See `.planning/REQUIREMENTS.md` and `.planning/ROADMAP.md`.

### Out of Scope

- Postgres-native full-text search as a first-class v1 product surface - it muddies the product boundary and competes with a different problem space.
- Public multi-backend support before real adoption pressure proves the common contract deserves to widen.
- Advanced relevance features such as vector search, hybrid retrieval, personalization, or analytics before the operational core and public release story settle.

## Context

The project exists to fill a gap in the Elixir ecosystem: there are low-level API clients and partial integrations for search engines, but no category-defining library that gives Ecto and Phoenix developers a Searchkick or Laravel Scout level experience. The strongest initial wedge is Meilisearch because the Elixir ecosystem gap is larger there than for Typesense, while the long-term architecture should still preserve an internal adapter seam so the public API is not painted into a corner.

Scrypath is intended primarily for Phoenix applications using Ecto, with Ecto-first APIs and Phoenix-friendly features layered on top. The library emphasizes least surprise, operational honesty, and high-quality developer experience. Search synchronization acknowledges eventual consistency where it exists, supports Oban naturally, and documents tradeoffs clearly in README and guides so users understand who the library is for and who it is not for.

The repository has **five** archived planning milestones (`v1.0`–`v1.4`); see `.planning/milestones/v*-ROADMAP.md` and `MILESTONES.md`.

- `v1.0` shipped the Meilisearch-first Ecto-native indexing core, search/hydration path, Oban support, reindex workflows, public Phoenix docs, and release automation baseline.
- `v1.1` shipped release hardening, docs-safety fixes, `mix verify.phase10`, and the launch-readiness evidence chain.
- `v1.2` shipped the first live public release as `scrypath 0.3.0`, the internal operations seam, operator visibility APIs, thin Mix tasks, and milestone-close verification/bookkeeping repairs.
- `v1.3` shipped planning-track delivery of relevance tuning, faceted search, multi-index search, operator polish + drift recovery guide, release-parity gates, and v1.2 Nyquist validation closure (archived 2026-04-17).
- `v1.4` shipped **Hex `scrypath 0.3.1`**, the bounded live-index `hot_apply/3` path, and operator failure rollups — archived 2026-04-17 (`milestones/v1.4-ROADMAP.md`, `milestones/v1.4-REQUIREMENTS.md`).

The current public line on Hex is **`scrypath 0.3.3`**. Planning milestone **v1.5** is open for **drift / schema-diff operator tooling** (phases **27–28**).

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

## Current Milestone: v1.5 — Operator drift and schema-diff tooling

**Goal:** Give operators a **read-only, structured** view of how a schema’s **declared** search contract compares to the **live** Meilisearch index, so drift triage stays explicit and composes with existing settings diff, reconcile, and reindex paths.

**Target features:**

- Structured **declared ↔ live** comparison (fields, filterable, sortable, faceting, selected settings families) without dumping opaque full-index payloads as the only output.
- **`Scrypath.*`** entry point (report-first; **no new recovery verbs** for v1.5).
- Thin **`mix scrypath.*`** surfacing with optional **`--json`** consistent with existing operator tasks.
- Updates to **`guides/drift-recovery.md`** and **`docs/operator-support.md`**; auth-free **`mix verify.phase27`**.

## Current State

Scrypath has **five archived planning milestones** (`v1.0`–`v1.4`) plus **v1.5 in flight**. **Hex:** `scrypath` **`0.3.3`**. The v1.3-era Meilisearch-native surface (relevance, facets, multi-index, operator polish) plus v1.4’s **hot_apply** subset and **failure rollups** are on the default install line. Release-parity gates (`mix verify.workspace_clean`, `mix verify.release_parity`) and `mix verify.phase11` remain the mechanical trust chain documented in **`docs/releasing.md`**.

**Planning:** **v1.5** — **Phase 27 complete**; **Phase 28** next — requirements in **`.planning/REQUIREMENTS.md`**, roadmap in **`.planning/ROADMAP.md`**. ROADMAP **Backlog** carries faceting, multi-index scoring, and per-query relevance follow-ups.

## Next milestone goals (parking lot)

See **`.planning/ROADMAP.md` § Backlog** for post–v1.5 candidates (faceting depth, multi-index scoring, per-query relevance once designed).

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
*Last updated: 2026-04-17 — Phase 27 complete (index contract drift); Hex `0.3.3` current*
