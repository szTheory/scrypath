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

  defmodule SyncDriftClient do
    def tasks(_filters, config) do
      Agent.update(:sync_drift_live_test_state, fn state ->
        Map.update!(state, :tasks_calls, &(&1 + 1))
      end)

      {:ok, %{results: Keyword.get(config, :meilisearch_tasks, [])}}
    end

    def get_settings(_index, _config) do
      Agent.update(:sync_drift_live_test_state, fn state ->
        Map.update!(state, :settings_calls, &(&1 + 1))
      end)

      {:error, :settings}
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

    Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostA])
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

  test "loads reconcile on mount and scopes drift errors separately", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/ops/sync-drift")

    assert html =~ "queue posture"
    assert html =~ "Index contract (declared vs live)"
    assert html =~ "sdv_ops_post_a"
    refute html =~ ":settings"

    html2 =
      lv
      |> element("button", "Load / refresh contract drift")
      |> render_click()

    assert html2 =~ ":settings"
    assert html2 =~ "sdv_ops_post_a"
  end

  test "swap live fresh sudo refreshes reconcile and drift in place" do
    socket =
      sync_drift_socket(%{
        selected_schema: OpsPostB,
        local_ui_state: %{compact?: true}
      })

    {:noreply, socket} = SyncDriftLive.handle_event("load_drift", %{}, socket)

    assert Agent.get(:sync_drift_live_test_state, & &1.settings_calls) == 1
    assert socket.assigns.drift_error == :settings

    assert {:noreply, updated_socket} = SyncDriftLive.handle_event("swap_live", %{}, socket)

    assert Agent.get(:sync_drift_live_test_state, & &1.swap_called) == true
    assert Agent.get(:sync_drift_live_test_state, & &1.tasks_calls) > 0
    assert Agent.get(:sync_drift_live_test_state, & &1.settings_calls) == 2
    assert updated_socket.assigns.selected_schema == OpsPostB
    assert updated_socket.assigns.local_ui_state == %{compact?: true}
    assert updated_socket.assigns.reconcile_loaded_at != nil
    assert updated_socket.assigns.drift_error == :settings
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

    assert updated_socket.assigns.selected_schema == OpsPostA
    assert flash_value(updated_socket, "error") =~ "allowlisted"

    assert_raise ArgumentError, fn ->
      String.to_existing_atom(mod_str)
    end
  end

  test "swap live blocks impersonation before any refresh" do
    socket =
      sync_drift_socket(%{
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
      reconcile_result: nil,
      reconcile_loaded_at: nil,
      drift_result: nil,
      drift_loaded_at: nil,
      drift_error: nil,
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
