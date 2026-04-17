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

### Active

- [ ] Deepen Meilisearch-native search power through Scrypath-owned APIs: faceted search, relevance tuning (typo/synonyms/ranking), and multi-index search — without breaking sync, backfill, or operator contracts.
- [ ] Surface narrow operator-polish improvements (failed-work depth plus a drift recovery guide) without expanding the operator surface beyond what early adopter feedback justifies.
- [ ] Retire remaining release/tooling debt: GitHub Actions Node 20 deprecation warnings and VALIDATION.md closure for v1.2 phases 13, 14, 15.

### Out of Scope

- Postgres-native full-text search as a first-class v1 product surface - it muddies the product boundary and competes with a different problem space.
- Public multi-backend support before real adoption pressure proves the common contract deserves to widen.
- Advanced relevance features such as vector search, hybrid retrieval, personalization, or analytics before the operational core and public release story settle.

## Context

The project exists to fill a gap in the Elixir ecosystem: there are low-level API clients and partial integrations for search engines, but no category-defining library that gives Ecto and Phoenix developers a Searchkick or Laravel Scout level experience. The strongest initial wedge is Meilisearch because the Elixir ecosystem gap is larger there than for Typesense, while the long-term architecture should still preserve an internal adapter seam so the public API is not painted into a corner.

Scrypath is intended primarily for Phoenix applications using Ecto, with Ecto-first APIs and Phoenix-friendly features layered on top. The library emphasizes least surprise, operational honesty, and high-quality developer experience. Search synchronization acknowledges eventual consistency where it exists, supports Oban naturally, and documents tradeoffs clearly in README and guides so users understand who the library is for and who it is not for.

The repository now has three archived milestones:

- `v1.0` shipped the Meilisearch-first Ecto-native indexing core, search/hydration path, Oban support, reindex workflows, public Phoenix docs, and release automation baseline.
- `v1.1` shipped release hardening, docs-safety fixes, `mix verify.phase10`, and the launch-readiness evidence chain.
- `v1.2` shipped the first live public release as `scrypath 0.3.0`, the internal operations seam, operator visibility APIs, thin Mix tasks, and milestone-close verification/bookkeeping repairs.

The library is now publicly released and functionally complete for its current boundary. The next milestone should follow real maintainer and adopter pressure rather than speculative surface expansion.

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

## Current State

Scrypath has shipped three milestones and one real public Hex release, `0.3.0`. Maintainers now have a verified release contract, live Hex and HexDocs proof, and explicit recovery runbooks. Operators have status, failed-work, retry, and reconcile visibility through Scrypath-owned APIs plus thin `mix scrypath.*` ergonomics. The internal operations seam is in place so future backend work can evolve without forcing a premature public abstraction. Milestone `v1.3` is now active, focused on closing the Meilisearch-native search feature gap that the first adopter tier reaches for immediately after install.

## Current Milestone: v1.3 Search Power That Phoenix Teams Reach For

**Goal:** Land the three Meilisearch-native capabilities every growth-stage Phoenix SaaS immediately needs — faceted search, relevance tuning (typo tolerance, synonyms, ranking rules), and multi-index search — through Scrypath-owned APIs that preserve the shipped sync, backfill, and operator contracts. Retire remaining release and tooling debt in the same cycle so v1.4 starts clean.

**Target features:**
- Faceted search: declarative `faceting` schema field, validated facet filter expressions, facet distribution and stats on `SearchResult`, Phoenix LiveView guide
- Relevance tuning: declarative per-schema settings for synonyms, typo tolerance, ranking rules, distinct attribute, and stop words applied safely through the existing reindex pipeline
- Multi-index search: `Scrypath.search_many/2` federated queries across N schemas with per-schema validation preserved and a unified hydration path
- Operator polish: richer `FailedWork.t()` (attempt count, error reason class, last attempt timestamp) plus an end-to-end drift recovery guide
- Release and tooling debt retirement: GitHub Actions upgraded past Node 20 deprecation warnings and missing VALIDATION.md artifacts closed for v1.2 phases 13, 14, 15

**Key context:** Direction chosen by extrapolation rather than a single explicit adopter request — the evidence from the codebase gap analysis, planning history, and ecosystem research converges on "deepen Meilisearch-first before widening backends". Persona 2 (growth-stage Phoenix SaaS) is the primary cohort for v1.3 impact. Reference libraries (Searchkick, Laravel Scout) shipped comprehensive first-backend features before adding a second adapter, and Scrypath is deliberately at that inflection point.

## Next Milestone Goals

- Collect real adopter feedback during the v1.3 cycle to validate whether deeper search power or backend breadth should drive v1.4.
- Hold the line on non-goals: no second public backend, no vector/hybrid search, no dashboard product surface.
- Reserve deeper drift/schema-diff operator tooling for v1.4 once v1.3 feature work produces real-world recovery scenarios.

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
*Last updated: 2026-04-16 — v1.3 milestone started*
