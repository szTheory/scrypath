defmodule Scrypath.Phase108ContractTest do
  use ExUnit.Case, async: true
  @moduletag :phase108_contract

  @related_guide File.read!("guides/related-data-and-reindexing.md")
  @jtbd_gap_map File.read!("docs/jtbd-gap-map.md")
  @roadmap File.read!(".planning/ROADMAP.md")
  @requirements File.read!(".planning/REQUIREMENTS.md")
  @project File.read!(".planning/PROJECT.md")
  @contributing File.read!("CONTRIBUTING.md")
  @mix_exs File.read!("mix.exs")
  @ci_workflow File.read!(".github/workflows/ci.yml")

  describe "related-data fan-out truth" do
    test "ordinary schemas use generated fan_outs reflection while owner-only accessors stay advanced" do
      assert_contains_all(@related_guide, [
        "For ordinary schemas, declare fan-out with `use Scrypath, fan_outs:`",
        "generated `__scrypath__(:fan_outs)`",
        "Hand-written `__scrypath__/1` remains supported as a low-level escape hatch",
        "owner-only schemas that intentionally do not `use Scrypath`"
      ])

      assert_contains_all(@related_guide, [
        "durably queued",
        "document IDs",
        "records"
      ])

      assert_absent_all(@related_guide, [
        "Scrypath.FanOuts",
        "schema_fan_outs",
        "duplicate fan-out",
        "nil fan-out"
      ])
    end
  end

  describe "v1.29 closeout truth" do
    test "planning and JTBD surfaces close the repair milestone without widening scope" do
      assert_contains_all(@jtbd_gap_map, [
        "maintenance-and-evidence mode",
        "outside-adopter evidence",
        "concrete production bug"
      ])

      assert_contains_all(@project, [
        "maintenance-and-evidence mode",
        "outside-adopter evidence",
        "concrete production bug",
        "repaired generated `__scrypath__(:fan_outs)`",
        "tenant-preserving ecommerce readiness regression proof",
        "aligned roadmap/JTBD truth"
      ])

      assert_contains_all(@roadmap, [
        "✅ **Phase 108: Truth Alignment and Closeout Proof**",
        "Plans: 1/1 plans complete",
        "v1.29 Contract Repair and Proof Hardening | 106-108 | 3/3 | Complete"
      ])

      assert_contains_all(@requirements, [
        "[x] **TRUTH-01**",
        "`Scrypath.FanOuts` owner-only macro",
        "`Scrypath.schema_fan_outs/1` public helper",
        "Promote `phase105-e2e` to required CI"
      ])
    end
  end

  describe "verification posture" do
    test "phase108 is a local truth gate and phase105-e2e remains advisory" do
      assert_contains_all(@contributing, [
        "mix verify.phase108",
        "**`main-ci`**",
        "**`repo-hygiene`**",
        "**`release-truth`**",
        "**`phase99-trust`**",
        "phase105-e2e",
        "advisory"
      ])

      assert_contains_all(@mix_exs, [
        "\"verify.phase108\": :test"
      ])

      assert_contains_all(@ci_workflow, [
        "phase105-e2e",
        "playwright-report",
        "test-results"
      ])

      assert_absent_all(@ci_workflow, [
        "verify.phase108"
      ])

      assert ordered?(@contributing, "**`main-ci`**", "**`repo-hygiene`**")
      assert ordered?(@contributing, "**`repo-hygiene`**", "**`release-truth`**")
      assert ordered?(@contributing, "**`release-truth`**", "**`phase99-trust`**")
    end
  end

  defp assert_contains_all(content, tokens) do
    Enum.each(tokens, fn token ->
      assert content =~ token, "expected content to include #{inspect(token)}"
    end)
  end

  defp assert_absent_all(content, tokens) do
    Enum.each(tokens, fn token ->
      refute content =~ token, "expected content not to include #{inspect(token)}"
    end)
  end

  defp ordered?(content, first, second) do
    first_index = :binary.match(content, first)
    second_index = :binary.match(content, second)

    match?({_, _}, first_index) and match?({_, _}, second_index) and
      elem(first_index, 0) < elem(second_index, 0)
  end
end
