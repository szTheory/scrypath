defmodule Mix.Tasks.UiContrastContractTest do
  use ExUnit.Case, async: false

  alias Scrypath.TestSupport.UiTokens

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
    const {passesAA, contrastRatioRaw} = await import(pathToFileURL(process.argv[2]));
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
          "ui-threshold-test",
          Path.join(@root, "examples/scrypath_ecommerce/contrast-checker.mjs")
        ],
        stderr_to_stdout: true
      )

    assert status == 0, output
    assert output =~ "raw-thresholds-ok"
    refute output =~ "Contrast check:"
  end

  # Gate 2 of the v1.46 gate budget: token-map parity plus the retired-identity
  # deny-list, one mechanism in one Node test. This wrapper is how it reaches CI:
  # this file runs in `core` (full suite) and in `repository-contracts`
  # (@focused_tests in dev/mix/tasks/verify.phase99.ex), so no ci.yml step exists.
  # Every live test name must appear as a passing TAP line, so an empty or
  # silently skipped run cannot pass.
  @token_test_names [
    "live token map parity both directions",
    "live applied rows equal pinned brand hex and pending rows differ",
    "live built CSS emissions equal source theme blocks",
    "live hex allowlist holds",
    "live deny-list scan finds no unlisted retired value",
    "live allowlist entries are current and tagged",
    "deny set and new set are disjoint",
    "live ops source holds the 12 px font-size floor",
    "live ops source has no arbitrary text size",
    "live ops source has no uppercase",
    "live ops source has no infinite iteration",
    "live ops source has no size xs caller",
    "live favicon consumer scan finds nothing outside the exempt paths"
  ]

  # 186 verification IN-03: the planted and accept cases are what prove the guards can fail, so a
  # deleted, skipped or `only`-filtered case must fail this wrapper too. Their names are read from
  # the token test's own `test("...")` calls (the loop-generated planted forms have template names
  # and are not listed). The floor is the number of such calls when this check was written; lower
  # it only when a case is removed on purpose, which is the second key a deletion needs.
  @token_test_file "examples/scrypath_ecommerce/ui-tokens.test.mjs"
  @min_token_test_calls 84

  test "token map parity and retired-identity guards pass" do
    node = System.find_executable("node") || flunk("Node is required for the token test")
    names = token_test_call_names()

    assert length(names) >= @min_token_test_calls,
           "#{@token_test_file} has #{length(names)} test(\"...\") calls, below the floor " <>
             "#{@min_token_test_calls}: a case was deleted or renamed. If that was intended, " <>
             "lower @min_token_test_calls in #{@test_path}."

    assert length(names) == length(Enum.uniq(names)), "token test names must be unique"
    assert Enum.any?(names, &String.starts_with?(&1, "planted")), "no planted case found"
    assert Enum.any?(names, &String.starts_with?(&1, "accept")), "no accept case found"

    {output, status} =
      System.cmd(
        node,
        ["--test", "--test-reporter=tap", Path.join(@root, @token_test_file)],
        cd: @root,
        stderr_to_stdout: true
      )

    assert status == 0, output
    assert output =~ ~r/^# fail 0$/m, output

    for name <- Enum.uniq(@token_test_names ++ names) do
      assert output =~ ~r/^ok \d+ - #{Regex.escape(name)}$/m,
             "the token test did not report #{inspect(name)} as passing:\n#{output}"
    end
  end

  defp token_test_call_names do
    ~r/^test\("((?:[^"\\]|\\.)+)",/m
    |> Regex.scan(File.read!(Path.join(@root, @token_test_file)))
    |> Enum.map(fn [_match, name] -> name end)
  end

  @tag :contrast_child
  test "repository contracts reject a dark ordinary content label below 4.5" do
    root = copy_repository()

    css = Path.join(root, "scrypath_ops/assets/css/app.css")
    original = File.read!(css)

    # Give the dark secondary content label the same color as its own fill: a
    # contrast ratio of 1, below 4.5 whatever the palette is. Read from the live
    # dark block so a recolor does not change what this case guards.
    secondary_fill = UiTokens.theme_value!(original, "dark", "--color-secondary")

    mutated =
      UiTokens.replace_theme_value!(
        original,
        "dark",
        "--color-secondary-content",
        secondary_fill
      )

    refute mutated == original
    File.write!(css, mutated)

    {output, status} =
      System.cmd("mix", ["verify.repository_contracts"],
        cd: root,
        stderr_to_stdout: true,
        env: [{"ERL_FLAGS", "+S 4"}, {"GITHUB_EVENT_NAME", nil}]
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

    dark_theme_match =
      Regex.run(
        ~r/@plugin "\.\.\/vendor\/daisyui-theme" \{\s*name: "dark";[\s\S]*?\n\}/,
        original_css
      )

    assert dark_theme_match,
           "maintained CSS has one dark theme block for the quoted-decoy witness"

    quoted_dark_theme = dark_theme_match |> hd() |> String.replace(~r/\s+/, " ")

    # Mutations come from live tokens, never from a pinned old color. The light
    # primary is a convenient contrast-breaking color: it is a fill, not a surface.
    live_dark_primary = UiTokens.theme_value!(original_css, "dark", "--color-primary")
    live_light_primary = UiTokens.theme_value!(original_css, "light", "--color-primary")
    live_dark_muted = UiTokens.theme_value!(original_css, "dark", "--ops-text-muted")

    quoted_theme_decoy =
      String.replace(original_css, hd(dark_theme_match), "", global: false) <>
        "\n.quoted-theme-decoy::before { content: '#{quoted_dark_theme}'; }\n"

    without_bindings =
      original_manifest
      |> String.replace(
        ~r/export const FOCUS_BINDINGS = \[[\s\S]*?\n\];/,
        "export const FOCUS_BINDINGS = [];"
      )
      |> String.replace(
        ~r/export const SURFACE_BINDINGS = \[[\s\S]*?\n\];/,
        "export const SURFACE_BINDINGS = [];"
      )

    cases = [
      {"missing dark theme", css,
       Regex.replace(
         ~r/@plugin[^{}]*daisyui-theme[^{}]*\{[^}]*name: "dark";[^}]*\}/,
         original_css,
         ""
       )},
      {"quoted dark theme decoy", css, quoted_theme_decoy},
      {"duplicate theme", css,
       original_css <> hd(Regex.run(~r/@plugin[^{}]*daisyui-theme[^{}]*\{[^}]+\}/, original_css))},
      {"missing required token", css,
       String.replace(original_css, "--color-warning:", "--color-renamed:")},
      {"unsupported token color", css,
       UiTokens.replace_theme_value!(
         original_css,
         "dark",
         "--color-primary",
         UiTokens.rgb_function(live_dark_primary)
       )},
      # The muted-alpha manifest (and its per-entry text roles) is retired, so these two attack the
      # brand pair matrix that replaced it: a text role dropped from the matrix leaves fewer than the
      # 56 pairs the check counts, and a lowered floor would let a weak pair pass as text.
      {"text role dropped from the matrix", manifest,
       String.replace(original_manifest, ~s(      "ops-text-muted",\n), "", global: false)},
      {"text floor lowered", manifest,
       String.replace(original_manifest, "text: {\n    min: 4.5,", "text: {\n    min: 1.0,",
         global: false
       )},
      # --ops-text-muted is an opaque brand hex (Phase 187). Drift it from its live dark value,
      # never from a pinned old mix, so the opaque-token guard has to catch the change.
      {"muted token drift", css,
       UiTokens.replace_theme_value!(
         original_css,
         "dark",
         "--ops-text-muted",
         UiTokens.bump_hex(live_dark_muted)
       )},
      # A manifest that exports empty focus and surface bindings (every other export intact) must be
      # refused rather than treated as "nothing to check".
      {"manifest without bindings", manifest, without_bindings},
      # Text never uses alpha (N-07) and no primary or status tint returns (N-12): the retired muted
      # manifest used to catch the first, these two planted declarations prove the bans stand alone.
      {"alpha text declaration", css,
       original_css <>
         "\n.planted { color: color-mix(in oklch, var(--color-base-content) 50%, transparent); }\n"},
      {"retired color tint", css,
       original_css <>
         "\n.planted { background: color-mix(in oklch, var(--color-primary) 14%, transparent); }\n"},
      {"dark focus below 3", css,
       String.replace(
         original_css,
         "outline: 2px solid var(--color-primary);",
         "outline: 2px solid #333333;",
         global: false
       )},
      # --ops-selection is a surviving bound surface (the selected filter chip fill). Painting it the
      # primary color puts the focus ring on its own color, so the focus-on-surface pair fails.
      {"changed focus background", css,
       UiTokens.replace_theme_value!(
         original_css,
         "light",
         "--ops-selection",
         live_light_primary
       )},
      {"changed shell background declaration", css,
       String.replace(
         original_css,
         "background-color: var(--ops-bg);",
         "background-color: #{live_light_primary};"
       )},
      {"new unbound focus", css,
       original_css <> "\n.unbound:focus-visible { outline: 2px solid var(--color-primary); }"},
      {"broken checker launch", checker, "throw new Error('checker launch witness');"}
    ]

    originals = %{css => original_css, manifest => original_manifest, checker => original_checker}

    # The reason each retired-manifest replacement must fail for, so a case cannot pass by breaking
    # something unrelated: the checker's own message names the ban or guard that fired.
    reasons = %{
      "text role dropped from the matrix" => "N-03 expected 56 text pairs",
      "text floor lowered" => "N-03 text threshold is 1 in the pair matrix",
      "manifest without bindings" => "Required focus/surface bindings are empty",
      "alpha text declaration" => "N-07 text color at app.css line",
      "retired color tint" => "N-12 color-mix at app.css line"
    }

    for {name, file, content} <- cases do
      # A mutation that changes nothing would "fail" nothing: it means its target string is gone.
      refute content == Map.fetch!(originals, file), "#{name} did not change #{file}"

      File.write!(css, original_css)
      File.write!(manifest, original_manifest)
      File.write!(checker, original_checker)
      File.write!(file, content)
      {output, status} = canonical(root)
      assert status != 0, "#{name} unexpectedly passed:\n#{output}"

      assert output =~ "Contrast check: FAIL" or output =~ "contrast-checker error:" or
               output =~ "checker launch witness",
             "#{name} failed outside contrast:\n#{output}"

      if reason = reasons[name] do
        assert output =~ reason, "#{name} did not fail for #{inspect(reason)}:\n#{output}"
      end
    end
  end

  defp canonical(root) do
    System.cmd("mix", ["verify.repository_contracts"],
      cd: root,
      stderr_to_stdout: true,
      env: [{"ERL_FLAGS", "+S 4"}, {"GITHUB_EVENT_NAME", nil}]
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

    {remote_output, remote_status} =
      System.cmd(
        "git",
        ["remote", "set-url", "origin", "https://github.com/szTheory/scrypath.git"],
        cd: root,
        stderr_to_stdout: true
      )

    assert remote_status == 0, remote_output

    for path <- [
          @test_path,
          "test/mix/tasks/ui_literal_contract_test.exs",
          "dev/mix/tasks/verify.phase99.ex",
          "examples/scrypath_ecommerce/contrast-checker.mjs",
          "scrypath_ops/assets/css/contrast-pairs.mjs"
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
