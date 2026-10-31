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
        "scrypath-contrast-report-#{System.pid()}-#{System.unique_integer([:positive])}"
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

  test "raw contrast thresholds classify below at and above without rounding" do
    node = System.find_executable("node") || flunk("Node is required for UI contrast")

    script = ~S"""
    import assert from "node:assert/strict";
    import {pathToFileURL} from "node:url";
    const {passesAA, contrastRatioRaw} = await import(pathToFileURL(process.argv[1]));
    for (const [role, threshold] of [["text", 4.5], ["large", 3], ["ui", 3]]) {
      assert.equal(passesAA(threshold - 1e-12, role), false);
      assert.equal(passesAA(threshold, role), true);
      assert.equal(passesAA(threshold + 1e-12, role), true);
    }
    assert.equal(contrastRatioRaw("#000000", "#ffffff"), 21);
    assert.equal(passesAA(contrastRatioRaw("#777777", "#ffffff"), "text"), false);
    assert.throws(() => passesAA(NaN, "text"));
    assert.throws(() => passesAA(4.5, "unknown"));
    console.log("raw-thresholds-ok");
    """

    {output, status} =
      System.cmd(
        node,
        [
          "--input-type=module",
          "--eval",
          script,
          Path.join(@root, "examples/scrypath_ecommerce/contrast-checker.mjs")
        ],
        stderr_to_stdout: true
      )

    assert status == 0, output
    assert output =~ "raw-thresholds-ok"
  end

  @tag :contrast_child
  test "repository contracts reject a dark ordinary content label below 4.5" do
    root = copy_repository()

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

  @tag :contrast_child
  @tag timeout: 600_000
  test "canonical contrast rejects incomplete inputs and stale focus bindings" do
    root = copy_repository()
    css = Path.join(root, "scrypath_ops/assets/css/app.css")
    manifest = Path.join(root, "scrypath_ops/assets/css/contrast-pairs.mjs")
    checker = Path.join(root, "examples/scrypath_ecommerce/contrast-checker.mjs")
    original_css = File.read!(css)
    original_manifest = File.read!(manifest)
    original_checker = File.read!(checker)

    cases = [
      {"missing dark theme", css,
       Regex.replace(
         ~r/@plugin[^{}]*daisyui-theme[^{}]*\{[^}]*name: "dark";[^}]*\}/,
         original_css,
         ""
       )},
      {"duplicate theme", css,
       original_css <> hd(Regex.run(~r/@plugin[^{}]*daisyui-theme[^{}]*\{[^}]+\}/, original_css))},
      {"missing required token", css,
       String.replace(original_css, "--color-warning: #d9a441;", "--color-renamed: #d9a441;")},
      {"unsupported token color", css,
       String.replace(
         original_css,
         "--color-primary: #aaa0ff;",
         "--color-primary: rgb(170 160 255);"
       )},
      {"invalid pair role", manifest,
       String.replace(original_manifest, ~s(role: "text"), ~s(role: "unknown"))},
      {"text role laundering", manifest,
       String.replace(original_manifest, ~s(role: "text"), ~s(role: "decorative"))},
      {"muted alpha drift", css,
       String.replace(
         original_css,
         "var(--color-base-content) 64%, transparent",
         "var(--color-base-content) 63%, transparent"
       )},
      {"empty pairs", manifest, "export const MUTED_PAIRS = [];"},
      {"dark focus below 3", css,
       String.replace(
         original_css,
         "outline: 2px solid var(--color-primary);",
         "outline: 2px solid #333333;",
         global: false
       )},
      {"changed focus background", css,
       String.replace(original_css, "--ops-surface-2: #edf1f5;", "--ops-surface-2: #5b4ad1;")},
      {"changed shell background declaration", css,
       String.replace(
         original_css,
         "background-color: var(--ops-bg);",
         "background-color: #5b4ad1;"
       )},
      {"new unbound focus", css,
       original_css <> "\n.unbound:focus-visible { outline: 2px solid var(--color-primary); }"},
      {"broken checker launch", checker, "throw new Error('checker launch witness');"}
    ]

    for {name, file, content} <- cases do
      File.write!(css, original_css)
      File.write!(manifest, original_manifest)
      File.write!(checker, original_checker)
      File.write!(file, content)
      {output, status} = canonical(root)
      assert status != 0, "#{name} unexpectedly passed:\n#{output}"

      assert output =~ "Contrast check: FAIL" or output =~ "contrast-checker error:" or
               output =~ "checker launch witness",
             "#{name} failed outside contrast:\n#{output}"
    end
  end

  defp canonical(root) do
    System.cmd("mix", ["verify.repository_contracts"],
      cd: root,
      stderr_to_stdout: true,
      env: [{"ERL_FLAGS", "+S 4"}]
    )
  end

  defp copy_repository do
    root =
      Path.join(
        System.tmp_dir!(),
        "scrypath-contrast-#{System.pid()}-#{System.unique_integer([:positive])}"
      )

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

    root
  end
end
