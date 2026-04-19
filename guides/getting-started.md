# Getting Started

Scrypath gives Phoenix and Ecto teams an explicit path for declaring searchable schemas, syncing search documents, and querying through one context-owned boundary.

For a **hands-on linear onboarding** checklist from dependencies through your first `Scrypath.search/3` with inline sync, follow the [Golden path](golden-path.md).

## What You Set Up

Start with three pieces:

1. A schema that declares search metadata with `use Scrypath`
2. A context that owns repo persistence plus `Scrypath.*` orchestration
3. A backend configuration that keeps sync mode explicit, plus Oban only if you want queued sync

## Declare A Searchable Schema

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

`use Scrypath` stays metadata-only. Runtime orchestration still lives in your context modules.
Scrypath also owns its internal transport dependency, so the base install path stays focused on adding `:scrypath`.

## Put Search And Sync In The Context

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

That keeps reads, writes, sync decisions, and failure handling in one application boundary instead of spreading them across controllers or LiveView callbacks.

## Keep Web Modules Thin

Controllers and LiveView modules call the same context boundary:

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

```elixir
defmodule MyAppWeb.PostLive do
  use MyAppWeb, :live_view

  alias MyApp.Content

  def handle_params(%{"q" => query}, _uri, socket) do
    {:ok, result} = Content.search_posts(query, preload: [:author])

    {:noreply, assign(socket, posts: result.records, search: result, query: query)}
  end
end
```

## Choose Sync Mode Deliberately

- `:inline` waits for terminal backend success before returning
- `:manual` returns accepted backend work immediately for imports and operator-driven flows
- `:oban` returns durable enqueue acceptance only and is an optional production path when you want queued sync

Accepted work is not the same thing as search visibility. Pick the mode that matches your consistency and operational constraints.

## Continue

- Read [Phoenix Walkthrough](phoenix-walkthrough.html) for the first end-to-end path
- Read [Phoenix Contexts](phoenix-contexts.html) for the recommended boundary shape
- Read [Sync Modes And Visibility](sync-modes-and-visibility.html) before choosing `:manual` or `:oban`
