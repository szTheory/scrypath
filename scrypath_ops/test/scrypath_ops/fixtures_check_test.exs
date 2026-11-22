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
  # A job plant is built the way the real builder builds a job (`built/3`), so it is impossible in
  # exactly one way; a malformed job is reported for its shape alone, so a shape plant names no
  # other tag.
  #
  # Pure: no app env and no database, so it runs async.
  use ExUnit.Case, async: true

  alias ScrypathFixtures.Bulk
  alias ScrypathFixtures.Check
  alias ScrypathFixtures.Failures
  alias ScrypathFixtures.Logistify
  alias ScrypathFixtures.Meili
  alias ScrypathFixtures.ObanJob
  alias ScrypathFixtures.Scenarios

  @now ScrypathFixtures.preview_epoch()

  @doc "Every tag this module plants, read from the plant table itself."
  def planted_tags, do: plants() |> Enum.map(& &1.tag) |> Enum.uniq()

  # Every plant runs once, here; the tests of "one planted failure per invariant" read the same
  # results (a plant costs a full round trip through the real Scrypath code).
  setup_all do
    %{results: for(plant <- plants(), do: {plant, Check.run(plant.opts)})}
  end

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
    test "every plant returns its own tag, and no tag that is not its own", %{results: results} do
      failures = Enum.flat_map(results, fn {plant, result} -> plant_failures(plant, result) end)

      assert failures == [], Enum.join(failures, "\n")
    end

    test "every invariant has at least one plant, and no plant names a tag Check does not list" do
      assert MapSet.new(planted_tags()) == MapSet.new(Check.invariants())
    end

    test "every problem any plant produces carries a tag Check.invariants/0 lists", %{
      results: results
    } do
      returned =
        for {_plant, result} <- results, reduce: MapSet.new() do
          acc ->
            assert {:error, problems} = result
            MapSet.union(acc, MapSet.new(problem_tags(problems)))
        end

      assert MapSet.to_list(returned) -- Check.invariants() == []
    end
  end

  describe "task uids, and a task that lacks a key" do
    setup do
      %{deep: Scenarios.get!(:logistify_deep_queue, @now)}
    end

    test "the order of the list is not the order of the uids", %{deep: deep} do
      # Meilisearch lists newest first; only uid against enqueue time is checked
      assert {:ok, _summary} = Check.run(scenarios: [change_tasks(deep, &Enum.reverse/1)])
    end

    test "tasks enqueued in the same instant may take ascending uids", %{deep: deep} do
      # the last waiting task of the deep queue was enqueued 30 seconds ago
      same_instant = change_tasks(deep, &(&1 ++ [task_enqueued(deep, 700, 30)]))
      assert {:ok, _summary} = Check.run(scenarios: [same_instant])

      later = change_tasks(deep, &(&1 ++ [task_enqueued(deep, 700, 10)]))
      assert {:ok, _summary} = Check.run(scenarios: [later])
    end

    test "a missing uid is not a duplicate, and an inversion is reported once", %{deep: deep} do
      id = deep.id
      first = task_at(deep, 0)

      # one task far in the past with a high uid: reported against that uid, not against the rest
      assert {:error, [{^id, {:task_uid_order, 700}}]} =
               Check.run(
                 scenarios: [change_tasks(deep, &(&1 ++ [task_enqueued(deep, 700, 5_400)]))]
               )

      # a uid that is not an integer is the wire guard's problem; the uid checks skip it
      planted = change_tasks(deep, fn [t | rest] -> [Map.delete(t, "uid") | rest] end)
      assert {:error, problems} = Check.run(scenarios: [planted])
      assert problem_tags(problems) -- [:task_keys, :wire_guard, :unexpected_outcome] == []
      refute :task_uid_unique in problem_tags(problems)
      refute :task_uid_order in problem_tags(problems)
      assert first["uid"] == 1
    end

    test "a task with no indexUid is reported as task_keys and nothing raises", %{deep: deep} do
      id = deep.id
      planted = change_tasks(deep, fn [t | rest] -> [Map.delete(t, "indexUid") | rest] end)

      assert {:error, [{^id, {:task_keys, 1}}]} = Check.run(scenarios: [planted])
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
    planted_lib = "/planted/lib/scrypath_fixtures"

    # The bulk sample with one record's title changed: a sample whose digest is not the golden one.
    changed_sample =
      Bulk.sample()
      |> Keyword.update!(:product, fn [first | rest] -> [%{first | title: "Altered"} | rest] end)

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
      # a task with no "indexUid" has no name to check: it is reported as task_keys, not raised
      plant(:task_keys, "a task with no index uid", id,
        scenarios: [change_tasks(deep, fn [t | rest] -> [Map.delete(t, "indexUid") | rest] end)],
        problem: {:task_keys, uid}
      ),
      plant(:index_uid, "a task on an index the scenario does not own", id,
        scenarios: [
          change_tasks(deep, fn [t | rest] -> [Map.put(t, "indexUid", "elsewhere") | rest] end)
        ],
        problem: {:index_uid, uid, "elsewhere"}
      ),
      plant(:task_uid_unique, "a uid used by two tasks", id,
        scenarios: [change_tasks(deep, fn [t | rest] -> [t, t | rest] end)],
        problem: {:task_uid_unique, uid}
      ),
      # the Shopadelic cause: a task with a higher uid that was enqueued long before the lower ones
      plant(:task_uid_order, "a task enqueued before the task with the next lower uid", id,
        scenarios: [
          change_tasks(deep, fn tasks ->
            tasks ++ [task_enqueued(deep, 700, 5_400)]
          end)
        ],
        problem: {:task_uid_order, 700}
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
            retry = [{:oban_transport, 1, []}]

            [
              built(j, now, %{state: "retryable", attempt: 1, scheduled_in: -10, errors: retry})
              | rest
            ]
          end)
        ],
        problem: {:retryable_attempts, job_id}
      ),
      plant(:retryable_attempts, "a retryable job at its last attempt", id,
        scenarios: [
          change_jobs(deep, fn [j | rest] ->
            last = j.max_attempts

            [
              built(j, now, %{
                state: "retryable",
                attempt: last,
                scheduled_in: 600,
                errors: [{:oban_transport, last, []}]
              })
              | rest
            ]
          end)
        ],
        problem: {:retryable_attempts, job_id}
      ),
      plant(:discarded_attempts, "a discarded job below its last attempt", id,
        scenarios: [
          change_jobs(deep, fn [j | rest] ->
            [
              built(j, now, %{
                state: "discarded",
                attempt: 3,
                errors: [{:oban_transport, 3, []}]
              })
              | rest
            ]
          end)
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
      # -- the shape of a job: reported for the shape alone, one cause per plant --------------
      plant(:job_shape, "a job that lost a key", id,
        scenarios: [change_jobs(deep, fn [j | rest] -> [Map.delete(j, :attempt) | rest] end)],
        problem: {:job_shape, job_id, :keys}
      ),
      plant(:job_shape, "a job that gained a key", id,
        scenarios: [
          change_jobs(deep, fn [j | rest] -> [Map.put(j, :inserted_at, now) | rest] end)
        ],
        problem: {:job_shape, job_id, :keys}
      ),
      plant(:job_shape, "a state Oban does not have", id,
        scenarios: [change_jobs(deep, fn [j | rest] -> [%{j | state: "exhausted"} | rest] end)],
        problem: {:job_shape, job_id, :state}
      ),
      plant(:job_shape, "a worker Scrypath does not have", id,
        scenarios: [change_jobs(deep, fn [j | rest] -> [%{j | worker: "Some.Other"} | rest] end)],
        problem: {:job_shape, job_id, :worker}
      ),
      plant(:job_shape, "a queue that is not a name", id,
        scenarios: [change_jobs(deep, fn [j | rest] -> [%{j | queue: :sync} | rest] end)],
        problem: {:job_shape, job_id, :queue}
      ),
      plant(:job_shape, "args that are not a map", id,
        scenarios: [change_jobs(deep, fn [j | rest] -> [%{j | args: []} | rest] end)],
        problem: {:job_shape, job_id, :args}
      ),
      plant(:job_shape, "errors that are not a list", id,
        scenarios: [change_jobs(deep, fn [j | rest] -> [%{j | errors: nil} | rest] end)],
        problem: {:job_shape, job_id, :errors}
      ),
      plant(:job_shape, "an attempt that is not a count", id,
        scenarios: [change_jobs(deep, fn [j | rest] -> [%{j | attempt: "1"} | rest] end)],
        problem: {:job_shape, job_id, :attempt}
      ),
      plant(:job_shape, "a negative attempt", id,
        scenarios: [change_jobs(deep, fn [j | rest] -> [%{j | attempt: -1} | rest] end)],
        problem: {:job_shape, job_id, :attempt}
      ),
      plant(:job_shape, "a job that may never be attempted", id,
        scenarios: [change_jobs(deep, fn [j | rest] -> [%{j | max_attempts: 0} | rest] end)],
        problem: {:job_shape, job_id, :max_attempts}
      ),
      plant(:job_shape, "an attempted_at that is not a time", id,
        scenarios: [
          change_jobs(deep, fn [j | rest] -> [%{j | attempted_at: "yesterday"} | rest] end)
        ],
        problem: {:job_shape, job_id, :attempted_at}
      ),
      plant(:job_shape, "a job with no scheduled_at", id,
        scenarios: [change_jobs(deep, fn [j | rest] -> [%{j | scheduled_at: nil} | rest] end)],
        problem: {:job_shape, job_id, :scheduled_at}
      ),
      plant(:job_shape, "a completed_at that is not a time", id,
        scenarios: [change_jobs(deep, fn [j | rest] -> [%{j | completed_at: 0} | rest] end)],
        problem: {:job_shape, job_id, :completed_at}
      ),
      # -- what a state implies: one plant per rule --------------------------------------------
      plant(:job_state_coherence, "an executing job that was never attempted", id,
        scenarios: [
          change_jobs(deep, fn [j | rest] ->
            [built(j, now, %{state: "executing", attempt: 0}) | rest]
          end)
        ],
        problem: {:job_state_coherence, job_id, :attempt_required}
      ),
      plant(:job_state_coherence, "a completed job at attempt zero", id,
        scenarios: [
          change_jobs(deep, fn [j | rest] ->
            [built(j, now, %{state: "completed", attempt: 0}) | rest]
          end)
        ],
        problem: {:job_state_coherence, job_id, :attempt_required}
      ),
      plant(:job_state_coherence, "a job past its last attempt", id,
        scenarios: [
          change_jobs(deep, fn [j | rest] ->
            [built(j, now, %{state: "executing", attempt: j.max_attempts + 1}) | rest]
          end)
        ],
        problem: {:job_state_coherence, job_id, :attempt_over_max}
      ),
      plant(:job_state_coherence, "an attempt with no attempted_at", id,
        scenarios: [change_jobs(deep, fn [j | rest] -> [%{j | attempt: 1} | rest] end)],
        problem: {:job_state_coherence, job_id, :attempted_at_mismatch}
      ),
      plant(:job_state_coherence, "an attempted_at on a job never attempted", id,
        scenarios: [
          change_jobs(deep, fn [j | rest] ->
            [%{j | attempted_at: DateTime.add(now, -10)} | rest]
          end)
        ],
        problem: {:job_state_coherence, job_id, :attempted_at_mismatch}
      ),
      plant(:job_state_coherence, "a retryable job with no error", id,
        scenarios: [
          change_jobs(deep, fn [j | rest] ->
            [built(j, now, %{state: "retryable", attempt: 1, scheduled_in: 480}) | rest]
          end)
        ],
        problem: {:job_state_coherence, job_id, :errors_required}
      ),
      plant(:job_state_coherence, "a discarded job with no error", id,
        scenarios: [
          change_jobs(deep, fn [j | rest] ->
            [built(j, now, %{state: "discarded", attempt: j.max_attempts}) | rest]
          end)
        ],
        problem: {:job_state_coherence, job_id, :errors_required}
      ),
      plant(:job_state_coherence, "a completed job with no completed_at", id,
        scenarios: [
          change_jobs(deep, fn [j | rest] ->
            [%{built(j, now, %{state: "completed", attempt: 1}) | completed_at: nil} | rest]
          end)
        ],
        problem: {:job_state_coherence, job_id, :completed_at_required}
      ),
      plant(:job_state_coherence, "a completed_at on a job that did not complete", id,
        scenarios: [
          change_jobs(deep, fn [j | rest] ->
            [%{j | completed_at: DateTime.add(now, -5)} | rest]
          end)
        ],
        problem: {:job_state_coherence, job_id, :completed_at_unexpected}
      ),
      # -- the order of a job's own stamps ------------------------------------------------------
      plant(:job_time_order, "a job completed before it was attempted", id,
        scenarios: [
          change_jobs(deep, fn [j | rest] ->
            done = built(j, now, %{state: "completed", attempt: 1})
            [%{done | completed_at: DateTime.add(now, -5_000)} | rest]
          end)
        ],
        problem: {:job_time_order, job_id}
      ),
      plant(:job_time_order, "an executing job attempted before its scheduled time", id,
        scenarios: [
          change_jobs(deep, fn [j | rest] ->
            [built(j, now, %{state: "executing", attempt: 1, scheduled_in: 60}) | rest]
          end)
        ],
        problem: {:job_time_order, job_id}
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
      ),
      # The source plants are in memory (a `{path, content}` pair) so the table needs no files; the
      # provenance test plants the same causes as real temporary files. A raw format character is
      # built from its bytes, never typed.
      plant(:raw_format_char, "a file holding a right-to-left override", :source,
        scenarios: [deep],
        source_files: [{planted_lib <> "/planted.txt", "a" <> <<0xE2, 0x80, 0xAE>> <> "b"}],
        problem: {:raw_format_char, planted_lib <> "/planted.txt", 0x202E}
      ),
      plant(:impure_source, "a lib file that reads the wall clock", :source,
        scenarios: [deep],
        source_files: [
          {planted_lib <> "/planted.ex",
           "defmodule Planted do\n  def at, do: DateTime.utc_now()\nend\n"}
        ],
        problem: {:impure_source, planted_lib <> "/planted.ex", "DateTime.utc_now"}
      ),
      plant(:denylisted_word, "a label that makes a compliance claim", id,
        scenarios: [deep],
        labels: [{id, "Logistify shipments, HIPAA ready (fictional)"}],
        problem: {:denylisted_word, {:label, id}, "HIPAA"}
      ),
      plant(:provenance_missing, "an adopter schema with no provenance line", :source,
        scenarios: [deep],
        source_files: [
          {planted_lib <> "/logistify/planted.ex",
           "defmodule Planted do\n  @moduledoc \"A shipment schema.\"\nend\n"}
        ],
        problem: {:provenance_missing, planted_lib <> "/logistify/planted.ex"}
      ),
      plant(:bulk_digest, "a bulk sample whose record changed", :bulk,
        scenarios: [deep],
        bulk_sample: changed_sample,
        problem: {:bulk_digest, Bulk.digest(changed_sample)}
      )
    ]
  end

  # Everything wrong with how one plant was reported; an empty list means it was reported cleanly.
  defp plant_failures(plant, result) do
    case result do
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

  # A job built the way the real builder builds one, from the deep queue's first job: an available
  # upsert with that job's id, queue, args and `max_attempts`, unless `attrs` say otherwise. The
  # builder stamps what the state implies (an attempt stamps `attempted_at`, a completed job
  # `completed_at`), so a plant changes the one field it names and nothing else.
  defp built(job, now, attrs) do
    base = %{
      id: job.id,
      state: "available",
      worker: :upsert,
      queue: job.queue,
      args: job.args,
      now: now,
      ago: 120,
      max_attempts: job.max_attempts
    }

    ObanJob.job(Map.merge(base, attrs))
  end

  # A succeeded task on the scenario's index with the given uid, enqueued `ago` seconds before now.
  defp task_enqueued(scenario, uid, ago) do
    Meili.task(%{
      type: "documentAdditionOrUpdate",
      status: "succeeded",
      uid: uid,
      index_uid: scenario |> task_at(0) |> Map.fetch!("indexUid"),
      now: scenario.now,
      enqueued_ago: ago
    })
  end

  defp change_tasks(scenario, fun), do: update_in(scenario.scrypath_opts[:meilisearch_tasks], fun)
  defp change_jobs(scenario, fun), do: update_in(scenario.scrypath_opts[:oban_jobs], fun)

  defp task_at(scenario, index),
    do: scenario.scrypath_opts |> Keyword.fetch!(:meilisearch_tasks) |> Enum.at(index)

  defp job_at(scenario, index),
    do: scenario.scrypath_opts |> Keyword.fetch!(:oban_jobs) |> Enum.at(index)
end
