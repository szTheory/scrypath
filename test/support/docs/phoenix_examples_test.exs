defmodule Scrypath.PhoenixExamplesTest do
  use ExUnit.Case, async: true

  @fixture_source File.read!("test/support/docs/phoenix_example_case.ex")

  alias Scrypath.TestSupport.Docs.PhoenixExampleCase.Api.PostController, as: ApiPostController
  alias Scrypath.TestSupport.Docs.PhoenixExampleCase.Content
  alias Scrypath.TestSupport.Docs.PhoenixExampleCase.Post
  alias Scrypath.TestSupport.Docs.PhoenixExampleCase.PostController
  alias Scrypath.TestSupport.Docs.PhoenixExampleCase.PostLive

  test "the context owns the search boundary used by web layers" do
    assert function_exported?(Content, :search_posts, 2)
    assert function_exported?(Content, :publish_post, 2)
    refute function_exported?(PostController, :search_posts, 2)
    refute function_exported?(PostLive, :search_posts, 2)
  end

  test "fixture source keeps repo and scrypath orchestration out of web modules" do
    controller_section = module_section("PostController")
    liveview_section = module_section("PostLive")

    refute controller_section =~ "Repo"
    refute controller_section =~ "Scrypath.search"
    refute controller_section =~ "Scrypath.sync"
    refute liveview_section =~ "Repo"
    refute liveview_section =~ "Scrypath.search"
    refute liveview_section =~ "Scrypath.sync"
    assert controller_section =~ "Content.search_posts"
    assert liveview_section =~ "Content.search_posts"
  end

  test "controller delegates search work to the context boundary" do
    response = PostController.index(%{"q" => "phoenix"})

    assert [%Post{title: "Phoenix search", status: "published"}] = response.posts
    assert response.search.query == "phoenix"
  end

  test "json controller keeps serialization in the web layer" do
    response = ApiPostController.index(%{"q" => "ecto", "page" => "2"})

    assert [%{id: 1, title: "Phoenix search", status: "published"}] = response.data
    assert response.page == %{number: 2, size: 20}
    assert response.search.query == "ecto"
  end

  test "liveview-facing module reuses the same context boundary" do
    socket = PostLive.mount()
    updated = PostLive.handle_params(%{"q" => "search"}, socket)

    assert updated.query == "search"
    assert [%Post{}] = updated.posts
    assert updated.search.query == "search"
  end

  test "liveview write events still call the context boundary" do
    socket = PostLive.mount()

    assert socket == PostLive.handle_event("publish", %{"id" => 1, "post" => %{title: "Published"}}, socket)
  end

  defp module_section(name) do
    Regex.run(
      ~r/defmodule #{name} do\n(.*?)\n  end/ms,
      @fixture_source,
      capture: :all_but_first
    )
    |> List.first()
  end
end
