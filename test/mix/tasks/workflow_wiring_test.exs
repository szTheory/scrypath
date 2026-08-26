defmodule Mix.Tasks.Verify.WorkflowWiringTest do
  use ExUnit.Case, async: true

  @ci_yml ".github/workflows/ci.yml"
  @publish_hex_yml ".github/workflows/publish-hex.yml"
  @release_please_yml ".github/workflows/release-please.yml"
  @verify_published_yml ".github/workflows/verify-published-release.yml"
  @verify_task "lib/mix/tasks/verify.ex"

  describe "INFRA-01 D-14: workspace_clean gate on all three publish paths" do
    test "ci.yml core job runs the canonical gate, which includes workspace cleanliness" do
      ci = File.read!(@ci_yml)
      core_job = workflow_job_block(ci, "core")

      assert core_job =~ "mix verify.core"
      assert File.read!(@verify_task) =~ ~s|Mix.Task.run("verify.workspace_clean")|
    end

    test "publish-hex.yml runs mix verify.workspace_clean" do
      assert File.read!(@publish_hex_yml) =~ "mix verify.workspace_clean"
    end

    test "release-please.yml publish-hex job runs mix verify.workspace_clean" do
      assert File.read!(@release_please_yml) =~ "mix verify.workspace_clean"
    end
  end

  describe "INFRA-02 D-18: release_parity step on scheduled monitor" do
    test "verify-published-release.yml runs mix verify.release_parity" do
      assert File.read!(@verify_published_yml) =~ "mix verify.release_parity"
    end
  end

  describe "SHIP-03: post-publish release_parity on publish workflows" do
    test "release-please.yml runs release_publish before release_parity" do
      yml = File.read!(@release_please_yml)
      assert yml =~ "mix verify.release_parity"
      assert yml =~ ~s(mix verify.release_publish "${{ needs.release-please.outputs.version }}")
      assert yml =~ ~s(mix verify.release_parity "${{ needs.release-please.outputs.version }}")

      {idx_pub, _} = :binary.match(yml, "mix verify.release_publish")
      {idx_par, _} = :binary.match(yml, "mix verify.release_parity")
      assert idx_pub < idx_par
    end

    test "publish-hex.yml runs release_publish before release_parity" do
      yml = File.read!(@publish_hex_yml)
      assert yml =~ "mix verify.release_parity"
      assert yml =~ ~s(mix verify.release_publish "${{ inputs.release_version }}")
      assert yml =~ ~s(mix verify.release_parity "${{ inputs.release_version }}")

      {idx_pub, _} = :binary.match(yml, "mix verify.release_publish")
      {idx_par, _} = :binary.match(yml, "mix verify.release_parity")
      assert idx_pub < idx_par
    end
  end

  describe "REL-03 D-10..D-13: canonical publish and monitor wiring" do
    test "release-please publish job runs the canonical ordered proof chain" do
      yml = File.read!(@release_please_yml)

      assert_ordered_steps(yml, [
        "mix verify.workspace_clean",
        ~s(grep -n "@version \\"${{ needs.release-please.outputs.version }}\\"" mix.exs),
        "mix verify.package",
        "mix hex.publish --dry-run --yes",
        "mix hex.publish --yes",
        ~s(mix verify.release_publish "${{ needs.release-please.outputs.version }}"),
        ~s(mix verify.release_parity "${{ needs.release-please.outputs.version }}")
      ])
    end

    test "publish-hex recovery job mirrors the same ordered proof chain from explicit inputs" do
      yml = File.read!(@publish_hex_yml)

      assert_ordered_steps(yml, [
        "mix verify.workspace_clean",
        ~s(grep -n "@version \\"${{ inputs.release_version }}\\"" mix.exs),
        "mix verify.package",
        "mix hex.publish --dry-run --yes",
        "mix hex.publish --yes",
        ~s(mix verify.release_publish "${{ inputs.release_version }}"),
        ~s(mix verify.release_parity "${{ inputs.release_version }}")
      ])
    end

    test "published-release monitor stays publish-free and schedule-deduped" do
      yml = File.read!(@verify_published_yml)

      assert yml =~
               "version=\"$(jq -r '.latest_stable_version // .latest_version // empty' package.json)\""

      assert yml =~ "mix verify.release_publish \"${{ steps.resolve-version.outputs.version }}\""
      assert yml =~ "mix verify.release_parity \"${{ steps.resolve-version.outputs.version }}\""
      refute yml =~ "mix hex.publish --yes"
      assert yml =~ "failure() && github.event_name == 'schedule'"
      assert yml =~ "update_existing: true"
    end
  end

  describe "INFRA-03 D-13: ci.yml action pins on Node 24 runtime" do
    test "ci.yml pins actions/checkout v6 to immutable commits" do
      yml = File.read!(@ci_yml)
      refute yml =~ "actions/checkout@v4", "expected no legacy checkout@v4 pins"
      assert yml =~ ~r|actions/checkout@[0-9a-f]{40} # v6|
    end

    test "ci.yml pins actions/cache v5 to immutable commits" do
      yml = File.read!(@ci_yml)
      refute yml =~ "actions/cache@v4", "expected no legacy cache@v4 pins"
      assert yml =~ ~r|actions/cache@[0-9a-f]{40} # v5|
    end

    test "ci.yml pins checkout in every executable job" do
      count = Regex.scan(~r|actions/checkout@[0-9a-f]{40} # v6|, File.read!(@ci_yml)) |> length()

      assert count >= 10, "expected checkout pins across the CI graph, got #{count}"
    end

    test "ci.yml caches each BEAM verification lane" do
      count = Regex.scan(~r|actions/cache@[0-9a-f]{40} # v5|, File.read!(@ci_yml)) |> length()

      assert count >= 9, "expected cache pins across BEAM jobs, got #{count}"
    end
  end

  describe "INFRA-04 D-19: scheduled drift-issue wiring" do
    test "create-an-issue step is guarded on failure() + schedule event" do
      yml = File.read!(@verify_published_yml)
      assert yml =~ "failure() && github.event_name == 'schedule'"
    end

    test "create-an-issue step pins JasonEtco/create-an-issue v2" do
      yml = File.read!(@verify_published_yml)
      assert yml =~ ~r|JasonEtco/create-an-issue@[0-9a-f]{40} # v2|
    end

    test "create-an-issue step sets update_existing: true for per-version dedup" do
      yml = File.read!(@verify_published_yml)
      assert yml =~ "update_existing: true"
    end

    test "verify-published-release.yml permissions include issues: write" do
      yml = File.read!(@verify_published_yml)

      assert yml =~ "issues: write",
             "create-an-issue@v2 needs issues:write permission in the workflow permissions: block"
    end

    test "verify-published-release.yml still runs on schedule cron" do
      yml = File.read!(@verify_published_yml)

      assert yml =~ ~r/schedule:\s*\n\s*- cron:/,
             "scheduled cron trigger required for INFRA-04 daily run"
    end
  end

  describe "mix.exs cli.preferred_envs registrations" do
    test "verify.phase97 is registered as :test" do
      envs = Scrypath.MixProject.cli()[:preferred_envs]
      assert envs[:"verify.phase97"] == :test
    end

    test "verify.phase98 is registered as :test" do
      envs = Scrypath.MixProject.cli()[:preferred_envs]
      assert envs[:"verify.phase98"] == :test
    end

    test "verify.phase99 is registered as :test" do
      envs = Scrypath.MixProject.cli()[:preferred_envs]
      assert envs[:"verify.phase99"] == :test
    end

    test "phase trust-spine aliases remain in parity for phases 97-99" do
      envs = Scrypath.MixProject.cli()[:preferred_envs]

      assert envs[:"verify.phase97"] == :test
      assert envs[:"verify.phase98"] == :test
      assert envs[:"verify.phase99"] == :test
    end

    test "verify.phase100 stays intentionally unregistered in preferred_envs" do
      envs = Scrypath.MixProject.cli()[:preferred_envs]
      refute Keyword.has_key?(envs, :"verify.phase100")

      mix_exs = File.read!("mix.exs")

      refute mix_exs =~ "\"verify.phase100\": :test",
             "verify.phase100 must remain unregistered; phase100 trust checks run in verify.phase99"
    end

    test "verify.workspace_clean is registered as :test" do
      envs = Scrypath.MixProject.cli()[:preferred_envs]
      assert envs[:"verify.workspace_clean"] == :test
    end

    test "verify.release_parity is registered as :test" do
      envs = Scrypath.MixProject.cli()[:preferred_envs]
      assert envs[:"verify.release_parity"] == :test
    end
  end

  describe "canonical repository and compatibility wiring" do
    test "every CI lane that runs the history-sensitive root suite fetches full history" do
      ci = File.read!(@ci_yml)

      for job_name <- ["core", "repository-contracts", "compatibility", "coverage"] do
        job = workflow_job_block(ci, job_name)

        assert job =~ "fetch-depth: 0",
               "#{job_name} runs a history-sensitive root suite and must not use checkout's shallow default"
      end
    end

    test "ci defines repository-contracts and routes it to the canonical command" do
      ci = File.read!(@ci_yml)

      assert workflow_job_block(ci, "repository-contracts") =~
               "run: mix verify.repository_contracts"
    end

    test "ci defines compatibility matrix lane with floor/head tuple evidence" do
      ci = File.read!(@ci_yml)
      assert ci =~ "\n  compatibility:\n"
      assert ci =~ ~s({elixir: "1.17.3", otp: "26.2.5"})
      assert ci =~ ~s({elixir: "1.19.0", otp: "28.1"})
      assert ci =~ "run: mix verify.compatibility"
    end

    test "contributing required-check contract includes canonical jobs" do
      contributing = File.read!("CONTRIBUTING.md")

      assert contributing =~ "**`core`**"
      assert contributing =~ "**`package`**"
      assert contributing =~ "**`repository-contracts`**"
      assert contributing =~ "**`backend`**"
    end

    test "no docs or workflow guidance introduces verify.phase100/phase101 drift" do
      contributing = File.read!("CONTRIBUTING.md")
      ci = File.read!(@ci_yml)

      refute contributing =~ "mix verify.phase100",
             "verify.phase100 guidance must not be added; phase100 enforcement stays under verify.phase99"

      refute ci =~ "mix verify.phase100",
             "CI trust lane must remain on the canonical repository contract without verify.phase100 proliferation"

      refute contributing =~ "mix verify.phase101",
             "verify.phase101 guidance must not be added; phase101 compatibility checks stay under verify.phase99"

      refute ci =~ "mix verify.phase101",
             "CI trust lane must remain on the canonical repository contract without verify.phase101 proliferation"
    end
  end

  describe "UAT shift-left (closes /gsd-verify-work 18 manual tests)" do
    # Each test maps 1:1 to a row in 18-UAT.md. Together they turn the UAT
    # from 9 human-verification items into 0 — every claim that previously
    # needed a maintainer to run by hand is now an assertion here.

    test "UAT-05: ci.yml carries no legacy Node-20 pins for checkout or cache" do
      ci = File.read!(@ci_yml)

      refute ci =~ "actions/checkout@v4",
             "legacy actions/checkout@v4 pin found — Node 20 deprecation risk"

      refute ci =~ "actions/cache@v4",
             "legacy actions/cache@v4 pin found — Node 20 deprecation risk"

      # checkout went to @v6, cache went to @v5 — neither should sit at @v5/@v6 respectively
      refute ci =~ "actions/checkout@v5",
             "actions/checkout should be pinned to @v6, not @v5"
    end

    test "UAT-06: docs/releasing.md ships §Release parity gate section to HexDocs" do
      rel = File.read!("docs/releasing.md")

      assert rel =~ ~r/^## Release parity gate$/m
      assert rel =~ "### `mix verify.workspace_clean`"
      assert rel =~ "### `mix verify.release_parity X.Y.Z`"
      assert rel =~ "### Historical context"
      assert rel =~ "tag and"
      assert rel =~ "default-branch"
      assert rel =~ "release-please.yml"
      assert rel =~ "publish-hex.yml"
      assert rel =~ "mix verify.release_parity"

      # Confirm mix.exs lists docs/releasing.md in docs extras so HexDocs picks it up
      mix = File.read!("mix.exs")
      assert mix =~ ~s("docs/releasing.md")
    end

    test "UAT-07: CHANGELOG has exactly one Unreleased heading with Phase 18 bullets" do
      changelog = File.read!("CHANGELOG.md")

      # Exactly one ## Unreleased — any second stale block from prior phases
      # would create release-please ambiguity (see Phase 18 SECURITY.md
      # T-18-07-03 adjacent finding, resolved in commit 91b8a57).
      unreleased_count =
        Regex.scan(~r/^## \[?Unreleased\]?/m, changelog) |> length()

      assert unreleased_count == 1,
             "expected exactly one ## Unreleased heading, got #{unreleased_count}"

      # Phase 18 deliverables under Unreleased
      assert changelog =~ "### Added"
      assert changelog =~ "### Changed"
      assert changelog =~ "### Notes"
      assert changelog =~ "mix verify.workspace_clean"
      assert changelog =~ "mix verify.release_parity"
      assert changelog =~ "actions/checkout@v6"
      assert changelog =~ "actions/cache@v5"
      assert changelog =~ "docs/releasing.md"
    end

    test "UAT-08: drift-issue step is guarded to scheduled runs only (workflow_dispatch is silent)" do
      vpr = File.read!(@verify_published_yml)

      # This guard is the structural proof that a manual workflow_dispatch
      # of verify-published-release.yml will never file an issue — which is
      # what the original UAT-08 manual smoke test was verifying. Combined
      # with the integration canary (UAT-03) exercising the mix task body,
      # the manual workflow_dispatch run is now fully redundant.
      assert vpr =~ "failure() && github.event_name == 'schedule'"
    end

    test "UAT-09: release-please pre-1.0 bump policy + manifest pin hold on HEAD" do
      # (a) Pre-1.0 policy: ordinary feat: on 0.3.x bumps patch toward 0.3.1 under
      # bump-minor-pre-major + bump-patch-for-minor-pre-major; Release-As: remains
      # the explicit override when maintainers intentionally want a different version.
      cfg = File.read!("release-please-config.json")
      assert cfg =~ ~s("bump-minor-pre-major": true)
      assert cfg =~ ~s("bump-patch-for-minor-pre-major": true)
      assert cfg =~ ~s("release-type": "elixir")

      # (b) Manifest pins the current shipped line — release-please reads this to decide
      # the next version. Do not bump here casually; the release PR advances it.
      manifest_json = File.read!(".release-please-manifest.json")
      assert {:ok, %{"." => version}} = Jason.decode(manifest_json)
      assert Regex.match?(~r/^\d+\.\d+\.\d+$/, version)

      # (c) mix.exs @version matches the manifest — release-please owns the bump,
      # any manual bump here breaks the release-PR flow (T-18-07-03 mitigation).
      assert File.read!("mix.exs") =~ ~s(@version "#{version}")

      # (d) Recent history carries the D-22 feat(18): subject line anchor.
      # Keep a generous window so active development does not push this anchor
      # out of range (post–v1.7 main exceeded 120 commits from HEAD).
      {log, 0} = System.cmd("git", ["log", "--format=%s", "-2000"])

      assert log =~ ~r/^feat\(18\): add release-parity gates \+ Node 20 CI cleanup$/m,
             "expected the D-22 closing commit subject in recent history"
    end
  end

  describe "STAB-01 advisory evidence wiring" do
    test "the mounted proof remains distinct and required without promoting full E2E" do
      ci = File.read!(@ci_yml)
      contributing = File.read!("CONTRIBUTING.md")

      assert workflow_job_block(ci, "ecommerce-mounted") =~ "mix verify.ecommerce_mounted"

      assert contributing =~ "**`ecommerce-mounted`**"
      assert contributing =~ "`ecommerce-e2e` is advisory today"
    end

    test "ecommerce-e2e runs the canonical full proof and always uploads evidence" do
      ci = File.read!(@ci_yml)

      assert workflow_job_block(ci, "ecommerce-e2e") =~ "mix verify.ecommerce_e2e"
      assert ci =~ "- name: Upload advisory E2E evidence"
      assert ci =~ "if: always()"
      assert ci =~ "examples/scrypath_ecommerce/test-results/docker-full"
    end

    test "full Docker proof retains browser, light parity, contrast, and optional visual judgment" do
      docker_runner = File.read!("examples/scrypath_ecommerce/docker-playwright.sh")
      package_json = File.read!("examples/scrypath_ecommerce/package.json")

      assert package_json =~ ~s("test:e2e": "playwright test --workers=1")
      assert package_json =~ "test:e2e:admin-light-parity"
      assert package_json =~ "test:e2e:admin-shell-wash"
      assert package_json =~ "test:e2e:ops-ui-visual-judge"
      assert docker_runner =~ "npm run test:e2e"
      assert docker_runner =~ "npm run test:e2e:admin-light-parity"
      assert docker_runner =~ "node contrast-checker.mjs"
      assert docker_runner =~ "npm run test:e2e:ops-ui-visual-judge"
    end

    test "Docker verifier bounds collected artifacts to logs and browser reports" do
      verifier = File.read!("examples/scrypath_ecommerce/scripts/verify-e2e.sh")

      assert verifier =~ "test-results/docker-${scope}"
      assert verifier =~ "compose.log"
      assert verifier =~ "test-results/."
      assert verifier =~ "playwright-report/."
    end

    test "playwright config emits structured phase105 report and keeps retry-based flake visibility" do
      config = File.read!("examples/scrypath_ecommerce/playwright.config.ts")

      assert config =~ "retries: process.env.CI ? 1 : 0"
      assert config =~ "workers: process.env.CI ? 1 : undefined"
      assert config =~ "trace: \"on-first-retry\""
      assert config =~ "phase105-playwright.json"
    end

    test "phase105 evidence summary includes shifted-left visual gates" do
      summary_script = File.read!("scripts/ci/phase105_evidence.sh")

      assert summary_script =~ "admin-light-parity.json"
      assert summary_script =~ "ops-ui-visual-judge.json"
      assert summary_script =~ "light_parity_status"
      assert summary_script =~ "shell_wash_conclusion"
      assert summary_script =~ "shell_wash_visual"
      assert summary_script =~ "visual_judge_status"
      assert summary_script =~ "visual_judge_claims"
    end
  end

  describe "TEST-05 scheduled/manual informational coverage" do
    test "coverage is a bounded scheduled/manual advisory job with a retained source-SHA report" do
      ci = File.read!(@ci_yml)
      coverage_job = workflow_job_block(ci, "coverage")

      assert length(Regex.scan(~r/^  coverage:$/m, ci)) == 1
      assert coverage_job =~ "name: coverage (advisory)"

      assert coverage_job =~
               "if: github.event_name == 'schedule' || github.event_name == 'workflow_dispatch'"

      assert coverage_job =~ "continue-on-error: true"
      assert length(Regex.scan(~r/^\s*- run: mix verify\.coverage$/m, coverage_job)) == 1
      assert coverage_job =~ "- name: Upload informational coverage report"
      assert coverage_job =~ "if: always()"

      assert coverage_job =~
               "actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7"

      assert coverage_job =~ "name: coverage-report-${{ github.sha }}"
      assert coverage_job =~ "path: cover/"
      assert coverage_job =~ "if-no-files-found: warn"
      assert coverage_job =~ "retention-days: 7"
      refute coverage_job =~ "secrets."
      refute coverage_job =~ "id-token"
    end
  end

  defp assert_ordered_steps(content, [first | rest]) do
    {start_idx, _} = :binary.match(content, first)

    Enum.reduce(rest, start_idx, fn step, prev_idx ->
      {idx, _} = :binary.match(content, step)
      assert idx > prev_idx, "expected #{inspect(step)} to appear after previous release step"
      idx
    end)
  end

  defp workflow_job_block(content, job_name) do
    marker = "\n  #{job_name}:\n"
    {start_idx, marker_len} = :binary.match(content, marker)

    rest =
      binary_part(content, start_idx + marker_len, byte_size(content) - start_idx - marker_len)

    case Regex.run(~r/\n  [a-zA-Z0-9_-]+:\n/, rest, return: :index) do
      [{next_idx, _}] -> binary_part(rest, 0, next_idx)
      nil -> rest
    end
  end
end
