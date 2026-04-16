# Getting Started

Scrypath gives Phoenix and Ecto teams an explicit path for declaring searchable schemas, syncing search documents, and querying through one context-owned boundary.

## What You Set Up

Start with three pieces:

1. A schema that declares search metadata with `use Scrypath`
2. A context that owns repo persistence plus `Scrypath.*` orchestration
3. A backend configuration that keeps sync mode explicit

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

## Keep Search In The Context

```elixir
defmodule MyApp.Content do
  alias MyApp.Blog.Post
  alias MyApp.Repo

  def create_post(attrs) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, post} ->
        Scrypath.sync_record(Post, post,
          backend: Scrypath.Meilisearch,
          sync_mode: :inline
        )

      error ->
        error
    end
  end
end
```

That keeps database writes, sync decisions, and failure handling in one application boundary instead of spreading them across controllers or LiveView callbacks.

## Choose Sync Mode Deliberately

- `:inline` waits for terminal backend success before returning
- `:manual` returns accepted backend work immediately for imports and operator-driven flows
- `:oban` returns durable enqueue acceptance only

Accepted work is not the same thing as search visibility. Pick the mode that matches your consistency and operational constraints.

## Continue

- Read [Phoenix Walkthrough](phoenix-walkthrough.html) for the first end-to-end path
- Read [Phoenix Contexts](phoenix-contexts.html) for the recommended boundary shape
- Read [Sync Modes And Visibility](sync-modes-and-visibility.html) before choosing `:manual` or `:oban`
