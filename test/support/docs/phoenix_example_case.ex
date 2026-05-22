defmodule Scrypath.TestSupport.Docs.PhoenixExampleCase do
  @moduledoc false

  alias Scrypath.Phoenix, as: SearchPhoenix
  alias Scrypath.QueryParams

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
      alias Scrypath.Phoenix, as: SearchPhoenix
      alias Scrypath.QueryParams
      alias Scrypath.TestSupport.Docs.PhoenixExampleCase.Content

      def index(params) do
        case SearchPhoenix.from_params(params) do
          {:ok, query_params} ->
            {query, search_opts} = QueryParams.to_search_args(query_params)
            page_opts = page_with_default_size(Keyword.get(search_opts, :page, []))

            with {:ok, result} <- Content.search_posts(query, page: page_opts) do
              %{
                data: Enum.map(result.records, &serialize_post/1),
                page: Enum.into(page_opts, %{}),
                search: result,
                form: SearchPhoenix.to_form_data(query_params)
              }
            end

          {:error, error_map} ->
            %{
              data: [],
              page: %{number: 1, size: 20},
              search: nil,
              form: SearchPhoenix.to_form_data(params, error_map)
            }
        end
      end

      defp serialize_post(post), do: %{id: post.id, title: post.title, status: post.status}

      defp page_with_default_size(page_opts) do
        page_opts
        |> Keyword.put_new(:number, 1)
        |> Keyword.put_new(:size, 20)
      end
    end
  end

  defmodule PostLive do
    @moduledoc false
    alias Scrypath.Phoenix, as: SearchPhoenix
    alias Scrypath.QueryParams
    alias Scrypath.TestSupport.Docs.PhoenixExampleCase.Content

    def mount do
      %{posts: [], search: nil, query: "", form: SearchPhoenix.to_form_data(QueryParams.cast(%{}))}
    end

    def handle_params(params, socket) do
      case SearchPhoenix.from_params(params) do
        {:ok, query_params} ->
          form = SearchPhoenix.to_form_data(query_params)
          {query, search_opts} = QueryParams.to_search_args(query_params)

          with {:ok, result} <- Content.search_posts(query, Keyword.put(search_opts, :preload, [:author])) do
            Map.merge(socket, %{posts: result.records, search: result, query: query, form: form})
          end

        {:error, error_map} ->
          form = SearchPhoenix.to_form_data(params, error_map)
          Map.merge(socket, %{posts: [], search: nil, query: form.values["q"], form: form})
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

    alias Scrypath.Phoenix, as: SearchPhoenix
    alias Scrypath.QueryParams
    alias Scrypath.TestSupport.Docs.PhoenixExampleCase.Content

    def mount, do: %{q: "", posts: [], facet_filter: [], form: SearchPhoenix.to_form_data(QueryParams.cast(%{}))}

    def handle_params(params, socket) do
      case SearchPhoenix.from_params(params) do
        {:ok, query_params} ->
          form = SearchPhoenix.to_form_data(query_params)
          {query, search_opts} = QueryParams.to_search_args(query_params)
          facets = if search_opts[:facets] == [], do: [:genre, :year, :rating], else: search_opts[:facets]

          with {:ok, result} <-
                 Content.search_movies(query,
                   facets: facets,
                   facet_filter: search_opts[:facet_filter]
                 ) do
            Map.merge(socket, %{
              q: query,
              posts: result.records,
              facet_filter: search_opts[:facet_filter],
              form: form
            })
          end

        {:error, error_map} ->
          form = SearchPhoenix.to_form_data(params, error_map)
          Map.merge(socket, %{q: form.values["q"], posts: [], facet_filter: [], form: form})
      end
    end
  end
end
