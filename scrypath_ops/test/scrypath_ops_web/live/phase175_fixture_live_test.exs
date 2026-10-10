defmodule ScrypathOpsWeb.Phase175FixtureLiveTest do
  @moduledoc false
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScrypathOps.Test.OpsPostA
  alias ScrypathOps.Test.OpsPostB
  alias ScrypathOps.Test.Phase175FixtureSource
  alias ScrypathOpsWeb.DevRouter
  alias ScrypathOpsWeb.SyncDriftLive

  setup do
    keys = ~w(schema_allowlist backend index_prefix meilisearch_url meilisearch_client oban_inspector oban_jobs)a
    previous = Map.new(keys, &{&1, Application.get_env(:scrypath_ops, &1)})

    Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostA, OpsPostB])
    start_supervised!(%{
      id: Phase175FixtureSource.state_name(),
      start:
        {Agent, :start_link,
         [fn -> Phase175FixtureSource.initial_state() end, [name: Phase175FixtureSource.state_name()]]}
    })

    on_exit(fn ->
      Enum.each(previous, fn
        {key, nil} -> Application.delete_env(:scrypath_ops, key)
        {key, value} -> Application.put_env(:scrypath_ops, key, value)
      end)
    end)

    :ok
  end

  test "test-only standalone route mounts the production SyncDriftLive", %{conn: conn} do
    route = Enum.find(Phoenix.Router.routes(DevRouter), &(&1.path == "/ops/phase175/sync-drift"))

    assert route
    assert route.plug == Phoenix.LiveView.Plug
    assert {SyncDriftLive, :phase175, _opts, _live_session} = route.metadata.phoenix_live_view

    schema = "ScrypathOps.Test.OpsPostB"
    {:ok, view, _html} = live(conn, "/ops/phase175/sync-drift?schema=#{schema}")

    assert :sys.get_state(view.pid).socket.assigns.live_action == :phase175
    assert :sys.get_state(view.pid).socket.assigns.selected_schema == OpsPostB
    assert has_element?(view, "#promotion-task-status", "Index swap accepted")
    assert has_element?(view, "#promotion-task-status", schema)
    assert has_element?(view, "#promotion-task-status", "17501")

    view |> element("#promotion-task-status button", "Check swap status") |> render_click()
    render_async(view)

    assert has_element?(view, "#promotion-task-status", "Index swap running")
    assert Agent.get(Phase175FixtureSource.state_name(), &Enum.reverse(&1.task_calls)) == [17_501]
    assert Agent.get(Phase175FixtureSource.state_name(), & &1.swap_post_count) == 1

    {:ok, normal_view, _normal_html} = live(conn, "/ops/sync-drift?schema=#{schema}")
    normal = :sys.get_state(normal_view.pid).socket.assigns
    assert normal.live_action == nil
    refute Keyword.get(normal.scrypath_opts, :index_prefix) == "phase175_"
    refute Keyword.get(normal.scrypath_opts, :meilisearch_client) == Phase175FixtureSource
    assert normal.selected_schema == OpsPostB
  end
end
