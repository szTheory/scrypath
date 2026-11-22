defmodule ScrypathOps.FixturesRecordingsTest do
  @moduledoc false
  # Phase 196: the Meilisearch v1.15 payloads recorded once from a real server are the evidence for
  # every shape the fixture builders and the fake client produce. Key sets and value types only,
  # never values (uids and stamps differ on every recording run).
  #
  # Pure: no app env, no database. Every plant changes one field of a real scenario and asserts the
  # exact problem tag it must produce, with a positive control beside it.
  use ExUnit.Case, async: true

  alias ScrypathFixtures.Check
  alias ScrypathFixtures.FakeMeilisearchClient
  alias ScrypathFixtures.Failures
  alias ScrypathFixtures.Logistify
  alias ScrypathFixtures.Meili
  alias ScrypathFixtures.ObanJob
  alias ScrypathFixtures.Recordings

  @scenario_id :logistify_deep_queue
  @document_types ["documentAdditionOrUpdate", "documentDeletion"]
  @index "logistify_shipment"
  # ids of the failed task and the discarded job `with_failures/1` adds to the real deep queue
  @failed_uid 900
  @failed_job_id 901

  describe "Recordings" do
    test "every recording is decoded, listed and named in PROVENANCE.md" do
      files = Recordings.files()
      assert length(files) >= 25
      assert unlisted(files, Recordings.provenance()) == []
    end

    test "a file missing from PROVENANCE.md is reported by its name" do
      provenance = String.replace(Recordings.provenance(), "`22-list-page1-limit3.json`", "")

      assert unlisted(Recordings.files(), provenance) == ["22-list-page1-limit3"]
    end

    test "the server and image the recordings came from are named" do
      assert %{"pkgVersion" => "1.15." <> _patch} = Recordings.body!("01-version")
      assert Recordings.provenance() =~ "getmeili/meilisearch:v1.15"
      assert Recordings.provenance() =~ "sha256:"
    end

    test "one exemplar per status, each with that status" do
      assert Recordings.statuses() == [
               "canceled",
               "enqueued",
               "failed",
               "processing",
               "succeeded"
             ]

      for status <- Recordings.statuses() do
        assert %{"status" => ^status} = Recordings.task_exemplar!(status)
      end

      assert_raise ArgumentError, ~r/no recorded task exemplar for status "weird"/, fn ->
        Recordings.task_exemplar!("weird")
      end

      assert_raise ArgumentError, ~r/no recording named "nope"/, fn ->
        Recordings.body!("nope")
      end
    end

    test "details key sets are recorded per type; settingsUpdate is exempt" do
      assert Recordings.details_keys("documentAdditionOrUpdate") ==
               ["indexedDocuments", "receivedDocuments"]

      assert Recordings.details_keys("documentDeletion") ==
               ["deletedDocuments", "originalFilter", "providedIds"]

      assert Recordings.details_keys("indexCreation") == ["primaryKey"]
      assert Recordings.details_keys("indexSwap") == ["swaps"]
      assert Recordings.details_keys("settingsUpdate") == :any
      assert Recordings.details_keys("taskCancelation") == nil
    end

    test "the default settings have the 20 keys of v1.15" do
      assert map_size(Recordings.default_settings()) == 20
      assert Recordings.default_settings()["filterableAttributes"] == []
    end

    test "value_type/1 names the JSON kinds" do
      assert Recordings.value_type(nil) == :null
      assert Recordings.value_type("x") == :string
      assert Recordings.value_type(3) == :integer
      assert Recordings.value_type(%{}) == :map
      assert Recordings.value_type([]) == :list
      assert Recordings.value_type(true) == :boolean
      assert Recordings.value_type(1.5) == :other
    end
  end

  describe "builder shapes" do
    test "a task of each status has the recorded exemplar's keys and value types" do
      for status <- Recordings.statuses() do
        exemplar = Recordings.task_exemplar!(status)
        task = build(status)

        assert Enum.sort(Map.keys(task)) == Enum.sort(Map.keys(exemplar)),
               "#{status}: key set differs from the recording"

        for key <- Map.keys(exemplar) do
          assert Recordings.value_type(task[key]) == Recordings.value_type(exemplar[key]),
                 "#{status}: #{key} is a #{Recordings.value_type(task[key])}, recorded as " <>
                   "#{Recordings.value_type(exemplar[key])}"
        end
      end
    end

    test "details of each recorded type have the recorded keys and value types" do
      cases = [
        {"documentAdditionOrUpdate", "04-task-document-addition-succeeded", %{}},
        {"documentDeletion", "15-task-document-deletion-succeeded", %{}},
        {"indexCreation", "03-task-index-creation", %{}},
        {"indexSwap", "26-task-index-swap",
         %{index_uid: nil, swap: [@index, @index <> "__reindex"]}}
      ]

      for {type, recording, extra} <- cases do
        details = build("succeeded", Map.merge(%{type: type}, extra))["details"]
        recorded = recording |> Recordings.body!() |> Map.fetch!("details")

        assert Enum.sort(Map.keys(details)) == Recordings.details_keys(type)

        for {key, value} <- recorded do
          assert Recordings.value_type(details[key]) == Recordings.value_type(value),
                 "#{type}: details.#{key} differs in type from the recording"
        end
      end
    end

    test "a canceled task must say who canceled it" do
      assert_raise FunctionClauseError, ~r/ScrypathFixtures\.Meili\.task\/1/, fn ->
        Meili.task(Map.delete(attrs("canceled"), :canceled_by))
      end
    end
  end

  describe "fake client against the recorded lists" do
    setup do
      recorded = Recordings.body!("24-list-limit1000")["results"]
      config = [meilisearch_tasks: recorded]
      %{recorded: recorded, config: config}
    end

    test "limit 3 returns the recorded first page, its from and its next", %{config: config} do
      page = Recordings.body!("22-list-page1-limit3")

      assert {:ok, got} = FakeMeilisearchClient.tasks(filters(limit: 3), config)

      assert got["results"] == page["results"]
      assert uids(got) == uids(page)
      assert got["from"] == page["from"]
      assert got["next"] == page["next"]
      assert got["limit"] == page["limit"]
      assert got["total"] == page["total"]
      assert is_integer(got["next"])
    end

    test "the continuation returns the recorded second page", %{config: config} do
      page1 = Recordings.body!("22-list-page1-limit3")
      page2 = Recordings.body!("23-list-page2-from-next")

      assert {:ok, got} =
               FakeMeilisearchClient.tasks(filters(limit: 3, from: page1["next"]), config)

      assert got["results"] == page2["results"]
      assert uids(got) == uids(page2)
      assert got["from"] == page2["from"]
      assert got["next"] == page2["next"]
      assert got["from"] == page1["next"]
    end

    test "limit 1000 returns everything with no next, as recorded", %{config: config} do
      all = Recordings.body!("24-list-limit1000")

      assert {:ok, got} = FakeMeilisearchClient.tasks(filters(limit: 1000), config)

      assert uids(got) == uids(all)
      assert got["next"] == nil
      assert got["next"] == all["next"]
      assert got["from"] == all["from"]
    end

    test "an unknown index returns the recorded empty page", %{recorded: recorded} do
      page = Recordings.body!("25-list-unknown-index-empty")
      config = [meilisearch_tasks: recorded]

      assert {:ok, got} =
               FakeMeilisearchClient.tasks(
                 [index_uids: ["wikily_page"], types: @document_types, limit: 1000],
                 config
               )

      assert got["results"] == page["results"]
      assert got["results"] == []
      assert got["from"] == page["from"]
      assert got["next"] == page["next"]
    end

    test "a swap task (null indexUid) never appears under an indexUids filter" do
      swap = Recordings.body!("26-task-index-swap")
      assert swap["indexUid"] == nil
      config = [meilisearch_tasks: [swap]]

      for index <- [@index, @index <> "__reindex"] do
        assert {:ok, got} =
                 FakeMeilisearchClient.tasks([index_uids: [index], types: ["indexSwap"]], config)

        assert got["results"] == []
      end

      # positive control: with no index filter the same fake does return it
      assert {:ok, all} = FakeMeilisearchClient.tasks([types: ["indexSwap"]], config)
      assert uids(all) == [swap["uid"]]
    end

    test "finding F3 evidence: the recorded filtered swap lists are empty and the unfiltered one is not" do
      for name <- ["27-list-swap-live", "28-list-swap-partner"] do
        page = Recordings.body!(name)
        assert page["results"] == [], "#{name}: results should be empty"
        assert page["total"] == 1, "#{name}: total should still count the swap"
      end

      unfiltered = Recordings.body!("29-list-swap-unfiltered")
      assert [%{"type" => "indexSwap", "indexUid" => nil}] = unfiltered["results"]

      # what the fake does for the same task set
      swap = Recordings.body!("26-task-index-swap")

      assert {:ok, %{"results" => []}} =
               FakeMeilisearchClient.tasks(
                 [index_uids: [@index], types: ["indexSwap"]],
                 meilisearch_tasks: [swap]
               )
    end
  end

  describe "check against the recordings" do
    setup do
      %{scenario: Logistify.scenario(:deep_queue, now: ScrypathFixtures.preview_epoch())}
    end

    test "the real deep queue passes the shape checks (positive control)", %{scenario: scenario} do
      assert {:ok, %{scenarios: 1}} = Check.run(scenarios: [scenario])
      assert :task_shape in Check.invariants()
      assert :details_keys in Check.invariants()
    end

    test "a duration forced to an integer is a task_shape problem on duration", %{
      scenario: scenario
    } do
      planted =
        change_tasks(scenario, fn [task | rest] -> [Map.put(task, "duration", 100) | rest] end)

      uid = planted |> task_at(0) |> Map.fetch!("uid")

      assert {:error, problems} = Check.run(scenarios: [planted])
      assert {@scenario_id, {:task_shape, uid, "duration"}} in problems
      refute_wire_guard(problems)
      refute Enum.any?(problems, &match?({_id, {:details_keys, _uid}}, &1))
    end

    test "a stamp that is neither a string nor null is a task_shape problem on that stamp", %{
      scenario: scenario
    } do
      planted =
        change_tasks(scenario, fn [task | rest] -> [Map.put(task, "finishedAt", 5) | rest] end)

      uid = planted |> task_at(0) |> Map.fetch!("uid")

      assert {:error, problems} = Check.run(scenarios: [planted])
      assert {@scenario_id, {:task_shape, uid, "finishedAt"}} in problems
    end

    test "a details map that gains a key is a details_keys problem", %{scenario: scenario} do
      planted =
        change_tasks(scenario, fn [task | rest] ->
          [put_in(task, ["details", "extraKey"], 1) | rest]
        end)

      uid = planted |> task_at(0) |> Map.fetch!("uid")

      assert {:error, problems} = Check.run(scenarios: [planted])
      assert {@scenario_id, {:details_keys, uid}} in problems
      refute_wire_guard(problems)
      refute Enum.any?(problems, &match?({_id, {:task_shape, _uid, _key}}, &1))
    end

    test "a details map that loses a key is a details_keys problem", %{scenario: scenario} do
      planted =
        change_tasks(scenario, fn [task | rest] ->
          [update_in(task, ["details"], &Map.delete(&1, "receivedDocuments")) | rest]
        end)

      uid = planted |> task_at(0) |> Map.fetch!("uid")

      assert {:error, problems} = Check.run(scenarios: [planted])
      assert {@scenario_id, {:details_keys, uid}} in problems
    end
  end

  describe "Failures table" do
    test "an entry carries a source that resolves; an unknown id raises" do
      entry = Failures.entry!(:invalid_document_id)
      assert entry.source in Recordings.files()
      assert entry.surface == :meilisearch_task

      assert_raise FunctionClauseError, ~r/ScrypathFixtures\.Failures\.entry!\/1/, fn ->
        Failures.entry!(unknown_id())
      end
    end

    test "the table has seven unique entries and every source resolves" do
      entries = Failures.all()
      ids = Enum.map(entries, & &1.id)

      assert length(entries) == 7
      assert ids == Enum.uniq(ids)
      assert Enum.all?(entries, &(&1 == Failures.entry!(&1.id)))

      for entry <- entries do
        assert entry.source in Recordings.files() or
                 File.exists?(Path.join(repo_root(), entry.source)),
               "#{entry.id}: source #{entry.source} does not resolve"
      end
    end

    test "a Meilisearch entry renders the recorded error object, message code type and link" do
      recorded = fn name -> name |> Recordings.body!() |> Map.fetch!("error") end

      assert Failures.meili_error(:invalid_document_id, id: "LSH 2026/04") ==
               recorded.("05-task-failed-invalid-document-id-space-slash")

      assert Failures.meili_error(:invalid_document_id, id: "LSH-" <> String.duplicate("a", 508)) ==
               recorded.("06-task-failed-invalid-document-id-512-bytes")

      assert Failures.meili_error(:invalid_document_id,
               id: recorded_id("08-task-failed-invalid-document-id-hostile")
             ) == recorded.("08-task-failed-invalid-document-id-hostile")

      assert Failures.meili_error(:missing_document_id, document: recorded_document()) ==
               recorded.("09-task-failed-missing-document-id-markup")

      assert Failures.meili_error(:index_not_found_task, uid: "logistify_unknown") ==
               recorded.("10-task-failed-document-deletion-index-not-found")

      assert Failures.meili_error(:primary_key_no_candidate, []) ==
               recorded.("11-task-failed-primary-key-no-candidate")
    end

    test "bindings must be exactly the entry's, and the wrong surface raises" do
      assert_raise ArgumentError, ~r/:invalid_document_id takes bindings \[:id\], got \[\]/, fn ->
        Failures.meili_error(:invalid_document_id, [])
      end

      assert_raise ArgumentError, ~r/got \[:id, :uid\]/, fn ->
        Failures.meili_error(:invalid_document_id, id: "LSH-1", uid: "x")
      end

      assert_raise FunctionClauseError, fn -> Failures.meili_error(:oban_transport, []) end

      at = DateTime.add(ScrypathFixtures.preview_epoch(), -60)

      assert_raise FunctionClauseError, fn ->
        Failures.oban_error(:invalid_document_id, attempt: 1, at: at)
      end
    end

    test "an Oban entry renders attempt, at and the Oban.PerformError banner" do
      at = DateTime.add(ScrypathFixtures.preview_epoch(), -60)
      error = Failures.oban_error(:oban_transport, attempt: 3, at: at)

      assert Enum.sort(Map.keys(error)) == ["at", "attempt", "error"]
      assert error["attempt"] == 3
      assert error["at"] == DateTime.to_iso8601(at)

      assert String.starts_with?(
               error["error"],
               "** (Oban.PerformError) Scrypath.Oban.UpsertWorker failed with"
             )

      # the reason is exactly what inspect/1 prints for the real Req struct
      real = inspect({:error, {:transport_error, %Req.TransportError{reason: :econnrefused}}})

      assert error["error"] ==
               "** (Oban.PerformError) Scrypath.Oban.UpsertWorker failed with " <> real

      delete = Failures.oban_error(:oban_transport, attempt: 1, at: at, worker: :delete)
      assert delete["error"] =~ "Scrypath.Oban.DeleteWorker failed with"
    end

    test "the task-failed entry embeds the inspected task and is longer than 500 characters" do
      at = DateTime.add(ScrypathFixtures.preview_epoch(), -60)
      failed = build("failed")
      error = Failures.oban_error(:oban_task_failed, attempt: 8, at: at, task: failed)

      assert String.length(error["error"]) > 500
      assert error["error"] =~ "{:error, {:task_failed, %Scrypath.Operations.Task{"
      assert error["error"] =~ "invalid_document_id"

      assert_raise FunctionClauseError, fn ->
        Failures.oban_error(:oban_task_failed, attempt: 8, at: at, task: build("succeeded"))
      end
    end

    test "the invalid-job entry names the schema as Scrypath encodes it" do
      at = DateTime.add(ScrypathFixtures.preview_epoch(), -60)

      by_string =
        Failures.oban_error(:oban_cancel_invalid_job,
          attempt: 1,
          at: at,
          schema: "Elixir.Missing.Schema"
        )

      assert by_string["error"] ==
               "** (Oban.PerformError) Scrypath.Oban.UpsertWorker failed with " <>
                 ~s({:cancel, {:invalid_job, {:unknown_schema, "Elixir.Missing.Schema"}}})

      by_module =
        Failures.oban_error(:oban_cancel_invalid_job,
          attempt: 1,
          at: at,
          schema: ScrypathFixtures.Logistify.Shipment
        )

      assert by_module["error"] =~ ~s("Elixir.ScrypathFixtures.Logistify.Shipment")
    end

    test "the cannot-produce list names every impossible failure with a reason" do
      ids = Enum.map(Failures.cannot_produce(), & &1.id)

      for expected <- ~w(payload_too_large database_size_limit_reached no_space_left_on_device
                         per_tenant_drift minutes_of_lag per_document_size_limit
                         out_of_order_overwrite price_as_string) do
        assert expected in ids
      end

      assert Enum.all?(Failures.cannot_produce(), &(String.length(&1.reason) > 20))
    end
  end

  describe "builders cannot take failure text" do
    test "a failed task builds its error from the table, and the check recognizes it" do
      task = build("failed")

      assert task["error"] == Failures.meili_error(:invalid_document_id, id: "LSH 2026/04")
      assert Failures.meili_error?(task["error"], task["type"])
    end

    test "an error passed directly is rejected by the function head" do
      error = Recordings.task_exemplar!("failed")["error"]

      assert_raise FunctionClauseError, ~r/ScrypathFixtures\.Meili\.task\/1/, fn ->
        Meili.task(Map.put(attrs("failed"), :error, error))
      end
    end

    test "a failed task needs a failure and no other status takes one" do
      assert_raise FunctionClauseError, ~r/ScrypathFixtures\.Meili\.task\/1/, fn ->
        Meili.task(Map.delete(attrs("failed"), :failure))
      end

      assert_raise FunctionClauseError, ~r/ScrypathFixtures\.Meili\.task\/1/, fn ->
        Meili.task(Map.put(attrs("succeeded"), :failure, {:invalid_document_id, id: "LSH-1"}))
      end
    end

    test "an Oban job renders its errors from table tuples and rejects raw maps" do
      job = discarded_job(ScrypathFixtures.preview_epoch(), 8, [{:oban_transport, 8, []}])

      assert [%{"attempt" => 8, "at" => at, "error" => text}] = job.errors
      assert at == DateTime.to_iso8601(job.attempted_at)
      assert text =~ "** (Oban.PerformError) Scrypath.Oban.UpsertWorker failed with {:error,"
      assert Failures.oban_error?(hd(job.errors))

      raw = %{"attempt" => 8, "at" => at, "error" => "typed by hand"}

      assert_raise FunctionClauseError, ~r/ScrypathFixtures\.ObanJob\.error_entry\/3/, fn ->
        discarded_job(ScrypathFixtures.preview_epoch(), 8, [raw])
      end
    end
  end

  describe "check against the failure table" do
    setup do
      scenario = Logistify.scenario(:deep_queue, now: ScrypathFixtures.preview_epoch())
      %{scenario: scenario, failing: with_failures(scenario)}
    end

    test "failure text from the table passes all three invariants (positive control)", %{
      scenario: scenario,
      failing: failing
    } do
      assert {:ok, %{scenarios: 1}} = Check.run(scenarios: [failing])
      assert {:ok, %{scenarios: 1}} = Check.run(scenarios: [scenario], failures: Failures.all())
      assert {:ok, %{scenarios: 0}} = Check.run(scenarios: [], failures: Failures.all())

      for tag <- [:unknown_failure, :failure_source_missing, :forbidden_failure] do
        assert tag in Check.invariants()
      end
    end

    test "a hand-typed task message is an unknown_failure on that task", %{failing: failing} do
      planted =
        change_tasks(failing, fn tasks ->
          update_failed(tasks, &put_in(&1, ["error", "message"], "Something went wrong."))
        end)

      assert {:error, problems} = Check.run(scenarios: [planted])
      assert {@scenario_id, {:unknown_failure, @failed_uid}} in problems
      refute_wire_guard(problems)
      assert_only_failure_problem(problems, @failed_uid)
    end

    test "a code the table lacks is an unknown_failure on that task", %{failing: failing} do
      planted =
        change_tasks(failing, fn tasks ->
          update_failed(tasks, fn task ->
            Map.put(task, "error", %{
              "message" => "The request payload is too large.",
              "code" => "payload_too_large",
              "type" => "invalid_request",
              "link" => "https://docs.meilisearch.com/errors#payload_too_large"
            })
          end)
        end)

      assert {:error, problems} = Check.run(scenarios: [planted])
      assert {@scenario_id, {:unknown_failure, @failed_uid}} in problems
      assert_only_failure_problem(problems, @failed_uid)
    end

    test "a real error on a task type the server never produces it for is an unknown_failure", %{
      failing: failing
    } do
      planted =
        change_tasks(failing, fn tasks ->
          update_failed(tasks, &Map.put(&1, "type", "indexCreation"))
        end)

      assert {:error, problems} = Check.run(scenarios: [planted])
      assert {@scenario_id, {:unknown_failure, @failed_uid}} in problems
    end

    test "hand-typed Oban error text is an unknown_failure on that job", %{failing: failing} do
      planted =
        change_jobs(failing, fn jobs ->
          Enum.map(jobs, fn
            %{id: @failed_job_id} = job ->
              [entry] = job.errors
              %{job | errors: [Map.put(entry, "error", "** (RuntimeError) boom")]}

            job ->
              job
          end)
        end)

      assert {:error, problems} = Check.run(scenarios: [planted])
      assert {@scenario_id, {:unknown_failure, @failed_job_id}} in problems
      refute Enum.any?(problems, &match?({_id, {:unknown_failure, @failed_uid}}, &1))
    end

    test "an Oban error with an unknown reason after a known worker is an unknown_failure", %{
      failing: failing
    } do
      planted =
        change_jobs(failing, fn jobs ->
          Enum.map(jobs, fn
            %{id: @failed_job_id} = job ->
              [entry] = job.errors

              text =
                "** (Oban.PerformError) Scrypath.Oban.UpsertWorker failed with {:error, :something_else}"

              %{job | errors: [Map.put(entry, "error", text)]}

            job ->
              job
          end)
        end)

      assert {:error, problems} = Check.run(scenarios: [planted])
      assert {@scenario_id, {:unknown_failure, @failed_job_id}} in problems
    end

    test "an entry whose source is neither a recording nor an existing path is failure_source_missing",
         %{scenario: scenario} do
      real = Failures.entry!(:invalid_document_id)

      for bad <- ["99-no-such-recording", "lib/scrypath/does_not_exist.ex", nil] do
        planted = %{real | source: bad}

        assert {:error, problems} = Check.run(scenarios: [scenario], failures: [planted])

        assert {:failures, {:failure_source_missing, :invalid_document_id}} in problems,
               inspect(bad)

        refute Enum.any?(problems, &match?({:failures, {:forbidden_failure, _id}}, &1))
      end
    end

    # The guards in `Check` keep a source inside the repository. A plant proves its guard only if
    # the spelling would resolve to a real file without it, so each spelling below is first shown to
    # exist when it is joined onto the repository root the way a guard-free check would join it
    # (the traversal and the absolute spelling both point at a file that is there), and then shown
    # to be rejected. Without that first half the plants would be reported as missing whether or not
    # the guards existed.
    test "a source that reaches a real file by traversal or by an absolute spelling is failure_source_missing",
         %{scenario: scenario} do
      real = Failures.entry!(:invalid_document_id)

      spellings = [
        # needs the ".." guard: lib/../mix.exs is the repository's own mix.exs
        {"lib/../mix.exs", ".. guard"},
        # needs the :relative guard: Path.join re-roots it to lib/scrypath/meilisearch/client.ex
        {"/lib/scrypath/meilisearch/client.ex", "relative guard"}
      ]

      for {spelling, guard} <- spellings do
        assert File.exists?(Path.join(repo_root(), spelling)),
               "#{spelling} no longer resolves without the #{guard}, so it proves nothing"

        assert {:error, problems} =
                 Check.run(scenarios: [scenario], failures: [%{real | source: spelling}])

        assert {:failures, {:failure_source_missing, :invalid_document_id}} in problems,
               "#{spelling} was accepted: the #{guard} is missing"
      end

      # positive control: the plain relative spelling of the same file is accepted
      accepted = %{real | source: "lib/scrypath/meilisearch/client.ex"}
      assert {:ok, %{scenarios: 1}} = Check.run(scenarios: [scenario], failures: [accepted])
    end

    test "an entry on the cannot-produce list is a forbidden_failure, by code or by id", %{
      scenario: scenario
    } do
      real = Failures.entry!(:invalid_document_id)

      by_code = %{real | id: :planted_entry, code: "payload_too_large"}
      by_id = %{real | id: :minutes_of_lag}

      for {planted, id} <- [{by_code, :planted_entry}, {by_id, :minutes_of_lag}] do
        assert {:error, problems} = Check.run(scenarios: [scenario], failures: [planted])
        assert {:failures, {:forbidden_failure, id}} in problems
        refute Enum.any?(problems, &match?({:failures, {:failure_source_missing, _id}}, &1))
      end
    end
  end

  # -- helpers -------------------------------------------------------------------------------

  defp attrs(status) do
    base = %{
      type: "documentAdditionOrUpdate",
      status: status,
      uid: 1,
      index_uid: @index,
      now: ScrypathFixtures.preview_epoch(),
      enqueued_ago: 100
    }

    case status do
      "failed" -> Map.put(base, :failure, {:invalid_document_id, id: "LSH 2026/04"})
      "canceled" -> Map.put(base, :canceled_by, 12)
      _other -> base
    end
  end

  defp build(status, overrides \\ %{}),
    do: status |> attrs() |> Map.merge(overrides) |> Meili.task()

  defp filters(extra), do: [index_uids: [@index], types: @document_types] ++ extra

  defp uids(%{"results" => results}), do: Enum.map(results, & &1["uid"])

  # The base names in `files` that `provenance` never names with a backticked `<name>.json`.
  defp unlisted(files, provenance),
    do: Enum.reject(files, &String.contains?(provenance, "`#{&1}.json`"))

  defp change_tasks(scenario, fun), do: update_in(scenario.scrypath_opts[:meilisearch_tasks], fun)
  defp change_jobs(scenario, fun), do: update_in(scenario.scrypath_opts[:oban_jobs], fun)

  defp job_at(scenario, index),
    do: scenario.scrypath_opts |> Keyword.fetch!(:oban_jobs) |> Enum.at(index)

  defp repo_root, do: Path.expand("../../..", __DIR__)

  # An id outside the table, hidden from the compiler's type checker so the call is a runtime test.
  defp unknown_id, do: Enum.random([:made_up])

  # The id the server echoed in a recorded invalid_document_id message, as the decoded string.
  # Reading it back keeps the hostile characters out of this file's source.
  defp recorded_id(name) do
    message = name |> Recordings.body!() |> get_in(["error", "message"])
    [_all, json] = Regex.run(~r/\ADocument identifier `(.+)` is invalid\./s, message)
    Jason.decode!(json)
  end

  # The document the server echoed in the recorded missing_document_id message, with key order.
  defp recorded_document do
    message =
      "09-task-failed-missing-document-id-markup"
      |> Recordings.body!()
      |> get_in(["error", "message"])

    [_all, json] = Regex.run(~r/\ADocument doesn't have a `id` attribute: `(.+)`\.\z/s, message)
    %Jason.OrderedObject{values: pairs} = Jason.decode!(json, objects: :ordered_objects)
    pairs
  end

  # The real deep queue plus one failed task and one discarded job, both with failure text
  # rendered from the table.
  defp with_failures(scenario) do
    now = scenario.now
    first_job = job_at(scenario, 0)
    index = scenario |> task_at(0) |> Map.fetch!("indexUid")

    failed =
      Meili.task(%{
        type: "documentAdditionOrUpdate",
        status: "failed",
        uid: @failed_uid,
        index_uid: index,
        now: now,
        # the highest uid is the newest task: the deep queue's last task was enqueued 30 s ago
        enqueued_ago: 10,
        failure: {:invalid_document_id, id: "LSH 2026/04"}
      })

    job =
      ObanJob.job(%{
        id: @failed_job_id,
        state: "discarded",
        worker: :upsert,
        queue: first_job.queue,
        args: first_job.args,
        now: now,
        ago: 30,
        attempt: first_job.max_attempts,
        max_attempts: first_job.max_attempts,
        errors: [{:oban_transport, first_job.max_attempts, []}]
      })

    scenario |> change_tasks(&(&1 ++ [failed])) |> change_jobs(&(&1 ++ [job]))
  end

  defp update_failed(tasks, fun) do
    Enum.map(tasks, fn
      %{"uid" => @failed_uid} = task -> fun.(task)
      task -> task
    end)
  end

  defp discarded_job(now, attempts, errors) do
    ObanJob.job(%{
      id: 1,
      state: "discarded",
      worker: :upsert,
      queue: "logistify_sync",
      args: %{"operation" => "upsert"},
      now: now,
      ago: 30,
      attempt: attempts,
      max_attempts: 8,
      errors: errors
    })
  end

  # The plant changed failure text and nothing else, so that is the only problem reported.
  defp assert_only_failure_problem(problems, uid) do
    assert problems == [{@scenario_id, {:unknown_failure, uid}}]
  end

  defp task_at(scenario, index),
    do: scenario.scrypath_opts |> Keyword.fetch!(:meilisearch_tasks) |> Enum.at(index)

  # The plant reached the check as a well-formed wire shape; it did not fail in the wire guard.
  defp refute_wire_guard(problems) do
    refute Enum.any?(problems, &match?({_id, {:wire_guard, _uid}}, &1)),
           "plant tripped the wire guard instead of its own invariant: #{inspect(problems)}"
  end
end
