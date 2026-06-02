# Meilisearch concepts for Scrypath adopters

This guide is for Phoenix and Ecto teams who are evaluating or adopting Scrypath and need enough Meilisearch context to make good decisions. It is not a replacement for the Meilisearch reference docs. It is the short mental model that keeps Scrypath usage honest.

The core model:

- Postgres or your primary store is the source of truth.
- Meilisearch is an async, denormalized search projection.
- Scrypath owns the projection, sync, rebuild, drift, and recovery workflow around that projection.

## The moving parts

| Term | What it means in a Scrypath app |
| --- | --- |
| Instance | A running Meilisearch service with one API surface, task queue, indexes, keys, snapshots, and dumps. |
| Index | A collection of JSON search documents with a UID, primary key, settings, and tasks. Treat it like a materialized search read model. |
| Document | The denormalized JSON shape Meilisearch stores. It is not your Ecto struct and should not contain sensitive fields unless you intend to return them from search. |
| Primary key | The stable document identity. Re-sending a document with the same key updates the stored search document. |
| Settings | The search contract for an index: searchable, filterable, sortable, displayed attributes, ranking rules, synonyms, stop words, typo tolerance, facets, and related knobs. |
| Task | Meilisearch's async unit of work. Index creation, settings updates, document writes, deletes, swaps, dumps, and snapshots return task references before the work is necessarily visible. |
| Snapshot | Fast same-version backup of the database. Useful for ordinary restore. Not the migration path across versions. |
| Dump | Portable export for migration and upgrades. Slower to import because Meilisearch reprocesses data. |
| API key | Scoped credential for search, indexing, settings, or task access. The master key should be reserved for key management. |
| Tenant token | Search-time restriction token for direct browser/client search against shared indexes. Server-side Phoenix searches usually keep tenant enforcement in the app boundary. |

Meilisearch's own docs cover these surfaces in detail: [tasks](https://www.meilisearch.com/docs/learn/async/asynchronous_operations), [backups](https://www.meilisearch.com/docs/resources/self_hosting/data_backup/overview), [storage](https://www.meilisearch.com/docs/learn/engine/storage), and [API keys](https://www.meilisearch.com/docs/learn/security/differences_master_api_keys).

## Documents are projections

The document you index should be shaped for search, not copied from the database.

```elixir
use Scrypath,
  fields: [:title, :body],
  filterable: [:tenant_id, :status, :category_id],
  sortable: [:price_cents, :inserted_at],
  displayed: [:id, :title, :price_cents, :status]
```

That declaration says what the search index needs to know. Your Ecto schema still owns validation, relationships, authorization, and durable state.

Two common rendering styles are valid:

- **Fast UI mode:** index safe display fields and render lightweight search cards directly from hits.
- **Strict mode:** ask Meilisearch for IDs, hydrate records from Postgres, enforce authorization in the repo query, and preserve hit order.

Use strict mode when records are tenant-sensitive, visibility changes often, or search documents would otherwise carry private data.

## Accepted is not visible

Most Meilisearch writes are asynchronous. A document update or settings change usually means:

1. Meilisearch accepted a task.
2. The task waits in the queue.
3. The task processes.
4. The task succeeds, fails, or is canceled.

That means these statements are different:

- the Ecto transaction committed
- Scrypath accepted or enqueued sync work
- Meilisearch accepted the backend task
- the task reached terminal success
- a user's next search sees the new projection

Scrypath's sync modes name this instead of hiding it. Use [Sync modes and visibility](sync-modes-and-visibility.md) for the exact `:inline`, `:oban`, and `:manual` contract.

## Settings are migrations

Settings are the shape of the index. Some changes are small operational tweaks, but many affect how Meilisearch builds internal search structures. Meilisearch documents that updates such as `filterableAttributes` and `searchableAttributes` can require reindexing all documents.

The safe habit:

1. Declare settings in code.
2. Create the index explicitly.
3. Apply settings before the first import.
4. Diff declared settings against the live index.
5. Use managed reindex when the contract changed.

Do not discover after importing millions of documents that a tenant, status, category, or sort field should have been declared. If the change affects the index contract, treat it like a database migration with a rehearsal and rollback plan. Use [Relevance tuning](relevance-tuning.md) for Scrypath's settings and drift semantics.

## Search is not the source of truth

Meilisearch is fast because it precomputes and stores search-oriented structures. That is the point. It is also why it should not become the authoritative place for business state.

Prefer these boundaries:

- Write durable business data to Postgres first.
- Sync search documents after successful persistence.
- Keep upserts idempotent by stable primary key.
- Hydrate sensitive records from Postgres when search visibility alone is not enough.
- Rebuild from Postgres when projection or settings drift makes the live index untrusted.

If search gets strange and a rebuild from source-of-truth data cannot fix it, the bug is usually in projection shape, settings, filtering, or authorization policy.

## Operational truths worth knowing

Meilisearch is intentionally simple to stand up, but it is still a stateful service.

- It stores data in LMDB and leans on memory-mapped I/O and the OS page cache.
- Fast local or block storage matters; do not put the live database on S3FS, NFS, or slow network storage.
- Indexing competes for CPU, RAM, disk, and task queue capacity.
- Lots of tiny writes can become task queue debt.
- Full rebuilds need disk headroom because the old and new index can coexist during the cutover window.
- Version upgrades need a deliberate backup/import story; do not run unpinned `latest` in production.

Use [Meilisearch operations](meilisearch-operations.md) for deployment, backup, upgrade, capacity, and production checklist guidance. Use [Search backend operations](../docs/search-backend-sre.md) when you need SRE-oriented signals and alerting posture.

## What to read next

- First working schema: [Golden path](golden-path.md)
- Sync semantics: [Sync modes and visibility](sync-modes-and-visibility.md)
- Settings and drift: [Relevance tuning](relevance-tuning.md)
- Tenant safety: [Multitenancy](multitenancy.md)
- Production posture: [Meilisearch operations](meilisearch-operations.md)
- Incident triage: [Drift recovery](drift-recovery.md)
