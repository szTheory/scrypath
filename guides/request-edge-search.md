# Request-edge search with QueryParams and Phoenix

This guide shows the request-edge path: browser params enter at the web edge, `Scrypath.QueryParams` normalizes them into plain data, optional `Scrypath.Phoenix` helpers round-trip params and attempted values, your context calls `Scrypath.search/3`, and the runtime stops there.

If you want the broader onboarding path first, read [Getting Started](getting-started.md) or the [Golden path](golden-path.md). If you want reusable search defaults, metadata-backed host rendering, or multi-search composition after this shared contract, continue with [Composing real-app search](composing-real-app-search.md).

## The Boundary

Keep the lane narrow and explicit:

1. Browser params arrive in a controller, LiveView, or another app-owned web edge.
2. `Scrypath.QueryParams.normalize/1` turns request-shaped params into one stable plain-data contract.
3. `Scrypath.Phoenix` is optional glue for params, forms, and URL round-tripping.
4. `QueryParams.to_search_args/1` prepares `{query, search_opts}` for your context.
5. Your context calls `Scrypath.search/3`.

`Scrypath.Phoenix` does not execute search, own socket lifecycle, or replace contexts. `%Scrypath.Query{}` is not public API.

## Framework-light core

`Scrypath.QueryParams` is the framework-light public edge seam:

```elixir
case Scrypath.QueryParams.normalize(params) do
  {:ok, query_params} ->
    {query, search_opts} = Scrypath.QueryParams.to_search_args(query_params)
    MyApp.Content.search_posts(query, search_opts)

  {:error, error_map} ->
    {:error, error_map}
end
```

That shape works outside Phoenix too. The normalized output is plain data that feeds the same context-owned runtime path.

## Optional Phoenix glue

If you are in Phoenix, `Scrypath.Phoenix` removes repeated request-edge glue without becoming a second runtime:

```elixir
alias Scrypath.Phoenix, as: SearchPhoenix
alias Scrypath.QueryParams

case SearchPhoenix.from_params(params) do
  {:ok, query_params} ->
    form = SearchPhoenix.to_form_data(query_params)
    {query, search_opts} = QueryParams.to_search_args(query_params)
    {:ok, result} = MyApp.Content.search_posts(query, search_opts)
    {:ok, %{form: form, result: result}}

  {:error, error_map} ->
    {:error, SearchPhoenix.to_form_data(params, error_map)}
end
```

Use that helper layer for:

- browser-shaped param normalization
- renderable attempted values plus field/form errors
- URL param round-tripping

Do not use it for:

- search execution
- repo access
- controller macros or `use Scrypath.Phoenix`
- LiveView socket ownership

## Contexts stay canonical

Contexts remain the application boundary for search orchestration:

```elixir
defmodule MyApp.Content do
  alias MyApp.Blog.Post
  alias MyApp.Repo

  def search_posts(query, opts \\ []) do
    Scrypath.search(Post, query,
      Keyword.merge([backend: Scrypath.Meilisearch, repo: Repo], opts)
    )
  end
end
```

That is where repo-backed hydration, backend choice, preload policy, sync mode choice, and feature-level defaults belong.

## Controller and LiveView flow

Controllers and LiveView stay thin:

- controllers normalize params, call the context, and render HTML or JSON
- `handle_params/3` remains the canonical LiveView source of truth for URL-driven search state
- the same `QueryParams` / `SearchPhoenix` contract feeds both

See:

- [Phoenix controllers and JSON](phoenix-controllers-and-json.md)
- [Phoenix LiveView](phoenix-liveview.md)
- [Faceted search with Phoenix LiveView](faceted-search-with-phoenix-liveview.md)

## Example app vs guides

Use this guide when you want to understand the boundary. Use the runnable example when you want to exercise the same shape against Postgres, Meilisearch, and Oban:

- guide path: this guide plus the rest of `guides/`
- runnable path: [`examples/phoenix_meilisearch/README.md`](../examples/phoenix_meilisearch/README.md)

Use the guide to understand the boundary. Use the example when you want to prove the operational path against real services.

## Continue

- [Composing real-app search](composing-real-app-search.md)
- [Phoenix Walkthrough](phoenix-walkthrough.md)
- [Phoenix Contexts](phoenix-contexts.md)
- [Phoenix Controllers and JSON](phoenix-controllers-and-json.md)
- [Phoenix LiveView](phoenix-liveview.md)
