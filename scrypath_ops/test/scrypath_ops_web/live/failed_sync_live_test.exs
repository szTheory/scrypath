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
    assert html =~ "1 Queue job has manual replay data"
    assert html =~ "2 failed sync jobs"
    assert html =~ "data-testid=\"failed-sync-row\""
    assert html =~ "data-testid=\"failed-sync-retry\""
    assert html =~ "Failed sync jobs"
    assert html =~ "Refresh failed sync work"
    assert html =~ "Retry queue job"
    assert html =~ "index missing"
    assert html =~ "upsert"
    assert html =~ "search_sync"
    assert html =~ "Diagnostics"
    row_html = lv |> element("article[data-testid='failed-sync-row']:nth-of-type(2)") |> render()
    retry_pos = row_html |> :binary.match("Retry queue job") |> elem(0)
    diagnostics_pos = row_html |> :binary.match("Diagnostics") |> elem(0)
    assert retry_pos < diagnostics_pos
    # Reason-class rollup tiles (the single, branded representation of by-class counts).
    assert html =~ "transport: 0"
    assert html =~ "validation: 0"
    assert html =~ "unknown: 2"
  end

  test "every source-qualified work row uses an opaque stable DOM and action key", %{conn: conn} do
    Application.put_env(:scrypath_ops, :meilisearch_tasks, [
      %{
        "uid" => 501,
        "status" => "failed",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "fsv_ops_post_a",
        "error" => %{"message" => "index missing"}
      }
    ])

    {:ok, view, html} = live(conn, ~p"/ops/failed-sync?schema=ScrypathOps.Test.OpsPostA")

    backend_key = expected_work_key("ScrypathOps.Test.OpsPostA", "meilisearch", "501")
    queue_key = expected_work_key("ScrypathOps.Test.OpsPostA", "oban", "501")

    refute backend_key == queue_key
    assert html =~ ~s(id="failed-detail-#{backend_key}")
    assert html =~ ~s(id="failed-detail-#{queue_key}")

    assert view |> element("[data-testid='failed-sync-retry']") |> render() =~
             ~s(phx-value-id="#{queue_key}")
  end

  test "diagnosis and current recovery availability precede collapsed diagnostics", %{conn: conn} do
    Application.put_env(:scrypath_ops, :meilisearch_tasks, [
      %{
        "uid" => 501,
        "status" => "failed",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "fsv_ops_post_a",
        "error" => %{"message" => "index missing"}
      }
    ])

    {:ok, view, html} = live(conn, ~p"/ops/failed-sync?schema=ScrypathOps.Test.OpsPostA")

    backend_row = rendered_row(html, "Backend task 501")

    assert backend_row =~ "Backend task 501"
    assert backend_row =~ "ScrypathOps.Test.OpsPostA"
    assert backend_row =~ "upsert"
    assert backend_row =~ "fsv_ops_post_a"
    assert backend_row =~ "index missing"
    assert backend_row =~ "Backend tasks have no supported in-page replay action"
    refute backend_row =~ "data-testid=\"failed-sync-retry\""

    identity_pos = backend_row |> :binary.match("Backend task 501") |> elem(0)
    schema_pos = backend_row |> :binary.match("ScrypathOps.Test.OpsPostA") |> elem(0)
    operation_pos = backend_row |> :binary.match("upsert") |> elem(0)
    index_pos = backend_row |> :binary.match("fsv_ops_post_a") |> elem(0)
    reason_pos = backend_row |> :binary.match("index missing") |> elem(0)

    availability_pos =
      backend_row
      |> :binary.match("Backend tasks have no supported in-page replay action")
      |> elem(0)

    diagnostics_pos = backend_row |> :binary.match("Diagnostics") |> elem(0)

    assert identity_pos < schema_pos
    assert schema_pos < operation_pos
    assert operation_pos < index_pos
    assert index_pos < reason_pos
    assert reason_pos < availability_pos
    assert availability_pos < diagnostics_pos

    queue_row = rendered_row(html, "Queue job 501")

    assert queue_row =~ "Manual retry data is present; current server and host gates still apply."
    retry = view |> element("[data-testid='failed-sync-retry']") |> render()
    assert retry =~ "Retry queue job"
    assert retry =~ "ops-btn"
    refute retry =~ "btn-xs"
  end

  test "a backend task token cannot retry or receive the same-ID queue receipt", %{conn: conn} do
    Application.put_env(:scrypath_ops, :meilisearch_tasks, [
      %{
        "uid" => 501,
        "status" => "failed",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "fsv_ops_post_a",
        "error" => %{"message" => "index missing"}
      }
    ])

    {:ok, view, _html} = live(conn, ~p"/ops/failed-sync?schema=ScrypathOps.Test.OpsPostA")
    backend_key = expected_work_key("ScrypathOps.Test.OpsPostA", "meilisearch", "501")

    html = render_click(view, "retry", %{"id" => backend_key})

    assert Agent.get(:failed_sync_insert_counter, & &1) == 0
    assert html =~ "Backend task 501"
    assert html =~ "Queue job 501"
    refute html =~ "data-testid=\"recovery-receipt\""
    assert map_size(:sys.get_state(view.pid).socket.assigns.recovery_receipts) == 0
  end

  test "a bare numeric ID is not an actionable work identity", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/failed-sync?schema=ScrypathOps.Test.OpsPostA")

    html = render_click(view, "retry", %{"id" => "501"})

    assert Agent.get(:failed_sync_insert_counter, & &1) == 0
    assert :sys.get_state(view.pid).socket.assigns.recovery_receipts == %{}
    assert html =~ "Could not find that failed sync work row"
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
    assert html =~ "1 Queue job has manual replay data"
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
    stale_queue_key = expected_work_key("ScrypathOps.Test.OpsPostA", "oban", "501")
    Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostB])
    retry_html = render_click(removed_view, "retry", %{"id" => stale_queue_key})
    assert retry_html =~ "That schema is unavailable"
    refute retry_html =~ "Retried 501"
    assert :sys.get_state(removed_view.pid).socket.assigns.selected_schema == nil
  end

  test "sigra retry redirects stale sudo and keeps the failed-sync row in place", %{} do
    {:ok, inspection} =
      Scrypath.failed_sync_work(
        OpsPostA,
        Keyword.put(ScrypathOps.Schemas.scrypath_opts(), :reason_class_counts, true)
      )

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
        inspection: inspection,
        mount_path: "/ops",
        context_generation: 0,
        selection_error: nil
      },
      host_uri:
        URI.parse(
          "https://scrypath.example/ops/failed-sync?evil=1&schema=ScrypathOps.Test.OpsPostB"
        )
    }

    {:noreply, socket} =
      ScrypathOpsWeb.FailedSyncLive.handle_event(
        "retry",
        %{"id" => expected_work_key("ScrypathOps.Test.OpsPostA", "oban", "501")},
        socket
      )

    assert inspect(socket.redirected) =~ "/sudo/confirm"

    assert inspect(socket.redirected) =~
             "return_to=%2Fops%2Ffailed-sync%3Fschema%3DScrypathOps.Test.OpsPostA"

    refute inspect(socket.redirected) =~ "evil"
    assert Agent.get(:failed_sync_insert_counter, & &1) == 0
  end

  test "sigra retry refreshes the inspection in place without losing local state", %{conn: conn} do
    Application.put_env(:scrypath_ops, :meilisearch_tasks, [
      %{
        "uid" => 501,
        "status" => "failed",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "fsv_ops_post_a",
        "error" => %{"message" => "index missing"}
      }
    ])

    {:ok, view, _html} = live(conn, ~p"/ops/failed-sync")

    put_live_assigns(view,
      current_scope: %{user: %{id: "user_123"}, active_organization: %{id: "org_456"}},
      operator_context: %ScrypathOps.Integrations.Sigra.OperatorContext{
        user_id: "user_123",
        active_org_id: "org_456",
        impersonator_user_id: nil,
        sudo_at: DateTime.add(DateTime.utc_now(), -60, :second)
      }
    )

    queue_key = expected_work_key("ScrypathOps.Test.OpsPostA", "oban", "501")
    html = render_click(view, "retry", %{"id" => queue_key})

    assert html =~
             "Replacement accepted — queue job 991. Terminal completion has not been observed."

    assert html =~ "Original Queue job 501 failure retained"
    refute html =~ "Recovery verified"

    backend_row = rendered_row(html, "Backend task 501")
    queue_row = rendered_row(html, "Queue job 501")

    assert backend_row =~ "Backend task 501"
    refute backend_row =~ "data-testid=\"recovery-receipt\""
    assert queue_row =~ "Queue job 501"

    assert queue_row =~
             "Replacement accepted — queue job 991. Terminal completion has not been observed."

    assigns = :sys.get_state(view.pid).socket.assigns
    queue_key = expected_work_key("ScrypathOps.Test.OpsPostA", "oban", "501")
    assert assigns.selected_schema == OpsPostA
    assert assigns.last_refresh_at != nil
    assert assigns.load_error == nil
    assert assigns.inspection != nil
    assert assigns.recovery_receipts[queue_key].replacement_job == 991
    assert Agent.get(:failed_sync_insert_counter, & &1) == 1

    repeated = render_click(view, "retry", %{"id" => queue_key})
    assert repeated =~ "A retry for Queue job 501 is already accepted"
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
    queue_key = expected_work_key("ScrypathOps.Test.OpsPostA", "oban", "502")
    html = render_click(view, "retry", %{"id" => queue_key})

    assert html =~ "Confirm delete sync work"
    assert html =~ "ScrypathOps.Test.OpsPostA"
    assert html =~ "fsv_ops_post_a"
    assert html =~ "2 documents"
    assert html =~ "doc-1"
    assert html =~ "doc-2"
    assert html =~ "Cancel"

    html = render_click(view, "cancel_retry_delete", %{})
    refute html =~ "Confirm delete sync work"
    assert html =~ "Queue job 502"
    refute html =~ "Replacement accepted"
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

  defp expected_work_key(schema, source, id) do
    [schema, source, id]
    |> Enum.map(fn value -> <<byte_size(value)::unsigned-big-32, value::binary>> end)
    |> IO.iodata_to_binary()
    |> Base.url_encode64(padding: false)
  end

  defp rendered_row(html, marker) do
    html
    |> then(&Regex.scan(~r/<article[^>]*data-testid="failed-sync-row"[^>]*>.*?<\/article>/s, &1))
    |> List.flatten()
    |> Enum.find(&String.contains?(&1, marker))
  end
end
