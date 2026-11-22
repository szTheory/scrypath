defmodule ScrypathOpsWeb.FixturesTracerTest do
  @moduledoc false
  # Phase 196 tracer: the Logistify builders emit raw wire shapes, the fake client and inspector hand
  # them to the real Scrypath code, and /ops/health renders the result. App env is global, so this
  # module is async: false and every test that puts a scenario restores the env it touched.
  #
  # Every plant below changes ONE field of the real deep-queue scenario and asserts the exact problem
  # tag that field must produce, with a positive control beside it. A plant that only asserted "not
  # ok" could pass for the wrong reason (research Pitfall 5).
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScrypathFixtures.Check
  alias ScrypathFixtures.Logistify
  alias ScrypathFixtures.Logistify.Shipment
  alias ScrypathFixtures.Meili
  alias ScrypathFixtures.ObanJob
  alias ScrypathFixtures.Scenario
  alias ScrypathOps.Test.FixtureEnv

  @scenario_id :logistify_deep_queue

  describe "tracer" do
    setup do
      scenario = Logistify.scenario(:deep_queue, now: ScrypathFixtures.preview_epoch())
      on_exit(FixtureEnv.put(scenario))
      %{scenario: scenario}
    end

    test "Logistify deep queue renders a neutral pending verdict with nothing failed", %{
      conn: conn
    } do
      {:ok, lv, _document} = live(conn, ~p"/ops/health")

      assert has_element?(
               lv,
               ".ops-verdict[data-verdict-kind='neutral'] [data-sync-status='pending']"
             )

      refute has_element?(lv, "[data-sync-status='failed']")

      headline =
        lv
        |> element(".ops-posture-verdict p.text-ops-h2")
        |> render()
        |> LazyHTML.from_fragment()
        |> LazyHTML.text()

      assert headline =~ "No sync failures found"
    end
  end

  describe "closed enums" do
    test "a valid Meilisearch task and a valid Oban job build (positive controls)" do
      assert %{"status" => "succeeded"} = Meili.task(task_attrs())
      assert %{"indexUid" => nil, "type" => "indexSwap"} = Meili.task(swap_attrs())

      assert %{state: "available", worker: "Scrypath.Oban.UpsertWorker"} =
               ObanJob.job(job_attrs())
    end

    test "a task type outside the five Scrypath reads raises" do
      assert_raise FunctionClauseError, ~r/ScrypathFixtures\.Meili\.task\/1/, fn ->
        Meili.task(task_attrs(%{type: "documentAdditionOrUpdateX"}))
      end
    end

    test "the Oban spelling cancelled is not a Meilisearch status" do
      assert_raise FunctionClauseError, ~r/ScrypathFixtures\.Meili\.task\/1/, fn ->
        Meili.task(task_attrs(%{status: "cancelled"}))
      end
    end

    test "an indexSwap task that names an index raises" do
      assert_raise FunctionClauseError, ~r/ScrypathFixtures\.Meili\.task\/1/, fn ->
        Meili.task(swap_attrs(%{index_uid: "logistify_shipment"}))
      end
    end

    test "the Meilisearch spelling canceled is not an Oban state" do
      assert_raise FunctionClauseError, ~r/ScrypathFixtures\.ObanJob\.job\/1/, fn ->
        ObanJob.job(job_attrs(%{state: "canceled"}))
      end
    end

    test "an Oban state outside the seven Scrypath reads raises" do
      assert_raise FunctionClauseError, ~r/ScrypathFixtures\.ObanJob\.job\/1/, fn ->
        ObanJob.job(job_attrs(%{state: "exhausted"}))
      end
    end

    test "a worker outside the three Scrypath workers raises" do
      assert_raise FunctionClauseError, ~r/ScrypathFixtures\.ObanJob\.job\/1/, fn ->
        ObanJob.job(job_attrs(%{worker: :reindex}))
      end
    end
  end

  describe "check skeleton" do
    setup do
      %{scenario: Logistify.scenario(:deep_queue, now: ScrypathFixtures.preview_epoch())}
    end

    test "the real deep queue is clean (positive control)", %{scenario: scenario} do
      assert {:ok, %{scenarios: 1}} = Check.run(scenarios: [scenario])
      assert {:ok, %{scenarios: 1}} = Check.run()
    end

    test "a job that names a foreign index is a job_index problem", %{scenario: scenario} do
      [first | _] = Keyword.fetch!(scenario.scrypath_opts, :oban_jobs)

      planted =
        change_jobs(scenario, fn [job | rest] ->
          [put_in(job, [:args, "index"], "elsewhere") | rest]
        end)

      assert {:error, problems} = Check.run(scenarios: [planted])
      assert {@scenario_id, {:job_index, first.id}} in problems
      refute_wire_guard(problems)
    end

    test "a task that finishes before it was enqueued is a time_order problem", %{
      scenario: scenario
    } do
      now = scenario.now

      planted =
        change_tasks(scenario, fn [task | rest] ->
          [Map.put(task, "finishedAt", Meili.stamp(now, 90_000)) | rest]
        end)

      uid = planted |> task_at(0) |> Map.fetch!("uid")

      assert {:error, problems} = Check.run(scenarios: [planted])
      assert {@scenario_id, {:time_order, uid}} in problems
      refute_wire_guard(problems)
    end

    test "a task with a status outside the wire list is a wire_guard problem", %{
      scenario: scenario
    } do
      planted =
        change_tasks(scenario, fn [task | rest] -> [Map.put(task, "status", "weird") | rest] end)

      uid = planted |> task_at(0) |> Map.fetch!("uid")

      assert {:error, problems} = Check.run(scenarios: [planted])
      assert {@scenario_id, {:wire_guard, uid}} in problems
    end

    test "an outcome that differs from the scenario's expectation is unexpected_outcome", %{
      scenario: scenario
    } do
      planted = %{scenario | expect: %{sync_status: {:error, :task_history_truncated}}}

      assert {:error, problems} = Check.run(scenarios: [planted])
      assert {@scenario_id, {:unexpected_outcome, :sync_status, :ok}} in problems
      refute_wire_guard(problems)
    end

    test "each remaining invariant fires on its own plant", %{scenario: scenario} do
      now = scenario.now
      job_id = scenario |> job_at(0) |> Map.fetch!(:id)
      uid = scenario |> task_at(0) |> Map.fetch!("uid")

      plants = [
        {{:task_keys, uid},
         &change_tasks(&1, fn [t | rest] -> [Map.delete(t, "duration") | rest] end)},
        {{:index_uid, uid, "elsewhere"},
         &change_tasks(&1, fn [t | rest] -> [Map.put(t, "indexUid", "elsewhere") | rest] end)},
        {{:unparsable_time, uid},
         &change_tasks(&1, fn [t | rest] -> [Map.put(t, "enqueuedAt", "yesterday") | rest] end)},
        {{:meili_cancelled_spelling, uid},
         &change_tasks(&1, fn [t | rest] -> [Map.put(t, "status", "cancelled") | rest] end)},
        # retryable below max_attempts but scheduled in the past
        {{:retryable_attempts, job_id},
         &change_jobs(&1, fn [j | rest] ->
           [%{j | state: "retryable", attempt: 1, scheduled_at: DateTime.add(now, -10)} | rest]
         end)},
        # retryable at max_attempts (it would be discarded) even though scheduled in the future
        {{:retryable_attempts, job_id},
         &change_jobs(&1, fn [j | rest] ->
           [
             %{
               j
               | state: "retryable",
                 attempt: j.max_attempts,
                 scheduled_at: DateTime.add(now, 600)
             }
             | rest
           ]
         end)},
        {{:discarded_attempts, job_id},
         &change_jobs(&1, fn [j | rest] -> [%{j | state: "discarded", attempt: 3} | rest] end)},
        {{:job_in_future, job_id},
         &change_jobs(&1, fn [j | rest] ->
           [%{j | attempted_at: DateTime.add(now, 60), attempt: 1} | rest]
         end)}
      ]

      for {expected, plant} <- plants do
        assert {:error, problems} = Check.run(scenarios: [plant.(scenario)])

        assert {@scenario_id, expected} in problems,
               "expected #{inspect(expected)} in #{inspect(problems)}"

        refute_wire_guard(problems)
      end
    end

    test "every tag the plants produce is listed in Check.invariants/0", %{scenario: scenario} do
      now = scenario.now

      plants = [
        fn s ->
          change_jobs(s, fn [j | rest] -> [put_in(j, [:args, "index"], "elsewhere") | rest] end)
        end,
        fn s -> change_tasks(s, fn [t | rest] -> [Map.put(t, "status", "weird") | rest] end) end,
        fn s ->
          change_tasks(s, fn [t | rest] ->
            [Map.put(t, "finishedAt", Meili.stamp(now, 90_000)) | rest]
          end)
        end
      ]

      problems =
        Enum.flat_map(plants, fn plant ->
          assert {:error, found} = Check.run(scenarios: [plant.(scenario)])
          found
        end)

      assert problems != []
      tags = for {_id, tuple} <- problems, uniq: true, do: elem(tuple, 0)
      assert tags -- Check.invariants() == []
      assert Enum.all?(Check.invariants(), &is_atom/1)
      refute :ok in Check.invariants()
      refute :error in Check.invariants()
    end
  end

  describe "FixtureEnv" do
    setup do
      %{scenario: Logistify.scenario(:deep_queue, now: ScrypathFixtures.preview_epoch())}
    end

    test "restores every key it touched, including keys that were absent", %{scenario: scenario} do
      before_put = snapshot()

      restore = FixtureEnv.put(scenario)
      on_exit(restore)

      assert Application.fetch_env!(:scrypath_ops, :backend) == Scrypath.Meilisearch
      assert Application.fetch_env!(:scrypath_ops, :schema_allowlist) == [Shipment]
      clock = Application.fetch_env!(:scrypath_ops, :test_clock_file)
      assert File.read!(clock) == DateTime.to_iso8601(scenario.now) <> "\n"
      refute snapshot() == before_put

      restore.()

      assert snapshot() == before_put
      refute File.exists?(clock)
    end

    test "a key the scenario omits is deleted while the scenario is in effect", %{
      scenario: scenario
    } do
      before_put = snapshot()
      planted = update_in(scenario.scrypath_opts, &Keyword.delete(&1, :backend))

      restore = FixtureEnv.put(planted)
      on_exit(restore)

      assert Application.fetch_env(:scrypath_ops, :backend) == :error
      restore.()

      assert snapshot() == before_put
    end
  end

  describe "operator-only keys" do
    setup do
      %{scenario: Logistify.scenario(:deep_queue, now: ScrypathFixtures.preview_epoch())}
    end

    test "the fixtures list equals @operator_only_opts in lib/scrypath/operator.ex" do
      assert :ok = operator_key_drift(operator_only_opts_from_source(), Scenario.operator_keys())
    end

    test "a list that lost :task_history_limit is reported by name" do
      actual = List.delete(Scenario.operator_keys(), :task_history_limit)

      assert {:drift, message} = operator_key_drift(operator_only_opts_from_source(), actual)
      assert message =~ "missing [:task_history_limit]"
    end

    test "split_opts/1 puts every operator key on the operator side", %{scenario: scenario} do
      {runtime_opts, operator_opts} = Scenario.split_opts(scenario.scrypath_opts)

      assert Keyword.keys(operator_opts) |> Enum.sort() ==
               Enum.sort([:meilisearch_tasks, :oban_inspector, :oban_jobs])

      assert Keyword.take(runtime_opts, Scenario.operator_keys()) == []
      assert Scenario.runtime_opts(scenario.scrypath_opts) == runtime_opts
    end

    test "index_contract_drift/2 rejects unsplit options and accepts the runtime half", %{
      scenario: scenario
    } do
      assert_raise ArgumentError, ~r/:meilisearch_tasks/, fn ->
        Scrypath.index_contract_drift(Shipment, scenario.scrypath_opts)
      end

      # positive control: the runtime half resolves without raising
      assert is_list(Scrypath.Config.resolve!(Scenario.runtime_opts(scenario.scrypath_opts)))
    end
  end

  # -- helpers -------------------------------------------------------------------------------

  defp task_attrs(overrides \\ %{}) do
    Map.merge(
      %{
        type: "documentAdditionOrUpdate",
        status: "succeeded",
        uid: 1,
        index_uid: "logistify_shipment",
        now: ScrypathFixtures.preview_epoch(),
        enqueued_ago: 100
      },
      overrides
    )
  end

  defp swap_attrs(overrides \\ %{}) do
    task_attrs(Map.merge(%{type: "indexSwap", index_uid: nil}, overrides))
  end

  defp job_attrs(overrides \\ %{}) do
    Map.merge(
      %{
        id: 1,
        state: "available",
        worker: :upsert,
        queue: "logistify_sync",
        args: %{"operation" => "upsert"},
        now: ScrypathFixtures.preview_epoch(),
        ago: 10,
        max_attempts: 8
      },
      overrides
    )
  end

  defp change_tasks(scenario, fun), do: update_in(scenario.scrypath_opts[:meilisearch_tasks], fun)
  defp change_jobs(scenario, fun), do: update_in(scenario.scrypath_opts[:oban_jobs], fun)

  defp task_at(scenario, index),
    do: scenario.scrypath_opts |> Keyword.fetch!(:meilisearch_tasks) |> Enum.at(index)

  defp job_at(scenario, index),
    do: scenario.scrypath_opts |> Keyword.fetch!(:oban_jobs) |> Enum.at(index)

  # The plant reached the check as a well-formed wire shape; it did not fail in the builder or the guard.
  defp refute_wire_guard(problems) do
    refute Enum.any?(problems, &match?({_id, {:wire_guard, _uid}}, &1)),
           "plant tripped the wire guard instead of its own invariant: #{inspect(problems)}"
  end

  defp snapshot, do: Map.new(FixtureEnv.keys(), &{&1, Application.fetch_env(:scrypath_ops, &1)})

  # The `@operator_only_opts` attribute in lib/scrypath/operator.ex, read from the AST.
  defp operator_only_opts_from_source do
    path = Path.expand("../../../../lib/scrypath/operator.ex", __DIR__)

    {_ast, keys} =
      path
      |> File.read!()
      |> Code.string_to_quoted!()
      |> Macro.prewalk(nil, fn
        {:@, _, [{:operator_only_opts, _, [keys]}]} = node, _acc when is_list(keys) ->
          {node, keys}

        node, acc ->
          {node, acc}
      end)

    assert is_list(keys) and keys != [], "@operator_only_opts not found in #{path}"
    Enum.sort(keys)
  end

  # Pure comparison, so its own plant can prove the message names the missing key.
  defp operator_key_drift(expected, actual) do
    missing = Enum.sort(expected -- actual)
    extra = Enum.sort(actual -- expected)

    if missing == [] and extra == [] do
      :ok
    else
      {:drift, "operator keys drifted: missing #{inspect(missing)}, extra #{inspect(extra)}"}
    end
  end
end
