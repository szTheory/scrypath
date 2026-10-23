defmodule ScrypathOpsWeb.FailedSyncLiveTest do
  @moduledoc false
  # Phase 47 D-10: see SECURITY + prod guard tests. D-13: `reason_class_counts: true`
  # inspection + rollup counts (`FailedSyncLive` mount).
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScrypathOps.Test.OpsPostA
  alias ScrypathOps.Test.OpsPostB

  defmodule FailedSyncFakeClient do
    # Scoped like Meilisearch: only tasks for the requested index come back.
    def tasks(filters, config) do
      uids = Keyword.get(filters, :index_uids, [])
      failing = Application.get_env(:scrypath_ops, :failing_index_uids, [])

      cond do
        Enum.any?(uids, &(&1 in failing)) ->
          {:error, :backend_unavailable}

        true ->
          case Keyword.get(config, :meilisearch_tasks, []) do
            {:error, reason} ->
              {:error, reason}

            results ->
              {:ok, %{results: Enum.filter(results, &(Map.get(&1, "indexUid") in uids))}}
          end
      end
    end
  end

  defmodule FailedSyncObanInspector do
    # Scoped like the real inspector: only jobs whose args name this schema.
    def list_jobs(schema_module, config) do
      schema = Atom.to_string(schema_module)

      jobs =
        config
        |> Keyword.get(:oban_jobs, [])
        |> Enum.filter(fn job ->
          Map.get(job.args, "schema", "Elixir.ScrypathOps.Test.OpsPostA") == schema
        end)

      {:ok, jobs}
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
      meilisearch_tasks oban oban_queue oban_inspector oban_jobs failing_index_uids
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
          "repo" => "Elixir.ScrypathOps.Repo",
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

  defp upsert_job(id, schema, opts \\ []) do
    short = schema |> Module.split() |> List.last() |> Macro.underscore()

    %{
      id: id,
      state: Keyword.get(opts, :state, "retryable"),
      worker: "Scrypath.Oban.UpsertWorker",
      queue: "search_sync",
      attempted_at: Keyword.get(opts, :attempted_at, "2026-10-10T14:15:00Z"),
      attempt: Keyword.get(opts, :attempt),
      max_attempts: Keyword.get(opts, :max_attempts),
      errors: List.wrap(Keyword.get(opts, :error)) |> Enum.map(&%{"error" => &1}),
      args: %{
        "operation" => "upsert",
        "repo" => "Elixir.ScrypathOps.Repo",
        "schema" => Atom.to_string(schema),
        "backend" => "Elixir.Scrypath.Meilisearch",
        "index" => "fsv_#{short}",
        "document_count" => length(Keyword.get(opts, :ids, [1])),
        "document_ids" => Keyword.get(opts, :ids, [1])
      }
    }
  end

  defp sudo!(view) do
    put_live_assigns(view,
      current_scope: %{user: %{id: "user_123"}, active_organization: %{id: "org_456"}},
      operator_context: %ScrypathOps.Integrations.Sigra.OperatorContext{
        user_id: "user_123",
        active_org_id: "org_456",
        impersonator_user_id: nil,
        sudo_at: DateTime.add(DateTime.utc_now(), -60, :second)
      }
    )
  end

  test "all schemas load by default with a schema label on every row", %{conn: conn} do
    Application.put_env(:scrypath_ops, :oban_jobs, [
      upsert_job(501, OpsPostA, error: "** (Ecto.CastError) cannot cast"),
      upsert_job(509, OpsPostB, state: "discarded", error: "the Variant source remains visible")
    ])

    {:ok, view, html} = live(conn, ~p"/ops/failed-sync")

    assert html =~ "2 failed, 1 retrying"
    assert has_element?(view, "[data-testid='failed-sync-row']", "OpsPostA")
    assert has_element?(view, "[data-testid='failed-sync-row']", "OpsPostB")
    assert has_element?(view, "[data-testid='failed-sync-row']", "Oban search_sync #509")
    assert has_element?(view, "[data-testid='failed-sync-row']", "Meilisearch task #401")
    assert html =~ "Retry queues the same records again and sends their current data."
    assert html =~ ~s(aria-labelledby="failed-sync-summary-heading")
    assert html =~ ~s(id="failed-sync-summary-heading")
    refute html =~ "Error categories"
    refute has_element?(view, "input[type='radio'][name='schema']")

    # Schema facets carry per-schema counts; nothing is preselected.
    assert has_element?(view, "[data-testid='failed-sync-schema-filter']", "OpsPostA")

    assert has_element?(
             view,
             "[data-testid='failed-sync-schema-filter'] .sr-only",
             "1 failed, 1 retrying"
           )

    refute has_element?(view, "input[name='schema[]']:checked")
    assert has_element?(view, "a[href='/ops/sync-and-index']")
  end

  test "zero-count schemas stay visible but quiet", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/failed-sync")

    assert has_element?(
             view,
             "label.ops-filter-chip--quiet[data-testid='failed-sync-schema-filter']",
             "OpsPostB"
           )

    refute has_element?(view, "label.ops-filter-chip--quiet", "OpsPostA")
  end

  test "schema deep link preselects the filter and scopes rows, counts and handoff", %{
    conn: conn
  } do
    Application.put_env(:scrypath_ops, :oban_jobs, [
      upsert_job(501, OpsPostA),
      upsert_job(509, OpsPostB, error: "the Variant source remains visible")
    ])

    {:ok, view, html} = live(conn, ~p"/ops/failed-sync?schema=ScrypathOps.Test.OpsPostB")

    assert html =~ "1 retrying"
    assert summary(view) =~ "1 retrying"
    refute summary(view) =~ " failed"
    assert has_element?(view, "input[name='schema[]'][value='ScrypathOps.Test.OpsPostB']:checked")
    refute has_element?(view, "input[name='schema[]'][value='ScrypathOps.Test.OpsPostA']:checked")
    assert has_element?(view, "[data-testid='failed-sync-row']", "#509")
    refute has_element?(view, "[data-testid='failed-sync-row']", "#501")

    assert has_element?(
             view,
             "[data-testid='failed-sync-filter-note']",
             ~r/\d+ more hidden by filters\./
           )

    assert has_element?(view, "[data-testid='failed-sync-filter-note'] a", "Clear filters")
    assert has_element?(view, "a[href='/ops/sync-and-index?schema=ScrypathOps.Test.OpsPostB']")
  end

  test "repeated and comma-separated schema params select several schemas", %{conn: conn} do
    for path <- [
          "/ops/failed-sync?schema=ScrypathOps.Test.OpsPostA&schema=ScrypathOps.Test.OpsPostB",
          "/ops/failed-sync?schema=ScrypathOps.Test.OpsPostA,ScrypathOps.Test.OpsPostB"
        ] do
      {:ok, view, _html} = live(conn, path)

      assert has_element?(
               view,
               "input[name='schema[]'][value='ScrypathOps.Test.OpsPostA']:checked"
             )

      assert has_element?(
               view,
               "input[name='schema[]'][value='ScrypathOps.Test.OpsPostB']:checked"
             )

      assert :sys.get_state(view.pid).socket.assigns.schema_filter == [OpsPostA, OpsPostB]
    end
  end

  test "changing the filters patches the URL without reloading every schema", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/failed-sync")
    loaded_at = :sys.get_state(view.pid).socket.assigns.last_refresh_at

    view
    |> form("#failed-sync-filters", %{"schema" => ["ScrypathOps.Test.OpsPostB"]})
    |> render_change()

    assert_patch(view, "/ops/failed-sync?schema=ScrypathOps.Test.OpsPostB")
    assigns = :sys.get_state(view.pid).socket.assigns
    assert assigns.schema_filter == [OpsPostB]
    assert assigns.last_refresh_at == loaded_at

    html = render_change(view, "filter", %{"cause" => ["unknown"]})
    assert_patch(view, "/ops/failed-sync?cause=unknown")
    assert html =~ "1 failed, 1 retrying"

    render_change(view, "filter", %{"schema" => ["ScrypathOps.Test.Nope"], "cause" => ["bogus"]})
    assert_patch(view, "/ops/failed-sync")
  end

  test "cause filters use readable labels ordered by count and narrow the summary", %{
    conn: conn
  } do
    Application.put_env(:scrypath_ops, :meilisearch_tasks, [])

    Application.put_env(:scrypath_ops, :oban_jobs, [
      upsert_job(601, OpsPostA, state: "discarded", error: "** (Ecto.CastError) bad"),
      upsert_job(602, OpsPostA, state: "discarded", error: "** (ArgumentError) bad"),
      upsert_job(603, OpsPostB, error: "** (Req.TransportError) connection refused"),
      upsert_job(604, OpsPostB, state: "discarded")
    ])

    {:ok, view, html} = live(conn, ~p"/ops/failed-sync")

    assert html =~ "3 failed, 1 retrying"

    labels =
      view
      |> render()
      |> LazyHTML.from_fragment()
      |> LazyHTML.query("[data-testid='failed-sync-cause-filter']")
      |> Enum.map(&LazyHTML.text/1)
      |> Enum.map(&String.replace(&1, ~r/\s+/, " "))
      |> Enum.map(&String.trim/1)

    assert labels == ["Invalid data 2", "Couldn't reach Meilisearch 1", "Retries used up 1"]
    refute html =~ "queue exhausted"
    refute html =~ "backend rejected"

    {:ok, view, html} = live(conn, ~p"/ops/failed-sync?cause=transport")
    assert html =~ "1 retrying"
    assert has_element?(view, "input[name='cause[]'][value='transport']:checked")
    assert has_element?(view, "[data-testid='failed-sync-row']", "#603")
    refute has_element?(view, "[data-testid='failed-sync-row']", "#601")
    assert html =~ "Couldn&#39;t reach Meilisearch. This will retry automatically."

    {:ok, view, html} = live(conn, ~p"/ops/failed-sync?cause=validation")
    assert summary(view) =~ "2 failed"
    refute summary(view) =~ " retrying"
    assert html =~ "Invalid data: fix the record, then retry."
    assert html =~ "Review the errors and fix their causes, then retry."
  end

  test "filters that match nothing say so and offer to clear them", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/ops/failed-sync?schema=ScrypathOps.Test.OpsPostB")

    assert html =~ "No sync work matches these filters"
    assert has_element?(view, "a[href='/ops/failed-sync']", "Clear filters")
    refute has_element?(view, "[data-testid='failed-sync-row']")
  end

  test "one schema's load error is attributed to it without hiding the others", %{conn: conn} do
    Application.put_env(:scrypath_ops, :failing_index_uids, ["fsv_ops_post_b"])

    {:ok, view, html} = live(conn, ~p"/ops/failed-sync")

    assert has_element?(view, "[data-testid='failed-sync-load-error']", "OpsPostB")
    refute has_element?(view, "[data-testid='failed-sync-load-error']", "OpsPostA couldn")
    assert html =~ ":backend_unavailable"
    assert html =~ ~s(aria-label="Copy error")
    assert html =~ ~s(data-ops-copy-success="Error copied")
    assert html =~ "1 failed, 1 retrying"
    assert has_element?(view, "[data-testid='failed-sync-row']", "#501")
    assert has_element?(view, "[data-testid='failed-sync-schema-filter']", "couldn't load")
  end

  test "rows show the error in a copyable code block and secondary data behind More details",
       %{conn: conn} do
    Application.put_env(:scrypath_ops, :meilisearch_tasks, [])

    Application.put_env(:scrypath_ops, :oban_jobs, [
      upsert_job(20, OpsPostA,
        state: "discarded",
        attempt: 3,
        max_attempts: 3,
        ids: [11, 12, 13, 14, 15],
        error: ~s|** (Ecto.CastError) cannot cast "n/a" to :integer for field :category_id|
      )
    ])

    {:ok, view, html} = live(conn, ~p"/ops/failed-sync")

    assert summary(view) =~ "1 failed"
    refute summary(view) =~ " retrying"
    assert html =~ "Review the error and fix its cause, then retry."
    assert has_element?(view, "[data-testid='failed-sync-row']", "Add or update")
    assert has_element?(view, "[data-testid='failed-sync-row']", "Oban search_sync #20")
    assert has_element?(view, "[data-testid='failed-sync-records']", "5 records")
    assert has_element?(view, "[data-testid='failed-sync-records'] code", "11, 12, 13")
    assert has_element?(view, "[data-testid='failed-sync-records']", "and 2 more")
    assert has_element?(view, "pre[data-testid='failed-sync-reason']", "Ecto.CastError")
    assert has_element?(view, ".ops-code-block button[aria-label='Copy error']")
    refute html =~ "Copy payload"
    assert html =~ "Invalid data: fix the record, then retry."

    retry = element(view, "[data-testid='failed-sync-retry']")
    assert render(retry) =~ "btn-outline"
    refute render(retry) =~ "btn-primary"

    details = view |> element("details[id^='failed-detail-']") |> render()
    assert details =~ "More details"
    assert details =~ "Scrypath.Oban.UpsertWorker"
    assert details =~ "3 of 3"
    assert details =~ "Copy job args"
    refute details =~ "Error category"
    refute details =~ ">upsert<"
    refute details =~ "validation"
  end

  test "long errors clamp with a Show all toggle", %{conn: conn} do
    Application.put_env(:scrypath_ops, :meilisearch_tasks, [])
    long = "** (RuntimeError) " <> String.duplicate("very long failure text ", 30)
    Application.put_env(:scrypath_ops, :oban_jobs, [upsert_job(30, OpsPostA, error: long)])

    {:ok, view, _html} = live(conn, ~p"/ops/failed-sync")

    assert has_element?(view, ".ops-code-block--clamp button[aria-expanded='false']", "Show all")
  end

  test "retry stays bound to the row's own schema", %{conn: conn} do
    Application.put_env(:scrypath_ops, :meilisearch_tasks, [])

    Application.put_env(:scrypath_ops, :oban_jobs, [
      upsert_job(509, OpsPostB, ids: ["variant-509"], error: "the Variant source remains visible")
    ])

    {:ok, view, html} = live(conn, ~p"/ops/failed-sync")

    assert html =~ ~s(datetime="2026-10-10T14:15:00Z")
    assert html =~ "the Variant source remains visible"

    assert has_element?(
             view,
             "[data-testid='failed-sync-retry'][phx-value-schema='ScrypathOps.Test.OpsPostB'][phx-value-id='509']"
           )

    sudo!(view)

    # A retry naming another schema never matches this row.
    missing =
      render_click(view, "retry", %{"id" => "509", "schema" => "ScrypathOps.Test.OpsPostA"})

    assert missing =~ "Could not find that failed job."
    assert Agent.get(:failed_sync_insert_counter, & &1) == 0

    accepted =
      view
      |> element("[data-testid='failed-sync-retry']")
      |> render_click()

    assert accepted =~ "Retry queued"
    assert accepted =~ "Oban job #991"
    assert accepted =~ "Original job #509 is retained"
    assert accepted =~ "schema=ScrypathOps.Test.OpsPostB"
    refute accepted =~ "Recovery verified"
    assert Agent.get(:failed_sync_insert_counter, & &1) == 1

    receipt = :sys.get_state(view.pid).socket.assigns.recovery_receipts

    assert %{
             "ScrypathOps.Test.OpsPostB|oban|509" => %{schema: "Elixir.ScrypathOps.Test.OpsPostB"}
           } = receipt
  end

  test "zero failed sync work stays truthful", %{conn: conn} do
    Application.put_env(:scrypath_ops, :meilisearch_tasks, [])
    Application.put_env(:scrypath_ops, :oban_jobs, [])

    {:ok, view, html} = live(conn, ~p"/ops/failed-sync")

    assert html =~ "No failed or retrying sync work"
    assert html =~ "Pending work and document freshness are checked on Sync and index."
    refute html =~ "0 failed"
    refute html =~ "0 retrying"
    refute has_element?(view, "[data-testid='failed-sync-row']")
    refute has_element?(view, "#failed-sync-filters")
  end

  test "retrying-only work uses retry guidance and leaves out the failed cohort", %{conn: conn} do
    Application.put_env(:scrypath_ops, :meilisearch_tasks, [])

    {:ok, view, html} = live(conn, ~p"/ops/failed-sync")

    assert summary(view) =~ "1 retrying"
    refute summary(view) =~ " failed"
    assert html =~ "It will retry automatically."
    assert html =~ "Retrying"
    assert html =~ "Unknown cause. This will retry automatically."
  end

  test "empty allowlist shows setup rather than healthy zero work", %{conn: conn} do
    Application.put_env(:scrypath_ops, :schema_allowlist, [])

    {:ok, lv, html} = live(conn, ~p"/ops/failed-sync")

    assert html =~ "No schemas configured."
    refute html =~ "No failed or retrying sync work"
    refute has_element?(lv, "[data-testid='failed-sync-summary']")
  end

  test "failed observation is not presented as zero work", %{conn: conn} do
    Application.put_env(:scrypath_ops, :meilisearch_tasks, {:error, :backend_unavailable})

    {:ok, lv, html} = live(conn, ~p"/ops/failed-sync")

    assert html =~ "Failed sync work could not load"
    assert html =~ ":backend_unavailable"
    refute html =~ "No failed or retrying sync work"
    refute has_element?(lv, "[data-testid='failed-sync-summary']")
  end

  test "explicit invalid or removed schemas show unavailable and refuse retry", %{conn: conn} do
    {:ok, invalid_view, invalid_html} =
      live(conn, ~p"/ops/failed-sync?schema=ScrypathOps.Test.Gone")

    assert invalid_html =~ "That schema is unavailable."
    assert has_element?(invalid_view, "a[href='/ops/failed-sync']", "Show all schemas")
    refute has_element?(invalid_view, "[data-testid='failed-sync-row']")

    {:ok, removed_view, _html} = live(conn, ~p"/ops/failed-sync")
    Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostB])
    retry_html = render_click(removed_view, "retry", %{"id" => "501"})
    assert retry_html =~ "That schema is unavailable."
    refute retry_html =~ "Retry queued"
    assert :sys.get_state(removed_view.pid).socket.assigns.scope_error == :unavailable
    assert Agent.get(:failed_sync_insert_counter, & &1) == 0
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
        loads: nil,
        recovery_receipts: %{},
        mount_path: "/ops",
        context_generation: 0
      },
      host_uri: URI.parse("https://scrypath.example/ops/failed-sync")
    }

    {:noreply, socket} =
      ScrypathOpsWeb.FailedSyncLive.handle_event("retry", %{"id" => "501"}, socket)

    assert inspect(socket.redirected) =~ "/sudo/confirm"
    assert inspect(socket.redirected) =~ "return_to=%2Fops%2Ffailed-sync"
    assert Agent.get(:failed_sync_insert_counter, & &1) == 0
  end

  test "sigra retry refreshes in place and keeps receipts across filter changes", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/failed-sync")
    sudo!(view)

    html = render_click(view, "retry", %{"id" => "501", "schema" => "ScrypathOps.Test.OpsPostA"})

    assert html =~ "Retry queued"
    assert html =~ "Oban job #991"
    assert html =~ "Original job #501 is retained"
    refute html =~ "Recovery verified"

    assigns = :sys.get_state(view.pid).socket.assigns
    assert assigns.last_refresh_at != nil
    assert assigns.recovery_receipts["ScrypathOps.Test.OpsPostA|oban|501"].replacement_job == 991
    assert Agent.get(:failed_sync_insert_counter, & &1) == 1

    repeated = render_click(view, "retry", %{"id" => "501"})
    assert repeated =~ "A retry for job 501 is already accepted"
    assert Agent.get(:failed_sync_insert_counter, & &1) == 1

    render_change(view, "filter", %{"cause" => ["unknown"]})
    assert render(view) =~ "Original job #501 is retained"

    assert :sys.get_state(view.pid).socket.assigns.context_generation ==
             assigns.context_generation
  end

  test "ineligible failed work explains the unavailable retry and never inserts", %{conn: conn} do
    Application.put_env(:scrypath_ops, :meilisearch_tasks, [])

    Application.put_env(:scrypath_ops, :oban_jobs, [
      %{
        id: 515,
        state: "discarded",
        worker: "Scrypath.Oban.UpsertWorker",
        queue: "search_sync",
        args: %{
          "operation" => "upsert",
          "repo" => "Elixir.ScrypathOps.Repo",
          "schema" => "Elixir.ScrypathOps.Test.OpsPostA",
          "backend" => "Elixir.Scrypath.Meilisearch",
          "index" => "fsv_ops_post_a"
        }
      }
    ])

    {:ok, view, html} = live(conn, ~p"/ops/failed-sync?schema=ScrypathOps.Test.OpsPostA")

    assert html =~ "The job didn&#39;t keep its record IDs, so it can&#39;t be retried here."
    refute has_element?(view, "[data-testid='failed-sync-retry']")
    refute html =~ "then retry"
    assert html =~ "Review the error and fix its cause."

    rejected = render_click(view, "retry", %{"id" => "515"})
    assert rejected =~ "That job does not expose a retry action"
    assert rejected =~ "Oban search_sync #515"
    assert Agent.get(:failed_sync_insert_counter, & &1) == 0
  end

  test "Meilisearch task rows keep their shortened eligibility copy", %{conn: conn} do
    Application.put_env(:scrypath_ops, :oban_jobs, [])

    {:ok, view, _html} = live(conn, ~p"/ops/failed-sync")

    assert has_element?(
             view,
             "[data-testid='failed-sync-eligibility']",
             "Meilisearch tasks can't be retried here."
           )
  end

  test "hostile failure values remain escaped text", %{conn: conn} do
    hostile = "<script>window.operatorCompromised = true</script>"

    Application.put_env(:scrypath_ops, :oban_jobs, [])

    Application.put_env(:scrypath_ops, :meilisearch_tasks, [
      %{
        "uid" => 401,
        "status" => "failed",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "fsv_ops_post_a",
        "error" => %{"message" => hostile}
      }
    ])

    {:ok, view, html} = live(conn, ~p"/ops/failed-sync?schema=ScrypathOps.Test.OpsPostA")

    assert html =~ "&lt;script&gt;window.operatorCompromised = true&lt;/script&gt;"
    refute has_element?(view, "script")
    assert has_element?(view, "[data-testid='failed-sync-reason']")
  end

  test "missing backend remains a setup state without retry actions", %{conn: conn} do
    Application.delete_env(:scrypath_ops, :backend)
    Application.delete_env(:scrypath_ops, :meilisearch_client)

    {:ok, view, html} = live(conn, ~p"/ops/failed-sync?schema=ScrypathOps.Test.OpsPostA")

    assert html =~ "Runtime not configured"
    refute has_element?(view, "[data-testid='failed-sync-row']")
    refute has_element?(view, "[data-testid='failed-sync-retry']")
  end

  test "delete retry requires confirmation and dismissal keeps the failed row", %{conn: conn} do
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
    assert html =~ "ScrypathOps.Test.OpsPostA"
    assert html =~ "fsv_ops_post_a"
    assert html =~ "doc-1"
    assert html =~ "doc-2"
    assert html =~ "Keep failed work and close"
    assert html =~ ~s(aria-label="Keep failed work and close")

    html = render_click(view, "cancel_retry_delete", %{})
    refute html =~ "Confirm delete sync work"
    assert html =~ "Oban search_sync #502"
    refute html =~ "Retry queued"
  end

  defp summary(view), do: view |> element("#failed-sync-summary-heading") |> render()

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
