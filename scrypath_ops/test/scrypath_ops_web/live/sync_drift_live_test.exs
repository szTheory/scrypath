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
    end

    def get_settings(_index, _config) do
      Agent.update(:sync_drift_live_test_state, fn state ->
        Map.update!(state, :settings_calls, &(&1 + 1))
      end)

      if settings = Agent.get(:sync_drift_live_test_state, &Map.get(&1, :applied_settings)) do
        {:ok, settings}
      else
        if Agent.get(:sync_drift_live_test_state, &Map.get(&1, :ready, false)) do
          {:ok,
           %{
             "searchableAttributes" => ["*"],
             "filterableAttributes" => [],
             "sortableAttributes" => []
           }}
        else
          {:error, :settings}
        end
      end
    end

    def swap_indexes(_indexes, _config) do
      Agent.update(:sync_drift_live_test_state, fn state ->
        state
        |> Map.put(:swap_called, true)
        |> Map.update!(:swap_calls, &(&1 + 1))
      end)

      {:ok,
       %{
         "uid" => 201,
         "status" => "succeeded",
         "type" => "indexSwap",
         "indexUid" => "sdv_ops_post_b"
       }}
    end

    def task(uid, _config) do
      Agent.update(:sync_drift_live_test_state, fn state ->
        Map.update!(state, :task_calls, &[uid | &1])
      end)

      Agent.get(:sync_drift_live_test_state, fn state ->
        %{"uid" => uid, "status" => state.task_status, "type" => "indexSwap"}
      end)
      |> then(&{:ok, &1})
    end
  end

  defmodule SyncDriftObanInspector do
    def list_jobs(_schema_module, config) do
      {:ok, Keyword.get(config, :oban_jobs, [])}
    end
  end

  setup do
    keys = ~w(
      schema_allowlist backend sync_mode index_prefix meilisearch_url meilisearch_client
      meilisearch_tasks oban oban_queue oban_inspector oban_jobs
    )a

    previous = Map.new(keys, &{&1, Application.get_env(:scrypath_ops, &1)})

    Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostA, OpsPostB])
    Application.put_env(:scrypath_ops, :backend, Scrypath.Meilisearch)
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
               swap_called: false,
               swap_calls: 0,
               task_calls: [],
               task_status: "processing"
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
    {:ok, lv, _html} = live(conn, ~p"/ops/sync-and-index?schema=ScrypathOps.Test.OpsPostA")

    lv
    |> form("#sync-and-index-schema-form", %{"schema" => "ScrypathOps.Test.OpsPostB"})
    |> render_change()

    assert_patch(lv, "/ops/sync-and-index?schema=ScrypathOps.Test.OpsPostB")
    assert :sys.get_state(lv.pid).socket.assigns.selected_schema == OpsPostB
  end

  test "old /sync-drift links redirect to Sync and index and keep the schema", %{conn: conn} do
    assert {:error, {:live_redirect, %{to: to}}} =
             live(conn, "/ops/sync-drift?schema=ScrypathOps.Test.OpsPostB")

    assert to == "/ops/sync-and-index?schema=ScrypathOps.Test.OpsPostB"

    assert {:error, {:live_redirect, %{to: "/ops/sync-and-index"}}} =
             live(conn, "/ops/sync-drift")
  end

  test "automatically reads settings and keeps their errors separate from sync", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/ops/sync-and-index")
    html = render_async(lv)
    assert has_element?(lv, "h1", "Sync and index")
    assert has_element?(lv, "h2#sync-pipeline-heading", "Is sync keeping up?")
    assert has_element?(lv, "h2#index-settings-heading", "Does the live index match your schema?")

    assert has_element?(
             lv,
             "#index-settings-error[role='alert']",
             "Couldn't read the Meilisearch settings"
           )

    assert has_element?(lv, "#index-settings-error pre", ":settings")
    assert has_element?(lv, "#index-settings-error [data-ops-copy-text=':settings']")
    assert has_element?(lv, "#sync-pipeline-status")
    assert html =~ "sdv_ops_post_a"
    assert Agent.get(:sync_drift_live_test_state, & &1.settings_calls) == 1

    assert has_element?(
             lv,
             "#sync-and-index-refresh[aria-label='Refresh sync and index settings']"
           )

    refute html =~ "Settings checked"
    refute html =~ "snapshot"
  end

  test "one page-level Checked time; settings show their own checking state until they load", %{
    conn: conn
  } do
    Agent.update(:sync_drift_live_test_state, &Map.put(&1, :ready, true))
    html = conn |> get(~p"/ops/sync-and-index") |> html_response(200)
    assert html =~ "Checked"
    refute html =~ "Settings checked"
    refute html =~ "Sync checked"
    refute html =~ "Meilisearch settings match the schema."
    assert html =~ ~s(id="index-settings-checking")
    assert html =~ "Checking Meilisearch settings…"

    {:ok, lv, _html} = live(conn, ~p"/ops/sync-and-index")
    render_async(lv)
    refute has_element?(lv, "#index-settings-checking")
    assert has_element?(lv, ".ops-time__label", "Checked")
    assert Enum.count(LazyHTML.query(LazyHTML.from_fragment(render(lv)), ".ops-time__label")) == 1

    assert has_element?(
             lv,
             "#index-settings-status",
             "Meilisearch settings match the schema."
           )

    assert has_element?(
             lv,
             "#index-settings-status",
             "Filters, sorting and facets work as declared."
           )

    refute render(lv) =~ "Full comparison details"
    refute has_element?(lv, ".ops-settings-diff")
  end

  test "inline and manual sync say there is no queue instead of claiming caught up", %{
    conn: conn
  } do
    {:ok, lv, _html} = live(conn, ~p"/ops/sync-and-index")
    render_async(lv)

    assert has_element?(lv, "#sync-pipeline-status", "No Meilisearch tasks waiting or failed.")
    assert has_element?(lv, "#sync-pipeline-status", "Manual sync: ")
    assert has_element?(lv, "#sync-pipeline-status", "there's no queue to check")
    refute has_element?(lv, "#sync-pipeline-status", "Caught up")
    assert has_element?(lv, "[data-testid='sync-identity']", "Manual sync")
    assert has_element?(lv, "[data-testid='sync-identity'] code", "sdv_ops_post_a")

    Application.put_env(:scrypath_ops, :sync_mode, :inline)
    {:ok, inline_lv, _html} = live(conn, ~p"/ops/sync-and-index")
    render_async(inline_lv)

    assert has_element?(
             inline_lv,
             "#sync-pipeline-status",
             "Inline sync: writes go straight to Meilisearch, so there's no queue to check."
           )

    refute has_element?(inline_lv, "#sync-pipeline-status", "Caught up")
  end

  test "an observed empty Oban queue reads as caught up", %{conn: conn} do
    Application.put_env(:scrypath_ops, :sync_mode, :oban)
    Application.put_env(:scrypath_ops, :oban, Oban)
    Application.put_env(:scrypath_ops, :oban_queue, :scrypath_sync)
    {:ok, lv, _html} = live(conn, ~p"/ops/sync-and-index")
    render_async(lv)

    assert has_element?(
             lv,
             "#sync-pipeline-status[data-status-kind='success']",
             "Caught up. Nothing queued, retrying or failed."
           )

    assert has_element?(lv, "[data-testid='sync-identity']", "Oban background sync")
    refute has_element?(lv, "#sync-pipeline-status", "no queue to check")
  end

  test "sync activity counts separate pending work, scheduled retries and terminal failures", %{
    conn: conn
  } do
    Application.put_env(:scrypath_ops, :sync_mode, :oban)
    Application.put_env(:scrypath_ops, :oban, Oban)
    Application.put_env(:scrypath_ops, :oban_queue, :scrypath_sync)
    job = %{id: 1, state: "available", worker: "Scrypath.Oban.UpsertWorker", args: %{}}
    Application.put_env(:scrypath_ops, :oban_jobs, [job, %{job | id: 2, state: "retryable"}])
    {:ok, lv, _html} = live(conn, ~p"/ops/sync-and-index")
    render_async(lv)
    assert has_element?(lv, "#sync-pipeline-status", "Sync work is pending")
    assert has_element?(lv, ".ops-sync-work", "1 job queued, 1 scheduled retry")
    refute has_element?(lv, ".ops-sync-work [data-tone='error']")
    refute has_element?(lv, "#sync-pipeline-status", "Caught up")

    assert has_element?(
             lv,
             ".ops-sync-work a[href='/ops/health?schema=ScrypathOps.Test.OpsPostA']"
           )

    Application.put_env(:scrypath_ops, :oban_jobs, [
      job,
      %{job | id: 2, state: "retryable"},
      %{job | id: 3, state: "discarded"}
    ])

    {:ok, updated_lv, _html} = live(conn, ~p"/ops/sync-and-index")
    render_async(updated_lv)

    assert has_element?(
             updated_lv,
             "#sync-pipeline-status[data-status-kind='error']",
             "Some sync work failed"
           )

    assert has_element?(
             updated_lv,
             ".ops-sync-work [data-tone='error']",
             "1 failed sync operation"
           )

    assert has_element?(
             updated_lv,
             ".ops-sync-work a[href='/ops/failed-sync?schema=ScrypathOps.Test.OpsPostA']"
           )
  end

  test "ordinary browsing omits recovery placeholders and keeps a scoped handoff", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/ops/sync-and-index?schema=ScrypathOps.Test.OpsPostB")
    render_async(lv)
    refute has_element?(lv, "#document-freshness-result")
    refute has_element?(lv, "#ordinary-recovery")
    assert has_element?(lv, "h2#sync-pipeline-heading.text-ops-h2")
    assert has_element?(lv, "h2#index-settings-heading.text-ops-h2")
    assert has_element?(lv, "h2#reindexing-heading.text-ops-h2", "Reindexing")
    assert has_element?(lv, "#reindex-idle", "No reindex in progress.")
    assert has_element?(lv, "#reindex-idle a[href='/ops/help#reindexing']")
    refute has_element?(lv, "#index-promotion")
    refute has_element?(lv, "button", "Promote target index")
    assert has_element?(lv, "a[href='/ops/health?schema=ScrypathOps.Test.OpsPostB']")
  end

  test "promotion controls appear once a prepared target index is observed", %{conn: conn} do
    Agent.update(:sync_drift_live_test_state, &Map.put(&1, :ready, true))
    {:ok, lv, _html} = live(conn, ~p"/ops/sync-and-index?schema=ScrypathOps.Test.OpsPostA")
    render_async(lv)

    refute has_element?(lv, "#reindex-idle")
    assert has_element?(lv, "#index-promotion", "sdv_ops_post_a__reindex")

    assert has_element?(
             lv,
             "#index-promotion button#promote-target-index",
             "Promote target index"
           )
  end

  test "a settings response from a previous selection or superseded read is ignored" do
    socket =
      sync_drift_socket(%{
        selected_schema: OpsPostB,
        context_generation: 5,
        drift_request: 3,
        drift_loading: true
      })

    for key <- [{:index_settings, 4, 3}, {:index_settings, 5, 2}] do
      {:noreply, result} = SyncDriftLive.handle_async(key, {:ok, {:error, :old_read}}, socket)
      assert result.assigns.drift_loading
      assert result.assigns.drift_error == nil
    end
  end

  test "settings show actual differences without counting overlapping categories twice", %{
    conn: conn
  } do
    Agent.update(
      :sync_drift_live_test_state,
      &Map.put(&1, :applied_settings, %{
        "searchableAttributes" => ["*"],
        "filterableAttributes" => ["unexpected"],
        "sortableAttributes" => []
      })
    )

    {:ok, lv, _html} = live(conn, ~p"/ops/sync-and-index")
    html = render_async(lv)

    assert has_element?(
             lv,
             "[role='region'][aria-label='Index settings differences'][tabindex='0']"
           )

    assert has_element?(lv, "th", "Declared in schema")
    assert has_element?(lv, "th", "Effect")
    assert html =~ "unexpected"
    assert html =~ "Not declared"
    refute html =~ "Dimension mismatches"
    refute html =~ "version 1"
    refute html =~ "Full comparison details"
    refute html =~ "snapshot"

    assert has_element?(
             lv,
             "#index-settings-status[data-status-kind='warning']",
             "Meilisearch settings differ from the schema"
           )

    assert has_element?(lv, "#index-settings-status a[href='/ops/help#settings']")

    assert has_element?(
             lv,
             ".ops-settings-diff tbody tr",
             "Works now, but applying the schema's settings would remove it."
           )

    Agent.update(
      :sync_drift_live_test_state,
      &Map.put(&1, :applied_settings, %{
        "searchableAttributes" => ["other"],
        "filterableAttributes" => [],
        "sortableAttributes" => []
      })
    )

    {:ok, missing_lv, _html} = live(conn, ~p"/ops/sync-and-index")
    render_async(missing_lv)

    assert has_element?(missing_lv, ".ops-settings-diff tbody th code", "title")
    assert has_element?(missing_lv, ".ops-setting-live[data-missing='true']", "Not searchable")
    assert has_element?(missing_lv, ".ops-settings-diff tbody tr", "Not searched yet.")
  end

  test "failed settings refresh retains the previous comparison and its original check time", %{
    conn: conn
  } do
    Agent.update(:sync_drift_live_test_state, &Map.put(&1, :ready, true))
    {:ok, lv, _html} = live(conn, ~p"/ops/sync-and-index")
    render_async(lv)
    before = :sys.get_state(lv.pid).socket.assigns
    Agent.update(:sync_drift_live_test_state, &Map.put(&1, :ready, false))
    lv |> element("#sync-and-index-refresh") |> render_click()
    html = render_async(lv)
    after_check = :sys.get_state(lv.pid).socket.assigns
    assert after_check.drift_result == before.drift_result
    assert after_check.drift_loaded_at == before.drift_loaded_at
    assert after_check.drift_error == :settings
    assert html =~ "Showing the comparison from"
    assert has_element?(lv, "#index-settings-error time[datetime]")
    assert has_element?(lv, "#index-settings-error pre", ":settings")
  end

  test "verified document freshness renders the exact expected effect and index", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/ops/sync-and-index?schema=ScrypathOps.Test.OpsPostB")

    assigns =
      :sys.get_state(lv.pid).socket.assigns
      |> Map.put(:recovery_document_observation, %{
        state: :verified,
        operation: :upsert,
        index: "sdv_ops_post_b",
        expected_ids: ["post-6001"],
        checked_at: DateTime.utc_now()
      })

    html =
      assigns
      |> SyncDriftLive.render()
      |> Phoenix.HTML.Safe.to_iodata()
      |> IO.iodata_to_binary()

    assert html =~ "Expected documents observed"
    assert html =~ "Expected effect: upsert"
    assert html =~ "sdv_ops_post_b"
    assert html =~ "post-6001"
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
               "https://scrypath.example/ops/sync-and-index",
               socket
             )

    assert entered.assigns.context_generation == 1
    assert entered.assigns.recovery_origin_generation == 7
    assert entered.assigns.recovery_handle == "opaque-receipt"

    assert {:noreply, invalid} =
             SyncDriftLive.handle_params(
               %{params | "recovery_generation" => "oops"},
               "https://scrypath.example/ops/sync-and-index",
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
        "https://scrypath.example/ops/sync-and-index?schema=ScrypathOps.Test.OpsPostB",
        loading_socket
      )

    assert switched_socket.assigns.selected_schema == OpsPostB
    assert switched_socket.assigns.context_generation == 5

    {:noreply, final_socket} = SyncDriftLive.handle_info({:run_drift, 4}, switched_socket)
    assert Agent.get(:sync_drift_live_test_state, & &1.settings_calls) == 0
    assert final_socket.assigns.selected_schema == OpsPostB
    assert final_socket.assigns.drift_result == nil
  end

  test "recovery refresh retains prior verification and stale results cannot replace it" do
    checked_at = DateTime.utc_now()

    socket =
      sync_drift_socket(%{
        selected_schema: OpsPostA,
        context_generation: 8,
        recovery_handle: "opaque-handle",
        recovery_status: :verified,
        recovery_checked_at: checked_at,
        recovery_loading: false
      })

    {:noreply, refreshing} = SyncDriftLive.handle_event("refresh_recovery_status", %{}, socket)

    assert refreshing.assigns.recovery_status == :verified
    assert refreshing.assigns.recovery_checked_at == checked_at
    assert refreshing.assigns.recovery_loading
    assert Agent.get(:sync_drift_live_test_state, & &1.tasks_calls) == 0
    assert Agent.get(:sync_drift_live_test_state, & &1.settings_calls) == 0

    {:noreply, stale} =
      SyncDriftLive.handle_async(
        {:recovery_observation, 7, "opaque-handle"},
        {:ok, {7, "opaque-handle", :verified}},
        refreshing
      )

    assert stale.assigns.recovery_status == :verified
    assert stale.assigns.recovery_checked_at == checked_at
    assert stale.assigns.recovery_loading
  end

  test "recovery results retain exact observed evidence while refresh runs" do
    evidence = %{replacement_job: 45, attempt: 1, task_uid: 780, index: "posts"}

    document_observation = %{
      state: :verified,
      operation: :upsert,
      index: "posts",
      expected_ids: ["post-45"],
      checked_at: DateTime.utc_now()
    }

    socket = sync_drift_socket(%{context_generation: 3, recovery_handle: "receipt"})

    {:noreply, checked} =
      SyncDriftLive.handle_async(
        {:recovery_observation, 3, "receipt"},
        {:ok, {3, "receipt", {:verified, evidence, document_observation}}},
        socket
      )

    assert checked.assigns.recovery_status == :verified
    assert checked.assigns.recovery_evidence == evidence
    assert checked.assigns.recovery_document_observation == document_observation
    checked_at = checked.assigns.recovery_checked_at
    {:noreply, refreshing} = SyncDriftLive.handle_event("refresh_recovery_status", %{}, checked)
    assert refreshing.assigns.recovery_evidence == evidence
    assert refreshing.assigns.recovery_document_observation == document_observation
    assert refreshing.assigns.recovery_checked_at == checked_at
    assert refreshing.assigns.recovery_loading

    {:noreply, unavailable} =
      SyncDriftLive.handle_async(
        {:recovery_observation, 3, "receipt"},
        {:ok,
         {3, "receipt",
          {:unknown, nil, %{state: :not_checked, reason: :task_unavailable, checked_at: nil}}}},
        refreshing
      )

    assert unavailable.assigns.recovery_status == :verified
    assert unavailable.assigns.recovery_evidence == evidence
    assert unavailable.assigns.recovery_document_observation == document_observation
    assert unavailable.assigns.recovery_checked_at == checked_at
    assert unavailable.assigns.recovery_observation_error == :task_unavailable
    refute unavailable.assigns.recovery_loading
  end

  test "recovery lifecycle states retain the receipt identity and distinguish observer errors" do
    evidence = %{replacement_job: 45, attempt: 2, task_uid: 781, index: "posts"}

    observation = %{
      state: :verified,
      operation: :delete,
      index: "posts",
      expected_ids: ["post-45"]
    }

    for {status, document_observation} <- [
          {:accepted, nil},
          {:running, nil},
          {:failed, nil},
          {:cancelled, %{state: :cancelled, operation: :delete, index: "posts"}},
          {:unknown, %{state: :unknown, reason: :transport_error}}
        ] do
      socket =
        sync_drift_socket(%{
          context_generation: 6,
          recovery_handle: "receipt",
          recovery_status: :verified,
          recovery_evidence: evidence,
          recovery_document_observation: observation,
          recovery_checked_at: ~U[2026-01-02 03:04:05Z]
        })

      {:noreply, result} =
        SyncDriftLive.handle_async(
          {:recovery_observation, 6, "receipt"},
          {:ok, {6, "receipt", {status, evidence, document_observation}}},
          socket
        )

      if status == :unknown do
        assert result.assigns.recovery_status == :verified
        assert result.assigns.recovery_evidence == evidence
        assert result.assigns.recovery_document_observation == observation
        assert result.assigns.recovery_checked_at == ~U[2026-01-02 03:04:05Z]
        assert result.assigns.recovery_observation_error == :transport_error
      else
        assert result.assigns.recovery_status == status
        assert result.assigns.recovery_evidence == evidence
        assert result.assigns.recovery_document_observation == document_observation
        assert result.assigns.recovery_checked_at
        assert is_nil(result.assigns.recovery_observation_error)
      end
    end
  end

  test "swap observer keeps exact task outcomes and waits for fresh evidence before completion" do
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
        {:ok, {9, 991, {:ok, %{id: 991, state: :succeeded}}}},
        socket
      )

    assert completed.assigns.promotion_status == :unknown
    assert completed.assigns.promotion_task_id == 991

    {:noreply, wrong_task} =
      SyncDriftLive.handle_async(
        {:promotion_swap, 9, 991},
        {:ok, {9, 991, {:ok, %{id: 992, state: :succeeded}}}},
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

    assert failed.assigns.promotion_status ==
             {:failed,
              {:task_failed,
               %OperationTask{source: :meilisearch, kind: :index_swap, id: 991, state: :failed}}}

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

    assert cancelled.assigns.promotion_status ==
             {:failed,
              {:cancelled,
               %OperationTask{source: :meilisearch, kind: :index_swap, id: 991, state: :cancelled}}}

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
        {:ok, {8, 991, {:ok, %{id: 991, state: :succeeded}}}},
        socket
      )

    assert stale.assigns.promotion_status == :accepted
    assert stale.assigns.promotion_loading
  end

  test "promotion result announces its outcome and distinguishes cancellation", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/ops/sync-and-index?schema=ScrypathOps.Test.OpsPostA")
    base = :sys.get_state(lv.pid).socket.assigns

    accepted_html =
      base
      |> Map.merge(%{
        promotion_task_id: 991,
        promotion_status: :accepted,
        promotion_loading: true
      })
      |> SyncDriftLive.render()
      |> Phoenix.HTML.Safe.to_iodata()
      |> IO.iodata_to_binary()

    assert accepted_html =~ ~s(id="promotion-status-result")
    assert accepted_html =~ ~s(role="status")
    assert accepted_html =~ "Index swap accepted"

    cancelled_html =
      base
      |> Map.merge(%{
        promotion_task_id: 991,
        promotion_status:
          {:failed,
           {:cancelled,
            %OperationTask{
              source: :meilisearch,
              kind: :index_swap,
              id: 991,
              state: :cancelled
            }}},
        promotion_loading: false
      })
      |> SyncDriftLive.render()
      |> Phoenix.HTML.Safe.to_iodata()
      |> IO.iodata_to_binary()

    assert cancelled_html =~ ~s(id="promotion-status-result")
    assert cancelled_html =~ ~s(role="alert")
    assert cancelled_html =~ "Index swap canceled"
    assert cancelled_html =~ "The swap task was canceled."
    assert cancelled_html =~ "991"
    refute cancelled_html =~ "The swap task failed."
  end

  test "a successful swap task without fresh index evidence is not promotion completion" do
    socket =
      sync_drift_socket(%{
        context_generation: 9,
        promotion_task_id: 991,
        promotion_status: :accepted,
        promotion_loading: true,
        reconcile_result: nil,
        reconcile_error: :backend_unavailable,
        drift_result: nil,
        drift_error: :backend_unavailable
      })

    assert {:noreply, observed} =
             SyncDriftLive.handle_async(
               {:promotion_swap, 9, 991},
               {:ok, {9, 991, {:ok, %{id: 991, state: :succeeded}}}},
               socket
             )

    assert observed.assigns.promotion_status == :unknown
    assert observed.assigns.promotion_task_id == 991
  end

  test "a correlated prepared-target document mismatch keeps promotion unconfirmed", %{
    conn: conn
  } do
    Agent.update(:sync_drift_live_test_state, fn state ->
      state |> Map.put(:ready, true) |> Map.put(:task_status, "succeeded")
    end)

    stub = Module.concat(__MODULE__, "PromotionDocumentMismatch")
    test_pid = self()

    Req.Test.stub(stub, fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/indexes/sdv_ops_post_a/documents/7301"
      send(test_pid, :prepared_target_document_read)

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(200, Jason.encode!(%{"id" => 7301, "title" => "Stale"}))
    end)

    {:ok, lv, _html} = live(conn, ~p"/ops/sync-and-index?schema=ScrypathOps.Test.OpsPostA")
    handle = prepare_promotion_observation(lv, stub, [promotion_failed_job()])

    lv
    |> render_click("refresh_promotion_checks", %{})
    |> then(fn _ -> render_async(lv) end)

    result = :sys.get_state(lv.pid).socket.assigns
    html = render(lv)

    assert result.promotion_status == :unknown

    assert result.promotion_document_observation.reason ==
             {:prepared_target_effect_unconfirmed, :failed, :document_mismatch}

    assert result.promotion_task_id == 991
    assert result.recovery_handle == handle
    assert result.promotion_identity.live_index == "sdv_ops_post_a"
    assert result.promotion_identity.target_index == "sdv_ops_post_a__reindex"
    assert html =~ "Index swap outcome unconfirmed"
    assert html =~ "document_mismatch"
    assert html =~ "991"
    assert_receive :prepared_target_document_read
    assert has_element?(lv, "#index-promotion button", "Refresh checks")
    assert Agent.get(:sync_drift_live_test_state, & &1.swap_calls) == 0
  end

  test "a correlated receipt with unavailable expected-effect source stays unconfirmed", %{
    conn: conn
  } do
    Agent.update(:sync_drift_live_test_state, fn state ->
      state |> Map.put(:ready, true) |> Map.put(:task_status, "succeeded")
    end)

    stub = Module.concat(__MODULE__, "UnavailablePromotionEffectSource")
    Req.Test.stub(stub, fn conn -> Plug.Conn.send_resp(conn, 503, "unavailable") end)

    {:ok, lv, _html} = live(conn, ~p"/ops/sync-and-index?schema=ScrypathOps.Test.OpsPostA")
    handle = prepare_promotion_observation(lv, stub, [])

    lv
    |> render_click("refresh_promotion_checks", %{})
    |> then(fn _ -> render_async(lv) end)

    result = :sys.get_state(lv.pid).socket.assigns
    html = render(lv)

    assert result.promotion_status == :unknown

    assert result.promotion_document_observation.reason ==
             {:prepared_target_effect_unconfirmed, :unknown, :source_unavailable}

    assert result.promotion_task_id == 991
    assert result.recovery_handle == handle
    assert html =~ "Index swap outcome unconfirmed"
    assert html =~ "source_unavailable"
    refute html =~ "Index swap completed"
    assert Agent.get(:sync_drift_live_test_state, & &1.swap_calls) == 0
  end

  test "an unavailable expected-document read keeps a succeeded swap unconfirmed across refreshes",
       %{
         conn: conn
       } do
    Agent.update(:sync_drift_live_test_state, fn state ->
      state |> Map.put(:ready, true) |> Map.put(:task_status, "succeeded")
    end)

    stub = Module.concat(__MODULE__, "UnavailablePromotionDocumentRead")
    test_pid = self()

    Req.Test.stub(stub, fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/indexes/sdv_ops_post_a/documents/7301"
      send(test_pid, :prepared_target_document_read)
      Plug.Conn.send_resp(conn, 503, "unavailable")
    end)

    {:ok, lv, _html} = live(conn, ~p"/ops/sync-and-index?schema=ScrypathOps.Test.OpsPostA")
    handle = prepare_promotion_observation(lv, stub, [promotion_failed_job()])

    lv
    |> render_click("refresh_promotion_checks", %{})
    |> then(fn _ -> render_async(lv) end)

    result = :sys.get_state(lv.pid).socket.assigns
    html = render(lv)

    assert result.promotion_status == :unknown

    assert result.promotion_document_observation.reason ==
             {:prepared_target_effect_unconfirmed, :unknown, :document_observation_http_error}

    assert result.promotion_task_id == 991
    assert result.recovery_handle == handle
    assert result.promotion_identity.schema == OpsPostA
    assert result.promotion_identity.live_index == "sdv_ops_post_a"
    assert result.promotion_identity.target_index == "sdv_ops_post_a__reindex"

    assert html =~
             "The swap task succeeded, but its expected-document observation could not be confirmed."

    assert html =~ "Expected document effect:"
    assert html =~ "document_observation_http_error"
    assert html =~ "991"
    refute html =~ "The selected live-index or contract effect could not be confirmed"
    refute html =~ "Index swap failed"
    refute html =~ "Index swap completed"
    assert_receive :prepared_target_document_read
    assert has_element?(lv, "#index-promotion button", "Refresh checks")

    lv
    |> render_click("refresh_promotion_checks", %{})
    |> then(fn _ -> render_async(lv) end)

    refreshed = :sys.get_state(lv.pid).socket.assigns
    assert refreshed.promotion_status == :unknown
    assert refreshed.promotion_task_id == 991
    assert refreshed.recovery_handle == handle
    assert Agent.get(:sync_drift_live_test_state, & &1.task_calls) == [991, 991]
    assert Agent.get(:sync_drift_live_test_state, & &1.swap_calls) == 0
  end

  test "promotion without an applicable receipt says document freshness was not checked", %{
    conn: conn
  } do
    Agent.update(:sync_drift_live_test_state, fn state ->
      state |> Map.put(:ready, true) |> Map.put(:task_status, "succeeded")
    end)

    stub = Module.concat(__MODULE__, "NoApplicablePromotionEffect")
    Req.Test.stub(stub, fn conn -> Plug.Conn.send_resp(conn, 503, "unused") end)

    {:ok, lv, _html} = live(conn, ~p"/ops/sync-and-index?schema=ScrypathOps.Test.OpsPostA")
    prepare_promotion_observation(lv, stub, [], false)

    lv
    |> render_click("refresh_promotion_checks", %{})
    |> then(fn _ -> render_async(lv) end)

    result = :sys.get_state(lv.pid).socket.assigns
    html = render(lv)

    assert result.promotion_status == :completed
    assert result.promotion_document_observation.state == :not_checked

    assert result.promotion_document_observation.reason ==
             :no_authoritative_prepared_target_effect

    assert html =~ "Expected document freshness was not checked"
    refute html =~ "Expected documents observed"
    assert Agent.get(:sync_drift_live_test_state, & &1.swap_calls) == 0
  end

  test "post-promotion evidence applies only to the current generation and task" do
    socket =
      sync_drift_socket(%{
        context_generation: 9,
        promotion_task_id: 991,
        promotion_status: :unknown,
        promotion_loading: true
      })

    observed_assigns = %{
      reconcile_result: %{schema: OpsPostA},
      reconcile_loaded_at: DateTime.utc_now(),
      reconcile_generation: 9,
      reconcile_error: nil,
      drift_result: %{schema: OpsPostA},
      drift_loaded_at: DateTime.utc_now(),
      drift_generation: 9,
      drift_error: nil,
      promotion_status: :completed,
      promotion_document_observation: %{state: :verified},
      promotion_observation_error: nil
    }

    assert {:noreply, observed} =
             SyncDriftLive.handle_async(
               {:promotion_effects, 9, 991},
               {:ok, {9, 991, observed_assigns}},
               socket
             )

    assert observed.assigns.promotion_status == :completed
    assert observed.assigns.promotion_document_observation == %{state: :verified}
    refute observed.assigns.promotion_loading

    assert {:noreply, stale} =
             SyncDriftLive.handle_async(
               {:promotion_effects, 8, 991},
               {:ok, {8, 991, observed_assigns}},
               socket
             )

    assert stale.assigns == socket.assigns
  end

  test "promotion task refresh failure clears the previous document observation", %{
    conn: conn
  } do
    {:ok, lv, _html} = live(conn, ~p"/ops/sync-and-index?schema=ScrypathOps.Test.OpsPostA")
    mounted_socket = :sys.get_state(lv.pid).socket
    generation = mounted_socket.assigns.context_generation

    pending_html =
      mounted_socket.assigns
      |> Map.merge(%{
        promotion_task_id: 991,
        promotion_status: :unknown,
        promotion_loading: true,
        promotion_document_observation: %{state: :verified},
        promotion_observation_error: nil
      })
      |> SyncDriftLive.render()
      |> Phoenix.HTML.Safe.to_iodata()
      |> IO.iodata_to_binary()

    assert pending_html =~ "Checking the retained swap task and current index evidence."
    refute pending_html =~ "Expected document effect:"

    refute pending_html =~
             "The swap task succeeded, but its expected-document observation could not be confirmed."

    refute pending_html =~ "The task result could not be confirmed."

    socket = %{
      mounted_socket
      | assigns:
          Map.merge(mounted_socket.assigns, %{
            promotion_task_id: 991,
            promotion_status: :completed,
            promotion_loading: true,
            promotion_document_observation: %{state: :verified},
            promotion_observation_error: nil
          })
    }

    assert {:noreply, refreshed} =
             SyncDriftLive.handle_async(
               {:promotion_refresh, generation, 991},
               {:exit, :task_unavailable},
               socket
             )

    assert refreshed.assigns.promotion_status == :unknown
    refute refreshed.assigns.promotion_loading
    assert is_nil(refreshed.assigns.promotion_document_observation)
    assert is_nil(refreshed.assigns.promotion_observation_error)
    assert refreshed.assigns.promotion_task_read_error == :task_observation_exit

    html =
      refreshed.assigns
      |> SyncDriftLive.render()
      |> Phoenix.HTML.Safe.to_iodata()
      |> IO.iodata_to_binary()

    assert html =~ "The retained task result could not be confirmed (task_observation_exit)."
    assert html =~ "Refresh to inspect this same task; do not submit another operation."
    refute html =~ "Expected document effect:"
    refute html =~ "The selected live-index or contract effect could not be confirmed"

    refute html =~
             "The swap task succeeded, but its expected-document observation could not be confirmed."
  end

  test "mounted promotion refresh reads the retained UID once without swapping again", %{
    conn: conn
  } do
    {:ok, lv, _html} = live(conn, ~p"/ops/sync-and-index?schema=ScrypathOps.Test.OpsPostA")

    :sys.replace_state(lv.pid, fn state ->
      socket = %{
        state.socket
        | assigns:
            Map.merge(state.socket.assigns, %{
              promotion_task_id: 991,
              promotion_status: :unknown,
              promotion_loading: false,
              promotion_identity: nil,
              __changed__:
                Map.merge(state.socket.assigns.__changed__, %{
                  promotion_task_id: true,
                  promotion_status: true,
                  promotion_loading: true
                })
            })
      }

      %{state | socket: socket}
    end)

    assert :sys.get_state(lv.pid).socket.assigns.promotion_status == :unknown

    lv
    |> element("button[phx-click='refresh_reconcile']")
    |> render_click()

    lv
    |> element("#index-promotion button", "Refresh checks")
    |> render_click()
    |> then(fn _ -> render_async(lv) end)

    lv
    |> element("#index-promotion button", "Refresh checks")
    |> render_click()
    |> then(fn _ -> render_async(lv) end)

    assert Agent.get(:sync_drift_live_test_state, & &1.task_calls) == [991, 991]
    assert Agent.get(:sync_drift_live_test_state, & &1.swap_calls) == 0
    assert :sys.get_state(lv.pid).socket.assigns.promotion_task_id == 991
  end

  test "rendered sync drift links preserve the selected schema", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/ops/sync-and-index?schema=ScrypathOps.Test.OpsPostB")

    assert html =~ "OpsPostB"
    assert has_element?(lv, "a[href='/ops']", "Return to Control Room")
    assert has_element?(lv, "a[href='/ops/health?schema=ScrypathOps.Test.OpsPostB']")
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
    assert inspect(updated_socket.redirected) =~ "return_to=%2Fops%2Fsync-and-index"
    assert Agent.get(:sync_drift_live_test_state, & &1.swap_called) != true
    assert Agent.get(:sync_drift_live_test_state, & &1.tasks_calls) == 0
    assert Agent.get(:sync_drift_live_test_state, & &1.settings_calls) == 0
    assert updated_socket.assigns.local_ui_state == :keep
  end

  defp prepare_promotion_observation(lv, stub, oban_jobs, register_receipt? \\ true) do
    socket = :sys.get_state(lv.pid).socket
    assigns = socket.assigns
    schema_name = Atom.to_string(OpsPostA) |> String.replace_prefix("Elixir.", "")

    host_context = %{
      host: socket.host_uri.host || "unknown",
      org: nil,
      schema: schema_name,
      generation: assigns.recovery_origin_generation
    }

    handle =
      if register_receipt? do
        {:ok, handle} =
          RecoveryObservation.register(host_context, %{
            replacement_job: 520,
            attempt: 2,
            operation: :upsert,
            schema: schema_name,
            index: "sdv_ops_post_a__reindex",
            backend: "Elixir.Scrypath.Meilisearch",
            source_failure: %{id: 520},
            task_uid: 812,
            endpoint: "http://localhost:7700"
          })

        handle
      end

    opts =
      Keyword.merge(assigns.scrypath_opts,
        sync_mode: :oban,
        oban: Oban,
        oban_queue: :scrypath_sync,
        oban_inspector: SyncDriftObanInspector,
        oban_jobs: oban_jobs,
        req_options: [plug: {Req.Test, stub}]
      )

    :sys.replace_state(lv.pid, fn state ->
      current = state.socket

      next_assigns =
        Map.merge(current.assigns, %{
          scrypath_opts: opts,
          promotion_task_id: 991,
          promotion_status: :unknown,
          promotion_loading: false,
          promotion_identity: %{
            schema: OpsPostA,
            generation: current.assigns.context_generation,
            live_index: "sdv_ops_post_a",
            target_index: "sdv_ops_post_a__reindex"
          },
          recovery_handle: handle
        })

      %{state | socket: %{current | assigns: next_assigns}}
    end)

    handle
  end

  defp promotion_failed_job do
    schema_name = Atom.to_string(OpsPostA) |> String.replace_prefix("Elixir.", "")

    %{
      id: 520,
      state: "discarded",
      worker: "Scrypath.Oban.UpsertWorker",
      queue: "scrypath_sync",
      args: %{
        "operation" => "upsert",
        "schema" => schema_name,
        "backend" => "Elixir.Scrypath.Meilisearch",
        "index" => "sdv_ops_post_a__reindex",
        "document_count" => 1,
        "document_ids" => [7301],
        "documents" => [%{"id" => 7301, "data" => %{"title" => "Prepared"}}]
      }
    }
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
      page_title: "Sync and index",
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
      promotion_task_id: nil,
      promotion_status: nil,
      promotion_task_read_error: nil,
      confirm_swap?: false,
      recovery_status: nil,
      recovery_evidence: nil,
      recovery_checked_at: nil,
      recovery_loading: false,
      current_scope: scope,
      operator_context: operator_context,
      local_ui_state: nil
    }

    %Phoenix.LiveView.Socket{
      assigns: Map.merge(base_assigns, overrides),
      host_uri: URI.parse("https://scrypath.example/ops/sync-and-index")
    }
  end

  defp sync_drift_scrypath_opts do
    [
      backend: Scrypath.Meilisearch,
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
