defmodule ScrypathOpsWeb.Phase174FixtureLiveTest do
  @moduledoc false
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScrypathOps.Test.OpsPostA
  alias ScrypathOps.Test.OpsPostB
  alias ScrypathOps.Integrations.Sigra.OperatorContext
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

    {:ok, normal_health_view, _normal_health_html} = live(conn, "/ops/health")
    normal_assigns = :sys.get_state(normal_health_view.pid).socket.assigns
    assert normal_assigns.live_action == nil
    refute Keyword.get(normal_assigns.scrypath_opts, :index_prefix) == "phase174_"
  end

  test "standalone overview normalizes old scope and scoped recovery returns from stale-sudo", %{
    conn: conn
  } do
    assert Code.ensure_loaded?(Sigra.Audit)

    previous_allowlist = Application.get_env(:scrypath_ops, :schema_allowlist)
    Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostA, OpsPostB])

    on_exit(fn ->
      if is_nil(previous_allowlist),
        do: Application.delete_env(:scrypath_ops, :schema_allowlist),
        else: Application.put_env(:scrypath_ops, :schema_allowlist, previous_allowlist)
    end)

    schema_a = ScrypathOps.OperatorSelection.canonical(OpsPostA)
    query = URI.encode_query(%{"schema" => schema_a, "scenario" => "a-selected-b-worse"})

    {:ok, room, room_html} =
      live(conn, "/ops/phase174?#{query}")
      |> follow_redirect(conn, "/ops/phase174?scenario=a-selected-b-worse")

    refute room_html =~ "Selected schema"
    refute has_element?(room, "[data-testid='recovery-target']")
    assert room_html =~ "ScrypathOps.Test.OpsPostB"
    assert has_element?(room, "#control-room-health-link[href='/ops/phase174/health']")

    {:ok, health, health_html} =
      live(conn, "/ops/phase174/health?#{query}")
      |> follow_redirect(conn, "/ops/phase174/health?scenario=a-selected-b-worse")

    assert has_element?(health, "[id='posture-ScrypathOps.Test.OpsPostB']")
    refute health_html =~ "Selected schema"
    assert health_html =~ schema_a
    render_click(health, "refresh", %{"scenario" => "a-selected-b-worse"})
    assert has_element?(health, "[id='posture-ScrypathOps.Test.OpsPostB']")

    {:ok, unavailable, unavailable_html} =
      live(
        conn,
        "/ops/phase174/failed-sync?schema=ScrypathOps.Test.Gone&scenario=source-collision"
      )

    assert unavailable_html =~ "That schema is unavailable"
    refute has_element?(unavailable, "[data-testid='failed-sync-row']")

    {:ok, selector, _selector_html} = live(conn, "/ops/phase174/failed-sync?#{query}")

    selector_html =
      render_change(selector, "select_schema", %{"schema" => "ScrypathOps.Test.OpsPostB"})

    assert :sys.get_state(selector.pid).socket.assigns.selected_schema == OpsPostB
    assert selector_html =~ "OpsPostB"

    collision_query =
      URI.encode_query(%{"schema" => schema_a, "scenario" => "source-collision"})

    {:ok, failed_sync, failed_html} =
      live(conn, "/ops/phase174/failed-sync?#{collision_query}")

    assert length(Regex.scan(~r/data-testid="failed-sync-row"/, failed_html)) == 2
    assert failed_html =~ "Backend task 501"
    assert failed_html =~ "Queue job 501"
    assert :sys.get_state(failed_sync.pid).socket.assigns.selected_schema == OpsPostA

    retry_button =
      failed_sync
      |> element("[data-testid='failed-sync-retry']")
      |> render()

    [_, work_key] = Regex.run(~r/phx-value-id="([^"]+)"/, retry_button)
    [_, generation] = Regex.run(~r/phx-value-generation="([^"]+)"/, retry_button)

    %{operator_context: %OperatorContext{sudo_at: sudo_at}} =
      :sys.get_state(failed_sync.pid).socket.assigns

    assert DateTime.diff(DateTime.utc_now(), sudo_at, :second) > 300

    expected_return = "/ops/phase174/failed-sync?schema=#{schema_a}"
    confirm_path = "/sudo/confirm?" <> URI.encode_query(%{"return_to" => expected_return})

    render_click(failed_sync, "retry", %{"id" => work_key, "generation" => generation})
    assert_redirect(failed_sync, confirm_path)

    assert get(conn, confirm_path).status == 200

    {:ok, returned, returned_html} = live(conn, expected_return)
    assert :sys.get_state(returned.pid).socket.assigns.selected_schema == OpsPostA
    assert :sys.get_state(returned.pid).socket.assigns.recovery_receipts == %{}
    assert returned_html =~ schema_a
    assert returned_html =~ "Failed sync work"
    refute returned_html =~ "Retry accepted"
  end
end
