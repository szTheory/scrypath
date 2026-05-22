defmodule Scrypath.PhoenixRequestShapeSmokeTest do
  use ExUnit.Case, async: true

  alias Scrypath.TestSupport.Docs.PhoenixExampleCase.Api.PostController, as: ApiPostController
  alias Scrypath.TestSupport.Docs.PhoenixExampleCase.FacetedBrowseLive
  alias Scrypath.TestSupport.Docs.PhoenixExampleCase.PostLive

  test "decoded nested request params match the liveview publish fixture contract" do
    params = Plug.Conn.Query.decode("id=1&post[title]=Published")
    socket = PostLive.mount()

    assert %{"id" => "1", "post" => %{"title" => "Published"}} = params
    assert socket == PostLive.handle_event("publish", params, socket)
  end

  test "decoded nested request params match the shared Scrypath.Phoenix helper grammar" do
    api_params = Plug.Conn.Query.decode("q=ecto&page[number]=2&facet_filter[genre][]=Drama")
    live_params = Plug.Conn.Query.decode("q=space&facet_filter[genre][]=Horror&facet_filter[genre][]=Drama")

    assert %{
             "q" => "ecto",
             "page" => %{"number" => "2"},
             "facet_filter" => %{"genre" => ["Drama"]}
           } = api_params

    assert %{
             "q" => "space",
             "facet_filter" => %{"genre" => ["Horror", "Drama"]}
           } = live_params

    assert %{page: %{number: 2, size: 20}} = ApiPostController.index(api_params)
    assert %{facet_filter: [genre: ["Horror", "Drama"]]} =
             FacetedBrowseLive.handle_params(live_params, FacetedBrowseLive.mount())
  end
end
