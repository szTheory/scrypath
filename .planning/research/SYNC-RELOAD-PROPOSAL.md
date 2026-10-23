# Proposal: Oban sync jobs carry IDs and load current records when they run

Status: proposed 2026-10-22, awaiting maintainer approval. It replaces the narrower Q18 option (a callback used only by operator Retry) in `.planning/UI-FEEDBACK.md`.

## The problem in one paragraph

An Oban upsert job stores a full copy of each search document, taken when the job is queued (`lib/scrypath/oban/payload.ex:8-25`). The worker sends that copy to Meilisearch without reading the database (`upsert_worker.ex:49-109`; a test even pins this: `test/scrypath/oban/worker_test.exs:72-98`). Three things then go wrong:

- **Operator Retry** resends the old copy (`recovery_action.ex:44-61`).
- **Oban's own automatic retries** (up to 8 attempts) resend the old copy.
- **Concurrent jobs** for the same record (queue concurrency 5–10, no `unique:`) can finish out of order. An older copy that lands last overwrites newer data, and Meilisearch replaces the whole document.

So search can quietly show outdated data even when every job "succeeded". The project already recorded this as a known gap (`.planning/research/v1.40/C09-DELETE-VISIBILITY.md:117`). Fixing only the Retry button would leave the other two paths broken.

## How the field solves this (primary sources)

| Library | What the job carries | What happens when it runs | Deleted rows |
| --- | --- | --- | --- |
| Searchkick (Ruby) | class, id, index | Reloads the record with the `search_import` scope (where eager loading lives), re-checks `should_index?` | Missing or ineligible → delete |
| Laravel Scout (PHP) | model IDs (`SerializesModels`) | Re-fetches; `makeSearchableUsing` hook for eager loading | `RemoveFromSearch` builds stubs from IDs; never fails on a missing row |
| meilisearch-rails / algoliasearch-rails | record GlobalID | Re-fetched at execution | Learned the hard way: deleting a record broke the job; now the remove job carries only index + primary key |
| Hibernate Search (Java) | entity ID in an outbox table, same transaction | "Completely reloads entities from the database"; one processor per shard so the same entity never races | Aborted events can be reprocessed (the equivalent of operator Retry) |
| django-elasticsearch-dsl | pk + model | Re-reads in the Celery task "to ensure eventual consistency" | Delete actions computed before the row disappears |
| Sidekiq best practices / Oban maintainers | "save simple identifiers", "use resource ids and fetch records in the job" | | |

Elasticsearch can also reject stale writes with external versioning (`version_type=external`). **Meilisearch has no equivalent** (no conditional write or version check), so Scrypath can't guard against staleness on the search side; it has to send current data.

**The convention is unanimous:** queue IDs, load and project current data when the job runs, give the app one hook for eager loading and scoping, treat a missing row as a delete, and give delete jobs only the IDs.

## Why Scrypath did it differently, and why that should change now

Phase 4 chose snapshots deliberately (`git show c345e194:.planning/phases/04-oban-and-observability/04-CONTEXT.md`):

- D-07: jobs carry projected documents.
- D-09: projection stays in explicit app-side code, “not hidden worker reload logic”.
- Reloading in workers was deferred because it conflicted with the “no hidden preloads” rule (`projection.ex:9-11`).

It was never weighed against stale retries. Scrypath's own research prompts recommend the ID approach (`prompts/elixir-search-lib-deep-research.md:129-133`). Scrypath has also already adopted the pattern for related-data fan-out: those jobs carry only IDs and call an app-provided resolver that reloads with the right preloads and tenant handling (`sync/related_enqueue.ex:53-72`, `related_worker.ex:44-48`, documented in `guides/related-data-and-reindexing.md:184-224`). So moving upserts to the same model makes the library *more* internally consistent, not less. The “no hidden preloads” value is kept by making loading explicit and declared, not implicit.

The library isn't released to adopters yet, so changing job args now costs no migration for anyone.

## Recommendation

### 1. Jobs carry IDs, not documents

- **Upsert job args:** `schema`, `document_ids`, `index`, `backend` (and the existing URL/prefix context). No `documents`.
- **Delete job args:** unchanged (IDs + index). Deletes never reload; they delete by ID (D-08 stays, and it matches every library above).
- Smaller jobs, and no copies of row data sitting in `oban_jobs`.

### 2. The worker loads current records through one explicit, declared seam

What the app writes, from least to most effort:

```elixir
# Zero extra config when the search document only uses the row's own fields.
use Scrypath, fields: [:name, :description]

# Declare what the projection needs; Scrypath loads by ID with these preloads.
use Scrypath,
  fields: [:name, :description, :category_id],
  preload: [:category]                       # like Searchkick's search_import / Scout's makeSearchableUsing

# Full control (tenancy rules, soft deletes, custom scopes): an optional callback
# next to the existing optional search_document/1.
@impl Scrypath
def search_records(ids, _context) do
  from(p in __MODULE__, where: p.id in ^ids, preload: :category)
  |> Repo.all(skip_tenant_id: true)
end
```

- The default loader is `repo.all(from r in schema, where: field(r, ^document_id_field) in ^ids, preload: ^preload)`, using the `repo` that's already in the sync config.
- `search_records/2` replaces the default when defined. It's the same seam the fan-out resolver already uses, phrased the same way as `search_document/1`, so it's familiar.
- If document IDs aren't a column (custom `search_document_id/1` or a computed `:id`), the default loader can't map them back. Scrypath raises a clear error when the schema is used with Oban sync without `search_records/2`. That's an early failure with a fix-it message, not a silent wrong result.

### 3. What a job does with the loaded records

- Records found → project with `search_document/1` (or declared fields) → upsert.
- IDs not found → delete those documents (the Searchkick/Scout behavior: “the row is gone, so it shouldn't be searchable”).
- Loader raises (DB down, tenant rule) → the job errors and Oban retries it normally; the Failed sync page shows the real reason.

### 4. Retry becomes simple and always correct

- **Operator Retry** on a failed upsert or delete enqueues a fresh job with the same IDs. Because jobs load current data, retry can't roll anything back. No snapshot warning, no special path.
- **Oban's automatic retries** get the same guarantee for free.
- Inline and manual mode retries keep requiring the caller's records or IDs (unchanged).

### 5. Ordering and duplicate work

- Add Oban `unique` on `[:worker, :args]` for the `available`/`scheduled`/`retryable` states, so an identical pending batch isn't queued twice.
- Remaining race, documented plainly: job A loads, job B loads newer data and writes, then A writes. A's data was current when it loaded, and the next change triggers another job. Fully closing it needs per-record serialization (Hibernate's sharding, or Oban Pro partitioning), which is out of scope. The docs say so, in line with the project's “eventual consistency stated honestly” value.

### 6. Knock-on changes (blast radius, from the code survey)

- **Core:** `payload.ex`, `upsert_worker.ex`, `oban.ex` (the `Ecto.Multi` helper queues IDs inside the transaction; projection now happens after commit, which is more correct), `recovery_action.ex`, `failed_work/translation.ex:104-110` (an upsert is retryable when it has `document_ids`).
- **ScrypathOps verification:** “did the retry work?” currently compares the index with the stored copy (`document_observation.ex`, `sync_drift_live.ex:1066-1092`). It becomes: the new job succeeded, and each ID is present in the index (or absent, for rows that no longer exist), optionally compared with a freshly loaded projection.
- **Demo:** Product declares `preload: [:category]`. Because its Repo enforces tenant scoping, Product and Variant define `search_records/2` with an explicit tenant decision. The seeded “n/a” failure incident and `e2e_recovery.ex` are rewritten around ID-only jobs. The incident's error text is synthetic and its stored copy would actually overwrite a real product today, so the rewrite also removes a hidden demo bug.
- **Tests:** about a dozen files pin snapshot behavior. They're rewritten, and the test named “writes serialized documents without reloading source rows” becomes its opposite, plus a regression test that a retried old job can't overwrite newer data.
- **Docs:** sync-modes, drift-recovery and related-data guides, `ARCHITECTURE.md`, the `search_records/2` and `preload:` docs, a CHANGELOG entry, and a `PROJECT.md` decision note superseding D-07/D-09.

### 7. Explicitly not doing

- Snapshot + “check the index version first” (racy without Meilisearch support, and still wrong for deletes).
- A transactional outbox table (Hibernate-style). It's strong but heavy, and Oban jobs inserted in the same `Ecto.Multi` already give commit-atomic queuing. It could come back later as an opt-in if adopters need coalescing.
- Re-checking an “eligible for search” rule at load time: Scrypath has no `should_index?` concept yet. Worth a seed, not this change.

## Sequencing

This is a core library change with real reach. Ship it as **its own PR first**, then the UI batch on top. The Failed sync redesign (CONTENT-42, UI-60–63) then only needs one plain sentence about what Retry does, with no snapshot warning state to design.

## Decisions for the maintainer

1. Approve the ID-and-load design (sections 1–4) as the replacement for snapshots.
2. Approve the app-facing shape: `preload:` option plus the optional `search_records/2` callback.
3. Approve the two-PR sequence (library change first, UI batch second).
