defmodule ScrypathOpsWeb.FailedSyncLiveTest do
  @moduledoc false
  # Phase 47 D-10: see SECURITY + prod guard tests. D-13: `reason_class_counts: true`
  # inspection + rollup counts (`FailedSyncLive` mount).
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Scrypath.Operator.FailedSyncWorkInspection
  alias ScrypathOps.FailedSyncView
  alias ScrypathOps.Test.CopyStubs.FailedSync, as: FailedSyncStubs
  alias ScrypathOps.Test.FixtureEnv
  alias ScrypathOps.Test.HtmlCanon
  alias ScrypathOps.Test.OpsPostA
  alias ScrypathOps.Test.OpsPostB
  alias ScrypathOpsWeb.Components.FailedSync

  defmodule FailingOban do
    # An enqueue that fails with the kind of term a real queue returns: a map holding atoms.
    def insert(_changeset), do: {:error, %{reason: :timeout, meta: %{}}}
  end

  setup do
    previous = FailedSyncStubs.put_env()
    start_supervised!(FailedSyncStubs.counter_spec())

    # The sudo confirmation lives here, not in the shared stubs: the namespace fence keeps
    # references to that integration out of test/support.
    prev_sigra = Application.get_env(:scrypath_ops, :sigra)
    prev_opsui_auth_mode = System.get_env("OPSUI_AUTH_MODE")

    Application.put_env(:scrypath_ops, :sigra,
      sudo_confirm_path: "/sudo/confirm",
      sudo_window: 300
    )

    System.put_env("OPSUI_AUTH_MODE", "sigra")

    on_exit(fn ->
      FailedSyncStubs.restore_env(previous)

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
      scheduled_at: Keyword.get(opts, :scheduled_at),
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

  # A confirmed operator by default (confirmed a minute ago, window 300 s); pass -600 for one whose
  # confirmation is stale.
  defp sudo!(view, sudo_at_offset \\ -60) do
    put_live_assigns(view,
      current_scope: %{user: %{id: "user_123"}, active_organization: %{id: "org_456"}},
      operator_context: %ScrypathOps.Integrations.Sigra.OperatorContext{
        user_id: "user_123",
        active_org_id: "org_456",
        impersonator_user_id: nil,
        sudo_at: DateTime.add(DateTime.utc_now(), sudo_at_offset, :second)
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

  # Phase 187 E-02 (Failed sync half): a row's state is the shared status word and icon, never a
  # badge, and `data-state` keeps its value so the row stays addressable.
  test "each failed sync row renders one status word and icon from its state", %{conn: conn} do
    Application.put_env(:scrypath_ops, :oban_jobs, [
      upsert_job(501, OpsPostA, error: "** (Ecto.CastError) cannot cast"),
      upsert_job(509, OpsPostB, state: "discarded", error: "the Variant source remains visible")
    ])

    {:ok, _view, html} = live(conn, ~p"/ops/failed-sync")

    rows =
      html
      |> LazyHTML.from_fragment()
      |> LazyHTML.query("[data-testid='failed-sync-row']")

    assert Enum.count(rows) == 3

    states =
      for row <- rows do
        [state] = LazyHTML.attribute(row, "data-state")
        statuses = LazyHTML.query(row, "[data-sync-status]")

        assert Enum.count(statuses) == 1
        assert LazyHTML.attribute(statuses, "data-sync-status") == [state]

        assert statuses |> LazyHTML.query(".ops-sync-status__word") |> LazyHTML.text() ==
                 String.capitalize(state)

        assert statuses |> LazyHTML.query("svg[aria-hidden='true'][data-shape]") |> Enum.count() ==
                 1

        badge_words = row |> LazyHTML.query(".ops-badge") |> Enum.map(&LazyHTML.text/1)
        assert Enum.all?(badge_words, &(String.trim(&1) not in ~w(Failed Retrying Pending Clear)))

        state
      end

    assert Enum.sort(states) == ["failed", "failed", "retrying"]
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
    # Phase 187: a row action is underlined text, not a button.
    assert render(retry) =~ "ops-text-action"
    refute render(retry) =~ ~r/\bbtn\b/
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

    # The receipt is a neutral notice (Control Edge rule), not a tinted or Plum one.
    assert has_element?(
             view,
             "[data-testid='recovery-receipt'].ops-notice-surface--neutral[data-status-kind='neutral']",
             "Retry queued"
           )

    receipt = :sys.get_state(view.pid).socket.assigns.recovery_receipts

    assert %{
             "ScrypathOps.Test.OpsPostB|oban|509" => %{schema: "Elixir.ScrypathOps.Test.OpsPostB"}
           } = receipt
  end

  # Phase 187 E-11 / T-187-11: the reason can hold backend or queue detail, so the page gets a
  # fixed sentence naming the schema and the reason goes to the log.
  test "a retry that does not go through says so without leaking the raw reason", %{conn: conn} do
    Application.put_env(:scrypath_ops, :meilisearch_tasks, [])
    Application.put_env(:scrypath_ops, :oban, FailingOban)

    Application.put_env(:scrypath_ops, :oban_jobs, [
      upsert_job(509, OpsPostB, ids: ["variant-509"], error: "the Variant source remains visible")
    ])

    {:ok, view, _html} = live(conn, ~p"/ops/failed-sync")
    sudo!(view)

    log =
      ExUnit.CaptureLog.capture_log(fn ->
        view |> element("[data-testid='failed-sync-retry']") |> render_click()
      end)

    expected =
      "Retry did not go through for ScrypathOps.Test.OpsPostB. " <>
        "The failed work is unchanged and still listed. " <>
        "Check that the queue and Meilisearch are reachable, then retry."

    flash = :sys.get_state(view.pid).socket.assigns.flash["error"]
    assert flash == expected

    for leaked <- ["%{", ":timeout", "{:error", "meta"] do
      refute flash =~ leaked
      refute render(view) =~ "Retry failed:"
    end

    # The failed work is unchanged and still listed, with no receipt.
    assert has_element?(view, "[data-testid='failed-sync-row']", "#509")
    refute has_element?(view, "[data-testid='recovery-receipt']")

    # The reason is not lost: it is in the log for the operator running the host.
    assert log =~ "Failed sync retry did not go through for ScrypathOps.Test.OpsPostB"
    assert log =~ ":timeout"
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

  test "retrying rows show when Oban will try again; failed rows do not", %{conn: conn} do
    Application.put_env(:scrypath_ops, :meilisearch_tasks, [])

    Application.put_env(:scrypath_ops, :oban_jobs, [
      upsert_job(601, ScrypathOps.Test.OpsPostA, scheduled_at: "2026-10-10T14:20:00Z"),
      upsert_job(602, ScrypathOps.Test.OpsPostA,
        state: "discarded",
        scheduled_at: "2026-10-10T14:00:00Z"
      )
    ])

    {:ok, view, _html} = live(conn, ~p"/ops/failed-sync")

    next_try = view |> element(~s([data-testid="failed-sync-next-try"])) |> render()

    assert next_try =~ "Next try"
    assert next_try =~ "14:20"
    assert has_element?(view, ~s([data-state="retrying"] [data-testid="failed-sync-next-try"]))
    refute has_element?(view, ~s([data-state="failed"] [data-testid="failed-sync-next-try"]))
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

  # Phase 197 PILOT-01: this test used to hand-build a socket with no loaded rows, so no row was
  # ever found and the sudo gate was never reached for a real row. It now drives a mounted view and
  # clicks the retry button the page renders.
  test "stale sudo sends a click on a rendered retry button to the confirm page and keeps the row",
       %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ops/failed-sync")
    retry = "[data-testid='failed-sync-retry'][phx-value-id='501']"
    assert has_element?(view, retry)

    sudo!(view, -600)
    assert {:error, {:live_redirect, %{to: to}}} = view |> element(retry) |> render_click()

    assert String.starts_with?(to, "/sudo/confirm")
    assert Agent.get(:failed_sync_insert_counter, & &1) == 0

    # The row is still retryable on a fresh mount.
    {:ok, fresh, _html} = live(conn, ~p"/ops/failed-sync")
    assert has_element?(fresh, retry)

    # Positive control: the same click with a fresh confirmation is queued exactly once.
    sudo!(fresh)
    accepted = fresh |> element(retry) |> render_click()
    assert accepted =~ "Retry queued"
    assert Agent.get(:failed_sync_insert_counter, & &1) == 1
  end

  # Phase 197 defect D1: LiveView prunes the path and query from `host_uri`, so a stale-sudo
  # operator used to come back from the confirm page to "/" and lose the filters they had set.
  test "stale sudo returns the operator to the filtered page they left", %{conn: conn} do
    Application.put_env(:scrypath_ops, :meilisearch_tasks, [])

    Application.put_env(:scrypath_ops, :oban_jobs, [
      upsert_job(603, OpsPostA, error: "** (Req.TransportError) connection refused")
    ])

    left = "/ops/failed-sync?schema=ScrypathOps.Test.OpsPostA&cause=transport"
    {:ok, view, _html} = live(conn, left)
    retry = "[data-testid='failed-sync-retry'][phx-value-id='603']"
    assert has_element?(view, retry)

    sudo!(view, -600)
    assert {:error, {:live_redirect, %{to: to}}} = view |> element(retry) |> render_click()

    assert %URI{path: "/sudo/confirm", query: query} = URI.parse(to)
    assert %{"return_to" => ^left} = URI.decode_query(query)
    assert Agent.get(:failed_sync_insert_counter, & &1) == 0
  end

  describe "OnMount.return_to_path/1" do
    alias ScrypathOpsWeb.Live.OnMount

    test "keeps the path and the query of a request URL and drops the host" do
      assert OnMount.return_to_path("https://ops.example.com/ops/failed-sync?schema=A&cause=b") ==
               "/ops/failed-sync?schema=A&cause=b"

      assert OnMount.return_to_path("http://localhost:4002/ops/health") == "/ops/health"
      assert OnMount.return_to_path("http://localhost:4002/ops/health?") == "/ops/health"
    end

    test "never returns a target that could leave the host" do
      # A protocol-relative path would send the browser to another host after the confirmation.
      assert OnMount.return_to_path("https://ops.example.com//evil.example/x") == nil
      assert OnMount.return_to_path("//evil.example/x") == nil
      assert OnMount.return_to_path("https://ops.example.com/\\evil.example") == nil
      assert OnMount.return_to_path("https://ops.example.com/ops/\r\nSet-Cookie: a=b") == nil
    end

    test "returns nil when there is no usable absolute path" do
      assert OnMount.return_to_path("https://ops.example.com") == nil
      assert OnMount.return_to_path("ops/failed-sync") == nil
      assert OnMount.return_to_path("") == nil
      assert OnMount.return_to_path(nil) == nil
    end
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
    assert repeated =~ "A retry for job 501 is already queued"
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

  describe "E-07 and E-08 retry-delete dialog" do
    @modal "#retry-delete-modal"

    for {ids, label, noun} <- [
          {["doc-1"], "Retry deleting 1 document", "1 document"},
          {["doc-1", "doc-2", "doc-3"], "Retry deleting 3 documents", "3 documents"}
        ] do
      test "#{label}: the confirm is the single Plum button and Cancel opens focused", %{
        conn: conn
      } do
        ids = unquote(ids)
        put_delete_job!(ids)

        {:ok, view, _html} = live(conn, ~p"/ops/failed-sync")
        html = render_click(view, "retry", %{"id" => "502"})

        # exactly one Plum button inside the dialog, and it names its consequence
        assert has_element?(view, "#{@modal} .btn-primary", unquote(label))

        assert [_] =
                 html
                 |> LazyHTML.from_fragment()
                 |> LazyHTML.query("#{@modal} .btn-primary")
                 |> Enum.to_list()

        refute html =~ "btn-error"
        refute html =~ "Retry delete sync work"

        # the page behind the dialog has no Plum button of its own
        assert html |> LazyHTML.from_fragment() |> LazyHTML.query(".btn-primary") |> Enum.count() ==
                 1

        # description and list use the same pluralization, titles and Cancel are kept
        assert has_element?(
                 view,
                 "#{@modal}-description",
                 "Retry deletion of #{unquote(noun)} for ScrypathOps.Test.OpsPostA in fsv_ops_post_a."
               )

        assert has_element?(view, "#{@modal} p", unquote(noun))
        assert has_element?(view, "#{@modal}", "Confirm delete sync work")

        # Cancel is present, outline (not ghost), and is the dialog's initial focus
        assert has_element?(
                 view,
                 "#{@modal}[data-ops-modal-initial-focus='[data-ops-modal-cancel]']"
               )

        assert has_element?(
                 view,
                 "#{@modal} button[data-ops-modal-cancel].btn-outline:not(.btn-ghost)",
                 "Keep failed work and close"
               )
      end
    end

    test "the page itself has no Plum button before the dialog opens", %{conn: conn} do
      put_delete_job!(["doc-1"])
      {:ok, view, html} = live(conn, ~p"/ops/failed-sync")

      assert html |> LazyHTML.from_fragment() |> LazyHTML.query(".btn-primary") |> Enum.count() ==
               0

      refute has_element?(view, @modal)
    end
  end

  describe "E-09 Retry row action" do
    test "Retry is an underlined text action, not a button, and keeps its test id and name", %{
      conn: conn
    } do
      put_delete_job!(["doc-1"])
      {:ok, view, _html} = live(conn, ~p"/ops/failed-sync")

      retry = "button[data-testid='failed-sync-retry']"
      assert has_element?(view, "#{retry}.ops-text-action", "Retry")
      refute has_element?(view, "#{retry}.btn")
      refute has_element?(view, "#{retry}.ops-btn")
      assert has_element?(view, "#{retry}[type=button][phx-click=retry]")
    end
  end

  # ── The view-model (Phase 197): classification is decided here, never in the markup ──────────────

  describe "FailedSyncView.build/4" do
    test "the failed journey's rows carry a closed action: Retry for the Oban jobs, none for the task" do
      view = journey_view()

      assert view.state == :ready
      assert view.summary_kind == :warning
      assert view.headline == "4 failed, 1 retrying"

      actions = Map.new(view.rows, &{&1.id, &1.action})

      assert actions == %{
               43 => :ineligible,
               101 => :retry,
               102 => :retry,
               103 => :retry,
               104 => :retry
             }

      # The facts the page shows today are on the row.
      row_101 = Enum.find(view.rows, &(&1.id == 101))
      assert row_101.schema == ScrypathFixtures.Shopadelic.Product
      assert row_101.operation == :upsert
      assert row_101.cause == :transport
      assert row_101.sync_status == :failed
      assert row_101.attempts == "8 of 8"
      assert row_101.dom_id == "ScrypathFixtures-Shopadelic-Product-oban-101"
      assert row_101.record_ids != nil and row_101.recoverable?
      assert is_binary(row_101.reason)

      row_102 = Enum.find(view.rows, &(&1.id == 102))
      assert row_102.sync_status == :retrying
      assert %DateTime{} = row_102.next_attempt_at

      row_43 = Enum.find(view.rows, &(&1.id == 43))
      assert row_43.source == :meilisearch
      assert row_43.cause == :validation
      refute row_43.recoverable?
      assert row_43.record_ids == nil
    end

    test "a row with a receipt has the receipt action, and only that row" do
      {loads, scope} = journey_loads()
      entry = loads |> FailedSyncView.all_rows() |> Enum.find(&(&1.id == 101))

      receipt = %{
        replacement_job: 991,
        handle: "h",
        generation: 0,
        operation: :upsert,
        index: "i"
      }

      view =
        FailedSyncView.build(
          loads,
          scope,
          %{FailedSyncView.row_key(entry) => receipt},
          ScrypathFixtures.preview_epoch()
        )

      actions = Map.new(view.rows, &{&1.id, &1.action})
      assert actions[101] == :receipt
      assert Enum.find(view.rows, &(&1.id == 101)).receipt == receipt

      assert Map.delete(actions, 101) == %{
               43 => :ineligible,
               102 => :retry,
               103 => :retry,
               104 => :retry
             }
    end

    test "every cause is in the closed set, and an unclassified row is unknown" do
      view = journey_view()
      assert Enum.all?(view.rows, &(&1.cause in FailedSyncView.causes()))

      unclassified = %{journey_entry(101) | reason_class: nil}
      assert FailedSyncView.cause(unclassified) == :unknown
      assert FailedSyncView.cause(%{journey_entry(101) | reason_class: :surprise}) == :unknown
    end

    test "the page state is one of four, decided from the scope and the loads" do
      now = ScrypathFixtures.preview_epoch()
      {loads, scope} = journey_loads()

      assert FailedSyncView.build(loads, scope, %{}, now).state == :ready
      assert FailedSyncView.build(:missing_backend, scope, %{}, now).state == :missing_backend

      assert FailedSyncView.build(nil, %{scope | error: :no_schemas}, %{}, now).state ==
               :no_schemas

      assert FailedSyncView.build(nil, %{scope | error: :unavailable}, %{}, now).state ==
               :unavailable

      # A nil load with no scope error is a state the LiveView never produces: it is refused, not
      # rendered as a healthy page.
      assert_raise FunctionClauseError, fn -> FailedSyncView.build(nil, scope, %{}, now) end
    end

    test "the summary kind follows the rows, the filters and the load errors" do
      now = ScrypathFixtures.preview_epoch()
      {loads, scope} = journey_loads()
      [{mod, _}] = loads

      assert FailedSyncView.build(loads, scope, %{}, now).summary_kind == :warning

      # Filtered to a cause no row has: work exists but none matches.
      neutral =
        FailedSyncView.build(loads, %{scope | cause_filter: [:backend_rejected]}, %{}, now)

      assert neutral.summary_kind == :neutral
      assert neutral.headline == "No sync work matches these filters"
      assert neutral.filtered_out?
      assert neutral.hidden_count == 5

      # Two schemas, one failed to load and the other has nothing: partial, not success.
      other = ScrypathOps.Test.OpsPostA

      partial =
        FailedSyncView.build(
          [{mod, {:error, :timeout}}, {other, {:ok, []}}],
          %{scope | allowlist: [mod, other]},
          %{},
          now
        )

      assert partial.summary_kind == :partial
      assert partial.headline == "No failed or retrying sync work in the schemas that loaded"
      assert partial.errors == [{mod, :timeout}]
      refute partial.all_failed?

      success = FailedSyncView.build([{mod, {:ok, []}}], scope, %{}, now)
      assert success.summary_kind == :success
      assert success.headline == "No failed or retrying sync work"

      # Every schema in scope failed to load: the verdict is withheld, the errors stay.
      assert FailedSyncView.build([{mod, {:error, :timeout}}], scope, %{}, now).all_failed?
    end

    test "build/4 is pure: the same inputs give the same view, and now is only what it is given" do
      {loads, scope} = journey_loads()
      now = ScrypathFixtures.preview_epoch()

      assert FailedSyncView.build(loads, scope, %{}, now) ==
               FailedSyncView.build(loads, scope, %{}, now)

      later = DateTime.add(now, 3600, :second)
      assert FailedSyncView.build(loads, scope, %{}, later).now == later
    end

    test "an open delete retry is a row, and only a delete with a recovery action" do
      now = ScrypathFixtures.preview_epoch()
      {loads, scope} = journey_loads()
      delete_entry = journey_entry(104)

      view =
        FailedSyncView.build(
          loads,
          %{scope | delete_confirmation: FailedSyncView.row_key(delete_entry)},
          %{},
          now
        )

      assert view.delete_row.id == 104
      assert view.delete_row.operation == :delete

      # An upsert job's key opens nothing.
      upsert_key = FailedSyncView.row_key(journey_entry(101))

      refute FailedSyncView.build(loads, %{scope | delete_confirmation: upsert_key}, %{}, now).delete_row
    end
  end

  # The story renders the same function components the page does. Each area gets one seam test: the
  # mounted page contains exactly the component's own output for the page's own view-model.
  describe "seam: failed_row (story output equals production output)" do
    setup do
      scenario =
        ScrypathFixtures.Scenarios.get!(
          :shopadelic_failed_journey,
          ScrypathFixtures.preview_epoch()
        )

      on_exit(FixtureEnv.put(scenario))
      :ok
    end

    test "each mounted row for shopadelic_failed_journey equals the component output", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, ~p"/ops/failed-sync")
      _ = render_async(view)

      assigns = :sys.get_state(view.pid).socket.assigns
      now = ScrypathOps.Clock.utc_now()
      page_view = page_view(assigns, now)
      mounted = view |> render() |> LazyHTML.from_fragment()

      # The cause is real data: the five failed journey rows, including the one with a next try.
      assert Enum.map(page_view.rows, & &1.id) |> Enum.sort() == [43, 101, 102, 103, 104]
      assert Enum.any?(page_view.rows, &(&1.next_attempt_at != nil))

      for row <- page_view.rows do
        selector = "[id='failed-row-#{row.dom_id}']"
        mounted_row = LazyHTML.query(mounted, selector)

        component_row =
          row |> component_html(now, assigns.mount_path) |> LazyHTML.query(selector)

        assert Enum.count(mounted_row) == 1
        assert Enum.count(component_row) == 1
        assert HtmlCanon.canon(mounted_row) == HtmlCanon.canon(component_row)
      end

      # Control: the comparison can fail. A different row action changes the canonical tree.
      row = Enum.find(page_view.rows, &(&1.id == 101))
      selector = "[id='failed-row-#{row.dom_id}']"

      changed =
        %{row | action: :ineligible, recoverable?: false}
        |> component_html(now, assigns.mount_path)
        |> LazyHTML.query(selector)

      refute HtmlCanon.canon(LazyHTML.query(mounted, selector)) == HtmlCanon.canon(changed)
    end

    test "a mounted row holding a receipt equals the component output for it", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/ops/failed-sync")
      entry = journey_entry(101)

      # The shape `FailedSyncLive` stores after a retry is accepted (the journey drives the real
      # retry; this test pins what the page shows for such a receipt).
      receipt = %{
        replacement_job: 991,
        attempt: 1,
        operation: :upsert,
        index: "shopadelic_product",
        generation: 0,
        handle: "seam-handle",
        state: :accepted
      }

      put_live_assigns(view, recovery_receipts: %{FailedSyncView.row_key(entry) => receipt})
      # A patch to the same page makes the LiveView re-render with the injected receipt.
      _ = render_patch(view, ~p"/ops/failed-sync")

      assigns = :sys.get_state(view.pid).socket.assigns
      now = ScrypathOps.Clock.utc_now()
      row = assigns |> page_view(now) |> Map.fetch!(:rows) |> Enum.find(&(&1.id == 101))
      assert row.action == :receipt

      selector = "[id='failed-row-#{row.dom_id}']"
      mounted_row = view |> render() |> LazyHTML.from_fragment() |> LazyHTML.query(selector)

      component_row =
        row |> component_html(now, assigns.mount_path) |> LazyHTML.query(selector)

      assert Enum.count(mounted_row) == 1
      assert HtmlCanon.canon(mounted_row) =~ "Retry queued"
      assert HtmlCanon.canon(mounted_row) == HtmlCanon.canon(component_row)

      refute has_element?(
               view,
               "[id='failed-row-#{row.dom_id}'] button[data-testid='failed-sync-retry']"
             )
    end
  end

  # Each case is mounted through the real router under FixtureEnv. When the page is ready, its
  # summary and filters, and in every state the whole page, must canonicalize equal to the shared
  # components' own output for the page's own view-model. The stories render the same functions, so
  # this is what lets a story claim to show the page. The four page states are all reached: ready,
  # no schemas, missing backend and an unavailable schema.
  describe "seam: failed_summary, failed_filters and screen (story output equals production output)" do
    for {scenario_id, query, state} <- [
          {:shopadelic_failed_journey, "", :ready},
          {:shopadelic_failed_journey, "?cause=transport", :ready},
          {:shopadelic_failed_journey, "?cause=backend_rejected", :ready},
          {:shopadelic_settings_aligned, "", :ready},
          {:logistify_history_over_limit_f1, "", :ready},
          {:wikily_first_delete_failed, "", :ready},
          {:wikily_unconfigured, "", :no_schemas},
          {:wikily_missing_backend, "", :missing_backend},
          {:shopadelic_failed_journey, "?schema=No.Such.Schema", :unavailable}
        ] do
      test "#{scenario_id}#{query}: the #{state} page equals the component output", %{conn: conn} do
        scenario_id = unquote(scenario_id)
        scenario = ScrypathFixtures.Scenarios.get!(scenario_id, ScrypathFixtures.preview_epoch())
        on_exit(FixtureEnv.put(scenario))

        {:ok, view, _html} = live(conn, "/ops/failed-sync" <> unquote(query))
        _ = render_async(view)

        assigns = :sys.get_state(view.pid).socket.assigns
        now = ScrypathOps.Clock.utc_now()
        page_view = page_view(assigns, now)
        mounted = view |> render() |> LazyHTML.from_fragment()

        # The cause is real data: the page reached the state this case names.
        assert page_view.state == unquote(state)

        if page_view.state == :ready do
          summary =
            "[data-testid='failed-sync-load-error'], section[aria-labelledby='failed-sync-summary-heading']"

          mounted_summary = LazyHTML.query(mounted, summary)

          component_summary =
            component_fragment(&FailedSync.failed_summary/1,
              view: page_view,
              mount_path: assigns.mount_path
            )
            |> LazyHTML.query(summary)

          assert Enum.count(mounted_summary) > 0
          assert HtmlCanon.canon(mounted_summary) == HtmlCanon.canon(component_summary)

          if page_view.show_filters? do
            filters = "#failed-sync-filters"
            mounted_filters = LazyHTML.query(mounted, filters)

            component_filters =
              component_fragment(&FailedSync.failed_filters/1, view: page_view)
              |> LazyHTML.query(filters)

            assert Enum.count(mounted_filters) == 1
            assert HtmlCanon.canon(mounted_filters) == HtmlCanon.canon(component_filters)
          end
        end

        screen_assigns = [
          view: page_view,
          mount_path: assigns.mount_path,
          flash: assigns.flash,
          shell: assigns.shell,
          page_title: assigns.page_title,
          last_refresh_at: assigns.last_refresh_at
        ]

        page = LazyHTML.query(mounted, "[data-phx-main] > *")
        component_page = component_fragment(&FailedSync.screen/1, screen_assigns)

        assert Enum.count(page) > 0
        assert HtmlCanon.canon(page) == HtmlCanon.canon(component_page)

        # Control: the comparison can fail. A different mount path changes every shell link.
        changed_page =
          component_fragment(
            &FailedSync.screen/1,
            Keyword.put(screen_assigns, :mount_path, "/elsewhere")
          )

        refute HtmlCanon.canon(page) == HtmlCanon.canon(changed_page)
      end
    end

    test "the delete confirmation the mounted page opens equals the component output", %{
      conn: conn
    } do
      scenario =
        ScrypathFixtures.Scenarios.get!(
          :shopadelic_failed_journey,
          ScrypathFixtures.preview_epoch()
        )

      on_exit(FixtureEnv.put(scenario))

      {:ok, view, _html} = live(conn, ~p"/ops/failed-sync")
      refute has_element?(view, "#retry-delete-modal")

      # Job 104 is the failed delete: pressing its rendered Retry opens the confirmation.
      view
      |> element("button[data-testid='failed-sync-retry'][phx-value-id='104']")
      |> render_click()

      assert has_element?(view, "#retry-delete-modal")

      assigns = :sys.get_state(view.pid).socket.assigns
      page_view = page_view(assigns, ScrypathOps.Clock.utc_now())
      assert page_view.delete_row.id == 104

      mounted =
        view |> render() |> LazyHTML.from_fragment() |> LazyHTML.query("#retry-delete-modal")

      component =
        component_fragment(&FailedSync.delete_confirmation/1, row: page_view.delete_row)
        |> LazyHTML.query("#retry-delete-modal")

      assert Enum.count(mounted) == 1
      assert HtmlCanon.canon(mounted) =~ "Confirm delete sync work"
      assert HtmlCanon.canon(mounted) == HtmlCanon.canon(component)

      # Control: a different document list changes the canonical tree.
      recovery = page_view.delete_row.entry.recovery
      reference = put_in(recovery.reference, [:payload, "document_ids"], ["OTHER-1"])
      entry = %{page_view.delete_row.entry | recovery: %{recovery | reference: reference}}
      changed_row = %{page_view.delete_row | entry: entry}

      changed =
        component_fragment(&FailedSync.delete_confirmation/1, row: changed_row)
        |> LazyHTML.query("#retry-delete-modal")

      refute HtmlCanon.canon(mounted) == HtmlCanon.canon(changed)
    end

    test "the retry receipt the mounted page shows equals the component output", %{conn: conn} do
      scenario =
        ScrypathFixtures.Scenarios.get!(
          :shopadelic_failed_journey,
          ScrypathFixtures.preview_epoch()
        )

      on_exit(FixtureEnv.put(scenario))

      {:ok, view, _html} = live(conn, ~p"/ops/failed-sync")

      receipt = %{
        replacement_job: 991,
        attempt: 1,
        operation: :upsert,
        index: "shopadelic_product",
        generation: 0,
        handle: "seam-handle",
        state: :accepted
      }

      put_live_assigns(view,
        recovery_receipts: %{FailedSyncView.row_key(journey_entry(101)) => receipt}
      )

      _ = render_patch(view, ~p"/ops/failed-sync")

      assigns = :sys.get_state(view.pid).socket.assigns
      page_view = page_view(assigns, ScrypathOps.Clock.utc_now())
      row = Enum.find(page_view.rows, &(&1.id == 101))
      assert row.action == :receipt

      selector = "[data-testid='recovery-receipt']"
      mounted = view |> render() |> LazyHTML.from_fragment() |> LazyHTML.query(selector)

      component =
        component_fragment(&FailedSync.retry_receipt/1, row: row, mount_path: assigns.mount_path)
        |> LazyHTML.query(selector)

      assert Enum.count(mounted) == 1
      assert HtmlCanon.canon(mounted) =~ "Retry queued"
      assert HtmlCanon.canon(mounted) == HtmlCanon.canon(component)

      # Control: a receipt without a handle has no status link, so it is a different tree.
      no_handle =
        component_fragment(&FailedSync.retry_receipt/1,
          row: %{row | receipt: %{receipt | handle: nil}},
          mount_path: assigns.mount_path
        )
        |> LazyHTML.query(selector)

      refute HtmlCanon.canon(mounted) == HtmlCanon.canon(no_handle)
    end
  end

  defp put_delete_job!(document_ids) do
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
          "document_count" => length(document_ids),
          "document_ids" => document_ids
        }
      }
    ])
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

  # The Shopadelic failed journey's loads and scope, built the way the story builds them: straight
  # from `Scrypath.failed_sync_work/2` over the scenario's own options, no process running.
  defp journey_loads do
    scenario =
      ScrypathFixtures.Scenarios.get!(
        :shopadelic_failed_journey,
        ScrypathFixtures.preview_epoch()
      )

    opts = Keyword.put(scenario.scrypath_opts, :reason_class_counts, true)

    loads =
      for mod <- scenario.allowlist do
        {:ok, %FailedSyncWorkInspection{entries: entries}} = Scrypath.failed_sync_work(mod, opts)
        {mod, {:ok, entries}}
      end

    {loads, view_scope(scenario.allowlist)}
  end

  defp journey_view do
    {loads, scope} = journey_loads()
    FailedSyncView.build(loads, scope, %{}, ScrypathFixtures.preview_epoch())
  end

  defp journey_entry(id) do
    {loads, _scope} = journey_loads()
    loads |> FailedSyncView.all_rows() |> Enum.find(&(&1.id == id))
  end

  defp view_scope(allowlist) do
    %{
      error: nil,
      allowlist: allowlist,
      schema_filter: [],
      cause_filter: [],
      delete_confirmation: nil
    }
  end

  # The view the mounted page rendered, rebuilt from its own state.
  defp page_view(assigns, now) do
    scope = %{
      error: assigns.scope_error,
      allowlist: assigns.schema_allowlist,
      schema_filter: assigns.schema_filter,
      cause_filter: assigns.cause_filter,
      delete_confirmation: assigns.delete_confirmation
    }

    FailedSyncView.build(assigns.loads, scope, assigns.recovery_receipts, now)
  end

  # A Failed sync row rendered by the shared component, as a parsed fragment.
  defp component_html(row, now, mount_path) do
    assigns = [row: row, now: now, mount_path: mount_path]

    (&FailedSync.failed_row/1)
    |> render_component(assigns)
    |> LazyHTML.from_fragment()
  end

  # A shared component rendered with the given assigns, as a parsed fragment.
  defp component_fragment(component, assigns) do
    component |> render_component(assigns) |> LazyHTML.from_fragment()
  end
end
