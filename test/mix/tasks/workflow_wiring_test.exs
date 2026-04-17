defmodule Mix.Tasks.Verify.WorkflowWiringTest do
  use ExUnit.Case, async: true

  @ci_yml ".github/workflows/ci.yml"
  @publish_hex_yml ".github/workflows/publish-hex.yml"
  @release_please_yml ".github/workflows/release-please.yml"
  @verify_published_yml ".github/workflows/verify-published-release.yml"

  describe "INFRA-01 D-14: workspace_clean gate on all three publish paths" do
    test "ci.yml quality job runs mix verify.workspace_clean" do
      assert File.read!(@ci_yml) =~ "mix verify.workspace_clean"
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
    test "verify.workspace_clean is registered as :test" do
      envs = Scrypath.MixProject.cli()[:preferred_envs]
      assert envs[:"verify.workspace_clean"] == :test
    end

    test "verify.release_parity is registered as :test" do
      envs = Scrypath.MixProject.cli()[:preferred_envs]
      assert envs[:"verify.release_parity"] == :test
    end
  end
end
