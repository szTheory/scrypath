defmodule Scrypath.CompositionPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Scrypath.Composition

  property "repeated composition of equivalent inputs stays idempotent and deterministic" do
    check all(
            text <- string(:alphanumeric, min_length: 1),
            status <- string(:alphanumeric, min_length: 1),
            page_size <- integer(1..20)
          ) do
      fragment = %{
        defaults: %{
          text: text,
          filter: [status: status, category: "news"],
          page: [size: page_size],
          per_query: %{show_ranking_score: true}
        },
        fixed: %{filter: [role: "admin"]}
      }

      caller = %{
        text: "",
        filter: [category: "articles"],
        page: [size: page_size + 1],
        per_query: %{ranking_score_threshold: 0.1}
      }

      assert {:ok, once} = Composition.compose(fragment, caller)
      assert {:ok, twice} = Composition.compose([fragment], caller)
      assert once == twice
      assert once == Composition.compose!(fragment, caller)
    end
  end

  property "canonical keyword output is stable for equivalent fragment orderings" do
    check all(
            left <- string(:alphanumeric, min_length: 1),
            right <- string(:alphanumeric, min_length: 1)
          ) do
      a = %{defaults: %{filter: [status: left, genre: "fiction"]}}
      b = %{defaults: %{filter: [status: right], facet_filter: [year: "2024", genre: "fiction"]}}

      assert {:ok, first} = Composition.compose([a, b], %{})

      assert {:ok, second} =
               Composition.compose(
                 [
                   a,
                   %{
                     defaults: %{
                       facet_filter: [genre: "fiction", year: "2024"],
                       filter: [status: right]
                     }
                   }
                 ],
                 %{}
               )

      assert first.filter == second.filter
      assert first.facet_filter == second.facet_filter
      assert first.defaulted == second.defaulted
    end
  end
end
