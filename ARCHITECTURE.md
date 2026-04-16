# Scrypath Architecture

## Public Surface

Phase 5 keeps one common runtime surface and one explicit backend-specific escape hatch:

- `Scrypath` for runtime reflection helpers, common sync verbs, backfill, managed reindex, and the common search path
- `Scrypath.Schema` for the metadata declaration contract
- `Scrypath.Projection` for document projection rules
- `Scrypath.Meilisearch` for backend-native operations that do not belong on the common path

Schemas opt in through `use Scrypath`, then runtime code reads normalized metadata through `Scrypath.*` functions instead of generated per-schema APIs.

The common path covers document projection, canonical delete identity, index resolution,
explicit sync verbs, backfill and reindex orchestration, and the stable search API through
`Scrypath.search/3`.

`Scrypath.Meilisearch.*` is the explicit escape hatch for Meilisearch-specific behavior such as task-native results and later index-level operations. That keeps backend-native power visible without forcing Meilisearch concepts into every common call.

## Search Flow

`Scrypath.search/3` normalizes caller input into `%Scrypath.Query{}` before any backend code runs.
That query struct is the only common-path search payload backends receive.

The common path supports:

- text as the second function argument
- structured `filter:` over declared `filterable` fields
- Ecto-shaped `sort:` over declared `sortable` fields
- nested `page:` options
- optional explicit hydration through `repo:` and `preload:`

Successful common-path searches return one `%Scrypath.SearchResult{}` with:

- raw backend hits
- hydrated records
- pagination metadata
- `missing_ids` for stale or missing source rows

Hydration is explicit and repo-backed. Scrypath builds one batch query against the schema's
primary key, applies explicit preloads only to that query, and restores search hit order in Elixir.
It does not infer repos globally or silently hide drift between the index and the database.

## Projection Flow

Schema declaration stores normalized metadata on the schema module through `__scrypath__/1`.

`Scrypath.Projection.document/2` turns a source record into a `Scrypath.Document` struct. It follows one precedence rule:

1. If the schema exports `search_document/1`, use that result.
2. Otherwise project the exact field list declared in `fields: [...]`.

Projection never performs implicit association loading. Any association-derived data must be loaded before projection begins.

## Internal Backend Seam

`Scrypath.Backend` is an internal behavior. It exists to preserve a path for future backend support without promising a public backend-agnostic extension surface in v1.

Phase 3 defines these callbacks:

- `name/0`
- `index_name/2`
- `upsert_documents/3`
- `delete_documents/3`
- `search/3`

`search/3` now takes the normalized `%Scrypath.Query{}` contract on the common path.
Backend-specific search power remains visible under explicit namespaces such as `Scrypath.Meilisearch.*`.

## Runtime Configuration

`Scrypath.Config.resolve!/1` treats explicit runtime options as canonical input and only falls back to `Application.get_env(:scrypath, :defaults, [])` as convenience defaults.

That keeps the contract legible for later inline, manual, and Oban-backed sync paths while avoiding hidden global behavior in the core library.

## Sync Guarantees

Sync is explicit orchestration code that should run after successful repo persistence.

`sync_mode: :inline` waits for terminal backend success before returning `{:ok, result}`, but it does not make database and search writes atomic.

`sync_mode: :manual` uses the same verbs and result shape, while returning accepted task metadata immediately for operator-controlled workflows such as imports and migrations.

| Sync Mode | Contract |
|-----------|----------|
| `:inline` | waits for terminal backend task success before returning |
| `:manual` | returns accepted backend work immediately |
| `:oban` | returns durable enqueue acceptance only |

`sync_mode: :oban` keeps the public verbs on `Scrypath.*`, inserts durable jobs through Oban, and stops there. It does not imply backend completion or search visibility.

All three modes share one operator-facing lifecycle:

`requested -> enqueued -> processing -> backend_accepted -> completed | retrying | discarded`

That wording is intentional. Retry exhaustion, discarded jobs, stale deletes, and search drift are normal operational cases that applications need to observe and recover from.

## Backfill And Managed Reindex

Bulk repair and rebuild flows stay explicit instead of being hidden behind callback magic:

- `Scrypath.backfill/2` reads the source dataset through an explicit repo, batches deterministically by primary key, projects every row through the same projection contract, and writes into one explicit index.
- `Scrypath.reindex/2` creates a target index, applies settings to that target, backfills the target, and optionally performs cutover.

The reindex workflow order is fixed on purpose:

`create target -> apply settings -> backfill -> optional cutover`

That ordering avoids two common operator mistakes:

- applying schema settings to the live index while a rebuild is still in progress
- swapping traffic to a target index that was populated before its real settings were applied

Managed reindex returns the live index name, target index name, whether settings were applied,
batch and document counts, and whether cutover happened. The result is an audit of the workflow,
not a promise that the old index was cleaned up or that the new one is instantly visible to every query.

## Drift And Recovery Semantics

Scrypath treats drift as an expected operational state, not a library bug by definition. Drift can come from:

- projection changes that alter document shape
- settings changes that require a full rebuild
- stale deletes where the source row is gone but the search document remains
- failed, retrying, or discarded async work
- document-count mismatches between source data and the search backend
- stale hydrated search hits that point at missing database rows

The operator decision is blunt:

- backfill into the live index when the index contract is still correct and you need to repair missing or stale documents
- rebuild into a target index when the contract changed or you do not trust the live index contents anymore

`cutover?: false` is the safety valve for incomplete or suspicious rebuilds. It leaves the live index untouched while giving operators a concrete target index to inspect, compare, or discard. That is the right path when counts are off, sampled queries look wrong, or the rebuild failed halfway through.

Accepted work is not search-visible completion. Durable enqueue is not backend completion. Backend completion is still not a stronger guarantee than the backend's visibility semantics. The docs, result envelopes, and workflow names all keep those distinctions visible because operator recovery depends on them.

## Observability

Phase 4 adds layered telemetry instead of flattening everything into one event family:

- `[:scrypath, :sync, ...]`, `[:scrypath, :search, ...]`, and `[:scrypath, :hydration, ...]` are the stable common-path spans.
- `[:scrypath, :meilisearch, :request, ...]` and `[:scrypath, :meilisearch, :task_wait, ...]` are explicit backend spans for request detail, task ids, poll counts, and wait outcomes.
- Oban job lifecycle remains on Oban's own telemetry events. Scrypath emits search semantics, not a second queue lifecycle.

## Deferred Work

Phase 5 intentionally still does not implement:

- public multi-backend query parity
- automatic drift detection or auto-rebuild triggers
- old-index cleanup as part of the same managed reindex step

Those workflows build on the contracts defined here instead of reshaping them later.
