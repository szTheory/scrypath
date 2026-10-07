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

  test "the /ops root renders the Control Room landing, not the posture table", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/ops")

    assert html =~ "Control Room"
    assert html =~ "What do you need to do?"

    assert html =~
             "Recover search, verify a change before promotion, or inspect and save a useful search check."

    refute html =~ "Posture"
    assert has_element?(lv, "[data-ops-refresh][aria-label='Refresh search health']")
    # Overview, not the deep per-schema table (that lives on /ops/health).
    refute html =~ "data-testid=\"posture-row\""
  end

  test "configured recovery entry and intent cards route to the right surfaces", %{conn: conn} do
    put_healthy_posture_config!()
    query = URI.encode_query(%{"schema" => ScrypathOps.OperatorSelection.canonical(OpsPostA)})
    {:ok, lv, html} = live(conn, "/ops?" <> query)

    assert has_element?(
             lv,
             "[data-testid='control-room-health-link'][href='/ops/health?#{query}']"
           )

    refute has_element?(lv, "[data-testid='intent-incident']")
    assert has_element?(lv, "[data-testid='intent-change'][href$='/ops/sync-drift']")
    assert has_element?(lv, "[data-testid='intent-explore'][href$='/ops/search']")
    assert html =~ "Verify a change before promotion."
    assert html =~ "Inspect a search result, then save a useful check."

    html
    |> card_fragment("intent-change")
    |> assert_before("ops-intent-card__icon", "ops-intent-card__markers")
  end

  test "selected recovery target is named in both shell navs and scopes recovery links", %{
    conn: conn
  } do
    put_healthy_posture_config!()
    query = URI.encode_query(%{"schema" => ScrypathOps.OperatorSelection.canonical(OpsPostA)})
    {:ok, lv, html} = live(conn, "/ops?" <> query)

    assert html =~ "Recovery target"
    assert html =~ "ScrypathOps.Test.OpsPostA"

    for destination <- ["health", "failed-sync", "sync-drift"] do
      href = "/ops/#{destination}?#{query}"
      assert has_element?(lv, ".ops-sidebar a[href='#{href}']")
      assert has_element?(lv, "#ops-mobile-nav a[href='#{href}']")
    end

    assert html =~ ~s(href="/ops/search")
    assert html =~ ~s(href="/ops/playbooks")
  end

  test "invalid explicit recovery target is not propagated into shell navigation", %{conn: conn} do
    put_healthy_posture_config!()
    {:ok, _lv, html} = live(conn, "/ops?schema=ScrypathOps.Test.Unknown")

    assert html =~ "That schema is unavailable"
    refute html =~ "Recovery target"

    for destination <- ["health", "failed-sync", "sync-drift"] do
      refute html =~ ~s(href="/ops/#{destination}?schema=)
    end
  end

  test "unconfigured fleet shows the config empty state but keeps the intent cards", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/ops")

    assert html =~ "No schemas configured"
    assert has_element?(lv, "[data-ops-refresh][aria-label='Refresh search health']")
    refute has_element?(lv, ".ops-muted-panel [data-ops-refresh]")
    assert html =~ "Recover search"
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

    assert html =~ "1 sync job(s) failed to apply"
    refute html =~ "Federated"
  end

  test "healthy fleet summary uses positive health language", %{conn: conn} do
    put_healthy_posture_config!()

    {:ok, _lv, html} = live(conn, ~p"/ops")

    assert html =~ "2 schemas checked"
    assert html =~ "No fetch errors observed"
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
    assert html =~ "No fetch errors observed"
  end

  test "degraded scope stays separate from the selected recovery target", %{conn: conn} do
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
    {:ok, lv, html} = live(conn, "/ops?" <> query)

    assert has_element?(lv, "[data-testid='control-room-affected-scope']", "OpsPostB")
    assert html =~ "Recovery target:"
    assert html =~ "ScrypathOps.Test.OpsPostA"
    refute has_element?(lv, "[data-testid='control-room-affected-scope']", "OpsPostA")
    assert has_element?(lv, "#control-room-health-link[href='/ops/health?#{query}']")
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
