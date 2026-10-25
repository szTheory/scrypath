# Sync Modes And Visibility

Scrypath, the Ecto-native search indexing library, makes sync mode explicit because search visibility is an operational concern, not hidden framework magic.

Meilisearch makes this unavoidable: document writes, settings updates, deletes, swaps, snapshots, and dumps are task-driven operations. A backend response can mean "task accepted" before the work is visible to a user's next search.

## The Contract

| Mode | Return boundary | What it does not mean |
|------|-----------------|------------------------|
| `:inline` | `:completed` when the backend returns a task handle and its wait reaches terminal success; otherwise `:accepted` | database and search writes are not atomic |
| `:manual` | `:accepted` when the backend accepts work | the document may not be searchable yet |
| `:oban` | the enqueue is durable | the backend write has not happened yet |

For `:oban`, the successful return status is `:accepted` when the durable enqueue succeeds; the backend write has not happened yet.

The exact successful map fields and conditional `:accepted` / `:completed` contract are documented on [**`Scrypath.sync_record/3`**](https://hexdocs.pm/scrypath/Scrypath.html#sync_record/3).

Accepted work is not the same thing as search visibility.

Read every sync result through that lens:

- database commit means the source of truth changed
- durable enqueue means Scrypath accepted responsibility to do work later
- backend accepted means Meilisearch accepted an async task
- terminal backend success means the tracked task finished
- visible search means a later query observes the updated projection

### Large id lists

Scrypath dedupes the ids and documents you pass and sends them in chunks of at most 1000, so one call never builds an unbounded backend request, database query or job. The chunk size is fixed.

- Chunks run in order. The call stops at the first failed chunk and returns that chunk's `{:error, reason}`; later chunks are not sent.
- Chunks already sent stay applied. Writes are idempotent by id (and an Oban retry reloads the current records), so retrying the whole call is safe.
- The result's `tasks:` lists one entry per chunk, in order, and `task:` is the last one. A call with 1000 ids or fewer has a one-element `tasks:` list.
- There is no ordering contract. Resolvers, loaders and `search_records/2` get deduped input (set semantics) in no promised order.
- The result's `document_ids` lists each id once, sorted by its string form (`[2, 10]` becomes `[10, 2]`), whatever the call size, and `document_count` counts distinct ids. Do not zip `document_ids` with the records or ids you passed.

## Operator lifecycle

`requested -> enqueued -> processing -> backend_accepted -> completed | retrying | discarded`

| State | Operator meaning | Not implied for search visibility |
|-------|------------------|-----------------------------------|
| `requested` | Work is queued for sync | Nothing is durable or visible in the index yet |
| `enqueued` | The system accepted responsibility to run the work | For `:oban`, this can stop at durable enqueue; search may still be stale |
| `processing` | A worker or inline path is actively driving backend work | Reads may still return older index state |
| `backend_accepted` | The backend acknowledged the write attempt | The document may still be behind on visibility or eventual indexing |
| `completed` | Terminal success for the tracked unit of work | Stale reads or drift can still exist across deployments |
| `retrying` | Work is being retried after a transient failure | Retries do not guarantee immediate search freshness |
| `discarded` | The operator path gave up on this unit of work | Deletes or tombstones may still need explicit recovery |

`:inline`, `:oban`, and `:manual` all move records along this same chain; they differ in **where your app usually observes progress**—before the caller returns, after durable enqueue, or only after you take the next manual step—not in the underlying lifecycle vocabulary. See the per-mode sections below for the exact return semantics and recovery posture.

## `:inline`

Use `:inline` when the write path should wait for terminal backend task success before it returns.

What you can see:

- backend success or failure before the caller continues
- for more than 1000 ids, Scrypath waits on each chunk's task before it sends the next chunk, and `inline_timeout` applies to each chunk's wait, not to the whole call
- `mix scrypath.status` for current backend visibility
- `mix scrypath.reconcile` when you suspect drift after a deployment or contract change

What can still fail:

- database and search writes are still not atomic
- later reads can still surface stale search hits if the contract changed
- inline sync of more than 1000 ids inside a request holds the request for several backend waits; that is a smell, so move bulk work to `:oban`

Recovery posture:

- retry explicit failed work if the original contract still holds
- backfill the live index when the index is still trustworthy
- reindex when mappings or settings changed and the live index should not be trusted

## `:oban`

Use `:oban` when durable enqueue matters more than immediate search visibility.

What you can see:

- the enqueue is durable
- queue backlog, retrying work, and failed jobs via `mix scrypath.status` and `mix scrypath.failed`
- report-first action guidance via `mix scrypath.reconcile`

What can still fail:

- the backend write may not have started yet
- retry exhaustion, discarded jobs, and stale deletes are operational cases, not surprises

Recovery posture:

- inspect retryable work first
- use `mix scrypath.retry` only with one explicit failed-work id
- move to backfill or reindex when the issue is larger than one queue replay

### What an Oban job carries

An Oban upsert job carries document ids, not document data. When the job runs, it loads the records as they are now, projects them, upserts the ones that exist, and deletes the documents whose rows are gone. This is the same approach Searchkick and Laravel Scout take, and it means a delayed job, an automatic Oban retry or an operator retry can never write an older copy over newer index data.

Tell Scrypath how to load records, from least to most effort:

```elixir
# Nothing extra when the search document only uses the row's own fields.
# Pass the repo when you sync (or configure it): it is stored on the job.
Scrypath.sync_record(MyApp.Catalog.Product, product, sync_mode: :oban, repo: MyApp.Repo)

# Declare the associations search_document/1 reads.
use Scrypath,
  fields: [:name, :category_name],
  preload: [:category]

# Full control: scoped repos, soft deletes, or ids that are not a column.
def search_records(ids, %{repo: repo}) do
  from(p in __MODULE__, where: p.id in ^ids and is_nil(p.deleted_at), preload: :category)
  |> repo.all()
end
```

Return only the records that should be searchable; Scrypath removes the rest from the index. Schemas that define `search_document_id/1` must define `search_records/2`, because a custom document id cannot be mapped back to a row. Scrypath raises at enqueue time when a job could not load its records later.

Backfill and managed reindex load each batch through the same `preload:` and `search_records/2` path as Oban sync, so they build the same documents. A live-index backfill also removes the ids `search_records/2` leaves out, but only ids from the rows it visits. Those deletes are accepted asynchronously, like the upserts: each batch result reports the delete under `delete_task` next to the upsert `task`, and `removed` counts the ids submitted for deletion. A page with more than 1000 documents or removed ids is written in chunks, one task per chunk: `tasks` lists every upsert chunk task and `delete_tasks` every delete chunk task, with `task` and `delete_task` as the last of each. Backfill does not wait on any of them, so follow every entry in `delete_tasks` as well as `tasks` when you need the removals applied. A managed reindex writes into a fresh index that never held those ids, so it reports them as `omitted` instead of deleting anything.

A backfill is not a whole-index prune. The default path, without `search_records/2`, never omits rows. Documents for rows deleted outside Scrypath, or for rows outside the visited `:query` scope, stay in the index until drift recovery (`Scrypath.reconcile_sync/2`) or a managed reindex handles them.

Delete jobs still carry only ids and never reload the deleted row.

Each job carries at most 1000 ids. A larger call enqueues one job per chunk, inserted together in one transaction, so either every chunk job is queued or none is; the result's `tasks:` lists one queued job per chunk. Each worker also writes to the backend in chunks of at most 1000. An identical job that is still pending (available, scheduled or retryable) is not inserted twice: the existing job is returned and reported with `conflict?: true`. `Scrypath.Oban.enqueue_upsert/5` and `Scrypath.Oban.enqueue_delete/5` still add one job per `Ecto.Multi` step, whatever its size; the worker bounds each backend write.

#### Call sync functions after your write commits

Call `Scrypath.sync_records/3`, `Scrypath.delete_documents/3` and `Scrypath.sync_related/3` after your transaction commits, in every sync mode, not from inside it:

- Under `:oban`, Scrypath collapses a sync into an identical pending job instead of inserting a second one (`conflict?: true`). That decision is made when you enqueue. Inside a transaction, the job you collapse into can start before your commit, load the old rows and finish, and no job is left to index your change.
- Under `:oban`, Oban also holds a lock on that unique job until your transaction ends. An identical sync from another process during that time reports `conflict?: true` and inserts nothing. If your transaction then rolls back, neither job exists and the other process's update is never indexed.
- Under `:inline`, the backend write runs immediately, so inside a transaction the backend would index rows that are not committed yet and may still roll back.

The trade-off: if your process crashes between the commit and the sync call, that sync is missed. The data is committed, so a retry of the call, a backfill or a managed reindex brings the index back in line; see [Drift recovery](drift-recovery.md) and the recovery posture for each mode above.

If you do call a sync function inside a transaction on the Oban repo, Scrypath won't break your transaction. It inserts the chunk jobs in your transaction instead of opening a nested one, and returns the first failed insert's `{:error, reason}` without rolling anything back, so fail your transaction on `{:error, _}` (returning the error from `Ecto.Multi.run/3` does that). The freshness hazards above still apply. They also apply to `Scrypath.Oban.enqueue_upsert/5` and `Scrypath.Oban.enqueue_delete/5`, which insert their job inside your `Ecto.Multi` by design.

#### Upgrading from 0.3.15 or earlier

Oban mode now needs a repo, either passed as `repo:` when you sync or configured under `:scrypath`. Without one, `Scrypath.sync_record/3` and friends raise and explain the fix. Upsert jobs queued by 0.3.15 or earlier still carry their document snapshot. From 0.3.17 they reload current records when a repo is available, and otherwise write the snapshot they carry, as before. Under 0.3.16 those jobs were cancelled when no repo was available. To avoid relying on either path, drain the `:scrypath` queue before upgrading.

Identical pending jobs are deduplicated. One narrow race remains: if two jobs for the same record load it at nearly the same moment, the one that finishes last wins, even if it loaded a moment earlier. Meilisearch has no conditional write to reject it, so the next change to that record corrects the document. Use a backfill when you need to settle a burst of concurrent writes immediately.

## `:manual`

Use `:manual` when operators or migration workflows should hold the next step explicitly.

What you can see:

- accepted backend work
- the current live/target index posture through `mix scrypath.reconcile`
- the same report-first guidance as the other modes

What can still fail:

- accepted work does not mean the document is searchable yet
- for more than 1000 ids, Scrypath sends every chunk without waiting on any task, so a successful `task:` does not prove that earlier chunks succeeded; check every entry in `tasks:`
- manual follow-up can drift from the source of truth if nobody closes the loop

Recovery posture:

- use status and reconcile to decide whether the live index is still sound
- prefer backfill when the contract is unchanged
- prefer reindex when the contract changed or rebuild visibility is already pointing at a target index

## Phoenix Implications

This wording matters in Phoenix because a controller response, JSON payload, or LiveView state update can easily over-promise what happened.

- A successful controller action can mean repo write succeeded while search visibility is still pending
- A LiveView update can reflect database state before async search work completes
- An Oban-backed flow means the durable enqueue succeeded, not that the search backend finished

The recommended boundary is still the same: let the context choose the mode, then let the controller or LiveView present the outcome honestly.

For user-facing copy, prefer language like "saved" or "queued for search indexing" over "now searchable" unless the path actually waited for terminal backend success and your product can tolerate any remaining eventual visibility edge.

## Where To Put The Decision

Choose sync mode in the context that owns the feature. That keeps consistency and recovery tradeoffs close to the repo write and close to the operator workflow that will respond when drift appears.

## Recovery Still Matters

Retries, stale deletes, and drift are normal operator concerns. When the live index contract is still correct, backfill into the live index. When the contract changed or you do not trust the live index, rebuild into a target index and review before cutover.

The thin CLI wrappers in `guides/operator-mix-tasks.md` exist to make those checks easy from a terminal, but the real operator contract still lives on `Scrypath.*`.

When a sync-semantics discussion starts to become a feature-scope argument, route that decision to `guides/scope-and-reopen-policy.md` instead of expanding sync-mode guidance into product policy.
