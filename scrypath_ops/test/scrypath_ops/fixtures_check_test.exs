defmodule ScrypathOps.FixturesCheckTest do
  @moduledoc false
  # Phase 196: every problem tag `ScrypathFixtures.Check` can emit has at least one planted failure
  # in this file that returns exactly that tag, beside the positive control that the real data is
  # clean. A plant changes one thing in a real registered scenario (or builder, or failure table),
  # so it cannot pass by failing somewhere else: each asserts the exact problem and that no tag
  # outside its own (plus the ones its cause legitimately drags along, named in `:also`) appears.
  #
  # The plant table is in this one file, and the coverage test reads the tag list from
  # `Check.invariants/0` (never from a source regex), so a new invariant without a plant fails
  # here. It is self-contained on purpose: ExUnit loads only the test files it is given, so a
  # coverage test that called another test module could not run when this file runs alone.
  #
  # Pure: no app env and no database, so it runs async.
  use ExUnit.Case, async: true

  alias ScrypathFixtures.Check
  alias ScrypathFixtures.Failures
  alias ScrypathFixtures.Logistify
  alias ScrypathFixtures.Meili
  alias ScrypathFixtures.Scenarios

  @now ScrypathFixtures.preview_epoch()

  @doc "Every tag this module plants, read from the plant table itself."
  def planted_tags, do: plants() |> Enum.map(& &1.tag) |> Enum.uniq()

  describe "positive controls" do
    test "the registry is clean and the count is the number of registered scenarios" do
      expected = length(Scenarios.all(@now))
      assert expected == length(Scenarios.ids())
      assert {:ok, %{scenarios: ^expected}} = Check.run()
    end

    test "an empty run is clean" do
      assert {:ok, %{scenarios: 0}} = Check.run(scenarios: [], builders: [])
    end

    test "each real scenario is clean on its own, built from its own builder" do
      for {id, build} <- Scenarios.builders() do
        assert {:ok, %{scenarios: 1}} = Check.run(builders: [{id, build}]),
               "#{id} should be clean"

        assert {:ok, %{scenarios: 1}} = Check.run(scenarios: [build.(@now)]),
               "#{id} should be clean without its builder"
      end
    end

    test "the invariant list has no duplicate and no result wrapper" do
      tags = Check.invariants()
      assert Enum.uniq(tags) == tags
      assert Enum.all?(tags, &is_atom/1)
      refute :ok in tags
      refute :error in tags
    end
  end

  describe "one planted failure per invariant" do
    test "every plant returns its own tag, and no tag that is not its own" do
      failures =
        for plant <- plants(), reduce: [] do
          acc -> acc ++ plant_failures(plant)
        end

      assert failures == [], Enum.join(failures, "\n")
    end

    test "every invariant has at least one plant, and no plant names a tag Check does not list" do
      assert MapSet.new(planted_tags()) == MapSet.new(Check.invariants())
    end

    test "every problem any plant produces carries a tag Check.invariants/0 lists" do
      returned =
        for plant <- plants(), reduce: MapSet.new() do
          acc ->
            assert {:error, problems} = Check.run(plant.opts)
            MapSet.union(acc, MapSet.new(problem_tags(problems)))
        end

      assert MapSet.to_list(returned) -- Check.invariants() == []
    end
  end

  describe "the relative-time check reports where time stopped being relative" do
    test "a pinned task stamp names the task and the stamp" do
      [plant] = Enum.filter(plants(), &(&1.name == "a task stamp pinned to the epoch"))

      assert {:error, problems} = Check.run(plant.opts)

      assert {:logistify_deep_queue,
              {:time_not_relative, :logistify_deep_queue,
               [:scrypath_opts, :meilisearch_tasks, 0, "finishedAt"]}} in problems
    end

    test "a pinned job time names the job and the field" do
      [plant] = Enum.filter(plants(), &(&1.name == "a job time pinned to the epoch"))

      assert {:error, problems} = Check.run(plant.opts)

      assert {:logistify_deep_queue,
              {:time_not_relative, :logistify_deep_queue,
               [:scrypath_opts, :oban_jobs, 0, :scheduled_at]}} in problems
    end

    test "a non-time field that moves with the clock is reported too" do
      [plant] = Enum.filter(plants(), &(&1.name == "a label that changes with the clock"))

      assert {:error, problems} = Check.run(plant.opts)

      assert {:logistify_deep_queue, {:time_not_relative, :logistify_deep_queue, [:label]}} in problems
    end

    test "a scenario whose Oban error text embeds raw task stamps is still relative" do
      # positive control: the failed journey's delete job embeds failed tasks, stamps and all
      build = &ScrypathFixtures.Shopadelic.scenario(:failed_journey, now: &1)
      assert {:ok, %{scenarios: 1}} = Check.run(builders: [{:shopadelic_failed_journey, build}])
    end
  end

  # -- the plant table -------------------------------------------------------------------------

  # Each plant is %{tag, name, opts (for Check.run/1), problem (one element of the result),
  # also (tags the cause legitimately drags along)}.
  defp plants do
    deep = Scenarios.get!(:logistify_deep_queue, @now)
    journey = Scenarios.get!(:shopadelic_failed_journey, @now)
    id = deep.id
    uid = task_at(deep, 0)["uid"]
    job_id = job_at(deep, 0).id
    now = deep.now
    deep_builder = &Logistify.scenario(:deep_queue, now: &1)

    [
      plant(:wire_guard, "a task whose status is outside the wire list", id,
        scenarios: [
          change_tasks(deep, fn [t | rest] -> [Map.put(t, "status", "weird") | rest] end)
        ],
        problem: {:wire_guard, uid},
        # the real normalizer rejects the task, so the real sync_status fails as well
        also: [:unexpected_outcome]
      ),
      plant(:unexpected_outcome, "an expectation the real code does not meet", id,
        scenarios: [%{deep | expect: %{sync_status: {:error, :task_history_truncated}}}],
        problem: {:unexpected_outcome, :sync_status, :ok}
      ),
      plant(:task_keys, "a task that lost a key", id,
        scenarios: [change_tasks(deep, fn [t | rest] -> [Map.delete(t, "duration") | rest] end)],
        problem: {:task_keys, uid}
      ),
      plant(:index_uid, "a task on an index the scenario does not own", id,
        scenarios: [
          change_tasks(deep, fn [t | rest] -> [Map.put(t, "indexUid", "elsewhere") | rest] end)
        ],
        problem: {:index_uid, uid, "elsewhere"}
      ),
      plant(:time_order, "a task that finishes before it was enqueued", id,
        scenarios: [
          change_tasks(deep, fn [t | rest] ->
            [Map.put(t, "finishedAt", Meili.stamp(now, 90_000)) | rest]
          end)
        ],
        problem: {:time_order, uid}
      ),
      plant(:unparsable_time, "a stamp that is not a time", id,
        scenarios: [
          change_tasks(deep, fn [t | rest] -> [Map.put(t, "enqueuedAt", "yesterday") | rest] end)
        ],
        problem: {:unparsable_time, uid}
      ),
      plant(:meili_cancelled_spelling, "Oban's spelling on a Meilisearch task", id,
        scenarios: [
          change_tasks(deep, fn [t | rest] -> [Map.put(t, "status", "cancelled") | rest] end)
        ],
        problem: {:meili_cancelled_spelling, uid}
      ),
      plant(:task_shape, "a duration forced to an integer", id,
        scenarios: [change_tasks(deep, fn [t | rest] -> [Map.put(t, "duration", 100) | rest] end)],
        problem: {:task_shape, uid, "duration"}
      ),
      plant(:details_keys, "a details map that gained a key", id,
        scenarios: [
          change_tasks(deep, fn [t | rest] -> [put_in(t, ["details", "extraKey"], 1) | rest] end)
        ],
        problem: {:details_keys, uid}
      ),
      plant(:unknown_failure, "a hand-typed failure message", journey.id,
        scenarios: [
          change_tasks(journey, fn tasks ->
            Enum.map(tasks, fn
              %{"uid" => 43} = t -> put_in(t, ["error", "message"], "Something went wrong.")
              t -> t
            end)
          end)
        ],
        problem: {:unknown_failure, 43}
      ),
      plant(:failure_source_missing, "a table entry whose source does not resolve", :failures,
        scenarios: [deep],
        failures: [%{Failures.entry!(:invalid_document_id) | source: "99-no-such-recording"}],
        problem: {:failure_source_missing, :invalid_document_id}
      ),
      plant(:forbidden_failure, "a table entry on the cannot-produce list", :failures,
        scenarios: [deep],
        failures: [
          %{Failures.entry!(:invalid_document_id) | id: :planted, code: "payload_too_large"}
        ],
        problem: {:forbidden_failure, :planted}
      ),
      plant(:job_index, "a job that names a foreign index", id,
        scenarios: [
          change_jobs(deep, fn [j | rest] -> [put_in(j, [:args, "index"], "elsewhere") | rest] end)
        ],
        problem: {:job_index, job_id}
      ),
      plant(:retryable_attempts, "a retryable job scheduled in the past", id,
        scenarios: [
          change_jobs(deep, fn [j | rest] ->
            [%{j | state: "retryable", attempt: 1, scheduled_at: DateTime.add(now, -10)} | rest]
          end)
        ],
        problem: {:retryable_attempts, job_id}
      ),
      plant(:retryable_attempts, "a retryable job at its last attempt", id,
        scenarios: [
          change_jobs(deep, fn [j | rest] ->
            [
              %{
                j
                | state: "retryable",
                  attempt: j.max_attempts,
                  scheduled_at: DateTime.add(now, 600)
              }
              | rest
            ]
          end)
        ],
        problem: {:retryable_attempts, job_id}
      ),
      plant(:discarded_attempts, "a discarded job below its last attempt", id,
        scenarios: [
          change_jobs(deep, fn [j | rest] -> [%{j | state: "discarded", attempt: 3} | rest] end)
        ],
        problem: {:discarded_attempts, job_id}
      ),
      plant(:job_in_future, "a job attempted after now", id,
        scenarios: [
          change_jobs(deep, fn [j | rest] ->
            [%{j | attempted_at: DateTime.add(now, 60), attempt: 1} | rest]
          end)
        ],
        problem: {:job_in_future, job_id}
      ),
      plant(:duplicate_id, "the same scenario registered twice", id,
        scenarios: [deep, deep],
        problem: {:duplicate_id, id}
      ),
      plant(:job_schema, "a job that names a schema the scenario does not allowlist", id,
        scenarios: [
          change_jobs(deep, fn [j | rest] ->
            [put_in(j, [:args, "schema"], "Elixir.Nowhere.Schema") | rest]
          end)
        ],
        problem: {:job_schema, job_id}
      ),
      plant(:time_not_relative, "a task stamp pinned to the epoch", id,
        builders: [
          {id,
           fn at ->
             at
             |> deep_builder.()
             |> change_tasks(fn [t | rest] ->
               [Map.put(t, "finishedAt", Meili.stamp(@now, 100)) | rest]
             end)
           end}
        ],
        problem: {:time_not_relative, id, [:scrypath_opts, :meilisearch_tasks, 0, "finishedAt"]}
      ),
      plant(:time_not_relative, "a job time pinned to the epoch", id,
        builders: [
          {id,
           fn at ->
             at
             |> deep_builder.()
             |> change_jobs(fn [j | rest] ->
               [%{j | scheduled_at: DateTime.add(@now, -5)} | rest]
             end)
           end}
        ],
        problem: {:time_not_relative, id, [:scrypath_opts, :oban_jobs, 0, :scheduled_at]}
      ),
      plant(:time_not_relative, "a label that changes with the clock", id,
        builders: [
          {id, fn at -> %{deep_builder.(at) | label: "Deep queue (fictional) #{at.day}"} end}
        ],
        problem: {:time_not_relative, id, [:label]}
      ),
      plant(:unlabelled, "a label that does not say fictional", id,
        scenarios: [%{deep | label: "Logistify shipments, deep queue"}],
        problem: {:unlabelled, id}
      ),
      plant(:stress_unmarked, "a stress scenario that does not say stress", id,
        scenarios: [%{deep | kind: :stress}],
        problem: {:stress_unmarked, id}
      )
    ]
  end

  # Everything wrong with how one plant was reported; an empty list means it was reported cleanly.
  defp plant_failures(plant) do
    case Check.run(plant.opts) do
      {:ok, _summary} ->
        ["#{plant.name}: the plant was not reported at all"]

      {:error, problems} ->
        tags = problem_tags(problems)
        own = [plant.tag | plant.also]

        List.flatten([
          if(plant.problem in problems,
            do: [],
            else: ["#{plant.name}: expected #{inspect(plant.problem)} in #{inspect(problems)}"]
          ),
          if(tags -- own == [],
            do: [],
            else: ["#{plant.name}: tags outside #{inspect(own)}: #{inspect(tags)}"]
          ),
          for guard <- [:wire_guard, :unexpected_outcome], guard not in own, guard in tags do
            "#{plant.name}: the plant tripped #{guard} instead of its own tag"
          end
        ])
    end
  end

  defp plant(tag, name, id, opts) do
    {problem, opts} = Keyword.pop!(opts, :problem)
    {also, opts} = Keyword.pop(opts, :also, [])

    %{
      tag: tag,
      name: name,
      opts: opts,
      also: also,
      problem: {id, problem}
    }
  end

  # -- helpers -------------------------------------------------------------------------------

  defp problem_tags(problems), do: for({_id, tuple} <- problems, uniq: true, do: elem(tuple, 0))

  defp change_tasks(scenario, fun), do: update_in(scenario.scrypath_opts[:meilisearch_tasks], fun)
  defp change_jobs(scenario, fun), do: update_in(scenario.scrypath_opts[:oban_jobs], fun)

  defp task_at(scenario, index),
    do: scenario.scrypath_opts |> Keyword.fetch!(:meilisearch_tasks) |> Enum.at(index)

  defp job_at(scenario, index),
    do: scenario.scrypath_opts |> Keyword.fetch!(:oban_jobs) |> Enum.at(index)
end
