# Phoenix LiveView

LiveView is a strong fit for search interfaces, but the recommended Scrypath boundary stays the same: LiveView owns UI state, and the context owns repo access plus Scrypath orchestration. Use `Scrypath.Phoenix` only as request-edge glue around params, form projection, and URL round-tripping.

## Handle Params Through The Context

```elixir
defmodule MyAppWeb.PostLive do
  use MyAppWeb, :live_view

  alias MyApp.Content
  alias Scrypath.Phoenix, as: SearchPhoenix
  alias Scrypath.QueryParams

  def mount(_params, _session, socket) do
    {:ok, assign(socket, posts: [], search: nil, query: "", form: nil)}
  end

  def handle_params(params, _uri, socket) do
    case SearchPhoenix.from_params(params) do
      {:ok, query_params} ->
        form = SearchPhoenix.to_form_data(query_params)
        {query, search_opts} = QueryParams.to_search_args(query_params)
        {:ok, result} = Content.search_posts(query, Keyword.put(search_opts, :preload, [:author]))

        {:noreply,
         assign(socket,
           posts: result.records,
           search: result,
           query: query,
           form: form
         )}

      {:error, error_map} ->
        form = SearchPhoenix.to_form_data(params, error_map)

        {:noreply,
         assign(socket,
           posts: [],
           search: nil,
           query: form.values["q"],
           form: form
         )}
    end
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

`handle_event/3` should collect intent and push the next URL state. `handle_params/3` remains the one place that normalizes params, assigns attempted values plus errors, and calls the context when normalization succeeds.

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

## See also

For faceted catalogs (checkbox groups, chips, numeric ranges, and URL-synced `handle_params/3` with `Scrypath.search/3`), read `guides/faceted-search-with-phoenix-liveview.md`.
