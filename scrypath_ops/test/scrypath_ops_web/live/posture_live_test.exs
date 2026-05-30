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
        {:error, :boom}
      else
        {:ok, %{results: Keyword.get(config, :meilisearch_tasks, [])}}
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

    {:ok, _pid} =
      Agent.start_link(fn -> %{tasks_calls: 0, swap_called: false} end,
        name: :posture_live_test_state
      )

    Application.put_env(:scrypath_ops, :meilisearch_tasks, [
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
    {:ok, _lv, html} = live(conn, ~p"/ops/posture")

    assert html =~ "data-testid=\"posture-row\""
    assert html =~ "fetch error: :boom"
    assert html =~ "queue not observed"
  end

  test "posture shows next checks block with ordered items and failed-sync egress", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/ops/posture")

    assert has_element?(lv, "[data-testid='posture-next-checks']")

    html = render(lv)
    assert html =~ "Degraded"
    assert html =~ "/ops/failed-sync"

    [_before, rest] = String.split(html, ~s(data-testid="posture-next-checks"), parts: 2)
    [section | _] = String.split(rest, "</section>", parts: 2)
    li_opens = Regex.scan(~r/<li[\s>]/, section)
    assert length(li_opens) <= 5
  end

  test "swap live fresh sudo refreshes posture in place and keeps local assigns" do
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

    assert Agent.get(:posture_live_test_state, & &1.swap_called) == true
    assert Agent.get(:posture_live_test_state, & &1.tasks_calls) == 2
    assert updated_socket.assigns.local_ui_state == %{expanded: [:details]}
    assert match?({:ok, _}, updated_socket.assigns.posture_rows)
    assert updated_socket.assigns.last_refresh_at != nil
  end

  test "swap live blocks impersonation before refresh" do
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

    assert flash_value(updated_socket, "error") =~ "Impersonation must be cleared"
    assert Agent.get(:posture_live_test_state, & &1.swap_called) != true
    assert Agent.get(:posture_live_test_state, & &1.tasks_calls) == 0
    assert updated_socket.assigns.local_ui_state == :keep
    assert updated_socket.assigns.posture_rows == []
  end

  test "swap live stale sudo redirects with return_to only" do
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

    assert inspect(updated_socket.redirected) =~ "/sudo/confirm"
    assert inspect(updated_socket.redirected) =~ "return_to=%2Fops%2Fposture"
    assert Agent.get(:posture_live_test_state, & &1.swap_called) != true
    assert Agent.get(:posture_live_test_state, & &1.tasks_calls) == 0
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
      page_title: "Posture / health",
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
      host_uri: URI.parse("https://scrypath.example/ops/posture")
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
end
