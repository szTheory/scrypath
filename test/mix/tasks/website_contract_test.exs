defmodule Mix.Tasks.WebsiteContractTest do
  use ExUnit.Case, async: false

  @moduletag timeout: 180_000
  @root Path.expand("../../..", __DIR__)
  @test_path "test/mix/tasks/website_contract_test.exs"

  # Gate 9 of the 12-gate budget in CONTRIBUTING.md: the website static contract. It is a
  # dependency-free Node test (node built-ins only, no npm ci) that builds the site into a temp
  # directory from the pinned brand files and checks the output, with planted-failure and accept
  # cases proving each check can fail. This wrapper is how it reaches CI: this file runs in `core`
  # (full suite) and in `repository-contracts` (@focused_tests in dev/mix/tasks/verify.phase99.ex),
  # so no ci.yml step exists. Every contract case must appear as a passing TAP line, so a skipped,
  # filtered or deleted case cannot pass.
  @contract_file "website/scripts/site-contract.test.mjs"

  # The planted and accept cases are what prove the guards can fail, so a deleted, skipped or
  # renamed case must fail this wrapper too. Names are read from the contract's own `test('...')`
  # calls. This floor is the number of such calls when it was written; lowering it is the second key
  # a deletion needs.
  @min_site_test_calls 78

  # Cases that exist only because of the picker or the dark theme carry the tag below in their name
  # (the SITE-02 fallback decision runs --test-name-pattern=theme-picker), so a pattern run needs a
  # floor of its own or it could pass with nothing run.
  @theme_picker_tag "theme-picker"
  @min_theme_picker_cases 6

  # A developer-only filter for a quick local run, for example WEBSITE_CONTRACT_PATTERN='^(planted|accept)'
  # while the live cases are red. The floor, uniqueness and planted/accept naming checks still run on
  # the full name list. A filtered run can never stand in for the real gate, so it flunks under CI.
  @pattern_variable "WEBSITE_CONTRACT_PATTERN"

  test "website static contract passes" do
    node = System.find_executable("node") || flunk("Node is required for the website contract")
    pattern = filter_pattern()
    names = contract_call_names()

    assert length(names) >= @min_site_test_calls,
           "#{@contract_file} has #{length(names)} test(...) calls, below the floor " <>
             "#{@min_site_test_calls}: a case was deleted or renamed. If that was intended, " <>
             "lower @min_site_test_calls in #{@test_path}."

    assert length(names) == length(Enum.uniq(names)), "website contract case names must be unique"
    assert Enum.any?(names, &String.starts_with?(&1, "planted")), "no planted case found"
    assert Enum.any?(names, &String.starts_with?(&1, "accept")), "no accept case found"

    for name <- names do
      assert Regex.match?(~r/^(live|planted|accept) /, name),
             "case name must start with live, planted or accept: #{inspect(name)}"

      refute String.contains?(name, ["#", "\\"]),
             "case name must not contain # or a backslash, TAP escapes both: #{inspect(name)}"
    end

    tagged = Enum.count(names, &String.contains?(&1, @theme_picker_tag))

    assert tagged >= @min_theme_picker_cases,
           "only #{tagged} contract cases carry the #{@theme_picker_tag} tag, the floor is " <>
             "#{@min_theme_picker_cases}: --test-name-pattern=#{@theme_picker_tag} could pass with nothing run."

    pattern_args = if pattern, do: ["--test-name-pattern=#{pattern}"], else: []

    {output, status} =
      System.cmd(
        node,
        ["--test", "--test-reporter=tap"] ++ pattern_args ++ [Path.join(@root, @contract_file)],
        cd: @root,
        stderr_to_stdout: true
      )

    assert status == 0, output
    assert output =~ ~r/^# fail 0$/m, output

    required =
      if pattern, do: Enum.filter(names, &Regex.match?(Regex.compile!(pattern), &1)), else: names

    refute required == [], "#{@pattern_variable}=#{inspect(pattern)} matches no contract case"

    for name <- Enum.uniq(required) do
      assert output =~ ~r/^ok \d+ - #{Regex.escape(name)}$/m,
             "the website contract did not report #{inspect(name)} as passing:\n#{output}"
    end
  end

  defp filter_pattern do
    case System.get_env(@pattern_variable) do
      value when value in [nil, ""] ->
        nil

      value ->
        if System.get_env("CI") not in [nil, ""] do
          flunk(
            "#{@pattern_variable} is set under CI: a filtered run can never stand in for the gate. " <>
              "Unset it."
          )
        end

        value
    end
  end

  defp contract_call_names do
    ~r/^test\((['"])((?:(?!\1)[^\\\n]|\\.)+)\1,/m
    |> Regex.scan(File.read!(Path.join(@root, @contract_file)))
    |> Enum.map(fn [_match, _quote, name] -> name end)
  end
end
