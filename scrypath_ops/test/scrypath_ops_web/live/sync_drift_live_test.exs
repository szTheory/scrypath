defmodule ScrypathOpsWeb.SyncDriftLiveTest do
  @moduledoc false
  # Phase 47 D-10: SECURITY + prod guard tests. D-14: reconcile on mount does not bundle
  # `include_index_contract_drift`; drift loads only via explicit control.
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScrypathOps.Test.OpsPostA
  alias ScrypathOps.Test.OpsPostB
  alias ScrypathOps.Integrations.Sigra.OperatorContext
  alias ScrypathOps.RecoveryObservation
  alias ScrypathOpsWeb.SyncDriftLive
  alias Scrypath.Operations.Task, as: OperationTask

  defmodule SyncDriftClient do
    def tasks(filters, config) do
      Agent.update(:sync_drift_live_test_state, fn state ->
        Map.update!(state, :tasks_calls, &(&1 + 1))
      end)

      case Agent.get(:sync_drift_live_test_state, &Map.get(&1, :tasks_error)) do
        nil ->
          tasks =
            if Agent.get(:sync_drift_live_test_state, &Map.get(&1, :ready, false)) and
                 Keyword.get(filters, :index_uids) == ["sdv_ops_post_a__reindex"] do
              [
                %{
                  "uid" => 100,
                  "status" => "succeeded",
                  "type" => "indexCreation",
                  "indexUid" => "sdv_ops_post_a__reindex"
                }
              ]
            else
              Keyword.get(config, :meilisearch_tasks, [])
            end

          {:ok, %{results: tasks}}

        reason ->
          {:error, reason}
      end
    end

    def get_settings(_index, _config) do
      Agent.update(:sync_drift_live_test_state, fn state ->
        Map.update!(state, :settings_calls, &(&1 + 1))
      end)

      if Agent.get(:sync_drift_live_test_state, &Map.get(&1, :ready, false)) do
        default_settings = %{
          "searchableAttributes" => ["*"],
          "filterableAttributes" => [],
          "sortableAttributes" => []
        }

        {:ok,
         Agent.get(:sync_drift_live_test_state, &Map.get(&1, :applied_settings, default_settings))}
      else
        {:error, :settings}
      end
    end

    def swap_indexes(indexes, _config) do
      Agent.update(:sync_drift_live_test_state, fn state ->
        state
        |> Map.put(:swap_called, true)
        |> Map.update!(:swap_calls, &[indexes | &1])
      end)

      {:ok,
       %{
         "uid" => 201,
         "status" => "enqueued",
         "type" => "indexSwap",
         "indexUid" => nil
       }}
    end

    def task(uid, _config) do
      Agent.update(:sync_drift_live_test_state, fn state ->
        Map.update!(state, :task_calls, &[uid | &1])
      end)

      state = Agent.get(:sync_drift_live_test_state, & &1)
      if state.task_delay_ms > 0, do: Process.sleep(state.task_delay_ms)

      case state do
        %{task_error: reason} when not is_nil(reason) -> {:error, reason}
        %{task_response: response} -> {:ok, response}
      end
    end
  end

  defmodule SyncDriftObanInspector do
    def list_jobs(_schema_module, config) do
      {:ok, Keyword.get(config, :oban_jobs, [])}
    end
  end

  setup do
    keys = ~w(
      schema_allowlist backend repo sync_mode index_prefix meilisearch_url meilisearch_client
      meilisearch_tasks oban oban_queue oban_inspector oban_jobs
    )a

    previous = Map.new(keys, &{&1, Application.get_env(:scrypath_ops, &1)})

    Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostA, OpsPostB])
    Application.put_env(:scrypath_ops, :backend, Scrypath.Meilisearch)
    Application.put_env(:scrypath_ops, :repo, ScrypathOps.Repo)
    Application.put_env(:scrypath_ops, :sync_mode, :manual)
    Application.put_env(:scrypath_ops, :index_prefix, "sdv")
    Application.put_env(:scrypath_ops, :meilisearch_url, "http://localhost:7700")
    Application.put_env(:scrypath_ops, :meilisearch_client, SyncDriftClient)
    Application.put_env(:scrypath_ops, :meilisearch_tasks, [])
    Application.put_env(:scrypath_ops, :oban, nil)
    Application.put_env(:scrypath_ops, :oban_queue, nil)
    Application.put_env(:scrypath_ops, :oban_inspector, SyncDriftObanInspector)
    Application.put_env(:scrypath_ops, :oban_jobs, [])

    start_supervised!(%{
      id: :sync_drift_live_test_state,
      start:
        {Agent, :start_link,
         [
           fn ->
             %{
               tasks_calls: 0,
               settings_calls: 0,
               task_calls: [],
               task_response: %{"uid" => 201, "status" => "processing"},
               task_delay_ms: 0,
               task_error: nil,
               swap_called: false,
               swap_calls: [],
               tasks_error: nil
             }
           end,
           [name: :sync_drift_live_test_state]
         ]}
    })

    on_exit(fn ->
      Enum.each(previous, fn
        {k, nil} -> Application.delete_env(:scrypath_ops, k)
        {k, v} -> Application.put_env(:scrypath_ops, k, v)
      end)
    end)

    :ok
  end

  test "rendered schema form changes the selected target", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/ops/sync-drift?schema=ScrypathOps.Test.OpsPostA")

    lv
    |> form("#sync-drift-schema-form", %{"schema" => "ScrypathOps.Test.OpsPostB"})
    |> render_change()

    assert_patch(lv, "/ops/sync-drift?schema=ScrypathOps.Test.OpsPostB")
    assert :sys.get_state(lv.pid).socket.assigns.selected_schema == OpsPostB
  end

  test "rendered selection scopes both observations without submitting a mutation", %{conn: conn} do
    Agent.update(:sync_drift_live_test_state, &Map.put(&1, :ready, true))
    {:ok, view, _html} = live(conn, ~p"/ops/sync-drift?schema=ScrypathOps.Test.OpsPostA")

    view
    |> form("#sync-drift-schema-form", %{"schema" => "ScrypathOps.Test.OpsPostB"})
    |> render_change()

    assert_patch(view, "/ops/sync-drift?schema=ScrypathOps.Test.OpsPostB")
    html = render(view)

    assert html =~ "ScrypathOps.Test.OpsPostB"
    assert html =~ "sdv_ops_post_b"
    assert has_element?(view, "a[href='/ops']", "Return to Control Room")
    assert has_element?(view, "a[href='/ops/health']", "Review search health")

    view |> element("#sync-drift-refresh") |> render_click()
    view |> element("button", "Check index configuration") |> render_click()
    render(view)

    assert Agent.get(:sync_drift_live_test_state, & &1.tasks_calls) > 0
    assert Agent.get(:sync_drift_live_test_state, & &1.settings_calls) > 0
    refute Agent.get(:sync_drift_live_test_state, & &1.swap_called)
  end

  test "invalid schema selection stays unavailable with a safe next step", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/ops/sync-drift?schema=ScrypathOps.Test.Removed")

    assert html =~ "That schema is unavailable"

    assert has_element?(
             view,
             "[role=alert]",
             "Choose an available schema to continue."
           )

    assert has_element?(view, "a[href='/ops/health']", "Review search health")
    refute html =~ "No pending or failed sync work found"
  end

  test "missing backend renders an unavailable sync observation", %{conn: conn} do
    Application.delete_env(:scrypath_ops, :backend)
    {:ok, view, html} = live(conn, ~p"/ops/sync-drift?schema=ScrypathOps.Test.OpsPostB")

    assert has_element?(view, "[role=alert]", "Sync status is unavailable")
    assert html =~ "backend is not configured"
    refute html =~ "No pending or failed sync work found"
  end

  test "sync read failure keeps an independent configuration result", %{conn: conn} do
    Agent.update(:sync_drift_live_test_state, fn state ->
      state
      |> Map.put(:ready, true)
      |> Map.put(:tasks_error, :backend_tasks_unavailable)
    end)

    {:ok, view, _html} = live(conn, ~p"/ops/sync-drift?schema=ScrypathOps.Test.OpsPostB")
    assert has_element?(view, "[role=alert]", "Sync status is unavailable")
    assert has_element?(view, "[role=alert]", "backend task or queue read failed")
    refute has_element?(view, "#sync-work-status", "No pending or failed sync work found")

    view |> element("button", "Check index configuration") |> render_click()
    html = render(view)

    assert html =~ "Index configuration matches"
    assert has_element?(view, "[role=alert]", "Sync status is unavailable")
    assert Agent.get(:sync_drift_live_test_state, & &1.settings_calls) > 0
  end

  test "loads reconcile on mount and scopes drift errors separately", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/ops/sync-drift")

    assert html =~ "Sync status"

    assert html =~
             "Check sync progress and compare index configuration."

    assert html =~ "Check backend tasks and queued work for this schema."
    assert html =~ "Index configuration"
    assert has_element?(lv, "[data-testid=configuration-not-checked]", "Not checked")
    refute html =~ "Drift not loaded"
    assert html =~ "sdv_ops_post_a"
    refute html =~ ":settings"

    # `load_drift` now defers the bounded backend read to a `:run_drift` message so the
    # loading skeleton paints first (S3). The click shows the in-flight state; rendering
    # again flushes the deferred read and surfaces the drift result.
    loading_html =
      lv
      |> element("button", "Check index configuration")
      |> render_click()

    assert loading_html =~ "Checking index configuration"

    html2 = render(lv)

    assert html2 =~ ":settings"
    assert html2 =~ "sdv_ops_post_a"
    assert has_element?(lv, "[role=alert]", "Index configuration could not be checked")
    assert has_element?(lv, "details:not([open]) summary", "Check diagnostics")
    assert has_element?(lv, "#sync-work-status", "No pending or failed sync work found")
  end

  test "matching configuration keeps comparison details optional and does not claim freshness", %{
    conn: conn
  } do
    Agent.update(:sync_drift_live_test_state, &Map.put(&1, :ready, true))
    {:ok, view, _} = live(conn, ~p"/ops/sync-drift")

    view |> element("button[phx-click=load_drift]") |> render_click()
    html = render(view)

    assert html =~ "Index configuration matches"
    assert html =~ "This does not check document freshness"
    assert has_element?(view, "details[data-testid=configuration-details]:not([open])")
    assert has_element?(view, "details[data-testid=configuration-details]", "sdv_ops_post_a")
    refute html =~ "ops-tone-chip ops-tone-success"
  end

  test "configuration differences open their comparison without declaring document failure", %{
    conn: conn
  } do
    Agent.update(:sync_drift_live_test_state, fn state ->
      state
      |> Map.put(:ready, true)
      |> Map.put(:applied_settings, %{
        "searchableAttributes" => ["*"],
        "filterableAttributes" => ["category"],
        "sortableAttributes" => []
      })
    end)

    {:ok, view, _} = live(conn, ~p"/ops/sync-drift")
    view |> element("button[phx-click=load_drift]") |> render_click()
    html = render(view)

    assert html =~ "Index configuration differs"
    assert has_element?(view, "details[data-testid=configuration-details][open]")

    assert has_element?(
             view,
             "details[data-testid=configuration-details]",
             "filterable attributes"
           )

    refute html =~ "Documents are stale"
  end

  test "multiple configuration differences expose each affected dimension", %{conn: conn} do
    Agent.update(:sync_drift_live_test_state, fn state ->
      state
      |> Map.put(:ready, true)
      |> Map.put(:applied_settings, %{
        "searchableAttributes" => ["title"],
        "filterableAttributes" => ["category"],
        "sortableAttributes" => ["price"]
      })
    end)

    {:ok, view, _html} = live(conn, ~p"/ops/sync-drift?schema=ScrypathOps.Test.OpsPostB")
    view |> element("button", "Check index configuration") |> render_click()
    html = render(view)

    assert html =~ "Index configuration differs"
    assert html =~ "2 configuration differences found"
    assert has_element?(view, "details[data-testid=configuration-details][open]")

    assert has_element?(
             view,
             "details[data-testid=configuration-details]",
             "filterable attributes"
           )

    assert has_element?(
             view,
             "details[data-testid=configuration-details]",
             "sortable attributes"
           )
  end

  test "pending work remains visible before optional sync diagnostics and health return is overall",
       %{conn: conn} do
    Application.put_env(:scrypath_ops, :meilisearch_tasks, [
      %{
        "uid" => 7,
        "status" => "enqueued",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "sdv_ops_post_b"
      }
    ])

    {:ok, view, html} = live(conn, ~p"/ops/sync-drift?schema=ScrypathOps.Test.OpsPostB")
    assert has_element?(view, "#sync-work-status", "Sync work is pending")
    assert has_element?(view, "details:not([open]) summary", "Sync details")
    assert has_element?(view, "a[href='/ops/health']", "Review search health")
    assert html =~ "Across all configured schemas"
    refute html =~ "For the selected schema"
    refute html =~ "No pending or failed sync work found"
  end

  test "rendered recovery handoff keeps source identity through a read-only refresh", %{
    conn: conn
  } do
    schema = "ScrypathOps.Test.OpsPostA"
    {:ok, origin, _html} = live(conn, "/ops/sync-drift?schema=#{URI.encode_www_form(schema)}")
    origin_socket = :sys.get_state(origin.pid).socket
    scope = Map.get(origin_socket.assigns, :current_scope, %{})
    operator_context = Map.get(origin_socket.assigns, :operator_context)

    org =
      Map.get(operator_context || %{}, :active_org_id) ||
        get_in(scope, [:active_organization, :id])

    host_context = %{
      host: (origin_socket.host_uri && origin_socket.host_uri.host) || "unknown",
      org: org && to_string(org),
      schema: schema,
      generation: origin_socket.assigns.context_generation
    }

    receipt = %{
      replacement_job: 845,
      attempt: 2,
      task_uid: 780,
      operation: :upsert,
      schema: "Elixir." <> schema,
      index: "sdv_ops_post_a",
      source_failure: %{source: :oban, id: 501, operation: :upsert},
      endpoint: "http://localhost:7700",
      instance: __MODULE__.UnconfiguredOban,
      repo: ScrypathOps.Repo,
      prefix: "public",
      node: node(),
      generation: origin_socket.assigns.context_generation
    }

    {:ok, handle} = RecoveryObservation.register(host_context, receipt)

    path =
      "/ops/sync-drift?" <>
        URI.encode_query(%{
          "schema" => schema,
          "recovery" => handle,
          "recovery_generation" => to_string(host_context.generation)
        })

    {:ok, view, _html} = live(conn, path)
    render_async(view)
    assert has_element?(view, "#recovery-observation", "Recovery unknown")
    assert has_element?(view, "[data-testid=recovery-evidence]", "845")
    assert has_element?(view, "[data-testid=recovery-source]", "Oban")
    assert has_element?(view, "[data-testid=recovery-source]", "501")
    assert has_element?(view, "[data-testid=recovery-source]", schema)
    assert has_element?(view, "[data-testid=recovery-source]", "upsert")

    before = Agent.get(:sync_drift_live_test_state, & &1)
    view |> element("button", "Refresh recovery status") |> render_click()
    render_async(view)
    after_refresh = Agent.get(:sync_drift_live_test_state, & &1)

    assert after_refresh.swap_called == before.swap_called
    assert after_refresh.tasks_calls == before.tasks_calls
    assert after_refresh.settings_calls == before.settings_calls
    assert has_element?(view, "#recovery-observation", "Recovery unknown")
  end

  test "expired recovery handoff remains visible and names unavailable evidence", %{conn: conn} do
    path =
      "/ops/sync-drift?" <>
        URI.encode_query(%{
          "schema" => "ScrypathOps.Test.OpsPostB",
          "recovery" => "expired-receipt-handle",
          "recovery_generation" => "1"
        })

    {:ok, view, _html} = live(conn, path)
    render_async(view)

    assert :sys.get_state(view.pid).socket.assigns.recovery_status == :unknown
    assert has_element?(view, "#recovery-observation", "Recovery unknown")
    assert :sys.get_state(view.pid).socket.assigns.selected_schema == OpsPostB
    assert has_element?(view, "[data-testid=recovery-unavailable]", "queue, task, or document")
    refute has_element?(view, "#recovery-observation", "Retry queue job")

    before = Agent.get(:sync_drift_live_test_state, & &1.swap_called)
    view |> element("button", "Refresh recovery status") |> render_click()
    render_async(view)
    assert has_element?(view, "[data-testid=recovery-unavailable]")
    assert Agent.get(:sync_drift_live_test_state, & &1.swap_called) == before
  end

  test "swap live rechecks current prerequisites and refuses a stale contract read" do
    socket =
      sync_drift_socket(%{
        selected_schema: OpsPostB,
        confirm_swap?: true,
        local_ui_state: %{compact?: true}
      })

    {:noreply, socket} = SyncDriftLive.handle_event("load_drift", %{}, socket)
    # load_drift now defers the read; it sets the loading flag and the actual
    # contract-drift read happens in the :run_drift message handler (S3).
    assert socket.assigns.drift_loading == true

    {:noreply, socket} =
      SyncDriftLive.handle_info({:run_drift, socket.assigns.context_generation}, socket)

    assert Agent.get(:sync_drift_live_test_state, & &1.settings_calls) == 1
    assert socket.assigns.drift_error == :settings
    assert socket.assigns.drift_loading == false

    assert {:noreply, updated_socket} = SyncDriftLive.handle_event("swap_live", %{}, socket)

    refute Agent.get(:sync_drift_live_test_state, & &1.swap_called)
    assert Agent.get(:sync_drift_live_test_state, & &1.tasks_calls) > 0
    assert Agent.get(:sync_drift_live_test_state, & &1.settings_calls) == 2
    assert updated_socket.assigns.selected_schema == OpsPostB
    assert updated_socket.assigns.local_ui_state == %{compact?: true}
    assert flash_value(updated_socket, "error") =~ "Index promotion blocked"
    assert updated_socket.assigns.drift_error == :settings
  end

  test "promotion retains the backend task UID returned by the real normalization boundary" do
    Agent.update(:sync_drift_live_test_state, &Map.put(&1, :ready, true))
    socket = sync_drift_socket(%{confirm_swap?: true})

    assert {:noreply, accepted} = SyncDriftLive.handle_event("swap_live", %{}, socket)
    assert Agent.get(:sync_drift_live_test_state, & &1.swap_called)
    assert accepted.assigns.promotion_status == :accepted
    assert accepted.assigns.promotion_task_id == 201
  end

  test "rendered promotion confirms the exact pair and submits once without claiming completion",
       %{
         conn: conn
       } do
    Agent.update(:sync_drift_live_test_state, fn state ->
      state
      |> Map.put(:ready, true)
      |> Map.put(:task_error, :task_read_failed)
    end)

    {:ok, view, _html} = live(conn, "/ops/sync-drift?schema=ScrypathOps.Test.OpsPostA")

    view
    |> element("#index-promotion button", "Refresh sync and configuration checks")
    |> render_click()

    assert has_element?(view, "#index-promotion", "Ready for promotion")

    view
    |> element("#index-promotion button", "Promote target index")
    |> render_click()

    assert has_element?(view, "#confirm-index-promotion[role=dialog]")
    assert has_element?(view, "#confirm-index-promotion", "ScrypathOps.Test.OpsPostA")
    assert has_element?(view, "#confirm-index-promotion", "sdv_ops_post_a")
    assert has_element?(view, "#confirm-index-promotion", "sdv_ops_post_a__reindex")

    assert has_element?(
             view,
             "#confirm-index-promotion",
             "documents, primary keys, settings, and task history"
           )

    assert has_element?(view, "#confirm-index-promotion", "prepared target becomes live")

    view
    |> form("#confirm-index-promotion form")
    |> render_submit()

    render_async(view)

    assert Agent.get(:sync_drift_live_test_state, &Enum.reverse(&1.swap_calls)) == [
             {"sdv_ops_post_a", "sdv_ops_post_a__reindex"}
           ]

    assert has_element?(view, "#promotion-task-status", "201")
    assert has_element?(view, "#promotion-task-status", "outcome unconfirmed")
    refute has_element?(view, "#promotion-task-status", "Index swap completed")

    view
    |> element("#index-promotion button", "Promote target index")
    |> render_click()

    refute Agent.get(:sync_drift_live_test_state, &(length(&1.swap_calls) > 1))
  end

  test "promotion task identity stays visible outside the manually controlled disclosure", %{
    conn: conn
  } do
    {:ok, view, _html} = live(conn, "/ops/sync-drift?schema=ScrypathOps.Test.OpsPostA")

    seed_rendered_promotion(view)

    assert has_element?(view, "#index-promotion[phx-hook=OpsHealthDetails]")
    assert has_element?(view, "#index-promotion summary[data-testid=advanced-promotion-summary]")
    refute has_element?(view, "#index-promotion[open]")

    assert has_element?(
             view,
             "#promotion-task-status [data-testid=promotion-task-identity]",
             "201"
           )

    refute has_element?(view, "#index-promotion #promotion-task-status")
  end

  test "rendered promotion confirmation can be cancelled without submitting", %{conn: conn} do
    Agent.update(:sync_drift_live_test_state, &Map.put(&1, :ready, true))
    {:ok, view, _html} = live(conn, "/ops/sync-drift?schema=ScrypathOps.Test.OpsPostA")

    view
    |> element("#index-promotion button", "Refresh sync and configuration checks")
    |> render_click()

    view
    |> element("#index-promotion button", "Promote target index")
    |> render_click()

    assert has_element?(view, "#confirm-index-promotion[role=dialog]")

    view
    |> element("#confirm-index-promotion button", "Cancel index swap")
    |> render_click()

    refute has_element?(view, "#confirm-index-promotion")
    assert Agent.get(:sync_drift_live_test_state, & &1.swap_calls) == []
  end

  test "rendered promotion rechecks prerequisites immediately before submitting", %{conn: conn} do
    Agent.update(:sync_drift_live_test_state, &Map.put(&1, :ready, true))
    {:ok, view, _html} = live(conn, "/ops/sync-drift?schema=ScrypathOps.Test.OpsPostA")

    view
    |> element("#index-promotion button", "Refresh sync and configuration checks")
    |> render_click()

    view
    |> element("#index-promotion button", "Promote target index")
    |> render_click()

    Agent.update(:sync_drift_live_test_state, &Map.put(&1, :ready, false))

    view
    |> form("#index-promotion-form")
    |> render_submit()

    render_async(view)

    refute has_element?(view, "#confirm-index-promotion")
    assert has_element?(view, "[role=alert]", "Index promotion blocked")
    assert Agent.get(:sync_drift_live_test_state, & &1.swap_calls) == []
  end

  test "rendered promotion returns through sudo confirmation without replay", %{conn: conn} do
    Agent.update(:sync_drift_live_test_state, &Map.put(&1, :ready, true))
    {:ok, view, _html} = live(conn, "/ops/sync-drift?schema=ScrypathOps.Test.OpsPostA")

    view
    |> element("#index-promotion button", "Refresh sync and configuration checks")
    |> render_click()

    view
    |> element("#index-promotion button", "Promote target index")
    |> render_click()

    :sys.replace_state(view.pid, fn state ->
      socket = state.socket

      assigns =
        Map.put(
          socket.assigns,
          :operator_context,
          operator_context(sudo_at: DateTime.add(DateTime.utc_now(), -600, :second))
        )
        |> Map.put(:__changed__, %{operator_context: true})

      %{state | socket: %{socket | assigns: assigns}}
    end)

    view
    |> form("#index-promotion-form")
    |> render_submit()

    assert_redirect(
      view,
      "/sudo/confirm?return_to=%2Fops%2Fsync-drift%3Fschema%3DScrypathOps.Test.OpsPostA"
    )

    assert Agent.get(:sync_drift_live_test_state, & &1.swap_calls) == []
  end

  test "rendered promotion status check reads only the retained task UID", %{conn: conn} do
    {:ok, view, _html} =
      live(conn, "/ops/sync-drift?schema=ScrypathOps.Test.OpsPostA")

    seed_rendered_promotion(view)

    assert has_element?(view, "#promotion-task-status")
    assert render(view) =~ "201"
    assert has_element?(view, "#promotion-task-status", "Index swap accepted")

    view
    |> element("#promotion-task-status button", "Check swap status")
    |> render_click()

    render_async(view)

    assert has_element?(view, "#promotion-task-status", "Index swap running")
    assert Agent.get(:sync_drift_live_test_state, &Enum.reverse(&1.task_calls)) == [201]
    refute Agent.get(:sync_drift_live_test_state, & &1.swap_called)
  end

  test "rendered promotion status keeps an enqueued task accepted while checking", %{conn: conn} do
    Agent.update(:sync_drift_live_test_state, fn state ->
      state
      |> Map.put(:task_response, %{"taskUid" => 201, "status" => "enqueued"})
      |> Map.put(:task_delay_ms, 100)
    end)

    {:ok, view, _html} =
      live(conn, "/ops/sync-drift?schema=ScrypathOps.Test.OpsPostA")

    seed_rendered_promotion(view)

    view
    |> element("#promotion-task-status button", "Check swap status")
    |> render_click()

    assert :sys.get_state(view.pid).socket.assigns.promotion_status == :accepted
    assert :sys.get_state(view.pid).socket.assigns.promotion_check_loading
    assert has_element?(view, "#promotion-task-status", "Checking swap status…")

    render_async(view)

    assert has_element?(view, "#promotion-task-status", "Index swap accepted")
    refute has_element?(view, "#promotion-task-status", "Index swap running")
    assert Agent.get(:sync_drift_live_test_state, &Enum.reverse(&1.task_calls)) == [201]
    refute Agent.get(:sync_drift_live_test_state, & &1.swap_called)
  end

  test "rendered promotion checks map exact terminal and unconfirmed responses", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/ops/sync-drift?schema=ScrypathOps.Test.OpsPostA")
    seed_rendered_promotion(view)

    cases = [
      {%{"uid" => 201, "status" => "succeeded"}, nil, "Index swap completed"},
      {%{"uid" => 201, "status" => "failed"}, nil, "Index swap failed"},
      {%{"uid" => 201, "status" => "canceled"}, nil, "Index swap cancelled"},
      {%{"uid" => 202, "status" => "succeeded"}, nil, "outcome unconfirmed"},
      {%{"uid" => 201}, nil, "outcome unconfirmed"},
      {nil, :task_read_failed, "outcome unconfirmed"}
    ]

    for {response, error, expected} <- cases do
      Agent.update(:sync_drift_live_test_state, fn state ->
        state |> Map.put(:task_response, response) |> Map.put(:task_error, error)
      end)

      view
      |> element("#promotion-task-status button", "Check swap status")
      |> render_click()

      render_async(view)
      assert has_element?(view, "#promotion-task-status", expected)
      assert has_element?(view, "#promotion-task-status", "201")
      refute Agent.get(:sync_drift_live_test_state, & &1.swap_called)
    end

    assert Agent.get(:sync_drift_live_test_state, &Enum.reverse(&1.task_calls)) ==
             [201, 201, 201, 201, 201, 201]
  end

  test "rendered timed-out promotion check retries the same UID without another swap", %{
    conn: conn
  } do
    Agent.update(:sync_drift_live_test_state, &Map.put(&1, :task_error, :timeout))
    {:ok, view, _html} = live(conn, "/ops/sync-drift?schema=ScrypathOps.Test.OpsPostA")
    seed_rendered_promotion(view)

    view |> element("#promotion-task-status button", "Check swap status") |> render_click()
    render_async(view)
    assert has_element?(view, "#promotion-task-status", "outcome unconfirmed")

    Agent.update(:sync_drift_live_test_state, fn state ->
      state
      |> Map.put(:task_error, nil)
      |> Map.put(:task_response, %{"uid" => 201, "status" => "processing"})
    end)

    view |> element("#promotion-task-status button", "Check swap status") |> render_click()
    render_async(view)

    assert has_element?(view, "#promotion-task-status", "Index swap running")
    assert Agent.get(:sync_drift_live_test_state, &Enum.reverse(&1.task_calls)) == [201, 201]
    refute Agent.get(:sync_drift_live_test_state, & &1.swap_called)
  end

  test "promotion callbacks discard success and error results after runtime or context changes" do
    stale_mutations = [
      fn -> Application.put_env(:scrypath_ops, :meilisearch_url, "http://other:7700") end,
      fn -> Application.put_env(:scrypath_ops, :backend, :other_backend) end,
      fn -> Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostB]) end,
      fn -> Application.put_env(:scrypath_ops, :index_prefix, "changed") end,
      fn -> Application.put_env(:scrypath_ops, :meilisearch_client, Client) end,
      fn -> :selected_schema end,
      fn -> :generation end
    ]

    for mutate <- stale_mutations do
      socket = sync_drift_socket(%{promotion_task_id: 201, promotion_status: :accepted})
      context = socket.assigns.promotion_context

      changed_socket =
        case mutate.() do
          :generation ->
            %{
              socket
              | assigns: Map.put(socket.assigns, :context_generation, context.generation + 1)
            }

          :selected_schema ->
            %{socket | assigns: Map.put(socket.assigns, :selected_schema, OpsPostB)}

          _ ->
            socket
        end

      {:noreply, success} =
        SyncDriftLive.handle_async(
          {:promotion_check, context.generation, context.task_id},
          {:ok, {context, {:ok, %{uid: 201, status: :succeeded}}}},
          changed_socket
        )

      assert success.assigns.promotion_task_id == 201

      expected =
        if context.generation == changed_socket.assigns.context_generation,
          do: :unknown,
          else: :accepted

      assert success.assigns.promotion_status == expected
      refute success.assigns.promotion_check_loading

      {:noreply, failed} =
        SyncDriftLive.handle_async(
          {:promotion_check, context.generation, context.task_id},
          {:exit, :observer_failed},
          changed_socket
        )

      assert failed.assigns.promotion_task_id == 201
      assert failed.assigns.promotion_status == expected
      refute failed.assigns.promotion_check_loading

      Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostA, OpsPostB])
      Application.put_env(:scrypath_ops, :backend, Scrypath.Meilisearch)
      Application.put_env(:scrypath_ops, :meilisearch_url, "http://localhost:7700")
      Application.put_env(:scrypath_ops, :index_prefix, "sdv")
      Application.put_env(:scrypath_ops, :meilisearch_client, SyncDriftClient)
    end
  end

  test "guarded promotion preserves the queue inspector and refuses newly pending work" do
    Agent.update(:sync_drift_live_test_state, &Map.put(&1, :ready, true))

    opts =
      sync_drift_scrypath_opts()
      |> Keyword.put(:sync_mode, :oban)
      |> Keyword.put(:oban, Oban)
      |> Keyword.put(:oban_queue, :scrypath_sync)
      |> Keyword.put(:oban_jobs, [
        %{id: 12, state: "available", worker: "Scrypath.Oban.UpsertWorker", args: %{}}
      ])

    socket = sync_drift_socket(%{scrypath_opts: opts, confirm_swap?: true})
    assert {:noreply, blocked} = SyncDriftLive.handle_event("swap_live", %{}, socket)
    refute Agent.get(:sync_drift_live_test_state, & &1.swap_called)
    assert blocked.assigns.promotion_eligibility == {:blocked, :queue_work_pending}
  end

  test "promotion consumes confirmation and refuses duplicate in-flight or replayed events" do
    Agent.update(:sync_drift_live_test_state, &Map.put(&1, :ready, true))

    for overrides <- [
          %{confirm_swap?: true, promotion_loading: true, promotion_task_id: 201},
          %{
            confirm_swap?: false,
            promotion_loading: false,
            promotion_task_id: 201,
            promotion_status: :completed
          }
        ] do
      socket = sync_drift_socket(overrides)
      assert {:noreply, unchanged} = SyncDriftLive.handle_event("swap_live", %{}, socket)
      refute Agent.get(:sync_drift_live_test_state, & &1.swap_called)
      assert unchanged.assigns.promotion_task_id == 201
    end
  end

  test "handoff keeps the origin generation separate from this page's async generation" do
    socket = sync_drift_socket(%{selected_schema: nil})

    params = %{
      "schema" => "ScrypathOps.Test.OpsPostB",
      "recovery" => "opaque-receipt",
      "recovery_generation" => "7"
    }

    assert {:noreply, entered} =
             SyncDriftLive.handle_params(
               params,
               "https://scrypath.example/ops/sync-drift",
               socket
             )

    assert entered.assigns.context_generation == 1
    assert entered.assigns.recovery_origin_generation == 7
    assert entered.assigns.recovery_handle == "opaque-receipt"

    assert {:noreply, invalid} =
             SyncDriftLive.handle_params(
               %{params | "recovery_generation" => "oops"},
               "https://scrypath.example/ops/sync-drift",
               entered
             )

    assert invalid.assigns.recovery_handle == nil
    refute invalid.assigns.recovery_loading
  end

  test "observer exits from a previous schema cannot change the current screen" do
    socket =
      sync_drift_socket(%{context_generation: 4, recovery_handle: nil, promotion_task_id: nil})

    assert {:noreply, unchanged} =
             SyncDriftLive.handle_async({:promotion_swap, 3, 201}, {:exit, :shutdown}, socket)

    assert unchanged.assigns == socket.assigns

    assert {:noreply, unchanged} =
             SyncDriftLive.handle_async(
               {:recovery_observation, 3, "old"},
               {:exit, :shutdown},
               socket
             )

    assert unchanged.assigns == socket.assigns
  end

  test "schema selector rejects non-allowlisted module strings without creating atoms" do
    mod_str = "ScrypathOps.Test.NotAllowlisted#{System.unique_integer([:positive])}"

    socket =
      sync_drift_socket(%{
        schema_allowlist: [OpsPostA],
        selected_schema: OpsPostA
      })

    assert {:noreply, updated_socket} =
             SyncDriftLive.handle_event("select_schema", %{"schema" => mod_str}, socket)

    assert updated_socket.assigns.selected_schema == nil
    assert updated_socket.assigns.selection_error == :unavailable

    assert_raise ArgumentError, fn ->
      String.to_existing_atom(mod_str)
    end
  end

  test "a stale queued drift check cannot overwrite a newly selected schema" do
    socket = sync_drift_socket(%{selected_schema: OpsPostA, context_generation: 4})
    {:noreply, loading_socket} = SyncDriftLive.handle_event("load_drift", %{}, socket)
    assert loading_socket.assigns.drift_loading

    {:noreply, switched_socket} =
      SyncDriftLive.handle_params(
        %{"schema" => "ScrypathOps.Test.OpsPostB"},
        "https://scrypath.example/ops/sync-drift?schema=ScrypathOps.Test.OpsPostB",
        loading_socket
      )

    assert switched_socket.assigns.selected_schema == OpsPostB
    assert switched_socket.assigns.context_generation == 5

    {:noreply, final_socket} = SyncDriftLive.handle_info({:run_drift, 4}, switched_socket)
    assert Agent.get(:sync_drift_live_test_state, & &1.settings_calls) == 0
    assert final_socket.assigns.selected_schema == OpsPostB
    assert final_socket.assigns.drift_result == nil
  end

  test "recovery refresh discards prior verification and stale results cannot restore it" do
    socket =
      sync_drift_socket(%{
        selected_schema: OpsPostA,
        context_generation: 8,
        recovery_handle: "opaque-handle",
        recovery_status: :verified,
        recovery_checked_at: DateTime.utc_now(),
        recovery_loading: false
      })

    {:noreply, refreshing} = SyncDriftLive.handle_event("refresh_recovery_status", %{}, socket)

    assert refreshing.assigns.recovery_status == :unknown
    assert refreshing.assigns.recovery_loading
    assert Agent.get(:sync_drift_live_test_state, & &1.tasks_calls) == 0
    assert Agent.get(:sync_drift_live_test_state, & &1.settings_calls) == 0

    {:noreply, stale} =
      SyncDriftLive.handle_async(
        {:recovery_observation, 7, "opaque-handle"},
        {:ok, {7, "opaque-handle", :verified}},
        refreshing
      )

    assert stale.assigns.recovery_status == :unknown
    assert stale.assigns.recovery_loading
  end

  test "recovery results retain exact observed evidence and refresh clears it" do
    evidence = %{replacement_job: 45, attempt: 1, task_uid: 780, index: "posts"}
    socket = sync_drift_socket(%{context_generation: 3, recovery_handle: "receipt"})

    {:noreply, checked} =
      SyncDriftLive.handle_async(
        {:recovery_observation, 3, "receipt"},
        {:ok, {3, "receipt", {:verified, evidence}}},
        socket
      )

    assert checked.assigns.recovery_status == :verified
    assert checked.assigns.recovery_evidence == evidence
    {:noreply, refreshing} = SyncDriftLive.handle_event("refresh_recovery_status", %{}, checked)
    assert refreshing.assigns.recovery_evidence == nil
  end

  test "recovery success arriving after its selected schema is removed is discarded" do
    socket =
      sync_drift_socket(%{
        selected_schema: OpsPostA,
        context_generation: 8,
        recovery_handle: "removed-target-receipt",
        recovery_status: :unknown,
        recovery_loading: true
      })

    Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostB])

    {:noreply, updated} =
      SyncDriftLive.handle_async(
        {:recovery_observation, 8, "removed-target-receipt"},
        {:ok, {8, "removed-target-receipt", {:verified, %{index: "sdv_ops_post_a"}}}},
        socket
      )

    assert updated.assigns.selected_schema == nil
    assert updated.assigns.selection_error == :unavailable
    assert updated.assigns.recovery_handle == nil
    assert updated.assigns.recovery_status == nil
    assert updated.assigns.recovery_evidence == nil
    refute updated.assigns.recovery_loading
  end

  test "recovery failure arriving after its selected schema is removed clears pending status" do
    socket =
      sync_drift_socket(%{
        selected_schema: OpsPostA,
        context_generation: 9,
        recovery_handle: "removed-target-receipt",
        recovery_status: :unknown,
        recovery_loading: true
      })

    Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostB])

    {:noreply, updated} =
      SyncDriftLive.handle_async(
        {:recovery_observation, 9, "removed-target-receipt"},
        {:exit, :observer_failed},
        socket
      )

    assert updated.assigns.selected_schema == nil
    assert updated.assigns.selection_error == :unavailable
    assert updated.assigns.recovery_handle == nil
    assert updated.assigns.recovery_status == nil
    assert updated.assigns.recovery_evidence == nil
    refute updated.assigns.recovery_loading
  end

  test "swap observer distinguishes terminal outcomes from unconfirmed observations and keeps task identity" do
    socket =
      sync_drift_socket(%{
        context_generation: 9,
        promotion_task_id: 991,
        promotion_status: :accepted,
        promotion_loading: true
      })

    {:noreply, completed} =
      SyncDriftLive.handle_async(
        {:promotion_swap, 9, 991},
        {:ok,
         {9, 991,
          {:ok,
           %OperationTask{source: :meilisearch, kind: :index_swap, id: 991, state: :succeeded}}}},
        socket
      )

    assert completed.assigns.promotion_status == :completed
    assert completed.assigns.promotion_task_id == 991

    {:noreply, wrong_task} =
      SyncDriftLive.handle_async(
        {:promotion_swap, 9, 991},
        {:ok,
         {9, 991,
          {:ok,
           %OperationTask{source: :meilisearch, kind: :index_swap, id: 992, state: :succeeded}}}},
        socket
      )

    assert wrong_task.assigns.promotion_status == :unknown
    assert wrong_task.assigns.promotion_task_id == 991

    {:noreply, failed} =
      SyncDriftLive.handle_async(
        {:promotion_swap, 9, 991},
        {:ok,
         {9, 991,
          {:error,
           {:task_failed,
            %OperationTask{source: :meilisearch, kind: :index_swap, id: 991, state: :failed}}}}},
        socket
      )

    assert failed.assigns.promotion_status == {:failed, :task_failed}

    assert failed.assigns.promotion_task_id == 991

    {:noreply, cancelled} =
      SyncDriftLive.handle_async(
        {:promotion_swap, 9, 991},
        {:ok,
         {9, 991,
          {:error,
           {:cancelled,
            %OperationTask{source: :meilisearch, kind: :index_swap, id: 991, state: :cancelled}}}}},
        socket
      )

    assert cancelled.assigns.promotion_status == {:failed, :cancelled}

    assert cancelled.assigns.promotion_task_id == 991

    {:noreply, wrong_terminal_task} =
      SyncDriftLive.handle_async(
        {:promotion_swap, 9, 991},
        {:ok,
         {9, 991,
          {:error,
           {:task_failed,
            %OperationTask{source: :meilisearch, kind: :index_swap, id: 992, state: :failed}}}}},
        socket
      )

    assert wrong_terminal_task.assigns.promotion_status == :unknown
    assert wrong_terminal_task.assigns.promotion_task_id == 991

    {:noreply, nonterminal_error} =
      SyncDriftLive.handle_async(
        {:promotion_swap, 9, 991},
        {:ok,
         {9, 991,
          {:error,
           {:task_failed,
            %OperationTask{source: :meilisearch, kind: :index_swap, id: 991, state: :processing}}}}},
        socket
      )

    assert nonterminal_error.assigns.promotion_status == :unknown
    assert nonterminal_error.assigns.promotion_task_id == 991

    {:noreply, transport_error} =
      SyncDriftLive.handle_async(
        {:promotion_swap, 9, 991},
        {:ok, {9, 991, {:error, {:transport_error, :econnrefused}}}},
        socket
      )

    assert transport_error.assigns.promotion_status == :unknown
    assert transport_error.assigns.promotion_task_id == 991

    {:noreply, invalid_payload} =
      SyncDriftLive.handle_async(
        {:promotion_swap, 9, 991},
        {:ok, {9, 991, {:error, {:invalid_task_payload, %{task_uid: 991}}}}},
        socket
      )

    assert invalid_payload.assigns.promotion_status == :unknown
    assert invalid_payload.assigns.promotion_task_id == 991

    {:noreply, timed_out} =
      SyncDriftLive.handle_async(
        {:promotion_swap, 9, 991},
        {:ok, {9, 991, {:error, {:timeout, %{id: 991}}}}},
        socket
      )

    assert timed_out.assigns.promotion_status == :timed_out
    assert timed_out.assigns.promotion_task_id == 991

    {:noreply, observer_exit} =
      SyncDriftLive.handle_async({:promotion_swap, 9, 991}, {:exit, :noproc}, socket)

    assert observer_exit.assigns.promotion_status == :unknown
    assert observer_exit.assigns.promotion_task_id == 991

    {:noreply, stale} =
      SyncDriftLive.handle_async(
        {:promotion_swap, 8, 991},
        {:ok,
         {8, 991,
          {:ok,
           %OperationTask{source: :meilisearch, kind: :index_swap, id: 991, state: :succeeded}}}},
        socket
      )

    assert stale.assigns.promotion_status == :accepted
    assert stale.assigns.promotion_loading
  end

  test "refresh after an unconfirmed promotion checks state without submitting another swap" do
    for status <- [:timed_out, :unknown] do
      socket =
        sync_drift_socket(%{
          promotion_task_id: 991,
          promotion_status: status,
          promotion_loading: false
        })

      {:noreply, refreshed} = SyncDriftLive.handle_event("refresh_promotion_checks", %{}, socket)

      assert refreshed.assigns.promotion_task_id == 991
      assert refreshed.assigns.promotion_status == status
      refute Agent.get(:sync_drift_live_test_state, & &1.swap_called)
    end
  end

  test "rendered sync drift links preserve the selected schema", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/ops/sync-drift?schema=ScrypathOps.Test.OpsPostB")

    assert html =~ "OpsPostB"
    assert has_element?(lv, "a[href='/ops']", "Return to Control Room")
    assert has_element?(lv, "a[href='/ops/health']")
    assert :sys.get_state(lv.pid).socket.assigns.selected_schema == OpsPostB
  end

  test "swap live blocks impersonation before any refresh" do
    socket =
      sync_drift_socket(%{
        confirm_swap?: true,
        operator_context: operator_context(impersonator: "impersonator_789"),
        local_ui_state: :keep
      })

    assert {:noreply, updated_socket} = SyncDriftLive.handle_event("swap_live", %{}, socket)

    assert flash_value(updated_socket, "error") =~ "Impersonation must be cleared"
    assert Agent.get(:sync_drift_live_test_state, & &1.swap_called) != true
    assert Agent.get(:sync_drift_live_test_state, & &1.tasks_calls) == 0
    assert Agent.get(:sync_drift_live_test_state, & &1.settings_calls) == 0
    assert updated_socket.assigns.local_ui_state == :keep
    assert updated_socket.assigns.selected_schema == OpsPostA
  end

  test "swap live stale sudo redirects with return_to only" do
    socket =
      sync_drift_socket(%{
        confirm_swap?: true,
        operator_context:
          operator_context(sudo_at: DateTime.add(DateTime.utc_now(), -600, :second)),
        local_ui_state: :keep
      })

    assert {:noreply, updated_socket} = SyncDriftLive.handle_event("swap_live", %{}, socket)

    assert inspect(updated_socket.redirected) =~ "/sudo/confirm"
    assert inspect(updated_socket.redirected) =~ "return_to=%2Fops%2Fsync-drift"
    assert Agent.get(:sync_drift_live_test_state, & &1.swap_called) != true
    assert Agent.get(:sync_drift_live_test_state, & &1.tasks_calls) == 0
    assert Agent.get(:sync_drift_live_test_state, & &1.settings_calls) == 0
    assert updated_socket.assigns.local_ui_state == :keep
  end

  defp sync_drift_socket(overrides) do
    scope = %{
      user: %{id: "user_123"},
      active_organization: %{id: "org_456"},
      impersonating_from: Map.get(overrides, :impersonating_from)
    }

    operator_context = Map.get(overrides, :operator_context, operator_context())

    base_assigns = %{
      __changed__: %{},
      flash: %{},
      page_title: "Sync and drift",
      schema_allowlist: [OpsPostA, OpsPostB],
      scrypath_opts: sync_drift_scrypath_opts(),
      selected_schema: OpsPostA,
      context_generation: 0,
      selection_error: nil,
      mount_path: "/ops",
      reconcile_result: nil,
      reconcile_loaded_at: nil,
      reconcile_generation: nil,
      reconcile_error: nil,
      drift_result: nil,
      drift_loaded_at: nil,
      drift_generation: nil,
      drift_error: nil,
      drift_loading: false,
      recovery_handle: nil,
      recovery_origin_generation: nil,
      promotion_loading: false,
      promotion_check_loading: false,
      promotion_task_id: nil,
      promotion_status: nil,
      promotion_context: nil,
      promotion_schema: nil,
      promotion_indexes: nil,
      confirm_swap?: false,
      recovery_status: nil,
      recovery_evidence: nil,
      recovery_checked_at: nil,
      recovery_loading: false,
      current_scope: scope,
      operator_context: operator_context,
      local_ui_state: nil
    }

    assigns = Map.merge(base_assigns, overrides)

    promotion_context =
      if is_integer(assigns.promotion_task_id) do
        %{
          generation: assigns.context_generation,
          task_id: assigns.promotion_task_id,
          schema: assigns.selected_schema,
          indexes: assigns.promotion_indexes || {"sdv_ops_post_a", "sdv_ops_post_a__reindex"},
          runtime: promotion_test_runtime(assigns.selected_schema, assigns.scrypath_opts)
        }
      end

    assigns =
      assigns
      |> Map.put(:promotion_context, promotion_context)
      |> Map.put(:promotion_schema, assigns.selected_schema)

    assigns =
      if is_map(promotion_context),
        do: Map.put(assigns, :promotion_indexes, promotion_context.indexes),
        else: assigns

    %Phoenix.LiveView.Socket{
      assigns: assigns,
      host_uri: URI.parse("https://scrypath.example/ops/sync-drift")
    }
  end

  defp seed_rendered_promotion(view) do
    :sys.replace_state(view.pid, fn state ->
      socket = state.socket
      indexes = {"sdv_ops_post_a", "sdv_ops_post_a__reindex"}

      runtime = %{
        schema: OpsPostA,
        backend: Scrypath.Meilisearch,
        endpoint: %{scheme: "http", host: "localhost", port: 7700, path: ""},
        index_prefix: "sdv",
        meilisearch_client: SyncDriftClient,
        oban: nil,
        repo: ScrypathOps.Repo,
        prefix: nil,
        node: node()
      }

      context = %{
        generation: socket.assigns.context_generation,
        task_id: 201,
        schema: OpsPostA,
        indexes: indexes,
        runtime: runtime
      }

      assigns =
        Map.merge(socket.assigns, %{
          promotion_task_id: 201,
          promotion_status: :accepted,
          promotion_schema: OpsPostA,
          promotion_indexes: indexes,
          promotion_context: context,
          promotion_check_loading: false
        })
        |> Map.put(:__changed__, %{
          promotion_task_id: true,
          promotion_status: true,
          promotion_schema: true,
          promotion_indexes: true,
          promotion_context: true,
          promotion_check_loading: true
        })

      %{state | socket: %{socket | assigns: assigns}}
    end)

    view |> element("#sync-drift-refresh") |> render_click()
  end

  defp promotion_test_runtime(schema, opts) do
    endpoint = URI.parse(Keyword.get(opts, :meilisearch_url))

    %{
      schema: schema,
      backend: Keyword.get(opts, :backend),
      endpoint:
        Map.merge(Map.take(endpoint, [:scheme, :host, :port]), %{
          path: String.trim_trailing(endpoint.path || "", "/")
        }),
      index_prefix: Keyword.get(opts, :index_prefix),
      meilisearch_client: Keyword.get(opts, :meilisearch_client),
      oban: Keyword.get(opts, :oban),
      repo: Keyword.get(opts, :repo),
      prefix: Keyword.get(opts, :prefix),
      node: node()
    }
  end

  defp sync_drift_scrypath_opts do
    [
      backend: Scrypath.Meilisearch,
      repo: ScrypathOps.Repo,
      sync_mode: :manual,
      index_prefix: "sdv",
      meilisearch_url: "http://localhost:7700",
      meilisearch_client: SyncDriftClient,
      meilisearch_tasks: [],
      oban: nil,
      oban_queue: nil,
      oban_inspector: SyncDriftObanInspector,
      oban_jobs: []
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
end
