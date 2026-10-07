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
      boom_index = "postlv_ops_post_a"

      if boom_index in uids do
        Process.sleep(Agent.get(:posture_live_test_state, &Map.get(&1, :delay_a, 0)))
      end

      if boom_index in uids and Agent.get(:posture_live_test_state, & &1.fail_a?) do
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
      Agent.start(fn -> %{tasks_calls: 0, swap_called: false, fail_a?: true} end,
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
    assert html =~ "fetch error: :boom"
    assert html =~ "Queue not used"
    assert html =~ "Not observed"
    assert html =~ "Backend tasks"
    assert html =~ "Queue jobs"
    assert html =~ "Last success"
    refute html =~ "Posture"
    assert has_element?(lv, "[data-ops-refresh][aria-label='Refresh search health']")
  end

  test "phase 173 source-error refresh retains the prior completion", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/ops/phase173/health")
    assert html =~ "2026-10-04T13:02:05.123456-04:00"

    refreshed = render_click(lv, "refresh", %{"scenario" => "source-error"})

    assert refreshed =~ "Backend observation unavailable"
    assert refreshed =~ "last success retained from the previous check"
    assert refreshed =~ "2026-10-04T13:02:05.123456-04:00"
  end

  test "phase 173 degraded health keeps zero metrics neutral and localizes failure cues", %{
    conn: conn
  } do
    {:ok, lv, html} = live(conn, ~p"/ops/phase173/health?scenario=failed")

    assert html =~ "Degraded"
    assert html =~ "backend failed"
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
        "[id='posture-ScrypathOps.Test.OpsPostA'] .ops-signal-group[aria-label^='Backend task signals']"
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

  test "posture shows next checks block with ordered items and failed-sync egress", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/ops/health")

    assert has_element?(lv, "[data-testid='posture-next-checks']")

    html = render(lv)
    assert html =~ "Degraded"
    assert html =~ "/ops/failed-sync"
    assert html =~ "/ops/sync-drift"
    assert has_element?(lv, "a[href='/ops/failed-sync?schema=ScrypathOps.Test.OpsPostB']")

    [_before, rest] = String.split(html, ~s(data-testid="posture-next-checks"), parts: 2)
    [section | _] = String.split(rest, "</section>", parts: 2)
    li_opens = Regex.scan(~r/<li[\s>]/, section)
    assert length(li_opens) <= 5
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
  end
end
