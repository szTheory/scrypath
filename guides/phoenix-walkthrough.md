# Phoenix Walkthrough

This walkthrough shows the recommended adoption path for Scrypath in a Phoenix app: searchable schema, context-owned search boundary, controller call, LiveView call, and explicit sync visibility choices.

## 1. Start With The Context Boundary

Put search orchestration in a Phoenix context, not in controllers and not in LiveView modules.

```elixir
defmodule MyApp.Content do
  alias MyApp.Blog.Post
  alias MyApp.Repo

  def search_posts(query, opts \\ []) do
    Scrypath.search(Post, query,
      Keyword.merge(
        [backend: Scrypath.Meilisearch, repo: Repo],
        opts
      )
    )
  end
end
```

The context owns repo-backed hydration, backend choice, sync mode choice, and any preload policy.

## 2. Call That Boundary From Controllers

Controllers translate request params into a context call and render a response. They should not compose raw `Repo` and `Scrypath.*` operations as the recommended pattern.

```elixir
defmodule MyAppWeb.PostController do
  use MyAppWeb, :controller

  alias MyApp.Content

  def index(conn, params) do
    query = Map.get(params, "q", "")

    {:ok, result} =
      Content.search_posts(query,
        filter: [status: "published"]
      )

    render(conn, :index, posts: result.records, search: result)
  end
end
```

## 3. Reuse The Same Context From LiveView

LiveView owns UI state. The context still owns repo access and Scrypath orchestration.

```elixir
defmodule MyAppWeb.PostLive.Index do
  use MyAppWeb, :live_view

  alias MyApp.Content

  def handle_params(%{"q" => query}, _uri, socket) do
    {:ok, result} = Content.search_posts(query, preload: [:author])

    {:noreply, assign(socket, posts: result.records, search: result, query: query)}
  end
end
```

## 4. Keep Visibility Language Honest

If your context writes to the repo and then enqueues search work, the HTTP response or LiveView update still does not imply the document is searchable yet.

- `:inline` means Scrypath waited for terminal backend success
- `:manual` means the backend accepted work
- `:oban` means the enqueue is durable

None of those erase backend visibility semantics or the possibility of drift.

## Next Guides

- [Phoenix Contexts](phoenix-contexts.html)
- [Phoenix Controllers And JSON](phoenix-controllers-and-json.html)
- [Phoenix LiveView](phoenix-liveview.html)
- [Sync Modes And Visibility](sync-modes-and-visibility.html)
