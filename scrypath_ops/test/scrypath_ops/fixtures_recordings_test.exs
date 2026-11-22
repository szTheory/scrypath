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
  alias ScrypathFixtures.Logistify
  alias ScrypathFixtures.Meili
  alias ScrypathFixtures.Recordings

  @scenario_id :logistify_deep_queue
  @document_types ["documentAdditionOrUpdate", "documentDeletion"]
  @index "logistify_shipment"

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
      "failed" -> Map.put(base, :error, Recordings.task_exemplar!("failed")["error"])
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

  defp task_at(scenario, index),
    do: scenario.scrypath_opts |> Keyword.fetch!(:meilisearch_tasks) |> Enum.at(index)

  # The plant reached the check as a well-formed wire shape; it did not fail in the wire guard.
  defp refute_wire_guard(problems) do
    refute Enum.any?(problems, &match?({_id, {:wire_guard, _uid}}, &1)),
           "plant tripped the wire guard instead of its own invariant: #{inspect(problems)}"
  end
end
