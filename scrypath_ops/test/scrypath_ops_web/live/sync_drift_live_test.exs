defmodule ScrypathOpsWeb.SyncDriftLiveTest do
  @moduledoc false
  # Phase 47 D-10: SECURITY + prod guard tests. D-14: reconcile on mount does not bundle
  # `include_index_contract_drift`; drift loads only via explicit control.
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScrypathOps.Test.OpsPostA
  alias ScrypathOps.Test.OpsPostB
  alias ScrypathOps.Integrations.Sigra.OperatorContext
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

    def swap_indexes(_indexes, _config) do
      Agent.update(:sync_drift_live_test_state, fn state ->
        Map.put(state, :swap_called, true)
      end)

      {:ok,
       %{
         "uid" => 201,
         "status" => "succeeded",
         "type" => "indexSwap",
         "indexUid" => "sdv_ops_post_b"
       }}
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

    if pid = Process.whereis(:sync_drift_live_test_state) do
      Agent.stop(pid)
    end

    {:ok, _pid} =
      Agent.start_link(fn -> %{tasks_calls: 0, settings_calls: 0, swap_called: false} end,
        name: :sync_drift_live_test_state
      )

    on_exit(fn ->
      Enum.each(previous, fn
        {k, nil} -> Application.delete_env(:scrypath_ops, k)
        {k, v} -> Application.put_env(:scrypath_ops, k, v)
      end)

      if pid = Process.whereis(:sync_drift_live_test_state) do
        Agent.stop(pid)
      end
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

  test "loads reconcile on mount and scopes drift errors separately", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/ops/sync-drift")

    assert html =~ "queue posture"

    assert html =~
             "Check sync status and compare the schema contract with its live index."

    assert html =~ "Check current backend tasks and queued work for this schema."
    assert html =~ "Index contract"
    assert html =~ "sdv_ops_post_a"
    refute html =~ ":settings"

    # `load_drift` now defers the bounded backend read to a `:run_drift` message so the
    # loading skeleton paints first (S3). The click shows the in-flight state; rendering
    # again flushes the deferred read and surfaces the drift result.
    loading_html =
      lv
      |> element("button", "Check index contract")
      |> render_click()

    assert loading_html =~ "Loading contract drift"

    html2 = render(lv)

    assert html2 =~ ":settings"
    assert html2 =~ "sdv_ops_post_a"
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
        {:ok, {9, 991, {:ok, %{id: 991, state: :succeeded}}}},
        socket
      )

    assert completed.assigns.promotion_status == :completed
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
    assert has_element?(lv, "a[href='/ops']", "Recheck search health")
    assert has_element?(lv, "a[href='/ops/posture?schema=ScrypathOps.Test.OpsPostB']")
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
      page_title: "Sync / drift",
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
      host_uri: URI.parse("https://scrypath.example/ops/sync-drift")
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
