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

  test "json controller fixture normalizes page params safely before calling the context" do
    api_section = module_section("PostController", "Api")

    assert api_section =~ "page_number = params |> Map.get(\"page\", 1) |> normalize_page()"
    assert api_section =~ "page: [number: page_number, size: 20]"
    assert api_section =~ "Integer.parse(page)"
    assert api_section =~ "{number, \"\"} when number > 0 -> number"
    refute api_section =~ "String.to_integer(page)"
  end

  test "json controller normalizes missing and invalid page params to page 1" do
    cases = [
      %{"q" => "ecto"},
      %{"q" => "ecto", "page" => "abc"},
      %{"q" => "ecto", "page" => "0"},
      %{"q" => "ecto", "page" => "-3"},
      %{"q" => "ecto", "page" => 0},
      %{"q" => "ecto", "page" => -2}
    ]

    Enum.each(cases, fn params ->
      response = ApiPostController.index(params)

      assert response.page == %{number: 1, size: 20}
      assert response.search.query == "ecto"
    end)
  end

  test "liveview-facing module reuses the same context boundary" do
    socket = PostLive.mount()
    updated = PostLive.handle_params(%{"q" => "search"}, socket)

    assert updated.query == "search"
    assert [%Post{}] = updated.posts
    assert updated.search.query == "search"
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
