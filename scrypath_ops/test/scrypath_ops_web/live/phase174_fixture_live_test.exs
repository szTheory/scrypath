defmodule ScrypathOpsWeb.Phase174FixtureLiveTest do
  @moduledoc false
  use ScrypathOpsWeb.ConnCase, async: false

  alias ScrypathOps.Test.OpsPostA
  alias ScrypathOps.Test.OpsPostB
  alias ScrypathOpsWeb.ControlRoomLive
  alias ScrypathOpsWeb.DevRouter
  alias ScrypathOpsWeb.FailedSyncLive
  alias ScrypathOpsWeb.PostureLive

  test "test-only routes target production views and deterministic source fixtures", %{conn: conn} do
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

    assert get(conn, "/ops/phase174/assets/css/app.css").status == 200

    fixture_source = Module.concat(["ScrypathOps.Test.Phase174FixtureSource"])
    assert Application.get_env(:scrypath_ops, :phase174_fixture_source) == fixture_source
    fixture = apply(fixture_source, :scenario, ["a-selected-b-worse"])
    assert fixture.allowlist == [OpsPostA, OpsPostB]

    tasks = Keyword.fetch!(fixture.opts, :meilisearch_tasks)
    assert Enum.map(tasks, & &1["uid"]) == [501, 501]

    index_a = Scrypath.Meilisearch.index_name(OpsPostA, index_prefix: "phase174_")
    index_b = Scrypath.Meilisearch.index_name(OpsPostB, index_prefix: "phase174_")
    assert Enum.map(tasks, & &1["indexUid"]) == [index_a, index_b]
    assert Enum.map(tasks, & &1["status"]) == ["succeeded", "failed"]

    collision = apply(fixture_source, :scenario, ["source-collision"])
    assert Enum.map(Keyword.fetch!(collision.opts, :meilisearch_tasks), & &1["uid"]) == [501, 501]
    assert Enum.map(Keyword.fetch!(collision.opts, :oban_jobs), & &1.id) == [501, 501]

    normal_health =
      Enum.find(Phoenix.Router.routes(DevRouter), &(&1.path == "/ops/health"))

    assert {PostureLive, nil, _opts, _live_session} =
             normal_health.metadata.phoenix_live_view

  end
end
