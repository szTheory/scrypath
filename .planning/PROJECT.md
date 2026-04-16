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

### Active

- [ ] Deliver a launch-readiness milestone that hardens Scrypath's existing v1 surface before broad public adoption.
- [ ] Resolve the remaining advisory debt from Phase 2 and Phase 6 so copied examples and Meilisearch task handling are trustworthy.
- [ ] Close the remaining release-confidence gaps around validation coverage, public docs safety, and maintainer release flow integrity.

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
| Use `Scrypath` as the working project name | The name is available on Hex and matches the intended brand posture | - Pending |
| Position the product as the missing Searchkick or Scout for Ecto and Phoenix | The real gap is the integration and sync layer, not another thin HTTP client | - Pending |
| Start with Meilisearch as the public v1 backend | The market gap is stronger and it keeps v1 focused while preserving an internal adapter seam | - Pending |
| Keep the core Ecto-first and Phoenix-friendly | Ecto is the stable architectural center, while Phoenix ergonomics are critical for adoption | - Pending |
| Support inline, Oban, and manual sync modes in v1 | Teams need a simple local path, a production queue path, and an explicit escape hatch | Phase 2 validated inline and manual; Oban remains active scope |
| Exclude Postgres-native full-text search from the v1 product surface | It solves a different problem and would blur the product story too early | - Pending |
| Defer public multi-backend support and advanced relevance features | Premature abstraction and feature breadth would increase API risk before the core is validated | - Pending |

## Current State

Scrypath v1.0 is archived. The shipped milestone includes schema declaration and projection contracts, Meilisearch-backed sync flows, the common search and hydration path, Oban-backed async support, reindex/backfill workflows, Phoenix-facing docs, release automation, and repaired milestone verification history.

The library is functionally complete for its v1 product boundary. The next constraint is not missing product breadth; it is public trust. Remaining debt clusters around Meilisearch task-wait edge cases, a handful of copied-example hazards in the public docs, and the maintainer confidence needed to treat Hex/GitHub release automation as ready for real users.

## Current Milestone: v1.1 Release Hardening and Public Launch Readiness

**Goal:** Make Scrypath feel safe to adopt publicly by removing footguns, tightening edge-case behavior, and closing the remaining release-confidence gaps around docs, verification, and maintainer workflows.

**Target features:**
- Harden Meilisearch task waiting and shared sync/delete edge-case contracts so failures stay explicit and no-op flows are defined.
- Fix public install and Phoenix example hazards so copied README, controller, and LiveView examples model safe behavior.
- Close launch-readiness gaps in validation, release documentation, and maintainer publish confidence without widening the public product surface.

## Next Milestone Goals

- Treat `v1.1` as a launch-readiness milestone rather than a breadth milestone.
- Resolve the advisory issues around Meilisearch task payloads, empty-batch semantics, README install guidance, JSON pagination robustness, and LiveView string-key fixtures.
- Finish the remaining verification and release-confidence work needed before inviting broader public adoption.

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
*Last updated: 2026-04-16 after starting milestone v1.1*
