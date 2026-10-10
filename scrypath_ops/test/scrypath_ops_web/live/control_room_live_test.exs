defmodule ScrypathOpsWeb.ControlRoomLiveTest do
  @moduledoc false
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScrypathOps.Test.OpsPostA
  alias ScrypathOps.Test.OpsPostB

  defmodule ControlRoomHealthyClient do
    @moduledoc false
    def tasks(filters, config) do
      uids = filters[:index_uids] || []

      results =
        config
        |> Keyword.get(:meilisearch_tasks, [])
        |> Enum.filter(&(Map.get(&1, "indexUid") in uids))

      {:ok, %{results: results}}
    end
  end

  defmodule ControlRoomErrorClient do
    @moduledoc false
    def tasks(_filters, _config), do: {:error, :fixture_timeout}
  end

  setup do
    keys = ~w(
      schema_allowlist backend sync_mode index_prefix meilisearch_url meilisearch_client
      meilisearch_tasks oban oban_queue oban_inspector oban_jobs
    )a

    previous = Map.new(keys, &{&1, Application.get_env(:scrypath_ops, &1)})
    prev_auth_mode = System.get_env("OPSUI_AUTH_MODE")

    # Empty allowlist keeps this test free of a live backend while still exercising
    # the full Control Room chrome (strip + intent cards + shell shortcut).
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

  test "refresh checks the current allowlist without retaining an overview selection", %{
    conn: conn
  } do
    put_healthy_posture_config!()

    {:ok, lv, _} =
      live(conn, "/ops?schema=ScrypathOps.Test.OpsPostA") |> follow_redirect(conn, "/ops")

    Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostB])
    html = render_click(lv, "refresh", %{})
    refute html =~ "That schema is unavailable"
    assigns = :sys.get_state(lv.pid).socket.assigns
    assert assigns.schema_allowlist == [OpsPostB]
    assert assigns.recovery_target == nil
    refute has_element?(lv, "#ops-command-palette-destinations[data-recovery-target]")
    assert has_element?(lv, "#control-room-health-link[href='/ops/health']")
    refute has_element?(lv, "[data-testid='shell-recovery-target']", "ScrypathOps.Test.OpsPostA")
  end

  test "the /ops root renders the Control Room landing, not the posture table", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/ops")

    assert html =~ "Control Room"
    assert html =~ "What do you need to do?"

    assert html =~
             "Monitor search sync, verify a change, or explore search results."

    refute html =~ "Posture"
    assert has_element?(lv, "[data-ops-refresh][aria-label='Refresh search health']")
    # Overview, not the deep per-schema table (that lives on /ops/health).
    refute html =~ "data-testid=\"posture-row\""
  end

  test "configured recovery entry and intent cards route to the right surfaces", %{conn: conn} do
    put_healthy_posture_config!()
    query = URI.encode_query(%{"schema" => ScrypathOps.OperatorSelection.canonical(OpsPostA)})
    {:ok, lv, html} = live(conn, "/ops?" <> query) |> follow_redirect(conn, "/ops")

    assert has_element?(
             lv,
             "[data-testid='control-room-health-link'][href='/ops/health']"
           )

    refute has_element?(lv, "[data-testid='intent-incident']")
    assert has_element?(lv, "[data-testid='intent-change'][href$='/ops/sync-drift']")
    assert has_element?(lv, "[data-testid='intent-explore'][href$='/ops/search']")
    assert html =~ "Check sync status and index configuration before promoting a change."
    assert html =~ "Inspect a search result, then save a useful check."

    html
    |> card_fragment("intent-change")
    |> assert_before("ops-intent-card__icon", "ops-intent-card__markers")
  end

  test "old overview selection is discarded from the URL and both shell navs", %{
    conn: conn
  } do
    put_healthy_posture_config!()
    query = URI.encode_query(%{"schema" => ScrypathOps.OperatorSelection.canonical(OpsPostA)})
    {:ok, lv, html} = live(conn, "/ops?" <> query) |> follow_redirect(conn, "/ops")

    refute html =~ "Selected schema"
    refute has_element?(lv, "[data-testid='recovery-target']")

    for destination <- ["health", "failed-sync", "sync-drift"] do
      href = "/ops/#{destination}"
      assert has_element?(lv, ".ops-sidebar a[href='#{href}']")
      assert has_element?(lv, "#ops-mobile-nav a[href='#{href}']")
    end

    assert html =~ ~s(href="/ops/search")
    assert html =~ ~s(href="/ops/playbooks")
  end

  test "invalid explicit recovery target is not propagated into shell navigation", %{conn: conn} do
    put_healthy_posture_config!()

    {:ok, _lv, html} =
      live(conn, "/ops?schema=ScrypathOps.Test.Unknown") |> follow_redirect(conn, "/ops")

    refute html =~ "That schema is unavailable"
    refute html =~ "Selected schema"

    for destination <- ["health", "failed-sync", "sync-drift"] do
      refute html =~ ~s(href="/ops/#{destination}?schema=)
    end
  end

  test "unconfigured fleet shows the config empty state but keeps the intent cards", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/ops")

    assert html =~ "No schemas configured"
    assert has_element?(lv, "[data-ops-refresh][aria-label='Refresh search health']")
    refute has_element?(lv, ".ops-muted-panel [data-ops-refresh]")
    assert has_element?(lv, "#ops-main", "Monitor search sync")
    refute html =~ "If something looks broken"
    refute html =~ "Federated"
    assert html =~ "Inspect and save a search check"
  end

  test "Control Room offers one shortcut hint at the surface jump control", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/ops")

    assert length(:binary.matches(html, "data-ops-command-open")) == 1
    assert has_element?(lv, "[data-ops-command-open]", "Jump to surface")
    assert has_element?(lv, "[data-ops-command-open] .ops-kbd", "⌘K")
  end

  test "degraded fleet names the observed cause without claiming federation", %{
    conn: conn
  } do
    put_degraded_posture_config!()

    {:ok, _lv, html} = live(conn, ~p"/ops")

    assert html =~ "1 sync failure needs review"
    refute html =~ "Federated"
  end

  test "healthy fleet summary uses positive health language", %{conn: conn} do
    put_healthy_posture_config!()

    {:ok, _lv, html} = live(conn, ~p"/ops")

    refute html =~ "2 schemas checked"
    refute html =~ "No affected schemas"
    refute html =~ "schema fetch errors"
    assert html =~ "No sync failures found"
    refute html =~ "All fetches healthy"
    refute html =~ "All backends healthy"
    refute html =~ "0 fetch error"
    refute html =~ "0 failed backend"
  end

  test "healthy Control Room presents one evidence-bounded Search health entry", %{conn: conn} do
    put_healthy_posture_config!()

    {:ok, lv, html} = live(conn, ~p"/ops")

    assert has_element?(lv, "#control-room-health-link", "Review Search health")
    refute html =~ "View search health"
    refute html =~ "All backends healthy"
    assert html =~ "No sync failures found"
  end

  test "default Control Room is a fleet overview with no implicit schema or scoped handoff", %{
    conn: conn
  } do
    put_healthy_posture_config!()

    Application.put_env(:scrypath_ops, :meilisearch_tasks, [
      %{
        "uid" => 9,
        "status" => "failed",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "ctrl_ops_post_b"
      }
    ])

    {:ok, lv, _html} = live(conn, ~p"/ops")

    refute has_element?(lv, "[data-testid='recovery-target']")
    refute has_element?(lv, "#ops-command-palette-destinations[data-recovery-target]")
    assert :sys.get_state(lv.pid).socket.assigns.recovery_target == nil
    assert has_element?(lv, "[data-testid='control-room-affected-scope']", "OpsPostB")
    refute has_element?(lv, "[data-testid='control-room-affected-scope']", "OpsPostA")
    assert has_element?(lv, "#control-room-health-link[href='/ops/health']")

    for destination <- ["health", "failed-sync", "sync-drift"] do
      assert has_element?(lv, ".ops-sidebar a[href='/ops/#{destination}']")
      assert has_element?(lv, "#ops-mobile-nav a[href='/ops/#{destination}']")
      assert has_element?(lv, "#ops-command-palette-destinations a[href='/ops/#{destination}']")
    end

    render_click(lv, "refresh")
    refute has_element?(lv, "[data-testid='recovery-target']")

    {:ok, health, _} =
      lv |> element("#control-room-health-link") |> render_click() |> follow_redirect(conn)

    refute has_element?(health, "[data-testid='recovery-target']")
    assert :sys.get_state(health.pid).socket.assigns.recovery_target == nil
    assert has_element?(health, "[id='posture-ScrypathOps.Test.OpsPostA']")
    assert has_element?(health, "[id='posture-ScrypathOps.Test.OpsPostB']")
    refute has_element?(health, "a[href*='schema=nil']")
  end

  test "old schema query does not hide a different schema needing attention", %{conn: conn} do
    put_healthy_posture_config!()

    Application.put_env(:scrypath_ops, :meilisearch_tasks, [
      %{
        "uid" => 9,
        "status" => "failed",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "ctrl_ops_post_b",
        "error" => %{"message" => "index missing"}
      }
    ])

    query = URI.encode_query(%{"schema" => ScrypathOps.OperatorSelection.canonical(OpsPostA)})
    {:ok, lv, html} = live(conn, "/ops?" <> query) |> follow_redirect(conn, "/ops")

    assert has_element?(lv, "[data-testid='control-room-affected-scope']", "OpsPostB")
    refute html =~ "Selected schema"
    refute has_element?(lv, "[data-testid='recovery-target']")
    refute has_element?(lv, "[data-testid='control-room-affected-scope']", "OpsPostA")
    assert has_element?(lv, "#control-room-health-link[href='/ops/health']")
  end

  test "refresh names unavailable evidence and keeps the previous successful observation", %{
    conn: conn
  } do
    put_healthy_posture_config!()
    {:ok, lv, html} = live(conn, ~p"/ops")

    assert html =~ "No sync failures found"

    Application.put_env(:scrypath_ops, :meilisearch_client, ControlRoomErrorClient)
    refreshed = render_click(lv, "refresh")

    assert has_element?(
             lv,
             "[data-testid='control-room-observation-error']",
             "Backend observation unavailable"
           )

    assert refreshed =~ "Backend observation unavailable"
    assert refreshed =~ "fixture_timeout"
    assert refreshed =~ "last success retained from the previous check"
    assert refreshed =~ "2026-04-16T18:00:00Z"
    assert refreshed =~ "Refresh search health"
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
    Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostA, OpsPostB])
    Application.put_env(:scrypath_ops, :backend, Scrypath.Meilisearch)
    Application.put_env(:scrypath_ops, :sync_mode, :manual)
    Application.put_env(:scrypath_ops, :index_prefix, "ctrl")
    Application.put_env(:scrypath_ops, :meilisearch_url, "http://localhost:7700")
    Application.put_env(:scrypath_ops, :meilisearch_client, ControlRoomHealthyClient)

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

  defp card_fragment(html, testid) do
    [_before, rest] = String.split(html, ~s(data-testid="#{testid}"), parts: 2)
    [fragment | _] = String.split(rest, "</a>", parts: 2)
    fragment
  end

  defp assert_before(fragment, first, second) do
    assert {first_pos, _} = :binary.match(fragment, first)
    assert {second_pos, _} = :binary.match(fragment, second)
    assert first_pos < second_pos
  end
end
