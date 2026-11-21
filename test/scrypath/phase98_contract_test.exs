defmodule Scrypath.Phase98ContractTest do
  use ExUnit.Case, async: true

  alias Scrypath.Release.ShippedDocs

  @support_guide File.read!("guides/support-and-compatibility.md")
  @contributing File.read!("CONTRIBUTING.md")
  @intake_guide File.read!("guides/outside-adopter-intake.md")
  @evidence_template File.read!(".github/ISSUE_TEMPLATE/outside-adopter-evidence.md")

  test "proof boundary discoverability and live prerequisites stay explicit" do
    # The README half is retired: the shipped-docs invariant
    # (test/release/shipped_docs_contract_test.exs) forbids an unqualified README mention, and the
    # CONTRIBUTING half below stays. The support guide must name the task with the
    # source-checkout qualifier (stronger than the old substring); the live-flag and env tokens stay.
    assert_qualified_adopter_mention(@support_guide, "guides/support-and-compatibility.md")

    assert_contains_all(@support_guide, [
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
      "## Environment matrix",
      "## Scrypath ref or Hex version",
      "## Chosen path",
      "## Sync mode",
      "## Ordered commands",
      "## Expected versus actual outcome",
      "## First failure or confusion point",
      "## Supporting logs",
      "Classification"
    ])
  end

  defp assert_contains_all(content, snippets) do
    Enum.each(snippets, fn snippet ->
      assert String.contains?(content, snippet),
             "expected phase-98 contract token #{inspect(snippet)}"
    end)
  end

  # Names the adopter proof task in at least one unit, and every such unit carries the
  # source-checkout qualifier (the same unit rule the shipped-docs invariant enforces).
  defp assert_qualified_adopter_mention(text, doc) do
    units =
      text
      |> ShippedDocs.units()
      |> Enum.filter(&("verify.adopter" in ShippedDocs.mentions(&1.text, ["verify.adopter"])))

    refute units == [], "#{doc} no longer names mix verify.adopter"

    for unit <- units do
      assert ShippedDocs.unit_qualified?(unit),
             "#{doc}:#{unit.line} names mix verify.adopter without the source-checkout qualifier"
    end
  end
end
