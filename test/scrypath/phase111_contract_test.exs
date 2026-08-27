defmodule Scrypath.Phase111ContractTest do
  use ExUnit.Case, async: true
  @moduletag :phase111_contract

  @roadmap File.read!(".planning/ROADMAP.md")
  @requirements File.read!(".planning/milestones/v1.29-REQUIREMENTS.md")
  @project File.read!(".planning/PROJECT.md")
  @decision File.read!(".planning/phases/111-advisory-proof-stability-decision/111-DECISION.md")
  @contributing File.read!("CONTRIBUTING.md")
  @ci_workflow File.read!(".github/workflows/ci.yml")

  describe "phase 111 advisory decision authority" do
    test "decision file freezes advisory posture, thresholds, and non-goals" do
      assert_contains_all(@decision, [
        "Current decision: remain advisory in Phase 111",
        "Canonical stability (push to main + schedule)",
        "Merge risk (pull_request)",
        "Treat pre-change and post-change job identity evidence separately",
        "20 eligible runs",
        "10 main/schedule runs",
        "10 pull_request runs",
        "flake rate <= 5%",
        "p95 runtime <= 900 seconds",
        "artifacts classify failures without rerun",
        "owner response within 1 business day",
        "14 calendar days",
        "10 consecutive eligible pull requests",
        "no path-scoped required promotion",
        "no branch-protection change in Phase 111",
        "no new runtime APIs"
      ])
    end
  end

  describe "policy consistency across planning and contributor surfaces" do
    test "required gates stay lean and full E2E remains advisory" do
      assert_contains_all(@contributing, [
        "**`core`**",
        "**`package`**",
        "**`repository-contracts`**",
        "**`backend`**",
        "ecommerce-e2e",
        "advisory",
        "phase105-playwright.json",
        "phase105-evidence.ndjson",
        "phase105-evidence.json",
        "phase105-evidence-summary.md",
        "1 business day"
      ])

      assert ordered?(@contributing, "**`core`**", "**`package`**")
      assert ordered?(@contributing, "**`package`**", "**`repository-contracts`**")
      assert ordered?(@contributing, "**`repository-contracts`**", "**`backend`**")

      assert_contains_all(@ci_workflow, [
        "core:",
        "package:",
        "repository-contracts:",
        "backend:",
        "ecommerce-e2e:"
      ])
    end

    test "promotion language excludes immediate or path-scoped required escalation" do
      combined =
        @decision <>
          "\n" <> @contributing <> "\n" <> @roadmap <> "\n" <> @requirements <> "\n" <> @project

      assert combined =~ "no path-scoped required promotion"
      assert combined =~ "no branch-protection change in Phase 111"
      refute combined =~ "phase105-e2e is now required"
      refute combined =~ "path-scoped required check"
      refute combined =~ "immediate required promotion"
    end

    test "Phase 147 uses a separate focused check without rewriting Phase 111 history" do
      assert @decision =~ "no path-scoped required promotion"
      assert @contributing =~ "**`ecommerce-mounted`**"
      assert @contributing =~ "separate focused deterministic check"
      assert @contributing =~ "full lane remains advisory"
      assert @ci_workflow =~ "ecommerce-mounted:"
      assert @ci_workflow =~ "ecommerce-e2e:"
    end
  end

  defp assert_contains_all(content, tokens) do
    Enum.each(tokens, fn token ->
      assert content =~ token, "expected content to include #{inspect(token)}"
    end)
  end

  defp ordered?(content, first, second) do
    first_index = :binary.match(content, first)
    second_index = :binary.match(content, second)

    match?({_, _}, first_index) and match?({_, _}, second_index) and
      elem(first_index, 0) < elem(second_index, 0)
  end
end
