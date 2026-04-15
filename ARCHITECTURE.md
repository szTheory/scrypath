# Scrypath Architecture

## Public Surface

Phase 1 exposes three core modules:

- `Scrypath` for runtime reflection helpers
- `Scrypath.Schema` for the metadata declaration contract
- `Scrypath.Projection` for document projection rules

Schemas opt in through `use Scrypath`, then runtime code reads normalized metadata through `Scrypath.*` functions instead of generated per-schema APIs.

## Projection Flow

Schema declaration stores normalized metadata on the schema module through `__scrypath__/1`.

`Scrypath.Projection.document/2` turns a source record into a `Scrypath.Document` struct. It follows one precedence rule:

1. If the schema exports `search_document/1`, use that result.
2. Otherwise project the exact field list declared in `fields: [...]`.

Projection never performs implicit association loading. Any association-derived data must be loaded before projection begins.

## Internal Backend Seam

`Scrypath.Backend` is an internal behavior. It exists to preserve a path for future backend support without promising a public backend-agnostic extension surface in v1.

Phase 1 defines these callbacks:

- `name/0`
- `index_name/2`
- `upsert_documents/3`
- `delete_documents/3`
- `search/3`

Backend-specific power remains a later concern for explicit namespaces such as `Scrypath.Meilisearch.*`.

## Runtime Configuration

`Scrypath.Config.resolve!/1` treats explicit runtime options as canonical input and only falls back to `Application.get_env(:scrypath, :defaults, [])` as convenience defaults.

That keeps the contract legible for later inline, manual, and Oban-backed sync paths while avoiding hidden global behavior in the core library.

## Deferred Work

Phase 1 intentionally does not implement:

- Meilisearch sync execution
- Oban integration
- query execution
- managed reindex orchestration

Those workflows build on the contracts defined here instead of reshaping them later.
