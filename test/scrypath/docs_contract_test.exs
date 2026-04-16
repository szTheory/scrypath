defmodule Scrypath.DocsContractTest do
  use ExUnit.Case, async: true

  @readme File.read!("README.md")
  @architecture File.read!("ARCHITECTURE.md")
  @ci_workflow File.read!(".github/workflows/ci.yml")
  @release_docs File.read!("docs/releasing.md")
  @guide_paths [
    "guides/getting-started.md",
    "guides/phoenix-walkthrough.md",
    "guides/phoenix-contexts.md",
    "guides/phoenix-controllers-and-json.md",
    "guides/phoenix-liveview.md",
    "guides/sync-modes-and-visibility.md"
  ]
  @guides Enum.into(@guide_paths, %{}, fn path -> {path, File.read!(path)} end)

  test "README preserves the operator contract for backfill and reindex" do
    assert_contains_all(@readme, [
      "Scrypath.backfill/2",
      "Scrypath.reindex/2",
      "Use backfill when",
      "Use managed reindex when",
      "cutover?: false",
      "Accepted work is not the same thing as search visibility"
    ])
  end

  test "README opens with installation, quick path, and phoenix wayfinding" do
    assert String.contains?(@readme, "Scrypath, the Ecto-native search indexing library")
    assert ordered?(@readme, "## Installation", "## When Scrypath Fits")
    assert ordered?(@readme, "## Quick Path", "## When Scrypath Fits")
    assert @readme =~ ~S|{:scrypath, "~> 0.1.0"}|
    refute @readme =~ ~S|{:scrypath, path: "../scrypath"}|

    assert_contains_all(@readme, [
      "MyApp.Content",
      "search_posts(query, opts \\\\ [])",
      "publish_post(post, attrs)",
      "MyAppWeb.PostController",
      "Phoenix Walkthrough"
    ])
  end

  test "ARCHITECTURE preserves the operational semantics contract" do
    assert_contains_all(@architecture, [
      "create target -> apply settings -> backfill -> optional cutover",
      "Scrypath treats drift as an expected operational state",
      "Accepted work is not search-visible completion",
      "backfill into the live index",
      "cutover?: false"
    ])
  end

  test "documentation keeps drift detection and recovery guidance explicit" do
    assert_contains_all(@readme, [
      "Detect drift before deciding",
      "stale search hits whose hydrated records are now missing",
      "document-count mismatches",
      "failed or discarded sync work",
      "stale deletes"
    ])

    assert_contains_all(@architecture, [
      "Drift can come from",
      "projection changes",
      "settings changes that require a full rebuild",
      "failed, retrying, or discarded async work",
      "old-index cleanup as part of the same managed reindex step"
    ])
  end

  test "phase 6 guide shell exists with the expected phoenix reading path" do
    Enum.each(@guide_paths, &assert(File.exists?(&1), "expected guide #{&1} to exist"))

    assert_contains_all(@guides["guides/getting-started.md"], [
      "Runtime orchestration still lives in your context modules",
      "Accepted work is not the same thing as search visibility"
    ])

    assert_contains_all(@guides["guides/phoenix-walkthrough.md"], [
      "## 1. Declare The Searchable Schema",
      "## 2. Put Search And Sync In The Context",
      "## 3. Call That Boundary From Controllers",
      "## 4. Reuse The Same Context From LiveView",
      "Controllers translate request params into a context call",
      "LiveView owns UI state. The context still owns repo access and Scrypath orchestration."
    ])

    assert_contains_all(@guides["guides/sync-modes-and-visibility.md"], [
      "search visibility is an operational concern",
      "the enqueue is durable",
      "Accepted work is not the same thing as search visibility."
    ])
  end

  test "guide snippets stay aligned with the phoenix fixture contract" do
    docs = [@readme | Map.values(@guides)] |> Enum.join("\n")

    assert_contains_all(docs, [
      "search_posts(query, opts \\\\ [])",
      "publish_post(post, attrs)",
      "defmodule MyAppWeb.PostController",
      "defmodule MyAppWeb.PostLive",
      "defmodule MyAppWeb.Api.PostController"
    ])
  end

  test "release docs and CI keep the package gate auth-free" do
    assert_contains_all(@ci_workflow, [
      "mix test test/release/package_metadata_test.exs",
      "mix hex.build --unpack"
    ])

    refute @ci_workflow =~ "mix hex.publish --dry-run"

    assert_contains_all(@release_docs, [
      "mix test test/release/package_metadata_test.exs",
      "mix hex.build --unpack",
      "HEX_API_KEY",
      "mix hex.publish --dry-run --yes",
      "always-on CI gate"
    ])
  end

  test "phoenix guides keep the context-first boundary explicit" do
    assert_contains_all(@guides["guides/phoenix-contexts.md"], [
      "Scrypath fits Phoenix best when your context is the application-facing boundary",
      "Do not teach controllers or LiveView modules to compose raw `Repo` and `Scrypath.*` calls as the main pattern."
    ])

    assert_contains_all(@guides["guides/phoenix-controllers-and-json.md"], [
      "Phoenix controllers should translate request params into a context call",
      "Do not recommend direct `Repo` queries plus direct `Scrypath.search/3` calls inside the controller.",
      "page_number =",
      "normalize_page()",
      "String.to_integer(page)",
      "page: [number: page_number, size: 20]"
    ])

    assert_contains_all(@guides["guides/phoenix-liveview.md"], [
      "LiveView owns UI state, and the context owns repo access plus Scrypath orchestration.",
      "the UI should not imply immediate search visibility unless the context chose `:inline`"
    ])
  end

  test "all Elixir code fences in docs stay syntactically valid" do
    for snippet <- extract_elixir_fences(@readme) ++ extract_elixir_fences(@architecture) ++ guide_fences() do
      assert {:ok, _quoted} = Code.string_to_quoted(snippet)
    end
  end

  defp guide_fences do
    @guides
    |> Map.values()
    |> Enum.flat_map(&extract_elixir_fences/1)
  end

  defp extract_elixir_fences(markdown) do
    Regex.scan(~r/```elixir\n(.*?)```/ms, markdown, capture: :all_but_first)
    |> List.flatten()
    |> Enum.map(&String.trim/1)
  end

  defp assert_contains_all(content, snippets) do
    Enum.each(snippets, fn snippet ->
      assert String.contains?(content, snippet),
             "expected docs to include #{inspect(snippet)}"
    end)
  end

  defp ordered?(content, first, second) do
    {first_index, second_index} =
      Enum.reduce([first, second], %{}, fn needle, acc ->
        Map.put(acc, needle, :binary.match(content, needle))
      end)
      |> then(fn indices ->
        {elem(indices[first], 0), elem(indices[second], 0)}
      end)

    first_index < second_index
  end
end
