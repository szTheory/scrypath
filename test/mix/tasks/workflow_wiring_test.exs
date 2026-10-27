defmodule Mix.Tasks.Verify.WorkflowWiringTest do
  use ExUnit.Case, async: true

  @ci_yml ".github/workflows/ci.yml"
  @publish_hex_yml ".github/workflows/publish-hex.yml"
  @release_please_yml ".github/workflows/release-please.yml"
  @verify_published_yml ".github/workflows/verify-published-release.yml"
  @verify_task "lib/mix/tasks/verify.ex"

  describe "HYG-02 no blanket compiler suppression" do
    test "mix.exs sets no elixirc_options" do
      refute File.read!("mix.exs") =~ "elixirc_options",
             "mix.exs must not set elixirc_options; fix warnings at the source"
    end

    test "no library source changes compiler options at runtime" do
      offenders =
        "lib/**/*.ex"
        |> Path.wildcard()
        |> Enum.filter(&(File.read!(&1) =~ "Code.put_compiler_option"))

      assert offenders == [],
             "Code.put_compiler_option found in: #{Enum.join(offenders, ", ")}"
    end

    test "no_warn_undefined is limited to Oban modules" do
      site_count =
        "lib/**/*.ex"
        |> Path.wildcard()
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

    test "repository contracts execute counted browser build, lifecycle, evidence, and target behavior tests" do
      {output, status} =
        System.cmd(
          "node",
          [
            "--test",
            "--test-reporter=tap",
            "scripts/ci/ecommerce_build.test.cjs",
            "scripts/ci/ecommerce_lifecycle.test.cjs",
            "scripts/ci/ecommerce_evidence.test.cjs",
            "scripts/ci/ecommerce_target.test.cjs"
          ],
          stderr_to_stdout: true
        )

      assert status == 0,
             "browser build and behavior tests failed with status #{status}:\n#{output}"

      assert [_, count] = Regex.run(~r/^# tests (\d+)$/m, output),
             "Node test output did not report a test count:\n#{output}"

      assert String.to_integer(count) > 0,
             "browser build and behavior tests ran zero tests:\n#{output}"

      assert output =~ ~r/^# fail 0$/m,
             "browser build and behavior tests reported failures:\n#{output}"
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
      assert core =~ "mix deps.get"
      assert core =~ "mix compile --warnings-as-errors"
      assert core =~ "mix verify.core --exclude integration --exclude docs_contract"
      assert core =~ "phase182_acceptance.cjs prepare-lock"
      assert core =~ "phase182_acceptance.cjs write-beam-proof"

      assert mounted =~ "phase182_acceptance.cjs configure-docker"
      assert mounted =~ "docker buildx inspect \"$BUILDER_ID\" --bootstrap"
      assert mounted =~ "mix verify.ecommerce_mounted"
      assert mounted =~ "phase182-cache-probe-docker-cold-${{ github.run_id }}-${{ github.run_attempt }}"

      assert full =~ "if: github.event_name == 'schedule' || github.event_name == 'workflow_dispatch'"
      assert full =~ "phase182_acceptance.cjs configure-docker"
      assert full =~ "mix verify.ecommerce_e2e"
      assert full =~ "phase182-cache-probe-docker-warm-${{ github.run_id }}-${{ github.run_attempt }}"
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
      upload = workflow_named_step_block(job, "Upload advisory E2E evidence")
      start_clock = workflow_named_step_block(job, "Record E2E job start and deadline")

      checkout =
        workflow_step_with_uses_block(
          job,
          "actions/checkout@d23441a48e516b6c34aea4fa41551a30e30af803 # v6"
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
      assert verify =~ "id: ecommerce_verify"
      assert verify =~ "run: mix verify.ecommerce_e2e"
      assert verify =~ "E2E_RUN_ID: ${{ github.run_id }}-${{ github.run_attempt }}"
      assert verify =~ "E2E_SOURCE_MODE: hosted"
      assert verify =~ "E2E_EVENT_SHA: ${{ steps.e2e_clock.outputs.E2E_EVENT_SHA }}"

      assert verify =~
               "E2E_WORKFLOW_RUN_ATTEMPT: ${{ steps.e2e_clock.outputs.E2E_WORKFLOW_RUN_ATTEMPT }}"

      assert upload =~ "id: ecommerce_upload"
      assert upload =~ "if: always()"
      assert upload =~ "test-results/docker-full/${{ github.run_id }}-${{ github.run_attempt }}"
      assert upload =~ "if-no-files-found: error"
      assert upload =~ "retention-days: 7"
      assert upload =~ "actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7"

      assert :binary.match(job, "Record E2E job start and deadline") <
               :binary.match(
                 job,
                 "actions/checkout@d23441a48e516b6c34aea4fa41551a30e30af803 # v6"
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

    test "exactly the five established required jobs remain required" do
      ci = File.read!(@ci_yml)

      required =
        Regex.scan(~r/^  ([a-z][a-z0-9-]+):\n    name: .*\(required\)$/m, ci)
        |> Enum.map(fn [_, job] -> job end)
        |> Enum.sort()

      assert required == [
               "backend",
               "core",
               "ecommerce-mounted",
               "package",
               "repository-contracts"
             ]
    end

    test "full Docker proof retains browser, light parity, and contrast without activating the judge" do
      docker_runner = File.read!("examples/scrypath_ecommerce/docker-playwright.sh")
      compose = File.read!("examples/scrypath_ecommerce/compose.e2e.yaml")
      package_json = File.read!("examples/scrypath_ecommerce/package.json")

      assert package_json =~ ~s("test:e2e": "playwright test --workers=1")
      assert package_json =~ "test:e2e:admin-light-parity"
      assert package_json =~ "test:e2e:admin-shell-wash"
      assert package_json =~ "test:e2e:ops-ui-visual-judge"
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
      assert verifier =~ ~s|"/tmp/scrypath-e2e-$run_id"|
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
      assert evidence_writer =~ "visual_judge_status"
      assert evidence_writer =~ "visual_judge_claims"
      assert evidence_writer =~ "visual_judge_required: false"
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
          "actions/checkout@d23441a48e516b6c34aea4fa41551a30e30af803 # v6"
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

      assert coverage_upload =~
               "actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7"

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

      assert closeout_upload =~
               "actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7"

      assert closeout_upload =~ "name: closeout-attestation-${{ github.sha }}"
      assert closeout_upload =~ "path: closeout-attestation.json"
      assert closeout_upload =~ "if-no-files-found: error"
      assert closeout_upload =~ "retention-days: 7"
      refute closeout_job =~ "secrets."
      refute closeout_job =~ "id-token"
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

  defp workflow_named_step_block(job_block, step_name) do
    workflow_step_block(job_block, "\n      - name: #{step_name}\n")
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
end
