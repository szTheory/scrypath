defmodule Scrypath.PhoenixExamplesTest do
  use ExUnit.Case, async: true

  @fixture_source File.read!("test/support/docs/phoenix_example_case.ex")

  alias Scrypath.Phoenix
  alias Scrypath.TestSupport.Docs.PhoenixExampleCase.Api.PostController, as: ApiPostController
  alias Scrypath.TestSupport.Docs.PhoenixExampleCase.Content
  alias Scrypath.TestSupport.Docs.PhoenixExampleCase.Post
  alias Scrypath.TestSupport.Docs.PhoenixExampleCase.PostController
  alias Scrypath.TestSupport.Docs.PhoenixExampleCase.PostLive
  alias Scrypath.TestSupport.Docs.PhoenixExampleCase.FacetedBrowseLive

  test "the context owns the search boundary used by web layers" do
    assert function_exported?(Content, :search_posts, 2)
    assert function_exported?(Content, :publish_post, 2)
    refute function_exported?(PostController, :search_posts, 2)
    refute function_exported?(PostLive, :search_posts, 2)
  end

  test "fixture source keeps repo and scrypath orchestration out of web modules" do
    controller_section = module_section("PostController")
    api_section = module_section("PostController", "Api")
    liveview_section = module_section("PostLive")
    faceted_section = module_section("FacetedBrowseLive")

    refute controller_section =~ "Repo"
    refute controller_section =~ "Scrypath.search"
    refute controller_section =~ "Scrypath.sync"
    refute liveview_section =~ "Repo"
    refute liveview_section =~ "Scrypath.search"
    refute liveview_section =~ "Scrypath.sync"
    assert api_section =~ "SearchPhoenix.from_params"
    assert liveview_section =~ "SearchPhoenix.from_params"
    assert faceted_section =~ "SearchPhoenix.from_params"
    assert controller_section =~ "Content.search_posts"
    assert liveview_section =~ "Content.search_posts"
  end

  test "controller delegates search work to the context boundary" do
    response = PostController.index(%{"q" => "phoenix"})

    assert [%Post{title: "Phoenix search", status: "published"}] = response.posts
    assert response.search.query == "phoenix"
  end

  test "json controller keeps serialization in the web layer" do
    response = ApiPostController.index(%{"q" => "ecto", "page" => %{"number" => "2"}})

    assert [%{id: 1, title: "Phoenix search", status: "published"}] = response.data
    assert response.page == %{number: 2, size: 20}
    assert response.search.query == "ecto"
    assert response.form.values["page"] == %{"number" => "2"}
  end

  test "json controller fixture delegates request-edge parsing to Scrypath.Phoenix" do
    api_section = module_section("PostController", "Api")

    assert api_section =~ "SearchPhoenix.from_params(params)"
    assert api_section =~ "QueryParams.to_search_args(query_params)"
    assert api_section =~ "page_with_default_size"
    refute api_section =~ "normalize_page"
  end

  test "json controller renders attempted state and skips search on invalid params" do
    response = ApiPostController.index(%{"q" => "ecto", "page" => %{"number" => "0"}})

    assert response.data == []
    assert response.search == nil
    assert response.page == %{number: 1, size: 20}
    assert response.form.values["page"] == %{"number" => "0"}

    assert [%{code: :invalid_value, path: ["page", "number"]}] =
             response.form.field_errors["page"]
  end

  test "liveview-facing module reuses the same context boundary" do
    socket = PostLive.mount()
    updated = PostLive.handle_params(%{"q" => "search"}, socket)

    assert updated.query == "search"
    assert [%Post{}] = updated.posts
    assert updated.search.query == "search"
    assert updated.form.values["q"] == "search"
  end

  test "faceted browse liveview passes facets and facet_filter through the context" do
    socket = FacetedBrowseLive.mount()

    updated =
      FacetedBrowseLive.handle_params(
        %{"q" => "space", "facet_filter" => %{"genre" => ["Horror", "Drama"]}},
        socket
      )

    assert updated.q == "space"
    assert updated.facet_filter == [genre: ["Horror", "Drama"]]
    assert [%Post{title: "Example Movie"}] = updated.posts
    assert updated.form.values["facet_filter"] == %{"genre" => ["Horror", "Drama"]}
  end

  test "liveview write events still call the context boundary with string-keyed attrs" do
    socket = PostLive.mount()

    assert socket ==
             PostLive.handle_event(
               "publish",
               %{"id" => 1, "post" => %{"title" => "Published"}},
               socket
             )
  end

  test "fixture content publish path reads realistic string-keyed attrs" do
    post = Content.get_post!(1)

    assert {:ok, %Post{title: "Published", status: :published}} =
             Content.publish_post(post, %{"title" => "Published"})
  end

  test "fixture wrapper usage stays pure and does not execute search in Scrypath.Phoenix" do
    source = File.read!("lib/scrypath/phoenix.ex")

    assert Phoenix.from_params(%{"q" => "ecto"}) ==
             Scrypath.QueryParams.normalize(%{"q" => "ecto"})

    refute source =~ "Repo"
    refute source =~ "Scrypath.search"
    refute source =~ "defmacro"
    refute source =~ "handle_params"
    refute source =~ "handle_event"
  end

  defp module_section(name, parent \\ nil) do
    pattern =
      case parent do
        nil ->
          ~r/defmodule #{name} do\n(.*?)\n  end/ms

        parent_name ->
          ~r/defmodule #{parent_name} do\n(.*?)defmodule #{name} do\n(.*?)\n    end\n  end/ms
      end

    case Regex.run(pattern, @fixture_source, capture: :all_but_first) do
      [section] -> section
      [_parent_section, section] -> section
    end
  end
end
