defmodule Mix.Tasks.UiContrastContractTest do
  use ExUnit.Case, async: false

  @moduletag timeout: 300_000
  @root Path.expand("../../..", __DIR__)
  @test_path "test/mix/tasks/ui_contrast_contract_test.exs"

  test "live text and focus contrast passes AA" do
    node = System.find_executable("node") || flunk("Node is required for UI contrast")

    report =
      Path.join(
        System.tmp_dir!(),
        "scrypath-contrast-report-#{System.unique_integer([:positive])}"
      )

    on_exit(fn -> File.rm_rf!(report) end)

    runner = ~S"""
    const {spawnSync} = require("node:child_process");
    const result = spawnSync(process.execPath, [process.argv[1]], {
      encoding: "utf8", timeout: 20000, maxBuffer: 2 * 1024 * 1024
    });
    process.stdout.write(result.stdout || "");
    process.stderr.write(result.stderr || "");
    if (result.error) console.error(result.error.message);
    process.exit(Number.isInteger(result.status) ? result.status : 2);
    """

    {output, status} =
      System.cmd(
        node,
        ["-e", runner, Path.join(@root, "examples/scrypath_ecommerce/contrast-checker.mjs")],
        cd: @root,
        stderr_to_stdout: true,
        env: [{"CONTRAST_REPORT_DIR", report}]
      )

    assert status == 0, output
    assert output =~ "Contrast check: PASS"
  end

  @tag :contrast_child
  test "repository contracts reject a dark ordinary content label below 4.5" do
    root = Path.join(System.tmp_dir!(), "scrypath-contrast-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(root) end)

    {output, status} =
      System.cmd("git", ["clone", "--quiet", "--shared", @root, root], stderr_to_stdout: true)

    assert status == 0, output

    for path <- [
          @test_path,
          "dev/mix/tasks/verify.phase99.ex",
          "examples/scrypath_ecommerce/contrast-checker.mjs",
          "scrypath_ops/assets/css/contrast-pairs.mjs",
          ".planning/phases/185-executable-ui-quality-foundations/185-08-PLAN.md",
          ".planning/phases/185-executable-ui-quality-foundations/185-09-PLAN.md"
        ] do
      File.cp!(Path.join(@root, path), Path.join(root, path))
    end

    for path <- ["deps", "_build"] do
      File.cp_r!(Path.join(@root, path), Path.join(root, path))
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

    css = Path.join(root, "scrypath_ops/assets/css/app.css")
    original = File.read!(css)

    mutated =
      String.replace(
        original,
        "--color-secondary-content: #0c0f14;",
        "--color-secondary-content: #333333;",
        global: false
      )

    refute mutated == original
    File.write!(css, mutated)

    {output, status} =
      System.cmd("mix", ["verify.repository_contracts"],
        cd: root,
        stderr_to_stdout: true,
        env: [{"ERL_FLAGS", "+S 4"}]
      )

    assert status != 0, "mutated repository command unexpectedly succeeded:\n#{output}"
    assert output =~ "secondary-content"
    assert output =~ "dark"
  end
end
