defmodule ScrypathOpsWeb.Phase174FixtureLiveTest do
  @moduledoc false
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScrypathOps.Test.OpsPostA
  alias ScrypathOps.Test.OpsPostB
  alias ScrypathOpsWeb.ControlRoomLive
  alias ScrypathOpsWeb.DevRouter
  alias ScrypathOpsWeb.FailedSyncLive
  alias ScrypathOpsWeb.PostureLive

  test "standalone routes mount production views over the A-selected fixture", %{conn: conn} do
    expected_routes = [
      {"/ops/phase174", ControlRoomLive},
      {"/ops/phase174/health", PostureLive},
      {"/ops/phase174/failed-sync", FailedSyncLive}
    ]

    Enum.each(expected_routes, fn {path, view_module} ->
      route = Enum.find(Phoenix.Router.routes(DevRouter), &(&1.path == path))

      assert route,
             "expected test-only Phase174 route #{path} to mount #{inspect(view_module)}"

      assert route.plug == Phoenix.LiveView.Plug
      assert {^view_module, :phase174, _opts, _live_session} = route.metadata.phoenix_live_view
    end)

    schema_a = ScrypathOps.OperatorSelection.canonical(OpsPostA)
    schema_b = ScrypathOps.OperatorSelection.canonical(OpsPostB)
    query = URI.encode_query(%{"schema" => schema_a, "scenario" => "a-selected-b-worse"})

    {:ok, room, room_html} = live(conn, "/ops/phase174?#{query}")
    assert room_html =~ "Control Room"
    assert has_element?(room, "[data-testid='recovery-target']")
    assert room_html =~ schema_a

    {:ok, health, health_html} = live(conn, "/ops/phase174/health?#{query}")
    assert health_html =~ schema_a
    assert health_html =~ schema_b
    assert has_element?(health, "[id='posture-ScrypathOps.Test.OpsPostA']")
    assert has_element?(health, "[id='posture-ScrypathOps.Test.OpsPostB']")

    {:ok, failed_sync, failed_html} = live(conn, "/ops/phase174/failed-sync?#{query}")
    assert length(Regex.scan(~r/data-testid="failed-sync-row"/, render(failed_sync))) == 2
    assert failed_html =~ "Backend task 501"
    assert failed_html =~ "Queue job 501"

    assert room_html =~ ~r|href="/ops/phase174/assets/css/app\.css\?v=[a-f0-9]{64}"|
    assert get(conn, "/ops/phase174/assets/css/app.css").status == 200

    normal_health =
      Enum.find(Phoenix.Router.routes(DevRouter), &(&1.path == "/ops/health"))

    assert {PostureLive, nil, _opts, _live_session} =
             normal_health.metadata.phoenix_live_view

    {:ok, _normal, normal_html} = live(conn, "/ops/health")
    refute normal_html =~ "Backend task 501"
    refute normal_html =~ "Queue job 501"
  end
end
