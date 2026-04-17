defmodule Scrypath.TestSupport.Docs.PhoenixExampleCase do
  @moduledoc false

  defmodule Post do
    @moduledoc false
    defstruct [:id, :title, :status]
  end

  defmodule SearchResult do
    @moduledoc false
    defstruct records: [], query: nil, mode: :inline, status: :completed
  end

  defmodule Content do
    @moduledoc false
    alias Scrypath.TestSupport.Docs.PhoenixExampleCase.Post
    alias Scrypath.TestSupport.Docs.PhoenixExampleCase.SearchResult

    def search_posts(query, opts \\ []) do
      status = opts |> Keyword.get(:filter, []) |> Keyword.get(:status, "published")

      {:ok,
       %SearchResult{
         query: query,
         records: [%Post{id: 1, title: "Phoenix search", status: status}]
       }}
    end

    def publish_post(%Post{} = post, attrs) when is_map(attrs) do
      {:ok, %{post | title: Map.get(attrs, "title", post.title), status: :published}}
    end

    def get_post!(id), do: %Post{id: id, title: "Draft", status: :draft}

    def search_movies(query, opts \\ []) do
      _ = Keyword.get(opts, :facets, [])
      _ = Keyword.get(opts, :facet_filter, [])

      {:ok,
       %SearchResult{
         query: query,
         records: [%Post{id: 1, title: "Example Movie", status: "published"}]
       }}
    end
  end

  defmodule PostController do
    @moduledoc false
    alias Scrypath.TestSupport.Docs.PhoenixExampleCase.Content

    def index(params) do
      query = Map.get(params, "q", "")

      with {:ok, result} <- Content.search_posts(query, filter: [status: "published"]) do
        %{posts: result.records, search: result}
      end
    end
  end

  defmodule Api do
    @moduledoc false

    defmodule PostController do
      @moduledoc false
      alias Scrypath.TestSupport.Docs.PhoenixExampleCase.Content

      def index(params) do
        query = Map.get(params, "q", "")
        page_number = params |> Map.get("page", 1) |> normalize_page()

        with {:ok, result} <- Content.search_posts(query, page: [number: page_number, size: 20]) do
          %{
            data: Enum.map(result.records, &serialize_post/1),
            page: %{number: page_number, size: 20},
            search: result
          }
        end
      end

      defp serialize_post(post), do: %{id: post.id, title: post.title, status: post.status}

      defp normalize_page(page) when is_integer(page) and page > 0, do: page

      defp normalize_page(page) when is_binary(page) do
        case Integer.parse(page) do
          {number, ""} when number > 0 -> number
          _ -> 1
        end
      end

      defp normalize_page(_page), do: 1
    end
  end

  defmodule PostLive do
    @moduledoc false
    alias Scrypath.TestSupport.Docs.PhoenixExampleCase.Content

    def mount do
      %{posts: [], search: nil, query: ""}
    end

    def handle_params(%{"q" => query}, socket) do
      with {:ok, result} <- Content.search_posts(query, preload: [:author]) do
        Map.merge(socket, %{posts: result.records, search: result, query: query})
      end
    end

    def handle_event("publish", %{"id" => id, "post" => attrs}, socket) do
      post = Content.get_post!(id)
      {:ok, _post} = Content.publish_post(post, attrs)

      socket
    end
  end

  defmodule FacetedBrowseLive do
    @moduledoc false

    alias Scrypath.TestSupport.Docs.PhoenixExampleCase.Content

    def mount, do: %{q: "", posts: [], facet_filter: []}

    def handle_params(params, socket) do
      q = Map.get(params, "q", "")
      genres = parse_genres(params["genre"])

      facet_filter =
        case genres do
          [] -> []
          list -> [genre: list]
        end

      with {:ok, result} <-
             Content.search_movies(q,
               facets: [:genre, :year, :rating],
               facet_filter: facet_filter
             ) do
        Map.merge(socket, %{q: q, posts: result.records, facet_filter: facet_filter})
      end
    end

    defp parse_genres(nil), do: []

    defp parse_genres(s) when is_binary(s) do
      s |> String.split(",", trim: true) |> Enum.map(&String.trim/1)
    end
  end
end
