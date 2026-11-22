defmodule ScrypathOps.FixturesRoundTripTest do
  @moduledoc false
  # Phase 196: every registered fixture scenario is driven through the real Scrypath normalizers and
  # the real operator posture, and must come out as its `expect` says. The posture call is the one
  # `ScrypathOps.PostureLive` makes on first render (`posture_summary/1` passes a nil previous
  # summary then), with the allowlist and options the LiveView reads from `ScrypathOps.Schemas`
  # after `FixtureEnv.put/1`.
  #
  # `async: false`: `FixtureEnv` writes the global `:scrypath_ops` app env, and every test that puts a
  # scenario restores it in `on_exit`. Nothing here touches the database, so this is a plain
  # `ExUnit.Case` and not a `DataCase`: the started application (for the posture's task supervisor)
  # is all it needs.
  use ExUnit.Case, async: false

  alias ScrypathFixtures.AppliedSettings
  alias ScrypathFixtures.Recordings
  alias ScrypathFixtures.Scenario
  alias ScrypathFixtures.Scenarios
  alias ScrypathFixtures.Logistify.Shipment
  alias ScrypathFixtures.Shopadelic.Product
  alias ScrypathFixtures.Wikily.Page
  alias ScrypathOps.Posture
  alias ScrypathOps.Schemas
  alias ScrypathOps.Test.FixtureEnv

  @now ScrypathFixtures.preview_epoch()

  describe "the registry" do
    test "every builder's id is the id of the scenario it builds, and ids are unique" do
      built = Scenarios.all(@now)

      assert Enum.map(built, & &1.id) == Scenarios.ids()
      assert Enum.uniq(Scenarios.ids()) == Scenarios.ids()
      assert length(built) == length(Scenarios.builders())
    end

    test "get!/2 builds one scenario and raises, naming the known ids, for an unknown one" do
      assert %Scenario{id: :shopadelic_failed_journey} =
               Scenarios.get!(:shopadelic_failed_journey, @now)

      assert_raise ArgumentError, ~r/no scenario registered as :nope; known: \[:logistify_/, fn ->
        Scenarios.get!(:nope, @now)
      end
    end

    test "every registered scenario states the posture it should produce" do
      for scenario <- Scenarios.all(@now) do
        assert %{state: state, headline: headline} = scenario.expect[:posture],
               "#{scenario.id} has no :posture expectation"

        assert state in [:unconfigured, :missing_backend, :degraded, :ok]
        assert is_binary(headline) and headline != ""
      end
    end

    test "every label says fictional" do
      for scenario <- Scenarios.all(@now) do
        assert scenario.label =~ "(fictional)", "#{scenario.id}: #{scenario.label}"
      end
    end
  end

  describe "posture round trip, one test per registered scenario" do
    for id <- Scenarios.ids() do
      test "#{id} produces its designed posture through the real code" do
        scenario = Scenarios.get!(unquote(id), @now)
        on_exit(FixtureEnv.put(scenario))

        summary = Posture.summary(Schemas.allowlist(), Schemas.scrypath_opts(), scenario.now, nil)

        assert %{state: summary.state, headline: summary.headline} == scenario.expect.posture
        assert summary.refreshed_at == scenario.now
      end
    end
  end

  describe "Shopadelic settings, through the real index_contract_drift/2" do
    test "settings_aligned matches in every dimension" do
      scenario = Scenarios.get!(:shopadelic_settings_aligned, @now)

      assert {:ok, report} = drift(scenario)

      for {dimension, result} <- report.dimensions do
        assert %{match: true, details: []} = result, "#{dimension} should match"
      end

      assert map_size(report.dimensions) == 5
    end

    test "settings_drift reports storeId as declared but not applied, and nothing else" do
      scenario = Scenarios.get!(:shopadelic_settings_drift, @now)

      assert {:ok, report} = drift(scenario)

      assert %{match: false, details: [only_declared: "storeId"]} =
               report.dimensions.filterable_attributes

      assert %{
               match: false,
               details: [
                 %{
                   key: "filterableAttributes",
                   applied: ["status"],
                   declared: ["status", "storeId"]
                 }
               ]
             } = report.dimensions.settings

      for dimension <- [:fields, :sortable_attributes, :faceting] do
        assert %{match: true} = report.dimensions[dimension], "#{dimension} should match"
      end
    end

    test "the applied settings are the recorded default plus the one declared key" do
      recorded = Recordings.default_settings()
      assert map_size(recorded) == 20

      {:ok, aligned} = AppliedSettings.fetch(AppliedSettings.url(:shopadelic_aligned), "any")
      {:ok, drifted} = AppliedSettings.fetch(AppliedSettings.url(:shopadelic_drift), "any")

      assert aligned["filterableAttributes"] == ["status", "storeId"]
      assert drifted["filterableAttributes"] == ["status"]

      # Everything else is the recording, untouched, so no settings key is typed by hand.
      assert Map.delete(aligned, "filterableAttributes") ==
               Map.delete(recorded, "filterableAttributes")

      assert Map.delete(drifted, "filterableAttributes") ==
               Map.delete(recorded, "filterableAttributes")
    end

    test "a url that no state owns answers the recorded 404 for an index that was never created" do
      assert {:error, {:http_error, 404, body}} =
               AppliedSettings.fetch("https://nobody.fixtures.invalid", "shopadelic_product")

      assert body == Recordings.body!("19-settings-unknown-index-404")
      assert body["code"] == "index_not_found"
    end

    test "unsplit options raise naming :meilisearch_tasks, and the runtime half resolves" do
      scenario = Scenarios.get!(:shopadelic_settings_drift, @now)

      assert_raise ArgumentError, ~r/:meilisearch_tasks/, fn ->
        Scrypath.index_contract_drift(Product, scenario.scrypath_opts)
      end

      # positive control: the same scenario through the runtime half returns a report
      assert {:ok, %{schema: Product}} =
               Scrypath.index_contract_drift(
                 Product,
                 Scenario.runtime_opts(scenario.scrypath_opts)
               )
    end
  end

  describe "Shopadelic failed_journey, through the real failed_sync_work/2" do
    setup do
      scenario = Scenarios.get!(:shopadelic_failed_journey, @now)
      assert {:ok, rows} = Scrypath.failed_sync_work(Product, scenario.scrypath_opts)
      %{scenario: scenario, rows: Map.new(rows, &{&1.id, &1}), all_rows: rows}
    end

    test "it has exactly the five rows the journey starts from", %{all_rows: rows} do
      # 43 is the backend task; 101 to 104 are the four jobs
      assert rows |> Enum.map(& &1.id) |> Enum.sort() == [43, 101, 102, 103, 104]
    end

    test "the failed task is a validation failure that echoes the id as sent", %{rows: rows} do
      row = rows[43]

      assert %{source: :meilisearch, state: :failed, reason_class: :validation} = row
      assert row.reason =~ ~s("SPD 2041/B")
      assert row.reason =~ "is invalid"
    end

    test "the discarded upsert is at its last attempt after transport errors", %{
      rows: rows,
      scenario: scenario
    } do
      row = rows[101]
      max_attempts = scenario_max_attempts(scenario)

      assert %{source: :oban, state: :failed, operation: :upsert, reason_class: :transport} = row
      assert row.attempt == max_attempts
      assert row.max_attempts == max_attempts
    end

    test "the retryable upsert is below its last attempt with the next attempt in the future", %{
      rows: rows,
      scenario: scenario
    } do
      row = rows[102]

      assert %{source: :oban, state: :retrying, reason_class: :transport} = row
      assert row.attempt == 3
      assert row.attempt < row.max_attempts
      assert DateTime.compare(row.next_attempt_at, scenario.now) == :gt
    end

    test "the cancelled upsert names the schema its worker refused", %{rows: rows} do
      row = rows[103]

      assert %{source: :oban, state: :failed, operation: :upsert} = row
      assert row.reason =~ "{:cancel, {:invalid_job, {:unknown_schema,"
      assert row.reason =~ "ScrypathFixtures.Shopadelic.Product"
    end

    test "the discarded delete is exhausted and embeds the failed Meilisearch task", %{
      rows: rows,
      scenario: scenario
    } do
      row = rows[104]

      assert %{source: :oban, state: :failed, operation: :delete} = row
      assert row.attempt == scenario_max_attempts(scenario)
      assert row.reason_class == :queue_exhausted
      assert row.reason =~ "Scrypath.Oban.DeleteWorker failed with {:error, {:task_failed,"
    end

    test "every failure text is a table render, so the check passes", %{scenario: scenario} do
      assert {:ok, %{scenarios: 1}} = ScrypathFixtures.Check.run(scenarios: [scenario])
    end
  end

  describe "Logistify, ordinary states" do
    test "deep_queue reads as pending work and steady reads as clear, through the posture rows" do
      assert posture_row_status(:logistify_deep_queue) == :pending
      assert posture_row_status(:logistify_steady) == :clear
    end

    test "steady has no pending, retrying or failed work, and its queue was observed" do
      scenario = Scenarios.get!(:logistify_steady, @now)

      assert {:ok, status} = Scrypath.sync_status(Shipment, scenario.scrypath_opts)
      assert status.queue.observed?
      assert status.queue.last_succeeded != nil

      for list <- [
            status.backend.pending,
            status.backend.failed,
            status.queue.pending,
            status.queue.retrying,
            status.queue.failed
          ] do
        assert list == []
      end
    end

    test "both ordinary states report applied settings that match the schema in every dimension" do
      for id <- [:logistify_deep_queue, :logistify_steady] do
        scenario = Scenarios.get!(id, @now)

        assert {:ok, report} =
                 Scrypath.index_contract_drift(
                   Shipment,
                   Scenario.runtime_opts(scenario.scrypath_opts)
                 )

        for {dimension, result} <- report.dimensions do
          assert %{match: true, details: []} = result, "#{id}: #{dimension} should match"
        end
      end
    end
  end

  describe "Logistify history_over_limit, the labelled F1 stress variation" do
    setup do
      %{scenario: Scenarios.get!(:logistify_history_over_limit_f1, @now)}
    end

    test "it is one of exactly two stress scenarios, and it says so in its id, kind and label", %{
      scenario: scenario
    } do
      assert scenario.kind == :stress
      assert scenario.label =~ "stress"
      assert scenario.label =~ "finding F1"
      assert scenario.label =~ "(fictional)"

      # The other one is Shopadelic's hostile-text variation (Phase 196 plan 05).
      stress = for s <- Scenarios.all(@now), s.kind == :stress, do: s.id
      assert stress == [:logistify_history_over_limit_f1, :shopadelic_hostile_ids]
    end

    test "ordinary states are registered before their adopter's stress variation", %{
      scenario: stress
    } do
      ids = Scenarios.ids()
      stress_at = Enum.find_index(ids, &(&1 == stress.id))

      for ordinary <- Scenarios.all(@now),
          ordinary.adopter == stress.adopter,
          ordinary.kind == :ordinary do
        assert Enum.find_index(ids, &(&1 == ordinary.id)) < stress_at
      end
    end

    test "sync_status returns the real truncation error, field by field", %{scenario: scenario} do
      tasks = Keyword.fetch!(scenario.scrypath_opts, :meilisearch_tasks)
      assert length(tasks) == 1_200

      assert {:error,
              {:task_history_truncated,
               %{index_uid: "logistify_shipment", limit: 1000, observed: 1000, next: next}}} =
               Scrypath.sync_status(Shipment, scenario.scrypath_opts)

      # the 1,000 newest tasks were read; `next` is the newest one that was not
      assert is_integer(next)
      assert next == length(tasks) - 1000
    end

    test "failed_sync_work reads the same truncated history", %{scenario: scenario} do
      assert {:error, {:task_history_truncated, %{observed: 1000, limit: 1000}}} =
               Scrypath.failed_sync_work(Shipment, scenario.scrypath_opts)
    end

    test "the posture says the health could not be fully checked, never that nothing failed", %{
      scenario: scenario
    } do
      on_exit(FixtureEnv.put(scenario))

      summary = Posture.summary(Schemas.allowlist(), Schemas.scrypath_opts(), scenario.now, nil)

      assert summary.state == :degraded
      assert summary.headline == "Search health could not be fully checked"
      assert [{Shipment, {:error, {:task_history_truncated, _}} = result}] = summary.rows
      assert Posture.row_status(result) == {:condition, "Not checked"}
    end
  end

  describe "Wikily, an empty install" do
    test "unconfigured has no allowlisted schema and the posture says Not configured" do
      scenario = Scenarios.get!(:wikily_unconfigured, @now)
      on_exit(FixtureEnv.put(scenario))

      assert scenario.allowlist == []
      assert Schemas.allowlist() == []

      summary = Posture.summary(Schemas.allowlist(), Schemas.scrypath_opts(), scenario.now, nil)
      assert summary.state == :unconfigured
      assert summary.headline == "Not configured"
      assert summary.rows == []
    end

    test "missing_backend has no :backend and the posture says Broken" do
      scenario = Scenarios.get!(:wikily_missing_backend, @now)
      on_exit(FixtureEnv.put(scenario))

      refute Keyword.has_key?(scenario.scrypath_opts, :backend)
      refute Keyword.has_key?(Schemas.scrypath_opts(), :backend)

      summary = Posture.summary(Schemas.allowlist(), Schemas.scrypath_opts(), scenario.now, nil)
      assert summary.state == :missing_backend
      assert summary.headline == "Broken"
      assert summary.rows == []
    end

    test "without a backend Scrypath.sync_status/2 raises instead of returning a tag", %{} do
      scenario = Scenarios.get!(:wikily_missing_backend, @now)

      # Recorded for Phase 197: the posture's guard is the only thing between the operator UI and
      # this raise, so a screen that calls Scrypath directly in this state needs its own guard.
      assert_raise ArgumentError, ~r/required :backend option not found/, fn ->
        Scrypath.sync_status(Page, scenario.scrypath_opts)
      end

      # positive control: the same scenario with its backend put back reads clean
      with_backend = Keyword.put(scenario.scrypath_opts, :backend, Scrypath.Meilisearch)
      assert {:ok, _status} = Scrypath.sync_status(Page, with_backend)
    end

    test "index_not_created reads clear from an empty page, and its settings are a 404" do
      scenario = Scenarios.get!(:wikily_index_not_created, @now)

      assert {:ok, status} = Scrypath.sync_status(Page, scenario.scrypath_opts)
      assert status.index == "wikily_page"
      assert %{pending: [], failed: [], last_succeeded: nil} = status.backend
      refute status.queue.observed?
      assert {:ok, []} = Scrypath.failed_sync_work(Page, scenario.scrypath_opts)

      assert {:error, :index_not_found} =
               Scrypath.index_contract_drift(Page, Scenario.runtime_opts(scenario.scrypath_opts))
    end

    test "first_delete_failed is one failed delete whose reason is index_not_found" do
      scenario = Scenarios.get!(:wikily_first_delete_failed, @now)

      assert {:ok, [row]} = Scrypath.failed_sync_work(Page, scenario.scrypath_opts)
      assert %{source: :meilisearch, operation: :delete, state: :failed} = row
      assert row.reason == "Index `wikily_page` not found."
      assert row.metadata.type == "documentDeletion"

      assert {:error, :index_not_found} =
               Scrypath.index_contract_drift(Page, Scenario.runtime_opts(scenario.scrypath_opts))
    end
  end

  # -- helpers -------------------------------------------------------------------------------

  # The status word of the one posture row, with the scenario in the app env only for the call.
  defp posture_row_status(id) do
    scenario = Scenarios.get!(id, @now)
    restore = FixtureEnv.put(scenario)

    try do
      summary = Posture.summary(Schemas.allowlist(), Schemas.scrypath_opts(), scenario.now, nil)
      assert [{_schema, result}] = summary.rows
      Posture.row_status(result)
    after
      restore.()
    end
  end

  defp drift(%Scenario{scrypath_opts: opts}),
    do: Scrypath.index_contract_drift(Product, Scenario.runtime_opts(opts))

  defp scenario_max_attempts(%Scenario{scrypath_opts: opts}) do
    opts
    |> Scenario.runtime_opts()
    |> Scrypath.Config.resolve!()
    |> Scrypath.Config.oban_max_attempts()
  end
end
