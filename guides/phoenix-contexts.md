# Phoenix Contexts

Scrypath fits Phoenix best when your context is the application-facing boundary for search orchestration.

If you want shared controller and LiveView glue for browser-shaped params, keep that glue in `Scrypath.Phoenix`. It delegates to `Scrypath.QueryParams` and stops at plain data, URL params, and renderable edge errors.

## What Belongs In The Context

Keep these responsibilities in the context:

- repo persistence
- explicit calls to `Scrypath.sync_record/3`, `Scrypath.sync_records/3`, or delete verbs
- `Scrypath.search/3` calls plus repo-backed hydration policy
- preload, filter, sort, and paging defaults that belong to the feature
- error handling and operator-visible sync semantics

## What Stays Out Of Controllers And LiveView

Do not teach controllers or LiveView modules to compose raw `Repo` and `Scrypath.*` calls as the main pattern.

That boundary matters because Phoenix web modules should stay focused on HTTP or UI concerns, while the context owns feature logic and operational decisions.

## Example

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

`MyApp.Content.search_posts/2` is the shared read path for controllers and LiveView. `MyApp.Content.publish_post/2` is the write path that owns the sync decision.

## Why This Boundary Holds Up

- controllers stay thin
- LiveView state stays UI-focused
- sync failures and rebuild decisions stay close to the feature that owns them
- docs and snippets can derive from one canonical example instead of teaching competing architectures
