defmodule ScrypathOpsWeb.ControlRoomLiveTest do
  @moduledoc false
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScrypathOps.Test.OpsPostA
  alias ScrypathOps.Test.OpsPostB

  defmodule ControlRoomClient do
    @moduledoc false

    def tasks(filters, config) do
      case Application.get_env(:scrypath_ops, :control_room_client_state, :healthy) do
        :unavailable -> {:error, :backend_unavailable}
        :healthy -> healthy_tasks(filters, config)
      end
    end

    defp healthy_tasks(filters, config) do
      uids = filters[:index_uids] || []

      results =
        config
        |> Keyword.get(:meilisearch_tasks, [])
        |> Enum.filter(&(Map.get(&1, "indexUid") in uids))

      {:ok, %{results: results}}
    end
  end

  setup do
    keys = ~w(
      schema_allowlist backend sync_mode index_prefix meilisearch_url meilisearch_client
      meilisearch_tasks oban oban_queue oban_inspector oban_jobs control_room_client_state
    )a

    previous = Map.new(keys, &{&1, Application.get_env(:scrypath_ops, &1)})
    prev_auth_mode = System.get_env("OPSUI_AUTH_MODE")
    Application.put_env(:scrypath_ops, :schema_allowlist, [])
    Application.delete_env(:scrypath_ops, :backend)
    System.put_env("OPSUI_AUTH_MODE", "sigra")

    on_exit(fn ->
      Enum.each(previous, fn
        {k, nil} -> Application.delete_env(:scrypath_ops, k)
        {k, v} -> Application.put_env(:scrypath_ops, k, v)
      end)

      if is_nil(prev_auth_mode),
        do: System.delete_env("OPSUI_AUTH_MODE"),
        else: System.put_env("OPSUI_AUTH_MODE", prev_auth_mode)
    end)

    :ok
  end

  test "the /ops root is an orientation point with a quiet guide and shared refresh", %{
    conn: conn
  } do
    Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostA])
    {:ok, lv, html} = live(conn, ~p"/ops")

    assert html =~ "Control Room"
    assert has_element?(lv, "[data-ops-refresh][aria-label='Refresh search health']")
    assert has_element?(lv, "[data-testid='control-room-missing-backend']")
    assert html =~ "Search backend not configured."

    assert html =~
             "Configure the Scrypath runtime in the host application before checking search health."

    refute html =~ "Recover search"
    refute html =~ "Start recovery"
    refute has_element?(lv, "[data-testid='control-room-health-link']")
    assert has_element?(lv, "a", "Read the operator guide")
  end

  test "unconfigured schemas show their exact setup guidance without recovery", %{conn: conn} do
    Application.put_env(:scrypath_ops, :schema_allowlist, [])
    Application.put_env(:scrypath_ops, :backend, Scrypath.Meilisearch)

    {:ok, lv, html} = live(conn, ~p"/ops")

    assert has_element?(lv, "[data-testid='control-room-unconfigured']")
    assert html =~ "No search schemas configured"
    assert html =~ "schema allowlist to inspect search health"
    refute has_element?(lv, "[data-testid='control-room-health-link']")
    refute html =~ "Recover search"
    refute html =~ "0 schemas"
  end

  test "degraded state leads with observed reason and affected scope before its single route", %{
    conn: conn
  } do
    put_degraded_posture_config!()

    {:ok, lv, html} = live(conn, ~p"/ops")

    assert has_element?(
             lv,
             "[data-testid='control-room-verdict']",
             "Search health needs attention."
           )

    assert has_element?(lv, "[data-testid='control-room-affected-scope']", "OpsPostA")

    assert has_element?(
             lv,
             "[data-testid='control-room-affected-scope']",
             "backend task(s) failed"
           )

    assert has_element?(
             lv,
             "[data-testid='control-room-health-link'][href='/ops/health']",
             "Inspect Search health"
           )

    assert length(:binary.matches(html, "Inspect Search health")) == 1
    assert html =~ "sync job(s) failed to apply"
    refute html =~ "Recover search"
    assert_before(html, "control-room-affected-scope", "control-room-health-link")
    assert_before(html, "control-room-health-link", "control-room-secondary-intents")

    assert has_element?(
             lv,
             "[data-testid='control-room-secondary-intents'] a[data-testid='control-room-verify-change']"
           )

    assert has_element?(
             lv,
             "[data-testid='control-room-secondary-intents'] a[data-testid='control-room-explore-search']"
           )

    refute has_element?(
             lv,
             "[data-testid='control-room-verdict'] [data-testid='control-room-verify-change']"
           )

    refute has_element?(
             lv,
             "[data-testid='control-room-verdict'] [data-testid='control-room-explore-search']"
           )
  end

  test "healthy wording requires complete evidence and keeps freshness explicit", %{conn: conn} do
    put_healthy_posture_config!()

    {:ok, lv, html} = live(conn, ~p"/ops")

    assert has_element?(lv, "[data-testid='control-room-verdict']", "Search health observed.")
    assert html =~ "No current sync or backend failures were observed across 2 schemas."
    assert html =~ "This check does not prove document freshness."

    assert has_element?(
             lv,
             "[data-testid='control-room-health-link'][href='/ops/health']",
             "Inspect Search health"
           )

    assert has_element?(
             lv,
             "[data-testid='control-room-secondary-intents'] a[data-testid='control-room-verify-change']"
           )

    assert has_element?(
             lv,
             "[data-testid='control-room-secondary-intents'] a[data-testid='control-room-explore-search']"
           )

    assert_before(html, "Observed search health", "No current sync or backend failures")
    assert_before(html, "No current sync or backend failures", "control-room-health-link")
    assert_before(html, "control-room-health-link", "control-room-secondary-intents")
  end

  test "partial refresh retains the prior complete observation and does not announce success", %{
    conn: conn
  } do
    put_healthy_posture_config!()
    {:ok, lv, initial_html} = live(conn, ~p"/ops")

    assert initial_html =~ "No current sync or backend failures were observed across 2 schemas."

    Application.put_env(:scrypath_ops, :control_room_client_state, :unavailable)
    lv |> element("#control-room-refresh") |> render_click()

    refreshed_html = render(lv)

    assert has_element?(
             lv,
             "[data-testid='control-room-refresh-issue']",
             "Search health refresh incomplete."
           )

    assert has_element?(
             lv,
             "[data-testid='control-room-refresh-affected-scope']",
             "schema health could not be checked"
           )

    assert refreshed_html =~ "Last successful observation"
    assert refreshed_html =~ "No current sync or backend failures were observed across 2 schemas."
    assert refreshed_html =~ "Last successful check:"
    refute refreshed_html =~ "Search health refreshed."
    assert has_element?(lv, "[data-testid='control-room-health-link'][href='/ops/health']")
  end

  test "partial refresh without a prior complete observation is labeled accurately", %{conn: conn} do
    put_healthy_posture_config!()
    Application.put_env(:scrypath_ops, :control_room_client_state, :unavailable)
    {:ok, lv, _initial_html} = live(conn, ~p"/ops")

    lv |> element("#control-room-refresh") |> render_click()

    refreshed_html = render(lv)

    assert has_element?(
             lv,
             "[data-testid='control-room-refresh-issue']",
             "No prior complete observation is available"
           )

    assert has_element?(lv, "[data-testid='control-room-verdict']", "Partial observation")
    assert refreshed_html =~ "Incomplete observation checked:"
    refute refreshed_html =~ "The last successful observation is retained below"
    refute refreshed_html =~ "Last successful observation"
    refute refreshed_html =~ "Last successful check:"
    refute refreshed_html =~ "Search health refreshed."
  end

  test "a clean refresh reports success and updates the visible observation", %{conn: conn} do
    put_healthy_posture_config!()
    {:ok, lv, _html} = live(conn, ~p"/ops")

    lv |> element("#control-room-refresh") |> render_click()

    assert render(lv) =~ "Search health refreshed."
    refute has_element?(lv, "[data-testid='control-room-refresh-issue']")
  end

  defp put_degraded_posture_config! do
    put_healthy_posture_config!()

    Application.put_env(:scrypath_ops, :meilisearch_tasks, [
      %{
        "uid" => 401,
        "status" => "failed",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "ctrl_ops_post_a",
        "error" => %{"message" => "index missing"}
      }
    ])
  end

  defp put_healthy_posture_config! do
    Application.put_env(:scrypath_ops, :control_room_client_state, :healthy)
    Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostA, OpsPostB])
    Application.put_env(:scrypath_ops, :backend, Scrypath.Meilisearch)
    Application.put_env(:scrypath_ops, :sync_mode, :manual)
    Application.put_env(:scrypath_ops, :index_prefix, "ctrl")
    Application.put_env(:scrypath_ops, :meilisearch_url, "http://localhost:7700")
    Application.put_env(:scrypath_ops, :meilisearch_client, ControlRoomClient)

    Application.put_env(:scrypath_ops, :meilisearch_tasks, [
      %{
        "uid" => 1,
        "status" => "succeeded",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "ctrl_ops_post_a",
        "finishedAt" => "2026-04-16T18:00:00Z"
      },
      %{
        "uid" => 2,
        "status" => "succeeded",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "ctrl_ops_post_b",
        "finishedAt" => "2026-04-16T18:05:00Z"
      }
    ])
  end

  defp assert_before(html, first, second) do
    assert {first_pos, _} = :binary.match(html, first)
    assert {second_pos, _} = :binary.match(html, second)
    assert first_pos < second_pos
  end
end
