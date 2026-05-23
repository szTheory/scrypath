# Golden path: first indexed document and first search

If you prefer the conceptual overview first, read [Getting Started](getting-started.md). This guide is a **linear checklist** from dependency install through a working `Scrypath.search/3` using **`sync_mode: :inline`** only. Queueing and manual sync are intentionally deferred to [Sync Modes and Visibility](sync-modes-and-visibility.md) (`guides/sync-modes-and-visibility.md`).

If you want the shared request-edge story for browser params, `Scrypath.QueryParams`, optional `Scrypath.Phoenix`, and context-owned runtime calls, read [Request-edge search](request-edge-search.md). This guide stays focused on the first indexed document and first search.

When you need **`Scrypath.search_many/2`**, federation weights, or **`:all`** expansion across several schemas, read next: [Multi-index search](multi-index-search.md).

## Goal

By the end of this path you will have Meilisearch running locally, minimal application configuration pointing Scrypath at it, a searchable Ecto schema, and one context-owned function pair: **`Scrypath.sync_record/3`** after a successful repo write and **`Scrypath.search/3`** returning hydrated records. The first hour stays **inline** so success in your function means the backend finished the write—not that database and search are a single atomic transaction.

## Dependencies

Add Scrypath to your app’s `mix.exs`:

```elixir
def deps do
  [
    {:scrypath, "~> 0.3"}
  ]
end
```

Run `mix deps.get`. The minor-flexible range matches published **0.3.x** releases; bump the constraint when you intentionally adopt a new minor.

## Bring up Meilisearch

Scrypath’s v1 story assumes Meilisearch. For a stack aligned with this repository’s CI and example app, use Docker Compose from **`examples/phoenix_meilisearch/`** (image **`getmeili/meilisearch:v1.15`**, default URL **`http://127.0.0.1:7700`**):

```bash
cd path/to/examples/phoenix_meilisearch
docker compose up -d
```

Set **`SCRYPATH_MEILISEARCH_URL`** to your Meilisearch base URL if it is not the default (for example `export SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700`).

For a full Phoenix + Postgres smoke (fixtures, scripted test), follow [examples/phoenix_meilisearch/README.md](../examples/phoenix_meilisearch/README.md) (repository path `examples/phoenix_meilisearch/README.md`).

For where Meilisearch fits in production (networking, keys, backups vs rebuilding from Postgres), read [Meilisearch operations for Scrypath adopters](meilisearch-operations.md).

## Application config

Point your **otp_app** at Meilisearch in **`config/runtime.exs`** or **`config/dev.exs`** (pick the file your team uses for local secrets):

```elixir
import Config

config :my_app, :scrypath,
  meilisearch_url: System.get_env("SCRYPATH_MEILISEARCH_URL") || "http://127.0.0.1:7700"
```

Wire that into Scrypath’s backend configuration wherever you centralize runtime options (see [Getting Started](getting-started.md) for the shape: **backend module** + explicit **`sync_mode`** at call sites). Use placeholders for URLs in docs you commit; never embed real API keys.

## Schema

Declare search metadata on the Ecto schema with **`use Scrypath`**:

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
    field :status, :string
    timestamps()
  end
end
```

`use Scrypath` is metadata-only; persistence and sync stay in your context.

In production you may still enforce allowed values with **`validate_inclusion/3`** or **`Ecto.Enum`** on changesets; this guide keeps **`field :status, :string`** in the schema so Meilisearch filters stay string-shaped (for example **`status = "published"`**) and match the example app.

## Context: inline sync and search

Own both repo writes and Scrypath calls from one context module:

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

  defp update_post(post, attrs) do
    post
    |> Post.changeset(attrs)
    |> Repo.update()
  end
end
```

`sync_mode: :inline` means the call waits for terminal backend success before returning. It still does not make the database write and the search write atomic—operational honesty matters when you reason about failures.

## Proof of search (IEx)

After you have migrated data (or inserted a row in dev), prove search from **`iex -S mix`**:

```elixir
alias MyApp.Content

{:ok, result} = Content.search_posts("hello", [])
result.records
```

Index-time relevance tuning lives in [Relevance tuning](relevance-tuning.md); request-time search options are specified in the [Per-query tuning pipeline](per-query-tuning-pipeline.md) guide.

For controllers, JSON APIs, and LiveView that call the same context boundary, continue with [Phoenix Walkthrough](phoenix-walkthrough.md).

## Integration smoke (Postgres + Meilisearch + Oban)

The golden path stays **inline** on purpose. To **run** the multi-container proof (inline + **`:oban`** integration tests, same Meilisearch image pin as CI), use the runnable example—do not duplicate env tables here:

- **Runbook (from **`examples/phoenix_meilisearch/`** — commands, env vars, **`./scripts/smoke.sh`**):** [`examples/phoenix_meilisearch/README.md`](../examples/phoenix_meilisearch/README.md)
- **CI:** On **pull requests** and pushes to **`main`**, **GitHub Actions** runs job **`phoenix-example-integration`**, which starts **Postgres 16** (`postgres:16-alpine`) and **Meilisearch** (`getmeili/meilisearch:v1.15`) as workflow services, sets **`SCRYPATH_EXAMPLE_INTEGRATION=1`**, **`PGPORT=5433`**, and **`SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700`**, then runs **`cd examples/phoenix_meilisearch && mix deps.get && mix test`**—the same consumer-shaped **`mix test`** path the example README documents for local Compose. For job names, env vars, and how they map to **`mix verify.*`** tasks, see root [`CONTRIBUTING.md`](../CONTRIBUTING.md).

## Ecto without Phoenix (API-only)

You do not need `MyAppWeb` modules. The same context-owned pattern applies in an API-only app: call **`Scrypath.sync_record/3`** after **`Repo.insert` / `Repo.update`** succeeds, and expose **`Scrypath.search/3`** through functions you call from plugs or bounded contexts. Use `examples/phoenix_meilisearch/README.md` as the entry to the minimal consumer-shaped reference (the example is Phoenix, but the search boundary is still “context owns Scrypath”).

## What is next

- **Sync modes:** When you outgrow inline sync for throughput or durability, read [Sync Modes and Visibility](sync-modes-and-visibility.md) (`guides/sync-modes-and-visibility.md`) for **`:oban`** and **`:manual`**, operator lifecycle states, and recovery language. Production often uses **`:oban`**; the first hour above stays **inline** on purpose.
- **Oban:** If you choose **`:oban`**, add Oban as a dependency and follow its installation guides; Scrypath stays explicit about enqueue vs visibility—see the sync guide for the contract.
