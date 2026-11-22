defmodule ScrypathOps.Test.CopySurfaces do
  @moduledoc false
  # Registry of the rendered surfaces the copy rules table names. Each surface is an existing
  # fixture state of a ScrypathOps screen, rendered to HTML. Every surface carries a state
  # anchor: a short literal that appears in the HTML only when the surface reached its intended
  # state. The contract test asserts the anchor before it evaluates any row, so a forbidden-only
  # row cannot pass on a page that never showed the state. An anchor never contains a phrase a
  # row forbids or requires (`CopyRules.validate/2` checks that).
  #
  # Shared fixture setup lives in `ScrypathOps.Test.CopyStubs.*`, which the LiveView tests use
  # too, so no stub is defined twice.

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias ScrypathOps.Test.CopyStubs.ControlRoom, as: ControlRoomStubs
  alias ScrypathOps.Test.CopyStubs.FailedSync, as: FailedSyncStubs
  alias ScrypathOps.Test.CopyStubs.Posture, as: PostureStubs
  alias ScrypathOps.Test.CopyStubs.SyncDrift, as: SyncDriftStubs
  alias ScrypathOps.Test.FixtureEnv
  alias ScrypathOps.Test.OpsPostA
  alias ScrypathOpsWeb.SyncDriftLive

  @endpoint ScrypathOpsWeb.Endpoint

  @anchors %{
    "control_room.default" => "Search backend not configured.",
    "control_room.healthy" => "Document visibility is checked separately.",
    "control_room.refresh_no_prior" => "Incomplete observation checked:",
    "control_room.refresh_retained" => "Search health refresh incomplete.",
    "control_room.refresh_retained_degraded" => "Search health refresh incomplete.",
    "failed_sync.after_retry" => "Oban job #991",
    "failed_sync.delete_confirmation" => "Confirm delete sync work",
    "failed_sync.scoped_load_error" => "Failed sync work could not load",
    "posture.default" => "Meilisearch document tasks",
    "posture.failed_row_retained" => "source-local evidence is retained from check",
    "posture.shopadelic_degraded" => "Sync jobs and Meilisearch tasks failed",
    "sync_drift.caught_up" => "Caught up.",
    "sync_drift.default" => ~s(aria-label="Related search views"),
    "sync_drift.promotion_accepted" => ~s(id="promotion-status-result"),
    "sync_drift.promotion_blocked_queue" => "Promotion unavailable",
    "sync_drift.queue_pending" => "Sync work is pending",
    "sync_drift.reconcile_error_retained" => ~s(id="sync-pipeline-error"),
    "sync_drift.recovery_queued" => "Refresh recovery status",
    "sync_drift.recovery_unavailable" => "Recovery refresh could not be checked",
    "sync_drift.recovery_verified" => "Recovery verified",
    "sync_drift.settings_missing_field" => ~s(data-missing="true")
  }

  @doc "Registered surface ids."
  def ids, do: @anchors |> Map.keys() |> Enum.sort()

  @doc "Surface id to state anchor."
  def anchors, do: @anchors

  @doc "State anchor of one surface."
  def anchor(id), do: Map.fetch!(@anchors, id)

  @doc """
  Renders one surface to HTML. `ctx` carries the `conn` of the calling test (so the Ecto sandbox
  and the endpoint are the test's own).
  """
  def render(id, ctx)

  # /ops with one allowlisted schema and no configured backend (the first Control room test).
  def render("control_room.default", %{conn: conn}) do
    ControlRoomStubs.with_env(fn ->
      Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostA])
      {:ok, _lv, html} = live(conn, "/ops")
      html
    end)
  end

  # /ops after a healthy first check, when a refresh fails: the earlier observation stays on
  # screen as the last one that succeeded.
  def render("control_room.refresh_retained", %{conn: conn}) do
    ControlRoomStubs.with_env(fn ->
      ControlRoomStubs.put_healthy_posture!()
      {:ok, lv, _html} = live(conn, "/ops")
      Application.put_env(:scrypath_ops, :control_room_client_state, :unavailable)
      lv |> element("#control-room-refresh") |> render_click()
      render(lv)
    end)
  end

  # /ops after a first check that found nothing pending, retrying or failed: the verdict says Clear.
  def render("control_room.healthy", %{conn: conn}) do
    ControlRoomStubs.with_env(fn ->
      ControlRoomStubs.put_healthy_posture!()
      {:ok, _lv, html} = live(conn, "/ops")
      html
    end)
  end

  # /ops after a first check that found failed work, when a refresh fails: the earlier
  # observation stays on screen and keeps its Failed word (only Clear is dropped beside it).
  def render("control_room.refresh_retained_degraded", %{conn: conn}) do
    ControlRoomStubs.with_env(fn ->
      ControlRoomStubs.put_degraded_posture!()
      {:ok, lv, _html} = live(conn, "/ops")
      Application.put_env(:scrypath_ops, :control_room_client_state, :unavailable)
      lv |> element("#control-room-refresh") |> render_click()
      render(lv)
    end)
  end

  # /ops when the first check already fails and a refresh fails too: no prior observation.
  def render("control_room.refresh_no_prior", %{conn: conn}) do
    ControlRoomStubs.with_env(fn ->
      ControlRoomStubs.put_healthy_posture!()
      Application.put_env(:scrypath_ops, :control_room_client_state, :unavailable)
      {:ok, lv, _html} = live(conn, "/ops")
      lv |> element("#control-room-refresh") |> render_click()
      render(lv)
    end)
  end

  # /ops/failed-sync right after the operator retried one failed job: the receipt and the flash
  # that report the retry are both on screen.
  def render("failed_sync.after_retry", %{conn: conn}),
    do: FailedSyncStubs.render_after_retry(conn)

  # /ops/failed-sync for the Shopadelic failed journey after the operator pressed Retry on the failed
  # delete (job 104): the confirmation dialog is open over the page.
  def render("failed_sync.delete_confirmation", %{conn: conn}) do
    with_scenario(:shopadelic_failed_journey, fn ->
      {:ok, lv, _html} = live(conn, "/ops/failed-sync")
      _ = render_async(lv)

      lv
      |> element("button[data-testid='failed-sync-retry'][phx-value-id='104']")
      |> render_click()
    end)
  end

  # /ops/failed-sync when the schema's task history is over its limit: the check could not finish, so
  # the page says that instead of listing failed work.
  def render("failed_sync.scoped_load_error", %{conn: conn}) do
    with_scenario(:logistify_history_over_limit_f1, fn ->
      {:ok, lv, _html} = live(conn, "/ops/failed-sync")
      render_async(lv)
    end)
  end

  # /ops/health for the Shopadelic failed journey: failed jobs and a failed Meilisearch task.
  def render("posture.shopadelic_degraded", %{conn: conn}) do
    with_scenario(:shopadelic_failed_journey, fn ->
      {:ok, lv, _html} = live(conn, "/ops/health")
      render_async(lv)
    end)
  end

  # /ops/health with one unreadable and one clear schema (the default Search health test).
  def render("posture.default", %{conn: conn}) do
    PostureStubs.with_stubs(fn ->
      {:ok, _lv, html} = live(conn, "/ops/health")
      html
    end)
  end

  # One Search health row after a refresh failed: its source-local times are retained.
  def render("posture.failed_row_retained", %{conn: conn}) do
    PostureStubs.with_stubs(fn ->
      {:ok, lv, _html} = live(conn, "/ops/phase173/health?scenario=refresh-failure")
      lv |> element("#search-health-refresh") |> render_click()
      lv |> element("[id='posture-ScrypathOps.Phase173FixtureSchema']") |> render()
    end)
  end

  # /ops/sync-and-index as it loads, after its settings and sync checks finish.
  def render("sync_drift.default", %{conn: conn}) do
    SyncDriftStubs.with_stubs(fn ->
      {:ok, lv, _html} = live(conn, "/ops/sync-and-index")
      render_async(lv)
    end)
  end

  # /ops/sync-and-index when a later sync check failed but an earlier result is retained. A
  # route cannot reach this state, so a mounted view's own assigns are merged with the error and
  # rendered through `SyncDriftLive.render/1` (a hand-built socket lacks assigns the layout reads).
  def render("sync_drift.reconcile_error_retained", %{conn: conn}) do
    SyncDriftStubs.with_stubs(fn ->
      {:ok, lv, _html} = live(conn, "/ops/sync-and-index?schema=ScrypathOps.Test.OpsPostA")
      render_async(lv)

      lv.pid
      |> :sys.get_state()
      |> Map.fetch!(:socket)
      |> Map.fetch!(:assigns)
      |> Map.put(:reconcile_error, :backend_unreachable)
      |> SyncDriftLive.render()
      |> Phoenix.HTML.Safe.to_iodata()
      |> IO.iodata_to_binary()
    end)
  end

  # /ops/sync-and-index when the live index lacks a field the schema declares as searchable.
  def render("sync_drift.settings_missing_field", %{conn: conn}) do
    SyncDriftStubs.with_stubs(fn ->
      Agent.update(SyncDriftStubs.state_name(), fn state ->
        Map.put(state, :applied_settings, %{
          "searchableAttributes" => ["other"],
          "filterableAttributes" => [],
          "sortableAttributes" => []
        })
      end)

      {:ok, lv, _html} = live(conn, "/ops/sync-and-index")
      render_async(lv)
    end)
  end

  # /ops/sync-and-index with one job waiting in the queue and one scheduled to retry.
  def render("sync_drift.queue_pending", %{conn: conn}) do
    SyncDriftStubs.with_stubs(fn ->
      SyncDriftStubs.put_oban_env(SyncDriftStubs.pending_and_retrying_jobs())
      {:ok, lv, _html} = live(conn, "/ops/sync-and-index")
      render_async(lv)
    end)
  end

  # /ops/sync-and-index when the queue was observed and holds nothing.
  def render("sync_drift.caught_up", %{conn: conn}) do
    SyncDriftStubs.with_stubs(fn ->
      SyncDriftStubs.put_oban_env()
      {:ok, lv, _html} = live(conn, "/ops/sync-and-index")
      render_async(lv)
    end)
  end

  # The promotion notice when pending sync work blocks the swap. A prepared target index is
  # observed first (the stub's ready state), so the promotion block is on the page; the blocked
  # eligibility is then merged into the mounted view's own assigns.
  def render("sync_drift.promotion_blocked_queue", %{conn: conn}) do
    SyncDriftStubs.with_stubs(fn ->
      Agent.update(SyncDriftStubs.state_name(), &Map.put(&1, :ready, true))

      render_with_assigns(conn, "/ops/sync-and-index?schema=ScrypathOps.Test.OpsPostA", %{
        promotion_eligibility: {:blocked, :queue_work_pending}
      })
    end)
  end

  # The retry status block after a retry reached the host queue and its recovery was observed.
  def render("sync_drift.recovery_queued", %{conn: conn}) do
    SyncDriftStubs.with_stubs(fn ->
      render_with_assigns(conn, "/ops/sync-and-index?schema=ScrypathOps.Test.OpsPostA", %{
        recovery_handle: "opaque-receipt",
        recovery_status: :accepted,
        recovery_evidence: %{
          replacement_job: 991,
          attempt: 1,
          task_uid: nil,
          index: "sdv_ops_post_a"
        }
      })
    end)
  end

  # The retry status block when the handle in the URL cannot be resolved (an expired receipt, another
  # node or another organization): the page says the outcome could not be checked and shows no job.
  def render("sync_drift.recovery_unavailable", %{conn: conn}) do
    SyncDriftStubs.with_stubs(fn ->
      {:ok, lv, _html} =
        live(
          conn,
          "/ops/sync-and-index?schema=ScrypathOps.Test.OpsPostA" <>
            "&recovery=expired-or-other-node-handle&recovery_generation=0"
        )

      render_async(lv)
    end)
  end

  # The retry status block once the retry's task and its expected documents were observed.
  def render("sync_drift.recovery_verified", %{conn: conn}) do
    SyncDriftStubs.with_stubs(fn ->
      checked_at = ScrypathOps.Clock.utc_now()

      render_with_assigns(conn, "/ops/sync-and-index?schema=ScrypathOps.Test.OpsPostA", %{
        recovery_handle: "opaque-receipt",
        recovery_status: :verified,
        recovery_evidence: %{
          replacement_job: 991,
          attempt: 1,
          task_uid: 44,
          index: "sdv_ops_post_a"
        },
        recovery_document_observation: %{
          state: :verified,
          reason: nil,
          checked_at: checked_at,
          operation: :upsert,
          index: "sdv_ops_post_a",
          expected_ids: ["post-6001"]
        },
        recovery_checked_at: checked_at
      })
    end)
  end

  # The promotion result once Meilisearch has taken the index swap task.
  def render("sync_drift.promotion_accepted", %{conn: conn}) do
    SyncDriftStubs.with_stubs(fn ->
      render_with_assigns(conn, "/ops/sync-and-index?schema=ScrypathOps.Test.OpsPostA", %{
        promotion_task_id: 991,
        promotion_status: :accepted,
        promotion_loading: true
      })
    end)
  end

  # Runs `fun` with one fictional adopter scenario in the app env (the clock reads the scenario's
  # instant) and restores the env after, whatever `fun` does.
  defp with_scenario(id, fun) do
    scenario = ScrypathFixtures.Scenarios.get!(id, ScrypathFixtures.preview_epoch())
    restore = FixtureEnv.put(scenario)

    try do
      fun.()
    after
      restore.()
    end
  end

  # A route cannot reach these states, so a mounted view's own assigns are merged with the
  # override and rendered through `SyncDriftLive.render/1` (a hand-built socket lacks assigns the
  # layout reads).
  defp render_with_assigns(conn, path, overrides) do
    {:ok, lv, _html} = live(conn, path)
    render_async(lv)

    lv.pid
    |> :sys.get_state()
    |> Map.fetch!(:socket)
    |> Map.fetch!(:assigns)
    |> Map.merge(overrides)
    |> SyncDriftLive.render()
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end
end
