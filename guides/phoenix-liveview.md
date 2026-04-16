# Phoenix LiveView

LiveView is a strong fit for search interfaces, but the recommended Scrypath boundary stays the same: LiveView owns UI state, and the context owns repo access plus Scrypath orchestration.

## Handle Params Through The Context

```elixir
defmodule MyAppWeb.PostLive do
  use MyAppWeb, :live_view

  alias MyApp.Content

  def mount(_params, _session, socket) do
    {:ok, assign(socket, posts: [], search: nil, query: "")}
  end

  def handle_params(%{"q" => query}, _uri, socket) do
    {:ok, result} = Content.search_posts(query, preload: [:author])

    {:noreply,
     assign(socket,
       posts: result.records,
       search: result,
       query: query
     )}
  end
end
```

## Keep UI State Local

LiveView should own:

- current query text
- filter and sort params that belong in the URL
- loading state
- selected ids and pagination state

The context should own:

- repo-backed hydration
- backend selection
- `Scrypath.search/3` options
- write-path sync and delete orchestration

The same context boundary can back a publish event:

```elixir
def handle_event("publish", %{"id" => id, "post" => attrs}, socket) do
  post = load_post!(id)
  {:ok, _post} = Content.publish_post(post, attrs)

  {:noreply, socket}
end
```

Keep `attrs` string-keyed at this boundary. That matches the nested params LiveView receives from the browser before your context decides how to validate or persist them.

## Keep Visibility Wording Precise

If a LiveView event updates a record and then triggers sync work, the UI should not imply immediate search visibility unless the context chose `:inline` and waited for terminal backend success.

Even then, backend acceptance and visibility semantics remain separate concerns. Keep that distinction explicit in operator-facing UI and docs.
