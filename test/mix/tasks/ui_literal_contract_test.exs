defmodule Mix.Tasks.UiLiteralContractTest do
  use ExUnit.Case, async: false

  @moduletag timeout: 300_000
  @root Path.expand("../../..", __DIR__)

  test "production command checks this checkout against fresh trusted history" do
    node = System.find_executable("node") || flunk("Node is required for the UI literal policy")

    {output, status} =
      System.cmd(node, ["scripts/ci/ui_literal_policy.cjs"],
        cd: @root,
        stderr_to_stdout: true
      )

    assert status == 0, output
    assert output =~ "UI literal policy: PASS"
    assert output =~ "Trusted target:"
    assert output =~ "Trusted comparisons:"
    assert output =~ "Bootstrap ledger introduction:"
  end

  test "required repository-contracts lane runs the production resolver with full history" do
    ci = File.read!(Path.join(@root, ".github/workflows/ci.yml"))
    [_, tail] = String.split(ci, "\n  repository-contracts:\n", parts: 2)
    [job, _] = String.split(tail, "\n  backend:\n", parts: 2)

    assert job =~ "fetch-depth: 0"
    assert job =~ "run: node scripts/ci/ui_literal_policy.cjs"
  end

  @tag :contrast_child
  test "canonical child fails when source and candidate ledger bless a new finding" do
    node = System.find_executable("node") || flunk("Node is required for the UI literal policy")
    git = System.find_executable("git") || flunk("Git is required for UI literal history tests")

    temp =
      Path.join(
        System.tmp_dir!(),
        "scrypath-ui-literal-#{System.pid()}-#{System.unique_integer([:positive])}"
      )

    root = Path.join(temp, "repo")
    on_exit(fn -> File.rm_rf!(temp) end)
    File.mkdir_p!(temp)

    {clone_output, clone_status} =
      System.cmd(git, ["clone", "--quiet", "--shared", @root, root], stderr_to_stdout: true)

    assert clone_status == 0, clone_output

    {remote_output, remote_status} =
      System.cmd(git, ["remote", "set-url", "origin", "https://github.com/szTheory/scrypath.git"],
        cd: root,
        stderr_to_stdout: true
      )

    assert remote_status == 0, remote_output

    File.cp!(
      Path.join(@root, "test/mix/tasks/ui_literal_contract_test.exs"),
      Path.join(root, "test/mix/tasks/ui_literal_contract_test.exs")
    )

    for directory <- ["deps", "_build"] do
      File.cp_r!(Path.join(@root, directory), Path.join(root, directory))
    end

    helper = Path.join(root, "test/test_helper.exs")

    File.write!(
      helper,
      String.replace(
        File.read!(helper),
        "ExUnit.configure(exclude: exclude)",
        "ExUnit.configure(exclude: [:contrast_child | exclude])"
      )
    )

    source_path = "scrypath_ops/lib/scrypath_ops_web/components/layouts/root.html.heex"
    source_file = Path.join(root, source_path)
    source = File.read!(source_file)
    assert length(String.split(source, "</body>")) == 2

    File.write!(
      source_file,
      String.replace(source, "</body>", "<div class=\"z-60\"></div>\n  </body>", global: false)
    )

    prepare_ledger = ~S"""
    const fs = require("node:fs");
    const policy = require("./scripts/ci/ui_literal_policy.cjs");
    const findings = policy.scanTree(process.cwd());
    const counts = new Map();
    for (const {rule, path, context, value} of findings) {
      const key = JSON.stringify([rule, path, context, value]);
      counts.set(key, (counts.get(key) || 0) + 1);
    }
    const entries = [...counts].map(([key, count]) => {
      const [rule, path, context, value] = JSON.parse(key);
      return {rule, path, context, value, count};
    }).sort((a, b) => {
      const left = JSON.stringify([a.rule, a.path, a.context, a.value]);
      const right = JSON.stringify([b.rule, b.path, b.context, b.value]);
      return left < right ? -1 : left > right ? 1 : 0;
    });
    const ledger = {version: 1, bootstrap_commit: "767f368473f17fba43d7be4675c53ab65a87530c", findings: entries};
    fs.writeFileSync("scripts/ci/ui-literal-baseline.json", JSON.stringify(ledger, null, 2) + "\n");
    """

    {prepare_output, prepare_status} =
      System.cmd(node, ["-e", prepare_ledger], cd: root, stderr_to_stdout: true)

    assert prepare_status == 0, prepare_output

    for {key, value} <- [
          {"user.name", "UI literal child"},
          {"user.email", "ui-literal-child@example.invalid"}
        ] do
      {output, status} = System.cmd(git, ["config", key, value], cd: root, stderr_to_stdout: true)
      assert status == 0, output
    end

    {stage_output, stage_status} =
      System.cmd(git, ["add", source_path, "scripts/ci/ui-literal-baseline.json"],
        cd: root,
        stderr_to_stdout: true
      )

    assert stage_status == 0, stage_output

    {commit_output, commit_status} =
      System.cmd(git, ["commit", "-m", "malicious candidate blesses new literal"],
        cd: root,
        stderr_to_stdout: true
      )

    assert commit_status == 0, commit_output

    {output, status} =
      System.cmd("mix", ["verify.repository_contracts"],
        cd: root,
        stderr_to_stdout: true,
        env: [{"GITHUB_EVENT_NAME", nil}]
      )

    assert status != 0, "candidate source and ledger unexpectedly passed:\n#{output}"
    assert output =~ "candidate first-parent ledger grew or reversed"
    assert output =~ "literal-z"
  end
end
