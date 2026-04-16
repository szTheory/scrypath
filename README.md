# Scrypath

Scrypath, the Ecto-native search indexing library, helps Phoenix and Ecto teams declare searchable schemas without hiding the operational work that keeps search in sync.

## Product Boundary

Scrypath v1 publicly targets Meilisearch first. The backend seam is internal, and v1 does not promise public multi-backend parity.

Phase 1 defines the schema declaration contract, projection behavior, and runtime reflection helpers. Search execution, synchronization workflows, Oban integration, and managed reindex orchestration land in later phases.

Projection changes and backend-setting changes can require reindex work once indexing flows are in place. Scrypath treats that as a normal operational concern, not hidden magic.

## Schema Declaration

```elixir
defmodule MyApp.Post do
  use Ecto.Schema

  use Scrypath,
    fields: [:title, :body],
    filterable: [:status],
    sortable: [:inserted_at]

  schema "posts" do
    field :title, :string
    field :body, :string
    field :status, Ecto.Enum, values: [:draft, :published]
    timestamps()
  end
end
```

`use Scrypath` is metadata-only. It validates the declaration and exposes stable `__scrypath__/1` reflection keys without generating schema-specific runtime verbs.

## Projection

By default, Scrypath projects the exact field list declared in `fields: [...]` and uses the configured document id field, which defaults to `:id`.

When a schema defines `search_document/1`, that hook takes precedence over the declarative field list:

```elixir
def search_document(post) do
  %{
    id: "post:#{post.id}",
    title: post.title,
    excerpt: String.slice(post.body || "", 0, 140)
  }
end
```

Association-derived data requires explicit loading before projection. Scrypath does not preload relationships or reach through unloaded data implicitly.

## Runtime Reflection

Phase 1 exposes a small reflective surface for later sync and query code:

- `Scrypath.schema_config/1`
- `Scrypath.schema_fields/1`
- `Scrypath.document_source/1`
- `Scrypath.document_id_field/1`

These helpers are intended to keep runtime code centralized under `Scrypath.*` modules instead of generating APIs such as `Post.search/2`.

## Sync

Phase 2 adds explicit context-level sync verbs under `Scrypath`:

- `Scrypath.sync_record/3`
- `Scrypath.sync_records/3`
- `Scrypath.delete_record/3`
- `Scrypath.delete_document/3`
- `Scrypath.delete_documents/3`

Call sync after successful repo persistence. Inline sync improves immediacy, but it does not make database and search writes atomic.

```elixir
post =
  %Post{}
  |> Post.changeset(attrs)
  |> Repo.insert!()

{:ok, result} =
  Scrypath.sync_record(Post, post,
    backend: Scrypath.Meilisearch,
    sync_mode: :inline
  )

result.mode
# :inline
```

`sync_mode: :inline` waits for terminal backend success before returning `{:ok, result}`. The returned result still includes Meilisearch task metadata so the backend's asynchronous execution is visible.

```elixir
{:ok, result} =
  Scrypath.sync_record(Post, post,
    backend: Scrypath.Meilisearch,
    sync_mode: :inline
  )

result.status
# :completed
```

`sync_mode: :manual` uses the same verbs, but returns accepted work immediately for imports, migrations, and operator-controlled flows.

```elixir
{:ok, result} =
  Scrypath.sync_records(Post, posts,
    backend: Scrypath.Meilisearch,
    sync_mode: :manual
  )

result.mode
# :manual

result.status
# :accepted
```

Delete flows use the schema's configured document id by default. When a record needs a different stable delete identity, define `search_document_id/1`. Use `Scrypath.delete_document/3` or `Scrypath.delete_documents/3` when no source struct is available.

```elixir
def search_document_id(post), do: "post:#{post.legacy_id}"
```

```elixir
{:ok, _result} =
  Scrypath.delete_document(Post, "post:123",
    backend: Scrypath.Meilisearch,
    sync_mode: :manual
  )
```

Common sync examples should stay explicit in your Ecto contexts rather than hidden behind callbacks or transaction hooks.

### Sync Mode Contract Matrix

| Mode | What Scrypath does before returning | Result shape meaning | What it does not mean |
|------|-------------------------------------|----------------------|-----------------------|
| `:inline` | waits for terminal backend task success before returning | `status: :completed` means the backend accepted and finished the write task | database and search visibility are not atomic |
| `:manual` | returns accepted backend work immediately | `status: :accepted` means Scrypath asked the backend to do the work | the document may not be searchable yet |
| `:oban` | returns durable enqueue acceptance only | `status: :accepted` means the job insert succeeded and a worker can process it later | the backend write has not happened yet, and the document may not be searchable |

`sync_mode: :oban` means durable enqueue accepted, not search visibility completed.

### Async Lifecycle

Scrypath uses one operator-facing lifecycle across inline waiting, manual control, and Oban-backed execution:

`requested -> enqueued -> processing -> backend_accepted -> completed | retrying | discarded`

- `requested` means your application asked Scrypath to sync or delete documents.
- `enqueued` means work was accepted by the next system in the chain: the backend task queue for `:manual`, or the Oban jobs table for `:oban`.
- `processing` means a worker or backend task is actively doing the write.
- `backend_accepted` means Meilisearch accepted the document or delete task and assigned backend task state.
- `completed` means the backend reported terminal success.
- `retrying` means the job or backend interaction failed transiently and another attempt is expected.
- `discarded` means retries are exhausted or the job was cancelled as impossible work.

retries, discarded jobs, stale deletes, and drift are normal operational realities. They are not edge cases to hide with optimistic wording.

For `sync_mode: :oban`, a successful return only means the enqueue is durable. Search visibility happens later when the worker runs and the backend task completes.

## Search

Phase 3 adds the common search path under `Scrypath.search/3` and `Scrypath.search!/3`.

```elixir
{:ok, result} =
  Scrypath.search(MyApp.Post, "ecto",
    backend: Scrypath.Meilisearch,
    repo: Repo,
    filter: [status: "published"],
    sort: [desc: :inserted_at],
    page: [number: 2, size: 20],
    preload: [:author]
  )

result.records
result.hits
result.missing_ids
result.page
```

The common path keeps the public query shape small: search text plus structured `filter:`,
`sort:`, and `page:` options. It rejects raw backend filter strings and other Meilisearch-native
payloads.

`repo:` is explicit. When you pass a repo, Scrypath runs one batch hydration query, restores
search hit order in Elixir, and surfaces stale rows through `missing_ids` instead of dropping
them silently. Raw backend hits remain available on the same result struct.

Use `Scrypath.Meilisearch.search/3` when you need native Meilisearch request payloads that do
not belong on the common path.

## Backfill And Reindex

Phase 5 adds two explicit operator workflows:

- `Scrypath.backfill/2` writes existing rows into one index in deterministic primary-key batches.
- `Scrypath.reindex/2` runs the managed rebuild workflow: create target index, apply settings, backfill, then optionally cut over.

Use backfill when the live index is still structurally correct and you need to load missing data into it, such as an initial import, a one-time repair after failed async work, or a recovery pass after a batch of stale deletes.

Use managed reindex when the search contract changed and the safest fix is to rebuild into a fresh target index first. Common drift causes are projection changes, schema setting changes such as searchable or sortable attributes, stale or discarded async work, or document-count mismatches that tell you the live index is no longer trustworthy.

```elixir
{:ok, result} =
  Scrypath.reindex(MyApp.Post,
    backend: Scrypath.Meilisearch,
    repo: Repo,
    batch_size: 500,
    cutover?: false
  )

result.live_index
result.target_index
result.settings_applied
result.batches
result.documents
result.cutover
```

`Scrypath.reindex/2` is explicit about what happened. It does not delete the old index in the same step, and it does not hide whether cutover happened.

### Drift Detection

Detect drift before deciding whether a live-index backfill is enough or whether you need a full rebuild. Common signals are:

- stale search hits whose hydrated records are now missing
- document-count mismatches between the source table and the search index
- failed, retrying, or discarded async sync work
- stale deletes where search still returns records removed from the database
- projection or setting changes that should have rewritten every document

If the drift is localized and the live index contract still matches the schema, backfill into the live index. If the contract changed or the blast radius is unclear, rebuild into a target index and review it before cutover.

### Cutover And Eventual Consistency

`cutover?: false` exists so operators can build and inspect a target index without moving traffic yet. That is the review window for document counts, sampled queries, relevance checks, and missing-record audits.

`cutover?: true` swaps the live and target indexes after settings application and backfill complete. That still does not mean every caller sees the new index immediately. Backend acceptance, durable enqueue, and even terminal backend success are not stronger guarantees than the backend can provide. Accepted work is not the same thing as search visibility, and durable enqueue is not the same thing as rebuild completion.

### Recovery

Recovery depends on the failure mode:

- failed or discarded sync work: rerun targeted sync or backfill for the affected scope
- stale deletes: issue explicit delete operations when you know the document ids, or backfill/rebuild if delete identity drift is broader
- incomplete rebuild with `cutover?: false`: fix the cause, rerun the rebuild into a fresh target index, and leave the live index untouched until the new target is trustworthy
- bad cutover to a known-good old index: use the backend-native swap again to move traffic back, then rebuild forward deliberately

Scrypath is blunt about this: eventual consistency, stale deletes, drift, and rebuild retries are normal operator work. They are not rare exceptions.

## Roadmap

Phase 1 establishes the declaration and projection contracts.

Phase 2 adds the Meilisearch-backed sync path for insert, update, delete, and manual workflows.

Phase 3 adds the common search API, filtering, sorting, pagination, and explicit hydration.

Phase 4 adds Oban-backed synchronization and Telemetry instrumentation.

Phase 5 adds reindex and operator workflows.

Phase 6 adds Phoenix-focused guides and release polish.
