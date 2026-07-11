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
    # the full Control Room chrome (strip + intent cards + ⌘K/orientation footer).
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
    refute html =~ "Refresh posture"
    assert has_element?(lv, "[data-ops-refresh][aria-label='Refresh search trust status']")
    # Overview, not the deep per-schema table (that lives on /ops/posture).
    refute html =~ "data-testid=\"posture-row\""
  end

  test "intent cards route by job to the right surfaces", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/ops")

    assert has_element?(lv, "[data-testid='intent-incident'][href$='/ops/posture']")
    assert has_element?(lv, "[data-testid='intent-change'][href$='/ops/sync-drift']")
    assert has_element?(lv, "[data-testid='intent-explore'][href$='/ops/search']")

    html
    |> card_fragment("intent-incident")
    |> assert_before("ops-intent-card__icon", "ops-intent-card__markers")
  end

  test "unconfigured fleet shows the config empty state but keeps the intent cards", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/ops")

    assert html =~ "No schemas configured"
    assert has_element?(lv, ".ops-muted-panel [data-ops-refresh]")
    assert html =~ "If something looks broken"
    refute html =~ "Something looks broken"
    refute html =~ "Federated"
    assert html =~ "Explore &amp; capture"
  end

  test "degraded fleet marks the recommended recovery card with one earned copper badge", %{
    conn: conn
  } do
    put_degraded_posture_config!()

    {:ok, _lv, html} = live(conn, ~p"/ops")
    incident_card = card_fragment(html, "intent-incident")

    assert incident_card =~ "ops-copper-badge"
    assert incident_card =~ "Federated"
    assert length(:binary.matches(html, "ops-copper-badge")) == 1
  end

  test "healthy fleet summary uses positive health language", %{conn: conn} do
    put_healthy_posture_config!()

    {:ok, _lv, html} = live(conn, ~p"/ops")

    assert html =~ "2 schemas checked"
    assert html =~ "All fetches healthy"
    assert html =~ "All backends healthy"
    refute html =~ "0 fetch error"
    refute html =~ "0 failed backend"
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
