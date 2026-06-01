defmodule Scrypath.Phase112ContractTest do
  use ExUnit.Case, async: true

  @readme File.read!("README.md")
  @website_layout File.read!("website/src/layout.html")
  @website_index File.read!("website/src/pages/index.html")
  @website_docs File.read!("website/src/pages/docs.html")
  @website_evaluate File.read!("website/src/pages/evaluate.html")
  @website_operators File.read!("website/src/pages/operators.html")
  @scope_policy File.read!("guides/scope-and-reopen-policy.md")
  @overview File.read!("guides/overview.md")
  @support_guide File.read!("guides/support-and-compatibility.md")
  @intake_guide File.read!("guides/outside-adopter-intake.md")
  @sync_guide File.read!("guides/sync-modes-and-visibility.md")
  @operator_support File.read!("docs/operator-support.md")
  @jtbd_gap_map File.read!("docs/jtbd-gap-map.md")

  @all_surfaces [
    {"README.md", @readme},
    {"website/src/layout.html", @website_layout},
    {"website/src/pages/index.html", @website_index},
    {"website/src/pages/docs.html", @website_docs},
    {"website/src/pages/evaluate.html", @website_evaluate},
    {"website/src/pages/operators.html", @website_operators},
    {"guides/scope-and-reopen-policy.md", @scope_policy},
    {"guides/overview.md", @overview},
    {"guides/support-and-compatibility.md", @support_guide},
    {"guides/outside-adopter-intake.md", @intake_guide},
    {"guides/sync-modes-and-visibility.md", @sync_guide},
    {"docs/operator-support.md", @operator_support},
    {"docs/jtbd-gap-map.md", @jtbd_gap_map}
  ]

  @website_surfaces [
    {"website/src/layout.html", @website_layout},
    {"website/src/pages/index.html", @website_index},
    {"website/src/pages/docs.html", @website_docs},
    {"website/src/pages/evaluate.html", @website_evaluate},
    {"website/src/pages/operators.html", @website_operators}
  ]

  @misleading_tokens [
    "AI-powered",
    "AI search",
    "vector search",
    "hybrid search",
    "automatic callbacks",
    "immediately searchable"
  ]

  test "canonical claim, policy route, and three reopen triggers stay explicit" do
    assert_contains_all(@readme, [
      "Scrypath, the Ecto-native search indexing library",
      "scope-and-reopen-policy.md",
      "concrete production bug",
      "reviewed outside-adopter evidence",
      "deliberate strategic product decision"
    ])

    Enum.each([
      {"guides/scope-and-reopen-policy.md", @scope_policy},
      {"docs/operator-support.md", @operator_support},
      {"docs/jtbd-gap-map.md", @jtbd_gap_map}
    ], fn {_path, content} ->
      assert_contains_all(content, [
        "concrete production bug",
        "reviewed outside-adopter evidence",
        "deliberate strategic product decision"
      ])
    end)
  end

  test "website route-map surfaces keep canonical README, guides, examples, and package routes" do
    assert_contains_all(@website_docs, [
      "{{REPO_URL}}/blob/main/README.md",
      "{{REPO_URL}}/blob/main/examples/phoenix_meilisearch/README.md",
      "{{REPO_URL}}/blob/main/examples/scrypath_ecommerce/README.md"
    ])

    assert_contains_all(@website_layout, [
      "https://hex.pm/packages/scrypath",
      "https://hexdocs.pm/scrypath",
      "{{REPO_URL}}"
    ])

    assert String.contains?(@website_docs, "{{REPO_URL}}/blob/main/guides/"),
           "expected docs page to route into guides"
  end

  test "misleading positive-claim families stay absent while explicit evaluate negations remain" do
    Enum.each(@all_surfaces, fn {path, content} ->
      assert_absent_all(content, @misleading_tokens, path)
    end)

    assert_contains_all(@website_evaluate, [
      "If you want hidden hooks that imply search is always current, the library is deliberately",
      "v1 targets Meilisearch first and keeps the adapter seam internal."
    ])

    refute String.contains?(@website_evaluate, "public multi-backend support"),
           "did not expect positive public multi-backend support wording in evaluate page"
  end

  test "website pages remain route-map summaries and avoid runbook command depth" do
    runbook_tokens = ["docker compose up -d", "mix deps.get", "SCRYPATH_MEILISEARCH_URL", "mix test"]

    Enum.each(@website_surfaces, fn {path, content} ->
      assert_absent_all(content, runbook_tokens, path)
    end)
  end

  defp assert_contains_all(content, snippets) do
    Enum.each(snippets, fn snippet ->
      assert String.contains?(content, snippet),
             "expected phase-112 contract token #{inspect(snippet)}"
    end)
  end

  defp assert_absent_all(content, snippets, path) do
    Enum.each(snippets, fn snippet ->
      refute String.contains?(content, snippet),
             "did not expect token #{inspect(snippet)} in #{path}"
    end)
  end
end
