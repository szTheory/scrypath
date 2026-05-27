defmodule Scrypath.Phase98ContractTest do
  use ExUnit.Case, async: true

  @readme File.read!("README.md")
  @support_guide File.read!("guides/support-and-compatibility.md")
  @contributing File.read!("CONTRIBUTING.md")
  @intake_guide File.read!("guides/outside-adopter-intake.md")
  @evidence_template File.read!("docs/templates/outside-adopter-evidence.md")

  test "proof boundary discoverability and live prerequisites stay explicit" do
    assert_contains_all(@readme, [
      "mix verify.adopter",
      "mix verify.adopter --live"
    ])

    assert_contains_all(@support_guide, [
      "mix verify.adopter",
      "mix verify.adopter --live",
      "SCRYPATH_EXAMPLE_INTEGRATION",
      "PGPORT",
      "SCRYPATH_MEILISEARCH_URL"
    ])

    assert_contains_all(@contributing, [
      "mix verify.adopter",
      "mix verify.adopter --live",
      "SCRYPATH_EXAMPLE_INTEGRATION",
      "PGPORT",
      "SCRYPATH_MEILISEARCH_URL"
    ])
  end

  test "intake classes, findings routing, and required evidence headings stay bounded" do
    assert_contains_all(@intake_guide, [
      "Class A",
      "Class B",
      "Class C",
      "Class D",
      "Bug in Scrypath",
      "Doc or Contract Gap",
      "App-Side Error",
      "Environment Failure"
    ])

    assert_contains_all(@evidence_template, [
      "## Environment Matrix",
      "## Scrypath Ref or Hex version",
      "## Chosen Proof Path",
      "## Sync Mode",
      "## Ordered Commands",
      "## Expected versus Actual Outcome",
      "## First Failure/Confusion Point",
      "## Supporting Logs",
      "Classification"
    ])
  end

  defp assert_contains_all(content, snippets) do
    Enum.each(snippets, fn snippet ->
      assert String.contains?(content, snippet),
             "expected phase-98 contract token #{inspect(snippet)}"
    end)
  end
end
