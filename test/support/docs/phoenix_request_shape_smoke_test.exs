defmodule Scrypath.PhoenixRequestShapeSmokeTest do
  use ExUnit.Case, async: true

  alias Scrypath.TestSupport.Docs.PhoenixExampleCase.PostLive

  test "decoded nested request params match the liveview publish fixture contract" do
    params = Plug.Conn.Query.decode("id=1&post[title]=Published")
    socket = PostLive.mount()

    assert %{"id" => "1", "post" => %{"title" => "Published"}} = params
    assert socket == PostLive.handle_event("publish", params, socket)
  end
end
