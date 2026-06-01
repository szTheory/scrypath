defmodule ScrypathOpsWeb.FailedSyncLiveTest do
  @moduledoc false
  # Phase 47 D-10: see SECURITY + prod guard tests. D-13: `reason_class_counts: true`
  # inspection + rollup counts (`FailedSyncLive` mount).
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScrypathOps.Test.OpsPostA

  defmodule FailedSyncFakeClient do
    def tasks(_filters, config) do
      {:ok, %{results: Keyword.get(config, :meilisearch_tasks, [])}}
    end
  end

  defmodule FailedSyncObanInspector do
    def list_jobs(_schema_module, config) do
      {:ok, Keyword.get(config, :oban_jobs, [])}
    end
  end

  defmodule RecordingOban do
    def insert(changeset) do
      job = Ecto.Changeset.apply_changes(changeset)
      {:ok, %{job | id: 991, state: "available"}}
    end
  end

  defmodule Elixir.Oban.Job do
    defstruct [:id, :worker, :queue, :state, :attempt, :max_attempts, :args]

    def new(args, opts) do
      %Ecto.Changeset{
        data: %__MODULE__{
          args: args,
          worker: Keyword.fetch!(opts, :worker),
          queue: Keyword.fetch!(opts, :queue),
          max_attempts: Keyword.fetch!(opts, :max_attempts),
          state: "available",
          attempt: 0
        },
        changes: %{},
        errors: [],
        valid?: true,
        action: nil,
        types: %{},
        params: nil
      }
    end
  end

  setup do
    keys = ~w(
      schema_allowlist backend sync_mode index_prefix meilisearch_url meilisearch_client
      meilisearch_tasks oban oban_queue oban_inspector oban_jobs
    )a

    previous = Map.new(keys, &{&1, Application.get_env(:scrypath_ops, &1)})
    prev_sigra = Application.get_env(:scrypath_ops, :sigra)
    prev_opsui_auth_mode = System.get_env("OPSUI_AUTH_MODE")

    Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostA])
    Application.put_env(:scrypath_ops, :backend, Scrypath.Meilisearch)
    Application.put_env(:scrypath_ops, :sync_mode, :oban)
    Application.put_env(:scrypath_ops, :index_prefix, "fsv")
    Application.put_env(:scrypath_ops, :meilisearch_url, "http://localhost:7700")
    Application.put_env(:scrypath_ops, :meilisearch_client, FailedSyncFakeClient)

    Application.put_env(:scrypath_ops, :meilisearch_tasks, [
      %{
        "uid" => 401,
        "status" => "failed",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "fsv_ops_post_a",
        "error" => %{"message" => "index missing"}
      }
    ])

    Application.put_env(:scrypath_ops, :oban, RecordingOban)
    Application.put_env(:scrypath_ops, :oban_queue, :search_sync)
    Application.put_env(:scrypath_ops, :oban_inspector, FailedSyncObanInspector)

    Application.put_env(:scrypath_ops, :sigra,
      sudo_confirm_path: "/sudo/confirm",
      sudo_window: 300
    )

    System.put_env("OPSUI_AUTH_MODE", "sigra")

    Application.put_env(:scrypath_ops, :oban_jobs, [
      %{
        id: 501,
        state: "retryable",
        worker: "Scrypath.Oban.UpsertWorker",
        queue: "search_sync",
        args: %{
          "operation" => "upsert",
          "schema" => "Elixir.ScrypathOps.Test.OpsPostA",
          "backend" => "Elixir.Scrypath.Meilisearch",
          "index" => "fsv_ops_post_a",
          "document_count" => 1,
          "document_ids" => [1],
          "documents" => [
            %{"id" => 1, "data" => %{"title" => "One"}, "source" => "fields"}
          ]
        }
      }
    ])

    on_exit(fn ->
      Enum.each(previous, fn
        {k, nil} -> Application.delete_env(:scrypath_ops, k)
        {k, v} -> Application.put_env(:scrypath_ops, k, v)
      end)

      if prev_sigra == nil do
        Application.delete_env(:scrypath_ops, :sigra)
      else
        Application.put_env(:scrypath_ops, :sigra, prev_sigra)
      end

      if prev_opsui_auth_mode == nil,
        do: System.delete_env("OPSUI_AUTH_MODE"),
        else: System.put_env("OPSUI_AUTH_MODE", prev_opsui_auth_mode)
    end)

    :ok
  end

  test "renders rollups and reason_class columns", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/ops/failed-sync")

    assert html =~ ~r/total[^\d]*2/s
    assert html =~ "data-testid=\"failed-sync-row\""
    assert html =~ "data-testid=\"failed-sync-retry\""
    assert html =~ "Failed sync jobs"
    assert html =~ "Refresh failed sync jobs"
    assert html =~ "Retry job"
    assert html =~ "Retry re-enqueues the original sync work"

    assert Enum.any?(
             ~w(transport validation backend_rejected queue_exhausted unknown),
             &String.contains?(html, &1)
           )
  end

  test "sigra retry redirects stale sudo and keeps the failed-sync row in place", %{} do
    socket = %Phoenix.LiveView.Socket{
      assigns: %{
        __changed__: %{},
        flash: %{},
        operator_context: %ScrypathOps.Integrations.Sigra.OperatorContext{
          user_id: "user_123",
          active_org_id: "org_456",
          impersonator_user_id: nil,
          sudo_at: DateTime.add(DateTime.utc_now(), -600, :second)
        }
      },
      host_uri: URI.parse("https://scrypath.example/ops/failed-sync")
    }

    {:noreply, socket} =
      ScrypathOpsWeb.FailedSyncLive.handle_event("retry", %{"id" => "501"}, socket)

    assert inspect(socket.redirected) =~ "/sudo/confirm"
    assert inspect(socket.redirected) =~ "return_to=%2Fops%2Ffailed-sync"
  end

  test "sigra retry refreshes the inspection in place without losing local state", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/failed-sync")

    render_click(view, "toggle_compact", %{})

    put_live_assigns(view,
      current_scope: %{user: %{id: "user_123"}, active_organization: %{id: "org_456"}},
      operator_context: %ScrypathOps.Integrations.Sigra.OperatorContext{
        user_id: "user_123",
        active_org_id: "org_456",
        impersonator_user_id: nil,
        sudo_at: DateTime.add(DateTime.utc_now(), -60, :second)
      }
    )

    html = render_click(view, "retry", %{"id" => "501"})

    assert html =~ "Retried 501"

    assigns = :sys.get_state(view.pid).socket.assigns
    assert assigns.selected_schema == OpsPostA
    assert assigns.compact_mode == true
    assert assigns.last_refresh_at != nil
    assert assigns.load_error == nil
    assert assigns.inspection != nil
  end

  test "schema selector rejects non-allowlisted module strings without crashing", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/failed-sync")

    mod_str = "ScrypathOps.Test.NotAllowlisted#{System.unique_integer([:positive])}"
    html = render_change(view, "select_schema", %{"schema" => mod_str})

    assert html =~ "Select an allowlisted schema."

    assigns = :sys.get_state(view.pid).socket.assigns
    assert assigns.selected_schema == OpsPostA
  end

  defp put_live_assigns(view, assigns) do
    :sys.replace_state(view.pid, fn state ->
      socket =
        Enum.reduce(assigns, state.socket, fn {key, value}, socket ->
          Phoenix.Component.assign(socket, key, value)
        end)

      %{state | socket: socket}
    end)
  end
end
