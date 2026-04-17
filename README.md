# Scrypath

Scrypath, the Ecto-native search indexing library, helps Phoenix and Ecto teams add search to existing schemas without hiding the operational work that keeps search in sync.

## Installation

Add Scrypath to your dependencies:

```elixir
def deps do
  [
    {:scrypath, "~> 0.1.0"}
  ]
end
```

Scrypath v1 publicly targets Meilisearch first. The backend seam is internal, and v1 does not promise public multi-backend parity.
Scrypath owns its internal transport dependency. Configure backend and sync behavior in your app code instead of pinning `Req` directly in the base install path.
If you want queued sync, add Oban as an optional production integration when you choose `sync_mode: :oban`.

## Quick Path

Start with one searchable schema and one Phoenix context that owns both repo persistence and Scrypath orchestration.

```elixir
defmodule MyApp.Blog.Post do
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

```elixir
defmodule MyApp.Content do
  alias MyApp.Blog.Post
  alias MyApp.Repo

  def search_posts(query, opts \\ []) do
    Scrypath.search(Post, query,
      Keyword.merge([backend: Scrypath.Meilisearch, repo: Repo], opts)
    )
  end

  def publish_post(post, attrs) do
    with {:ok, post} <- update_post(post, attrs),
         {:ok, _sync} <-
           Scrypath.sync_record(Post, post,
             backend: Scrypath.Meilisearch,
             sync_mode: :inline
           ) do
      {:ok, post}
    end
  end
end
```

```elixir
defmodule MyAppWeb.PostController do
  use MyAppWeb, :controller

  alias MyApp.Content

  def index(conn, params) do
    {:ok, result} =
      Content.search_posts(Map.get(params, "q", ""),
        filter: [status: "published"]
      )

    render(conn, :index, posts: result.records, search: result)
  end
end
```

That is the recommended shape throughout the docs: schema metadata on the Ecto schema, search orchestration in the context, and thin Phoenix web modules calling the same context boundary.

## When Scrypath Fits

Scrypath is a good fit when you want:

- search indexing that feels native to Ecto instead of bolted onto a controller or callback maze
- one explicit place to choose between inline, manual, and Oban-backed sync
- repo-backed hydration through the common `Scrypath.search/3` path
- first-class backfill and managed reindex workflows when drift or schema changes happen

## When It Does Not

Scrypath is not trying to be:

- a Postgres full-text abstraction
- a Phoenix-only library
- a public multi-backend facade in v1
- a callback-heavy "it just stays in sync somehow" runtime

If you want hidden model hooks, implicit repo access, or a library that pretends accepted work means immediate search visibility, this is the wrong tool.

## Phoenix Wayfinding

If you are wiring Scrypath into a Phoenix app, read these next:

- [Getting Started](guides/getting-started.md)
- [Phoenix Walkthrough](guides/phoenix-walkthrough.md)
- [Phoenix Contexts](guides/phoenix-contexts.md)
- [Phoenix Controllers and JSON](guides/phoenix-controllers-and-json.md)
- [Phoenix LiveView](guides/phoenix-liveview.md)
- [Sync Modes and Visibility](guides/sync-modes-and-visibility.md)
- [Operator Mix Tasks](guides/operator-mix-tasks.md)

The walkthrough uses one context-owned search flow and carries that same boundary through controllers and LiveView.

## Public Surface

Scrypath keeps one common runtime surface and one explicit backend-specific escape hatch:

- `Scrypath` for runtime reflection, sync verbs, operator visibility, backfill, managed reindex, and the common search path
- `Scrypath.Schema` for the declaration contract
- `Scrypath.Projection` for document projection rules
- `Scrypath.Meilisearch` for backend-native operations that do not belong on the common path

Backfill and managed reindex now use the same internal operations seam as sync, but that seam stays private. The public backend-native namespace remains `Scrypath.Meilisearch.*`.

The operator surface also stays on `Scrypath.*`:

- `Scrypath.sync_status/2`
- `Scrypath.failed_sync_work/2`
- `Scrypath.retry_sync_work/2`
- `Scrypath.reconcile_sync/2`

For terminal-first operations, the thin `mix scrypath.status`, `mix scrypath.failed`,
`mix scrypath.retry`, and `mix scrypath.reconcile` tasks wrap those same root APIs.
They do not create a second operator product surface.

`use Scrypath` is metadata-only. It validates the declaration and exposes stable `__scrypath__/1` reflection keys without generating schema-specific runtime verbs.

## Sync Modes

Call sync after successful repo persistence. Scrypath is explicit about what each mode means:

| Mode | What Scrypath does before returning | What it does not mean |
|------|-------------------------------------|-----------------------|
| `:inline` | waits for terminal backend task success before returning | database and search writes are not atomic |
| `:manual` | returns accepted backend work immediately | the document may not be searchable yet |
| `:oban` | returns durable enqueue acceptance only | the backend write has not happened yet, and the document may not be searchable |

Accepted work is not the same thing as search visibility.

`sync_mode: :oban` means durable enqueue accepted, not search visibility completed.

All three modes share one operator-facing lifecycle:

`requested -> enqueued -> processing -> backend_accepted -> completed | retrying | discarded`

In practice, retries, discarded jobs, stale deletes, and drift are normal operational realities. They are not edge cases to hide with optimistic wording.

## Search

The common search path stays small and explicit:

```elixir
{:ok, result} =
  Scrypath.search(MyApp.Blog.Post, "ecto",
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

Hydration is explicit and repo-backed. Scrypath does not infer repos globally or hide stale rows when search hits no longer match the database.

## Backfill And Reindex

Scrypath treats repair and rebuild work as first-class operator workflows:

- `Scrypath.backfill/2`
- `Scrypath.reindex/2`

Use backfill when the live index contract is still correct and you need to repair missing or stale documents.

Use managed reindex when the contract changed, settings changed, or you no longer trust the live index contents.

```elixir
{:ok, result} =
  Scrypath.reindex(MyApp.Blog.Post,
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

`cutover?: false` leaves the live index untouched while you inspect the rebuilt target.

## Drift Detection And Recovery

Detect drift before deciding whether a live-index backfill is enough or whether you need a full rebuild. Common signals are:

- stale search hits whose hydrated records are now missing
- document-count mismatches between the source table and the search index
- failed or discarded sync work
- stale deletes where search still returns records removed from the database
- projection or setting changes that should have rewritten every document

Accepted work is not the same thing as search visibility, and durable enqueue is not the same thing as rebuild completion.

Use `Scrypath.sync_status/2` and `Scrypath.failed_sync_work/2` when you need to inspect pending, retrying, failed, or last-successful work without reading raw Meilisearch or Oban payloads.

Use `Scrypath.reconcile_sync/2` when you need a report-first operator view that combines sync visibility, failed work, and rebuild visibility before you decide on recovery.

`Scrypath.reconcile_sync/2` does not heal anything by default. It returns drift signals plus explicit recovery actions so the caller can choose retry, backfill, or reindex deliberately.

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for the full runtime boundary, sync guarantees, drift model, and managed reindex workflow order.

For operational guides, see [Sync Modes and Visibility](guides/sync-modes-and-visibility.md),
[Operator Mix Tasks](guides/operator-mix-tasks.md), and
[Operator Support](docs/operator-support.md).
