# Phoenix Controllers And JSON

Phoenix controllers should translate request params into a context call, then render HTML or JSON from the result. If you want shared request-edge glue, use `Scrypath.Phoenix` as a thin wrapper over `Scrypath.QueryParams` rather than hand-rolling page, facet, and sort parsing in each controller.

## HTML Controllers

For HTML responses, treat `MyApp.Content.search_posts/2` as the search boundary and render the result:

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

## JSON Controllers

JSON controllers follow the same shape. They still call the context boundary and then serialize the result:

```elixir
defmodule MyAppWeb.Api.PostController do
  use MyAppWeb, :controller

  alias MyApp.Content
  alias Scrypath.Phoenix, as: SearchPhoenix
  alias Scrypath.QueryParams

  def index(conn, params) do
    case SearchPhoenix.from_params(params) do
      {:ok, query_params} ->
        {query, search_opts} = QueryParams.to_search_args(query_params)
        page_opts = page_with_default_size(Keyword.get(search_opts, :page, []))

        {:ok, result} = Content.search_posts(query, page: page_opts)

        json(conn, %{
          data: Enum.map(result.records, &serialize_post/1),
          page: Enum.into(page_opts, %{}),
          missing_ids: result.missing_ids
        })

      {:error, error_map} ->
        json(conn, %{
          data: [],
          errors: SearchPhoenix.to_form_data(params, error_map).errors
        })
    end
  end

  defp page_with_default_size(page_opts) do
    page_opts
    |> Keyword.put_new(:number, 1)
    |> Keyword.put_new(:size, 20)
  end
end
```

Keep JSON shaping in the controller or view layer. Keep repo access, search orchestration, and sync visibility choices in the context. `Scrypath.Phoenix` stops at param normalization, URL round-tripping, and renderable attempted values plus errors. It does not execute search.

## Avoid The Wrong Shortcut

Do not recommend direct `Repo` queries plus direct `Scrypath.search/3` calls inside the controller. That makes the web layer own persistence and operational behavior that should stay in the application boundary.

The same rule applies to writes. A controller that publishes or updates a record should call `MyApp.Content.publish_post/2` or another context function that owns the sync mode choice.
