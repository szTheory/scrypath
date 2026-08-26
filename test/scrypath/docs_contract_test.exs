defmodule Scrypath.DocsContractTest do
  use ExUnit.Case, async: true
  @moduletag :docs_contract

  @readme File.read!("README.md")
  @example_readme File.read!("examples/phoenix_meilisearch/README.md")
  @architecture File.read!("ARCHITECTURE.md")
  @contributing File.read!("CONTRIBUTING.md")
  @ci_workflow File.read!(".github/workflows/ci.yml")
  @release_workflow File.read!(".github/workflows/release-please.yml")
  @publish_recovery_workflow File.read!(".github/workflows/publish-hex.yml")
  @release_monitor_workflow File.read!(".github/workflows/verify-published-release.yml")
  @jtbd_gap_map File.read!("docs/jtbd-gap-map.md")
  @release_docs File.read!("docs/releasing.md")
  @operator_support_docs File.read!("docs/operator-support.md")
  @search_backend_sre_docs File.read!("docs/search-backend-sre.md")
  @verify_phase11 File.read!("lib/mix/tasks/verify.phase11.ex")
  @verify_phase14 File.read!("lib/mix/tasks/verify.phase14.ex")
  @verify_phase20 File.read!("lib/mix/tasks/verify.phase20.ex")
  @verify_phase26 File.read!("lib/mix/tasks/verify.phase26.ex")
  @verify_phase28 File.read!("lib/mix/tasks/verify.phase28.ex")
  @verify_phase36 File.read!("lib/mix/tasks/verify.phase36.ex")
  @verify_phase37 File.read!("lib/mix/tasks/verify.phase37.ex")
  @verify_phase38 File.read!("lib/mix/tasks/verify.phase38.ex")
  @verify_phase41 File.read!("lib/mix/tasks/verify.phase41.ex")
  @verify_phase43 File.read!("lib/mix/tasks/verify.phase43.ex")
  @verify_phase82 File.read!("lib/mix/tasks/verify.phase82.ex")
  @verify_phase83 File.read!("lib/mix/tasks/verify.phase83.ex")
  @verify_phase84 File.read!("lib/mix/tasks/verify.phase84.ex")
  @verify_phase85 File.read!("lib/mix/tasks/verify.phase85.ex")
  @verify_phase91 File.read!("lib/mix/tasks/verify.phase91.ex")
  @verify_phase96 File.read!("lib/mix/tasks/verify.phase96.ex")
  @verify_opsui File.read!("lib/mix/tasks/verify.ops_ui.ex")
  @verify_release_publish File.read!("lib/mix/tasks/verify.release_publish.ex")
  @guide_paths [
    "guides/common-mistakes.md",
    "guides/drift-recovery.md",
    "guides/getting-started.md",
    "guides/golden-path.md",
    "guides/support-and-compatibility.md",
    "guides/outside-adopter-intake.md",
    "guides/meilisearch-concepts.md",
    "guides/request-edge-search.md",
    "guides/composing-real-app-search.md",
    "guides/jtbd-and-user-flows.md",
    "guides/meilisearch-operations.md",
    "guides/phoenix-walkthrough.md",
    "guides/phoenix-contexts.md",
    "guides/phoenix-controllers-and-json.md",
    "guides/phoenix-liveview.md",
    "guides/faceted-search-with-phoenix-liveview.md",
    "guides/multi-index-search.md",
    "guides/overview.md",
    "guides/sync-modes-and-visibility.md",
    "guides/operator-mix-tasks.md",
    "guides/relevance-tuning.md",
    "guides/per-query-tuning-pipeline.md",
    "guides/related-data-and-reindexing.md",
    "guides/multitenancy.md"
  ]
  @guides Enum.into(@guide_paths, %{}, fn path -> {path, File.read!(path)} end)
  @per_query_tuning_pipeline File.read!("guides/per-query-tuning-pipeline.md")
  @multitenancy_guide File.read!("guides/multitenancy.md")
  @request_edge_guide File.read!("guides/request-edge-search.md")
  @support_guide File.read!("guides/support-and-compatibility.md")
  @verify_adopter File.read!("lib/mix/tasks/verify.adopter.ex")
  @phase97_contract_statements File.read!(
                                 ".planning/phases/97-canonical-contract-freeze-and-scope-guard/97-CONTRACT-STATEMENTS.md"
                               )
  @phase97_contract_traceability File.read!(
                                   ".planning/phases/97-canonical-contract-freeze-and-scope-guard/97-CONTRACT-TRACEABILITY.md"
                                 )
  @phase97_scope_guard File.read!(
                         ".planning/phases/97-canonical-contract-freeze-and-scope-guard/97-SCOPE-GUARD.md"
                       )

  # Paths shipped as ExDoc extras (mix.exs :docs extras) plus top-level narrative docs.
  @published_markdown_for_hygiene [
    "README.md",
    "ARCHITECTURE.md",
    "docs/releasing.md",
    "docs/operator-support.md",
    "docs/search-backend-sre.md"
    | @guide_paths
  ]

  test "per-query tuning pipeline guide spine anchors" do
    assert String.contains?(@per_query_tuning_pipeline, "## Two-plane model and precedence")
    assert String.contains?(@per_query_tuning_pipeline, "## Implementation readiness checklist")
    assert String.contains?(@per_query_tuning_pipeline, "## Telemetry catalog")
  end

  test "published markdown avoids internal planning and task artifact strings" do
    patterns = [
      {~r/\bFACET-\d{2}\b/, "FACET-NN requirement-style IDs"},
      {~r/\bTUNE-\d{2}\b/, "TUNE-NN requirement-style IDs"},
      {~r/\bMULTI-\d{2}\b/, "MULTI-NN requirement-style IDs"},
      {~r/\bADPT-\d{2}\b/, "ADPT-NN requirement-style IDs"},
      {~r/\bEXAM-\d{2}\b/, "EXAM-NN requirement-style IDs"},
      {~r/\bVRFY-\d{2}\b/, "VRFY-NN requirement-style IDs"},
      {~r/\bAUDT-\d{2}\b/, "AUDT-NN requirement-style IDs"},
      {~r/T-\d{2}-\d{2}-\d{2}/, "T-xx-xx-xx task-style IDs"},
      {~r/\(D-\d{2}\)/, "(D-xx) decision-style IDs"},
      {~r/Per decision D-/, "Per decision D- internal decision refs"},
      {~r/DocsContractTest/, "DocsContractTest (maintainer suite name in user docs)"},
      {~r/UI-SPEC/, "UI-SPEC internal label"}
    ]

    for path <- @published_markdown_for_hygiene do
      body = File.read!(path)

      for {re, label} <- patterns do
        refute Regex.match?(re, body),
               "remove #{label} from published doc #{path} (adopter-facing HexDocs hygiene)"
      end
    end
  end

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

  test "README and overview expose the jtbd guide as a first-class entry point" do
    assert_contains_all(@readme, [
      "guides/jtbd-and-user-flows.md",
      "jobs-to-be-done map"
    ])

    overview = @guides["guides/overview.md"]

    assert_contains_all(overview, [
      "[JTBD and user flows](jtbd-and-user-flows.md)",
      "Canonical mental model"
    ])

    assert ordered?(
             overview,
             "[JTBD and user flows](jtbd-and-user-flows.md)",
             "[Common mistakes](common-mistakes.md)"
           )
  end

  test "request-edge guide is the canonical v1.21 contract and root docs point to it" do
    assert_contains_all(@request_edge_guide, [
      "Scrypath.QueryParams",
      "Scrypath.Phoenix",
      "QueryParams.to_search_args/1",
      "Scrypath.search/3",
      "%Scrypath.Query{}",
      "not public API"
    ])

    assert_contains_all(@readme, [
      "guides/request-edge-search.md",
      "Request-edge contract"
    ])

    assert_contains_all(File.read!("lib/scrypath.ex"), [
      "guides/request-edge-search.md",
      "Scrypath.Phoenix` is optional glue"
    ])

    overview = @guides["guides/overview.md"]
    assert String.contains?(overview, "[Request-edge search](request-edge-search.md)")
  end

  test "phase 85 canonical guide owns composition and metadata wayfinding" do
    canonical = @guides["guides/composing-real-app-search.md"]
    overview = @guides["guides/overview.md"]
    scrypath_doc = File.read!("lib/scrypath.ex")

    assert_contains_all(canonical, [
      "defaults",
      "fixed",
      "schema_capabilities/1",
      "reflect_search/2",
      "compose_many/2",
      "host-owned",
      "## Non-goals",
      "%Scrypath.Query{}",
      "schema-generated runtime verbs",
      "generated UI widgets",
      "tenant/authz guarantees",
      "related-data propagation or rebuild correctness claims"
    ])

    assert_contains_all(@readme, [
      "guides/composing-real-app-search.md",
      "Real-app composition and metadata"
    ])

    assert_contains_all(scrypath_doc, [
      "guides/composing-real-app-search.md",
      "Scrypath.Composition",
      "Scrypath.Metadata"
    ])

    assert ordered?(
             overview,
             "[Request-edge search](request-edge-search.md)",
             "[Composing real-app search](composing-real-app-search.md)"
           )
  end

  test "composition seam stays context-owned and search/3 remains canonical" do
    scrypath_doc = File.read!("lib/scrypath.ex")
    composition_doc = File.read!("lib/scrypath/composition.ex")
    public_jtbd = @guides["guides/jtbd-and-user-flows.md"]

    assert_contains_all(scrypath_doc, [
      "Scrypath.Composition",
      "search/3` remains the canonical runtime entrypoint",
      "optional glue",
      "tenant authz"
    ])

    assert_contains_all(composition_doc, [
      "Scrypath.search/3",
      "it never exposes `%Scrypath.Query{}`",
      "it does not move composition ownership onto schemas or `Scrypath.Phoenix`"
    ])

    assert_contains_all(public_jtbd, [
      "Scrypath.Composition",
      "preset or scope",
      "contexts still call `Scrypath.search/3`"
    ])

    refute String.contains?(composition_doc, "def search(")
    refute String.contains?(composition_doc, "schema-generated")
  end

  test "jtbd docs stay grounded in the checked-out surface" do
    public_jtbd = @guides["guides/jtbd-and-user-flows.md"]

    assert_contains_all(public_jtbd, [
      "Keep a search-shaped read model in sync with Ecto data",
      "accepted work is not the same thing as visible search results",
      "Backfill repairs a trustworthy index. Reindex replaces an untrustworthy one.",
      "Scrypath.Composition"
    ])

    refute String.contains?(public_jtbd, "Scrypath.SearchModule")

    assert_contains_all(@jtbd_gap_map, [
      "**Last reviewed:** 2026-05-31",
      "Scrypath now looks roughly **92-94% done**",
      "contract-repair and proof-hardening closeout",
      "Outside-adopter evidence",
      "The `v1.20` `Scrypath.SearchModule` mismatch is resolved as archive-correction",
      "future milestone planning must not assume it exists"
    ])
  end

  test "support/readiness authority stays discoverable and verify.adopter parity stays explicit" do
    assert_contains_all(@readme, [
      "guides/support-and-compatibility.md",
      "mix verify.adopter"
    ])

    assert_contains_all(@contributing, [
      "guides/support-and-compatibility.md",
      "mix verify.adopter",
      "mix verify.adopter --live",
      "phoenix-example"
    ])

    assert_contains_all(@support_guide, [
      "Phoenix + Meilisearch",
      "`:inline`",
      "`:manual`",
      "`:oban`",
      "outside-adopter evidence"
    ])

    assert_contains_all(@verify_adopter, [
      "test/scrypath/readiness_contract_test.exs",
      "test/scrypath/phase110_contract_test.exs",
      "test/mix/tasks/verify_adopter_test.exs",
      "SCRYPATH_EXAMPLE_INTEGRATION",
      "PGPORT",
      "SCRYPATH_MEILISEARCH_URL",
      "mix verify.adopter --live"
    ])
  end

  test "phase 100 TRUTH-01/TRUTH-02 evergreen guard keeps install and release tokens stable" do
    intake = @guides["guides/outside-adopter-intake.md"]

    assert_contains_all(@readme, [~S|{:scrypath, "~> 0.3"}|])
    assert_contains_all(intake, [~S|{:scrypath, "~> 0.3"}|])
    refute String.contains?(intake, ~S|{:scrypath, "~> 1.0"}|)

    assert_contains_all(String.downcase(@support_guide), [
      "release-backed guidance",
      "main may contain unreleased changes"
    ])
  end

  test "example runbook and CI preserve the same ordered proof command chain" do
    assert String.contains?(@example_readme, "phoenix-example")
    assert ordered?(@example_readme, "cd examples/phoenix_meilisearch", "mix deps.get")
    assert ordered?(@example_readme, "mix deps.get", "mix test")

    [_head, job_tail] = String.split(@ci_workflow, "phoenix-example:", parts: 2)
    job_head = String.slice(job_tail, 0, 4000)
    assert String.contains?(job_head, "mix verify.phoenix_example")
  end

  test "verify.phase83 stays wired into the focused maintainer flow" do
    assert String.contains?(@verify_phase83, "test/scrypath/composition_test.exs")
    assert String.contains?(@verify_phase83, "test/scrypath/composition_property_test.exs")
    assert String.contains?(@verify_phase83, "test/scrypath/docs_contract_test.exs")
    assert String.contains?(@verify_phase83, "Mix.Task.run(\"docs\", [\"--warnings-as-errors\"])")
    assert String.contains?(File.read!("mix.exs"), "\"verify.phase83\": :test")
  end

  test "metadata reflection and compose_many stay bounded to plain-data helpers" do
    scrypath_doc = File.read!("lib/scrypath.ex")
    metadata_doc = File.read!("lib/scrypath/metadata.ex")
    multi_index_guide = @guides["guides/multi-index-search.md"]
    faceted_guide = @guides["guides/faceted-search-with-phoenix-liveview.md"]

    assert_contains_all(scrypath_doc, [
      "schema_capabilities/1",
      "reflect_search/2",
      "reflect_search_many/2",
      "generated UI",
      "tenant policy"
    ])

    assert_contains_all(metadata_doc, [
      "capabilities",
      "applied",
      "defaulted",
      "fixed",
      "unsupported",
      "host_owned"
    ])

    assert_contains_all(multi_index_guide, [
      "compose_many/2",
      "tuple/shared-option contract",
      "shared `fixed` is intentionally unsupported",
      "host-owned",
      "Composing real-app search"
    ])

    assert_contains_all(faceted_guide, [
      "schema_capabilities/1",
      "reflect_search/2",
      "host-owned",
      "Composing real-app search"
    ])
  end

  test "verify.phase84 stays wired into the focused maintainer flow" do
    assert String.contains?(@verify_phase84, "test/scrypath/metadata_test.exs")
    assert String.contains?(@verify_phase84, "test/scrypath/composition_many_test.exs")
    assert String.contains?(@verify_phase84, "test/scrypath/search_many_test.exs")
    assert String.contains?(@verify_phase84, "test/scrypath/docs_contract_test.exs")
    assert String.contains?(@verify_phase84, "Mix.Task.run(\"docs\", [\"--warnings-as-errors\"])")
    assert String.contains?(File.read!("mix.exs"), "\"verify.phase84\": :test")
  end

  test "verify.phase85 stays wired into the focused maintainer flow" do
    assert String.contains?(@verify_phase85, "test/scrypath/composition_test.exs")
    assert String.contains?(@verify_phase85, "test/scrypath/metadata_test.exs")
    assert String.contains?(@verify_phase85, "test/scrypath/composition_many_test.exs")
    assert String.contains?(@verify_phase85, "test/scrypath/docs_contract_test.exs")
    assert String.contains?(@verify_phase85, "Mix.Task.run(\"docs\", [\"--warnings-as-errors\"])")
    assert String.contains?(File.read!("mix.exs"), "\"verify.phase85\": :test")
  end

  test "verify.phase91 stays wired into the focused maintainer flow" do
    assert String.contains?(@verify_phase91, "test/scrypath/sync/related_test.exs")
    assert String.contains?(@verify_phase91, "test/scrypath/sync/related_worker_test.exs")
    assert String.contains?(@verify_phase91, "test/scrypath/docs_contract_test.exs")
    assert String.contains?(@verify_phase91, "Mix.Task.run(\"docs\", [\"--warnings-as-errors\"])")
    assert String.contains?(File.read!("mix.exs"), "\"verify.phase91\": :test")
  end

  test "README opens with installation, quick path, and phoenix wayfinding" do
    assert String.contains?(@readme, "Scrypath, the Ecto-native search indexing library")
    assert ordered?(@readme, "## Installation", "## When Scrypath Fits")
    assert ordered?(@readme, "## Quick Path", "## When Scrypath Fits")
    assert @readme =~ ~S|{:scrypath, "~> 0.3"}|
    refute @readme =~ ~S|{:req, "~> 0.5"}|
    refute @readme =~ ~S|{:scrypath, path: "../scrypath"}|

    assert_contains_all(@readme, [
      "## Quick Path",
      "Scrypath owns its internal transport dependency.",
      "If you want queued sync, add Oban as an optional production integration",
      "field :status, :string",
      "guides/golden-path.md"
    ])
  end

  test "phase 35 readme and sync guide share operator lifecycle chain" do
    chain =
      "requested -> enqueued -> processing -> backend_accepted -> completed | retrying | discarded"

    assert String.contains?(@readme, chain)
    assert String.contains?(@guides["guides/sync-modes-and-visibility.md"], chain)
  end

  test "lobby moduledoc two_hop keeps golden_path_first before sync modes" do
    src = File.read!("lib/scrypath.ex")

    doc =
      case Regex.run(~r/@moduledoc\s+"""\n([\s\S]*?)"""/, src) do
        [_, body] -> body
        _ -> flunk("missing Scrypath @moduledoc block")
      end

    {golden_pos, _} = :binary.match(doc, "guides/golden-path.md")
    {sync_pos, _} = :binary.match(doc, "guides/sync-modes-and-visibility.md")
    assert golden_pos < sync_pos
  end

  test "phase 34 readme and golden path agree on canonical status field" do
    golden = @guides["guides/golden-path.md"]

    assert String.contains?(@readme, "field :status, :string")
    assert String.contains?(golden, "field :status, :string")
  end

  test "phase 29 golden path guide and adoption readme contract" do
    golden = @guides["guides/golden-path.md"]

    assert_contains_all(golden, [
      "Scrypath.search",
      "sync_mode: :inline",
      "guides/sync-modes-and-visibility.md",
      "meilisearch-operations.md",
      "examples/phoenix_meilisearch/README.md",
      "SCRYPATH_MEILISEARCH_URL",
      "docker compose up -d",
      "Ecto without Phoenix",
      "Getting Started](getting-started.md)"
    ])

    assert ordered?(@readme, "## Installation", "## Quick Path")

    assert_contains_all(@readme, [
      "**Start here:**",
      "guides/golden-path.md",
      "## Versioning and upgrades",
      "mix verify.phase11",
      "docs/releasing.md",
      "**Choosing a mode:**",
      "guides/sync-modes-and-visibility.md"
    ])

    assert ordered?(@readme, "## Sync Modes", "## Search")
    assert ordered?(@readme, "## Versioning and upgrades", "## Search")
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
      "Accepted work is not the same thing as search visibility",
      "Golden path](golden-path.md)"
    ])

    assert_contains_all(@guides["guides/faceted-search-with-phoenix-liveview.md"], [
      "movies-shaped",
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
      "## :all expansion",
      "global_schemas:",
      ":scrypath_global_search_schemas",
      "merged ordering",
      "## Federation weights",
      "federation_weight:",
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
      "## Operator lifecycle",
      "requested -> enqueued -> processing -> backend_accepted -> completed | retrying | discarded",
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
      "mix scrypath_ops.playbooks.validate",
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

  test "CONTRIBUTING documents default test path and live integration jobs (VRFY)" do
    assert_contains_all(@contributing, [
      "mix test --exclude integration",
      "**`core`**",
      "**`package`**",
      "**`repository-contracts`**",
      "**`backend`**",
      "**`phoenix-example`**",
      "examples/phoenix_meilisearch"
    ])

    assert String.contains?(@contributing, "Required Meilisearch")
    assert String.contains?(@contributing, "Postgres 16 + Meilisearch")
  end

  test "example smoke script exists only under phoenix_meilisearch (Phase 33)" do
    assert File.regular?("examples/phoenix_meilisearch/scripts/smoke.sh")
    refute File.regular?("scripts/smoke.sh")
  end

  test "README and CONTRIBUTING document example smoke cwd (Phase 33)" do
    assert String.contains?(@readme, "cd examples/phoenix_meilisearch") or
             String.contains?(@readme, "bash examples/phoenix_meilisearch/scripts/smoke.sh")

    assert String.contains?(@contributing, "cd examples/phoenix_meilisearch") or
             String.contains?(@contributing, "bash examples/phoenix_meilisearch/scripts/smoke.sh")

    assert ordered?(@readme, "cd examples/phoenix_meilisearch", "./scripts/smoke.sh")

    assert ordered?(
             @contributing,
             "phoenix-example",
             "cd examples/phoenix_meilisearch"
           )

    assert ordered?(@contributing, "cd examples/phoenix_meilisearch", "./scripts/smoke.sh")
  end

  test "golden path scopes example smoke script to the phoenix_meilisearch example (Phase 33–34)" do
    golden = @guides["guides/golden-path.md"]

    assert_contains_all(golden, [
      "examples/phoenix_meilisearch/README.md",
      "phoenix-example",
      "pull requests",
      "GitHub Actions",
      "SCRYPATH_EXAMPLE_INTEGRATION=1",
      "postgres:16-alpine",
      "getmeili/meilisearch:v1.15"
    ])

    assert ordered?(golden, "examples/phoenix_meilisearch", "./scripts/smoke.sh")
  end

  test "CI workflow includes Phoenix example integration job wired to example path" do
    assert_contains_all(@ci_workflow, [
      "phoenix-example:",
      "SCRYPATH_EXAMPLE_INTEGRATION",
      "PGPORT",
      "postgres:16-alpine",
      "getmeili/meilisearch:v1.15",
      "mix deps.get",
      "mix verify.phoenix_example"
    ])

    [_head, job_tail] = String.split(@ci_workflow, "phoenix-example:", parts: 2)
    job_head = String.slice(job_tail, 0, 4000)
    assert ordered?(job_head, "mix deps.get", "mix verify.phoenix_example")
  end

  test "README sync authority ties sync-modes guide link to authority wording (Phase 51)" do
    assert @readme =~ ~S|](guides/sync-modes-and-visibility.md)|

    assert Regex.match?(
             ~r/sync-modes-and-visibility.{0,200}(authority|single source|single authority)/i,
             @readme
           ) or
             Regex.match?(
               ~r/(authority|single source|single authority).{0,200}sync-modes-and-visibility/i,
               @readme
             )
  end

  test "readme sync spine keeps :status :accepted wording tied to visibility guide (LIB-03)" do
    assert_contains_all(@readme, [
      "guides/sync-modes-and-visibility.md",
      "`:status` `:accepted`",
      "Accepted work is not the same thing as search visibility"
    ])
  end

  test "CONTRIBUTING phoenix-example matches ci.yml canonical command (Phase 51)" do
    assert String.contains?(@contributing, "phoenix-example")

    [_head, row_tail] = String.split(@contributing, "| **`phoenix-example`** |", parts: 2)
    assert String.contains?(String.slice(row_tail, 0, 1000), "mix verify.phoenix_example")

    [_head, job_tail] = String.split(@ci_workflow, "phoenix-example:", parts: 2)
    job_head = String.slice(job_tail, 0, 4000)
    assert ordered?(job_head, "mix deps.get", "mix verify.phoenix_example")
  end

  test "README surfaces canonical ops verification for optional scrypath_ops (Phase 53)" do
    assert String.contains?(@readme, "mix verify.ops_ui")
  end

  test "CONTRIBUTING documents scrypath_ops playbooks validate for fixture directories (Phase 64)" do
    assert String.contains?(@contributing, "mix scrypath_ops.playbooks.validate")
  end

  test "CONTRIBUTING ops-ui row matches ci.yml canonical command (Phase 53)" do
    assert String.contains?(@contributing, "ops-ui")

    [_head, row_tail] =
      String.split(
        @contributing,
        "`ops-ui-path` / `ops-ui`",
        parts: 2
      )

    assert String.contains?(String.slice(row_tail, 0, 1000), "mix verify.ops_ui")

    [_head, from_job] = String.split(@ci_workflow, "\n  ops-ui:\n", parts: 2)
    job_window = String.slice(from_job, 0, 4000)
    assert ordered?(job_window, "mix deps.get", "mix verify.ops_ui")
  end

  test "verify.opsui Mix task keeps orchestration markers (Phase 53)" do
    assert String.contains?(@verify_opsui, "cd: ops_dir")
    assert String.contains?(@verify_opsui, "mix test")
    assert String.contains?(@verify_opsui, "ensure_no_args!")
  end

  test "release docs and CI keep the package gate auth-free" do
    assert_contains_all(@ci_workflow, [
      "mix verify.core",
      "mix verify.package",
      "mix verify.repository_contracts",
      "mix verify.backend"
    ])

    refute @ci_workflow =~ "mix hex.publish --dry-run"

    assert_contains_all(@release_docs, [
      "mix verify.package",
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

  test "verify.phase36 lists hierarchical facet verification paths without Hex secrets" do
    assert_contains_all(@verify_phase36, [
      "test/scrypath/options_test.exs",
      "test/scrypath/search_test.exs",
      "test/scrypath/meilisearch/settings_test.exs",
      "test/scrypath/operator/index_contract_drift_test.exs",
      "test/scrypath/docs_contract_test.exs"
    ])

    refute @verify_phase36 =~ "HEX_API_KEY"
  end

  test "phase 37 guide documents disjunctive facet counts with stable phrases" do
    assert_contains_all(@guides["guides/faceted-search-with-phoenix-liveview.md"], [
      "## Disjunctive facet counts",
      "OR within the same facet field",
      "AND across different facet fields",
      "single search",
      "multi-search",
      "Scrypath.Facets.Disjunctive",
      "Genre OR + year AND on the movies catalog"
    ])
  end

  test "verify.phase37 lists disjunctive facet verification paths without Hex secrets" do
    assert_contains_all(@verify_phase37, [
      "test/scrypath/facets/disjunctive_test.exs",
      "test/scrypath/meilisearch/query_test.exs",
      "test/scrypath/docs_contract_test.exs"
    ])

    refute @verify_phase37 =~ "HEX_API_KEY"
  end

  test "phase 38 scoped facet search guide headings and phrases" do
    guide = @guides["guides/faceted-search-with-phoenix-liveview.md"]

    assert_contains_all(guide, [
      "## Searching within a facet selection",
      "## Composing facet filters with scoped search",
      "Scrypath.search_within_facet",
      "duplicate the same attribute"
    ])
  end

  test "verify.phase38 lists scoped facet search verification paths without Hex secrets" do
    assert_contains_all(@verify_phase38, [
      "test/scrypath/search_within_facet_test.exs",
      "test/scrypath/meilisearch/query_test.exs",
      "test/scrypath/docs_contract_test.exs"
    ])

    refute @verify_phase38 =~ "HEX_API_KEY"
  end

  test "verify.phase41 pins federation docs + doc contract slice without Hex secrets" do
    assert_contains_all(@verify_phase41, [
      "Mix.Tasks.Verify.Phase41",
      "docs_contract_test.exs"
    ])

    refute @verify_phase41 =~ "HEX_API_KEY"
  end

  test "verify.phase43 pins per-query verify task and focused paths" do
    assert_contains_all(@verify_phase43, [
      "Mix.Tasks.Verify.Phase43",
      "docs_contract_test.exs",
      "per_query_tuning_test.exs",
      "search_test.exs",
      "search_many_test.exs"
    ])

    refute @verify_phase43 =~ "HEX_API_KEY"
  end

  test "phase_41 federation anchors stay wired in multi-index guide and search_many docs" do
    guide = @guides["guides/multi-index-search.md"]

    assert guide =~ ~r/^## :all expansion/m
    assert String.contains?(guide, "global_schemas:")
    assert String.contains?(guide, ":scrypath_global_search_schemas")
    assert String.contains?(guide, "merged ordering")
    assert String.contains?(guide, "**Per-index relevance scores stay local")

    search_src = File.read!("lib/scrypath/search.ex")
    assert String.contains?(search_src, "## Scores vs merge ordering")
    assert String.contains?(search_src, "within one index")
  end

  test "faceted LiveView guide documents hierarchical facets with stable headings" do
    guide = @guides["guides/faceted-search-with-phoenix-liveview.md"]

    assert_contains_all(guide, [
      "## Hierarchical facets",
      "nested_facet_paths: true",
      "hierarchy: [base:",
      "facetDistribution",
      "AND between facet attributes",
      "same atoms"
    ])
  end

  test "release workflow verifies the live published version after hex publish" do
    assert_contains_all(@release_workflow, [
      "ref: ${{ needs.release-please.outputs.tag_name }}",
      "grep -n \"@version \\\"${{ needs.release-please.outputs.version }}\\\"\" mix.exs",
      "run: mix verify.package",
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
      "run: mix verify.package",
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
      "Do not teach controllers or LiveView modules to compose raw `Repo` and `Scrypath.*` calls as the main pattern.",
      "`Scrypath.Phoenix`"
    ])

    assert_contains_all(@guides["guides/phoenix-controllers-and-json.md"], [
      "Phoenix controllers should translate request params into a context call",
      "Do not recommend direct `Repo` queries plus direct `Scrypath.search/3` calls inside the controller.",
      "SearchPhoenix.from_params(params)",
      "QueryParams.to_search_args(query_params)",
      "page_with_default_size",
      "It does not execute search."
    ])

    refute @guides["guides/phoenix-controllers-and-json.md"] =~ "String.to_integer(page)"
    refute @guides["guides/phoenix-controllers-and-json.md"] =~ "normalize_page"

    assert_contains_all(@guides["guides/phoenix-liveview.md"], [
      "LiveView owns UI state, and the context owns repo access plus Scrypath orchestration.",
      "SearchPhoenix.from_params(params)",
      "`handle_params/3` remains the one place that normalizes params",
      "the UI should not imply immediate search visibility unless the context chose `:inline`"
    ])

    assert_contains_all(@guides["guides/phoenix-walkthrough.md"], [
      "request-edge-search.md",
      "shared request-edge contract"
    ])

    assert_contains_all(@guides["guides/faceted-search-with-phoenix-liveview.md"], [
      "request-edge-search.md",
      "Helpers normalize params/forms/URLs only, contexts remain canonical, and Phoenix is optional."
    ])
  end

  test "phase 82 verify gate stays focused and contributor-facing docs wire it consistently" do
    assert_contains_all(@verify_phase82, [
      "defmodule Mix.Tasks.Verify.Phase82",
      "test/scrypath/query_params_test.exs",
      "test/scrypath/phoenix_test.exs",
      "test/support/docs/phoenix_examples_test.exs",
      "test/support/docs/phoenix_request_shape_smoke_test.exs",
      "test/scrypath/docs_contract_test.exs",
      ~s|Mix.Task.run("docs", ["--warnings-as-errors"])|
    ])

    assert_contains_all(@contributing, [
      "mix verify.phase82",
      "request-edge docs/examples contract"
    ])

    assert_contains_all(@ci_workflow, [
      "core (required)",
      "run: mix verify.core --exclude integration --exclude docs_contract"
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

  test "phase 32 AUDT-01 planning hygiene contracts (Nyquist invariants)" do
    state_md = File.read!(".planning/STATE.md")

    requirements_md =
      [
        ".planning/REQUIREMENTS.md",
        ".planning/milestones/v1.14-REQUIREMENTS.md",
        ".planning/milestones/v1.13-REQUIREMENTS.md",
        ".planning/milestones/v1.6-REQUIREMENTS.md"
      ]
      |> Enum.find_value(fn path ->
        case File.read(path) do
          {:ok, body} ->
            if String.contains?(body, "| AUDT-01 |"), do: body

          _ ->
            nil
        end
      end) || flunk("expected one canonical requirements file to retain the AUDT-01 registry row")

    milestones_md = File.read!(".planning/MILESTONES.md")
    v16_audit = File.read!(".planning/milestones/v1.6-MILESTONE-AUDIT.md")
    project_md = File.read!(".planning/PROJECT.md")

    refute String.contains?(state_md, "pending_triage_v1_6"),
           "STATE.md must not retain pending_triage_v1_6 after AUDT-01 triage"

    # NOTE: STATE.md was redesigned into a clean current-position cursor (v1.32+) and no
    # longer doubles as an archived-artifact ledger. The AUDT-01-era artifacts it used to
    # list still exist and are recorded canonically elsewhere (e.g. 18-VERIFICATION.md in
    # v1.32-MILESTONE-AUDIT.md, v1.4-MILESTONE-AUDIT.md in MILESTONES.md, and the
    # 260416-*-SUMMARY.md files under .planning/quick/). The durable hygiene invariants
    # (no re-opened triage, AUDT-01 traceability, v1.6 audit score) are asserted below.

    assert String.contains?(requirements_md, "| AUDT-01 |"),
           "requirements traceability must include AUDT-01 row (root REQUIREMENTS.md or v1.14+ milestone requirements archive)"

    assert String.contains?(requirements_md, "Phase 32"),
           "AUDT-01 must retain the phase 32 delivery pointer"

    assert String.contains?(requirements_md, "gap closure 33"),
           "AUDT-01 must reference gap closure work when doc-contract follow-ups are scheduled"

    refute String.contains?(milestones_md, "pending_triage_v1_6"),
           "MILESTONES.md must not imply uncleared pending_triage_v1_6 ledger state"

    assert String.contains?(v16_audit, "requirements: 8/8"),
           "v1.6 milestone audit must record 8/8 requirements score"

    assert String.contains?(v16_audit, "gaps:\n  requirements: []"),
           "v1.6 audit gaps.requirements must stay empty (no re-opened requirement gaps)"

    assert String.contains?(project_md, "AUDT-01"),
           "PROJECT.md must still mention AUDT-01 for maintainer routing"
  end

  test "related-data guide adopts sync_related/3 as the canonical fan-out story" do
    guide = @guides["guides/related-data-and-reindexing.md"]

    refute String.contains?(guide, "temporary workaround"),
           "guide must not frame the fan-out path as a temporary workaround (D-09)"

    refute String.contains?(guide, "first-class feature"),
           "guide must not promise a future first-class feature; it already shipped (D-09)"

    assert_contains_all(guide, [
      "Scrypath.sync_related/3",
      "fan_outs:",
      "sync_mode: :inline",
      "sync_mode: :oban",
      "callback magic",
      "contexts own orchestration",
      "library owns execution",
      "__scrypath__(:fan_outs)",
      "For ordinary schemas, declare fan-out with `use Scrypath, fan_outs:`"
    ])
  end

  test "multitenancy guide contains required section anchors (TNNT-01)" do
    assert String.contains?(@multitenancy_guide, "shared-index")
    assert String.contains?(@multitenancy_guide, "Keyword.merge")
    assert String.contains?(@multitenancy_guide, "tenant token")
    assert String.contains?(@multitenancy_guide, "search_document")
    assert String.contains?(@multitenancy_guide, "tenant_field")
  end

  test "multitenancy guide is registered in ExDoc extras and Getting Started group (TNNT-01)" do
    mix_exs = File.read!("mix.exs")
    assert String.contains?(mix_exs, ~s("guides/multitenancy.md"))
  end

  test "verify.phase96 stays wired into the focused maintainer flow" do
    assert String.contains?(@verify_phase96, "test/scrypath/search_test.exs")
    assert String.contains?(@verify_phase96, "test/scrypath/meilisearch_test.exs")
    assert String.contains?(@verify_phase96, "test/scrypath/docs_contract_test.exs")
    assert String.contains?(@verify_phase96, "Mix.Task.run(\"docs\", [\"--warnings-as-errors\"])")
  end

  test "phase 97 canonical statement, traceability, and scope anchors stay frozen" do
    assert_contains_all(@phase97_contract_statements, [
      "CST-TRUTH-01-INSTALL",
      "CST-TRUTH-02-RELEASE-MAIN",
      "CST-TRUTH-03-SUPPORT-AUTHORITY"
    ])

    assert_contains_all(@phase97_contract_traceability, [
      "| TRUTH-01 |",
      "| TRUTH-02 |",
      "| TRUTH-03 |"
    ])

    assert_contains_all(@phase97_scope_guard, [
      "SCOPE-01",
      "Reopen policy",
      "outside-adopter signal",
      "reproducible production bug"
    ])

    assert String.contains?(File.read!(".planning/PROJECT.md"), "97-SCOPE-GUARD.md")
    assert String.contains?(File.read!(".planning/ROADMAP.md"), "[PHASE97-SCOPE-GUARD]")
  end

  test "facet value search documentation contains type-ahead examples" do
    scrypath_doc = File.read!("lib/scrypath.ex")

    assert_contains_all(scrypath_doc, [
      "search_facet_values(Product, \"brand\", \"ni\")",
      "handle_event(\"search-brands\"",
      "socket, :brand_suggestions, result.hits"
    ])
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
