defmodule ScrypathOpsWeb.FixturesHostileRenderTest do
  @moduledoc false
  # Phase 196: the Shopadelic hostile_ids stress scenario carries every string of
  # ScrypathFixtures.Hostile where the real system can carry it. This module proves two things.
  #
  #   1. Placement (pure): each hostile string sits only where Meilisearch and Scrypath can produce
  #      it, so the stress data is reachable and not invented.
  #   2. Escaping (rendered, security V5): the operator pages show the markup as text and create no
  #      script element. The assertions use LazyHTML selectors, never raw-HTML matching.
  #
  # App env is global, so this module is async: false and every test that puts a scenario restores
  # the env it touched through FixtureEnv.
  #
  # Unbounded error text is finding F2 (handed to the maintainer, not fixed here), so nothing below
  # asserts that long text is truncated.
  #
  # No raw bidirectional or zero-width character is typed in this file: a hostile character is
  # referenced through ScrypathFixtures.Hostile, whose source holds only escapes.
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScrypathFixtures.Hostile
  alias ScrypathFixtures.Scenarios
  alias ScrypathOps.Test.FixtureEnv

  @scenario_id :shopadelic_hostile_ids

  # Meilisearch's rule for a document id: a-z A-Z 0-9, hyphen and underscore, at most 511 bytes.
  @valid_id ~r/\A[A-Za-z0-9_-]{1,511}\z/

  describe "placement: each hostile string sits only where the real system can carry it" do
    setup do
      %{scenario: Scenarios.get!(@scenario_id, ScrypathFixtures.preview_epoch())}
    end

    test "the scenario is the one named stress variation, and says so", %{scenario: scenario} do
      assert scenario.kind == :stress
      assert scenario.label =~ "stress"
      assert scenario.label =~ "(fictional)"
    end

    test "the strings have the properties their names claim" do
      assert byte_size(Hostile.id_511()) == 511
      assert Hostile.id_511() =~ @valid_id
      assert byte_size(Hostile.id_512()) == 512
      assert String.length(Hostile.token_200()) == 200
      refute Hostile.token_200() =~ ~r/\s/
      assert Hostile.token_200() =~ @valid_id
      refute Hostile.nfc() == Hostile.nfd()
      assert :unicode.characters_to_nfc_binary(Hostile.nfd()) == Hostile.nfc()
      assert String.contains?(Hostile.bidi_override(), <<0xE2, 0x80, 0xAE>>)
      assert Hostile.all() |> Keyword.keys() |> length() == 12
    end

    test "every invalid-character id is rejected as invalid_document_id, and echoed as sent", %{
      scenario: scenario
    } do
      echoed =
        for %{"status" => "failed", "error" => %{"code" => "invalid_document_id"} = error} <-
              tasks(scenario) do
          # the message holds the id as the JSON string the customer sent
          [_all, json] =
            Regex.run(~r/\ADocument identifier `(.*)` is invalid\./s, error["message"])

          Jason.decode!(json)
        end

      assert length(echoed) == 10
      # a rejected id is outside Meilisearch's rule: a bad character, or over 511 bytes
      assert Enum.all?(echoed, fn id -> not (id =~ @valid_id) end)
      assert Hostile.id_512() in echoed
      assert ("SPD-" <> Hostile.markup()) in echoed

      for string <- [
            Hostile.bidi_override(),
            Hostile.bidi_isolates(),
            Hostile.zwj_family(),
            Hostile.zero_width_space(),
            Hostile.nfc(),
            Hostile.nfd(),
            Hostile.cjk(),
            Hostile.arabic()
          ] do
        assert ("SPD-" <> string) in echoed
      end
    end

    test "the markup and the non-Latin text are echoed inside one document, as the server does",
         %{
           scenario: scenario
         } do
      [message] =
        for %{"error" => %{"code" => "missing_document_id", "message" => message}} <-
              tasks(scenario),
            do: message

      assert message =~ Hostile.markup()
      assert message =~ Hostile.cjk()
      assert message =~ Hostile.arabic()
    end

    test "the 511-byte id and the 200-character token appear only as valid job document ids", %{
      scenario: scenario
    } do
      jobs = Keyword.fetch!(scenario.scrypath_opts, :oban_jobs)
      ids = Enum.flat_map(jobs, & &1.args["document_ids"])

      assert Hostile.id_511() in ids
      assert Hostile.token_200() in ids
      # every id a job carries is one Meilisearch accepts
      assert Enum.all?(ids, &(&1 =~ @valid_id))

      # the long ids are also on the discarded and the retryable job, the rows an operator reads
      by_state = Map.new(jobs, &{&1.state, &1.args["document_ids"]})
      assert Hostile.id_511() in by_state["discarded"]
      assert Hostile.token_200() in by_state["retryable"]

      # and never as the id a failed task rejects (they are valid, so the server would not): the
      # 512-byte id contains the 511-byte one as a prefix, so this compares whole ids, not text
      rejected = rejected_ids(scenario)
      refute Hostile.id_511() in rejected
      refute Hostile.token_200() in rejected
      refute scenario.label =~ Hostile.id_511()
      refute scenario.label =~ Hostile.token_200()
    end

    test "the check passes, so the scenario is one the real code can produce", %{
      scenario: scenario
    } do
      assert {:ok, %{scenarios: 1}} = ScrypathFixtures.Check.run(scenarios: [scenario])
    end
  end

  describe "escaping: the operator pages show the markup as text and run nothing" do
    setup do
      scenario = Scenarios.get!(@scenario_id, ScrypathFixtures.preview_epoch())
      on_exit(FixtureEnv.put(scenario))
      %{scenario: scenario}
    end

    test "the failed sync page lists every failed row and shows the markup as text", %{conn: conn} do
      {:ok, lv, _document} = live(conn, ~p"/ops/failed-sync")
      document = lv |> render() |> LazyHTML.from_fragment()

      # ten rejected ids, one echoed document, the discarded job and the retrying one
      assert count(document, "[data-testid='failed-sync-row']") == 13

      assert no_script_with_alert?(document)

      # the markup is text inside the error block, the characters it was sent as
      reasons =
        document |> LazyHTML.query("[data-testid='failed-sync-reason']") |> LazyHTML.text()

      assert reasons =~ Hostile.markup()
      assert reasons =~ Hostile.cjk()
      assert reasons =~ Hostile.arabic()

      # and the page text as a whole holds it literally, so an escaped angle bracket reads back
      assert LazyHTML.text(document) =~ Hostile.markup()
    end

    test "no element is created from the markup text on the failed sync page", %{conn: conn} do
      {:ok, lv, _document} = live(conn, ~p"/ops/failed-sync")
      document = lv |> render() |> LazyHTML.from_fragment()

      # the sent markup would create these if it were not escaped
      assert count(document, "script") == 0
      assert count(document, "[data-testid='failed-sync-reason'] script") == 0
    end

    test "the health page renders the same scenario with no script element", %{conn: conn} do
      {:ok, lv, _document} = live(conn, ~p"/ops/health")
      document = lv |> render() |> LazyHTML.from_fragment()

      assert count(document, ".ops-posture-verdict") >= 1
      assert no_script_with_alert?(document)
      assert count(document, "script") == 0
    end
  end

  # -- helpers -------------------------------------------------------------------------------

  defp tasks(scenario), do: Keyword.fetch!(scenario.scrypath_opts, :meilisearch_tasks)

  # The id of every task Meilisearch rejected with invalid_document_id, as the message echoes it:
  # the JSON string the customer sent.
  defp rejected_ids(scenario) do
    for %{"error" => %{"code" => "invalid_document_id", "message" => message}} <- tasks(scenario) do
      [_all, json] = Regex.run(~r/\ADocument identifier `(.*)` is invalid\./s, message)
      Jason.decode!(json)
    end
  end

  defp count(document, selector), do: document |> LazyHTML.query(selector) |> Enum.count()

  # No script element whose text contains the alert call the markup carries.
  defp no_script_with_alert?(document) do
    document
    |> LazyHTML.query("script")
    |> Enum.all?(fn script -> not (LazyHTML.text(script) =~ "alert") end)
  end
end
