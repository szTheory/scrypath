# Feature Research: Scrypath

**Research date:** 2026-04-15

## Table Stakes

### Schema Integration

- Declarative schema-level search configuration
- Configurable index naming
- Search document projection hook
- Introspection helpers for declared search metadata

### Sync Lifecycle

- Sync on insert
- Sync on update
- Sync on delete
- Bulk backfill and rebuild workflows
- Manual reindex operations
- Explicit eventual consistency documentation

### Query Experience

- Search API for query term submission
- Result hydration back to Ecto records
- Filter and sort support
- Pagination support
- Access to raw backend result metadata

### Operations

- Telemetry events
- Retry-safe async processing
- Safe delete semantics for missing source rows
- Reindex tooling with progress visibility
- Clear docs for drift, backfills, and failure recovery

### Phoenix Ergonomics

- Phoenix-oriented examples and guides
- Plug or controller-friendly request parameter handling where appropriate
- LiveView-friendly patterns for search UIs without forcing UI helpers into the core

## Differentiators

- Phoenix-first examples and integration guides that feel native instead of generic
- Strong operator-facing reindex and cutover workflows
- Honest documentation about eventual consistency and failure modes
- A carefully-designed internal adapter seam that avoids locking the API too tightly to one engine

## Anti-Features

- Claiming backend interchangeability that falls apart under real filtering, ranking, and schema differences
- Large macro DSLs that replace ordinary Ecto query composition
- Hidden callbacks or implicit side effects that users cannot reason about
- Shipping advanced relevance or vector features before sync correctness is solid

## Complexity Notes

| Feature Area | Complexity | Notes |
|--------------|------------|-------|
| Schema declaration and metadata | Medium | Needs careful API design but bounded scope |
| Sync lifecycle | High | Correctness and operator semantics matter |
| Query API and hydration | Medium | Must balance convenience and transparency |
| Reindex and cutover | High | Operationally sensitive, especially with large datasets |
| Phoenix-facing polish | Medium | Mostly docs and helpers, but important for adoption |

## Dependencies

- Reindex workflows depend on stable document projection and sync primitives
- Result hydration depends on stable schema metadata and query/result mapping
- Phoenix-facing helpers depend on the core API being stable and unsurprising
