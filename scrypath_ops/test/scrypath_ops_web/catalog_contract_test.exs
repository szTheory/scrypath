defmodule ScrypathOpsWeb.CatalogContractTest do
  use ScrypathOpsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Mix.Tasks.ScrypathOps.Catalog.Serve
  alias ScrypathOps.Catalog.RenderAll
  alias ScrypathOps.Test.CatalogChecks
  alias ScrypathOps.Test.CopyRules

  # The catalog contract file (Phase 195 and 197), ledger row 11 of 12 in CONTRIBUTING.md. It runs in
  # the existing ops-ui job and adds no CI context.
  #
  # Every story under scrypath_ops/storybook is rendered ONCE (setup_all) through the real iframe
  # route, in light and dark; render-all, identical variations, DOM hygiene and copy all read that one
  # pass, so a new story needs no edit here. Coverage and provenance read the story modules.
  # Extend @primitive_stories only for a path that must never disappear. The planted-tree describe
  # proves the same render path plus RenderAll.problems/1 fails on a crash, an empty story and an
  # unknown variation id; keep it green when you change either helper.
  #
  # Primitive stories (primitives/) are exempt from the provenance line: a primitive is
  # adopter-independent, so it names no adopter, persona or job.
  #
  # Planted copy strings are built by concatenation so this file never spells a phrase a copy row
  # forbids (the casing row scans every tracked file).

  @primitive_stories [
    "/primitives/ops_button",
    "/primitives/ops_badge",
    "/primitives/ops_panel",
    "/primitives/ops_empty_state",
    "/primitives/ops_sync_status"
  ]
  @themes ["light", "dark"]
  @repo_root Path.expand("../../..", __DIR__)
  @build_info_key {ScrypathOps.Catalog, :build_info}
  @storybook_bundle Path.expand("../../priv/static/assets/js/storybook.js", __DIR__)
  @font_assignment "document.body.style.fontFamily = \"var(--font-sans)\""
  @quality_doc ".planning/reference/OPERATOR-UI-QUALITY.md"
  @journey_test "scrypath_ops/test/scrypath_ops_web/live/catalog_journey_test.exs"

  # What is knowingly not storied, one reason per key. A key a story now covers, or that names
  # nothing, fails as stale, so this map can only shrink as stories arrive. The reasons are shared
  # through attributes for groups; every key is still listed here, one line each.
  @primitive_not_storied "primitive not storied yet: Phase 198 or later"
  @shell_helper "app shell piece: rendered inside every surface story, not storied alone"
  @search_deferred "Search screen deferred (Phase 197 CONTEXT, Deferred Ideas): Phase 198 or v1.51"
  @no_story %{
    {ScrypathOpsWeb.OpsUi, :ops_action_group} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_checkbox_list} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_code_block} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_command_hint} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_command_palette} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_condition} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_config_empty} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_data_card} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_disclosure} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_empty_hero} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_field} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_fieldset} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_handoff} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_heading} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_help_link} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_inline_code} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_intent_card} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_link_button} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_loading} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_metric} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_metric_grid} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_modal} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_notice} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_number_input} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_object_item} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_object_list} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_page_header} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_refresh_button} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_refresh_control} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_result_row} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_scaffold} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_schema_select} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_section} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_segmented_control} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_select} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_sheet} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_signal_table} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_status} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_table} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_text_input} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_textarea} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_time} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_tone_chip} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_toolbar} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_trail} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_upload_box} => @primitive_not_storied,
    {ScrypathOpsWeb.OpsUi, :ops_verdict} => @primitive_not_storied,
    {ScrypathOpsWeb.ResultUi, :result_hit} => @search_deferred,
    {ScrypathOpsWeb.ResultUi, :result_value} => @search_deferred,
    {ScrypathOpsWeb.CoreComponents, :flash} => @shell_helper,
    {ScrypathOpsWeb.CoreComponents, :icon} => @shell_helper,
    {ScrypathOpsWeb.Layouts, :app} => @shell_helper,
    {ScrypathOpsWeb.Layouts, :brand_mark} => @shell_helper,
    {ScrypathOpsWeb.Layouts, :flash_group} => @shell_helper,
    {ScrypathOpsWeb.Layouts, :ops_mobile_nav} => @shell_helper,
    {ScrypathOpsWeb.Layouts, :ops_primary_nav} => @shell_helper,
    {ScrypathOpsWeb.Layouts, :ops_sidebar} => @shell_helper,
    ScrypathOpsWeb.ControlRoomLive =>
      "Control room deferred (Phase 197 CONTEXT, Deferred Ideas): Phase 198 or v1.51",
    ScrypathOpsWeb.SearchLive => @search_deferred,
    ScrypathOpsWeb.HelpLive =>
      "Help deferred (Phase 197 CONTEXT, Deferred Ideas): Phase 198 or v1.51",
    ScrypathOpsWeb.SyncDriftLive =>
      "Sync and index as a whole surface deferred (Phase 197 CONTEXT); its two recovery areas are storied"
  }

  # One render of every variation in both themes, shared by the checks below. The LiveViews it starts
  # are linked to this process and end with the module.
  setup_all do
    %{rendered: render_every_variation(), pages: render_every_page()}
  end

  describe "mount" do
    test "the real iframe route renders the production ops_button with the built stylesheet", %{
      conn: conn
    } do
      {:ok, _view, html} =
        live(conn, "/storybook/iframe/primitives/ops_button?variation_id=default&theme=light")

      doc = LazyHTML.from_document(html)

      button = LazyHTML.query(doc, "[data-phx-main] button")
      refute Enum.empty?(button)
      assert LazyHTML.text(button) =~ "Retry"

      styles = doc |> LazyHTML.query("style") |> LazyHTML.text()
      assert styles =~ ~r|@import "/assets/css/app\.css\?hash=[0-9a-f]{32}"|

      refute Enum.empty?(LazyHTML.query(doc, ~s(body[data-theme="light"])))
    end
  end

  describe "render-all" do
    test "every variation of every story renders non-empty with real css, js and theme", %{
      rendered: rendered,
      pages: pages
    } do
      targets = RenderAll.targets(ScrypathOps.Catalog.Storybook)
      paths = targets |> Enum.map(&elem(&1, 0)) |> Enum.uniq()

      for story <- @primitive_stories do
        assert story in paths, "missing story #{story}"
      end

      # A page story is rendered through the shell below; any other kind of story would be skipped
      # by the checks, so none may exist unnoticed.
      refute Enum.any?(targets, &match?({_, {:unsupported, _}}, &1))

      {page_targets, variation_targets} = Enum.split_with(targets, &match?({_, :page}, &1))

      # The shared pass covered every variation in both themes and every page once.
      assert length(rendered) == length(variation_targets) * length(@themes)
      assert Enum.map(pages, &elem(&1, 0)) == Enum.map(page_targets, &elem(&1, 0))
      assert "/welcome" in Enum.map(pages, &elem(&1, 0))

      page_failures =
        for {path, {:ok, html}} <- pages,
            problems = RenderAll.page_problems(html),
            problems != [] do
          {path, problems}
        end

      assert page_failures == [], "page render failures: #{inspect(page_failures)}"

      assert Enum.all?(pages, &match?({_, {:ok, _}}, &1)),
             "a page story crashed: #{inspect(pages)}"

      failures =
        for {path, variation_id, theme, document} <- rendered,
            result = document_result(document, theme),
            result != {:rendered, []},
            do: {path, variation_id, theme, result}

      assert failures == [], "render-all failures: #{inspect(failures)}"
    end
  end

  describe "no two identical variations" do
    test "no two variations of one story render the same page in a theme", %{rendered: rendered} do
      digests =
        for {path, variation_id, theme, {:ok, html}} <- rendered do
          {path, variation_id, theme, CatalogChecks.main_digest(html)}
        end

      # The cause is real data: the catalog has stories with several variations to compare.
      assert length(digests) > length(Enum.uniq_by(digests, &elem(&1, 0)))

      assert CatalogChecks.identical_variations(digests) == [],
             "variations that render identically (drop one or make it show a different state): " <>
               inspect(CatalogChecks.identical_variations(digests))
    end
  end

  describe "DOM hygiene" do
    test "every rendered story has unique ids, resolvable ARIA references and named controls", %{
      rendered: rendered,
      pages: pages
    } do
      problems =
        for {path, variation_id, theme, document} <- rendered,
            problem <- hygiene_problems(path, document) do
          {path, variation_id, theme, problem}
        end

      # A page story is checked over its own content (not the upstream shell around it), with no
      # main-landmark rule: the shell owns the page's main.
      page_problems =
        for {path, {:ok, html}} <- pages,
            problem <- CatalogChecks.dom_problems(page(RenderAll.page_markup(html)), :other) do
          {path, problem}
        end

      assert problems == [], "DOM hygiene problems: #{inspect(problems)}"

      assert page_problems == [],
             "DOM hygiene problems on a page story: #{inspect(page_problems)}"
    end
  end

  describe "coverage" do
    test "every component and LiveView route is shown by a story or listed in @no_story" do
      components = app_components()
      routes = app_routes()
      index = story_index()

      problems = CatalogChecks.coverage_problems(components, routes, index, @no_story)

      assert problems == [],
             "components and routes without a story or an @no_story reason, or stale @no_story keys: " <>
               inspect(problems)

      # The cause is real data: the inventory is computed, and both sides are non-trivial. Some
      # components are storied, some are listed, and the same goes for routes.
      assert Enum.any?(components, &(&1 in index.components))
      assert Enum.any?(components, &Map.has_key?(@no_story, &1))
      assert Enum.any?(routes, &(&1 in index.routes))
      assert Enum.any?(routes, &Map.has_key?(@no_story, &1))
    end
  end

  describe "provenance and descriptions" do
    test "every variation outside primitives names its adopter, persona, job and a proof it can back" do
      known = known_provenance()

      checked =
        for {path, story} <- loaded_stories(),
            CatalogChecks.tier(path) != :primitive,
            story.storybook_type() == :component,
            variation <- story.variations(),
            do: {path, story, variation}

      problems =
        for {path, story, variation} <- checked,
            problem <- CatalogChecks.provenance_problems(path, story, variation, known) do
          {path, variation.id, problem}
        end

      assert problems == [], "provenance problems: #{inspect(problems)}"

      # The cause is real data: variations were linted, and the proof labels in use are all kinds
      # (render only, a Mounted test, a Mounted test with a Claim).
      notes = for {_path, _story, variation} <- checked, do: variation.note
      refute notes == []
      assert Enum.any?(notes, &(&1 =~ "Proof: render only"))
      assert Enum.any?(notes, &(&1 =~ ~r/Proof: Mounted \S+\z/m))
      assert Enum.any?(notes, &(&1 =~ " · Claim: "))
    end

    test "the Job story's file name carries its job id and it names the journey test as its proof" do
      assert {"/jobs/job_03_on_call_recovers_failed_sync", story} =
               Enum.find(loaded_stories(), fn {path, _story} ->
                 CatalogChecks.tier(path) == :job
               end)

      assert story.job() == "JOB-03"
      assert ScrypathOpsWeb.FailedSyncLive in story.covers()

      for variation <- story.variations() do
        assert variation.note =~ "Proof: Mounted #{@journey_test}"
      end
    end
  end

  describe "copy rules over every rendered variation" do
    test "no rendered story spells text a global copy row forbids", %{
      rendered: rendered,
      pages: pages
    } do
      rows = CatalogChecks.copy_rows(CopyRules.load!())

      problems =
        for {path, variation_id, theme, {:ok, html}} <- rendered,
            problem <- CatalogChecks.copy_problems(story_markup(html), rows) do
          {path, variation_id, theme, problem}
        end

      page_problems =
        for {path, {:ok, html}} <- pages,
            problem <- CatalogChecks.copy_problems(RenderAll.page_markup(html), rows) do
          {path, problem}
        end

      assert problems == [], "copy problems: #{inspect(problems)}"
      assert page_problems == [], "copy problems on a page story: #{inspect(page_problems)}"

      # The cause is real data: rows govern the stories, and rendered text was read.
      refute rows == []
      assert Enum.any?(rows, &(&1["id"] == "control-room-casing"))
      assert Enum.any?(rendered, &match?({_, _, _, {:ok, _}}, &1))
    end

    test "copy_rows/1 keeps the rows that scan all copy and leaves state-specific rows out" do
      ids = CopyRules.load!() |> CatalogChecks.copy_rows() |> Enum.map(& &1["id"])

      # Scanned across scrypath_ops/lib or every file: a lexicon rule for all copy.
      assert "control-room-casing" in ids
      assert "pending-aggregate" in ids
      assert "clear-not-healthy" in ids

      # Describes one state (Clear beside a retained observation): a story of a healthy schema
      # legitimately says Clear, so the row must not govern it.
      refute "clear-needs-observation" in ids
      # Requires text and forbids nothing.
      refute "searchable-settings-row" in ids
    end
  end

  describe "planted coverage, provenance and copy" do
    test "coverage_problems/4 reports each planted cause as its own tagged problem" do
      a = {ScrypathOpsWeb.PlantedUi, :planted_a}
      b = {ScrypathOpsWeb.PlantedUi, :planted_b}
      c = {ScrypathOpsWeb.PlantedUi, :planted_c}
      shown = ScrypathOpsWeb.PlantedLive
      hidden = ScrypathOpsWeb.PlantedOtherLive

      index = %{components: [a], routes: [shown]}
      no_story = %{b => "shown later", c => "shown later", hidden => "deferred"}
      coverage = &CatalogChecks.coverage_problems([a, b, c], [shown, hidden], index, &1)

      # Control: everything is shown or listed with a reason.
      assert coverage.(no_story) == []

      # A listed key that names nothing is stale.
      gone = {ScrypathOpsWeb.PlantedUi, :planted_gone}
      assert coverage.(Map.put(no_story, gone, "named nothing")) == [{:stale_no_story, gone}]

      # A listed key that a story now covers is stale, for a component and for a route.
      assert coverage.(Map.put(no_story, a, "now storied")) == [{:stale_no_story, a}]
      assert coverage.(Map.put(no_story, shown, "now storied")) == [{:stale_no_story, shown}]

      # A component or route nothing shows and nothing lists is uncovered.
      assert coverage.(Map.delete(no_story, b)) == [{:uncovered, b}]
      assert coverage.(Map.delete(no_story, hidden)) == [{:uncovered, hidden}]

      # A reason is required, and one line.
      assert coverage.(Map.put(no_story, b, "  ")) == [{:no_reason, b}]
      assert coverage.(Map.put(no_story, b, "two\nlines")) == [{:no_reason, b}]
    end

    test "the real inventory reports a planted fake key, a covered key and a deleted story" do
      components = app_components()
      routes = app_routes()
      index = story_index()
      coverage = &CatalogChecks.coverage_problems(components, routes, index, &1)

      # Control: the real inventory passes, so each failure below comes from the plant.
      assert coverage.(@no_story) == []

      fake = {ScrypathOpsWeb.OpsUi, :no_such_component}
      assert coverage.(Map.put(@no_story, fake, "planted")) == [{:stale_no_story, fake}]

      covered = {ScrypathOpsWeb.OpsUi, :ops_button}
      assert covered in index.components
      assert coverage.(Map.put(@no_story, covered, "planted")) == [{:stale_no_story, covered}]

      # Delete the one story that shows a component: it becomes uncovered.
      failed_row = {ScrypathOpsWeb.Components.FailedSync, :failed_row}
      assert failed_row in index.components

      without_story = %{index | components: List.delete(index.components, failed_row)}

      assert CatalogChecks.coverage_problems(components, routes, without_story, @no_story) ==
               [{:uncovered, failed_row}]

      # A route only a surface or jobs story covers: drop that coverage and it is uncovered.
      assert ScrypathOpsWeb.FailedSyncLive in index.routes
      no_routes = %{index | routes: List.delete(index.routes, ScrypathOpsWeb.FailedSyncLive)}

      assert CatalogChecks.coverage_problems(components, routes, no_routes, @no_story) ==
               [{:uncovered, ScrypathOpsWeb.FailedSyncLive}]
    end

    test "area and pattern stories name their LiveView for traceability but do not count as route coverage" do
      area_covers =
        for {path, story} <- loaded_stories(),
            CatalogChecks.tier(path) in [:area, :pattern],
            function_exported?(story, :covers, 0),
            route <- story.covers(),
            do: route

      # SyncDriftLive is named only by area stories (the recovery areas), so it stays listed.
      assert ScrypathOpsWeb.SyncDriftLive in area_covers
      refute ScrypathOpsWeb.SyncDriftLive in story_index().routes
      assert Map.has_key?(@no_story, ScrypathOpsWeb.SyncDriftLive)
    end

    test "provenance_problems/4 reports each planted cause as its own tagged problem" do
      story = ScrypathOpsWeb.CatalogContractTest.PlantedJobStory
      path = "/jobs/job_03_planted"
      real = known_provenance()
      journey = File.read!(Path.join(@repo_root, @journey_test))
      claim = "an unresolved recovery handle renders a closed unavailable state"

      note = fn tail ->
        "Adopter: Shopadelic (fictional) · Persona: On-call (ROLE-OPS) · Job: JOB-03 · Proof: " <>
          tail
      end

      variation = fn tail, opts ->
        %{
          id: Keyword.get(opts, :id, :shopadelic_failed_journey_planted),
          description: Keyword.get(opts, :description, "Planted, within the limit."),
          note: Keyword.get(opts, :note, note.(tail))
        }
      end

      check = fn variation, known, path, story ->
        CatalogChecks.provenance_problems(path, story, variation, known)
      end

      reader = fn text -> %{real | read_file: fn _path -> {:ok, text} end} end

      # Controls: a render-only note, and a Mounted note whose file holds the scenario id, pass.
      assert check.(variation.("render only", []), real, path, story) == []
      assert check.(variation.("Mounted #{@journey_test}", []), real, path, story) == []

      # A job nothing defines (the story and the file name say the same job, so only that is reported).
      bad_job =
        variation.("render only", note: String.replace(note.("render only"), "JOB-03", "JOB-99"))

      assert check.(
               bad_job,
               real,
               "/jobs/job_99_planted",
               ScrypathOpsWeb.CatalogContractTest.PlantedJob99Story
             ) == [{:bad_job, "JOB-99"}]

      # A note whose job is not the story's own (the file name carries the note's job, so only the
      # mismatch is reported).
      assert check.(
               variation.("render only",
                 note: String.replace(note.("render only"), "JOB-03", "JOB-02")
               ),
               real,
               "/jobs/job_02_planted",
               story
             ) == [{:job_mismatch, "JOB-02", "JOB-03"}]

      # A jobs-tier file name that does not carry the job id.
      assert check.(variation.("render only", []), real, "/jobs/job_02_planted", story) ==
               [{:job_not_in_path, "JOB-03", "/jobs/job_02_planted"}]

      # A Mounted test file that does not exist.
      missing = "scrypath_ops/test/scrypath_ops_web/live/no_such_test.exs"

      assert check.(variation.("Mounted #{missing}", []), real, path, story) ==
               [{:missing_test, missing}]

      # A real test file that does not contain the scenario id: the description would claim more
      # than the test mentions. The control above holds the id; here it is removed.
      stripped = String.replace(journey, "shopadelic_failed_journey", "")
      refute stripped == journey

      assert check.(variation.("Mounted #{@journey_test}", []), reader.(stripped), path, story) ==
               [{:unbacked_proof, @journey_test, "shopadelic_failed_journey"}]

      assert check.(variation.("Mounted #{@journey_test}", []), reader.(journey), path, story) ==
               []

      # A declared claim replaces the scenario id as the needle: present passes, absent fails.
      with_claim = variation.("Mounted #{@journey_test} · Claim: #{claim}", [])
      assert check.(with_claim, reader.(journey <> "\n# " <> claim), path, story) == []

      assert check.(with_claim, reader.(journey), path, story) ==
               [{:unbacked_proof, @journey_test, claim}]

      # A Mounted label for a variation with no scenario in its id and no claim proves nothing.
      assert check.(
               variation.("Mounted #{@journey_test}", id: :no_scenario_here),
               real,
               path,
               story
             ) == [{:proof_without_needle, "no_scenario_here"}]

      # Descriptions: 140 characters pass, 141 fail, empty fails.
      assert check.(
               variation.("render only", description: String.duplicate("a", 140)),
               real,
               path,
               story
             ) ==
               []

      assert check.(
               variation.("render only", description: String.duplicate("a", 141)),
               real,
               path,
               story
             ) ==
               [{:long_description, 141}]

      assert check.(variation.("render only", description: ""), real, path, story) ==
               [{:missing_description, "shopadelic_failed_journey_planted"}]

      # An adopter or role that is not registered, and a note that is not a provenance line at all.
      assert check.(
               variation.("render only",
                 note: String.replace(note.("render only"), "Shopadelic", "Acmeco")
               ),
               real,
               path,
               story
             ) == [{:unknown_adopter, "Acmeco"}]

      assert check.(
               variation.("render only",
                 note: String.replace(note.("render only"), "ROLE-OPS", "ROLE-ZZZ")
               ),
               real,
               path,
               story
             ) == [{:unknown_role, "ROLE-ZZZ"}]

      for bad <- [
            nil,
            "",
            "Shopadelic, on-call, JOB-03",
            String.replace(note.("render only"), " (fictional)", "")
          ] do
        assert check.(variation.("render only", note: bad), real, path, story) ==
                 [{:no_provenance, "shopadelic_failed_journey_planted"}]
      end
    end

    test "provenance_problems/4 reads only the first line of the note, so a caption can follow it" do
      story = ScrypathOpsWeb.CatalogContractTest.PlantedJobStory

      variation = %{
        id: :shopadelic_failed_journey_planted,
        description: "Planted.",
        note:
          "Adopter: Shopadelic (fictional) · Persona: On-call (ROLE-OPS) · Job: JOB-03 · Proof: render only\n\nA caption paragraph."
      }

      assert CatalogChecks.provenance_problems(
               "/jobs/job_03_planted",
               story,
               variation,
               known_provenance()
             ) == []
    end

    test "copy_problems/2 reports a planted phrase with its row, and ignores clean markup" do
      rows = CatalogChecks.copy_rows(CopyRules.load!())

      # Control: the same markup without the phrase is clean.
      assert CatalogChecks.copy_problems("<p>Control room</p>", rows) == []

      casing = "Control " <> "Room"

      assert CatalogChecks.copy_problems("<p>#{casing}</p>", rows) ==
               [{:copy, "control-room-casing", casing}]

      status_word = "Heal" <> "thy"

      assert CatalogChecks.copy_problems("<p>#{status_word} schema</p>", rows) ==
               [{:copy, "clear-not-healthy", status_word}]
    end

    test "copy_problems/2 reports a phrase planted into a real story render", %{
      rendered: rendered
    } do
      rows = CatalogChecks.copy_rows(CopyRules.load!())

      {_path, _id, _theme, {:ok, html}} =
        Enum.find(rendered, fn {path, id, theme, _doc} ->
          path == "/surfaces/failed_sync" and id == "shopadelic_failed_journey" and
            theme == "light"
        end)

      markup = story_markup(html)

      # Control: the real render is clean, so the failure below comes from the plant.
      assert CatalogChecks.copy_problems(markup, rows) == []
      assert markup =~ "Failed sync work"

      casing = "Control " <> "Room"
      planted = String.replace(markup, "Failed sync work", casing, global: false)

      assert CatalogChecks.copy_problems(planted, rows) ==
               [{:copy, "control-room-casing", casing}]
    end

    test "dom_problems/2 counts main landmarks for a jobs-tier story, and a plant into the real job render fails",
         %{rendered: rendered} do
      assert CatalogChecks.dom_problems(page("<p>No landmark</p>"), :job) == [{:main_count, 0}]

      assert CatalogChecks.dom_problems(page("<main>A</main><main>B</main>"), :job) == [
               {:main_count, 2}
             ]

      assert CatalogChecks.dom_problems(page("<main>A</main>"), :job) == []

      path = "/jobs/job_03_on_call_recovers_failed_sync"

      {^path, _id, _theme, {:ok, html}} =
        Enum.find(rendered, fn {p, _id, theme, _doc} -> p == path and theme == "light" end)

      # Control: the real Job story renders one main.
      assert CatalogChecks.dom_problems(html, :job) == []

      without_main = Regex.replace(~r/<(\/?)main\b/, html, "<\\1div")
      refute without_main == html
      assert CatalogChecks.dom_problems(without_main, :job) == [{:main_count, 0}]
    end
  end

  describe "planted catalog checks" do
    test "identical_variations/1 reports a planted pair with its cause and ignores distinct pages" do
      distinct = [
        {"/areas/row", "retryable", "light", "d1"},
        {"/areas/row", "retrying", "light", "d2"}
      ]

      assert CatalogChecks.identical_variations(distinct) == []

      planted = distinct ++ [{"/areas/row", "retry_queued", "light", "d1"}]

      assert CatalogChecks.identical_variations(planted) ==
               [{:identical, "/areas/row", "light", ["retry_queued", "retryable"]}]

      # The same digest in another theme or another story is not a pair.
      apart = [
        {"/areas/row", "retryable", "light", "d1"},
        {"/areas/row", "retryable", "dark", "d1"},
        {"/areas/other", "retryable", "light", "d1"}
      ]

      assert CatalogChecks.identical_variations(apart) == []
    end

    test "main_digest/1 hashes the story's markup and ignores the per-mount session tokens" do
      page = fn token, text ->
        ~s(<html><body><div data-phx-main data-phx-session="#{token}" data-phx-static="#{token}">) <>
          ~s(<section><p>#{text}</p></section></div></body></html>)
      end

      assert CatalogChecks.main_digest(page.("aaa", "Same")) ==
               CatalogChecks.main_digest(page.("bbb", "Same"))

      refute CatalogChecks.main_digest(page.("aaa", "Same")) ==
               CatalogChecks.main_digest(page.("aaa", "Different"))
    end

    test "dom_problems/2 passes the real production render" do
      conn = build_conn()

      {:ok, _view, html} =
        live(conn, "/storybook/iframe/primitives/ops_button?variation_id=default&theme=light")

      assert CatalogChecks.dom_problems(html, CatalogChecks.tier("/primitives/ops_button")) == []
    end

    test "dom_problems/2 reports a cause planted into the real Failed sync renders", %{conn: conn} do
      {:ok, _view, filters} =
        live(
          conn,
          "/storybook/iframe/patterns/failed_filters?variation_id=shopadelic_failed_journey_mixed_causes&theme=light"
        )

      {:ok, _view, surface} =
        live(
          conn,
          "/storybook/iframe/surfaces/failed_sync?variation_id=shopadelic_failed_journey&theme=light"
        )

      # Controls: the real renders are clean, so each failure below comes from the edit.
      assert CatalogChecks.dom_problems(filters, :pattern) == []
      assert CatalogChecks.dom_problems(surface, :surface) == []

      # The cause chips are checkboxes named only by their wrapping label: without the labels none is
      # named.
      boxes =
        filters
        |> LazyHTML.from_document()
        |> LazyHTML.query("[data-phx-main] input[type=checkbox]")
        |> Enum.count()

      assert boxes > 0

      assert CatalogChecks.dom_problems(
               Regex.replace(~r/<\/?label\b[^>]*>/, filters, ""),
               :pattern
             ) ==
               List.duplicate({:unnamed_control, "input"}, boxes)

      # The summary section is labelled by the verdict heading's id: rename the id and the reference
      # dangles.
      renamed = String.replace(surface, ~s(id="failed-sync-summary-heading"), ~s(id="renamed"))
      refute renamed == surface

      assert CatalogChecks.dom_problems(renamed, :surface) ==
               [{:dangling_aria, "aria-labelledby", "failed-sync-summary-heading"}]
    end

    test "dom_problems/2 reports each planted cause as its own tagged problem" do
      assert CatalogChecks.dom_problems(page(~s(<p id="x">A</p><p id="x">B</p>)), :area) ==
               [{:duplicate_id, "x"}]

      assert CatalogChecks.dom_problems(page(~s(<div aria-describedby="false">A</div>)), :area) ==
               [{:dangling_aria, "aria-describedby", "false"}]

      assert CatalogChecks.dom_problems(page(~s(<div aria-labelledby="nope">A</div>)), :area) ==
               [{:dangling_aria, "aria-labelledby", "nope"}]

      assert CatalogChecks.dom_problems(page(~s(<div aria-controls="a b" id="a">A</div>)), :area) ==
               [{:dangling_aria, "aria-controls", "b"}]

      assert CatalogChecks.dom_problems(page("<button></button>"), :area) ==
               [{:unnamed_control, "button"}]

      assert CatalogChecks.dom_problems(
               page(~s(<button><span aria-hidden="true">x</span></button>)),
               :area
             ) == [{:unnamed_control, "button"}]

      assert CatalogChecks.dom_problems(page(~s(<a href="/x"></a>)), :area) ==
               [{:unnamed_control, "a"}]

      assert CatalogChecks.dom_problems(page(~s(<input type="checkbox" name="a">)), :area) ==
               [{:unnamed_control, "input"}]

      assert CatalogChecks.dom_problems(page("<p>No landmark</p>"), :surface) ==
               [{:main_count, 0}]

      assert CatalogChecks.dom_problems(page("<main>A</main><main>B</main>"), :surface) ==
               [{:main_count, 2}]

      assert CatalogChecks.dom_problems(
               page(~s(<main>A</main><div role="main">B</div>)),
               :surface
             ) ==
               [{:main_count, 2}]
    end

    test "dom_problems/2 accepts the ways a control is really named, and only checks mains on surfaces" do
      # A checkbox named only by its wrapping label (the Failed sync cause chips).
      assert CatalogChecks.dom_problems(
               page(~s(<label><input type="checkbox" name="a"><span>Cause</span></label>)),
               :area
             ) == []

      # A wrapping label with no text names nothing.
      assert CatalogChecks.dom_problems(
               page(~s(<label><input type="checkbox" name="a"></label>)),
               :area
             ) == [{:unnamed_control, "input"}]

      named = [
        ~s(<button>Retry</button>),
        ~s(<button aria-label="Close"><svg aria-hidden="true"></svg></button>),
        ~s(<button title="Copy"></button>),
        ~s(<h2 id="t">Title</h2><button aria-labelledby="t"></button>),
        ~s(<label for="a">Name</label><input id="a">),
        ~s(<a href="/x"><span class="sr-only">Home</span></a>),
        ~s(<input type="submit" value="Save">),
        ~s(<input type="hidden" name="csrf">),
        ~s(<button><img alt="Run" src="/x.png"></button>)
      ]

      for fragment <- named do
        assert CatalogChecks.dom_problems(page(fragment), :area) == [], fragment
      end

      # An id that resolves, and exactly one main, are clean.
      assert CatalogChecks.dom_problems(
               page(~s(<main><h2 id="t">T</h2><section aria-labelledby="t">S</section></main>)),
               :surface
             ) == []

      # Mains are only counted for surface-tier stories.
      assert CatalogChecks.dom_problems(page("<p>No landmark</p>"), :area) == []
    end

    test "tier/1 reads the story path's first segment" do
      assert CatalogChecks.tier("/surfaces/failed_sync") == :surface
      assert CatalogChecks.tier("/areas/failed_row") == :area
      assert CatalogChecks.tier("/patterns/failed_filters") == :pattern
      assert CatalogChecks.tier("/primitives/ops_button") == :primitive
      assert CatalogChecks.tier("/jobs/job_03") == :job
      assert CatalogChecks.tier("/welcome") == :other
    end
  end

  describe "start here page" do
    # These tests put a build-info term in the VM-wide persistent_term. No other test in this module
    # renders the welcome page while one of them runs (the shared pass finished in setup_all), and
    # each restores what it found.
    setup do
      previous = :persistent_term.get(@build_info_key, :none)

      on_exit(fn ->
        case previous do
          :none -> :persistent_term.erase(@build_info_key)
          info -> :persistent_term.put(@build_info_key, info)
        end
      end)

      :ok
    end

    test "/storybook opens on the welcome page", %{conn: conn} do
      assert {:error, {kind, %{to: to}}} = live(conn, "/storybook")
      assert kind in [:redirect, :live_redirect]
      assert URI.parse(to).path == "/storybook/welcome"
    end

    test "the welcome page prints each marker once, reading 'unknown' when no build info is stored",
         %{conn: conn} do
      :persistent_term.erase(@build_info_key)

      markers = welcome_markers(conn)

      assert markers == %{
               "data-catalog-main-sha" => "unknown",
               "data-catalog-head-sha" => "unknown",
               "data-catalog-dirty" => "unknown",
               "data-catalog-checkout" => "unknown",
               "data-catalog-epoch" => DateTime.to_iso8601(ScrypathFixtures.preview_epoch())
             }
    end

    test "the welcome page prints the stored build info, and nothing else", %{conn: conn} do
      info = %{
        main_sha: "0123456789ab",
        head_sha: "fedcba987654",
        dirty: "true",
        checkout: "/work/some checkout",
        epoch: DateTime.to_iso8601(ScrypathFixtures.preview_epoch())
      }

      :persistent_term.put(@build_info_key, info)

      assert welcome_markers(conn) == %{
               "data-catalog-main-sha" => "0123456789ab",
               "data-catalog-head-sha" => "fedcba987654",
               "data-catalog-dirty" => "true",
               "data-catalog-checkout" => "/work/some checkout",
               "data-catalog-epoch" => info.epoch
             }
    end

    test "the welcome page says what the screens are and claims no approval", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/storybook/welcome")
      text = html |> RenderAll.page_markup() |> LazyHTML.from_fragment() |> LazyHTML.text()

      # The title comes from the root index, outside the page's own content.
      title =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("#psb-story-live h2")
        |> LazyHTML.text()

      assert title =~ "Start here"

      for phrase <- [
            "same components as the real app",
            "made up",
            "Logistify",
            "Shopadelic",
            "Wikily",
            "Buttons and links do nothing",
            "2026-11-20 14:00 UTC",
            "Primitives",
            "Patterns",
            "Areas",
            "Surfaces",
            "Jobs",
            "on-call engineer (ROLE-OPS)",
            "JOB-03",
            "journey test",
            "upstream storybook library",
            "Nothing here is an approved design"
          ] do
        assert text =~ phrase, "the welcome page does not say: #{phrase}"
      end
    end

    test "the welcome page sets the product font itself, because storybook.js does not load in the shell",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, "/storybook/welcome")

      styles =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("[data-phx-main] .psb-sandbox style")
        |> LazyHTML.text()

      # The sandbox class sets a serif family on the page's container; without this rule the whole
      # page reads in serif, as the iframe stories did before the bundle fix.
      assert styles =~ "#catalog-start-here {"
      assert styles =~ "font-family: var(--font-sans)"
    end

    test "build_info/1 reads 12-character shas, the dirty flag and the checkout from git" do
      calls = :ets.new(:build_info_calls, [:public, :bag])

      run = fn args ->
        :ets.insert(calls, {args})

        case args do
          ["rev-parse", "--short=12", "refs/remotes/origin/main"] -> {"aaaaaaaaaaaa\n", 0}
          # git may print a longer abbreviation when 12 is ambiguous; the page keeps 12.
          ["rev-parse", "--short=12", "HEAD"] -> {"bbbbbbbbbbbbccc\n", 0}
          ["status", "--porcelain"] -> {" M scrypath_ops/lib/x.ex\n", 0}
          ["rev-parse", "--show-toplevel"] -> {"/work/checkout\n", 0}
        end
      end

      assert Serve.build_info(run) == %{
               main_sha: "aaaaaaaaaaaa",
               head_sha: "bbbbbbbbbbbb",
               dirty: "true",
               checkout: "/work/checkout",
               epoch: DateTime.to_iso8601(ScrypathFixtures.preview_epoch())
             }

      assert length(:ets.tab2list(calls)) == 4

      # A clean tree reads "false".
      clean = fn
        ["status", "--porcelain"] -> {"", 0}
        args -> run.(args)
      end

      assert %{dirty: "false", main_sha: "aaaaaaaaaaaa"} = Serve.build_info(clean)
    end

    test "build_info/1 reads 'unknown' for every git value when git fails, raises or prints junk" do
      epoch = DateTime.to_iso8601(ScrypathFixtures.preview_epoch())
      unknown = %{main_sha: "unknown", head_sha: "unknown", dirty: "unknown", checkout: "unknown"}

      failing = fn _args -> {"fatal: not a git repository", 128} end
      raising = fn _args -> raise "git is not installed" end

      # Exit 0 with output that is not a sha: refs and the checkout must not be guessed.
      junk = fn
        ["rev-parse", "--short=12", _ref] -> {"not-a-sha\n", 0}
        ["rev-parse", "--show-toplevel"] -> {"\n", 0}
        ["status", "--porcelain"] -> {"", 1}
      end

      for run <- [failing, raising, junk] do
        assert Serve.build_info(run) == Map.put(unknown, :epoch, epoch)
      end
    end

    test "build_info/1 with the real git gives a sha or 'unknown' for every ref, never a guess" do
      info = Serve.build_info()

      # A shallow hosted checkout has no origin/main ref, so only the shape is asserted.
      for key <- [:main_sha, :head_sha] do
        assert info[key] == "unknown" or info[key] =~ ~r/\A[0-9a-f]{12}\z/
      end

      assert info.dirty in ["true", "false", "unknown"]
      assert is_binary(info.checkout)
    end

    test "port_verdict/4 is :free when nothing listens, whatever the holder or the page say" do
      expected = build_facts("/work/checkout", "bbbbbbbbbbbb")
      page = served_page(expected)
      assert has_marker?(page)

      assert Serve.port_verdict(false, nil, nil, expected) == :free
      assert Serve.port_verdict(false, "beam.smp (pid 1)", page, expected) == :free
    end

    test "port_verdict/4 is :ours for this checkout at this commit, read back from the real page" do
      # The path holds characters the page escapes, so reading it back also exercises the unescaping.
      expected = build_facts(~s(/work/a&b "c" <d>), "bbbbbbbbbbbb")
      page = served_page(expected)

      assert has_marker?(page)
      refute page =~ expected.checkout, "the page was expected to escape the checkout path"
      assert printed_attribute(page, "data-catalog-checkout") == expected.checkout
      assert printed_attribute(page, "data-catalog-head-sha") == "bbbbbbbbbbbb"

      assert Serve.port_verdict(true, nil, page, expected) == :ours
      assert Serve.port_verdict(true, "beam.smp (pid 7)", page, expected) == :ours

      # origin/main moving does not change the code a catalog serves: only the checkout and HEAD count.
      moved = served_page(%{expected | main_sha: "cccccccccccc", dirty: "true"})
      assert printed_attribute(moved, "data-catalog-main-sha") == "cccccccccccc"
      assert Serve.port_verdict(true, nil, moved, expected) == :ours
    end

    test "port_verdict/4 holds the port for a catalog from another commit or checkout and names which" do
      expected = build_facts("/work/checkout", "bbbbbbbbbbbb")

      # Control: the same plant with this checkout's own facts is ours, so what follows is caused by
      # the one value each plant changes.
      control = served_page(expected)
      assert Serve.port_verdict(true, nil, control, expected) == :ours

      # A catalog started before a pull: this checkout, an older HEAD.
      stale = served_page(build_facts("/work/checkout", "aaaaaaaaaaaa"))
      assert has_marker?(stale)
      assert printed_attribute(stale, "data-catalog-checkout") == "/work/checkout"
      assert printed_attribute(stale, "data-catalog-head-sha") == "aaaaaaaaaaaa"

      assert Serve.port_verdict(true, nil, stale, expected) ==
               {:held,
                " by a catalog from /work/checkout at HEAD aaaaaaaaaaaa " <>
                  "(this checkout: /work/checkout at HEAD bbbbbbbbbbbb)"}

      assert Serve.port_verdict(true, "beam.smp (pid 7)", stale, expected) ==
               {:held,
                " by beam.smp (pid 7), a catalog from /work/checkout at HEAD aaaaaaaaaaaa " <>
                  "(this checkout: /work/checkout at HEAD bbbbbbbbbbbb)"}

      # Another worktree at the very same commit is still not this checkout's catalog.
      foreign = served_page(build_facts("/work/other", "bbbbbbbbbbbb"))
      assert printed_attribute(foreign, "data-catalog-checkout") == "/work/other"
      assert printed_attribute(foreign, "data-catalog-head-sha") == "bbbbbbbbbbbb"

      assert Serve.port_verdict(true, nil, foreign, expected) ==
               {:held,
                " by a catalog from /work/other at HEAD bbbbbbbbbbbb " <>
                  "(this checkout: /work/checkout at HEAD bbbbbbbbbbbb)"}
    end

    test "port_verdict/4 never calls a catalog ours when either side cannot say where it comes from" do
      known = build_facts("/work/checkout", "bbbbbbbbbbbb")
      unknown = Serve.build_info(fn _args -> {"", 128} end)
      assert %{checkout: "unknown", head_sha: "unknown"} = unknown

      known_page = served_page(known)
      unknown_page = served_page(unknown)
      assert printed_attribute(unknown_page, "data-catalog-checkout") == "unknown"
      assert printed_attribute(unknown_page, "data-catalog-head-sha") == "unknown"

      # "unknown" equals "unknown", which proves nothing about the checkout.
      assert Serve.port_verdict(true, nil, unknown_page, unknown) ==
               {:held,
                " by a catalog from unknown at HEAD unknown (this checkout: unknown at HEAD unknown)"}

      # The page cannot say, or this run cannot say.
      assert Serve.port_verdict(true, nil, unknown_page, known) ==
               {:held,
                " by a catalog from unknown at HEAD unknown " <>
                  "(this checkout: /work/checkout at HEAD bbbbbbbbbbbb)"}

      assert Serve.port_verdict(true, nil, known_page, unknown) ==
               {:held,
                " by a catalog from /work/checkout at HEAD bbbbbbbbbbbb " <>
                  "(this checkout: unknown at HEAD unknown)"}
    end

    test "port_verdict/4 holds the port for anything that is not a catalog page" do
      expected = build_facts("/work/checkout", "bbbbbbbbbbbb")

      # Something else listens: held, never ours, and the holder is named when it is known.
      other = "<html><body><h1>Another app</h1></body></html>"
      refute has_marker?(other)

      assert Serve.port_verdict(true, "beam.smp (pid 22117)", other, expected) ==
               {:held, " by beam.smp (pid 22117)"}

      assert Serve.port_verdict(true, nil, other, expected) == {:held, ""}
      assert Serve.port_verdict(true, "", other, expected) == {:held, ""}

      # It did not answer, or answered with something that is not a page.
      assert Serve.port_verdict(true, "beam.smp (pid 22117)", nil, expected) ==
               {:held, " by beam.smp (pid 22117)"}

      assert Serve.port_verdict(true, nil, false, expected) == {:held, ""}

      # Mentioning the markers in text is not carrying them as attributes (the verdict agrees with a
      # parsed document in every case here).
      mention = "<p>The data-catalog-main-sha attribute is described here.</p>"
      refute has_marker?(mention)
      assert Serve.port_verdict(true, nil, mention, expected) == {:held, ""}

      quoted =
        ~s(<p>data-catalog-main-sha="aaaaaaaaaaaa" data-catalog-checkout="/work/checkout" ) <>
          ~s(data-catalog-head-sha="bbbbbbbbbbbb"</p>)

      refute has_marker?(quoted)
      assert Serve.port_verdict(true, nil, quoted, expected) == {:held, ""}

      # A catalog page that lacks the checkout and HEAD markers cannot be placed, so it is not ours.
      partial = ~s(<dl><dd data-catalog-main-sha="aaaaaaaaaaaa">main@aaaaaaaaaaaa</dd></dl>)
      assert has_marker?(partial)

      assert Serve.port_verdict(true, nil, partial, expected) ==
               {:held,
                " by a catalog from unknown at HEAD unknown " <>
                  "(this checkout: /work/checkout at HEAD bbbbbbbbbbbb)"}
    end
  end

  describe "storybook bundle" do
    test "the tracked bundle sets the product font on the iframe body, and the check fails without it" do
      bundle = File.read!(@storybook_bundle)

      # Control: the tracked bundle passes, so the failure below comes from the plant.
      assert body_font_problem(bundle) == nil

      planted = String.replace(bundle, @font_assignment, "")
      refute planted == bundle
      assert body_font_problem(planted) == :missing_body_font

      # A different family does not satisfy it either.
      serif = String.replace(bundle, "var(--font-sans)", "serif")
      refute serif == bundle
      assert body_font_problem(serif) == :missing_body_font
    end
  end

  describe "planted tree" do
    setup do
      start_supervised!(ScrypathOps.Catalog.PlantedEndpoint)
      :ok
    end

    test "the same render-all path reports the planted crash, empty story and unknown variation" do
      # The unknown id is planted on the raising story (the plan's case) and on the story that renders
      # fine on its own, so the second crash can only come from the unknown id, not from a raising story.
      targets =
        RenderAll.targets(ScrypathOps.Catalog.PlantedStorybook) ++
          [{"/failing/boom", "no_such_variation"}, {"/failing/empty", "no_such_variation"}]

      {results, _log} =
        ExUnit.CaptureLog.with_log(fn ->
          Map.new(targets, fn {path, variation_id} ->
            url = RenderAll.url("/storybook", path, variation_id, "light")

            {{path, variation_id},
             render_target(ScrypathOps.Catalog.PlantedEndpoint, url, "light")}
          end)
        end)

      # A story that raises, or an id no variation owns, takes the iframe render down; both are errors
      # raised out of the request (the endpoint re-raises after rendering its 500 page), each with its own cause.
      assert results == %{
               {"/failing/boom", "boom"} =>
                 {:crashed, :error, "** (RuntimeError) planted render failure"},
               {"/failing/empty", "empty"} => {:rendered, ["empty output"]},
               {"/failing/boom", "no_such_variation"} => {:crashed, :error, ":function_clause"},
               {"/failing/empty", "no_such_variation"} => {:crashed, :error, ":function_clause"}
             }
    end

    test "problems/1 flags a missing sandbox, stripped hashes and a data-phx-error marker", %{
      conn: conn
    } do
      assert "no LiveView sandbox container" in RenderAll.problems("<html><body></body></html>")

      {:ok, _view, html} =
        live(conn, "/storybook/iframe/primitives/ops_button?variation_id=default&theme=light")

      # Control: the production render passes every check, so the failures below come from the edit.
      assert RenderAll.problems(html) == []
      assert RenderAll.theme_problem(html, "light") == nil
      assert RenderAll.theme_problem(html, "dark") == "body data-theme is not dark"

      stripped = Regex.replace(~r/\?hash=[0-9a-f]{32}/, html, "")
      refute stripped == html

      assert RenderAll.problems(stripped) == [
               "css_path did not resolve (no ?hash=)",
               "js_path did not resolve (no ?hash=)"
             ]

      marked =
        String.replace(html, "data-phx-main", ~s(data-phx-error="planted" data-phx-main),
          global: false
        )

      assert marked
             |> LazyHTML.from_document()
             |> LazyHTML.query("[data-phx-main][data-phx-error]")
             |> Enum.empty?() == false

      assert RenderAll.problems(marked) == ["data-phx-error present"]
    end
  end

  # Renders one iframe url through the real LiveView mount and returns the problems found, or
  # {:crashed, kind, cause} when the story or the route took the render down (the request raises or the
  # LiveView exits; both are caught, so a crash is data here, not a test error).
  defp render_target(endpoint, url, theme),
    do: endpoint |> render_document(url) |> document_result(theme)

  # The render-all verdict for one rendered document: the problems found, or the crash.
  defp document_result({:ok, html}, theme),
    do: {:rendered, RenderAll.problems(html) ++ List.wrap(RenderAll.theme_problem(html, theme))}

  defp document_result({:crashed, _kind, _cause} = crashed, _theme), do: crashed

  # The rendered iframe document, or the crash that took the render down.
  defp render_document(endpoint, url) do
    conn = Phoenix.ConnTest.dispatch(build_conn(), endpoint, :get, url, nil)
    {:ok, _view, html} = live(conn)
    {:ok, html}
  catch
    kind, reason -> {:crashed, kind, crash_cause(reason)}
  end

  # Every variation of every story in both themes through the real endpoint, as
  # `{path, variation_id, theme, {:ok, html} | {:crashed, kind, cause}}`.
  defp render_every_variation do
    for {path, variation_id} <- RenderAll.targets(ScrypathOps.Catalog.Storybook),
        not match?({:unsupported, _}, variation_id),
        variation_id != :page,
        theme <- @themes do
      url = RenderAll.url("/storybook", path, variation_id, theme)
      {path, variation_id, theme, render_document(ScrypathOpsWeb.Endpoint, url)}
    end
  end

  # Every page story through the storybook shell route, once, as `{path, {:ok, html} | {:crashed, ...}}`.
  defp render_every_page do
    for {path, :page} <- RenderAll.targets(ScrypathOps.Catalog.Storybook) do
      {path, render_document(ScrypathOpsWeb.Endpoint, RenderAll.page_url("/storybook", path))}
    end
  end

  defp hygiene_problems(path, {:ok, html}),
    do: CatalogChecks.dom_problems(html, CatalogChecks.tier(path))

  defp hygiene_problems(_path, {:crashed, kind, cause}), do: [{:crashed, kind, cause}]

  # The five build markers of the rendered welcome page: attribute name => value. Each selector must
  # match exactly one node.
  defp welcome_markers(conn) do
    {:ok, _view, html} = live(conn, "/storybook/welcome")
    doc = LazyHTML.from_document(html)

    for name <- [
          "data-catalog-main-sha",
          "data-catalog-head-sha",
          "data-catalog-dirty",
          "data-catalog-checkout",
          "data-catalog-epoch"
        ],
        into: %{} do
      nodes = LazyHTML.query(doc, "[#{name}]")
      assert Enum.count(nodes) == 1, "expected exactly one [#{name}] node"
      assert [value] = LazyHTML.attribute(nodes, name)
      {name, value}
    end
  end

  # Whether a parsed page carries the build marker the serve task looks for.
  defp has_marker?(html) do
    html |> LazyHTML.from_document() |> LazyHTML.query("[data-catalog-main-sha]") |> Enum.any?()
  end

  # Build facts as the serve task stores them, for a checkout and a HEAD.
  defp build_facts(checkout, head) do
    %{
      main_sha: "aaaaaaaaaaaa",
      head_sha: head,
      dirty: "false",
      checkout: checkout,
      epoch: DateTime.to_iso8601(ScrypathFixtures.preview_epoch())
    }
  end

  # The body the serve task fetches from a listener: the dead render of the landing page of a catalog
  # that stored `info` before it started.
  defp served_page(info) do
    :persistent_term.put(@build_info_key, info)
    Phoenix.ConnTest.get(build_conn(), "/storybook/welcome").resp_body
  end

  # What a page prints for one marker, read from the parsed document (not by the serve task's own
  # reader), so a plant is known to differ in exactly the value it claims to.
  defp printed_attribute(html, name) do
    nodes = html |> LazyHTML.from_document() |> LazyHTML.query("[#{name}]")
    assert [value] = LazyHTML.attribute(nodes, name)
    value
  end

  # What the storybook iframe needs from `storybook.js`: the product font on <body>. The sandbox class
  # sets `font-family: serif` there and beats the product stylesheet, so without this assignment every
  # story draws in a serif face. Reads the built bundle text; nil when the assignment is there.
  defp body_font_problem(bundle) do
    if Regex.match?(~r/document\.body\.style\.fontFamily\s*=\s*"var\(--font-sans\)"/, bundle),
      do: nil,
      else: :missing_body_font
  end

  # ── Inventory ─────────────────────────────────────────────────────────────

  # Every `{module, function}` function component of the app, computed from the loaded modules.
  defp app_components do
    for module <- Application.spec(:scrypath_ops, :modules),
        Code.ensure_loaded?(module),
        function_exported?(module, :__components__, 0),
        {name, _definition} <- module.__components__(),
        do: {module, name}
  end

  # Every LiveView module the dev router serves, minus storybook's own and the test-only Phase 173
  # fixture mount (the same module under another path).
  defp app_routes do
    for %{path: path, metadata: %{phoenix_live_view: {module, _action, _opts, _extra}}} <-
          Phoenix.Router.routes(ScrypathOpsWeb.DevRouter),
        not String.starts_with?(path, "/storybook"),
        not String.starts_with?(path, "/ops/phase173"),
        String.starts_with?(inspect(module), "ScrypathOpsWeb."),
        uniq: true,
        do: module
  end

  # Every story the catalog loads, as `{path, story module}`.
  defp loaded_stories do
    backend = ScrypathOps.Catalog.Storybook

    for entry <- backend.leaves(),
        {:ok, story} = backend.load_story(String.trim_leading(entry.path, "/")),
        do: {entry.path, story}
  end

  # What stories show: the function each component story renders, and the LiveViews that surface and
  # jobs stories cover. Area and pattern stories name a LiveView for traceability only.
  defp story_index do
    stories = loaded_stories()

    components =
      for {_path, story} <- stories,
          function_exported?(story, :function, 0),
          fun = story.function(),
          do: {Function.info(fun, :module) |> elem(1), Function.info(fun, :name) |> elem(1)}

    routes =
      for {path, story} <- stories,
          CatalogChecks.tier(path) in [:surface, :job],
          function_exported?(story, :covers, 0),
          route <- story.covers(),
          do: route

    %{components: Enum.uniq(components), routes: Enum.uniq(routes)}
  end

  # What provenance is checked against: the registered adopters, the roles and jobs the operator
  # quality doc defines, the fixture scenario ids, and a reader of repo-relative files.
  defp known_provenance do
    quality = File.read!(Path.join(@repo_root, @quality_doc))

    ids = fn pattern ->
      pattern |> Regex.scan(quality, capture: :all_but_first) |> List.flatten() |> Enum.uniq()
    end

    %{
      adopters:
        ScrypathFixtures.preview_epoch()
        |> ScrypathFixtures.Scenarios.all()
        |> Enum.map(&(&1.adopter |> Atom.to_string() |> String.capitalize()))
        |> Enum.uniq(),
      roles: ids.(~r/`(ROLE-[A-Z]+)`/),
      jobs: ids.(~r/`(JOB-\d+)`/),
      scenario_ids: Enum.map(ScrypathFixtures.Scenarios.ids(), &Atom.to_string/1),
      read_file: &File.read(Path.join(@repo_root, &1))
    }
  end

  # The story's own markup in a rendered iframe document (the part copy rules govern).
  defp story_markup(html) do
    html |> LazyHTML.from_document() |> LazyHTML.query("[data-phx-main]") |> LazyHTML.to_html()
  end

  # A rendered iframe document around a hand-written fragment.
  defp page(fragment) do
    ~s(<html><body><div data-phx-main data-phx-session="s" data-phx-static="t">#{fragment}</div></body></html>)
  end

  # The cause keeps a crash attributable: without it a mistyped route (StoryNotFound) or a missing
  # error view would read as the same "crashed" as the failure the plant is meant to show.
  defp crash_cause(%Plug.Conn.WrapperError{reason: reason}), do: crash_cause(reason)

  defp crash_cause(%{__exception__: true} = exception),
    do: Exception.format_banner(:error, exception)

  defp crash_cause(reason), do: inspect(reason)
end

defmodule ScrypathOpsWeb.CatalogContractTest.PlantedJobStory do
  @moduledoc false
  # A story module that only answers `job/0`, for the provenance plants.
  def job, do: "JOB-03"
end

defmodule ScrypathOpsWeb.CatalogContractTest.PlantedJob99Story do
  @moduledoc false
  # Answers a job nothing defines, so a note naming it fails on the job alone.
  def job, do: "JOB-99"
end
