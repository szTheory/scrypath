# Phoenix Controllers And JSON

Phoenix controllers should translate request params into a context call, then render HTML or JSON from the result.

## HTML Controllers

For HTML responses, treat Scrypath as part of the context contract:

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

  def index(conn, params) do
    {:ok, result} =
      Content.search_posts(Map.get(params, "q", ""),
        page: [number: params["page"] || 1, size: 20]
      )

    json(conn, %{
      data: Enum.map(result.records, &serialize_post/1),
      page: result.page,
      missing_ids: result.missing_ids
    })
  end
end
```

Keep JSON shaping in the controller or view layer. Keep repo access, search orchestration, and sync visibility choices in the context.

## Avoid The Wrong Shortcut

Do not recommend direct `Repo` queries plus direct `Scrypath.search/3` calls inside the controller. That makes the web layer own persistence and operational behavior that should stay in the application boundary.
