defmodule Scrypath.CompositionTest do
  use ExUnit.Case, async: true

  alias Scrypath.Composition

  test "compose/2 expands plain-data presets into canonical search args" do
    fragment = %{
      defaults: %{
        text: "phoenix",
        filter: [status: "published"],
        sort: [desc: :inserted_at],
        page: [number: 2, size: 20],
        facets: [:genre, :year],
        facet_filter: [genre: ["Action", "Drama"]],
        per_query: %{show_ranking_score: true}
      },
      sources: %{text: :preset, filter: :preset},
      warnings: %{filter: ["preset applied"]}
    }

    assert {:ok, composition} = Composition.compose(fragment, %{})

    assert composition.text == "phoenix"
    assert composition.filter == [status: "published"]
    assert composition.sort == [desc: :inserted_at]
    assert composition.page == [number: 2, size: 20]
    assert composition.facets == [:genre, :year]
    assert composition.facet_filter == [genre: ["Action", "Drama"]]
    assert composition.per_query == %{show_ranking_score: true}
    assert composition.defaulted.text == "phoenix"
    assert composition.defaulted.filter == [status: "published"]
    assert composition.applied.text == "phoenix"
    assert composition.sources == %{text: :preset, filter: :preset}
    assert composition.warnings == %{filter: ["preset applied"]}
    refute match?(%Scrypath.Query{}, composition)

    assert {"phoenix",
            [
              filter: [status: "published"],
              sort: [desc: :inserted_at],
              page: [number: 2, size: 20],
              facets: [:genre, :year],
              facet_filter: [genre: ["Action", "Drama"]],
              per_query: %{show_ranking_score: true}
            ]} = Composition.to_search_args(composition)
  end

  test "caller text overrides default text while blank caller text receives the preset default" do
    fragment = %{defaults: %{text: "default text"}}

    assert {:ok, with_override} = Composition.compose(fragment, %{text: "caller text"})
    assert with_override.text == "caller text"
    assert with_override.defaulted == %{}

    assert {:ok, with_blank} = Composition.compose(fragment, %{text: "   "})
    assert with_blank.text == "default text"
    assert with_blank.defaulted == %{text: "default text"}
  end

  test "sort page and facets replace whole defaults rather than deep-merging" do
    fragment = %{
      defaults: %{
        sort: [desc: :inserted_at],
        page: [number: 1, size: 10],
        facets: [:genre, :year]
      }
    }

    caller = %{
      sort: [asc: :title],
      page: [size: 5],
      facets: [:author]
    }

    assert {:ok, composition} = Composition.compose(fragment, caller)

    assert composition.sort == [asc: :title]
    assert composition.page == [size: 5]
    assert composition.facets == [:author]
    assert composition.defaulted == %{}
  end

  test "filter and facet_filter defaults merge with caller bias while fixed conflicts fail explicitly" do
    fragment = %{
      defaults: %{
        filter: [status: "draft", genre: "fiction"],
        facet_filter: [year: "2024", genre: "fiction"]
      },
      fixed: %{
        filter: [role: "admin"],
        facet_filter: [region: "emea"]
      }
    }

    caller = %{
      filter: [status: "published"],
      facet_filter: [year: "2025"],
      per_query: %{show_ranking_score_details: true}
    }

    assert {:ok, composition} = Composition.compose(fragment, caller)
    assert composition.filter == [genre: "fiction", role: "admin", status: "published"]
    assert composition.facet_filter == [genre: "fiction", region: "emea", year: "2025"]
    assert composition.defaulted.filter == [genre: "fiction"]
    assert composition.defaulted.facet_filter == [genre: "fiction"]
    assert composition.fixed.filter == [role: "admin"]
    assert composition.fixed.facet_filter == [region: "emea"]
    assert composition.applied.filter == [genre: "fiction", role: "admin", status: "published"]
    assert composition.applied.facet_filter == [genre: "fiction", region: "emea", year: "2025"]

    assert {:error, {:composition_conflict, :filter, :role, details}} =
             Composition.compose(fragment, %{filter: [role: "member"]})

    assert details.caller == "member"
    assert details.fixed == "admin"

    assert {:error, {:composition_conflict, :facet_filter, :region, details}} =
             Composition.compose(fragment, %{facet_filter: [region: "na"]})

    assert details.caller == "na"
    assert details.fixed == "emea"
  end

  test "competing fixed conflicts and invalid fields fail with stable field-scoped tuples" do
    assert {:error, {:composition_conflict, :filter, :status, details}} =
             Composition.compose(
               [
                 %{fixed: %{filter: [status: "published"]}},
                 %{fixed: %{filter: [status: "draft"]}}
               ],
               %{}
             )

    assert details.left == "published"
    assert details.right == "draft"
    assert details.source == :fixed

    assert {:error, {:invalid_defaults_field, :unknown}} =
             Composition.compose(%{defaults: %{unknown: :value}}, %{})

    assert {:error, {:invalid_fixed_field, :sort}} =
             Composition.compose(%{fixed: %{sort: [asc: :id]}}, %{})

    assert {:error, {:invalid_fragment, {:page, [number: 0]}}} =
             Composition.compose(%{defaults: %{page: [number: 0]}}, %{})
  end

  test "per_query shallow merges and compose!/2 raises on conflicts" do
    fragment = %{
      defaults: %{per_query: %{show_ranking_score: true, ranking_score_threshold: 0.5}}
    }

    assert {:ok, composition} =
             Composition.compose(fragment, %{per_query: %{ranking_score_threshold: 0.8}})

    assert composition.per_query == %{
             show_ranking_score: true,
             ranking_score_threshold: 0.8
           }

    assert_raise ArgumentError, ~r/composition failed/, fn ->
      Composition.compose!(
        [%{fixed: %{filter: [status: "published"]}}, %{fixed: %{filter: [status: "draft"]}}],
        %{}
      )
    end
  end
end
