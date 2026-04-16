# Requirements: Scrypath

**Defined:** 2026-04-15
**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## v1 Requirements

### Schema Declaration

- [x] **SCMA-01**: Developer can declare a searchable Ecto schema with a small, explicit `use Scrypath` configuration.
- [x] **SCMA-02**: Developer can define how a source record is projected into a search document.
- [x] **SCMA-03**: Developer can inspect declared search metadata for a schema at runtime.

### Sync Lifecycle

- [x] **SYNC-01**: Developer can synchronize searchable records on insert.
- [x] **SYNC-02**: Developer can synchronize searchable records on update.
- [x] **SYNC-03**: Developer can remove searchable records from the index on delete without requiring the source record to still exist.
- [x] **SYNC-04**: Developer can choose inline synchronization for simple or local workflows.
- [x] **SYNC-05**: Developer can choose Oban-backed asynchronous synchronization for production workflows.
- [x] **SYNC-06**: Developer can choose manual synchronization for imports, migrations, or operator-controlled flows.

### Search Querying

- [ ] **SRCH-01**: Developer can execute a search against a searchable schema using a small, consistent API.
- [ ] **SRCH-02**: Developer can filter search results using declared filterable fields.
- [ ] **SRCH-03**: Developer can sort search results using declared sortable fields.
- [ ] **SRCH-04**: Developer can paginate search results.
- [ ] **SRCH-05**: Developer can access raw backend hit metadata when needed.
- [ ] **SRCH-06**: Developer can hydrate search hits back into Ecto records.

### Reindexing and Operations

- [ ] **OPER-01**: Developer can bulk backfill an index from existing Ecto records.
- [ ] **OPER-02**: Developer can trigger a reindex workflow intentionally rather than reimplementing it ad hoc.
- [ ] **OPER-03**: Developer can apply index settings as part of managed indexing workflows.
- [x] **OPER-04**: Developer can observe indexing and query workflows through Telemetry events.
- [ ] **OPER-05**: Developer can understand eventual consistency, failure modes, and recovery workflows from the official documentation.

### Phoenix Ergonomics

- [ ] **PHNX-01**: Phoenix developer can follow first-class guides and examples for using Scrypath in Phoenix applications.
- [ ] **PHNX-02**: Phoenix developer can use Scrypath patterns cleanly from controllers, contexts, and LiveView flows without relying on hidden magic.

### Backend Foundation

- [x] **BACK-01**: Developer can use Scrypath with Meilisearch as the supported public backend in v1.
- [x] **BACK-02**: The internal architecture preserves a path to future backend support without forcing a premature public abstraction.

## v2 Requirements

### Backends

- **BACK-03**: Developer can use Scrypath with Typesense through a supported adapter.
- **BACK-04**: Developer can adopt additional backend support without breaking the core public API.

### Search Features

- **SRCH-07**: Developer can use richer search features such as faceting, multisearch, or related backend-native capabilities through stable APIs.
- **SRCH-08**: Developer can use advanced relevance features such as vector or hybrid search where they fit the product direction.

### Associations and Multi-Tenancy

- **SYNC-07**: Developer can declare reindex dependencies for related records and avoid stale documents when associated data changes.
- **OPER-06**: Developer can use more complete tenant-scoping patterns beyond index prefixes where backend capabilities support them.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Postgres-native full-text search as a coequal v1 feature | Different product boundary and would blur the core use case |
| Public backend-agnostic API parity in v1 | Risks lowest-common-denominator design before one backend is great |
| Vector search, hybrid retrieval, or analytics in v1 | Too much surface area before the operational core is complete |
| Mandatory Oban or Phoenix dependency | Core library should stay Ecto-first and lightweight |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SCMA-01 | Phase 1 | Complete |
| SCMA-02 | Phase 1 | Complete |
| SCMA-03 | Phase 1 | Complete |
| BACK-02 | Phase 1 | Complete |
| BACK-01 | Phase 2 | Complete |
| SYNC-01 | Phase 2 | Complete |
| SYNC-02 | Phase 2 | Complete |
| SYNC-03 | Phase 2 | Complete |
| SYNC-04 | Phase 2 | Complete |
| SYNC-06 | Phase 2 | Complete |
| SRCH-01 | Phase 3 | Pending |
| SRCH-02 | Phase 3 | Pending |
| SRCH-03 | Phase 3 | Pending |
| SRCH-04 | Phase 3 | Pending |
| SRCH-05 | Phase 3 | Pending |
| SRCH-06 | Phase 3 | Pending |
| SYNC-05 | Phase 4 | Complete |
| OPER-04 | Phase 4 | Complete |
| OPER-01 | Phase 5 | Pending |
| OPER-02 | Phase 5 | Pending |
| OPER-03 | Phase 5 | Pending |
| OPER-05 | Phase 5 | Pending |
| PHNX-01 | Phase 6 | Pending |
| PHNX-02 | Phase 6 | Pending |

**Coverage:**
- v1 requirements: 24 total
- Mapped to phases: 24
- Unmapped: 0

---
*Requirements defined: 2026-04-15*
*Last updated: 2026-04-16 after phase 4 plan 04-03 execution*
