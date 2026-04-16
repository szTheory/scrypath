# Phoenix Walkthrough

This walkthrough shows the recommended adoption path for Scrypath in a Phoenix app: searchable schema, context-owned search boundary, controller call, LiveView call, and explicit sync visibility choices.

## 1. Declare The Searchable Schema

Start with a normal Ecto schema and keep the Scrypath declaration on the schema itself.

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

That declaration is metadata, not a generated runtime API. The runtime calls still belong in your context.

## 2. Put Search And Sync In The Context

Put search orchestration in a Phoenix context, not in controllers and not in LiveView modules.

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

The context owns repo-backed hydration, backend choice, sync mode choice, and preload policy. That is also where you decide whether a write waits inline or returns accepted async work.

## 3. Call That Boundary From Controllers

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

Use the same shape for JSON endpoints. The controller owns request parsing and rendering, while `MyApp.Content.search_posts/2` owns repo access and Scrypath options.

## 4. Reuse The Same Context From LiveView

LiveView owns UI state. The context still owns repo access and Scrypath orchestration.

```elixir
defmodule MyAppWeb.PostLive do
  use MyAppWeb, :live_view

  alias MyApp.Content

  def mount(_params, _session, socket) do
    {:ok, assign(socket, posts: [], search: nil, query: "")}
  end

  def handle_params(%{"q" => query}, _uri, socket) do
    {:ok, result} = Content.search_posts(query, preload: [:author])

    {:noreply, assign(socket, posts: result.records, search: result, query: query)}
  end
end
```

That keeps URL state, loading state, and selected filters in the LiveView while keeping the data boundary in the context.

## 5. Keep Visibility Language Honest

If your context writes to the repo and then enqueues search work, the HTTP response or LiveView update still does not imply the document is searchable yet.

- `:inline` means Scrypath waited for terminal backend success
- `:manual` means the backend accepted work
- `:oban` means the enqueue is durable

Accepted work is not the same thing as search visibility, and none of those modes erase drift, retries, or backend visibility semantics.

## Next Guides

- [Phoenix Contexts](phoenix-contexts.html)
- [Phoenix Controllers And JSON](phoenix-controllers-and-json.html)
- [Phoenix LiveView](phoenix-liveview.html)
- [Sync Modes And Visibility](sync-modes-and-visibility.html)
