defmodule ScrypathOpsWeb.FailedSyncLiveTest do
  @moduledoc false
  # Phase 47 D-10: see SECURITY + prod guard tests. D-13: `reason_class_counts: true`
  # inspection + rollup counts (`FailedSyncLive` mount).
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScrypathOps.Test.OpsPostA
  alias ScrypathOps.Test.OpsPostB

  defmodule FailedSyncFakeClient do
    def tasks(_filters, config) do
      case Keyword.get(config, :meilisearch_tasks, []) do
        {:error, reason} -> {:error, reason}
        results -> {:ok, %{results: results}}
      end
    end
  end

  defmodule FailedSyncObanInspector do
    def list_jobs(_schema_module, config) do
      {:ok, Keyword.get(config, :oban_jobs, [])}
    end
  end

  defmodule RecordingOban do
    def insert(changeset) do
      Agent.update(:failed_sync_insert_counter, &(&1 + 1))
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
    start_supervised!(%{
      id: :failed_sync_insert_counter,
      start: {Agent, :start_link, [fn -> 0 end, [name: :failed_sync_insert_counter]]}
    })

    keys = ~w(
      schema_allowlist backend sync_mode index_prefix meilisearch_url meilisearch_client
      meilisearch_tasks oban oban_queue oban_inspector oban_jobs
    )a

    previous = Map.new(keys, &{&1, Application.get_env(:scrypath_ops, &1)})
    prev_sigra = Application.get_env(:scrypath_ops, :sigra)
    prev_opsui_auth_mode = System.get_env("OPSUI_AUTH_MODE")

    Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostA, OpsPostB])
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

  test "rendered schema form changes the selected target", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/ops/failed-sync?schema=ScrypathOps.Test.OpsPostA")

    lv
    |> form("#failed-sync-schema-form", %{"schema" => "ScrypathOps.Test.OpsPostB"})
    |> render_change()

    assert_patch(lv, "/ops/failed-sync?schema=ScrypathOps.Test.OpsPostB")
    assert :sys.get_state(lv.pid).socket.assigns.selected_schema == OpsPostB
  end

  test "renders triage summary, rollups, and human reason-class columns", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/ops/failed-sync")

    assert html =~ "2 failed sync jobs need triage"
    assert html =~ "dominant reason"
    assert html =~ "1 retryable job"
    assert html =~ "2 failed sync jobs"
    assert html =~ "data-testid=\"failed-sync-row\""
    assert html =~ "data-testid=\"failed-sync-retry\""
    assert html =~ "Failed sync jobs"
    assert html =~ "Refresh failed sync jobs"
    assert html =~ "Retry sync work"
    assert html =~ "index missing"
    assert html =~ "upsert · oban"
    assert html =~ "Diagnostics"
    row_html = lv |> element("article[data-testid='failed-sync-row']:nth-of-type(2)") |> render()
    retry_pos = row_html |> :binary.match("Retry sync work") |> elem(0)
    diagnostics_pos = row_html |> :binary.match("Diagnostics") |> elem(0)
    assert retry_pos < diagnostics_pos
    # Reason-class rollup tiles (the single, branded representation of by-class counts).
    assert html =~ "transport: 0"
    assert html =~ "validation: 0"
    assert html =~ "unknown: 2"
  end

  test "zero failed sync work shows the empty hero", %{conn: conn} do
    Application.put_env(:scrypath_ops, :meilisearch_tasks, [])
    Application.put_env(:scrypath_ops, :oban_jobs, [])

    {:ok, _lv, html} = live(conn, ~p"/ops/failed-sync")

    assert html =~ ~s(data-testid="failed-sync-empty-hero")
    assert html =~ "No failed sync jobs"
    assert html =~ "Refresh this view"
    refute html =~ "data-testid=\"failed-sync-row\""
  end

  test "one failed job uses singular copy", %{conn: conn} do
    Application.put_env(:scrypath_ops, :meilisearch_tasks, [])

    {:ok, _lv, html} = live(conn, ~p"/ops/failed-sync")

    assert html =~ "1 failed sync job needs triage"
    assert html =~ "1 retryable job"
    refute html =~ "1 failed sync jobs need triage"
  end

  test "empty allowlist shows setup rather than healthy zero work", %{conn: conn} do
    Application.put_env(:scrypath_ops, :schema_allowlist, [])

    {:ok, lv, html} = live(conn, ~p"/ops/failed-sync")

    assert html =~ "No schemas configured"
    refute html =~ "No failed sync work visible"
    refute has_element?(lv, "[data-testid='failed-sync-empty-hero']")
  end

  test "failed observation is not presented as zero work", %{conn: conn} do
    Application.put_env(:scrypath_ops, :meilisearch_tasks, {:error, :backend_unavailable})

    {:ok, lv, html} = live(conn, ~p"/ops/failed-sync")

    assert html =~ "Failed sync work could not load"
    assert html =~ ":backend_unavailable"
    refute has_element?(lv, "[data-testid='failed-sync-empty-hero']")
  end

  test "rendered handoff keeps a non-first schema in the query string", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/ops/failed-sync?schema=ScrypathOps.Test.OpsPostB")

    assert html =~ "OpsPostB"
    assert has_element?(lv, "a[href='/ops/sync-drift?schema=ScrypathOps.Test.OpsPostB']")
    assert :sys.get_state(lv.pid).socket.assigns.selected_schema == OpsPostB
  end

  test "explicit invalid or removed selections show unavailable and refuse retry", %{conn: conn} do
    {:ok, invalid_view, invalid_html} =
      live(conn, ~p"/ops/failed-sync?schema=ScrypathOps.Test.Gone")

    assert invalid_html =~ "That schema is unavailable"
    refute has_element?(invalid_view, "[data-testid='failed-sync-row']")

    {:ok, removed_view, _html} = live(conn, ~p"/ops/failed-sync")
    Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostB])
    retry_html = render_click(removed_view, "retry", %{"id" => "501"})
    assert retry_html =~ "That schema is unavailable"
    refute retry_html =~ "Retried 501"
    assert :sys.get_state(removed_view.pid).socket.assigns.selected_schema == nil
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
        },
        schema_allowlist: [OpsPostA, OpsPostB],
        selected_schema: OpsPostA,
        mount_path: "/ops",
        context_generation: 0,
        selection_error: nil
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

    assert html =~ "Retry accepted"
    assert html =~ "Queue job 991"
    assert html =~ "Original failure #501 retained"
    refute html =~ "Recovery verified"

    assigns = :sys.get_state(view.pid).socket.assigns
    assert assigns.selected_schema == OpsPostA
    assert assigns.compact_mode == true
    assert assigns.last_refresh_at != nil
    assert assigns.load_error == nil
    assert assigns.inspection != nil
    assert assigns.recovery_receipts["501"].replacement_job == 991
    assert Agent.get(:failed_sync_insert_counter, & &1) == 1

    repeated = render_click(view, "retry", %{"id" => "501"})
    assert repeated =~ "A retry for job 501 is already accepted"
    assert Agent.get(:failed_sync_insert_counter, & &1) == 1
  end

  test "delete retry requires confirmation and Cancel keeps the failed row", %{conn: conn} do
    Application.put_env(:scrypath_ops, :oban_jobs, [
      %{
        id: 502,
        state: "discarded",
        worker: "Scrypath.Oban.DeleteWorker",
        queue: "search_sync",
        args: %{
          "operation" => "delete",
          "schema" => "Elixir.ScrypathOps.Test.OpsPostA",
          "backend" => "Elixir.Scrypath.Meilisearch",
          "index" => "fsv_ops_post_a",
          "document_count" => 2,
          "document_ids" => ["doc-1", "doc-2"]
        }
      }
    ])

    {:ok, view, _html} = live(conn, ~p"/ops/failed-sync")
    html = render_click(view, "retry", %{"id" => "502"})

    assert html =~ "Confirm delete sync work"
    assert html =~ "fsv_ops_post_a"
    assert html =~ "doc-1"
    assert html =~ "doc-2"
    assert html =~ "Cancel"

    html = render_click(view, "cancel_retry_delete", %{})
    refute html =~ "Confirm delete sync work"
    assert html =~ "Failed job 502"
    refute html =~ "Retry accepted"
  end

  test "schema selector rejects non-allowlisted module strings without crashing", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/failed-sync")

    mod_str = "ScrypathOps.Test.NotAllowlisted#{System.unique_integer([:positive])}"
    html = render_change(view, "select_schema", %{"schema" => mod_str})

    assert html =~ "That schema is unavailable"

    assigns = :sys.get_state(view.pid).socket.assigns
    assert assigns.selected_schema == nil
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
