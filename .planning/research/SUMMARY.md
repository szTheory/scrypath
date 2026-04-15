# Research Summary: Scrypath

**Date:** 2026-04-15

## Key Findings

**Stack:** Ecto-first Elixir library, Meilisearch-first public backend, optional Oban integration, Telemetry from day one, GitHub Actions plus Release Please plus Hex for OSS operations.

**Table Stakes:** schema declaration, projection hooks, sync on insert and update and delete, bulk backfill, reindex workflows, query plus hydration, filters and sorts, pagination, and operator-facing documentation.

**Watch Out For:** premature multi-backend abstraction, magical side effects, async delete bugs, weak reindex semantics, and underinvesting in Phoenix-facing ergonomics.

## Product Synthesis

Scrypath should be built as the missing Searchkick or Scout for Ecto and Phoenix, not as a generic search client. The biggest strategic choice is to keep the public v1 surface focused on Meilisearch while preserving an internal adapter seam to prevent future API damage.

The product should emphasize:

- minimal setup for Ecto schemas
- strong Phoenix adoption ergonomics
- explicit sync mode choices
- operational honesty about eventual consistency
- safe, boring reindex and cutover workflows

## Recommended v1 Focus

1. Schema metadata and projection contracts
2. Meilisearch adapter
3. Inline and manual sync
4. Query API plus hydration
5. Oban integration
6. Reindex and operational workflows
7. Phoenix-first docs and examples

## Deferred

- Public multi-backend support
- Typesense adapter as a committed public feature
- Postgres-native full-text search as part of the same product
- Advanced relevance features such as vector and hybrid search
