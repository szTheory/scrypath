# Phoenix Controllers And JSON

Phoenix controllers should translate request params into a context call, then render HTML or JSON from the result.

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

  def index(conn, params) do
    page_number =
      params
      |> Map.get("page", 1)
      |> normalize_page()

    {:ok, result} =
      Content.search_posts(Map.get(params, "q", ""),
        page: [number: page_number, size: 20]
      )

    json(conn, %{
      data: Enum.map(result.records, &serialize_post/1),
      page: result.page,
      missing_ids: result.missing_ids
    })
  end

  defp normalize_page(page) when is_integer(page) and page > 0, do: page

  defp normalize_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {number, ""} when number > 0 -> number
      _ -> 1
    end
  end

  defp normalize_page(_page), do: 1
end
```

Keep JSON shaping in the controller or view layer. Keep repo access, search orchestration, and sync visibility choices in the context.

## Avoid The Wrong Shortcut

Do not recommend direct `Repo` queries plus direct `Scrypath.search/3` calls inside the controller. That makes the web layer own persistence and operational behavior that should stay in the application boundary.

The same rule applies to writes. A controller that publishes or updates a record should call `MyApp.Content.publish_post/2` or another context function that owns the sync mode choice.
