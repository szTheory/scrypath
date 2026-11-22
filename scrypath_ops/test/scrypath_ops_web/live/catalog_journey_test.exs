defmodule ScrypathOpsWeb.CatalogJourneyTest do
  @moduledoc false
  # Phase 197 JOB-03: the paged on-call engineer goes from an unhealthy Search health row to a
  # verified retry and back, on fictional Shopadelic data (the `:shopadelic_failed_journey`
  # scenario: one schema, Oban job 101 holding SPD-2041 and SPD-2042).
  #
  # Written first and green on the code as it stood BEFORE the Search health and Failed sync
  # surfaces were extracted into view-models and components, so the extraction has a net. The
  # journey is never edited to make an extraction pass (Phase 197 CONTEXT).
  #
  # Mode rule: the linear journey runs with OPSUI_AUTH_MODE unset (basic). A Sigra-mode receipt is
  # bound to an organization the second mount does not have, so its handoff could not resolve.
  # Denials are separate Sigra-mode tests on a single mounted Failed sync view.
  #
  # Receipts are per LiveView process (finding D2, recorded, not fixed): what the page shows after
  # the return trip is printed in the test below, not asserted as expected behavior.
  #
  # `sudo!/1` and `put_live_assigns/2` are copies of the helpers in `failed_sync_live_test.exs`
  # (house rule: a copy over a shared dependency; the namespace fence keeps Sigra module names out
  # of `test/support`).
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScrypathOps.Test.FixtureEnv

  @schema "ScrypathFixtures.Shopadelic.Product"
  @index "shopadelic_product"
  @counter :catalog_journey_state
  @unavailable "That schema is unavailable."
  @recovery_links "section[aria-labelledby='ordinary-recovery'] a"
  @protected_values ["SPD-2041", "SPD-2042"]

  setup do
    scenario =
      ScrypathFixtures.Scenarios.get!(
        :shopadelic_failed_journey,
        ScrypathFixtures.preview_epoch()
      )

    # FixtureEnv restores every key it touches, including `:repo` and `:oban`, so the seams put
    # after it are undone by its restore function.
    restore_env = FixtureEnv.put(scenario)

    # Retry needs a repo (Loader.check_loadable) and a queue module the scenario does not set.
    Application.put_env(:scrypath_ops, :repo, ScrypathOpsWeb.CatalogJourneyTest.JobRepo)
    Application.put_env(:scrypath_ops, :oban, ScrypathOpsWeb.CatalogJourneyTest.Queue)

    start_supervised!(%{
      id: @counter,
      start:
        {Agent, :start_link,
         [fn -> %{count: 0, job: nil, job_state: "available"} end, [name: @counter]]}
    })

    previous_sigra = Application.fetch_env(:scrypath_ops, :sigra)
    previous_mode = System.get_env("OPSUI_AUTH_MODE")
    System.delete_env("OPSUI_AUTH_MODE")

    on_exit(fn ->
      restore_env.()

      case previous_sigra do
        {:ok, value} -> Application.put_env(:scrypath_ops, :sigra, value)
        :error -> Application.delete_env(:scrypath_ops, :sigra)
      end

      if previous_mode == nil,
        do: System.delete_env("OPSUI_AUTH_MODE"),
        else: System.put_env("OPSUI_AUTH_MODE", previous_mode)
    end)

    %{scenario: scenario}
  end

  describe "the linear journey (basic mode)" do
    test "JOB-03: the on-call engineer goes from an unhealthy Search health row to a queued retry and back",
         %{conn: conn} do
      # 1. Search health shows the degraded verdict and a link to the failed work.
      {:ok, health, _html} = live(conn, ~p"/ops/health")
      health_doc = health |> render_async() |> LazyHTML.from_fragment()

      verdict = LazyHTML.query(health_doc, ".ops-verdict[data-verdict-kind='error']")
      assert Enum.count(verdict) == 1
      assert verdict |> LazyHTML.query("[data-sync-status='failed']") |> Enum.count() == 1
      assert verdict |> LazyHTML.query(".ops-sync-status__word") |> LazyHTML.text() =~ "Failed"

      assert health_doc
             |> LazyHTML.query(".ops-posture-verdict p.text-ops-h2")
             |> LazyHTML.text() =~ "Sync jobs and Meilisearch tasks failed"

      [row] = health_doc |> LazyHTML.query("[data-testid='posture-row']") |> Enum.to_list()

      # The row's status word, then its queue and backend signals (failed, retrying, failed).
      assert row |> LazyHTML.query("[data-sync-status]") |> LazyHTML.attribute("data-sync-status") ==
               ["failed", "failed", "retrying", "failed"]

      assert LazyHTML.text(row) =~ @index

      link = LazyHTML.query(row, "a[data-testid='posture-failed-sync-link']")
      assert Enum.count(link) == 1
      [failed_href] = LazyHTML.attribute(link, "href")
      assert failed_href == "/ops/failed-sync?schema=#{@schema}"

      health_failed_counts = health_doc |> text() |> failed_counts()
      assert health_failed_counts == %{jobs: 3, tasks: 1}

      # 2. Following the link opens Failed sync scoped to the same schema.
      {:ok, failed, _html} =
        health
        |> element("a[data-testid='posture-failed-sync-link']")
        |> render_click()
        |> follow_redirect(conn, failed_href)

      failed_doc = failed |> render_async() |> LazyHTML.from_fragment()

      assert URI.decode_query(URI.parse(failed_href).query) == %{"schema" => @schema}
      assert failed_doc |> LazyHTML.query("[data-testid='failed-sync-row']") |> Enum.count() == 5

      assert failed_row_ids(failed_doc) == ["102", "43", "103", "101", "104"]

      retry_buttons = LazyHTML.query(failed_doc, "button[data-testid='failed-sync-retry']")

      assert retry_buttons |> LazyHTML.attribute("phx-value-id") |> Enum.sort() ==
               ["101", "102", "103", "104"]

      assert retry_buttons
             |> LazyHTML.attribute("phx-value-schema")
             |> Enum.uniq() == [@schema]

      # Meilisearch task 43 has no retry action.
      refute has_element?(failed, "button[data-testid='failed-sync-retry'][phx-value-id='43']")

      # The two pages agree on what failed.
      assert failed_doc |> LazyHTML.query("#failed-sync-summary-heading") |> LazyHTML.text() =~
               "4 failed, 1 retrying"

      # 3. Retry job 101 (a discarded upsert of SPD-2041 and SPD-2042).
      assert Agent.get(@counter, & &1.count) == 0

      receipt_html =
        failed
        |> element("button[data-testid='failed-sync-retry'][phx-value-id='101']")
        |> render_click()

      receipt_doc = LazyHTML.from_fragment(receipt_html)
      assert Agent.get(@counter, & &1.count) == 1

      assert receipt_doc
             |> LazyHTML.query("[data-testid='recovery-receipt']")
             |> Enum.count() == 1

      receipt_text =
        receipt_doc |> LazyHTML.query("[data-testid='recovery-receipt']") |> LazyHTML.text()

      assert receipt_text =~ "Retry queued"
      assert receipt_text =~ "Oban job #991"
      assert receipt_text =~ "Original job #101 is retained"

      assert :sys.get_state(failed.pid).socket.assigns.flash == %{
               "info" => "Retry queued · queue job 991"
             }

      # The retry button of row 101 is replaced by its receipt.
      refute has_element?(failed, "button[data-testid='failed-sync-retry'][phx-value-id='101']")

      # 4. The receipt hands off to Sync and index with the same schema.
      [handoff_href] =
        hrefs(receipt_doc, "[data-testid='recovery-receipt'] a", "Check sync status")

      handoff_uri = URI.parse(handoff_href)
      assert handoff_uri.path == "/ops/sync-and-index"
      handoff_query = URI.decode_query(handoff_uri.query)
      assert handoff_query["schema"] == @schema
      assert handoff_query["recovery_generation"] == "0"
      assert is_binary(handoff_query["recovery"]) and handoff_query["recovery"] != ""

      {:ok, sync, _html} =
        failed
        |> element("[data-testid='recovery-receipt'] a", "Check sync status")
        |> render_click()
        |> follow_redirect(conn)

      sync_doc = sync |> render_async() |> LazyHTML.from_fragment()
      assert sync_doc |> LazyHTML.query("#ordinary-recovery") |> Enum.count() == 1

      assert sync_doc
             |> LazyHTML.query("#recovery-observation")
             |> text() =~ "Retry queued"

      assert sync_doc
             |> LazyHTML.query("[data-testid='recovery-evidence']")
             |> text() =~ "Queue job 991 · attempt 1 · Active index #{@index}"

      # 5. The return links carry the same schema, and the first one leads back to Failed sync.
      assert hrefs(sync_doc, @recovery_links, "Review failed sync work") ==
               ["/ops/failed-sync?schema=#{@schema}"]

      [health_back] =
        hrefs(sync_doc, "nav[aria-label='Related search views'] a", "Inspect search health")

      assert health_back == "/ops/health?schema=#{@schema}"

      # The health link leads to the same unhealthy verdict.
      {:ok, health_again, _html} = live(conn, health_back)

      assert health_again
             |> render_async()
             |> LazyHTML.from_fragment()
             |> LazyHTML.query(".ops-verdict[data-verdict-kind='error']")
             |> Enum.count() == 1

      {:ok, back, _html} =
        sync
        |> element(@recovery_links, "Review failed sync work")
        |> render_click()
        |> follow_redirect(conn)

      # Receipts are per LiveView process (finding D2): what row 101 shows on this return is
      # recorded by the journey, not asserted, so the defect is not encoded as expected behavior.
      back_doc = back |> render_async() |> LazyHTML.from_fragment()
      assert back_doc |> LazyHTML.query("[data-testid='failed-sync-row']") |> Enum.count() == 5
      assert Agent.get(@counter, & &1.count) == 1
    end
  end

  describe "denial (Sigra mode)" do
    setup do
      Application.put_env(:scrypath_ops, :sigra,
        sudo_confirm_path: "/sudo/confirm",
        sudo_window: 300
      )

      System.put_env("OPSUI_AUTH_MODE", "sigra")
      :ok
    end

    test "allowlist denial shows no protected values and inserts nothing", %{conn: conn} do
      path = "/ops/failed-sync?schema=#{@schema}"

      # Control: the allowed page shows the protected values, so the absence check below can fail.
      {:ok, view, _html} = live(conn, path)
      before_html = render_async(view)
      assert text(before_html) =~ "SPD-2041"

      # The schema leaves the allowlist after the page was drawn; the retry names it.
      Application.put_env(:scrypath_ops, :schema_allowlist, [ScrypathOps.Test.OpsPostB])

      denied =
        view
        |> element("button[data-testid='failed-sync-retry'][phx-value-id='101']")
        |> render_click()

      assert text(denied) =~ @unavailable
      assert Agent.get(@counter, & &1.count) == 0

      for value <- @protected_values do
        refute text(denied) =~ value, "#{value} leaked through the allowlist denial"
      end

      refute denied
             |> LazyHTML.from_fragment()
             |> LazyHTML.query("[data-testid='failed-sync-row']")
             |> Enum.any?()

      # The unknown-schema URL does not echo the requested name.
      {:ok, gone, _html} = live(conn, "/ops/failed-sync?schema=ScrypathFixtures.Shopadelic.Gone")
      gone_doc = gone |> render_async() |> LazyHTML.from_fragment()
      assert LazyHTML.text(gone_doc) =~ @unavailable
      refute LazyHTML.text(gone_doc) =~ "Gone"

      assert gone_doc
             |> LazyHTML.query("[href*='Gone'], [value*='Gone'], [title*='Gone']")
             |> Enum.empty?()

      # Positive control: the same retry for an allowed viewer is queued exactly once.
      Application.put_env(:scrypath_ops, :schema_allowlist, [ScrypathFixtures.Shopadelic.Product])
      {:ok, allowed, _html} = live(conn, path)
      render_async(allowed)
      sudo!(allowed)

      accepted =
        allowed
        |> element("button[data-testid='failed-sync-retry'][phx-value-id='101']")
        |> render_click()

      assert text(accepted) =~ "Retry queued · queue job 991"
      assert Agent.get(@counter, & &1.count) == 1
    end

    test "stale sudo redirects without inserting and keeps the row", %{conn: conn} do
      path = "/ops/failed-sync?schema=#{@schema}"
      retry = "button[data-testid='failed-sync-retry'][phx-value-id='101']"

      {:ok, view, _html} = live(conn, path)
      render_async(view)
      stale_sudo!(view)

      assert {:error, {:live_redirect, %{to: to}}} = view |> element(retry) |> render_click()

      uri = URI.parse(to)
      assert String.starts_with?(to, "/sudo/confirm")
      assert Map.keys(URI.decode_query(uri.query)) == ["return_to"]
      refute to =~ "101"
      refute to =~ "SPD-"
      assert Agent.get(@counter, & &1.count) == 0

      # A fresh mount still shows row 101, retryable.
      {:ok, fresh, _html} = live(conn, path)
      render_async(fresh)
      assert has_element?(fresh, retry)

      # Positive control: with a fresh confirmation the same click queues the retry once.
      sudo!(fresh)
      accepted = fresh |> element(retry) |> render_click()
      assert text(accepted) =~ "Retry queued · queue job 991"
      assert Agent.get(@counter, & &1.count) == 1
    end
  end

  # -- helpers ---------------------------------------------------------------------------------

  defp text(%LazyHTML{} = doc), do: doc |> LazyHTML.text() |> squish()
  defp text(html) when is_binary(html), do: html |> LazyHTML.from_fragment() |> text()

  # The href of every link under `selector` whose text contains `label`.
  defp hrefs(doc, selector, label) do
    doc
    |> LazyHTML.query(selector)
    |> Enum.filter(&(LazyHTML.text(&1) =~ label))
    |> Enum.flat_map(&LazyHTML.attribute(&1, "href"))
  end

  defp squish(string), do: string |> String.replace(~r/\s+/, " ") |> String.trim()

  # "3 sync jobs and 1 Meilisearch tasks failed" in the verdict evidence.
  defp failed_counts(text) do
    [_, jobs, tasks] = Regex.run(~r/(\d+) sync jobs? and (\d+) Meilisearch tasks? failed/, text)
    %{jobs: String.to_integer(jobs), tasks: String.to_integer(tasks)}
  end

  # The numeric id of each failed-sync row, in display order, from its DOM id `failed-row-<...>`.
  defp failed_row_ids(doc) do
    doc
    |> LazyHTML.query("[data-testid='failed-sync-row']")
    |> LazyHTML.attribute("id")
    |> Enum.map(fn "failed-row-" <> key -> key |> String.split("-") |> List.last() end)
  end

  defp sudo!(view), do: put_operator!(view, -60)

  defp stale_sudo!(view), do: put_operator!(view, -600)

  defp put_operator!(view, sudo_age_seconds) do
    put_live_assigns(view,
      current_scope: %{user: %{id: "user_123"}, active_organization: %{id: "org_456"}},
      operator_context: %ScrypathOps.Integrations.Sigra.OperatorContext{
        user_id: "user_123",
        active_org_id: "org_456",
        impersonator_user_id: nil,
        sudo_at: DateTime.add(DateTime.utc_now(), sudo_age_seconds, :second)
      }
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
end

defmodule ScrypathOpsWeb.CatalogJourneyTest.Queue do
  @moduledoc false
  # The queue seam: `insert/1` counts and returns the inserted job at attempt 0 (the receipt then
  # expects attempt 1); `config/0` is the minimal Oban config the recovery identity check reads.
  # The state lives in the journey's own named Agent, so nothing here is global.

  def insert(changeset) do
    job = Ecto.Changeset.apply_changes(changeset)
    job = %{job | id: 991, state: "available", attempt: 0}
    Agent.update(:catalog_journey_state, &%{&1 | count: &1.count + 1, job: job})
    {:ok, job}
  end

  def config, do: %{repo: ScrypathOpsWeb.CatalogJourneyTest.JobRepo, prefix: nil}
end

defmodule ScrypathOpsWeb.CatalogJourneyTest.JobRepo do
  @moduledoc false
  # The repo seam: `get/3` hands back the inserted job at attempt 1 in the state the test chose
  # ("available" by default). An attempt that differs from the receipt's turns the handoff into an
  # unknown status.

  def get(Oban.Job, 991, _opts) do
    case Agent.get(:catalog_journey_state, & &1) do
      %{job: nil} -> nil
      %{job: job, job_state: state} -> %{job | attempt: 1, state: state}
    end
  end

  def get(_schema, _id, _opts), do: nil
end
