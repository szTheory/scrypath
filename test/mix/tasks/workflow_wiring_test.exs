defmodule Mix.Tasks.Verify.WorkflowWiringTest do
  use ExUnit.Case, async: true

  @ci_yml ".github/workflows/ci.yml"
  @workflow_security_yml ".github/workflows/workflow-security.yml"
  @website_yml ".github/workflows/website.yml"
  @website_select_browser_step "Select browser (runner Chrome when launchable, else Playwright Chromium)"
  @website_channel_guard "grep -q SCRYPATH_BROWSER_CHANNEL scripts/check.mjs"
  @website_deploy_if "if: (github.event_name == 'push' || github.event_name == 'workflow_dispatch') && github.ref == 'refs/heads/main'"
  @publish_hex_yml ".github/workflows/publish-hex.yml"
  @release_please_yml ".github/workflows/release-please.yml"
  @verify_published_yml ".github/workflows/verify-published-release.yml"
  @verify_task Scrypath.RepoTooling.task_path("verify.ex")

  describe "HYG-02 no blanket compiler suppression" do
    test "mix.exs sets no elixirc_options" do
      refute File.read!("mix.exs") =~ "elixirc_options",
             "mix.exs must not set elixirc_options; fix warnings at the source"
    end

    test "no library source changes compiler options at runtime" do
      offenders =
        ["lib/**/*.ex", "dev/**/*.ex"]
        |> Enum.flat_map(&Path.wildcard/1)
        |> Enum.filter(&(File.read!(&1) =~ "Code.put_compiler_option"))

      assert offenders == [],
             "Code.put_compiler_option found in: #{Enum.join(offenders, ", ")}"
    end

    test "no_warn_undefined is limited to Oban modules" do
      site_count =
        ["lib/**/*.ex", "dev/**/*.ex"]
        |> Enum.flat_map(&Path.wildcard/1)
        |> Enum.map(&assert_oban_suppressions!(File.read!(&1), &1))
        |> Enum.sum()

      assert site_count >= 3,
             "expected at least 3 targeted Oban no_warn_undefined sites, found #{site_count}"
    end

    test "the guard accepts targeted module and MFA forms independent of layout" do
      for source <- [
            "@compile {:no_warn_undefined, Oban}",
            "@compile {:no_warn_undefined,\n  [Oban, Oban.Job]}",
            "@compile no_warn_undefined: [Oban.Job]",
            "@compile [no_warn_undefined: Oban.Job]",
            "@compile {:no_warn_undefined, [{Oban, :insert, 2}]}",
            "Module.put_attribute(__MODULE__, :compile, {:no_warn_undefined, [Oban]})"
          ] do
        assert assert_oban_suppressions!(source, "fixture") == 1
      end
    end

    test "the guard rejects other modules, blanket and dynamic suppression forms" do
      for source <- [
            "@compile {:no_warn_undefined, [Oban, Foo]}",
            "@compile {:no_warn_undefined,\n  [Foo]}",
            "@compile no_warn_undefined: [Foo]",
            "@compile [no_warn_undefined: Foo]",
            "@compile {:no_warn_undefined, [{Foo, :insert, 2}]}",
            "@compile {:no_warn_undefined, ObanLike}",
            "@compile {:no_warn_undefined, :all}",
            "@compile {:no_warn_undefined, targets}",
            "Module.put_attribute(__MODULE__, :compile, {:no_warn_undefined, [Foo]})",
            "@key :no_warn_undefined\n@compile {@key, targets}"
          ] do
        assert_raise ExUnit.AssertionError, fn -> assert_oban_suppressions!(source, "fixture") end
      end
    end
  end

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

  describe "DEP-07 D-16/D-19: action pins and workflow trust boundaries" do
    test "ci.yml pins actions/checkout v7.0.1 to its verified immutable commit" do
      yml = File.read!(@ci_yml)
      refute yml =~ "actions/checkout@v4", "expected no legacy checkout@v4 pins"

      assert_action_pin!(
        yml,
        "actions/checkout",
        "3d3c42e5aac5ba805825da76410c181273ba90b1",
        "v7.0.1"
      )
    end

    test "ci.yml pins every cache component to v6.1.0's verified immutable commit" do
      yml = File.read!(@ci_yml)
      refute yml =~ "actions/cache@v4", "expected no legacy cache@v4 pins"

      for action <- ["actions/cache", "actions/cache/restore", "actions/cache/save"] do
        assert_action_pin!(
          yml,
          action,
          "55cc8345863c7cc4c66a329aec7e433d2d1c52a9",
          "v6.1.0"
        )
      end
    end

    test "ci.yml pins checkout in every executable job" do
      count =
        Regex.scan(
          ~r|actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7\.0\.1|,
          File.read!(@ci_yml)
        )
        |> length()

      assert count >= 10, "expected checkout pins across the CI graph, got #{count}"
    end

    test "ci.yml caches each BEAM verification lane" do
      count =
        Regex.scan(
          ~r|actions/cache@55cc8345863c7cc4c66a329aec7e433d2d1c52a9 # v6\.1\.0|,
          File.read!(@ci_yml)
        )
        |> length()

      assert count >= 9, "expected cache pins across BEAM jobs, got #{count}"
    end

    test "workflow-security pins dependency review v5 and keeps its PR check fail-closed" do
      security = File.read!(@workflow_security_yml)
      dependency_review = workflow_job_block(security, "dependency-review")

      assert_action_pin!(
        security,
        "actions/checkout",
        "3d3c42e5aac5ba805825da76410c181273ba90b1",
        "v7.0.1"
      )

      assert_action_pin!(
        security,
        "actions/dependency-review-action",
        "a1d282b36b6f3519aa1f3fc636f609c47dddb294",
        "v5.0.0"
      )

      assert dependency_review =~ "if: github.event_name == 'pull_request'"
      assert dependency_review =~ "contents: read"
      assert dependency_review =~ "pull-requests: read"
      refute dependency_review =~ "continue-on-error: true"
      refute dependency_review =~ "warn-only: true"
    end

    test "CI pin contract rejects a wrong action SHA or version comment" do
      ci = File.read!(@ci_yml)
      checkout_sha = "3d3c42e5aac5ba805825da76410c181273ba90b1"

      wrong_sha = String.replace(ci, checkout_sha, String.duplicate("f", 40), global: false)
      wrong_comment = String.replace(ci, "# v7.0.1", "# v7.0.0", global: false)

      assert_raise ExUnit.AssertionError, fn ->
        assert_action_pin!(wrong_sha, "actions/checkout", checkout_sha, "v7.0.1")
      end

      assert_raise ExUnit.AssertionError, fn ->
        assert_action_pin!(wrong_comment, "actions/checkout", checkout_sha, "v7.0.1")
      end
    end

    test "dependency audit remains failing while the independent quality check runs after it" do
      ci = File.read!(@ci_yml)
      deep_quality = workflow_job_block(ci, "deep-quality")
      audit = workflow_step_block(deep_quality, "\n      - id: dependency_audit\n")

      follow_up =
        workflow_named_step_block(
          deep_quality,
          "Run deep quality checks independently of the dependency audit"
        )

      assert audit =~ "run: elixir scripts/ci/dependency_audit.exs"
      refute audit =~ "continue-on-error: true"
      assert follow_up =~ "!cancelled() && steps.dependency_audit.outcome != 'skipped'"
      assert follow_up =~ "run_deep_quality_without_audit()"
    end

    test "all six affected workflows pin checkout v7.0.1 to its verified immutable commit" do
      checkout_sha = "3d3c42e5aac5ba805825da76410c181273ba90b1"

      for workflow <- [
            @ci_yml,
            @workflow_security_yml,
            @website_yml,
            @publish_hex_yml,
            @release_please_yml,
            @verify_published_yml
          ] do
        assert_action_pin!(File.read!(workflow), "actions/checkout", checkout_sha, "v7.0.1")
      end
    end

    test "website pins Node and Pages actions to verified commits while retaining Node 22 cache inputs" do
      website = File.read!(@website_yml)

      assert_action_pin!(
        website,
        "actions/setup-node",
        "949feb2413d6458794dcd2491c4babbbce0c15c1",
        "v7.1.0"
      )

      assert_action_pin!(
        website,
        "actions/deploy-pages",
        "368f82528645a54fb793d4d04e342629a3f51346",
        "v5.0.1"
      )

      for job_name <- ["build-and-check", "deploy"] do
        job = workflow_job_block(website, job_name)

        setup_node =
          workflow_step_with_uses_block(
            job,
            "actions/setup-node@949feb2413d6458794dcd2491c4babbbce0c15c1 # v7.1.0"
          )

        assert setup_node =~ "node-version: '22'"
        assert setup_node =~ "cache: npm"
        assert setup_node =~ "cache-dependency-path: website/package-lock.json"
      end

      assert length(
               Regex.scan(
                 ~r|actions/setup-node@949feb2413d6458794dcd2491c4babbbce0c15c1 # v7\.1\.0|,
                 website
               )
             ) ==
               2
    end

    test "website events, full-history checkout and Pages permissions remain scoped" do
      website = File.read!(@website_yml)
      build = workflow_job_block(website, "build-and-check")
      deploy = workflow_job_block(website, "deploy")

      assert website =~ "  pull_request:\n"
      assert website =~ "  push:\n    branches:\n      - main\n    paths:\n"

      assert deploy =~ @website_deploy_if

      assert build =~ "fetch-depth: 0"
      assert deploy =~ "fetch-depth: 0"
      assert website =~ "permissions:\n  contents: read"

      assert deploy =~
               "permissions:\n      contents: read\n      pages: write\n      id-token: write"

      refute build =~ "pages: write"
      refute build =~ "id-token: write"
    end

    test "website deploy safety net: filters, dispatch rollback, deploy group, smoke and timeout" do
      assert_website_safety_net!(File.read!(@website_yml))
    end

    test "the website safety-net contract rejects a workflow that loses a piece of it" do
      yml = File.read!(@website_yml)
      assert_website_safety_net!(yml)

      [before_pr, between, after_push] = String.split(yml, "      - 'brand/**'\n", parts: 3)
      brand_line = "      - 'brand/**'\n"

      planted = [
        {"brand/** dropped from the pull_request filter",
         before_pr <> between <> brand_line <> after_push},
        {"brand/** dropped from the push filter",
         before_pr <> brand_line <> between <> after_push},
        {"dispatch ref input dropped",
         String.replace(
           yml,
           "      ref:\n        description",
           "      other:\n        description"
         )},
        {"deploy group cancels in flight",
         String.replace(
           yml,
           "group: website-pages-deploy\n      cancel-in-progress: false",
           "group: website-pages-deploy\n      cancel-in-progress: true"
         )},
        {"smoke command dropped", String.replace(yml, "node website/scripts/smoke.mjs", "true")},
        {"soft check dropped", String.replace(yml, "curl -fsSI", "curl -sI")},
        {"build timeout dropped", String.replace(yml, "    timeout-minutes: 10\n", "")},
        {"deploy timeout dropped", String.replace(yml, "    timeout-minutes: 15\n", "")},
        {"dispatch ref interpolated into a shell command",
         String.replace(yml, "node website/scripts/smoke.mjs", "echo ${{ inputs.ref }}")},
        {"browser probe no longer launches the chrome channel",
         String.replace(yml, "channel: 'chrome'", "channel: 'x'")},
        {"deploy no longer restricted to main",
         String.replace(yml, " && github.ref == 'refs/heads/main'", "")},
        {"deploy no longer limited to push and dispatch events",
         String.replace(
           yml,
           "(github.event_name == 'push' || github.event_name == 'workflow_dispatch') && ",
           ""
         )},
        {"workflow-level group cancels every superseded run, deploys included",
         String.replace(
           yml,
           "cancel-in-progress: ${{ github.event_name == 'pull_request' }}",
           "cancel-in-progress: true"
         )},
        {"rollback dispatch shares the push group",
         String.replace(
           yml,
           "${{ github.event_name == 'workflow_dispatch' && 'rollback' || github.ref }}",
           "${{ github.ref }}"
         )},
        {"browser selection no longer checks that the ref's check script supports the channel",
         String.replace(yml, "#{@website_channel_guard} \\\n            && ", "")}
      ]

      for {label, mutated} <- planted do
        refute mutated == yml, "the planted mutation #{label} changed nothing"

        accepted? =
          try do
            assert_website_safety_net!(mutated)
            true
          rescue
            ExUnit.AssertionError -> false
          end

        refute accepted?, "planted #{label} was accepted by the safety-net contract"
      end
    end

    # Runs the real "Select browser" step script with stub executables on PATH, so what it does for a
    # rollback ref is observed rather than inferred from its text. The probe's node call is a stub that
    # succeeds, which is the runner case: Chrome is installed and launchable.
    test "website browser selection takes the runner Chrome only for a ref whose check script supports the channel" do
      yml = File.read!(@website_yml)
      build = workflow_job_block(yml, "build-and-check")

      script =
        build
        |> workflow_named_step_block(@website_select_browser_step)
        |> workflow_step_run_script()

      supported =
        run_website_browser_selection(
          script,
          "const channel = process.env.SCRYPATH_BROWSER_CHANNEL;\n"
        )

      assert supported.github_env =~ "SCRYPATH_BROWSER_CHANNEL=chrome"
      refute supported.npx_calls =~ "playwright install"

      # The check.mjs on main before this phase: a bare launch that ignores the channel variable.
      predates =
        run_website_browser_selection(script, "const browser = await chromium.launch();\n")

      refute predates.github_env =~ "SCRYPATH_BROWSER_CHANNEL",
             "a ref whose check.mjs ignores the channel variable must not be told to use it"

      assert predates.npx_calls =~ "playwright install --with-deps chromium",
             "a ref whose check.mjs ignores the channel variable needs Playwright's own Chromium installed"
    end

    test "release workflows retain tag selection, history, permissions and credential behavior" do
      publish = File.read!(@publish_hex_yml)
      release = File.read!(@release_please_yml)
      verify_release = File.read!(@verify_published_yml)

      publish_job = workflow_job_block(publish, "publish-scrypath")
      release_job = workflow_job_block(release, "release-please")
      release_publish_job = workflow_job_block(release, "publish-hex")
      verify_job = workflow_job_block(verify_release, "verify-latest-published-release")

      assert publish_job =~ "ref: ${{ inputs.tag }}"
      assert release_job =~ "fetch-depth: 0"
      refute release_job =~ ~r/^\s*ref:/m
      assert release_publish_job =~ "ref: ${{ needs.release-please.outputs.tag_name }}"
      assert verify_job =~ "fetch-depth: 0"
      assert publish =~ "permissions:\n  contents: read"
      assert release =~ "permissions:\n  contents: write\n  issues: write\n  pull-requests: write"
      assert release_publish_job =~ "permissions:\n      contents: read"
      assert verify_release =~ "permissions:\n  contents: read\n  issues: write"
      refute publish_job =~ "persist-credentials: false"
      refute release_job =~ "persist-credentials: false"
      refute release_publish_job =~ "persist-credentials: false"
      refute verify_job =~ "persist-credentials: false"
    end

    test "website action pin contracts reject wrong SHA and version comments" do
      website = File.read!(@website_yml)
      setup_node_sha = "949feb2413d6458794dcd2491c4babbbce0c15c1"
      deploy_pages_sha = "368f82528645a54fb793d4d04e342629a3f51346"

      wrong_setup_sha = String.replace(website, setup_node_sha, String.duplicate("f", 40))
      wrong_deploy_comment = String.replace(website, "# v5.0.1", "# v5.0.0")

      assert_raise ExUnit.AssertionError, fn ->
        assert_action_pin!(wrong_setup_sha, "actions/setup-node", setup_node_sha, "v7.1.0")
      end

      assert_raise ExUnit.AssertionError, fn ->
        assert_action_pin!(
          wrong_deploy_comment,
          "actions/deploy-pages",
          deploy_pages_sha,
          "v5.0.1"
        )
      end
    end
  end

  describe "CACHE-02 graph-aware BEAM cache wiring" do
    test "path-dependent CI consumers key their graph before normal dependency resolution and verification" do
      ci = File.read!(@ci_yml)

      for {job_name, graph, profile, verify_command} <- [
            {"ops-ui", "ops", "ops-test", "mix verify.ops_ui"},
            {"phoenix-example", "phoenix-example", "phoenix-test", "mix verify.phoenix_example"},
            {"ecommerce-mounted", "ecommerce", "ecommerce-test", "mix verify.ecommerce_mounted"},
            {"ecommerce-e2e", "ecommerce", "ecommerce-test", "mix verify.ecommerce_e2e"}
          ] do
        job = workflow_job_block(ci, job_name)

        assert job =~ "beam_cache.cjs plan --graph #{graph}"
        assert job =~ "MIX_ENV: test"
        assert job =~ "MIX_TARGET: host"
        assert job =~ "BEAM_CACHE_PROFILE: #{profile}"

        assert_ordered_steps(job, [
          "beam_cache.cjs plan --graph #{graph}",
          "actions/cache@",
          "mix deps.get",
          verify_command
        ])
      end
    end

    test "deep-quality resolves dependencies and caches PLTs separately with a strict key" do
      deep_quality = File.read!(@ci_yml) |> workflow_job_block("deep-quality")

      assert deep_quality =~ "beam_cache.cjs plan --graph root"
      assert deep_quality =~ "MIX_ENV: test"
      assert deep_quality =~ "MIX_TARGET: host"
      assert deep_quality =~ "BEAM_CACHE_PROFILE: deep-quality-test"
      assert deep_quality =~ "outputs.plt_paths"
      assert deep_quality =~ "outputs.plt_key"
      assert deep_quality =~ "mix deps.get"

      assert deep_quality =~
               ~r|path: \$\{\{ steps\.beam_cache\.outputs\.plt_paths \}\}\n\s+key: \$\{\{ steps\.beam_cache\.outputs\.plt_key \}\}\n\s+- run:|

      assert_ordered_steps(deep_quality, [
        "beam_cache.cjs plan --graph root",
        "actions/cache@",
        "mix deps.get",
        "elixir scripts/ci/dependency_audit.exs",
        "run_deep_quality_without_audit"
      ])
    end

    test "Node BEAM cache and exact-source collector boundaries execute inside the wiring contract lane" do
      {output, status} =
        System.cmd(
          "node",
          [
            "--test",
            "--test-reporter=tap",
            "scripts/ci/beam_cache.test.cjs",
            "scripts/ci/phase182_acceptance.test.cjs"
          ],
          stderr_to_stdout: true
        )

      assert status == 0, output
      assert output =~ ~r/# tests [1-9]\d*/
      assert output =~ "# fail 0"
      assert output =~ "BEAM probe keys preserve normal keys and isolate forced fallback misses"
    end
  end

  describe "CI-01 ecommerce path classifier wiring" do
    @classifier_script "scripts/ci/ecommerce_path_classifier.cjs"
    @classifier_node_test "scripts/ci/ecommerce_path_classifier.test.cjs"
    @classifier_allowlist ~S"^(\.planning/|docs/|[^/]+\.md$)"
    @mounted_fail_open_if "if: ${{ !cancelled() && (needs.ecommerce-path.result != 'success' || needs.ecommerce-path.outputs.run != 'false') }}"
    @step_fail_open_if "if: ${{ needs.ecommerce-path.result != 'success' || needs.ecommerce-path.outputs.run != 'false' }}"
    @allowlisted_paths [".planning/STATE.md", "docs/guide.md", "README.md"]
    @browser_install_step "Install locked demo dependencies for PNG evidence validation"
    @browser_start_step "Start browser build, lifecycle, evidence, and target behavior tests in the background"
    @browser_wait_step "Verify browser build, lifecycle, evidence, and target behavior"
    @contract_run_line "      - run: mix verify.repository_contracts\n"

    test "ecommerce-path is a fail-open classifier job, not a gate" do
      ci = File.read!(@ci_yml)
      job = workflow_job_block(ci, "ecommerce-path")

      assert job =~ "fetch-depth: 0"
      assert job =~ ~s(outputs: {run: "${{ steps.check.outputs.run }}"})
      assert job =~ "timeout-minutes: 5"

      check = workflow_step_block(job, "\n      - id: check\n")

      assert check =~
               ~s(run: node scripts/ci/ecommerce_path_classifier.cjs --output "$GITHUB_OUTPUT")

      # No name, so no new required context; and no `if:`, so the classifier itself always reports.
      refute job =~ "(required)"
      refute job =~ "(path-scoped)"
      refute job =~ ~r/^    name: /m
      refute job =~ ~r/^\s+if: /m
    end

    test "ecommerce-mounted skips only on an explicit run=false from a successful classifier" do
      ci = File.read!(@ci_yml)
      mounted = workflow_job_block(ci, "ecommerce-mounted")

      assert mounted =~ "    name: ecommerce-mounted (required)\n    needs: ecommerce-path\n"
      # Anchored to a whole line so a commented-out or indented-away copy cannot satisfy it.
      assert mounted =~ "\n    " <> @mounted_fail_open_if <> "\n"

      # Every consumer compares with != 'false' so a missing or empty output (a renamed step id, a
      # step that wrote nothing) still runs the lane. The equals-true form would silently skip it.
      refute ci =~ "ecommerce-path.outputs.run == 'true'"

      consumers =
        ci
        |> String.split("\n")
        |> Enum.filter(&String.contains?(&1, "needs.ecommerce-path.outputs.run"))

      # ecommerce-mounted, plus three repository-contracts steps (the demo install, the background
      # start and the final wait, which adds `!cancelled()` so it still reports after a Mix failure).
      assert length(consumers) == 4

      assert Enum.all?(
               consumers,
               &String.contains?(&1, "needs.ecommerce-path.outputs.run != 'false'")
             )

      closeout = workflow_job_block(ci, "closeout-attestation")

      assert closeout =~
               "needs: [core, package, repository-contracts, backend, ecommerce-mounted, coverage]"

      refute closeout =~ "ecommerce-path"
    end

    test "repository-contracts always runs its contract suite and gates only the three Node steps" do
      ci = File.read!(@ci_yml)
      job = workflow_job_block(ci, "repository-contracts")

      assert job =~ "    name: repository-contracts (required)\n    needs: ecommerce-path\n"

      # A failed or timed-out classifier must not skip this required job (a job whose `needs` fail
      # is skipped, and a skipped required job reports success), so the job keeps a status function.
      assert job =~ "\n    if: ${{ !cancelled() }}\n",
             "repository-contracts needs a job-level !cancelled() so a failed classifier cannot skip it"

      for step <- [@browser_install_step, @browser_start_step] do
        assert workflow_named_step_block(job, step) =~ @step_fail_open_if,
               "#{step} must fail open on the classifier"
      end

      # The wait step adds `!cancelled()` so it still reports after a failed Mix half; it fails open too.
      assert workflow_named_step_block(job, @browser_wait_step) =~ @mounted_fail_open_if,
             "#{@browser_wait_step} must fail open on the classifier and survive a failed Mix half"

      # Exactly the job condition plus the three Node-step conditions: nothing else is silently gated.
      assert length(Regex.scan(~r/^\s+if: /m, job)) == 4

      # The contract run itself carries no condition: it is the one step that always runs.
      refute workflow_step_block(job, "\n" <> @contract_run_line) =~ ~r/^\s+if: /m
    end

    test "a .planning-only diff is accepted as skippable" do
      assert_skips!(classify_paths([".planning/STATE.md"], "pull_request"))
      assert_skips!(classify_paths([".planning/phases/188.1-x/188.1-01-PLAN.md"], "pull_request"))
    end

    test "docs and root markdown beside planning paths are skippable" do
      assert_skips!(classify_paths(@allowlisted_paths, "pull_request"))
    end

    test "allowlisted paths plus exactly one non-allowlisted path run the lanes" do
      for extra <- ~w(
            brand/x scrypath_ops/x.ex examples/x scripts/ci/x.cjs lib/x.ex dev/x.ex config/x.exs
            priv/x language/x fixtures/x test/x.exs website/x guides/x.md mix.exs mix.lock
            .github/workflows/ci.yml .github/workflows/website.yml
          ) do
        assert_runs!(classify_paths(@allowlisted_paths ++ [extra], "pull_request"), extra)
      end
    end

    test "an empty diff, an unreadable diff and non-pull-request events run the lanes" do
      assert_runs!(classify_paths([], "pull_request"))

      dir = classifier_tmp_dir()
      assert_runs!(run_classifier_file(Path.join(dir, "missing-paths-file"), "pull_request", dir))

      for event <- ~w(push schedule workflow_dispatch merge_group) do
        assert_runs!(classify_paths([".planning/STATE.md"], event), event)
      end
    end

    test "the planted-diff assertion has teeth: a widened allowlist is caught" do
      source = File.read!(@classifier_script)

      assert source =~ @classifier_allowlist,
             "the classifier must keep the verbatim CI-01 allowlist literal"

      widened = String.replace(source, @classifier_allowlist, ~S"^(.*)")
      assert widened != source

      dir = classifier_tmp_dir()
      pristine_copy = Path.join(dir, "pristine_classifier.cjs")
      widened_copy = Path.join(dir, "widened_classifier.cjs")
      File.write!(pristine_copy, source)
      File.write!(widened_copy, widened)

      planted = @allowlisted_paths ++ ["lib/x.ex"]

      # Control: an untouched copy of the real script runs the lanes for the planted diff.
      assert_runs!(classify_paths(planted, "pull_request", pristine_copy))

      # The widened copy skips it, and the assertion refuses that.
      assert_skips!(classify_paths(planted, "pull_request", widened_copy))

      assert_raise ExUnit.AssertionError, fn ->
        assert_runs!(classify_paths(planted, "pull_request", widened_copy))
      end
    end

    test "the classifier's own node test executes inside the contract lane" do
      {output, status} =
        System.cmd("node", ["--test", "--test-reporter=tap", @classifier_node_test],
          stderr_to_stdout: true
        )

      assert status == 0, output
      assert output =~ ~r/# tests [1-9]\d*/
      assert output =~ "# fail 0"
    end
  end

  describe "CI-02 repository-contracts runs its Node and Mix halves concurrently" do
    @browser_test_files [
      "scripts/ci/ecommerce_build.test.cjs",
      "scripts/ci/ecommerce_lifecycle.test.cjs",
      "scripts/ci/ecommerce_evidence.test.cjs",
      "scripts/ci/ecommerce_target.test.cjs",
      "scripts/ci/ui_state_pairs.test.cjs"
    ]

    test "the Node half starts in the background, the Mix half runs, then the job waits for the Node half" do
      assert_repository_contracts_concurrent!(File.read!(@ci_yml))
    end

    test "the contract rejects a job that drops, serializes or ignores either half" do
      ci = File.read!(@ci_yml)
      assert_repository_contracts_concurrent!(ci)

      job = workflow_job_block(ci, "repository-contracts")

      start_text =
        "      - name: #{@browser_start_step}\n" <>
          workflow_named_step_block(job, @browser_start_step) <> "\n"

      assert String.contains?(job, start_text)

      planted = [
        {"Node half never started",
         String.replace(job, "- name: #{@browser_start_step}\n", "- name: Something unrelated\n")},
        {"Node half never awaited",
         String.replace(job, "- name: #{@browser_wait_step}\n", "- name: Something unrelated\n")},
        {"Mix half dropped",
         String.replace(job, @contract_run_line, "      - run: echo skipped\n")},
        {"one Node test file dropped from the background run",
         Regex.replace(~r/ *scripts\/ci\/ecommerce_lifecycle\.test\.cjs \\\n/, job, "")},
        {"Node exit status ignored by the wait step",
         String.replace(job, "          test \"$status\" = 0\n", "")},
        {"Node failure swallowed",
         String.replace(job, "test \"$status\" = 0\n", "test \"$status\" = 0 || true\n")},
        {"Node exit status no longer captured",
         String.replace(job, "echo \"${PIPESTATUS[0]}\" >", "echo 0 >")},
        {"counted TAP failure check dropped",
         Regex.replace(~r/ *grep -Eq '\^# fail 0\$'[^\n]*\n/, job, "")},
        {"counted TAP test-count check dropped",
         Regex.replace(~r/ *grep -Eq '\^# tests \[1-9\]\[0-9\]\*\$'[^\n]*\n/, job, "")},
        {"vanished background process not noticed",
         String.replace(job, "kill -0 \"$pid\" 2>/dev/null", "true")},
        {"wait step skipped after a failed Mix half",
         String.replace(job, @mounted_fail_open_if, @step_fail_open_if)},
        {"wait step soft-fails",
         String.replace(
           job,
           "        timeout-minutes: 30\n",
           "        timeout-minutes: 30\n        continue-on-error: true\n"
         )},
        {"job soft-fails",
         String.replace(
           job,
           "    runs-on: ubuntu-24.04\n",
           "    runs-on: ubuntu-24.04\n    continue-on-error: true\n"
         )},
        {"wait step unbounded", String.replace(job, "        timeout-minutes: 30\n", "")},
        {"Node half runs in the foreground again",
         String.replace(job, "< /dev/null &\n", "< /dev/null\n")},
        {"Node half keeps the step's stdin and output open",
         String.replace(job, " 2>&1 < /dev/null &\n", " &\n")},
        {"Node half started only after the Mix half",
         job
         |> String.replace(start_text, "")
         |> String.replace(@contract_run_line, @contract_run_line <> start_text)},
        {"start step no longer fails open on the classifier",
         String.replace(
           job,
           start_text,
           String.replace(start_text, @step_fail_open_if, "if: true")
         )}
      ]

      for {label, mutated_job} <- planted do
        mutated = String.replace(ci, job, mutated_job, global: false)
        refute mutated == ci, "the planted mutation #{label} changed nothing"

        accepted? =
          try do
            assert_repository_contracts_concurrent!(mutated)
            true
          rescue
            ExUnit.AssertionError -> false
          end

        refute accepted?, "planted #{label} was accepted by the concurrency contract"
      end
    end

    # Runs the real start and wait scripts from ci.yml against a stub `node`, so what they do is
    # observed rather than inferred from their text. A stub `sleep` keeps the wait loop quick.
    test "the start step returns at once and the wait step fails for every way the Node half can fail" do
      ci = File.read!(@ci_yml)
      job = workflow_job_block(ci, "repository-contracts")

      start_script =
        job |> workflow_named_step_block(@browser_start_step) |> workflow_step_run_script()

      wait_script =
        job |> workflow_named_step_block(@browser_wait_step) |> workflow_step_run_script()

      # Passing: the start step must return while the Node half is still running.
      fixture = browser_halves_fixture()
      {_, 0} = run_browser_script(start_script, fixture, STUB_NODE_SLEEP: "2")

      refute File.exists?(fixture.status),
             "the start step waited for the Node half instead of backgrounding it"

      assert File.exists?(fixture.pid)
      {output, 0} = run_browser_script(wait_script, fixture, [])
      assert output =~ "TAP version 13", "the wait step must print the Node half's output"
      assert output =~ "exit status: 0"
      assert File.read!(fixture.status) == "0\n"

      # Every way the Node half can fail fails the wait step, so the job.
      failing = [
        {"tests failed", [STUB_FAILS: "1", STUB_EXIT: "1"], "exit status: 1"},
        {"non-zero exit status with a clean TAP summary", [STUB_EXIT: "3"], "exit status: 3"},
        {"no tests counted", [STUB_TESTS: "0"], "exit status: 0"},
        {"TAP failures with exit status 0", [STUB_FAILS: "2"], "exit status: 0"}
      ]

      for {label, stub_env, expected} <- failing do
        fixture = browser_halves_fixture()
        {_, 0} = run_browser_script(start_script, fixture, stub_env)
        {output, status} = run_browser_script(wait_script, fixture, [])
        assert status != 0, "#{label}: the wait step passed a failing Node half:\n#{output}"
        assert output =~ expected, "#{label}: #{output}"
      end

      # The background process vanished without writing a status: fail, do not wait out the timeout.
      fixture = browser_halves_fixture()
      {dead_pid, 0} = System.cmd("sh", ["-c", "sh -c 'exit 0' & echo $!; wait"])
      File.write!(fixture.pid, dead_pid)
      {output, status} = run_browser_script(wait_script, fixture, [])
      assert status != 0
      assert output =~ "stopped without reporting a result"

      # The start step never ran (an earlier step failed): fail with a reason.
      fixture = browser_halves_fixture()
      {output, status} = run_browser_script(wait_script, fixture, [])
      assert status != 0
      assert output =~ "never started"
    end
  end

  describe "DEP-07 upload-artifact is pinned by pattern" do
    @dependabot_132_sha "cf430e030ddbb5b0abf93d22962f4752f3646cd9"

    test "every upload-artifact reference in ci.yml and website.yml matches the pattern" do
      assert_upload_artifact_pin!(File.read!(@ci_yml))
      assert_upload_artifact_pin!(File.read!(@website_yml))
    end

    test "the Dependabot 132 SHA is accepted, whichever SHA the files hold today" do
      for comment <- ["# v7", "# v7.0.2", "# v7.10.0"] do
        assert_upload_artifact_pin!(
          "      - uses: actions/upload-artifact@#{@dependabot_132_sha} #{comment}"
        )
      end

      for path <- [@ci_yml, @website_yml] do
        bumped =
          Regex.replace(
            ~r|(actions/upload-artifact@)[0-9a-f]{40}|,
            File.read!(path),
            "\\1#{@dependabot_132_sha}"
          )

        assert_upload_artifact_pin!(bumped)
      end
    end

    test "a tag, a short or malformed SHA, a wrong major, or a missing comment is rejected" do
      sha = String.duplicate("a", 40)

      rejected = [
        "uses: actions/upload-artifact@v7",
        "uses: actions/upload-artifact@v7 # v7",
        "uses: actions/upload-artifact@#{String.slice(sha, 0, 7)} # v7",
        "uses: actions/upload-artifact@#{String.slice(sha, 0, 39)} # v7",
        "uses: actions/upload-artifact@#{sha}a # v7",
        "uses: actions/upload-artifact@#{String.upcase(sha)} # v7",
        "uses: actions/upload-artifact@#{sha} # v6",
        "uses: actions/upload-artifact@#{sha} # v70",
        "uses: actions/upload-artifact@#{sha} # v8.0.0",
        "uses: actions/upload-artifact@#{sha}",
        "uses: actions/upload-artifact@#{sha} # v7 extra"
      ]

      for line <- rejected do
        assert_raise ExUnit.AssertionError, fn -> assert_upload_artifact_pin!(line) end
      end

      assert_raise ExUnit.AssertionError, fn -> assert_upload_artifact_pin!("no uploads here") end
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

    test "required repository-contracts lane runs counted browser build and behavior tests" do
      ci = File.read!(@ci_yml)
      job = workflow_job_block(ci, "repository-contracts")

      install = workflow_named_step_block(job, @browser_install_step)
      start = workflow_named_step_block(job, @browser_start_step)
      wait = workflow_named_step_block(job, @browser_wait_step)

      assert install =~
               "PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 npm ci --ignore-scripts --prefix examples/scrypath_ecommerce"

      # Install, then start (in the background), then the wait that counts and judges the result.
      assert :binary.match(job, @browser_install_step) < :binary.match(job, @browser_start_step)
      assert :binary.match(job, @browser_start_step) < :binary.match(job, @browser_wait_step)

      assert start =~ "node --test --test-reporter=tap"
      assert start =~ "scripts/ci/ecommerce_evidence.test.cjs"

      for test_file <- [
            "scripts/ci/ecommerce_build.test.cjs",
            "scripts/ci/ecommerce_lifecycle.test.cjs",
            "scripts/ci/ecommerce_evidence.test.cjs",
            "scripts/ci/ecommerce_target.test.cjs",
            "scripts/ci/ui_state_pairs.test.cjs"
          ] do
        assert start =~ test_file,
               "repository-contracts must execute #{test_file} outside the ExUnit suite"
      end

      # The counted TAP summary is still required, unchanged: at least one test and zero failures.
      assert wait =~ "grep -Eq '^# tests [1-9][0-9]*$' \"$RUNNER_TEMP/browser-behavior.tap\""
      assert wait =~ "grep -Eq '^# fail 0$' \"$RUNNER_TEMP/browser-behavior.tap\""
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
      assert contributing =~ "**`ecommerce-mounted`**"
      assert contributing =~ "**`ops-ui (path-scoped)`**"
    end

    @ledger_header [
      "Gate",
      "Enforced by",
      "Runs in",
      "Deletion trigger",
      "Expected churn per UI PR"
    ]
    @phase_186_gate_files [
      "test/mix/tasks/brand_pin_contract_test.exs",
      "examples/scrypath_ecommerce/ui-tokens.test.mjs",
      "test/mix/tasks/workflow_wiring_test.exs",
      "test/mix/tasks/dependency_boundary_contract_test.exs",
      "scripts/ci/ui_state_pairs.test.cjs"
    ]

    test "required-gate budget ledger stays within 12 with deletion triggers" do
      assert budget_ledger_errors(File.read!("CONTRIBUTING.md")) == []
    end

    test "planted ledger defects are flagged and a compliant ledger is accepted" do
      row = fn gate, file, trigger ->
        "| #{gate} | `#{file}` | `core` | #{trigger} | None |"
      end

      valid_rows =
        for file <- @phase_186_gate_files,
            do: row.("Gate for #{file}", file, "Delete when retired")

      ledger = fn rows, budget_line ->
        [
          "### Required-gate budget",
          "",
          "| " <> Enum.join(@ledger_header, " | ") <> " |",
          "|------|------|------|------|------|"
          | rows
        ]
        |> Enum.concat(["", budget_line, "", "### Next section"])
        |> Enum.join("\n")
      end

      assert budget_ledger_errors(ledger.(valid_rows, "Budget used: 5 of 12.")) == []

      extra = for n <- 6..13, do: row.("Extra #{n}", "mix.exs", "Delete when retired")

      assert Enum.any?(
               budget_ledger_errors(ledger.(valid_rows ++ extra, "Budget used: 13 of 12.")),
               &(&1 =~ "13 gates")
             )

      empty_trigger = [row.("No trigger", "mix.exs", "") | valid_rows]

      assert Enum.any?(
               budget_ledger_errors(ledger.(empty_trigger, "Budget used: 6 of 12.")),
               &(&1 =~ "empty trigger cell")
             )

      missing_file = [
        row.("Ghost", "test/mix/tasks/does_not_exist_test.exs", "Never") | valid_rows
      ]

      assert Enum.any?(
               budget_ledger_errors(ledger.(missing_file, "Budget used: 6 of 12.")),
               &(&1 =~ "does not exist")
             )

      assert Enum.any?(
               budget_ledger_errors(ledger.(tl(valid_rows), "Budget used: 4 of 12.")),
               &(&1 =~ "missing the Phase 186 gate")
             )

      assert Enum.any?(
               budget_ledger_errors(ledger.(valid_rows, "Budget used: 4 of 12.")),
               &(&1 =~ "budget line")
             )

      assert ["CONTRIBUTING.md must keep its Required-gate budget section"] =
               budget_ledger_errors("# Nothing here")
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

      # Current immutable refs are v7.0.1 and v6.1.0, respectively.
      refute ci =~ "actions/checkout@v6",
             "actions/checkout should be pinned to v7.0.1, not v6"
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

  describe "MINT-03 dependency security inventory wiring" do
    test "deep-quality owns one four-graph audit then runs the shared remaining checks" do
      ci = File.read!(@ci_yml)
      deep_quality = workflow_job_block(ci, "deep-quality")

      assert deep_quality =~ "name: deep-quality (advisory)"
      assert deep_quality =~ "continue-on-error: true"
      assert deep_quality =~ "mix local.hex 2.5.1 --force"
      assert deep_quality =~ "elixir scripts/ci/dependency_audit.exs"

      assert deep_quality =~
               "mix run --no-start -e 'Mix.Tasks.Verify.Capability.run_deep_quality_without_audit()'"

      assert deep_quality =~ "MIX_ENV: test"

      assert length(Regex.scan(~r|elixir scripts/ci/dependency_audit\.exs|, deep_quality)) == 1
      assert deep_quality =~ "mix deps.get"
      refute deep_quality =~ "mix verify.deep_quality"
      assert deep_quality =~ "MIX_TARGET: host"
      assert deep_quality =~ "BEAM_CACHE_PROFILE: deep-quality-test"
      assert deep_quality =~ "outputs.plt_paths"
      assert deep_quality =~ "outputs.plt_key"
    end
  end

  describe "STAB-01 advisory evidence wiring" do
    test "path-scoped ops-ui job provides its Postgres test dependency" do
      ops_ui = @ci_yml |> File.read!() |> workflow_job_block("ops-ui")

      assert ops_ui =~ "services:"
      assert ops_ui =~ "postgres:"
      assert ops_ui =~ "image: postgres:16-alpine"
      assert ops_ui =~ "POSTGRES_USER: postgres"
      assert ops_ui =~ "POSTGRES_PASSWORD: postgres"
      assert ops_ui =~ "ports: [5433:5432]"
      assert ops_ui =~ "pg_isready -U postgres"

      assert ops_ui =~ ~s|PGPORT: "5433"|
    end

    test "required backend job provides the real-Postgres loader lane" do
      backend = @ci_yml |> File.read!() |> workflow_job_block("backend")

      assert backend =~ "name: backend (required)"
      assert backend =~ "image: postgres:16-alpine"
      assert backend =~ "ports: [5434:5432]"
      assert backend =~ "pg_isready -U postgres"
      assert backend =~ "SCRYPATH_POSTGRES_URL: postgres://postgres:postgres@127.0.0.1:5434"
      assert backend =~ "mix verify.backend"
    end

    test "the mounted proof remains distinct and required without promoting full E2E" do
      ci = File.read!(@ci_yml)
      contributing = File.read!("CONTRIBUTING.md")

      assert workflow_job_block(ci, "ecommerce-mounted") =~ "mix verify.ecommerce_mounted"

      assert contributing =~ "**`ecommerce-mounted`**"
      assert contributing =~ "`ecommerce-e2e` is advisory today"
    end

    test "Phase 182 cache probes are opt-in and keep existing jobs and canonical verifiers" do
      ci = File.read!(@ci_yml)
      [triggers, _jobs] = String.split(ci, "\njobs:\n", parts: 2)
      core = workflow_job_block(ci, "core")
      mounted = workflow_job_block(ci, "ecommerce-mounted")
      full = workflow_job_block(ci, "ecommerce-e2e")

      assert triggers =~ "workflow_dispatch:"
      assert triggers =~ "phase182_cache_mode:"
      assert triggers =~ "default: normal"
      assert triggers =~ "phase182_probe_namespace:"
      assert triggers =~ "type: string"
      assert triggers =~ "default: \"\""

      for mode <- ["normal", "docker-cold", "beam-cold", "beam-fallback", "beam-lock-change"] do
        assert triggers =~ "- #{mode}"
      end

      assert core =~ "phase182_acceptance.cjs validate-inputs"
      assert core =~ "phase182_acceptance.cjs beam-plan"
      assert core =~ "if: steps.phase182_inputs.outputs.mode != 'beam-cold'"

      assert core =~
               "uses: actions/cache/restore@55cc8345863c7cc4c66a329aec7e433d2d1c52a9 # v6.1.0"

      assert core =~ "uses: actions/cache/save@55cc8345863c7cc4c66a329aec7e433d2d1c52a9 # v6.1.0"
      assert core =~ "steps.phase182_downloads_cache.outputs.cache-matched-key"
      assert core =~ "steps.phase182_resolved_cache.outputs.cache-matched-key"
      assert core =~ "steps.phase182_downloads_cache.outputs.cache-hit != 'true'"
      assert core =~ "steps.phase182_resolved_cache.outputs.cache-hit != 'true'"
      assert core =~ "mix deps.get"
      assert core =~ "mix compile --warnings-as-errors"
      assert core =~ "mix verify.core --exclude integration --exclude docs_contract"

      assert elem(
               :binary.match(
                 core,
                 "mix verify.core --exclude integration --exclude docs_contract"
               ),
               0
             ) <
               elem(:binary.match(core, "name: Save Hex download archive cache"), 0)

      assert elem(:binary.match(core, "name: Save Hex download archive cache"), 0) <
               elem(:binary.match(core, "name: Save resolved BEAM build cache"), 0)

      assert core =~ "phase182_acceptance.cjs prepare-lock"
      assert core =~ "phase182_acceptance.cjs write-beam-proof"

      assert mounted =~ "phase182_acceptance.cjs configure-docker"
      assert mounted =~ "docker buildx inspect \"$BUILDER_ID\" --bootstrap"
      assert mounted =~ "mix verify.ecommerce_mounted"

      assert mounted =~
               "phase182-cache-probe-docker-cold-${{ github.run_id }}-${{ github.run_attempt }}"

      assert full =~
               "if: github.event_name == 'schedule' || github.event_name == 'workflow_dispatch'"

      assert full =~ "phase182_acceptance.cjs configure-docker"
      assert full =~ "mix verify.ecommerce_e2e"

      assert full =~
               "phase182-cache-probe-docker-warm-${{ github.run_id }}-${{ github.run_attempt }}"
    end

    test "mounted and full E2E bake the checked local Compose graph without pushing" do
      ci = File.read!(@ci_yml)

      for {job_name, cache_job} <- [{"ecommerce-mounted", "mounted"}, {"ecommerce-e2e", "full"}] do
        job = workflow_job_block(ci, job_name)

        assert job =~ "E2E_CACHE_JOB: #{cache_job}"
        assert job =~ "uses: docker/setup-buildx-action@f87e5991a6d7451dcb8d9637bfbc97413f497069"
        assert job =~ "version: v0.37.2"
        assert job =~ "driver-opts: image=moby/buildkit:v0.33.1"
        assert job =~ "uses: docker/bake-action@59cb1203cd42bcefd40a1b6d73b589e48c86040e"

        assert job =~
                 "files: ${{ runner.temp }}/ecommerce-#{cache_job}-${{ github.run_id }}-${{ github.run_attempt }}/bake.json"

        assert job =~ "load: true"
        assert job =~ "push: false"
        assert job =~ "ecommerce_build.cjs verify-handoff --manifest"
        assert job =~ "ecommerce_build.cjs cache-outcome --manifest"
      end
    end

    test "ecommerce-e2e preserves raw outcome and uploads only this run's evidence" do
      ci = File.read!(@ci_yml)
      job = workflow_job_block(ci, "ecommerce-e2e")

      assert job =~ "timeout-minutes: 30"

      verify = workflow_named_step_block(job, "Run advisory full E2E proof")
      prepare = workflow_named_step_block(job, "Prepare checked full Compose images")
      upload = workflow_named_step_block(job, "Upload advisory E2E evidence")
      start_clock = workflow_named_step_block(job, "Record E2E job start and deadline")
      verifier_script = File.read!("examples/scrypath_ecommerce/scripts/verify-e2e.sh")

      checkout =
        workflow_step_with_uses_block(
          job,
          "actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1"
        )

      assert job =~ "name: ecommerce-e2e (advisory)"

      assert job =~
               "if: github.event_name == 'schedule' || github.event_name == 'workflow_dispatch'"

      assert job =~ "continue-on-error: true"
      assert job =~ "timeout-minutes: 30"
      assert job =~ "verification_outcome: ${{ steps.ecommerce_verify.outcome }}"
      assert job =~ "artifact_id: ${{ steps.ecommerce_upload.outputs.artifact-id }}"
      assert job =~ "artifact_url: ${{ steps.ecommerce_upload.outputs.artifact-url }}"
      assert job =~ "artifact_digest: ${{ steps.ecommerce_upload.outputs.artifact-digest }}"
      assert start_clock =~ "E2E_JOB_STARTED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
      assert start_clock =~ "E2E_DEADLINE_EPOCH=$((E2E_JOB_STARTED_EPOCH + 1800))"
      assert start_clock =~ "GITHUB_SHA"
      assert start_clock =~ "E2E_FINALIZATION_MARGIN_SECONDS=300"

      assert start_clock =~
               ~s|echo "E2E_PHASE185_CLOCK_PATH=$RUNNER_TEMP/phase185-clock-$GITHUB_RUN_ID-$GITHUB_RUN_ATTEMPT.txt" >> "$GITHUB_ENV"|

      assert prepare =~ "ecommerce_build.cjs prepare --scope full"
      assert prepare =~ "E2E_PRODUCT_SOURCE_SHA=\"$SCRYPATH_SOURCE_SHA\""
      assert prepare =~ "productTreeIdentity(process.cwd())"
      assert prepare =~ "fixtureOverlayDigest(process.cwd())"

      assert prepare =~
               "export E2E_PRODUCT_SOURCE_SHA E2E_PRODUCT_TREE_SHA256 E2E_FIXTURE_OVERLAY_SHA256"

      for variable <- [
            "E2E_PRODUCT_SOURCE_SHA",
            "E2E_PRODUCT_TREE_SHA256",
            "E2E_FIXTURE_OVERLAY_SHA256"
          ] do
        assert prepare =~ ~s|echo "#{variable}=$#{variable}"|
      end

      assert verifier_script =~ "productTreeIdentity(process.argv[2])"
      assert verifier_script =~ "fixtureOverlayDigest(process.argv[2])"

      assert verify =~ "id: ecommerce_verify"
      assert verify =~ "run: mix verify.ecommerce_e2e"
      assert verify =~ "E2E_RUN_ID: phase185-${{ github.run_id }}-${{ github.run_attempt }}"
      assert verify =~ "E2E_SOURCE_MODE: hosted"
      assert verify =~ "E2E_EVENT_SHA: ${{ steps.e2e_clock.outputs.E2E_EVENT_SHA }}"

      assert verify =~
               "E2E_WORKFLOW_RUN_ATTEMPT: ${{ steps.e2e_clock.outputs.E2E_WORKFLOW_RUN_ATTEMPT }}"

      assert verifier_script =~
               ~s|phase185_clock_path="${E2E_PHASE185_CLOCK_PATH:-$artifact_dir/phase185-clock.txt}"|

      assert verifier_script =~ "Phase185 full verification requires exact immutable clock bytes"
      assert verifier_script =~ "export E2E_PHASE185_CLOCK_PATH=\"$phase185_clock_path\""

      assert upload =~ "id: ecommerce_upload"
      assert upload =~ "if: always()"

      assert upload =~
               "test-results/docker-full/phase185-${{ github.run_id }}-${{ github.run_attempt }}"

      assert upload =~
               "name: ecommerce-e2e-evidence-${{ github.run_id }}-${{ github.run_attempt }}"

      assert upload =~ "if-no-files-found: error"
      assert upload =~ "retention-days: 7"
      assert_upload_artifact_pin!(upload)

      assert :binary.match(job, "Record E2E job start and deadline") <
               :binary.match(
                 job,
                 "actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1"
               )

      assert checkout =~ "fetch-depth: 0"
    end

    test "mounted E2E failure upload is scoped to the current invocation" do
      ci = File.read!(@ci_yml)
      job = workflow_job_block(ci, "ecommerce-mounted")
      verify = workflow_named_step_block(job, "Run mounted E2E proof")

      upload = workflow_named_step_block(job, "Upload mounted E2E failure evidence")

      assert job =~ "name: ecommerce-mounted (required)"
      assert verify =~ "mix verify.ecommerce_mounted"
      assert verify =~ "E2E_RUN_ID: ${{ github.run_id }}-${{ github.run_attempt }}"
      assert upload =~ "if: failure()"

      assert upload =~
               "test-results/docker-focused/${{ github.run_id }}-${{ github.run_attempt }}"

      assert upload =~ "if-no-files-found: warn"
      assert upload =~ "retention-days: 7"
    end

    test "exactly six required contexts: five (required) jobs plus ops-ui (path-scoped)" do
      ci = File.read!(@ci_yml)

      required =
        Regex.scan(~r/^  ([a-z][a-z0-9-]+):\n    name: .*\((required|path-scoped)\)$/m, ci)
        |> Enum.map(fn [_, job, _suffix] -> job end)
        |> Enum.sort()

      assert required == [
               "backend",
               "core",
               "ecommerce-mounted",
               "ops-ui",
               "package",
               "repository-contracts"
             ]

      # `main` branch protection lists this exact context string. Renaming the job would orphan the
      # live required context and leave merges waiting for a check that never reports.
      assert workflow_job_block(ci, "ops-ui") =~ "    name: ops-ui (path-scoped)\n",
             "renaming the ops-ui job would orphan the live required context on main"
    end

    test "full Docker proof retains deterministic checks after judge entrypoint retirement" do
      docker_runner = File.read!("examples/scrypath_ecommerce/docker-playwright.sh")
      compose = File.read!("examples/scrypath_ecommerce/compose.e2e.yaml")
      package_json = File.read!("examples/scrypath_ecommerce/package.json")

      assert package_json =~ ~s("test:e2e": "playwright test --workers=1")
      assert package_json =~ "test:e2e:admin-light-parity"
      assert package_json =~ "test:e2e:admin-shell-wash"
      refute package_json =~ "test:e2e:ops-ui-visual-judge"
      refute File.exists?("examples/scrypath_ecommerce/e2e/ops-ui-visual-judge.mjs")
      makefile = File.read!("examples/scrypath_ecommerce/Makefile")
      refute makefile =~ "OPS_UI_LLM_JUDGE"
      refute makefile =~ "JUDGE_STATUS"
      refute File.exists?("examples/scrypath_ecommerce/e2e/ops-ui-visual-rubric.md")

      for path <- ["CONTRIBUTING.md", "examples/scrypath_ecommerce/README.md"] do
        refute File.read!(path) =~ "test:e2e:ops-ui-visual-judge"
      end

      assert makefile =~ ~s|[ "$$SHELL_STATUS" -eq 0 ] && [ "$$WASH_STATUS" -eq 0 ]|
      assert docker_runner =~ "npm run test:e2e"
      assert docker_runner =~ "npm run test:e2e:admin-light-parity"
      assert docker_runner =~ "node contrast-checker.mjs"
      refute docker_runner =~ "npm run test:e2e:ops-ui-visual-judge"
      refute compose =~ "OPS_UI_LLM_JUDGE"
      refute compose =~ "OPENAI_API_KEY"
    end

    test "Docker verifier bounds collected artifacts to logs and browser reports" do
      verifier = File.read!("examples/scrypath_ecommerce/scripts/verify-e2e.sh")

      assert verifier =~ "test-results/docker-${scope}"
      assert verifier =~ ~s|"/tmp/$run_id"|
      assert verifier =~ "E2E_CONTAINER_ARTIFACT_DIR"
      assert verifier =~ "compose.log"
      assert verifier =~ "artifact_copy_status"
      assert verifier =~ "artifact-manifest.json"
    end

    test "playwright config emits structured phase105 report and forbids acceptance retries" do
      config = File.read!("examples/scrypath_ecommerce/playwright.config.ts")

      assert config =~ "retries: 0"
      refute config =~ "retries: process.env.CI"
      assert config =~ "workers: 1"
      assert config =~ "trace: \"retain-on-failure\""
      assert config =~ "phase105-playwright.json"
    end

    test "phase105 evidence summary includes shifted-left visual gates" do
      summary_script = File.read!("scripts/ci/phase105_evidence.sh")
      evidence_writer = File.read!("scripts/ci/ecommerce_evidence.cjs")

      assert summary_script =~ "ecommerce_evidence.cjs"
      assert summary_script =~ "write-evidence"
      assert summary_script =~ "--run-dir"
      assert evidence_writer =~ "admin-light-parity.json"
      assert evidence_writer =~ "light_parity_status"
      assert evidence_writer =~ "shell_wash_conclusion"
      assert evidence_writer =~ "shell_wash_visual"

      [current_writer, _legacy_reader] =
        String.split(evidence_writer, "function renderSummary", parts: 2)

      refute current_writer =~ "visual_judge_"
      assert evidence_writer =~ "withoutLegacyJudgeFields"
      refute evidence_writer =~ "ops-ui-visual-judge.json"
    end
  end

  describe "TEST-05 scheduled/manual informational coverage" do
    test "coverage is a bounded scheduled/manual advisory job with a retained source-SHA report" do
      ci = File.read!(@ci_yml)
      coverage_job = workflow_job_block(ci, "coverage")

      coverage_upload =
        workflow_named_step_block(coverage_job, "Upload informational coverage report")

      coverage_verify = workflow_named_step_block(coverage_job, "Run informational coverage")

      coverage_checkout =
        workflow_step_with_uses_block(
          coverage_job,
          "actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1"
        )

      assert length(Regex.scan(~r/^  coverage:$/m, ci)) == 1
      assert coverage_job =~ "name: coverage (advisory)"

      assert coverage_job =~
               "if: github.event_name == 'schedule' || github.event_name == 'workflow_dispatch'"

      assert coverage_job =~ "continue-on-error: true"
      assert coverage_verify =~ "id: coverage_verify"
      assert coverage_verify =~ "run: mix verify.coverage"
      assert coverage_job =~ "verification_outcome: ${{ steps.coverage_verify.outcome }}"
      assert coverage_upload =~ "if: always()"
      assert coverage_upload =~ "id: coverage_upload"

      assert_upload_artifact_pin!(coverage_upload)

      assert coverage_upload =~ "name: coverage-report-${{ github.sha }}"
      assert coverage_upload =~ "path: cover/"
      assert coverage_upload =~ "if-no-files-found: warn"
      assert coverage_upload =~ "retention-days: 7"
      assert coverage_job =~ "artifact_id: ${{ steps.coverage_upload.outputs.artifact-id }}"
      assert coverage_job =~ "artifact_url: ${{ steps.coverage_upload.outputs.artifact-url }}"

      assert coverage_job =~
               "artifact_digest: ${{ steps.coverage_upload.outputs.artifact-digest }}"

      assert coverage_checkout =~ "with: {fetch-depth: 0}"
      refute coverage_checkout =~ ~r/^\s*ref:/m
      refute coverage_job =~ "secrets."
      refute coverage_job =~ "id-token"
    end

    test "manual closeout attestation fails closed over exact required jobs and coverage artifact provenance" do
      ci = File.read!(@ci_yml)
      closeout_job = workflow_job_block(ci, "closeout-attestation")

      closeout_upload =
        workflow_named_step_block(closeout_job, "Upload exact-SHA closeout attestation")

      assert closeout_job =~ "name: closeout-attestation"
      assert closeout_job =~ "if: ${{ always() && github.event_name == 'workflow_dispatch' }}"

      assert closeout_job =~
               "needs: [core, package, repository-contracts, backend, ecommerce-mounted, coverage]"

      for result <-
            ~w(CORE_RESULT PACKAGE_RESULT REPOSITORY_CONTRACTS_RESULT BACKEND_RESULT ECOMMERCE_MOUNTED_RESULT) do
        assert closeout_job =~ ~s(test "$#{result}" = success)
      end

      assert closeout_job =~ ~s(test "$COVERAGE_OUTCOME" = success)
      assert closeout_job =~ ~s(test -n "$COVERAGE_ARTIFACT_ID")
      assert closeout_job =~ ~s(test -n "$COVERAGE_ARTIFACT_URL")
      assert closeout_job =~ ~s(test -n "$COVERAGE_ARTIFACT_DIGEST")
      assert closeout_job =~ "github-actions-exact-sha"
      assert closeout_job =~ "head_sha: $head_sha"
      assert closeout_job =~ "run_id: $run_id"

      assert_upload_artifact_pin!(closeout_upload)

      assert closeout_upload =~ "name: closeout-attestation-${{ github.sha }}"
      assert closeout_upload =~ "path: closeout-attestation.json"
      assert closeout_upload =~ "if-no-files-found: error"
      assert closeout_upload =~ "retention-days: 7"
      refute closeout_job =~ "secrets."
      refute closeout_job =~ "id-token"
    end
  end

  describe "CI hygiene (runner pin, token scope, action pins, ops-ui gate)" do
    @workflow_files Path.wildcard(".github/workflows/*.yml")
    @pin_script "scripts/ci/check_action_pins.sh"

    test "no workflow floats on ubuntu-latest" do
      offenders = for f <- @workflow_files, File.read!(f) =~ "ubuntu-latest", do: f
      assert offenders == [], "pin runs-on to a named image: #{inspect(offenders)}"
    end

    test "every workflow declares a top-level permissions block" do
      for f <- @workflow_files do
        assert File.read!(f) =~ ~r/^permissions:\n  [a-z-]+: (read|write)/m,
               "#{f} must declare top-level permissions"
      end
    end

    test "action pin script rejects an unpinned uses line under a named step" do
      tmp = Path.join(System.tmp_dir!(), "pins-#{System.unique_integer([:positive])}")
      File.mkdir_p!(tmp)
      on_exit(fn -> File.rm_rf(tmp) end)

      bad = Path.join(tmp, "bad.yml")
      sha = String.duplicate("a", 40)

      File.write!(bad, "steps:\n  - name: x\n    uses: actions/checkout@v4\n")
      assert {out, 1} = System.cmd("bash", [@pin_script, bad], stderr_to_stdout: true)
      assert out =~ "Unpinned action reference: actions/checkout@v4"

      File.write!(bad, "steps:\n  - name: x\n    uses: actions/checkout@#{sha} # v7\n")
      assert {_, 0} = System.cmd("bash", [@pin_script, bad], stderr_to_stdout: true)

      assert {_, 0} =
               System.cmd("bash", [@pin_script | @workflow_files], stderr_to_stdout: true)
    end

    test "ops-ui is a required context that reports instead of being path-filtered" do
      ci = File.read!(@ci_yml)
      ops_ui = workflow_job_block(ci, "ops-ui")

      # Required contexts must report on every PR: no workflow-level path filter in ci.yml.
      on_block = ci |> String.split("\npermissions:") |> hd()
      refute on_block =~ ~r/^\s+paths(-ignore)?:/m
      assert ops_ui =~ "name: ops-ui (path-scoped)"
      assert ops_ui =~ "needs.ops-ui-path.result != 'success'"

      path_job = workflow_job_block(ci, "ops-ui-path")

      for dir <- ~w(scrypath_ops/ lib/ dev/ brand/ language/ fixtures/ scripts/ci/ test/release/) do
        assert path_job =~ dir, "ops-ui path gate must cover #{dir}"
      end
    end

    # COPY-03 (Phase 190, D-18 and D-19): the copy rules table scans the glossary, DESIGN.md and
    # the demo's e2e specs, so a PR that only edits one of them must still run ops-ui. The
    # substring loop above cannot tell a pattern that works from one that only looks right, so
    # this compiles the pattern the job really greps with and matches paths against it.
    test "the ops-ui path pattern matches every path the copy rules table scans" do
      path_job = @ci_yml |> File.read!() |> workflow_job_block("ops-ui-path")
      pattern = ops_ui_path_pattern(path_job)
      regex = Regex.compile!(pattern)

      copy_inputs = [
        "GLOSSARY.md",
        "DESIGN.md",
        "examples/scrypath_ecommerce/e2e/operator.spec.ts",
        "examples/scrypath_ecommerce/lib/x.ex",
        "examples/scrypath_ecommerce/test/x_test.exs",
        "examples/scrypath_ecommerce/scripts/x.mjs",
        "scrypath_ops/lib/x.ex"
      ]

      assert ops_ui_path_misses(regex, copy_inputs) == []

      assert ops_ui_path_misses(regex, ["README.md", "website/src/index.html"]) ==
               ["README.md", "website/src/index.html"]

      # Negative control: the same check run on a pattern with the new alternatives removed
      # reports the glossary, DESIGN.md and the demo paths as missed. A check that cannot fail
      # would not be a check.
      new_alternatives =
        "|GLOSSARY\\.md|DESIGN\\.md|examples/scrypath_ecommerce/(e2e|lib|test|scripts)/"

      assert pattern =~ new_alternatives
      narrowed = Regex.compile!(String.replace(pattern, new_alternatives, ""))

      assert ops_ui_path_misses(narrowed, copy_inputs) ==
               copy_inputs -- ["scrypath_ops/lib/x.ex"]

      # The table and the pattern cannot drift: every literal directory a row scans must match.
      rows = "scrypath_ops/test/support/copy_rules.json" |> File.read!() |> Jason.decode!()

      scopes =
        for %{"id" => id, "source_scope" => globs} <- rows["rules"], glob <- globs do
          {id, glob}
        end

      assert scopes != [], "the copy rules table has no source_scope to check"

      for {id, glob} <- scopes, glob != "**" do
        prefix = String.replace_suffix(glob, "**", "")

        assert Regex.match?(regex, prefix),
               "copy rule #{id} scans #{glob}, but the ops-ui path pattern does not match #{prefix}"
      end

      # The whole-tree scope is the one place PR-time coverage is partial: a PR that touches
      # only a path outside the pattern (website/ or a root markdown file, say) skips ops-ui.
      # It is still enforced on every push to main, because ops-ui-path always runs there.
      assert Enum.any?(scopes, fn {_id, glob} -> glob == "**" end)
      assert path_job =~ ~s(GITHUB_EVENT_NAME" == push && "$GITHUB_REF" == refs/heads/main)
    end
  end

  defp assert_oban_suppressions!(source, path) do
    {_ast, {sites, tokens}} =
      source
      |> Code.string_to_quoted!()
      |> Macro.prewalk({[], 0}, fn
        {:no_warn_undefined, target} = node, {sites, tokens} ->
          {node, {[target | sites], tokens}}

        :no_warn_undefined = node, {sites, tokens} ->
          {node, {sites, tokens + 1}}

        node, acc ->
          {node, acc}
      end)

    assert length(sites) == tokens, "#{path} contains an unparsed no_warn_undefined option"

    for targets <- sites, target <- List.wrap(targets) do
      assert oban_suppression_target?(target),
             "#{path} suppresses undefined warnings for #{Macro.to_string(target)}, " <>
               "which must be a literal Oban module or MFA"
    end

    length(sites)
  end

  defp oban_suppression_target?({:__aliases__, _, [:Oban | _]}), do: true

  defp oban_suppression_target?({:{}, _, [module, function, arity]})
       when is_atom(function) and is_integer(arity) and arity >= 0,
       do: oban_suppression_target?(module)

  defp oban_suppression_target?(module) when is_atom(module),
    do: module == Oban or String.starts_with?(Atom.to_string(module), "Elixir.Oban.")

  defp oban_suppression_target?(_target), do: false

  defp assert_ordered_steps(content, [first | rest]) do
    {start_idx, _} = :binary.match(content, first)

    Enum.reduce(rest, start_idx, fn step, prev_idx ->
      {idx, _} = :binary.match(content, step)
      assert idx > prev_idx, "expected #{inspect(step)} to appear after previous release step"
      idx
    end)
  end

  # Returns a list of problems with the "Required-gate budget" ledger in the given CONTRIBUTING text.
  defp budget_ledger_errors(contributing) do
    case String.split(contributing, "### Required-gate budget", parts: 2) do
      [_before, after_heading] ->
        section = after_heading |> String.split(["\n## ", "\n### "], parts: 2) |> hd()

        table =
          section
          |> String.split("\n")
          |> Enum.filter(&String.starts_with?(&1, "|"))
          |> Enum.map(&ledger_cells/1)

        case table do
          [@ledger_header, _separator | rows] -> ledger_errors(rows, section)
          _ -> ["the ledger table header must be #{inspect(@ledger_header)}"]
        end

      [_whole] ->
        ["CONTRIBUTING.md must keep its Required-gate budget section"]
    end
  end

  defp ledger_cells(line) do
    line |> String.trim() |> String.trim("|") |> String.split("|") |> Enum.map(&String.trim/1)
  end

  defp ledger_errors(rows, section) do
    count_errors =
      if length(rows) in 1..12,
        do: [],
        else: ["the ledger lists #{length(rows)} gates; the budget is 1 to 12"]

    enforcing = Enum.map_join(rows, "\n", &Enum.at(&1, 1))

    missing_gates =
      for file <- @phase_186_gate_files,
          not String.contains?(enforcing, file),
          do: "the ledger is missing the Phase 186 gate enforced by #{file}"

    budget_line =
      if section =~ "Budget used: #{length(rows)} of 12.",
        do: [],
        else: ["the budget line must read: Budget used: #{length(rows)} of 12."]

    count_errors ++ Enum.flat_map(rows, &ledger_row_errors/1) ++ missing_gates ++ budget_line
  end

  defp ledger_row_errors([gate, enforced_by, runs_in, trigger, churn]) do
    empty_cells =
      for {label, cell} <- [gate: gate, runs_in: runs_in, trigger: trigger, churn: churn],
          cell == "",
          do: "ledger row #{inspect(gate)} has an empty #{label} cell"

    file_errors =
      case Regex.run(~r/`([^`]+)`/, enforced_by) do
        [_, file] ->
          if File.exists?(file),
            do: [],
            else: ["ledger row #{inspect(gate)} names #{file}, which does not exist"]

        nil ->
          ["ledger row #{inspect(gate)} must name its enforcing file in backticks"]
      end

    empty_cells ++ file_errors
  end

  defp ledger_row_errors(row), do: ["a ledger row must have five cells: #{inspect(row)}"]

  defp classifier_tmp_dir do
    dir = Path.join(System.tmp_dir!(), "ci01-classifier-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf(dir) end)
    dir
  end

  # Writes a NUL-separated planted diff and runs the real classifier script over it.
  defp classify_paths(paths, event, script \\ @classifier_script) do
    dir = classifier_tmp_dir()
    paths_file = Path.join(dir, "paths")
    File.write!(paths_file, Enum.map_join(paths, "", &(&1 <> <<0>>)))
    run_classifier_file(paths_file, event, dir, script)
  end

  defp run_classifier_file(paths_file, event, dir, script \\ @classifier_script) do
    output_file = Path.join(dir, "github_output")
    File.write!(output_file, "")

    {log, status} =
      System.cmd("node", [script, "--paths-file", paths_file, "--output", output_file],
        env: [{"GITHUB_EVENT_NAME", event}, {"GITHUB_BASE_REF", "main"}],
        stderr_to_stdout: true
      )

    assert status == 0, "classifier exited #{status} instead of failing open: #{log}"
    File.read!(output_file)
  end

  defp assert_skips!(output, label \\ "planted diff") do
    assert String.starts_with?(output, "run=false\n"),
           "#{label}: expected run=false, got #{inspect(output)}"
  end

  defp assert_runs!(output, label \\ "planted diff") do
    assert String.starts_with?(output, "run=true\n"),
           "#{label}: expected run=true, got #{inspect(output)}"
  end

  # A function, not a module attribute: Elixir 1.19 on OTP 28 cannot store a compiled regex in one.
  # 40 lowercase hex characters, then a comment of `# v7` with optional `.digits` groups, to end of line.
  defp upload_artifact_pin_pattern do
    ~r|uses: actions/upload-artifact@[0-9a-f]{40} # v7(\.[0-9]+)*$|m
  end

  defp assert_upload_artifact_pin!(text) do
    refs =
      text
      |> String.split("\n")
      |> Enum.filter(&String.contains?(&1, "uses: actions/upload-artifact@"))

    assert refs != [], "expected at least one actions/upload-artifact reference"

    Enum.each(refs, fn ref ->
      assert Regex.match?(upload_artifact_pin_pattern(), ref),
             "expected actions/upload-artifact pinned to 40 lowercase hex with a `# v7` comment; " <>
               "found #{String.trim(ref)}"
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

  # The one `grep -qE '<pattern>'` the ops-ui-path job greps changed paths with.
  defp ops_ui_path_pattern(path_job) do
    case Regex.scan(~r/grep -qE '([^']+)'/, path_job, capture: :all_but_first) do
      [[pattern]] -> pattern
      other -> flunk("expected one grep -qE pattern in ops-ui-path, found #{length(other)}")
    end
  end

  # The paths the compiled pattern does not match.
  defp ops_ui_path_misses(regex, paths), do: Enum.reject(paths, &Regex.match?(regex, &1))

  defp workflow_named_step_block(job_block, step_name) do
    workflow_step_block(job_block, "\n      - name: #{step_name}\n")
  end

  defp fetch_step!(job, name) do
    marker = "\n      - name: #{name}\n"

    assert String.contains?(job, marker),
           "repository-contracts has no step named #{inspect(name)}"

    workflow_step_block(job, marker)
  end

  # CI-02: the Node half starts in the background, the Mix half runs in the foreground, and a last
  # step waits for the Node half and fails the job on its status, its TAP summary or its absence.
  # Raises ExUnit.AssertionError for any job that drops, serializes or ignores either half.
  defp assert_repository_contracts_concurrent!(ci) do
    job = workflow_job_block(ci, "repository-contracts")
    start = fetch_step!(job, @browser_start_step)
    wait = fetch_step!(job, @browser_wait_step)

    assert String.contains?(job, @contract_run_line),
           "the Mix half (`mix verify.repository_contracts`) is missing from repository-contracts"

    # Order: the Node half is already running when the Mix half starts, and is awaited after it.
    {install_at, _} = :binary.match(job, "- name: #{@browser_install_step}\n")
    {start_at, _} = :binary.match(job, "- name: #{@browser_start_step}\n")
    {mix_at, _} = :binary.match(job, @contract_run_line)
    {wait_at, _} = :binary.match(job, "- name: #{@browser_wait_step}\n")

    assert install_at < start_at and start_at < mix_at and mix_at < wait_at,
           "expected install, background start, mix verify.repository_contracts, then wait"

    # Nothing in the job may soft-fail: either half failing must fail the required check.
    refute job =~ "continue-on-error", "repository-contracts must not soft-fail any step"
    refute wait =~ "|| true", "the wait step must not swallow a failure"

    # Start: gated like the install, runs the five counted test files, records the exit status of
    # `node --test` itself (not of tee), and detaches from the step's stdin, stdout and stderr.
    assert start =~ @step_fail_open_if
    assert start =~ "node --test --test-reporter=tap"

    for test_file <- @browser_test_files do
      assert start =~ test_file, "the background run must execute #{test_file}"
    end

    assert start =~ "echo \"${PIPESTATUS[0]}\" > \"$RUNNER_TEMP/browser-behavior.status\""
    assert start =~ "> \"$RUNNER_TEMP/browser-behavior.log\" 2>&1 < /dev/null &\n"
    assert start =~ "echo \"$!\" > \"$RUNNER_TEMP/browser-behavior.pid\""

    # Wait: runs after a failed Mix half, is bounded, fails when the process vanished, fails on the
    # Node exit status, and keeps both counted TAP greps.
    assert wait =~ @mounted_fail_open_if
    assert wait =~ "        timeout-minutes: 30\n"
    assert wait =~ "kill -0 \"$pid\""
    assert wait =~ "stopped without reporting a result"
    assert wait =~ "never started"
    assert wait =~ "\n          test \"$status\" = 0\n"
    assert wait =~ "grep -Eq '^# tests [1-9][0-9]*$' \"$RUNNER_TEMP/browser-behavior.tap\""
    assert wait =~ "grep -Eq '^# fail 0$' \"$RUNNER_TEMP/browser-behavior.tap\""
    :ok
  end

  # A scratch RUNNER_TEMP and workspace with stub `node` and `sleep` executables on PATH. The stub
  # node prints a TAP summary from STUB_TESTS and STUB_FAILS and exits with STUB_EXIT.
  defp browser_halves_fixture do
    root =
      Path.join(
        System.tmp_dir!(),
        "scrypath-browser-halves-#{System.unique_integer([:positive])}"
      )

    bin = Path.join(root, "bin")
    runner_temp = Path.join(root, "runner_temp")
    work = Path.join(root, "work")
    for dir <- [bin, runner_temp, work], do: File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf(root) end)

    stub = fn name, body ->
      path = Path.join(bin, name)
      File.write!(path, "#!/bin/sh\n" <> body)
      File.chmod!(path, 0o755)
    end

    stub.(
      "node",
      "printf 'TAP version 13\\n'\n" <>
        "/bin/sleep \"${STUB_NODE_SLEEP:-0}\"\n" <>
        "printf '# tests %s\\n# fail %s\\n' \"${STUB_TESTS:-5}\" \"${STUB_FAILS:-0}\"\n" <>
        "exit \"${STUB_EXIT:-0}\"\n"
    )

    stub.("sleep", "exec /bin/sleep 0.1\n")

    %{
      root: root,
      bin: bin,
      runner_temp: runner_temp,
      work: work,
      status: Path.join(runner_temp, "browser-behavior.status"),
      pid: Path.join(runner_temp, "browser-behavior.pid")
    }
  end

  defp run_browser_script(script, fixture, stub_env) do
    env =
      [
        {"PATH", fixture.bin <> ":" <> System.get_env("PATH", "")},
        {"RUNNER_TEMP", fixture.runner_temp}
      ] ++ Enum.map(stub_env, fn {key, value} -> {to_string(key), value} end)

    System.cmd("bash", ["-e", "-c", script], cd: fixture.work, env: env, stderr_to_stdout: true)
  end

  # The `run: |` script of a step block, dedented, as bash would receive it.
  defp workflow_step_run_script(step_block) do
    [_before, script] = String.split(step_block, "\n        run: |\n", parts: 2)

    script
    |> String.split("\n")
    |> Enum.map_join("\n", &String.replace_prefix(&1, "          ", ""))
  end

  # Runs a "Select browser" script in a scratch workspace whose scripts/check.mjs holds `check_source`.
  # `google-chrome`, `node` (the launch probe) and `npx` are stubs; the stubs record what was called.
  defp run_website_browser_selection(script, check_source) do
    root =
      Path.join(
        System.tmp_dir!(),
        "scrypath-select-browser-#{System.unique_integer([:positive])}"
      )

    bin = Path.join(root, "bin")
    work = Path.join([root, "work", "scripts"])
    github_env = Path.join(root, "github_env")
    npx_log = Path.join(root, "npx.log")

    File.mkdir_p!(bin)
    File.mkdir_p!(work)
    File.write!(Path.join(work, "check.mjs"), check_source)
    File.write!(github_env, "")

    stub = fn name, body ->
      path = Path.join(bin, name)
      File.write!(path, "#!/bin/sh\n" <> body)
      File.chmod!(path, 0o755)
    end

    stub.("google-chrome", "echo 'Google Chrome 999.0.0.0'\n")
    stub.("node", "exit 0\n")
    stub.("npx", "echo \"$@\" >> '#{npx_log}'\n")

    try do
      {_output, 0} =
        System.cmd("bash", ["-e", "-o", "pipefail", "-c", script],
          cd: Path.join(root, "work"),
          env: [{"PATH", bin <> ":" <> System.get_env("PATH", "")}, {"GITHUB_ENV", github_env}],
          stderr_to_stdout: true
        )

      %{
        github_env: File.read!(github_env),
        npx_calls: if(File.exists?(npx_log), do: File.read!(npx_log), else: "")
      }
    after
      File.rm_rf!(root)
    end
  end

  defp workflow_step_with_uses_block(job_block, action) do
    workflow_step_block(job_block, "\n      - uses: #{action}\n")
  end

  defp workflow_step_block(job_block, marker) do
    {start_idx, marker_len} = :binary.match(job_block, marker)

    rest =
      binary_part(
        job_block,
        start_idx + marker_len,
        byte_size(job_block) - start_idx - marker_len
      )

    case :binary.match(rest, "\n      - ") do
      {next_idx, _} -> binary_part(rest, 0, next_idx)
      :nomatch -> rest
    end
  end

  # The paths listed under one trigger of website.yml, in order.
  defp website_trigger_paths(yml, trigger) do
    [_before, rest] = String.split(yml, "\n  #{trigger}:\n", parts: 2)

    block =
      case Regex.run(~r/\n  [a-z_]+:\n|\n[a-z]+:\n/, rest, return: :index) do
        [{idx, _}] -> binary_part(rest, 0, idx)
        nil -> rest
      end

    ~r/^      - '([^']+)'$/m |> Regex.scan(block) |> Enum.map(fn [_match, path] -> path end)
  end

  # SITE-04 / SITE-05: the deploy safety net around the website. Every planted mutation in the test
  # above has to trip one of these assertions.
  defp assert_website_safety_net!(yml) do
    build = workflow_job_block(yml, "build-and-check")
    deploy = workflow_job_block(yml, "deploy")

    for trigger <- ["pull_request", "push"] do
      paths = website_trigger_paths(yml, trigger)

      assert "brand/**" in paths,
             "website.yml #{trigger} paths must list brand/** so a brand change rebuilds the site, got #{inspect(paths)}"

      assert "website/**" in paths
    end

    assert yml =~ ~r/\n  workflow_dispatch:\n    inputs:\n      ref:\n/,
           "website.yml needs workflow_dispatch with a ref input (the rollback)"

    # The ref input reaches a checkout `ref:` and nothing else, so it can never become shell text.
    ref_lines = yml |> String.split("\n") |> Enum.filter(&String.contains?(&1, "inputs.ref"))

    assert length(ref_lines) == 2,
           "inputs.ref must appear exactly twice (one checkout per job), got #{inspect(ref_lines)}"

    assert Enum.all?(ref_lines, &(String.trim(&1) == "ref: ${{ inputs.ref }}")),
           "inputs.ref may only be used as a checkout ref, got #{inspect(ref_lines)}"

    assert build =~ "timeout-minutes: 10"

    assert deploy =~ "timeout-minutes: 15",
           "the deploy job needs a timeout: the smoke talks to a remote host, and the default is 360 minutes"

    # Only a superseded pull_request run is cancelled. A push to main must never cut off a deploy that
    # is already running, and a rollback dispatch (which also runs on main) must not share a group
    # with pushes, or the next push would cancel it.
    assert yml =~
             "concurrency:\n  group: website-${{ github.workflow }}-${{ github.event_name == 'workflow_dispatch' && 'rollback' || github.ref }}\n  cancel-in-progress: ${{ github.event_name == 'pull_request' }}",
           "the workflow-level group cancels only superseded pull_request runs and keys a rollback separately"

    refute yml =~ ~r/^  cancel-in-progress: true/m,
           "a workflow-level cancel-in-progress: true would cancel a deploy that is already running"

    # Deployment is restricted to main by the job's own condition, not by a repository setting the
    # job never names: a dispatch from a branch with an edited copy of this file must not publish.
    assert deploy =~ @website_deploy_if,
           "the deploy job must run only for a push or dispatch on refs/heads/main"

    assert deploy =~
             "concurrency:\n      group: website-pages-deploy\n      cancel-in-progress: false",
           "the deploy job needs its own non-cancelling concurrency group"

    refute deploy =~ "cancel-in-progress: true"
    refute deploy =~ "environment:"

    assert workflow_named_step_block(deploy, "Deploy to GitHub Pages") =~ "id: deployment"

    smoke = workflow_named_step_block(deploy, "Smoke test the deployed site")
    assert smoke =~ "SCRYPATH_SMOKE_URL: ${{ steps.deployment.outputs.page_url }}"
    assert smoke =~ "node website/scripts/smoke.mjs"

    assert smoke =~ "curl -fsSI",
           "a rollback to a ref without the smoke script needs the soft check"

    assert smoke =~ "assets/styles.css"

    assert {deploy_idx, _} = :binary.match(deploy, "name: Deploy to GitHub Pages")
    assert {smoke_idx, _} = :binary.match(deploy, "name: Smoke test the deployed site")
    assert deploy_idx < smoke_idx

    # The runner's Chrome is only used when the checked-out ref's check script can use it (it reads
    # SCRYPATH_BROWSER_CHANNEL) and a probe launches it; the known-good install is the fallback after
    # that. Without the first condition a rollback to a ref whose check.mjs predates the channel
    # support skips the install and then cannot launch any browser.
    assert build =~ "google-chrome --version"
    assert build =~ "SCRYPATH_BROWSER_CHANNEL=chrome"

    select = workflow_named_step_block(build, @website_select_browser_step)

    assert select =~ @website_channel_guard,
           "the browser selection must take the runner Chrome only when the checked-out scripts/check.mjs supports SCRYPATH_BROWSER_CHANNEL"

    {guard_idx, _} = :binary.match(select, @website_channel_guard)
    assert {chrome_idx, _} = :binary.match(select, "google-chrome --version")
    assert guard_idx < chrome_idx, "the channel-support guard must come before the Chrome probe"

    assert {probe_idx, _} = :binary.match(build, "channel: 'chrome'")
    assert {install_idx, _} = :binary.match(build, "npx playwright install --with-deps chromium")
    assert probe_idx < install_idx

    refute build =~ "pages: write"
    refute build =~ "id-token: write"
  end

  defp assert_action_pin!(workflow, action, sha, version) do
    refs =
      workflow
      |> String.split("\n")
      |> Enum.filter(&String.contains?(&1, "uses: #{action}@"))

    assert refs != [], "expected at least one #{action} reference"

    Enum.each(refs, fn ref ->
      assert String.contains?(ref, "uses: #{action}@#{sha} # #{version}"),
             "expected #{action} to use #{sha} with comment #{version}; found #{String.trim(ref)}"
    end)
  end
end
