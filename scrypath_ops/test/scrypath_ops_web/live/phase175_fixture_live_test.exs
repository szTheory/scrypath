defmodule ScrypathOpsWeb.Phase175FixtureLiveTest do
  @moduledoc false
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScrypathOpsWeb.DevRouter
  alias ScrypathOpsWeb.SyncDriftLive

  test "test-only standalone route mounts the production SyncDriftLive", %{conn: conn} do
    route = Enum.find(Phoenix.Router.routes(DevRouter), &(&1.path == "/ops/phase175/sync-drift"))

    assert route, "expected a test-only Phase175 route for SyncDriftLive"
    assert route.plug == Phoenix.LiveView.Plug
    assert {SyncDriftLive, :phase175, _opts, _live_session} = route.metadata.phoenix_live_view

    {:ok, view, _html} = live(conn, "/ops/phase175/sync-drift")
    assert :sys.get_state(view.pid).socket.assigns.live_action == :phase175
  end
end
