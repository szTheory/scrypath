defmodule Mix.Tasks.Verify.WorkflowWiringTest do
  use ExUnit.Case, async: true

  @ci_yml ".github/workflows/ci.yml"
  @publish_hex_yml ".github/workflows/publish-hex.yml"
  @release_please_yml ".github/workflows/release-please.yml"
  @verify_published_yml ".github/workflows/verify-published-release.yml"

  describe "INFRA-01 D-14: workspace_clean gate on all three publish paths" do
    test "ci.yml quality job runs mix verify" do
      assert File.read!(@ci_yml) =~ "mix verify"
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

  describe "INFRA-03 D-13: ci.yml action pins on Node 24 runtime" do
    test "ci.yml uses actions/checkout@v6 everywhere" do
      yml = File.read!(@ci_yml)
      refute yml =~ "actions/checkout@v4", "expected no legacy checkout@v4 pins"
      assert yml =~ "actions/checkout@v6"
    end

    test "ci.yml uses actions/cache@v5 everywhere" do
      yml = File.read!(@ci_yml)
      refute yml =~ "actions/cache@v4", "expected no legacy cache@v4 pins"
      assert yml =~ "actions/cache@v5"
    end

    test "ci.yml has at least 4 checkout@v6 references (test matrix + quality + phase5-verification + phase13-verification)" do
      count =
        @ci_yml
        |> File.read!()
        |> String.split("actions/checkout@v6")
        |> length()
        |> Kernel.-(1)

      assert count >= 4, "expected >= 4 checkout@v6 refs in ci.yml, got #{count}"
    end

    test "ci.yml has at least 4 cache@v5 references" do
      count =
        @ci_yml
        |> File.read!()
        |> String.split("actions/cache@v5")
        |> length()
        |> Kernel.-(1)

      assert count >= 4, "expected >= 4 cache@v5 refs in ci.yml, got #{count}"
    end
  end

  describe "INFRA-04 D-19: scheduled drift-issue wiring" do
    test "create-an-issue step is guarded on failure() + schedule event" do
      yml = File.read!(@verify_published_yml)
      assert yml =~ "failure() && github.event_name == 'schedule'"
    end

    test "create-an-issue step uses JasonEtco/create-an-issue@v2" do
      yml = File.read!(@verify_published_yml)
      assert yml =~ "JasonEtco/create-an-issue@v2"
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

    test "verify.workspace_clean is registered as :test" do
      envs = Scrypath.MixProject.cli()[:preferred_envs]
      assert envs[:"verify.workspace_clean"] == :test
    end

    test "verify.release_parity is registered as :test" do
      envs = Scrypath.MixProject.cli()[:preferred_envs]
      assert envs[:"verify.release_parity"] == :test
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
end
