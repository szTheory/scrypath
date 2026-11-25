defmodule ScrypathOpsWeb.PostureLiveTest do
  @moduledoc false
  # Phase 47 D-10: prod fail-closed `/ops` boot is `OPSUI_AUTH_MODE` + `Application`
  # (`scrypath_ops/docs/SECURITY.md`, `config_prod_guard_test.exs`). D-12: mixed
  # `{:ok, _}` / `{:error, _}` rows surface per-row errors (no fleet-level “all healthy”).
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScrypathOps.Test.FixtureEnv
  alias ScrypathOps.Test.HtmlCanon
  alias ScrypathOpsWeb.Components.SearchHealth
  alias ScrypathOps.Test.CopyStubs.Posture, as: PostureStubs
  alias ScrypathOps.Test.CopyStubs.Posture.FakeClient, as: PostureFakeClient
  alias ScrypathOps.Test.OpsPostA
  alias ScrypathOps.Test.OpsPostB
  alias ScrypathOps.Integrations.Sigra.OperatorContext
  alias ScrypathOps.Posture
  alias ScrypathOpsWeb.OpsUi
  alias ScrypathOpsWeb.PostureLive

  @fixture_row "[id='posture-ScrypathOps.Phase173FixtureSchema']"
  @status_words ~w(Failed Retrying Pending Clear)
  @condition_words ["Not observed", "Not checked", "Queue not used", "Unavailable"]

  setup do
    previous = PostureStubs.put_env()
    PostureStubs.start_agent()

    on_exit(fn ->
      PostureStubs.restore_env(previous)
      PostureStubs.stop_agent()
    end)

    :ok
  end

  test "renders posture rows with sync_status and surfaces errors first", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/ops/health")

    assert html =~ "data-testid=\"posture-row\""

    assert html =~
             "Search health could not be checked: A configured search health source could not be read. Refresh health to try again."

    refute html =~ ":boom"

    # The row that could not be read says so in Ink with the condition word beside it: no icon,
    # no error color, no status word.
    error_row = lv |> element("[id='posture-ScrypathOps.Test.OpsPostA']") |> render()
    assert error_row =~ ~s(data-condition="Not checked")
    refute error_row =~ "text-error"
    refute error_row =~ "<svg"
    refute error_row =~ "data-sync-status"

    assert html =~ "Queue not used"
    assert html =~ ~s(class="text-ops-body ops-muted")
    assert html =~ "Meilisearch document tasks"
    assert html =~ "Manual sync"
    assert html =~ "Last succeeded"
    refute html =~ "Posture"
    assert has_element?(lv, "[data-ops-refresh][aria-label='Refresh search health']")

    # The unreadable row is unverified, so it ranks above the clear row (OpsPostB, manual sync).
    assert row_ids(html) == [
             "posture-ScrypathOps.Test.OpsPostA",
             "posture-ScrypathOps.Test.OpsPostB"
           ]
  end

  test "degraded search health shows its failures as status words, not badges", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/ops/phase173/health?scenario=failed")
    row = lv |> element("[id='posture-ScrypathOps.Phase173FixtureSchema']") |> render()

    assert html =~ "Sync jobs and Meilisearch tasks failed"

    # The verdict follows the worst row (LD-10): a failed row makes it an error, with the word.
    assert has_element?(lv, ".ops-verdict[data-verdict-kind='error'] [data-sync-status='failed']")
    refute html =~ "ops-verdict-icon"

    # The row header and both failing source groups say Failed through the shared component.
    assert has_element?(
             lv,
             "#{@fixture_row} .ops-schema-signal-card__badges [data-sync-status='failed']"
           )

    assert has_element?(lv, "#{@fixture_row} [data-tone='error'] [data-sync-status='failed']")
    refute has_element?(lv, ".ops-badge")
    refute row =~ "Meilisearch tasks failed"
    refute row =~ "Sync jobs failed"
    refute html =~ "ops-metric-success"
    refute row =~ "ops-schema-signal-card--warning"
    refute row =~ "ops-schema-signal-card--error"
  end

  test "healthy Search health says Clear because it observed both sources", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/ops/phase173/health?scenario=healthy")
    row = lv |> element("[id='posture-ScrypathOps.Phase173FixtureSchema']") |> render()

    assert html =~ "Search health"
    assert has_element?(lv, ".ops-verdict.ops-posture-verdict")

    assert has_element?(
             lv,
             ".ops-verdict[data-verdict-kind='neutral'] [data-sync-status='clear']"
           )

    assert has_element?(
             lv,
             "#{@fixture_row} .ops-schema-signal-card__badges [data-sync-status='clear']"
           )

    refute row =~ "backend clear"
    refute row =~ "queue observed"
    refute has_element?(lv, ".ops-badge")
  end

  # Phase 187 SKIN-08 / E-19: the capture fixture. The capture command is given this exact
  # scenario, so the status vocabulary cannot be missing from the captured screen.
  describe "the all-statuses capture fixture (E-19)" do
    @all_statuses_path "/ops/phase173/health?scenario=all-statuses"
    @capture_script Path.expand(
                      "../../../../examples/scrypath_ecommerce/scripts/reskin-capture.mjs",
                      __DIR__
                    )

    test "renders every status word with its shape and a condition word", %{conn: conn} do
      {:ok, lv, html} = live(conn, @all_statuses_path)
      doc = LazyHTML.from_fragment(html)

      assert doc |> LazyHTML.query("[data-testid='posture-row']") |> Enum.count() == 5

      statuses = LazyHTML.query(doc, "[data-sync-status]")

      assert statuses |> LazyHTML.attribute("data-sync-status") |> Enum.uniq() |> Enum.sort() ==
               ["clear", "failed", "pending", "retrying"]

      for {status, word, shape} <- [
            {"failed", "Failed", "notched"},
            {"retrying", "Retrying", "bottom-filled"},
            {"pending", "Pending", "hollow"},
            {"clear", "Clear", "filled"}
          ] do
        matches = LazyHTML.query(doc, "[data-sync-status='#{status}']")
        assert Enum.count(matches) >= 1

        for match <- matches do
          assert match |> LazyHTML.query(".ops-sync-status__word") |> LazyHTML.text() == word
          assert match |> LazyHTML.query("svg") |> LazyHTML.attribute("data-shape") == [shape]
        end
      end

      conditions = doc |> LazyHTML.query(".ops-condition") |> Enum.map(&LazyHTML.text/1)
      assert conditions != []
      assert Enum.all?(conditions, &(&1 in @condition_words))

      assert has_element?(lv, "#phase173-fixture-scenario option[value='all-statuses'][selected]")
    end

    test "each row carries its own state and its text", %{conn: conn} do
      {:ok, lv, _html} = live(conn, @all_statuses_path)

      failed = row_html(lv, "Phase173FixtureSchema")
      assert row_header_status(failed) == "failed"
      refute failed =~ "Jobs retrying"

      retrying = row_html(lv, "Phase173RetryingSchema")
      assert row_header_status(retrying) == "retrying"
      refute retrying =~ ~s(data-sync-status="failed")

      pending = row_html(lv, "Phase173PendingSchema")
      assert row_header_status(pending) == "pending"
      refute pending =~ ~s(data-sync-status="failed")
      refute pending =~ ~s(data-sync-status="retrying")
      refute pending =~ "No pending or failed tasks."

      clear = row_html(lv, "Phase173ClearSchema")
      assert row_header_status(clear) == "clear"
      assert clear =~ "No pending or failed tasks."
      assert clear =~ "No pending, retrying or failed jobs."
      refute clear =~ ~s(data-sync-status="failed")

      unreadable = row_html(lv, "Phase173PartialSchema")
      assert unreadable =~ ~s(data-condition="Not checked")
      assert unreadable =~ "Search health could not be checked"
      refute unreadable =~ "data-sync-status"
    end

    test "the capture command is given exactly this scenario" do
      script = File.read!(@capture_script)

      assert [_, scenario] = Regex.run(~r/export const SCENARIO = "([^"]+)";/, script)
      assert scenario == "all-statuses"
      assert @all_statuses_path =~ "scenario=#{scenario}"
    end
  end

  test "phase173 fixture ignores an unknown scenario and keeps the healthy rows", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/ops/phase173/health?scenario=not-a-scenario")

    rows = html |> LazyHTML.from_fragment() |> LazyHTML.query("[data-testid='posture-row']")
    assert Enum.count(rows) == 1
    assert has_element?(lv, "#phase173-fixture-scenario option[value='healthy'][selected]")
    refute has_element?(lv, "#phase173-fixture-scenario option[value='all-statuses'][selected]")
  end

  describe "Search health rows render the shared status component (E-02)" do
    test "every rendered dt holds one status and its count stays in the dd", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/ops/phase173/health?scenario=failed")
      row = lv |> element(@fixture_row) |> render() |> LazyHTML.from_fragment()

      dts = LazyHTML.query(row, ".ops-signal-counts dt")
      assert Enum.count(dts) == 2

      for dt <- dts do
        assert dt |> LazyHTML.query("[data-sync-status]") |> Enum.count() == 1
      end

      # One status icon in every dt: the mandatory closeout-attestation case compares these counts.
      assert row |> LazyHTML.query(".ops-signal-counts dt svg") |> Enum.count() == Enum.count(dts)

      counts =
        row
        |> LazyHTML.query(".ops-signal-counts dd")
        |> Enum.map(&String.trim(LazyHTML.text(&1)))

      assert counts == ["1", "1"]
    end

    test "the data-tone wrappers that the closeout cases read survive", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/ops/phase173/health?scenario=failed")
      assert has_element?(lv, "#{@fixture_row} .ops-signal-counts [data-tone='error']", "Failed")
      refute has_element?(lv, "#{@fixture_row} .ops-signal-counts [data-tone='retrying']")

      {:ok, lv, _html} = live(conn, ~p"/ops/phase173/health?scenario=retrying")

      assert has_element?(
               lv,
               "#{@fixture_row} .ops-signal-counts [data-tone='retrying']",
               "Retrying"
             )

      refute has_element?(lv, "#{@fixture_row} .ops-signal-counts [data-tone='error']")
    end

    test "no badge ever spells a status word", %{conn: conn} do
      for scenario <- ~w(healthy failed retrying all-statuses unavailable queue-unused partial) do
        {:ok, lv, html} = live(conn, "/ops/phase173/health?scenario=#{scenario}")

        badge_words =
          html
          |> LazyHTML.from_fragment()
          |> LazyHTML.query(".ops-badge")
          |> Enum.map(&String.trim(LazyHTML.text(&1)))

        assert Enum.all?(badge_words, &(&1 not in @status_words)),
               "#{scenario}: #{inspect(badge_words)}"

        assert has_element?(lv, ".ops-verdict")
      end
    end

    test "each row has a source-attributed facts line", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/ops/phase173/health?scenario=all-statuses")

      retrying = facts_text(row_html(lv, "Phase173RetryingSchema"))
      assert retrying =~ "Queue 1 retrying, no completed job in available history"
      assert retrying =~ "· Meilisearch 0 pending, no completed task in available history"

      failed = facts_text(row_html(lv, "Phase173FixtureSchema"))
      assert failed =~ "Meilisearch 1 failed"

      pending = facts_text(row_html(lv, "Phase173PendingSchema"))
      assert pending =~ "Meilisearch 1 pending"

      {:ok, lv, _html} = live(conn, ~p"/ops/phase173/health?scenario=healthy")
      healthy = row_html(lv, "Phase173FixtureSchema")
      # The label and the time are separate flex items, so their text has no space between them.
      assert facts_text(healthy) =~
               ~r/Queue 0 pending, last succeeded\s*Oct 5, 2026 at 15:12:13 UTC/

      assert facts_text(healthy) =~
               ~r/Meilisearch 0 pending, last succeeded\s*Oct 4, 2026 at 17:02:05 UTC/

      assert healthy
             |> LazyHTML.from_fragment()
             |> LazyHTML.query("[data-testid='posture-facts'] time")
             |> Enum.count() == 2
    end

    test "the facts line repeats a time as plain text, so each exact time has one copy control",
         %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/ops/phase173/health?scenario=healthy")
      healthy = row_html(lv, "Phase173FixtureSchema")
      fragment = LazyHTML.from_fragment(healthy)

      # No copy button inside the facts line, and its times keep the exact value and the mono face.
      assert fragment
             |> LazyHTML.query("[data-testid='posture-facts'] [data-ops-timestamp-copy]")
             |> Enum.count() == 0

      assert fragment
             |> LazyHTML.query("[data-testid='posture-facts'] time.ops-time__value[datetime]")
             |> Enum.count() == 2

      # Every exact value is offered for copying exactly once in the row (the source groups).
      copy_values =
        fragment
        |> LazyHTML.query("[data-ops-timestamp-copy]")
        |> Enum.map(&(&1 |> LazyHTML.attribute("data-ops-timestamp-copy") |> List.first()))

      assert copy_values != []
      assert copy_values == Enum.uniq(copy_values)
    end
  end

  describe "conditions are plain muted words (E-03)" do
    test "an unreadable row and an unused queue say so without an icon or a status", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/ops/phase173/health?scenario=all-statuses")
      unreadable = row_html(lv, "Phase173PartialSchema")

      assert condition_words(unreadable) == ["Not checked"]
      refute unreadable =~ "data-sync-status"

      {:ok, lv, _html} = live(conn, ~p"/ops/phase173/health?scenario=queue-unused")
      unused = row_html(lv, "Phase173FixtureSchema")

      assert "Queue not used" in condition_words(unused)
      assert row_header_status(unused) == "clear"
    end

    test "a condition word carries no svg and no icon class", %{conn: conn} do
      for scenario <- ~w(all-statuses queue-unused unavailable) do
        {:ok, _lv, html} = live(conn, "/ops/phase173/health?scenario=#{scenario}")
        conditions = html |> LazyHTML.from_fragment() |> LazyHTML.query(".ops-condition")

        assert Enum.count(conditions) >= 1

        for condition <- conditions do
          assert Enum.count(LazyHTML.query(condition, "svg")) == 0
          refute LazyHTML.to_html(condition) =~ "hero-"
          assert String.trim(LazyHTML.text(condition)) in @condition_words
        end
      end
    end
  end

  describe "Clear needs an observation (E-04)" do
    test "observed-empty and queue-not-used rows are Clear; a zero from an unobserved source is not" do
      assert Posture.row_status({:ok, status(mode: :oban, observed?: true)}) == :clear
      assert Posture.row_status({:ok, status(mode: :inline, observed?: false)}) == :clear
      assert Posture.row_status({:ok, status(mode: :manual, observed?: false)}) == :clear
      assert Posture.row_status({:ok, status(mode: "manual", observed?: false)}) == :clear

      # A queue that the sync mode says should have been observed, but was not: every list is
      # zero, and that zero is not evidence.
      assert Posture.row_status({:ok, status(mode: :oban, observed?: false)}) ==
               {:condition, "Not observed"}

      # A row that could not be read at all.
      assert Posture.row_status({:error, :backend_unavailable}) == {:condition, "Not checked"}
    end

    test "observed work outranks a missing queue observation" do
      unobserved = [mode: :oban, observed?: false]

      assert Posture.row_status({:ok, status([backend_pending: [:t]] ++ unobserved)}) == :pending
      assert Posture.row_status({:ok, status([backend_failed: [:t]] ++ unobserved)}) == :failed
    end

    test "a row shows its most urgent status" do
      everything = [
        backend_failed: [:t],
        backend_pending: [:t],
        queue: %{failed: [:j], retrying: [:j], pending: [:j]}
      ]

      assert Posture.row_status({:ok, status(everything)}) == :failed

      retrying_and_pending = [backend_pending: [:t], queue: %{retrying: [:j], pending: [:j]}]
      assert Posture.row_status({:ok, status(retrying_and_pending)}) == :retrying

      assert Posture.row_status({:ok, status(queue: %{pending: [:j]})}) == :pending
      assert Posture.row_status({:ok, status(queue: %{failed: [:j]})}) == :failed
    end

    test "a queue that was not observed never renders Clear on the page", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/ops/phase173/health?scenario=healthy")

      row = {ScrypathOps.Phase173FixtureSchema, {:ok, status(mode: :oban, observed?: false)}}

      # The verdict reads the posture summary (the shared component takes one view-model), so the
      # injected state is a coherent summary built by the pure builder, with the ranked row list
      # the rows section reads alongside it.
      summary = Posture.build([row], ScrypathOps.Clock.utc_now(), nil)
      put_live_assigns(lv, posture_rows: {:ok, [row]}, posture_summary: summary)
      render_patch(lv, ~p"/ops/phase173/health?scenario=healthy")

      html = lv |> element(@fixture_row) |> render()
      assert "Not observed" in condition_words(html)

      # The row header says Not observed instead of a status, and the queue group, the source
      # that was not observed, never says Clear. The backend was observed and is empty.
      refute has_element?(
               lv,
               "#{@fixture_row} .ops-schema-signal-card__badges [data-sync-status]"
             )

      assert has_element?(lv, "#{@fixture_row} .ops-schema-signal-card__badges .ops-condition")

      refute has_element?(
               lv,
               "#{@fixture_row} [aria-label^='Queue job signals'] [data-sync-status]"
             )

      refute html
             |> LazyHTML.from_fragment()
             |> LazyHTML.query("[data-testid='posture-facts'] [data-sync-status]")
             |> Enum.any?()

      refute has_element?(lv, ".ops-verdict [data-sync-status]")
      assert has_element?(lv, ".ops-verdict[data-verdict-kind='warning']")
    end
  end

  describe "ranking (E-05)" do
    test "failed, retrying, pending, unverified, clear, then module name" do
      rows = [
        {Clear.B, {:ok, status(mode: :oban, observed?: true)}},
        {Clear.A, {:ok, status(mode: :manual, observed?: false)}},
        {Pending.A, {:ok, status(backend_pending: [:t])}},
        {Retrying.A, {:ok, status(queue: %{retrying: [:j]})}},
        {Failed.B, {:ok, status(backend_failed: [:t])}},
        {Failed.A, {:ok, status(queue: %{failed: [:j]})}},
        {Unverified.NotObserved, {:ok, status(mode: :oban, observed?: false)}},
        {Unverified.Error, {:error, :boom}}
      ]

      expected = [
        Failed.A,
        Failed.B,
        Retrying.A,
        Pending.A,
        Unverified.Error,
        Unverified.NotObserved,
        Clear.A,
        Clear.B
      ]

      assert rows |> Posture.sort_by_urgency() |> Enum.map(&elem(&1, 0)) == expected

      assert rows |> Enum.reverse() |> Posture.sort_by_urgency() |> Enum.map(&elem(&1, 0)) ==
               expected
    end

    test "the page orders the fixture rows by urgency", %{conn: conn} do
      {:ok, _lv, html} = live(conn, @all_statuses_path)

      assert row_ids(html) == [
               "posture-ScrypathOps.Phase173FixtureSchema",
               "posture-ScrypathOps.Phase173RetryingSchema",
               "posture-ScrypathOps.Phase173PendingSchema",
               "posture-ScrypathOps.Phase173PartialSchema",
               "posture-ScrypathOps.Phase173ClearSchema"
             ]
    end

    test "rows re-sort only when a refresh brings new evidence", %{conn: conn} do
      {:ok, lv, html} = live(conn, @all_statuses_path)
      ranked = row_ids(html)
      {:ok, rows} = :sys.get_state(lv.pid).socket.assigns.posture_rows

      # Evidence changes in the assigns without a refresh: the page keeps the order it was given
      # instead of re-ranking itself while an operator reads it.
      put_live_assigns(lv, posture_rows: {:ok, Enum.reverse(rows)})
      render_patch(lv, @all_statuses_path)
      assert lv |> render() |> row_ids() == Enum.reverse(ranked)

      # A refresh reloads the evidence and ranks it again.
      lv |> element("#search-health-refresh") |> render_click()
      assert lv |> render() |> row_ids() == ranked
    end
  end

  describe "verdicts show the worst row status (E-06)" do
    test "worst status and kind follow LD-10" do
      clear = {A, {:ok, status(mode: :manual, observed?: false)}}
      pending = {B, {:ok, status(backend_pending: [:t])}}
      unverified = {C, {:error, :boom}}
      retrying = {D, {:ok, status(queue: %{retrying: [:j]})}}
      failed = {E, {:ok, status(backend_failed: [:t])}}

      for {rows, worst, kind} <- [
            {[clear, clear], :clear, :neutral},
            {[clear, pending], :pending, :neutral},
            {[clear, unverified], nil, :warning},
            {[pending, unverified], :pending, :warning},
            {[clear, retrying, pending], :retrying, :warning},
            {[unverified, failed, retrying], :failed, :error},
            {[], nil, :neutral}
          ] do
        assert Posture.worst_status(rows) == worst, inspect(rows)
        assert Posture.verdict_kind(rows) == kind, inspect(rows)
      end
    end

    test "the verdict names the worst row, and Clear only when every row is clear", %{conn: conn} do
      {:ok, lv, _html} = live(conn, @all_statuses_path)

      assert has_element?(
               lv,
               ".ops-verdict[data-verdict-kind='error'] [data-sync-status='failed']"
             )

      refute has_element?(lv, ".ops-verdict [data-sync-status='clear']")
      refute has_element?(lv, "[data-testid='ops-verdict-icon']")

      {:ok, lv, _html} = live(conn, ~p"/ops/phase173/health?scenario=retrying")

      assert has_element?(
               lv,
               ".ops-verdict[data-verdict-kind='warning'] [data-sync-status='retrying']"
             )

      {:ok, lv, _html} = live(conn, ~p"/ops/phase173/health?scenario=healthy")

      assert has_element?(
               lv,
               ".ops-verdict[data-verdict-kind='neutral'] [data-sync-status='clear']"
             )
    end

    test "an unreadable row keeps the verdict from saying Clear", %{conn: conn} do
      for scenario <- ~w(unavailable partial) do
        {:ok, lv, _html} = live(conn, "/ops/phase173/health?scenario=#{scenario}")

        assert has_element?(lv, ".ops-verdict[data-verdict-kind='warning']"), scenario
        refute has_element?(lv, ".ops-verdict [data-sync-status]"), scenario
      end
    end
  end

  test "refresh without configured schemas does not report a successful observation", %{
    conn: conn
  } do
    attach_posture_refresh_telemetry()
    {:ok, lv, _html} = live(conn, ~p"/ops/phase173/health?scenario=empty")

    lv |> element("#search-health-refresh") |> render_click()

    assert_receive {:posture_refresh, %{schema_count: 0}, %{outcome: :degraded}}
    refute render(lv) =~ "Search health refreshed."
  end

  test "refresh without a backend does not report a successful observation", %{conn: conn} do
    Application.delete_env(:scrypath_ops, :backend)
    attach_posture_refresh_telemetry()
    {:ok, lv, html} = live(conn, ~p"/ops/health")

    assert html =~ "Runtime not configured"

    lv |> element("#search-health-refresh") |> render_click()

    assert_receive {:posture_refresh, %{schema_count: 2}, %{outcome: :degraded}}
    refute render(lv) =~ "Search health refreshed."
  end

  test "refresh disabled eligibility follows a server-rendered fixture patch", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/ops/phase173/health?scenario=healthy")

    refresh = "#search-health-refresh"
    assert has_element?(lv, "#{refresh}[data-ops-refresh-eligible='true']:not([disabled])")

    lv
    |> element("#phase173-fixture-controls")
    |> render_change(%{"scenario" => "refresh-disabled"})

    assert has_element?(lv, "#{refresh}[data-ops-refresh-eligible='false'][disabled]")

    lv
    |> element("#phase173-fixture-controls")
    |> render_change(%{"scenario" => "healthy"})

    assert has_element?(lv, "#{refresh}[data-ops-refresh-eligible='true']:not([disabled])")
  end

  test "renders production last-success evidence from its successful observation snapshot", %{
    conn: conn
  } do
    {:ok, lv, _html} = live(conn, ~p"/ops/phase173/health")

    iso = "2026-10-04T13:02:05.123456-04:00"

    row =
      lv
      |> element("[id='posture-ScrypathOps.Phase173FixtureSchema']")
      |> render()

    assert row =~ "2 days ago"
    assert row =~ ~s(datetime="#{iso}")
    assert row =~ iso
    assert row =~ "Oct 4, 2026 at 17:02:05 UTC"
    refute row =~ "Exact timestamp"
    assert row =~ ~s(data-ops-timestamp-copy="#{iso}")
    # Accessible name = visible time + hidden "copy timestamp"; an aria-label would drop the
    # visible text the hook rewrites for local time (axe label-content-name-mismatch).
    refute row =~ ~s(aria-label="Copy timestamp)
    assert row =~ "copy timestamp</span>"
    refute row =~ ~s(data-ops-timestamp-message)
    assert has_element?(lv, "[data-ops-client-toast]")
  end

  test "keeps prior source-local timestamps when a later refresh is unavailable", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/ops/phase173/health?scenario=refresh-failure")
    row_selector = "[id='posture-ScrypathOps.Phase173FixtureSchema']"
    first_row = lv |> element(row_selector) |> render()
    iso = "2026-10-04T13:02:05.123456-04:00"

    assert first_row =~ "2 days ago"
    assert first_row =~ iso

    lv |> element("#search-health-refresh") |> render_click()
    failed_row = lv |> element(row_selector) |> render()

    assert failed_row =~
             "Search health could not be checked: A configured search health source could not be read. Refresh health to try again."

    refute failed_row =~ "phase173_backend_unavailable"

    assert failed_row =~ ~s(data-condition="Not checked")
    refute failed_row =~ "text-error"
    refute failed_row =~ "data-sync-status"

    assert failed_row =~ "2 days ago"
    assert failed_row =~ iso
    assert failed_row =~ ~s(data-ops-timestamp-copy="#{iso}")
    assert failed_row =~ "source-local evidence is retained from check 2026-10-06T17:18:42.318Z"
    assert failed_row =~ "Meilisearch last succeeded"
    assert failed_row =~ "Queue last succeeded"

    # Each retained label sits beside the retained time of its own source, not beside a bare or
    # empty value (190 review WR-05; the old-label guard is the `last-succeeded` table row).
    assert failed_row =~
             ~r/Meilisearch last succeeded<\/dt>\s*<dd>\s*<span id="posture-time-retained-backend-[^"]+"/

    assert failed_row =~
             ~r/Queue last succeeded<\/dt>\s*<dd>\s*<span id="posture-time-retained-queue-[^"]+"/

    refute render(lv) =~ "Search health refreshed."
  end

  test "preserves schema identity and retained evidence when a scan task exits", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/ops/health")
    schema = "ScrypathOps.Test.OpsPostB"
    row_selector = "[id='posture-#{schema}']"
    iso = "2026-04-16T18:00:00Z"

    first_row = lv |> element(row_selector) |> render()
    assert first_row =~ iso

    Agent.update(:posture_live_test_state, fn state ->
      Map.put(state, :exit_index, "postlv_ops_post_b")
    end)

    lv |> element("#search-health-refresh") |> render_click()

    failed_row = lv |> element(row_selector) |> render()

    assert failed_row =~
             "Search health could not be checked: A configured search health source could not be read. Refresh health to try again."

    refute failed_row =~ "posture_backend_exit"
    assert failed_row =~ iso
    assert failed_row =~ "source-local evidence is retained"
    refute has_element?(lv, "a[href='/ops/failed-sync?schema=#{schema}']")
    refute has_element?(lv, "#posture-posture_stream")
  end

  test "operational age thresholds use the observation snapshot and full precision" do
    {:ok, snapshot_at, _offset} = DateTime.from_iso8601("2026-10-06T13:18:42.318-04:00")

    for {seconds, expected} <- [
          {59, "just now"},
          {60, "1 min ago"},
          {3_599, "59 mins ago"},
          {3_600, "1 hr ago"},
          {86_399, "23 hrs ago"},
          {86_400, "1 day ago"},
          {604_799, "6 days ago"},
          {604_800, "Sep 29, 2026 at 17:18:42 UTC"}
        ] do
      dt = DateTime.add(snapshot_at, -seconds, :second)
      html = render_time(dt, snapshot_at)
      assert html =~ expected
    end

    microsecond_future = DateTime.add(snapshot_at, 1, :microsecond)
    future_html = render_time(microsecond_future, snapshot_at)
    assert future_html =~ "After this check"
    assert future_html =~ "Oct 6, 2026 at 17:18:42 UTC"
  end

  test "operational no-time and unavailable states remain distinct and have no evidence control" do
    {:ok, snapshot_at, _offset} = DateTime.from_iso8601("2026-10-06T13:18:42.318-04:00")

    for state_text <- [
          "No success observed",
          "Success time not observed",
          "Not observed: :backend_unavailable",
          "Queue not used"
        ] do
      html = render_time(nil, snapshot_at, state_text)
      assert html =~ state_text
      refute html =~ "<details"
      refute html =~ "copy timestamp"
      refute html =~ "data-ops-timestamp-copy"
    end
  end

  test "unmatched source ISO is not used as timestamp evidence" do
    {:ok, dt, _offset} = DateTime.from_iso8601("2026-10-04T13:02:05.123456-04:00")
    mismatched_iso = "2026-10-05T11:12:13.456-04:00"

    html =
      render_component(&OpsUi.ops_time/1, %{
        dt: dt,
        snapshot_at: dt,
        source_iso: mismatched_iso,
        operational: true
      })

    assert html =~ DateTime.to_iso8601(dt)
    refute html =~ mismatched_iso
  end

  test "schema records are one-level surfaces with an adjacent exact-schema failed-work handoff",
       %{
         conn: conn
       } do
    Application.put_env(:scrypath_ops, :meilisearch_tasks, [
      %{
        "uid" => 2,
        "status" => "failed",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "postlv_ops_post_b",
        "finishedAt" => "2026-04-17T18:00:00Z"
      }
    ])

    {:ok, lv, _html} = live(conn, ~p"/ops/health")

    assert has_element?(lv, "[aria-label='Per-schema search health'] > article[aria-labelledby]")
    refute has_element?(lv, "[data-testid='posture-next-checks']")

    assert has_element?(
             lv,
             "[id='posture-ScrypathOps.Test.OpsPostB'] [data-testid='posture-failed-sync-link']"
           )

    assert has_element?(
             lv,
             "[id='posture-ScrypathOps.Test.OpsPostB'] a[href='/ops/failed-sync?schema=ScrypathOps.Test.OpsPostB']"
           )
  end

  test "fetch failures sort first and ties retain alphabetical full-module order", %{conn: conn} do
    Agent.update(:posture_live_test_state, fn state ->
      %{state | boom_indexes: ["postlv_ops_post_a", "postlv_ops_post_b"]}
    end)

    {:ok, lv, _html} = live(conn, ~p"/ops/health")

    row_ids =
      Regex.scan(~r/id="(posture-ScrypathOps\.Test\.OpsPost[AB])"/, render(lv),
        capture: :all_but_first
      )
      |> List.flatten()

    assert row_ids == ["posture-ScrypathOps.Test.OpsPostA", "posture-ScrypathOps.Test.OpsPostB"]
    refute has_element?(lv, "[data-testid='posture-failed-sync-link']")
  end

  test "backend error bodies do not leak into the operator interface", %{conn: conn} do
    secret = "private credential from response body"

    Agent.update(:posture_live_test_state, fn state ->
      %{state | boom_reason: {:http_error, 503, %{"message" => secret}}}
    end)

    {:ok, lv, _html} = live(conn, ~p"/ops/health")
    row = lv |> element("[id='posture-ScrypathOps.Test.OpsPostA']") |> render()

    assert row =~ "The search backend returned HTTP 503."
    assert row =~ "No successful observation recorded."
    refute row =~ secret

    refute has_element?(
             lv,
             "[id='posture-ScrypathOps.Test.OpsPostA'] [data-testid='posture-failed-sync-link']"
           )
  end

  test "posture promotion handoff keeps the selected schema and does not swap directly" do
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

    assert inspect(updated_socket.redirected) =~
             "/ops/sync-and-index?schema=ScrypathOps.Test.OpsPostA"

    refute Agent.get(:posture_live_test_state, & &1.swap_called)
    assert Agent.get(:posture_live_test_state, & &1.tasks_calls) == 0
    assert updated_socket.assigns.local_ui_state == %{expanded: [:details]}
    assert updated_socket.assigns.posture_rows == []
  end

  test "posture promotion handoff performs no mutation while impersonating" do
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

    assert inspect(updated_socket.redirected) =~
             "/ops/sync-and-index?schema=ScrypathOps.Test.OpsPostA"

    assert Agent.get(:posture_live_test_state, & &1.swap_called) != true
    assert Agent.get(:posture_live_test_state, & &1.tasks_calls) == 0
    assert updated_socket.assigns.local_ui_state == :keep
    assert updated_socket.assigns.posture_rows == []
  end

  test "posture promotion handoff performs no mutation before sudo confirmation" do
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

    assert inspect(updated_socket.redirected) =~
             "/ops/sync-and-index?schema=ScrypathOps.Test.OpsPostA"

    assert Agent.get(:posture_live_test_state, & &1.swap_called) != true
    assert Agent.get(:posture_live_test_state, & &1.tasks_calls) == 0
    assert updated_socket.assigns.local_ui_state == :keep
  end

  test "swap live rejects non-allowlisted module strings before gating" do
    mod_str = "ScrypathOps.Test.NotAllowlisted#{System.unique_integer([:positive])}"

    socket =
      posture_socket(%{
        schema_allowlist: [OpsPostA],
        local_ui_state: :keep
      })

    assert {:noreply, updated_socket} =
             PostureLive.handle_event("swap_live", %{"schema" => mod_str}, socket)

    assert flash_value(updated_socket, "error") =~ "allowlisted"
    assert updated_socket.assigns.local_ui_state == :keep
  end

  describe "HtmlCanon (the canonical tree the seam tests compare)" do
    test "ignores attribute order, generated ids, session tokens and whitespace, but not text" do
      a =
        ~s(<div id="phx-F1abc" data-phx-session="s1" class=" a  b" phx-click="x" title="t">) <>
          ~s(<span id="ops-time-12">Hello   world</span></div>)

      b =
        ~s(<div title="t" phx-click="x" class="a b" data-phx-session="OTHER" id="phx-F9zzz">) <>
          ~s(<span id="ops-time-99">Hello world</span></div>)

      assert HtmlCanon.canon(a) == HtmlCanon.canon(b)
      assert HtmlCanon.digest(a) == HtmlCanon.digest(b)
      # Same input twice is stable.
      assert HtmlCanon.canon(a) == HtmlCanon.canon(a)

      # Controls: the equality above is not vacuous. A changed text node, a changed ordinary id and
      # a changed ordinary attribute each change the tree, and the text is in the canonical form.
      assert HtmlCanon.canon(a) =~ "Hello world"
      refute HtmlCanon.canon(a) == HtmlCanon.canon(String.replace(b, "Hello", "Goodbye"))
      refute HtmlCanon.canon(a) == HtmlCanon.canon(String.replace(b, "phx-F9zzz", "main"))

      refute HtmlCanon.canon(a) ==
               HtmlCanon.canon(String.replace(b, ~s(title="t"), ~s(title="u")))

      refute HtmlCanon.digest(a) == HtmlCanon.digest(String.replace(b, "Hello", "Goodbye"))
    end

    test "takes a parsed selection as well as a string" do
      html = ~s(<main><p class="x">One</p><p>Two</p></main>)
      selection = html |> LazyHTML.from_fragment() |> LazyHTML.query("main")
      assert HtmlCanon.canon(selection) == HtmlCanon.canon(html)
    end
  end

  # The story renders the same function components the page does. Each area gets one seam test: the
  # mounted page contains exactly the component's own output for the page's own view-model.
  describe "seam: health_verdict (story output equals production output)" do
    setup do
      scenario =
        ScrypathFixtures.Scenarios.get!(
          :shopadelic_failed_journey,
          ScrypathFixtures.preview_epoch()
        )

      on_exit(FixtureEnv.put(scenario))
      :ok
    end

    test "the mounted verdict for shopadelic_failed_journey canonicalizes equal to the component",
         %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/ops/health")
      _ = render_async(view)

      assigns = :sys.get_state(view.pid).socket.assigns
      summary = assigns.posture_summary
      sync_mode = Keyword.get(assigns.scrypath_opts, :sync_mode, :inline)

      # The cause is real data: the page is the degraded failed journey, not an empty state.
      assert summary.state == :degraded
      assert summary.queue_failed_count == 3

      verdict_root = "section[aria-labelledby='posture-summary-heading']"
      mounted = view |> render() |> LazyHTML.from_fragment() |> LazyHTML.query(verdict_root)

      component =
        verdict_component_root(summary, sync_mode, verdict_root)

      assert Enum.count(mounted) == 1
      assert Enum.count(component) == 1
      assert HtmlCanon.canon(mounted) == HtmlCanon.canon(component)
      assert HtmlCanon.canon(mounted) =~ "Sync jobs and Meilisearch tasks failed"

      # Control: a different summary does not canonicalize equal, so the comparison can fail.
      changed =
        verdict_component_root(%{summary | headline: "Changed headline"}, sync_mode, verdict_root)

      refute HtmlCanon.canon(mounted) == HtmlCanon.canon(changed)
    end
  end

  # Each scenario below is mounted through the real router under FixtureEnv. Every Search health row
  # on the page, and the whole page, must canonicalize equal to the shared components' own output for
  # the page's own view-model (summary, ranked rows, snapshot instant). The stories render the same
  # functions, so this is what lets a story claim to show the page.
  describe "seam: health_schema_row and screen (story output equals production output)" do
    for scenario_id <- [
          :shopadelic_failed_journey,
          :shopadelic_settings_aligned,
          :wikily_first_delete_failed,
          :logistify_history_over_limit_f1,
          :wikily_unconfigured
        ] do
      test "#{scenario_id}: each mounted row and the whole page equal the component output", %{
        conn: conn
      } do
        scenario_id = unquote(scenario_id)
        scenario = ScrypathFixtures.Scenarios.get!(scenario_id, ScrypathFixtures.preview_epoch())
        on_exit(FixtureEnv.put(scenario))

        {:ok, view, _html} = live(conn, ~p"/ops/health")
        _ = render_async(view)

        assigns = :sys.get_state(view.pid).socket.assigns
        summary = assigns.posture_summary
        now = assigns.last_refresh_at
        sync_mode = Keyword.get(assigns.scrypath_opts, :sync_mode, :inline)

        ranked =
          case assigns.posture_rows do
            {:ok, rows} -> rows
            _setup_state -> []
          end

        mounted = view |> render() |> LazyHTML.from_fragment()

        # The cause is real data: a setup scenario has no rows, every other one has exactly one.
        assert length(ranked) ==
                 if(summary.state in [:unconfigured, :missing_backend], do: 0, else: 1)

        for {mod, _result} = row <- ranked do
          selector = "[id='posture-#{inspect(mod)}']"
          mounted_row = LazyHTML.query(mounted, selector)

          component_row =
            row_component(&SearchHealth.health_schema_row/1,
              row: row,
              summary: summary,
              mount_path: assigns.mount_path,
              now: now
            )
            |> LazyHTML.query(selector)

          assert Enum.count(mounted_row) == 1
          assert Enum.count(component_row) == 1
          assert HtmlCanon.canon(mounted_row) == HtmlCanon.canon(component_row)
        end

        screen_assigns = [
          mount_path: assigns.mount_path,
          flash: assigns.flash,
          shell: assigns.shell,
          page_title: assigns.page_title,
          summary: summary,
          rows: ranked,
          sync_mode: sync_mode,
          now: now,
          auto_refresh: assigns.auto_refresh
        ]

        page = LazyHTML.query(mounted, "[data-phx-main] > *")
        component_page = screen_component(screen_assigns)

        assert Enum.count(page) > 0
        assert HtmlCanon.canon(page) == HtmlCanon.canon(component_page)

        # Control: the comparison can fail. A different mount path changes every shell link.
        changed_page = screen_component(Keyword.put(screen_assigns, :mount_path, "/elsewhere"))
        refute HtmlCanon.canon(page) == HtmlCanon.canon(changed_page)
      end
    end
  end

  defp screen_component(assigns), do: row_component(&SearchHealth.screen/1, assigns)

  # Renders a function component to a parsed fragment.
  defp row_component(component, assigns) do
    component |> render_component(assigns) |> LazyHTML.from_fragment()
  end

  defp verdict_component_root(summary, sync_mode, selector) do
    html =
      render_component(&SearchHealth.health_verdict/1, summary: summary, sync_mode: sync_mode)

    html |> LazyHTML.from_fragment() |> LazyHTML.query(selector)
  end

  # Row ids in page order, e.g. "posture-ScrypathOps.Test.OpsPostA".
  defp row_ids(html) do
    html
    |> LazyHTML.from_fragment()
    |> LazyHTML.query("[data-testid='posture-row']")
    |> Enum.flat_map(&LazyHTML.attribute(&1, "id"))
  end

  defp row_html(lv, short_name) do
    lv |> element("[id='posture-ScrypathOps.#{short_name}']") |> render()
  end

  # The status word in a row's own header (not the source groups below it).
  defp row_header_status(row_html) do
    row_html
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(".ops-schema-signal-card__badges [data-sync-status]")
    |> LazyHTML.attribute("data-sync-status")
    |> case do
      [status] -> status
      other -> flunk("expected one header status, got #{inspect(other)}")
    end
  end

  defp condition_words(row_html) do
    row_html
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(".ops-condition")
    |> Enum.map(&String.trim(LazyHTML.text(&1)))
  end

  defp facts_text(row_html) do
    row_html
    |> LazyHTML.from_fragment()
    |> LazyHTML.query("[data-testid='posture-facts']")
    |> LazyHTML.text()
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  # A status the way `Scrypath.sync_status/2` returns it, with only the fields a row reads.
  defp status(opts) do
    queue =
      Map.merge(
        %{
          observed?: Keyword.get(opts, :observed?, true),
          pending: [],
          retrying: [],
          failed: [],
          last_succeeded: nil
        },
        Keyword.get(opts, :queue, %{})
      )

    Scrypath.Operator.Status.new(
      schema: OpsPostA,
      mode: Keyword.get(opts, :mode, :oban),
      index: "ranking_ops_post_a",
      backend: %{
        pending: Keyword.get(opts, :backend_pending, []),
        failed: Keyword.get(opts, :backend_failed, []),
        last_succeeded: nil
      },
      queue: queue
    )
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
      page_title: "Search health",
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
      host_uri: URI.parse("https://scrypath.example/ops/health")
    }
  end

  defp attach_posture_refresh_telemetry do
    test_pid = self()
    handler_id = "posture-refresh-test-#{System.unique_integer([:positive])}"

    assert :ok =
             :telemetry.attach(
               handler_id,
               [:scrypath_ops, :posture, :refresh],
               fn _event, measurements, metadata, _config ->
                 send(test_pid, {:posture_refresh, measurements, metadata})
               end,
               nil
             )

    on_exit(fn -> :telemetry.detach(handler_id) end)
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

  defp render_time(dt, snapshot_at, state_text \\ "No success observed") do
    render_component(&OpsUi.ops_time/1, %{
      dt: dt,
      snapshot_at: snapshot_at,
      source_iso: if(dt, do: DateTime.to_iso8601(dt)),
      state_text: state_text,
      operational: true
    })
  end

  defp flash_value(socket, key) do
    socket.assigns |> Map.get(:flash, %{}) |> Map.get(key)
  end
end
