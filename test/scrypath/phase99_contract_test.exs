defmodule Scrypath.Phase99ContractTest do
  use ExUnit.Case, async: true
  @moduletag :phase99_contract

  @readme File.read!("README.md")
  @contributing File.read!("CONTRIBUTING.md")
  @support_guide File.read!("guides/support-and-compatibility.md")
  @intake_guide File.read!("guides/outside-adopter-intake.md")
  @example_readme File.read!("examples/phoenix_meilisearch/README.md")
  @verify_adopter_source File.read!("lib/mix/tasks/verify.adopter.ex")
  @mix_exs File.read!("mix.exs")

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
  end

  defp assert_contains_all(content, snippets) do
    Enum.each(snippets, fn snippet ->
      assert String.contains?(content, snippet),
             "expected phase-99 contract token #{inspect(snippet)}"
    end)
  end

  defp ordered?(content, first, second) do
    case {:binary.match(content, first), :binary.match(content, second)} do
      {{first_index, _}, {second_index, _}} -> first_index < second_index
      _ -> false
    end
  end
end
