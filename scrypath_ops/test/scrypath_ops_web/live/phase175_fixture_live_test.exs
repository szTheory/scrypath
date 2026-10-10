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
    keys =
      ~w(schema_allowlist backend index_prefix meilisearch_url meilisearch_client oban_inspector oban_jobs)a

    previous = Map.new(keys, &{&1, Application.get_env(:scrypath_ops, &1)})

    Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostA, OpsPostB])

    start_supervised!(%{
      id: Phase175FixtureSource.state_name(),
      start:
        {Agent, :start_link,
         [
           fn -> Phase175FixtureSource.initial_state() end,
           [name: Phase175FixtureSource.state_name()]
         ]}
    })

    on_exit(fn ->
      Enum.each(previous, fn
        {key, nil} -> Application.delete_env(:scrypath_ops, key)
        {key, value} -> Application.put_env(:scrypath_ops, key, value)
      end)
    end)

    :ok
  end

  test "fixture scenarios are explicitly named and reject unknown transitions" do
    assert {:ok, queued} = Phase175FixtureSource.scenario("accepted-queued")
    assert queued.allowlist == [OpsPostA, OpsPostB]
    assert queued.task_uid == 17_501
    assert Phase175FixtureSource.scenario("unexpected-mutation") == {:error, :unknown_scenario}
    assert Phase175FixtureSource.allowlist("unexpected-mutation") == []
  end

  test "rendered exact-UID checks keep queued, terminal, and unconfirmed task states distinct", %{
    conn: conn
  } do
    cases = [
      {"accepted-queued", "Index swap accepted"},
      {"accepted-processing", "Index swap running"},
      {"accepted-succeeded", "Index swap completed"},
      {"accepted-failed", "Index swap failed"},
      {"accepted-cancelled", "Index swap cancelled"},
      {"accepted-wrong-uid", "Index swap outcome unconfirmed"},
      {"accepted-malformed", "Index swap outcome unconfirmed"},
      {"accepted-timeout", "Index swap outcome unconfirmed"}
    ]

    for {scenario, expected} <- cases do
      path =
        "/ops/phase175/sync-drift?" <>
          URI.encode_query(%{
            "schema" => "ScrypathOps.Test.OpsPostB",
            "scenario" => scenario
          })

      {:ok, view, _html} = live(conn, path)

      assert has_element?(view, "#promotion-task-status", "17_501") or
               has_element?(view, "#promotion-task-status", "17501")

      assert has_element?(view, "#promotion-task-status", "Index swap accepted")

      view |> element("#promotion-task-status button", "Check swap status") |> render_click()
      render_async(view)

      assert has_element?(view, "#promotion-task-status", expected)
      assert :sys.get_state(view.pid).socket.assigns.promotion_task_id == 17_501
      assert Agent.get(Phase175FixtureSource.state_name(), & &1.swap_post_count) == 1
    end

    assert Agent.get(Phase175FixtureSource.state_name(), &Enum.reverse(&1.task_calls)) ==
             List.duplicate(17_501, length(cases))
  end

  test "removed schemas and unknown scenarios stay unavailable without task reads", %{conn: conn} do
    for {scenario, expected, expected_allowlist} <- [
          {"removed-schema", "That schema is unavailable", [OpsPostA]},
          {"unexpected-mutation", "No schemas configured", []}
        ] do
      path =
        "/ops/phase175/sync-drift?" <>
          URI.encode_query(%{
            "schema" => "ScrypathOps.Test.OpsPostB",
            "scenario" => scenario
          })

      {:ok, view, html} = live(conn, path)
      assigns = :sys.get_state(view.pid).socket.assigns
      assert assigns.schema_allowlist == expected_allowlist
      assert html =~ expected
      refute has_element?(view, "#promotion-task-status")
      refute has_element?(view, "No pending or failed sync work found")
      assert :sys.get_state(view.pid).socket.assigns.selected_schema == nil
    end

    assert Agent.get(Phase175FixtureSource.state_name(), & &1.task_calls) == []
    assert Agent.get(Phase175FixtureSource.state_name(), & &1.swap_post_count) == 1
  end

  test "form selection retains a non-first schema through the standalone fixture", %{conn: conn} do
    {:ok, view, _html} =
      live(conn, "/ops/phase175/sync-drift?schema=ScrypathOps.Test.OpsPostB")

    view
    |> form("#sync-drift-schema-form", %{"schema" => "ScrypathOps.Test.OpsPostA"})
    |> render_change()

    assert_patch(view, "/ops/phase175/sync-drift?schema=ScrypathOps.Test.OpsPostA")
    assert :sys.get_state(view.pid).socket.assigns.selected_schema == OpsPostA
    assert has_element?(view, "#promotion-task-status", "ScrypathOps.Test.OpsPostA")
    refute render(view) =~ "phase175_ops_post_b__reindex"
  end

  test "partial sync observations remain unavailable while configuration is independent", %{
    conn: conn
  } do
    for scenario <- ["sync-error", "queue-error"] do
      path =
        "/ops/phase175/sync-drift?" <>
          URI.encode_query(%{
            "schema" => "ScrypathOps.Test.OpsPostB",
            "scenario" => scenario
          })

      {:ok, view, _html} = live(conn, path)
      assert has_element?(view, "[role=alert]", "Sync status is unavailable"), scenario
      refute has_element?(view, "#sync-work-status", "No pending or failed sync work found")

      view |> element("button", "Check index configuration") |> render_click()
      html = render(view)
      assert html =~ "Index configuration matches"
      assert has_element?(view, "[role=alert]", "Sync status is unavailable")
    end
  end

  test "configuration mismatch and read errors are explicit rendered states", %{conn: conn} do
    for {scenario, expected} <- [
          {"config-mismatch", "Index configuration differs"},
          {"config-error", "Index configuration could not be checked"}
        ] do
      path =
        "/ops/phase175/sync-drift?" <>
          URI.encode_query(%{
            "schema" => "ScrypathOps.Test.OpsPostB",
            "scenario" => scenario
          })

      {:ok, view, _html} = live(conn, path)
      view |> element("button", "Check index configuration") |> render_click()
      html = render(view)

      assert html =~ expected
      assert has_element?(view, "#sync-work-status", "No pending or failed sync work found")
    end
  end

  test "promotion remains disabled while the standalone checks are not current", %{conn: conn} do
    path =
      "/ops/phase175/sync-drift?" <>
        URI.encode_query(%{
          "schema" => "ScrypathOps.Test.OpsPostB",
          "scenario" => "promotion-blocked"
        })

    {:ok, view, _html} = live(conn, path)
    assert has_element?(view, "#index-promotion button[disabled]", "Promote target index")
    assert Agent.get(Phase175FixtureSource.state_name(), & &1.swap_post_count) == 1
  end

  test "expired retry observation keeps its last-known exact identity", %{conn: conn} do
    schema = "ScrypathOps.Test.OpsPostB"

    {:ok, origin, _html} =
      live(
        conn,
        "/ops/phase175/sync-drift?schema=#{URI.encode_www_form(schema)}&scenario=retry-active"
      )

    origin_socket = :sys.get_state(origin.pid).socket
    operator_context = Map.get(origin_socket.assigns, :operator_context)

    host_context = %{
      host: (origin_socket.host_uri && origin_socket.host_uri.host) || "unknown",
      org: Map.get(operator_context || %{}, :active_org_id),
      schema: schema,
      generation: origin_socket.assigns.context_generation
    }

    receipt = %{
      replacement_job: 17_503,
      attempt: 2,
      task_uid: 17_504,
      operation: :upsert,
      schema: "Elixir." <> schema,
      index: "phase175_ops_post_b",
      source_failure: %{source: :oban, id: 17_502, operation: :upsert},
      endpoint: "http://phase175.fixture.invalid",
      instance: __MODULE__,
      repo: ScrypathOps.Repo,
      prefix: "public",
      node: node(),
      generation: host_context.generation
    }

    {:ok, handle} = ScrypathOps.RecoveryObservation.register(host_context, receipt)

    path =
      "/ops/phase175/sync-drift?" <>
        URI.encode_query(%{
          "schema" => schema,
          "scenario" => "retry-active",
          "recovery" => handle,
          "recovery_generation" => to_string(host_context.generation)
        })

    {:ok, view, _html} = live(conn, path)
    render_async(view)

    assert has_element?(view, "#recovery-observation", "Recovery unknown")
    assert has_element?(view, "#recovery-observation", "17503")
    assert has_element?(view, "#recovery-observation", schema)

    :ok = ScrypathOps.RecoveryObservation.invalidate(handle)
    view |> element("#recovery-observation button", "Refresh recovery status") |> render_click()
    render_async(view)

    assert has_element?(view, "#recovery-observation", "unknown")
    assert has_element?(view, "#recovery-observation", "17503")
    assert has_element?(view, "#recovery-observation", schema)
    assert Agent.get(Phase175FixtureSource.state_name(), & &1.swap_post_count) == 1
  end

  test "stale task result is discarded after the rendered schema changes", %{conn: conn} do
    {:ok, view, _html} =
      live(
        conn,
        "/ops/phase175/sync-drift?schema=ScrypathOps.Test.OpsPostB&scenario=accepted-slow-processing"
      )

    view |> element("#promotion-task-status button", "Check swap status") |> render_click()

    view
    |> form("#sync-drift-schema-form", %{"schema" => "ScrypathOps.Test.OpsPostA"})
    |> render_change()

    render_async(view, 1_000)

    assert :sys.get_state(view.pid).socket.assigns.selected_schema == OpsPostA
    assert has_element?(view, "#promotion-task-status", "Index swap accepted")
    refute has_element?(view, "#promotion-task-status", "Index swap running")
    assert Agent.get(Phase175FixtureSource.state_name(), &Enum.reverse(&1.task_calls)) == [17_501]
    assert Agent.get(Phase175FixtureSource.state_name(), & &1.swap_post_count) == 1
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
