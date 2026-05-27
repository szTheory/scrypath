defmodule Scrypath.Phase99ContractTest do
  use ExUnit.Case, async: true
  @moduletag :phase99_contract

  @readme File.read!("README.md")
  @contributing File.read!("CONTRIBUTING.md")
  @support_guide File.read!("guides/support-and-compatibility.md")
  @intake_guide File.read!("guides/outside-adopter-intake.md")
  @evidence_template File.read!("docs/templates/outside-adopter-evidence.md")
  @example_readme File.read!("examples/phoenix_meilisearch/README.md")
  @verify_adopter_source File.read!("lib/mix/tasks/verify.adopter.ex")
  @mix_exs File.read!("mix.exs")
  @ci_workflow File.read!(".github/workflows/ci.yml")
  @compatibility_floor_elixir "1.17.3"
  @compatibility_floor_otp "26.2.5"
  @compatibility_head_elixir "1.19.0"
  @compatibility_head_otp "28.1"

  describe "TEST-01 docs contract anchors" do
    test "high-risk surfaces keep canonical install/support/proof wayfinding tokens" do
      assert_contains_all(@readme, [
        "guides/support-and-compatibility.md",
        "guides/outside-adopter-intake.md",
        "mix verify.adopter",
        "mix verify.adopter --live"
      ])

      assert_contains_all(@contributing, [
        "guides/support-and-compatibility.md",
        "guides/outside-adopter-intake.md",
        "mix verify.adopter",
        "mix verify.adopter --live"
      ])

      assert_contains_all(@support_guide, [
        "mix verify.adopter",
        "mix verify.adopter --live",
        "examples/phoenix_meilisearch/README.md"
      ])

      assert_contains_all(@intake_guide, [
        "README.md",
        "guides/support-and-compatibility.md",
        "mix verify.adopter",
        "mix verify.adopter --live"
      ])

      assert String.contains?(@example_readme, "mix verify.adopter --live")
    end
  end

  describe "TEST-02 proof boundary parity" do
    test "fast-vs-live proof env tokens remain explicit across root and example surfaces" do
      assert_contains_all(@contributing, [
        "SCRYPATH_EXAMPLE_INTEGRATION",
        "PGPORT",
        "SCRYPATH_MEILISEARCH_URL"
      ])

      assert_contains_all(@support_guide, [
        "SCRYPATH_EXAMPLE_INTEGRATION",
        "PGPORT",
        "SCRYPATH_MEILISEARCH_URL"
      ])

      assert_contains_all(@example_readme, [
        "SCRYPATH_EXAMPLE_INTEGRATION",
        "PGPORT",
        "SCRYPATH_MEILISEARCH_URL"
      ])
    end

    test "CI-shaped command chain stays ordered on example and maintainer runbook surfaces" do
      assert ordered?(@example_readme, "cd examples/phoenix_meilisearch", "mix deps.get")
      assert ordered?(@example_readme, "mix deps.get", "mix test")
      assert String.contains?(
               @verify_adopter_source,
               "cd examples/phoenix_meilisearch && mix deps.get && mix test"
             )
    end
  end

  describe "TEST-03 verify alias parity" do
    test "phase trust-lane aliases stay aligned across mix wiring and contributor docs" do
      assert_contains_all(@mix_exs, [
        "\"verify.phase97\": :test",
        "\"verify.phase98\": :test",
        "\"verify.phase99\": :test"
      ])

      assert_contains_all(@contributing, [
        "mix verify.phase97",
        "mix verify.phase98",
        "mix verify.phase99"
      ])
    end

    test "required-check names and phase99 gate wiring stay aligned across workflow and docs" do
      assert_contains_all(@ci_workflow, [
        "phase99-trust",
        "mix verify.phase99",
        "main-ci",
        "repo-hygiene",
        "release-truth"
      ])

      assert_contains_all(@contributing, [
        "**`main-ci`**",
        "**`repo-hygiene`**",
        "**`release-truth`**",
        "**`phase99-trust`**"
      ])

      assert ordered?(@contributing, "**`main-ci`**", "**`repo-hygiene`**")
      assert ordered?(@contributing, "**`repo-hygiene`**", "**`release-truth`**")
      assert ordered?(@contributing, "**`release-truth`**", "**`phase99-trust`**")
    end
  end

  describe "TRUTH-01 install token and evidence boundary parity" do
    test "canonical and intake surfaces keep the ~> 0.3 token and reject stale major token snippets" do
      assert_contains_all(@support_guide, [~S|{:scrypath, "~> 0.3"}|])
      assert_contains_all(@readme, [~S|{:scrypath, "~> 0.3"}|])
      assert_contains_all(@intake_guide, [~S|{:scrypath, "~> 0.3"}|])

      assert_absent_all(@readme, [~S|{:scrypath, "~> 1.0"}|])
      assert_absent_all(@support_guide, [~S|{:scrypath, "~> 1.0"}|])
      assert_absent_all(@intake_guide, [~S|{:scrypath, "~> 1.0"}|])
      assert_absent_all(@evidence_template, [~S|{:scrypath, "~> 1.0"}|])
    end

    test "intake and evidence template preserve exact package-vs-ref evidence requirements" do
      assert_contains_all(@intake_guide, [
        "exact Hex package version",
        "exact git ref/commit"
      ])

      assert_contains_all(@evidence_template, [
        "exact Hex package version",
        "exact git ref/commit"
      ])
    end
  end

  describe "TRUTH-02 release truth token parity" do
    test "canonical, entry, and intake surfaces keep release-backed and unreleased-main tokens" do
      Enum.each([@support_guide, @readme, @contributing, @intake_guide], fn surface ->
        assert_contains_all(String.downcase(surface), [
          "release-backed guidance",
          "main may contain unreleased changes"
        ])
      end)
    end

    test "entry and intake surfaces route normative policy to support authority" do
      Enum.each([@readme, @contributing, @intake_guide], fn surface ->
        assert_contains_all(surface, ["guides/support-and-compatibility.md"])
      end)
    end
  end

  defp extract_support_ci_tuples(content) do
    content
    |> lines_after("GitHub Actions CI evidence currently exercises these explicit tuples:")
    |> Enum.map(fn line ->
      Regex.run(~r/-\s*Elixir\s*`([^`]+)`\s*with OTP\s*`([^`]+)`/, line, capture: :all_but_first)
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.map(fn [elixir_version, otp_version] -> {elixir_version, otp_version} end)
    |> normalize_tuple_set()
  end

  defp extract_workflow_ci_tuples(content) do
    case Regex.run(
           ~r/\n  compatibility-truth:\n(?<lane>.*?)(?:\n  [a-z0-9][a-z0-9-]*:\n|\z)/ms,
           content,
           capture: :all_names
         ) do
      [lane] ->
        lane
        |> Regex.scan(
          ~r/-\s*elixir-version:\s*"([^"]+)"\n\s+otp-version:\s*"([^"]+)"/,
          capture: :all_but_first
        )
        |> Enum.map(fn [elixir_version, otp_version] -> {elixir_version, otp_version} end)
        |> normalize_tuple_set()

      _ ->
        []
    end
  end

  defp normalize_tuple_set(tuples) do
    tuples
    |> Enum.map(&normalize_tuple_pair/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp assert_tuple_set_parity(expected_tuples, actual_tuples, context) do
    normalized_expected = normalize_tuple_set(expected_tuples)
    normalized_actual = normalize_tuple_set(actual_tuples)

    assert normalized_expected == normalized_actual,
           "#{context} tuple mismatch\n" <>
             "expected: #{inspect(normalized_expected)}\n" <>
             "actual: #{inspect(normalized_actual)}"
  end

  defp lines_after(content, marker) do
    case String.split(content, marker, parts: 2) do
      [_, remaining] -> String.split(remaining, "\n")
      _ -> []
    end
  end

  defp normalize_tuple_pair({left, right}) when is_binary(left) and is_binary(right) do
    if String.starts_with?(right, "1.") and not String.starts_with?(left, "1.") do
      {right, left}
    else
      {left, right}
    end
  end

  defp normalize_tuple_pair([left, right]), do: normalize_tuple_pair({left, right})

  defp assert_contains_all(content, snippets) do
    Enum.each(snippets, fn snippet ->
      assert String.contains?(content, snippet),
             "expected phase-99 contract token #{inspect(snippet)}"
    end)
  end

  defp assert_absent_all(content, snippets) do
    Enum.each(snippets, fn snippet ->
      refute String.contains?(content, snippet),
             "did not expect phase-99 contract token #{inspect(snippet)}"
    end)
  end

  defp ordered?(content, first, second) do
    case {:binary.match(content, first), :binary.match(content, second)} do
      {{first_index, _}, {second_index, _}} -> first_index < second_index
      _ -> false
    end
  end
end
