defmodule Scrypath.CompositionManyTest do
  use ExUnit.Case, async: true

  alias Scrypath.Composition

  test "compose_many/2 lowers per-entry composition into tuple/shared-option contract" do
    assert {:ok, many} =
             Composition.compose_many(
               [
                 %{
                   schema: SearchablePost,
                   text: "ecto",
                   fragments: [%{defaults: %{filter: [status: "published"]}}],
                   criteria: %{page: [size: 5]}
                 },
                 %{
                   schema: FacetableMovie,
                   text: "ecto",
                   criteria: %{facets: [:genre], facet_filter: [genre: ["Sci-Fi"]]}
                 }
               ],
               shared: %{defaults: %{per_query: %{show_ranking_score: true}}}
             )

    {entries, shared_opts} = Composition.to_search_many_args(many)

    assert shared_opts == [per_query: %{show_ranking_score: true}]

    assert entries == [
             {SearchablePost, "ecto", [filter: [status: "published"], page: [size: 5]]},
             {FacetableMovie, "ecto",
              [
                facets: [:genre],
                facet_filter: [genre: ["Sci-Fi"]]
              ]}
           ]
  end

  test "compose_many/2 keeps :all entries honest and entry-scoped" do
    assert {:ok, many} =
             Composition.compose_many(
               [
                 %{schema: :all, text: "release", criteria: %{page: [size: 3]}},
                 %{schema: SearchablePost, text: "release"}
               ],
               shared: %{defaults: %{per_query: %{show_ranking_score_details: true}}}
             )

    {entries, shared_opts} = Composition.to_search_many_args(many)

    assert shared_opts == [per_query: %{show_ranking_score_details: true}]
    assert entries == [{:all, "release", [page: [size: 3]]}, {SearchablePost, "release"}]
  end

  test "shared fixed is rejected explicitly" do
    assert {:error, {:invalid_shared_fixed, :fixed_not_supported}} =
             Composition.compose_many(
               [%{schema: SearchablePost, text: "ecto"}],
               shared: %{fixed: %{filter: [status: "published"]}}
             )
  end

  test "shared defaults preserve per_query shallow merge while entry opts stay canonical" do
    assert {:ok, many} =
             Composition.compose_many(
               [
                 %{
                   schema: SearchablePost,
                   text: "ecto",
                   criteria: %{per_query: %{ranking_score_threshold: 0.8}}
                 }
               ],
               shared: %{defaults: %{per_query: %{show_ranking_score: true}}}
             )

    {entries, shared_opts} = Composition.to_search_many_args(many)

    assert shared_opts == [per_query: %{show_ranking_score: true}]

    assert entries == [
             {SearchablePost, "ecto", [per_query: %{ranking_score_threshold: 0.8}]}
           ]
  end
end
