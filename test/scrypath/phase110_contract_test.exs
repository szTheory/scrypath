defmodule Scrypath.Phase110ContractTest do
  use ExUnit.Case, async: true

  @readme File.read!("README.md")
  @contributing File.read!("CONTRIBUTING.md")
  @support_guide File.read!("guides/support-and-compatibility.md")
  @intake_guide File.read!("guides/outside-adopter-intake.md")
  @evidence_template File.read!(".github/ISSUE_TEMPLATE/outside-adopter-evidence.md")
  @operator_support File.read!("docs/operator-support.md")
  @website_docs File.read!("website/src/pages/docs.html")
  @website_operators File.read!("website/src/pages/operators.html")

  @non_owner_surfaces [
    {"README.md", @readme},
    {"CONTRIBUTING.md", @contributing},
    {"guides/outside-adopter-intake.md", @intake_guide},
    {"docs/operator-support.md", @operator_support},
    {"website/src/pages/docs.html", @website_docs},
    {"website/src/pages/operators.html", @website_operators}
  ]

  @tuple_literals ["1.17.3", "26.2.5", "1.19.0", "28.1"]

  test "support authority stays single-sourced and non-owner surfaces avoid tuple drift" do
    assert_contains_all(@support_guide, [
      "single current support and readiness authority",
      "Elixir `1.17.3` with OTP `26.2.5`",
      "Elixir `1.19.0` with OTP `28.1`",
      "outside-adopter evidence"
    ])

    Enum.each(@non_owner_surfaces, fn {path, surface} ->
      assert String.contains?(surface, "support-and-compatibility.md"),
             "expected #{path} to route to guides/support-and-compatibility.md"

      assert_absent_all(surface, @tuple_literals, path)
    end)
  end

  test "intake guide and issue template expose classification and routing vocabulary" do
    shared_tokens = [
      "Class A",
      "Class B",
      "Class C",
      "Class D",
      "Bug in Scrypath",
      "Doc or Contract Gap",
      "App-Side Error",
      "Environment Failure",
      "Needs Information"
    ]

    assert_contains_all(@intake_guide, shared_tokens)

    assert_contains_all(@intake_guide, [
      "patch-sized bugfix issue",
      "docs correction",
      "correction guidance",
      "environment fix request",
      "needs-info"
    ])

    assert_contains_all(@evidence_template, [
      "## Evidence Block (required)",
      "Path",
      "Runtime vs support matrix",
      "Reporter class guess",
      "Reporter finding guess",
      "Scrypath ref or Hex version",
      "First failing command step",
      "Logs or artifacts",
      "Classification (A-D)",
      "Finding bucket",
      "Maintainer action"
    ])
  end

  test "public evidence template warns against leaking sensitive data" do
    assert_contains_all(@evidence_template, [
      "public issue",
      "secrets",
      "tokens",
      "API keys",
      "sensitive private dumps"
    ])
  end

  test "public and operator entrypoints stay route-only for support and intake" do
    assert_contains_all(@operator_support, [
      "../guides/support-and-compatibility.md",
      "../guides/outside-adopter-intake.md"
    ])

    assert_contains_all(@website_docs, [
      "guides/support-and-compatibility.md",
      "guides/outside-adopter-intake.md"
    ])

    assert_contains_all(@website_operators, [
      "guides/support-and-compatibility.md",
      "guides/outside-adopter-intake.md"
    ])

    Enum.each(
      [
        {"docs/operator-support.md", @operator_support},
        {"website/src/pages/docs.html", @website_docs},
        {"website/src/pages/operators.html", @website_operators}
      ],
      fn {path, surface} -> assert_absent_all(surface, @tuple_literals, path) end
    )
  end

  defp assert_contains_all(content, snippets) do
    Enum.each(snippets, fn snippet ->
      assert String.contains?(content, snippet),
             "expected phase-110 contract token #{inspect(snippet)}"
    end)
  end

  defp assert_absent_all(content, snippets, path) do
    Enum.each(snippets, fn snippet ->
      refute String.contains?(content, snippet),
             "did not expect compatibility tuple token #{inspect(snippet)} in #{path}"
    end)
  end
end
