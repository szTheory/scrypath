# Scrypath Architecture

## Public Surface

Phase 2 keeps one common runtime surface and one explicit backend-specific escape hatch:

- `Scrypath` for runtime reflection helpers plus common sync verbs
- `Scrypath.Schema` for the metadata declaration contract
- `Scrypath.Projection` for document projection rules
- `Scrypath.Meilisearch` for backend-native operations that do not belong on the common path

Schemas opt in through `use Scrypath`, then runtime code reads normalized metadata through `Scrypath.*` functions instead of generated per-schema APIs.

The common path covers document projection, canonical delete identity, index resolution, and explicit sync verbs such as `Scrypath.sync_record/3` and `Scrypath.delete_document/3`.

`Scrypath.Meilisearch.*` is the explicit escape hatch for Meilisearch-specific behavior such as task-native results and later index-level operations. That keeps backend-native power visible without forcing Meilisearch concepts into every common call.

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

## Sync Guarantees

Sync is explicit orchestration code that should run after successful repo persistence.

`sync_mode: :inline` waits for terminal backend success before returning `{:ok, result}`, but it does not make database and search writes atomic.

`sync_mode: :manual` uses the same verbs and result shape, while returning accepted task metadata immediately for operator-controlled workflows such as imports and migrations.

## Deferred Work

Phase 1 intentionally does not implement:

- Meilisearch sync execution
- Oban integration
- query execution
- managed reindex orchestration

Those workflows build on the contracts defined here instead of reshaping them later.
