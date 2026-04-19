defmodule Scrypath.DocsContractTest do
  use ExUnit.Case, async: true

  @readme File.read!("README.md")
  @architecture File.read!("ARCHITECTURE.md")
  @ci_workflow File.read!(".github/workflows/ci.yml")
  @release_workflow File.read!(".github/workflows/release-please.yml")
  @publish_recovery_workflow File.read!(".github/workflows/publish-hex.yml")
  @release_monitor_workflow File.read!(".github/workflows/verify-published-release.yml")
  @release_docs File.read!("docs/releasing.md")
  @operator_support_docs File.read!("docs/operator-support.md")
  @search_backend_sre_docs File.read!("docs/search-backend-sre.md")
  @verify_phase11 File.read!("lib/mix/tasks/verify.phase11.ex")
  @verify_phase14 File.read!("lib/mix/tasks/verify.phase14.ex")
  @verify_phase20 File.read!("lib/mix/tasks/verify.phase20.ex")
  @verify_phase26 File.read!("lib/mix/tasks/verify.phase26.ex")
  @verify_phase28 File.read!("lib/mix/tasks/verify.phase28.ex")
  @verify_release_publish File.read!("lib/mix/tasks/verify.release_publish.ex")
  @guide_paths [
    "guides/drift-recovery.md",
    "guides/getting-started.md",
    "guides/phoenix-walkthrough.md",
    "guides/phoenix-contexts.md",
    "guides/phoenix-controllers-and-json.md",
    "guides/phoenix-liveview.md",
    "guides/faceted-search-with-phoenix-liveview.md",
    "guides/multi-index-search.md",
    "guides/sync-modes-and-visibility.md",
    "guides/operator-mix-tasks.md"
  ]
  @guides Enum.into(@guide_paths, %{}, fn path -> {path, File.read!(path)} end)

  test "README preserves the operator contract for backfill and reindex" do
    assert_contains_all(@readme, [
      "Scrypath.backfill/2",
      "Scrypath.reindex/2",
      "Scrypath.reconcile_sync/2",
      "Use backfill when",
      "Use managed reindex when",
      "cutover?: false",
      "Accepted work is not the same thing as search visibility"
    ])
  end

  test "README opens with installation, quick path, and phoenix wayfinding" do
    assert String.contains?(@readme, "Scrypath, the Ecto-native search indexing library")
    assert ordered?(@readme, "## Installation", "## When Scrypath Fits")
    assert ordered?(@readme, "## Quick Path", "## When Scrypath Fits")
    assert @readme =~ ~S|{:scrypath, "~> 0.3"}|
    refute @readme =~ ~S|{:req, "~> 0.5"}|
    refute @readme =~ ~S|{:scrypath, path: "../scrypath"}|

    assert_contains_all(@readme, [
      "Scrypath owns its internal transport dependency.",
      "If you want queued sync, add Oban as an optional production integration",
      "MyApp.Content",
      "search_posts(query, opts \\\\ [])",
      "publish_post(post, attrs)",
      "MyAppWeb.PostController",
      "Phoenix Walkthrough"
    ])
  end

  test "ARCHITECTURE preserves the operational semantics contract" do
    assert_contains_all(@architecture, [
      "create target -> apply settings -> backfill -> optional cutover",
      "Scrypath treats drift as an expected operational state",
      "Accepted work is not search-visible completion",
      "backfill into the live index",
      "cutover?: false",
      "Reconcile is not an auto-heal button"
    ])
  end

  test "docs keep the operator recovery contract report-first and explicit" do
    assert_contains_all(@readme, [
      "Scrypath.sync_status/2",
      "Scrypath.failed_sync_work/2",
      "Scrypath.retry_sync_work/2",
      "Scrypath.reconcile_sync/2",
      "does not heal anything by default",
      "retry, backfill, or reindex deliberately"
    ])

    assert_contains_all(@architecture, [
      "Scrypath.sync_status/2",
      "Scrypath.failed_sync_work/2",
      "Scrypath.retry_sync_work/2",
      "Scrypath.reconcile_sync/2",
      "report-first",
      "only mutates when the caller passes an explicit action"
    ])
  end

  test "documentation keeps drift detection and recovery guidance explicit" do
    assert_contains_all(@readme, [
      "Detect drift before deciding",
      "stale search hits whose hydrated records are now missing",
      "document-count mismatches",
      "failed or discarded sync work",
      "stale deletes"
    ])

    assert_contains_all(@architecture, [
      "Drift can come from",
      "projection changes",
      "settings changes that require a full rebuild",
      "failed, retrying, or discarded async work",
      "old-index cleanup as part of the same managed reindex step"
    ])
  end

  test "phase 6 guide shell exists with the expected phoenix reading path" do
    Enum.each(@guide_paths, &assert(File.exists?(&1), "expected guide #{&1} to exist"))

    assert_contains_all(@guides["guides/getting-started.md"], [
      "Oban only if you want queued sync",
      "Runtime orchestration still lives in your context modules",
      "Scrypath also owns its internal transport dependency",
      "optional production path",
      "Accepted work is not the same thing as search visibility"
    ])

    assert_contains_all(@guides["guides/faceted-search-with-phoenix-liveview.md"], [
      "faceted-search-with-phoenix-liveview.md",
      "Scrypath.search/3",
      "facet_filter",
      "Anti-pattern appendix",
      "handle_params",
      "### API",
      "Meilisearch",
      "### UI"
    ])

    assert_contains_all(@guides["guides/multi-index-search.md"], [
      "Scrypath.search_many",
      "%Scrypath.MultiSearchResult{}",
      "failures",
      "ordered",
      "faceted-search-with-phoenix-liveview.md",
      "sync-modes-and-visibility.md"
    ])

    assert_contains_all(@guides["guides/phoenix-walkthrough.md"], [
      "## 1. Declare The Searchable Schema",
      "## 2. Put Search And Sync In The Context",
      "## 3. Call That Boundary From Controllers",
      "## 4. Reuse The Same Context From LiveView",
      "Controllers translate request params into a context call",
      "LiveView owns UI state. The context still owns repo access and Scrypath orchestration."
    ])

    assert_contains_all(@guides["guides/sync-modes-and-visibility.md"], [
      "search visibility is an operational concern",
      "the enqueue is durable",
      "Accepted work is not the same thing as search visibility.",
      "## `:inline`",
      "## `:oban`",
      "## `:manual`"
    ])

    assert_contains_all(@guides["guides/operator-mix-tasks.md"], [
      "mix scrypath.status",
      "mix scrypath.failed",
      "mix scrypath.retry",
      "mix scrypath.reconcile",
      "scrypath.index.contract_drift",
      "thin terminal entrypoints",
      "Scrypath.Meilisearch.*",
      "--json",
      "--no-class-summary",
      "Failed work by class:",
      "reason_class="
    ])

    assert_contains_all(@guides["guides/drift-recovery.md"], [
      "Symptom",
      "Diagnosis",
      "Action",
      "Verify",
      "Scrypath.failed_sync_work",
      "mix scrypath.failed",
      "failed_work_counts",
      "mix scrypath.index.contract_drift",
      "Scrypath.index_contract_drift",
      "mix scrypath.settings.diff",
      "relevance-tuning.md",
      "multi-index-search.md",
      "sync-modes-and-visibility.md"
    ])
  end

  test "guide snippets stay aligned with the phoenix fixture contract" do
    docs = [@readme | Map.values(@guides)] |> Enum.join("\n")

    assert_contains_all(docs, [
      "search_posts(query, opts \\\\ [])",
      "publish_post(post, attrs)",
      "defmodule MyAppWeb.PostController",
      "defmodule MyAppWeb.PostLive",
      "defmodule MyAppWeb.Api.PostController"
    ])
  end

  test "search backend SRE doc keeps telemetry table and anti-alert-fatigue posture" do
    assert_contains_all(@search_backend_sre_docs, [
      "[:scrypath, :search]",
      "[:scrypath, :meilisearch, :request]",
      "[:scrypath, :operator, :failed_work, :observed]",
      "alert fatigue",
      "Disk free",
      "skip_settings_verification?",
      "Scrypath v1",
      "guides/sync-modes-and-visibility.md"
    ])
  end

  test "release docs and CI keep the package gate auth-free" do
    assert_contains_all(@ci_workflow, [
      "mix verify.phase11",
      "mix verify.phase13 --skip-integration",
      "mix verify.phase14",
      "mix verify.phase20",
      "mix verify.phase22",
      "mix verify.phase26",
      "mix verify.phase28",
      "Operator integration verification (`mix verify.phase13`)",
      "mix verify.phase13"
    ])

    refute @ci_workflow =~ "mix hex.publish --dry-run"

    assert_contains_all(@release_docs, [
      "mix verify.phase11",
      "mix verify.release_publish X.Y.Z",
      "./scripts/verify_phase11_docker.sh",
      ".github/workflows/publish-hex.yml",
      ".github/workflows/verify-published-release.yml",
      "HEX_API_KEY",
      "mix hex.publish --dry-run --yes",
      "HEX_API_KEY=... mix hex.publish --dry-run --yes",
      "always-on CI gate",
      "must stay out of the always-on CI gate"
    ])
  end

  test "phase 11 release docs keep the public recovery contract explicit" do
    assert_contains_all(@release_docs, [
      "## Recovering Tag or Version Drift",
      "## Recovering a Failed Publish",
      "## Recovering Published Artifact Mismatch",
      ".release-please-manifest.json",
      "git tag --sort=version:refname",
      "mix hex.publish --replace --yes",
      "mix hex.publish --revert X.Y.Z",
      "HexDocs"
    ])
  end

  test "verify.phase11 keeps the release gate auth-free and complete" do
    assert_contains_all(@verify_phase11, [
      "test/release/package_metadata_test.exs",
      "test/release/consumer_smoke_test.exs",
      "test/scrypath/docs_contract_test.exs",
      "mix verify.release_publish"
    ])

    refute @verify_phase11 =~ "HEX_API_KEY"
    refute @verify_phase11 =~ ~s|run_command!(["hex.publish"|
  end

  test "verify.phase14 keeps the operator Mix and docs gate auth-free and docs focused" do
    assert_contains_all(@verify_phase14, [
      "test/scrypath/mix_tasks/operator_tasks_test.exs",
      "test/scrypath/docs_contract_test.exs",
      "test/release/package_metadata_test.exs",
      "Mix.Task.run(\"docs\", [\"--warnings-as-errors\"])"
    ])

    refute @verify_phase14 =~ "HEX_API_KEY"
  end

  test "verify.phase20 keeps the faceting + guide gate auth-free and docs focused" do
    assert_contains_all(@verify_phase20, [
      "test/scrypath/options_test.exs",
      "test/scrypath/search_test.exs",
      "test/scrypath/meilisearch/query_test.exs",
      "test/scrypath/meilisearch/settings_test.exs",
      "test/scrypath/docs_contract_test.exs",
      "Mix.Task.run(\"docs\", [\"--warnings-as-errors\"])"
    ])

    refute @verify_phase20 =~ "HEX_API_KEY"
  end

  test "verify.phase26 keeps the operator rollup gate auth-free and test-focused" do
    assert_contains_all(@verify_phase26, [
      "test/scrypath/operator/failed_work_test.exs",
      "test/scrypath/operator/reconcile_test.exs",
      "test/scrypath/mix_tasks/operator_tasks_test.exs",
      "test/scrypath/docs_contract_test.exs",
      "--warnings-as-errors",
      "Mix.Task.run(\"docs\", [\"--warnings-as-errors\"])"
    ])

    refute @verify_phase26 =~ "HEX_API_KEY"
  end

  test "verify.phase28 keeps the index contract operator gate auth-free and docs-focused" do
    assert_contains_all(@verify_phase28, [
      "test/scrypath/operator/index_contract_drift_test.exs",
      "test/scrypath/mix_tasks/operator_tasks_test.exs",
      "test/scrypath/docs_contract_test.exs",
      "Mix.Task.run(\"docs\", [\"--warnings-as-errors\"])",
      "--warnings-as-errors"
    ])

    refute @verify_phase28 =~ "HEX_API_KEY"
  end

  test "release workflow verifies the live published version after hex publish" do
    assert_contains_all(@release_workflow, [
      "ref: ${{ needs.release-please.outputs.tag_name }}",
      "grep -n \"@version \\\"${{ needs.release-please.outputs.version }}\\\"\" mix.exs",
      "run: mix verify.phase11",
      "run: mix hex.publish --dry-run --yes",
      "run: mix hex.publish --yes",
      ~s|run: mix verify.release_publish "${{ needs.release-please.outputs.version }}"|
    ])
  end

  test "publish recovery workflow reruns the release checks from an explicit ref" do
    assert_contains_all(@publish_recovery_workflow, [
      "name: Publish Hex Recovery",
      "ref: ${{ inputs.tag }}",
      "grep -n \"@version \\\"${{ inputs.release_version }}\\\"\" mix.exs",
      "run: mix verify.phase11",
      "run: mix hex.publish --dry-run --yes",
      "run: mix hex.publish --yes",
      ~s|run: mix verify.release_publish "${{ inputs.release_version }}"|
    ])
  end

  test "published release monitor verifies the latest Hex release without publishing" do
    assert_contains_all(@release_monitor_workflow, [
      "name: Verify Published Release",
      "schedule:",
      "workflow_dispatch:",
      "https://hex.pm/api/packages/scrypath",
      ".latest_stable_version // .latest_version // empty",
      "Scrypath is not published on Hex yet. Skipping ongoing published-release verification.",
      ~s|run: mix verify.release_publish "${{ steps.resolve-version.outputs.version }}"|
    ])

    refute @release_monitor_workflow =~ "mix hex.publish --yes"
  end

  test "verify.release_publish checks the public package and docs contract" do
    assert_contains_all(@verify_release_publish, [
      ~s|System.cmd("mix", ["hex.info", "scrypath"]|,
      ~S|{:scrypath, "~> #{version}"}|,
      ~s|System.cmd("curl", ["-IfsS", url]|
    ])
  end

  test "phoenix guides keep the context-first boundary explicit" do
    assert_contains_all(@guides["guides/phoenix-contexts.md"], [
      "Scrypath fits Phoenix best when your context is the application-facing boundary",
      "Do not teach controllers or LiveView modules to compose raw `Repo` and `Scrypath.*` calls as the main pattern."
    ])

    assert_contains_all(@guides["guides/phoenix-controllers-and-json.md"], [
      "Phoenix controllers should translate request params into a context call",
      "Do not recommend direct `Repo` queries plus direct `Scrypath.search/3` calls inside the controller.",
      "page_number =",
      "normalize_page()",
      "Integer.parse(page)",
      "when number > 0 -> number",
      "defp normalize_page(_page), do: 1",
      "page: [number: page_number, size: 20]"
    ])

    refute @guides["guides/phoenix-controllers-and-json.md"] =~ "String.to_integer(page)"

    assert_contains_all(@guides["guides/phoenix-liveview.md"], [
      "LiveView owns UI state, and the context owns repo access plus Scrypath orchestration.",
      "the UI should not imply immediate search visibility unless the context chose `:inline`"
    ])
  end

  test "operator docs keep tasks thin and Meilisearch-native power namespaced" do
    assert_contains_all(@readme, [
      "mix scrypath.status",
      "mix scrypath.failed",
      "mix scrypath.retry",
      "mix scrypath.reconcile",
      "They do not create a second operator product surface."
    ])

    assert_contains_all(@architecture, [
      "Thin **`mix scrypath.*` wrappers** delegate to those same root APIs without creating a second operator product surface.",
      "mix scrypath.status",
      "mix scrypath.reconcile"
    ])

    assert_contains_all(@operator_support_docs, [
      "mix verify.phase14",
      "mix verify.phase20",
      "mix verify.phase26",
      "mix verify.phase28",
      "mix verify.phase11",
      "mix scrypath.index.contract_drift",
      "Scrypath.index_contract_drift/2",
      "operator visibility and recovery live on `Scrypath.*`",
      "backend-native search power stays under `Scrypath.Meilisearch.*`"
    ])
  end

  test "all Elixir code fences in docs stay syntactically valid" do
    for snippet <-
          extract_elixir_fences(@readme) ++
            extract_elixir_fences(@architecture) ++
            extract_elixir_fences(@release_docs) ++
            guide_fences() do
      assert {:ok, _quoted} = Code.string_to_quoted(snippet)
    end
  end

  defp guide_fences do
    @guides
    |> Map.values()
    |> Enum.flat_map(&extract_elixir_fences/1)
  end

  defp extract_elixir_fences(markdown) do
    Regex.scan(~r/```elixir\n(.*?)```/ms, markdown, capture: :all_but_first)
    |> List.flatten()
    |> Enum.map(&String.trim/1)
  end

  defp assert_contains_all(content, snippets) do
    Enum.each(snippets, fn snippet ->
      assert String.contains?(content, snippet),
             "expected docs to include #{inspect(snippet)}"
    end)
  end

  defp ordered?(content, first, second) do
    {first_index, second_index} =
      Enum.reduce([first, second], %{}, fn needle, acc ->
        Map.put(acc, needle, :binary.match(content, needle))
      end)
      |> then(fn indices ->
        {elem(indices[first], 0), elem(indices[second], 0)}
      end)

    first_index < second_index
  end
end
