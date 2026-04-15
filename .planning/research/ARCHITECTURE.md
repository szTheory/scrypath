# Architecture Research: Scrypath

**Research date:** 2026-04-15

## Recommended Component Boundaries

### 1. Schema Metadata Layer

Responsible for:
- `use Scrypath, ...` declaration
- compile-time validation where appropriate
- reflection helpers such as `__scrypath__/1`

Not responsible for:
- network calls
- repo ownership
- background job execution

### 2. Projection Layer

Responsible for:
- converting Ecto structs into search documents
- deciding document id, index name, and projected fields
- serializing domain data into backend payloads

### 3. Sync Orchestration Layer

Responsible for:
- inline sync
- Oban-backed async sync
- manual sync entry points
- delete semantics
- bulk backfill and reindex orchestration

### 4. Backend Adapter Layer

Responsible for:
- translating Scrypath operations into backend-specific HTTP calls
- surfacing backend-native settings and capabilities
- preserving escape hatches where needed

### 5. Query Layer

Responsible for:
- search request construction
- result shaping
- raw hit access
- hydration back into Ecto records

### 6. Phoenix Integration Layer

Responsible for:
- examples, helpers, and patterns that improve Phoenix usage
- request and parameter ergonomics where helpful
- LiveView integration guidance

This should remain optional and lightweight.

## Data Flow

1. Developer declares searchable schema metadata.
2. Application writes source records through Ecto.
3. Scrypath projects the source record into a search document.
4. Sync orchestration performs inline update, enqueues Oban work, or exposes manual control.
5. Backend adapter writes to Meilisearch.
6. Search queries return raw hits and optionally hydrated Ecto records.
7. Telemetry events expose timing, failure, and workload details.

## Suggested Build Order

1. Core schema metadata and projection contracts
2. Meilisearch adapter and raw sync primitives
3. Inline sync and manual APIs
4. Query API, hydration, filters, sorts, and pagination
5. Oban integration and retry-safe async processing
6. Reindex and cutover workflows
7. Phoenix-focused docs, guides, and ergonomic helpers
8. Internal adapter seam hardening for future backend expansion

## Architecture Tradeoffs

- **Internal adapter seam now, public abstraction later**: preserves future flexibility without overpromising parity
- **Function-heavy API over heavy macros**: more idiomatic in Elixir and easier to reason about
- **Optional runtime components**: keeps the core library lightweight
- **Ecto-first core with Phoenix polish**: stable architecture underneath, strong adoption story on top
