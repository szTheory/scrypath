# Roadmap: Scrypath

**Created:** 2026-04-15
**Project:** Scrypath
**Total phases:** 6
**v1 requirements:** 24
**Coverage:** 100%

## Overview

| # | Phase | Goal | Requirements | UI Hint |
|---|-------|------|--------------|---------|
| 1 | Core Contracts and API Shape | Establish the schema metadata model, projection contract, internal adapter seam, and public API boundaries | SCMA-01, SCMA-02, SCMA-03, BACK-02 | No |
| 2 | Meilisearch Core Sync | Deliver the Meilisearch adapter plus inline and manual synchronization for insert, update, and delete flows | BACK-01, SYNC-01, SYNC-02, SYNC-03, SYNC-04, SYNC-06 | No |
| 3 | Search Query API and Hydration | Deliver the core search API, filtering, sorting, pagination, and hydration back into Ecto records | SRCH-01, SRCH-02, SRCH-03, SRCH-04, SRCH-05, SRCH-06 | No |
| 4 | Oban and Observability | Add production-grade async synchronization through Oban and first-class Telemetry instrumentation | SYNC-05, OPER-04 | No |
| 5 | Reindexing and Operational Workflows | Build bulk backfill, managed reindex flows, settings application, and operator documentation for drift and recovery | OPER-01, OPER-02, OPER-03, OPER-05 | No |
| 6 | Phoenix Ergonomics and Public-Facing Polish | Make the library feel excellent in Phoenix apps through guides, examples, and final release-quality polish | PHNX-01, PHNX-02 | Yes |

## Phase Details

### Phase 1: Core Contracts and API Shape

**Goal:** Define the public and internal foundations so later implementation work reinforces a stable, idiomatic product shape.

**Status:** Complete (2026-04-15)

**Requirements:** SCMA-01, SCMA-02, SCMA-03, BACK-02

**Success criteria:**
1. A developer can declare searchable metadata on an Ecto schema with a small, explicit API.
2. The projection contract is documented and testable.
3. The codebase has an internal backend seam that does not overcommit the public API.
4. The core README and architecture docs explain the chosen product boundary and tradeoffs.

**UI hint:** no

### Phase 2: Meilisearch Core Sync

**Goal:** Make Scrypath useful end to end for one real backend by delivering safe core indexing flows.

**Status:** Complete (2026-04-15)

**Requirements:** BACK-01, SYNC-01, SYNC-02, SYNC-03, SYNC-04, SYNC-06

**Plans:** 4 plans

Plans:
- [x] 02-01-PLAN.md - Common sync facade and delete identity contract
- [x] 02-02-PLAN.md - Meilisearch backend, client, and runtime config
- [x] 02-03-PLAN.md - Inline task waiting and failure semantics
- [x] 02-04-PLAN.md - Manual batch workflows and Phase 2 documentation

**Success criteria:**
1. A developer can synchronize searchable records to Meilisearch on insert and update.
2. A developer can remove documents from the index safely after deletes.
3. Inline and manual sync paths are both supported and documented.
4. The sync flow preserves stable document identity without relying on reloading deleted rows.

**UI hint:** no

### Phase 3: Search Query API and Hydration

**Goal:** Provide the developer-facing search API that turns the indexing core into a usable product.

**Status:** Complete (2026-04-15)

**Requirements:** SRCH-01, SRCH-02, SRCH-03, SRCH-04, SRCH-05, SRCH-06

**Plans:** 4 plans

Plans:
- [x] 03-01-PLAN.md - Common search facade and normalized query contract
- [x] 03-02-PLAN.md - Backend search execution and Meilisearch translation
- [x] 03-03-PLAN.md - Stable result envelope and explicit hydration
- [x] 03-04-PLAN.md - Search docs and native-path boundary

**Success criteria:**
1. A developer can run a search against a declared schema through a consistent API.
2. Filters, sorts, and pagination work against declared searchable metadata.
3. Raw hits remain accessible for advanced use while hydrated Ecto records are easy to consume.
4. The query API feels composable and unsurprising in normal Ecto and Phoenix application code.

**UI hint:** no

### Phase 4: Oban and Observability

**Goal:** Add the production async path and instrumentation needed for serious application use.

**Requirements:** SYNC-05, OPER-04

**Plans:** 3 plans

Plans:
- [x] 04-01-PLAN.md - Common Oban sync contract, option validation, and JSON-safe payloads
- [ ] 04-02-PLAN.md - Durable Oban enqueue, workers, and transactional helper
- [ ] 04-03-PLAN.md - Telemetry spans, async operator docs, and focused observability tests

**Success criteria:**
1. A developer can enqueue durable indexing work through Oban.
2. Async sync is documented with clear consistency expectations and failure semantics.
3. Telemetry spans and metadata cover key search and indexing workflows.
4. Optional dependencies remain optional and the core path stays lightweight.

**UI hint:** no

### Phase 5: Reindexing and Operational Workflows

**Goal:** Make rebuilds, cutovers, and recovery workflows safe enough for real systems.

**Requirements:** OPER-01, OPER-02, OPER-03, OPER-05

**Success criteria:**
1. A developer can backfill existing records into a fresh or rebuilt index.
2. A developer can run a managed reindex workflow instead of composing one manually.
3. Index settings are applied intentionally as part of operational workflows.
4. Official docs explain drift detection, rebuild strategy, and recovery expectations.

**UI hint:** no

### Phase 6: Phoenix Ergonomics and Public-Facing Polish

**Goal:** Turn a solid core into a library Phoenix teams will actually want to adopt and recommend.

**Requirements:** PHNX-01, PHNX-02

**Success criteria:**
1. Phoenix-focused guides show how Scrypath fits into contexts, controllers, and LiveView.
2. The README explains who the library is for, who it is not for, and why key tradeoffs were made.
3. Examples, docs, CI, and release ergonomics reflect public-release quality.
4. The library feels first-class for Phoenix users while staying Ecto-first architecturally.

**UI hint:** yes

## Dependency Notes

- Phase 1 is foundational for every later phase.
- Phase 2 depends on Phase 1.
- Phase 3 depends on Phase 1 and Phase 2.
- Phase 4 depends on Phase 2 and should align with Phase 3 API semantics.
- Phase 5 depends on Phases 2 through 4.
- Phase 6 depends on the product shape being mostly stable across Phases 1 through 5.

---
*Last updated: 2026-04-16 after phase 4 plan 04-01 execution*
