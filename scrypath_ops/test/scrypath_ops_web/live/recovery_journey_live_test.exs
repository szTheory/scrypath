defmodule ScrypathOpsWeb.RecoveryJourneyLiveTest do
  @moduledoc false
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScrypathOps.Test.OpsPostA
  alias ScrypathOps.Test.OpsPostB

  defmodule JourneyClient do
    def task(701, _config) do
      {:ok,
       %{
         "uid" => 701,
         "status" => "processing",
         "type" => "documentAdditionOrUpdate",
         "indexUid" => "journey_ops_post_a"
       }}
    end

    def tasks(filters, config) do
      uids = filters[:index_uids] || []
      tasks = Keyword.get(config, :meilisearch_tasks, [])
      {:ok, %{results: Enum.filter(tasks, &(&1["indexUid"] in uids))}}
    end
  end

  defmodule JourneyQueueInspector do
    def list_jobs(_schema, config), do: {:ok, Keyword.get(config, :oban_jobs, [])}
  end

  defmodule RecordingOban do
    def config do
      %{repo: ScrypathOpsWeb.RecoveryJourneyLiveTest.JourneyRepo, prefix: "public"}
    end

    def insert(changeset) do
      job = Ecto.Changeset.apply_changes(changeset)
      {:ok, %{job | id: 991, state: "available"}}
    end
  end

  defmodule JourneyRepo do
    def get(Oban.Job, 991, prefix: "public") do
      struct(Oban.Job,
        id: 991,
        attempt: 1,
        state: "completed",
        worker: "Scrypath.Oban.UpsertWorker",
        args: %{
          "schema" => "Elixir.ScrypathOps.Test.OpsPostA",
          "index" => "journey_ops_post_a",
          "backend" => "Elixir.Scrypath.Meilisearch",
          "meilisearch_url" => "http://localhost:7700"
        }
      )
    end
  end

  setup do
    keys = ~w(
      schema_allowlist backend sync_mode index_prefix meilisearch_url meilisearch_client
      meilisearch_tasks oban oban_queue oban_inspector oban_jobs sigra
    )a
    previous = Map.new(keys, &{&1, Application.get_env(:scrypath_ops, &1)})
    previous_auth_mode = System.get_env("OPSUI_AUTH_MODE")

    Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostA, OpsPostB])
    Application.put_env(:scrypath_ops, :backend, Scrypath.Meilisearch)
    Application.put_env(:scrypath_ops, :sync_mode, :oban)
    Application.put_env(:scrypath_ops, :index_prefix, "journey")
    Application.put_env(:scrypath_ops, :meilisearch_url, "http://localhost:7700")
    Application.put_env(:scrypath_ops, :meilisearch_client, JourneyClient)

    Application.put_env(:scrypath_ops, :meilisearch_tasks, [
      %{
        "uid" => 401,
        "status" => "failed",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "journey_ops_post_b",
        "error" => %{"message" => "B has a visible backend failure"}
      }
    ])

    Application.put_env(:scrypath_ops, :oban, RecordingOban)
    Application.put_env(:scrypath_ops, :oban_queue, :search_sync)
    Application.put_env(:scrypath_ops, :oban_inspector, JourneyQueueInspector)

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
          "index" => "journey_ops_post_a",
          "document_count" => 1,
          "document_ids" => [1],
          "documents" => [%{"id" => 1, "data" => %{"title" => "One"}, "source" => "fields"}]
        }
      }
    ])

    Application.put_env(:scrypath_ops, :sigra,
      sudo_confirm_path: "/sudo/confirm",
      sudo_window: 300
    )

    System.put_env("OPSUI_AUTH_MODE", "sigra")

    on_exit(fn ->
      Enum.each(previous, fn
        {key, nil} -> Application.delete_env(:scrypath_ops, key)
        {key, value} -> Application.put_env(:scrypath_ops, key, value)
      end)

      if previous_auth_mode,
        do: System.put_env("OPSUI_AUTH_MODE", previous_auth_mode),
        else: System.delete_env("OPSUI_AUTH_MODE")
    end)

    :ok
  end

  test "selected A stays the recovery target while worse B is listed first", %{conn: conn} do
    schema_a = "ScrypathOps.Test.OpsPostA"
    schema_b = "ScrypathOps.Test.OpsPostB"

    {:ok, room, _html} = live(conn, "/ops?schema=#{schema_a}")
    assert has_element?(room, "[data-testid='recovery-target']", schema_a)

    health_href =
      room
      |> element("a[data-testid='control-room-health-link']")
      |> render()
      |> href_from_anchor()

    assert health_href == "/ops/health?schema=#{schema_a}"

    {:ok, health, health_html} = live(conn, health_href)
    assert health_html =~ "#{schema_a}"
    assert health_html =~ "Recovery target"
    assert :sys.get_state(health.pid).socket.assigns.selected_schema == OpsPostA

    assert has_element?(
             health,
             "[data-testid='posture-row'][id='posture-ScrypathOps.Test.OpsPostB']"
           )

    assert health_html =~ "#{schema_b}"

    assert has_element?(
             health,
             ".ops-schema-signal-list > article:nth-of-type(1)[id='posture-ScrypathOps.Test.OpsPostB']"
           )

    failed_href =
      health
      |> element(
        "a[data-testid='posture-failed-sync-link'][aria-label='View failed sync work for #{schema_a}']"
      )
      |> render()
      |> href_from_anchor()

    assert failed_href == "/ops/failed-sync?schema=#{schema_a}"
    {:ok, failed, _html} = live(conn, failed_href)
    assert :sys.get_state(failed.pid).socket.assigns.selected_schema == OpsPostA
    assert has_element?(failed, "[data-testid='failed-sync-row']", "Queue job 501")

    put_live_assigns(failed,
      current_scope: %{user: %{id: "user_123"}, active_organization: %{id: "org_456"}},
      operator_context: %ScrypathOps.Integrations.Sigra.OperatorContext{
        user_id: "user_123",
        active_org_id: "org_456",
        impersonator_user_id: nil,
        sudo_at: DateTime.add(DateTime.utc_now(), -60, :second)
      }
    )

    failed |> element("[data-testid='failed-sync-retry']") |> render_click()
    receipt = element(failed, "[data-testid='recovery-receipt']")

    assert render(receipt) =~
             "Replacement accepted — queue job 991. Terminal completion has not been observed."

    assert render(receipt) =~ "Original Queue job 501 failure retained"
    refute render(receipt) =~ "Recovery verified"

    handoff_href =
      failed
      |> element("[data-testid='recovery-receipt'] a", "Check sync status")
      |> render()
      |> href_from_anchor()
      |> String.replace("&amp;", "&")

    handoff = URI.parse(handoff_href)
    assert handoff.path == "/ops/sync-drift"
    assert URI.decode_query(handoff.query)["schema"] == schema_a

    queue_key = expected_work_key("ScrypathOps.Test.OpsPostA", "oban", "501")

    assert :sys.get_state(failed.pid).socket.assigns.recovery_receipts[queue_key].state ==
             :accepted


  end

  test "retry identifies the queue row when a backend task has the same numeric id", %{
    conn: conn
  } do
    Application.put_env(:scrypath_ops, :meilisearch_tasks, [
      %{
        "uid" => 501,
        "status" => "failed",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "journey_ops_post_a",
        "error" => %{"message" => "Backend task shares the queue job id"}
      }
    ])

    {:ok, failed, _html} = live(conn, "/ops/failed-sync?schema=ScrypathOps.Test.OpsPostA")

    assert has_element?(failed, "[data-testid='failed-sync-row']", "Backend task 501")
    assert has_element?(failed, "[data-testid='failed-sync-row']", "Queue job 501")

    put_live_assigns(failed,
      current_scope: %{user: %{id: "user_123"}, active_organization: %{id: "org_456"}},
      operator_context: %ScrypathOps.Integrations.Sigra.OperatorContext{
        user_id: "user_123",
        active_org_id: "org_456",
        impersonator_user_id: nil,
        sudo_at: DateTime.add(DateTime.utc_now(), -60, :second)
      }
    )

    queue_key = expected_work_key("ScrypathOps.Test.OpsPostA", "oban", "501")

    failed
    |> element("button[data-testid='failed-sync-retry'][phx-value-id='#{queue_key}']")
    |> render_click()

    assert render(element(failed, "[data-testid='recovery-receipt']")) =~
             "Replacement accepted — queue job 991. Terminal completion has not been observed."

    assert :sys.get_state(failed.pid).socket.assigns.recovery_receipts[queue_key].state ==
             :accepted

    # The accepted receipt and real telemetry collector must preserve source identity
    # through the rendered status handoff, not only on the retry button.
    collector = ScrypathOps.RecoveryObservation

    collector.handle_event(
      [:oban, :job, :start],
      %{},
      %{
        job: JourneyRepo.get(Oban.Job, 991, prefix: "public"),
        conf: Map.merge(RecordingOban.config(), %{name: RecordingOban})
      },
      %{server: collector}
    )

    collector.handle_event(
      [:scrypath, :meilisearch, :task_wait, :stop],
      %{},
      %{task_uid: 701, final_status: :processing},
      %{server: collector}
    )

    href =
      failed
      |> element("[data-testid='recovery-receipt'] a", "Check sync status")
      |> render()
      |> href_from_anchor()
      |> String.replace("&amp;", "&")

    {:ok, drift, _html} = live(conn, href)
    render_async(drift)

    put_live_assigns(drift,
      current_scope: %{user: %{id: "user_123"}, active_organization: %{id: "org_456"}},
      operator_context: %ScrypathOps.Integrations.Sigra.OperatorContext{
        user_id: "user_123",
        active_org_id: "org_456",
        impersonator_user_id: nil,
        sudo_at: DateTime.add(DateTime.utc_now(), -60, :second)
      }
    )

    render_click(drift, "refresh_recovery_status", %{})
    html = render_async(drift)
    assert html =~ "Retry running"
    assert :sys.get_state(drift.pid).socket.assigns.recovery_status == :running
  end

  test "explicit unavailable and empty schema selections never become a recovery target", %{
    conn: conn
  } do
    {:ok, default_room, default_room_html} = live(conn, "/ops")
    assert default_room_html =~ "Recovery target"

    assert has_element?(
             default_room,
             "[data-testid='recovery-target']",
             "ScrypathOps.Test.OpsPostA"
           )

    for path <- [
          "/ops?schema=",
          "/ops?schema=Elixir.NotAllowed",
          "/ops?schema=%3Cscript%3Ealert(1)%3C/script%3E",
          "/ops/health?schema=Elixir.NotAllowed",
          "/ops/failed-sync?schema=Elixir.NotAllowed"
        ] do
      {:ok, view, html} = live(conn, path)
      assert html =~ "That schema is unavailable"
      refute has_element?(view, "a[data-testid='control-room-health-link']")
      refute has_element?(view, "a[data-testid='posture-failed-sync-link']")
      refute has_element?(view, "[data-testid='failed-sync-retry']")
    end

    Application.put_env(:scrypath_ops, :schema_allowlist, [])
    {:ok, setup_view, setup_html} = live(conn, "/ops?schema=ScrypathOps.Test.OpsPostA")
    assert setup_html =~ "No schemas configured"
    refute has_element?(setup_view, "[data-testid='recovery-target']")
  end

  test "selection changes invalidate receipts, confirmations, and inspected evidence", %{
    conn: conn
  } do
    {:ok, failed, _html} = live(conn, "/ops/failed-sync?schema=ScrypathOps.Test.OpsPostA")
    before = :sys.get_state(failed.pid).socket.assigns

    put_live_assigns(failed,
      delete_confirmation: "ScrypathOps.Test.OpsPostA:oban:501",
      recovery_receipts: %{
        expected_work_key("ScrypathOps.Test.OpsPostA", "oban", "501") => %{
          handle: "old-handle",
          generation: before.context_generation,
          state: :accepted
        }
      }
    )

    render_patch(failed, "/ops/failed-sync?schema=ScrypathOps.Test.OpsPostB")
    after_selection = :sys.get_state(failed.pid).socket.assigns

    assert after_selection.selected_schema == OpsPostB
    assert after_selection.context_generation == before.context_generation + 1
    assert after_selection.delete_confirmation == nil
    assert after_selection.recovery_receipts == %{}
    refute has_element?(failed, "[data-testid='recovery-receipt']")

    stale_html =
      render_click(failed, "retry", %{
        "id" => expected_work_key("ScrypathOps.Test.OpsPostA", "oban", "501"),
        "generation" => to_string(before.context_generation)
      })

    assert stale_html =~ "earlier inspection"
    assert :sys.get_state(failed.pid).socket.assigns.recovery_receipts == %{}
    assert :sys.get_state(failed.pid).socket.assigns.selected_schema == OpsPostB

    Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostA])
    removed_html = render_patch(failed, "/ops/failed-sync?schema=ScrypathOps.Test.OpsPostB")
    assert removed_html =~ "That schema is unavailable"
    assert :sys.get_state(failed.pid).socket.assigns.selected_schema == nil
  end

  defp href_from_anchor(html) do
    [_, href] = Regex.run(~r/href="([^"]+)"/, html)
    href
  end

  defp expected_work_key(schema, source, id) do
    [schema, source, id]
    |> Enum.map(fn value -> <<byte_size(value)::unsigned-big-32, value::binary>> end)
    |> IO.iodata_to_binary()
    |> Base.url_encode64(padding: false)
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
