defmodule Scrypath.PhoenixExamplesTest do
  use ExUnit.Case, async: true

  alias Scrypath.TestSupport.Docs.PhoenixExampleCase.ApiPostController
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
end
