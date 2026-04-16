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

### Active

- [ ] Validate the first real tagged/public package release with publisher-scoped Hex credentials and confirm the Release Please publish path end to end.
- [ ] Give operators explicit status, failure inspection, retry, reconcile, and reindex visibility without turning Scrypath into a dashboard product.
- [ ] Preserve the Meilisearch-first common path while extracting an internal operations seam that makes future backend work survivable.

### Out of Scope

- Postgres-native full-text search as a first-class v1 product surface - it muddies the product boundary and competes with a different problem space.
- Public multi-backend support in the first release - it increases abstraction pressure before the core sync and DX story is proven.
- Advanced relevance features such as vector search, hybrid retrieval, personalization, or analytics in v1 - they add surface area before the operational core is solid.

## Context

The project exists to fill a gap in the Elixir ecosystem: there are low-level API clients and partial integrations for search engines, but no category-defining library that gives Ecto and Phoenix developers a Searchkick or Laravel Scout level experience. The strongest initial wedge is Meilisearch because the Elixir ecosystem gap is larger there than for Typesense, while the long-term architecture should still preserve an internal adapter seam so the public API is not painted into a corner.

Scrypath is intended primarily for Phoenix applications using Ecto, with Ecto-first APIs and Phoenix-friendly features layered on top. The library should emphasize least surprise, operational honesty, and high-quality developer experience. Search synchronization should acknowledge eventual consistency where it exists, support Oban naturally, and document tradeoffs clearly in README and guides so users understand who the library is for and who it is not for.

This repository also includes local reference docs under `prompts/` covering search-library use cases, Elixir and Ecto best practices, OSS library ergonomics, and CI/CD conventions. Those documents informed the initial framing and should continue to serve as project context during planning.

When running future GSD discuss, plan, and execute flows, consult the relevant files under `prompts/` as authoritative local reference material whenever phase decisions touch API design, Phoenix and Ecto ergonomics, OSS release practices, or project positioning.

## Constraints

- **Tech stack**: Elixir OSS library with Ecto-first APIs and Phoenix-friendly integrations - the ecosystem fit is central to adoption.
- **Backend strategy**: Public v1 should target Meilisearch first, while preserving an internal adapter seam - avoid premature public abstraction without causing API damage later.
- **Write-path support**: v1 should support inline, Oban-backed, and manual synchronization flows - different apps need different consistency and operational tradeoffs.
- **Developer experience**: Minimal setup and great Phoenix ergonomics are the top priority, with correctness close behind - product decisions should optimize for low friction without hiding reality.
- **Operational clarity**: Eventual consistency, delete semantics, backfills, and reindex workflows must be explicit - search sync failures are operational issues, not minor edge cases.
- **Release quality**: The library should not be released publicly until it feels complete - roadmap and documentation should reflect a high quality bar rather than a rush to ship.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Use `Scrypath` as the project and package identity | The name is available on Hex and matches the intended brand posture | Retained through v1.1 hardening |
| Position the product as the missing Searchkick or Scout for Ecto and Phoenix | The real gap is the integration and sync layer, not another thin HTTP client | Reinforced by v1.0 and v1.1 |
| Start with Meilisearch as the public v1 backend | The market gap is stronger and it keeps v1 focused while preserving an internal adapter seam | Validated in v1.0 and retained in v1.1 |
| Keep the core Ecto-first and Phoenix-friendly | Ecto is the stable architectural center, while Phoenix ergonomics are critical for adoption | Validated in shipped API and docs |
| Support inline, Oban, and manual sync modes in v1 | Teams need a simple local path, a production queue path, and an explicit escape hatch | Validated in v1.0 |
| Exclude Postgres-native full-text search from the v1 product surface | It solves a different problem and would blur the product story too early | Still out of scope after v1.1 |
| Defer public multi-backend support and advanced relevance features | Premature abstraction and feature breadth would increase API risk before the core is validated | Still deferred pending adoption feedback |

## Current State

Scrypath has two archived milestones:

- `v1.0` shipped the Meilisearch-first Ecto-native indexing core, search/hydration path, Oban support, reindex workflows, public Phoenix docs, and release automation baseline.
- `v1.1` shipped the release-hardening pass that tightened Meilisearch task contracts, closed copied-doc hazards, added `mix verify.phase10`, and built the final launch-readiness evidence chain.

The library is functionally complete for its current public boundary. The next unknown is not basic product breadth; it is how the package and release story behave under real public adoption and where real users push hardest on backend breadth, operator tooling, or backend-native search power.

## Current Milestone

**v1.2 — Public Release Trust and Operator Visibility**

**Goal:** Turn Scrypath's internal launch-readiness evidence into real public release confidence while adding a small, explicit operator surface for sync status, failure inspection, and recovery.

**Target features:**
- Validate one real public Hex release path end to end, including version/tag/workflow alignment and post-publish smoke verification.
- Add `Scrypath.Operator.*`-style primitives plus thin Mix task ergonomics for status, failed work inspection, retry, reconcile, and reindex visibility.
- Extract an internal operations seam so sync and reindex flows stop depending directly on Meilisearch-shaped orchestration details.

## Next Milestone Goals

- Confirm one successful real release with the correct publisher-scoped Hex credentials and the existing GitHub Actions publish path.
- Make operational state legible enough that early adopters can trust async/manual indexing in production.
- Use post-release adoption feedback to decide whether the following milestone should widen backend support or deepen Meilisearch-native search power.

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
*Last updated: 2026-04-16 after starting milestone v1.2*
