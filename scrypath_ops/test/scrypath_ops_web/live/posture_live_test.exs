defmodule ScrypathOpsWeb.PostureLiveTest do
  @moduledoc false
  # Phase 47 D-10: prod fail-closed `/ops` boot is `OPSUI_AUTH_MODE` + `Application`
  # (`scrypath_ops/docs/SECURITY.md`, `config_prod_guard_test.exs`). D-12: mixed
  # `{:ok, _}` / `{:error, _}` rows surface per-row errors (no fleet-level “all healthy”).
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScrypathOps.Test.OpsPostA
  alias ScrypathOps.Test.OpsPostB
  alias ScrypathOps.Integrations.Sigra.OperatorContext
  alias ScrypathOpsWeb.PostureLive

  defmodule PostureFakeClient do
    def tasks(filters, config) do
      Agent.update(:posture_live_test_state, fn state ->
        Map.update!(state, :tasks_calls, &(&1 + 1))
      end)

      uids = filters[:index_uids] || []
      boom_indexes = ["postlv_ops_post_a", "postlv_ops_post_b"]

      if "postlv_ops_post_a" in uids do
        Process.sleep(Agent.get(:posture_live_test_state, &Map.get(&1, :delay_a, 0)))
      end

      failed_index =
        Enum.find(boom_indexes, fn index ->
          key = if index == "postlv_ops_post_a", do: :fail_a?, else: :fail_b?
          index in uids and Agent.get(:posture_live_test_state, &Map.get(&1, key, false))
        end)

      if failed_index do
        {:error, :boom}
      else
        results =
          Keyword.get(config, :meilisearch_tasks, [])
          |> Enum.filter(&(&1["indexUid"] in uids))

        {:ok, %{results: results}}
      end
    end

    def swap_indexes(_indexes, _config) do
      Agent.update(:posture_live_test_state, fn state ->
        Map.put(state, :swap_called, true)
      end)

      {:ok,
       %{
         "uid" => 101,
         "status" => "succeeded",
         "type" => "indexSwap",
         "indexUid" => "postlv_ops_post_a"
       }}
    end
  end

  defmodule PartialQueueInspector do
    def list_jobs(_schema, _config) do
      if Agent.get(:posture_live_test_state, &Map.get(&1, :fail_queue?, false)),
        do: {:error, :queue_unavailable},
        else: {:ok, [%{id: 99, state: "completed", completed_at: ~U[2026-04-16 18:00:00Z]}]}
    end
  end

  defmodule StatusQueueInspector do
    def list_jobs(_schema, config), do: {:ok, Keyword.get(config, :oban_jobs, [])}
  end

  setup do
    prev_allow = Application.get_env(:scrypath_ops, :schema_allowlist)
    prev_backend = Application.get_env(:scrypath_ops, :backend)
    prev_sync = Application.get_env(:scrypath_ops, :sync_mode)
    prev_prefix = Application.get_env(:scrypath_ops, :index_prefix)
    prev_url = Application.get_env(:scrypath_ops, :meilisearch_url)
    prev_client = Application.get_env(:scrypath_ops, :meilisearch_client)
    prev_tasks = Application.get_env(:scrypath_ops, :meilisearch_tasks)
    prev_oban = Application.get_env(:scrypath_ops, :oban)
    prev_queue = Application.get_env(:scrypath_ops, :oban_queue)
    prev_insp = Application.get_env(:scrypath_ops, :oban_inspector)
    prev_jobs = Application.get_env(:scrypath_ops, :oban_jobs)
    prev_sigra = Application.get_env(:scrypath_ops, :sigra)
    prev_auth_mode = System.get_env("OPSUI_AUTH_MODE")

    Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostA, OpsPostB])
    Application.put_env(:scrypath_ops, :backend, Scrypath.Meilisearch)
    Application.put_env(:scrypath_ops, :sync_mode, :manual)
    Application.put_env(:scrypath_ops, :index_prefix, "postlv")
    Application.put_env(:scrypath_ops, :meilisearch_url, "http://localhost:7700")
    Application.put_env(:scrypath_ops, :meilisearch_client, PostureFakeClient)

    Application.put_env(:scrypath_ops, :sigra,
      sudo_confirm_path: "/sudo/confirm",
      sudo_window: 300
    )

    System.put_env("OPSUI_AUTH_MODE", "sigra")

    if pid = Process.whereis(:posture_live_test_state) do
      Agent.stop(pid)
    end

    # Keep the fixture alive until on_exit/1 performs deterministic cleanup.
    # A linked Agent can exit with the test process before the callback runs.
    {:ok, _pid} =
      Agent.start(fn -> %{tasks_calls: 0, swap_called: false, fail_a?: true, fail_b?: false} end,
        name: :posture_live_test_state
      )

    Application.put_env(:scrypath_ops, :meilisearch_tasks, [
      %{
        "uid" => 2,
        "status" => "succeeded",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "postlv_ops_post_a",
        "finishedAt" => "2026-04-16T17:59:00Z"
      },
      %{
        "uid" => 1,
        "status" => "succeeded",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "postlv_ops_post_b",
        "finishedAt" => "2026-04-16T18:00:00Z"
      }
    ])

    on_exit(fn ->
      restore = fn k, v ->
        if v == nil,
          do: Application.delete_env(:scrypath_ops, k),
          else: Application.put_env(:scrypath_ops, k, v)
      end

      restore.(:schema_allowlist, prev_allow)
      restore.(:backend, prev_backend)
      restore.(:sync_mode, prev_sync)
      restore.(:index_prefix, prev_prefix)
      restore.(:meilisearch_url, prev_url)
      restore.(:meilisearch_client, prev_client)
      restore.(:meilisearch_tasks, prev_tasks)
      restore.(:oban, prev_oban)
      restore.(:oban_queue, prev_queue)
      restore.(:oban_inspector, prev_insp)
      restore.(:oban_jobs, prev_jobs)
      restore.(:sigra, prev_sigra)

      if is_nil(prev_auth_mode),
        do: System.delete_env("OPSUI_AUTH_MODE"),
        else: System.put_env("OPSUI_AUTH_MODE", prev_auth_mode)

      if pid = Process.whereis(:posture_live_test_state) do
        Agent.stop(pid)
      end
    end)

    :ok
  end

  test "renders posture rows with sync_status and surfaces errors first", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/ops/health")

    assert html =~ "data-testid=\"posture-row\""
    assert has_element?(lv, ".ops-disclosure:not([open])", ":boom")
    refute has_element?(lv, ".ops-signal-group > p", ":boom")
    refute has_element?(lv, "[data-testid='posture-next-checks']")
    refute has_element?(lv, "#ops-main a[href='/ops/failed-sync']")
    assert has_element?(lv, "[data-testid='posture-failed-sync-link']")
    assert html =~ "Queue not used"
    assert html =~ "Not observed"
    assert html =~ "Backend tasks"
    assert html =~ "Queue jobs"
    assert html =~ "Last success"
    refute html =~ "Posture"
    assert has_element?(lv, "[data-ops-refresh][aria-label='Refresh search health']")
  end

  test "schema action identity stays with its record when refresh changes worst-first order", %{
    conn: conn
  } do
    Agent.update(:posture_live_test_state, fn state ->
      state |> Map.put(:fail_a?, false) |> Map.put(:fail_b?, true)
    end)

    {:ok, lv, _html} = live(conn, ~p"/ops/health")

    assert has_element?(lv, "#posture-ScrypathOps\\.Test\\.OpsPostB")

    assert has_element?(
             lv,
             "[id='posture-failed-sync-link-ScrypathOps.Test.OpsPostB'][href='/ops/failed-sync?schema=ScrypathOps.Test.OpsPostB']"
           )

    Agent.update(:posture_live_test_state, fn state ->
      state |> Map.put(:fail_a?, true) |> Map.put(:fail_b?, false)
    end)

    render_click(lv, "refresh", %{})
    html = render(lv)

    assert :binary.match(html, ~s(id="posture-ScrypathOps.Test.OpsPostA")) <
             :binary.match(html, ~s(id="posture-ScrypathOps.Test.OpsPostB"))

    assert has_element?(
             lv,
             "[id='posture-failed-sync-link-ScrypathOps.Test.OpsPostB'][href='/ops/failed-sync?schema=ScrypathOps.Test.OpsPostB']"
           )
  end

  test "failed work promotion keeps the same link parents and requires open details", %{
    conn: conn
  } do
    {:ok, lv, _html} = live(conn, ~p"/ops/phase173/health")
    schema = "ScrypathOps.Test.OpsPostB"
    history = "[id='posture-failed-history-#{schema}']"
    action = "#{history} > [id='posture-failed-action-#{schema}'] > a"
    schema_details = "[id='posture-details-#{schema}']"

    assert has_element?(
             lv,
             "#{history}:not([open]) > summary:not([hidden])",
             "Failed work history"
           )

    assert has_element?(lv, "#{action}[id='posture-failed-sync-link-#{schema}']")
    refute has_element?(lv, "#{action}.ops-schema-action")

    for disclosure <- [history, schema_details] do
      assert has_element?(
               lv,
               "#{disclosure}[phx-hook='OpsHealthDetails'][data-ops-required-open='false']"
             )

      mounted =
        lv
        |> element(disclosure)
        |> render()
        |> LazyHTML.from_fragment()
        |> LazyHTML.query("details")
        |> LazyHTML.attribute("phx-mounted")
        |> hd()
        |> Jason.decode!()

      assert mounted == [["ignore_attrs", %{"attrs" => ["open"]}]]
    end

    render_click(lv, "refresh", %{"scenario" => "failed"})

    assert has_element?(lv, "#{history}[open][data-ops-required-open='true'] > summary[hidden]")
    assert has_element?(lv, "#{schema_details}[open][data-ops-required-open='true']")

    assert has_element?(
             lv,
             "#{action}.ops-schema-action[id='posture-failed-sync-link-#{schema}']"
           )

    assert has_element?(lv, "#{action}[href='/ops/phase173/failed-sync?schema=#{schema}']")
    refute has_element?(lv, "[id='posture-sync-link-#{schema}']")

    links =
      lv
      |> render()
      |> LazyHTML.from_document()
      |> LazyHTML.query("[id='posture-failed-sync-link-#{schema}']")
      |> LazyHTML.to_tree()

    assert length(links) == 1
  end

  test "fleet rollup reports failed jobs rather than the number of visible queues", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/ops/phase173/health?scenario=failed")

    assert has_element?(lv, ".ops-metric:has(#health-queue-help) .ops-metric__value", "4")
    assert has_element?(lv, ".ops-metric:has(#health-queue-help)", "Failed queue jobs")
    assert has_element?(lv, ".ops-metric-warning:has(#health-queue-help)")
    refute has_element?(lv, "#health-checks-help")
    refute render(lv) =~ "Queues observed"

    render_click(lv, "refresh", %{"scenario" => "queue-error"})
    assert has_element?(lv, ".ops-metric:has(#health-checks-help) .ops-metric__value", "2")
    assert has_element?(lv, ".ops-metric:has(#health-checks-help)", "Incomplete checks")
    refute has_element?(lv, "#health-queue-help")
    refute has_element?(lv, "#health-backend-help")
    assert has_element?(lv, "[data-testid='posture-row']", "Queue observation unavailable")
    refute has_element?(lv, "[aria-label^='Queue job health'] .ops-signal-metrics")
  end

  test "phase 173 source-error refresh retains the prior completion", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/ops/phase173/health")
    assert html =~ "2026-10-04T13:02:05.123456-04:00"

    refreshed = render_click(lv, "refresh", %{"scenario" => "source-error"})

    assert refreshed =~ "Backend observation unavailable"
    assert refreshed =~ "last success retained from the previous check"
    assert refreshed =~ "2026-10-04T13:02:05.123456-04:00"
  end

  test "healthy schemas start compact with no zero-count cards and errors expand after refresh",
       %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/ops/phase173/health")
    assert has_element?(lv, "#posture-fleet-heading", "Per-schema health")
    assert has_element?(lv, "[data-testid='health-schema-count']", "2 schemas")
    refute has_element?(lv, ".ops-metric")
    refute has_element?(lv, ".ops-schema-health[open]")
    refute has_element?(lv, ".ops-signal-metrics dt", "Pending")
    refute has_element?(lv, ".ops-signal-metrics dt", "Failed")
    refute has_element?(lv, ".ops-signal-metrics dt", "Retrying")
    assert has_element?(lv, "[data-testid='schema-health-status']", "No pending or failed work")
    assert has_element?(lv, ".ops-time__exact", "2026-10-04T13:02:05.123456-04:00")
    assert has_element?(lv, ".ops-disclosure:not([open]) summary", "Failed work history")
    refute has_element?(lv, "a.ops-schema-action[href*='/failed-sync']")

    render_click(lv, "refresh", %{"scenario" => "source-error"})
    assert has_element?(lv, ".ops-schema-health[open]")
    assert has_element?(lv, "[data-testid='schema-health-status']", "Backend status unavailable")
    assert has_element?(lv, ".ops-metric", "Incomplete checks")
    assert has_element?(lv, ".ops-time__exact", "2026-10-04T13:02:05.123456-04:00")

    render_click(lv, "refresh", %{"scenario" => "default"})
    refute has_element?(lv, ".ops-metric")
    refute has_element?(lv, ".ops-schema-health[open]")
  end

  test "pending and retrying work stay visible without zero failure cards", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/ops/phase173/health?scenario=no-success")
    refute has_element?(lv, ".ops-metric")
    assert has_element?(lv, ".ops-schema-health[open] summary", "1 backend task pending")
    assert has_element?(lv, ".ops-signal-metrics dt", "Pending")

    assert has_element?(
             lv,
             "[id='posture-sync-link-ScrypathOps.Test.OpsPostB'][href='/ops/phase173/sync-drift?schema=ScrypathOps.Test.OpsPostB']",
             "Check sync status"
           )

    render_click(lv, "refresh", %{"scenario" => "retrying"})
    refute has_element?(lv, ".ops-metric")
    assert has_element?(lv, ".ops-schema-health[open] summary", "2 queue jobs retrying")
    assert has_element?(lv, ".ops-signal-metrics dt", "Retrying")
    refute has_element?(lv, ".ops-signal-metrics dt", "Pending")

    assert has_element?(
             lv,
             "[id='posture-sync-link-ScrypathOps.Test.OpsPostB'][href='/ops/phase173/sync-drift?schema=ScrypathOps.Test.OpsPostB']",
             "Check sync status"
           )
  end

  test "pending backend work routes the exact non-first schema to sync verification", %{
    conn: conn
  } do
    Agent.update(:posture_live_test_state, &Map.put(&1, :fail_a?, false))

    Application.put_env(:scrypath_ops, :meilisearch_tasks, [
      %{
        "uid" => 801,
        "status" => "processing",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "postlv_ops_post_b"
      }
    ])

    {:ok, lv, _html} = live(conn, ~p"/ops/health")
    row = "[id='posture-ScrypathOps.Test.OpsPostB']"

    assert has_element?(lv, "#{row} summary", "1 backend task pending")

    assert has_element?(
             lv,
             "#{row} a.ops-schema-action[href='/ops/sync-drift?schema=ScrypathOps.Test.OpsPostB']",
             "Check sync status"
           )

    assert has_element?(
             lv,
             "#{row} .ops-disclosure:not([open]) a[href='/ops/failed-sync?schema=ScrypathOps.Test.OpsPostB']"
           )

    refute has_element?(lv, "#{row} a.ops-schema-action[href*='/failed-sync']")
  end

  for {state, summary} <- [
        {"available", "1 queue job pending"},
        {"retryable", "1 queue job retrying"}
      ] do
    test "queue #{state} work uses sync verification while failed history stays optional", %{
      conn: conn
    } do
      Agent.update(:posture_live_test_state, &Map.put(&1, :fail_a?, false))
      Application.put_env(:scrypath_ops, :sync_mode, :oban)
      Application.put_env(:scrypath_ops, :oban, StatusQueueInspector)
      Application.put_env(:scrypath_ops, :oban_inspector, StatusQueueInspector)
      Application.put_env(:scrypath_ops, :oban_queue, :search_sync)
      Application.put_env(:scrypath_ops, :meilisearch_tasks, [])
      Application.put_env(:scrypath_ops, :oban_jobs, [%{id: 802, state: unquote(state)}])

      {:ok, lv, _html} = live(conn, ~p"/ops/health")
      row = "[id='posture-ScrypathOps.Test.OpsPostB']"

      assert has_element?(lv, "#{row} summary", unquote(summary))

      assert has_element?(
               lv,
               "#{row} a.ops-schema-action[href='/ops/sync-drift?schema=ScrypathOps.Test.OpsPostB']",
               "Check sync status"
             )

      assert has_element?(lv, "#{row} .ops-disclosure:not([open]) summary", "Failed work history")
      refute has_element?(lv, "#{row} a.ops-schema-action[href*='/failed-sync']")
    end
  end

  test "observed queue failures take precedence over pending backend work", %{conn: conn} do
    Agent.update(:posture_live_test_state, &Map.put(&1, :fail_a?, false))
    Application.put_env(:scrypath_ops, :sync_mode, :oban)
    Application.put_env(:scrypath_ops, :oban, StatusQueueInspector)
    Application.put_env(:scrypath_ops, :oban_inspector, StatusQueueInspector)
    Application.put_env(:scrypath_ops, :oban_queue, :search_sync)
    Application.put_env(:scrypath_ops, :oban_jobs, [%{id: 803, state: "discarded"}])

    Application.put_env(:scrypath_ops, :meilisearch_tasks, [
      %{
        "uid" => 804,
        "status" => "processing",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "postlv_ops_post_b"
      }
    ])

    {:ok, lv, _html} = live(conn, ~p"/ops/health")
    row = "[id='posture-ScrypathOps.Test.OpsPostB']"

    assert has_element?(lv, "#{row} summary", "1 queue job failed")
    assert has_element?(lv, "#{row} summary", "1 backend task pending")

    assert has_element?(
             lv,
             "#{row} a.ops-schema-action[href='/ops/failed-sync?schema=ScrypathOps.Test.OpsPostB']",
             "View failed sync work"
           )

    refute has_element?(lv, "#{row} [data-testid='posture-sync-link']")
    refute has_element?(lv, "#{row} .ops-disclosure summary", "Failed work history")
  end

  test "unavailable health keeps uncertainty visible and diagnostics disclosed at the exact scope",
       %{
         conn: conn
       } do
    {:ok, lv, _html} = live(conn, ~p"/ops/health")
    row = "[id='posture-ScrypathOps.Test.OpsPostA']"

    assert has_element?(lv, "#{row} summary", "Backend status unavailable")
    assert has_element?(lv, "#{row} .ops-signal-group > p", "Backend observation unavailable")
    assert has_element?(lv, "#{row} .ops-signal-group > p", "then refresh search health")
    refute has_element?(lv, "#{row} .ops-signal-group > p", ":boom")
    refute has_element?(lv, "#{row} .ops-time__reason")
    assert has_element?(lv, "#{row} .ops-disclosure:not([open])", ":boom")

    assert has_element?(
             lv,
             "#{row} a.ops-schema-action[href='/ops/sync-drift?schema=ScrypathOps.Test.OpsPostA']",
             "Check sync status"
           )

    refute has_element?(
             lv,
             "#{row} [data-testid='schema-health-status']",
             "No pending or failed work"
           )
  end

  test "manual sync does not turn an unused queue into an unavailable check", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/ops/phase173/health?scenario=manual")
    refute has_element?(lv, ".ops-metric")
    refute has_element?(lv, ".ops-schema-health[open]")
    refute has_element?(lv, "[data-testid='schema-health-status']", "Queue status unavailable")
    assert has_element?(lv, ".ops-schema-health__details", "Queue not used in manual sync mode")
  end

  test "phase 173 degraded health hides zero metrics and localizes failure cues", %{
    conn: conn
  } do
    {:ok, lv, html} = live(conn, ~p"/ops/phase173/health?scenario=failed")

    assert html =~ "Sync needs attention"

    assert has_element?(
             lv,
             "#posture-ScrypathOps\\.Test\\.OpsPostA .ops-signal-group[aria-label^='Backend task health']",
             "Failed"
           )

    assert html =~ "failed"
    refute html =~ "document freshness"
    refute has_element?(lv, ".ops-metric-success")
    assert has_element?(lv, ".ops-metric-warning")
    assert has_element?(lv, ".ops-metric__cue[aria-hidden='true']")
    assert has_element?(lv, ".ops-schema-signal-card--warning")
    assert has_element?(lv, "a[data-testid='posture-failed-sync-link']")
  end

  test "renders backend success age from the observation snapshot with exact source evidence", %{
    conn: conn
  } do
    {:ok, lv, _html} = live(conn, ~p"/ops/phase173/health")

    time =
      lv
      |> element(
        "[id='posture-ScrypathOps.Test.OpsPostA'] .ops-signal-group[aria-label^='Backend task health']"
      )
      |> render()

    assert time =~ "2 days ago"
    assert time =~ "2026-10-04T13:02:05.123456-04:00"
    assert time =~ "UTC equivalent"

    assert has_element?(
             lv,
             "[id='ops-time-ScrypathOps.Test.OpsPostA-backend-success'][data-ops-timestamp='2026-10-04T13:02:05.123456-04:00']"
           )

    refute has_element?(lv, "#search-health-refresh .ops-time__copy")

    html = render_patch(lv, ~p"/ops/phase173/health?scenario=default")
    assert html =~ "2 days ago"
    assert html =~ "2026-10-04T13:02:05.123456-04:00"
  end

  test "does not offer copy when last-success source time is invalid", %{conn: conn} do
    tasks = Application.get_env(:scrypath_ops, :meilisearch_tasks)

    Application.put_env(
      :scrypath_ops,
      :meilisearch_tasks,
      Enum.map(tasks, &Map.put(&1, "finishedAt", "not-a-time"))
    )

    {:ok, lv, _html} = live(conn, ~p"/ops/health")

    refute has_element?(lv, "[id='posture-ScrypathOps.Test.OpsPostA'] .ops-time__copy")
    refute has_element?(lv, "[id='posture-ScrypathOps.Test.OpsPostB'] .ops-time__copy")
  end

  test "retains the source-local last success when a later fetch fails", %{conn: conn} do
    Agent.update(:posture_live_test_state, &Map.put(&1, :fail_a?, false))
    {:ok, lv, _html} = live(conn, ~p"/ops/health")

    row = lv |> element("[id='posture-ScrypathOps.Test.OpsPostA']") |> render()
    assert row =~ "Apr 16, 2026 at 17:59 UTC"

    Agent.update(:posture_live_test_state, &Map.put(&1, :fail_a?, true))
    lv |> element("#search-health-refresh") |> render_click()
    row = lv |> element("[id='posture-ScrypathOps.Test.OpsPostA']") |> render()

    assert row =~ "Backend observation unavailable"
    assert row =~ "last success retained from the previous check"
    assert row =~ "2026-04-16T17:59:00Z"
  end

  test "diagnosis uses schema-specific recovery and setup still has next-step guidance", %{
    conn: conn
  } do
    {:ok, lv, _html} = live(conn, ~p"/ops/health")
    refute has_element?(lv, "[data-testid='posture-next-checks']")
    assert has_element?(lv, "#ops-main", "Sync needs attention")
    assert has_element?(lv, "a[href='/ops/failed-sync?schema=ScrypathOps.Test.OpsPostB']")

    Application.put_env(:scrypath_ops, :schema_allowlist, [])
    {:ok, setup, _html} = live(conn, ~p"/ops/health")
    assert has_element?(setup, "[data-testid='posture-next-checks']", "Setup guide")
    refute has_element?(setup, "[data-testid='posture-row']")
  end

  test "posture promotion handoff keeps the selected schema and does not swap directly" do
    socket =
      posture_socket(%{
        local_ui_state: %{expanded: [:details]}
      })

    assert {:noreply, updated_socket} =
             PostureLive.handle_event(
               "swap_live",
               %{"schema" => "ScrypathOps.Test.OpsPostA"},
               socket
             )

    assert inspect(updated_socket.redirected) =~
             "/ops/sync-drift?schema=ScrypathOps.Test.OpsPostA"

    refute Agent.get(:posture_live_test_state, & &1.swap_called)
    assert Agent.get(:posture_live_test_state, & &1.tasks_calls) == 0
    assert updated_socket.assigns.local_ui_state == %{expanded: [:details]}
    assert updated_socket.assigns.posture_rows == []
  end

  test "posture promotion handoff performs no mutation while impersonating" do
    socket =
      posture_socket(%{
        operator_context: operator_context(impersonator: "impersonator_789"),
        local_ui_state: :keep
      })

    assert {:noreply, updated_socket} =
             PostureLive.handle_event(
               "swap_live",
               %{"schema" => "ScrypathOps.Test.OpsPostA"},
               socket
             )

    assert inspect(updated_socket.redirected) =~
             "/ops/sync-drift?schema=ScrypathOps.Test.OpsPostA"

    assert Agent.get(:posture_live_test_state, & &1.swap_called) != true
    assert Agent.get(:posture_live_test_state, & &1.tasks_calls) == 0
    assert updated_socket.assigns.local_ui_state == :keep
    assert updated_socket.assigns.posture_rows == []
  end

  test "posture promotion handoff performs no mutation before sudo confirmation" do
    socket =
      posture_socket(%{
        operator_context:
          operator_context(sudo_at: DateTime.add(DateTime.utc_now(), -600, :second)),
        local_ui_state: :keep
      })

    assert {:noreply, updated_socket} =
             PostureLive.handle_event(
               "swap_live",
               %{"schema" => "ScrypathOps.Test.OpsPostA"},
               socket
             )

    assert inspect(updated_socket.redirected) =~
             "/ops/sync-drift?schema=ScrypathOps.Test.OpsPostA"

    assert Agent.get(:posture_live_test_state, & &1.swap_called) != true
    assert Agent.get(:posture_live_test_state, & &1.tasks_calls) == 0
    assert updated_socket.assigns.local_ui_state == :keep
  end

  test "swap live rejects non-allowlisted module strings before gating" do
    mod_str = "ScrypathOps.Test.NotAllowlisted#{System.unique_integer([:positive])}"

    socket =
      posture_socket(%{
        schema_allowlist: [OpsPostA],
        local_ui_state: :keep
      })

    assert {:noreply, updated_socket} =
             PostureLive.handle_event("swap_live", %{"schema" => mod_str}, socket)

    assert flash_value(updated_socket, "error") =~ "allowlisted"
    assert updated_socket.assigns.local_ui_state == :keep
  end

  defp posture_socket(overrides) do
    scope = %{
      user: %{id: "user_123"},
      active_organization: %{id: "org_456"},
      impersonating_from: Map.get(overrides, :impersonating_from)
    }

    operator_context = Map.get(overrides, :operator_context, operator_context())

    base_assigns = %{
      __changed__: %{},
      flash: %{},
      page_title: "Search health",
      schema_allowlist: [OpsPostA, OpsPostB],
      scrypath_opts: posture_scrypath_opts(),
      auto_refresh: false,
      posture_rows: [],
      aggregate_error_count: 0,
      last_refresh_at: nil,
      posture_headline: "—",
      posture_evidence: "",
      next_checks: [],
      current_scope: scope,
      mount_path: "/ops",
      operator_context: operator_context,
      local_ui_state: nil
    }

    %Phoenix.LiveView.Socket{
      assigns: Map.merge(base_assigns, overrides),
      host_uri: URI.parse("https://scrypath.example/ops/health")
    }
  end

  defp posture_scrypath_opts do
    [
      backend: Scrypath.Meilisearch,
      sync_mode: :manual,
      index_prefix: "postlv",
      meilisearch_url: "http://localhost:7700",
      meilisearch_client: PostureFakeClient,
      meilisearch_tasks: [
        %{
          "uid" => 1,
          "status" => "succeeded",
          "type" => "documentAdditionOrUpdate",
          "indexUid" => "postlv_ops_post_b",
          "finishedAt" => "2026-04-16T18:00:00Z"
        }
      ]
    ]
  end

  defp operator_context(opts \\ []) do
    scope = %{
      user: %{id: "user_123"},
      active_organization: %{id: "org_456"},
      impersonating_from:
        Keyword.get(opts, :impersonator) && %{id: Keyword.fetch!(opts, :impersonator)}
    }

    session = %Sigra.Session{
      sudo_at: Keyword.get(opts, :sudo_at, DateTime.add(DateTime.utc_now(), -60, :second)),
      impersonator_user_id: Keyword.get(opts, :impersonator)
    }

    OperatorContext.build(scope, session)
  end

  defp flash_value(socket, key) do
    socket.assigns |> Map.get(:flash, %{}) |> Map.get(key)
  end

  test "partial queue errors retain only the failed source and render current backend data", %{
    conn: conn
  } do
    Agent.update(:posture_live_test_state, &Map.put(&1, :fail_a?, false))
    Application.put_env(:scrypath_ops, :sync_mode, :oban)
    Application.put_env(:scrypath_ops, :oban_inspector, PartialQueueInspector)
    Application.put_env(:scrypath_ops, :oban, PartialQueueInspector)
    Application.put_env(:scrypath_ops, :oban_queue, :search_sync)
    {:ok, view, _html} = live(conn, ~p"/ops/health")
    Agent.update(:posture_live_test_state, &Map.put(&1, :fail_queue?, true))
    html = render_click(view, "refresh", %{})
    assert html =~ "queue_unavailable"
    assert html =~ "Queue observation unavailable"
    assert html =~ "last success retained"

    assert has_element?(
             view,
             "#posture-ScrypathOps\\.Test\\.OpsPostA .ops-signal-group:first-child .ops-signal-metrics"
           )

    refute html =~ "Backend observation unavailable"

    Agent.update(:posture_live_test_state, &Map.put(&1, :fail_a?, true))
    render_click(view, "refresh", %{})

    assert has_element?(
             view,
             "#posture-ScrypathOps\\.Test\\.OpsPostA .ops-signal-group:nth-child(2) .ops-time__exact",
             "2026-04-16T18:00:00Z"
           )

    assert has_element?(
             view,
             "#posture-ScrypathOps\\.Test\\.OpsPostA .ops-signal-group:nth-child(2)",
             "queue_unavailable"
           )
  end

  test "timed-out schemas retain their own prior evidence" do
    Agent.update(:posture_live_test_state, &Map.put(&1, :fail_a?, false))

    opts = [
      backend: Scrypath.Meilisearch,
      sync_mode: :manual,
      index_prefix: "postlv",
      meilisearch_url: "http://localhost:7700",
      meilisearch_client: PostureFakeClient,
      meilisearch_tasks: Application.get_env(:scrypath_ops, :meilisearch_tasks)
    ]

    prior = ScrypathOps.Posture.summary([OpsPostA, OpsPostB], opts, ~U[2026-04-16 18:01:00Z])
    Agent.update(:posture_live_test_state, &Map.put(&1, :delay_a, 16_000))

    current =
      ScrypathOps.Posture.summary(
        [OpsPostA, OpsPostB],
        opts,
        ~U[2026-04-17 18:01:00Z],
        prior
      )

    assert {OpsPostA, {:error, {:async_stream, :timeout}}} in current.rows
    refute Enum.any?(current.rows, fn {mod, _} -> mod == :posture_stream end)
    assert ScrypathOps.Posture.last_success_ref(current, OpsPostA, :backend).retained?

    assert ScrypathOps.Posture.last_success_ref(current, OpsPostA, :backend).observed_at ==
             prior.refreshed_at

    assert ScrypathOps.Posture.last_success_ref(current, OpsPostB, :backend).observed_at ==
             current.refreshed_at
  end

  test "error-row rendering tolerates invalid runtime configuration", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/health")

    assigns =
      view.pid
      |> :sys.get_state()
      |> Map.fetch!(:socket)
      |> Map.fetch!(:assigns)
      |> Map.put(:scrypath_opts, sync_mode: :invalid_mode)
      |> Map.put(:posture_rows, {:ok, [{OpsPostA, {:error, :invalid_configuration}}]})

    html = render_component(&PostureLive.render/1, assigns)
    assert html =~ "invalid_configuration"
    assert html =~ "Backend observation unavailable"
    assert html =~ "Queue observation unavailable"
    assert html =~ "/ops/sync-drift?schema=ScrypathOps.Test.OpsPostA"
    assert html =~ "Check sync status"
  end
end
