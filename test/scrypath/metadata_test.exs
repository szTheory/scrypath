defmodule Scrypath.MetadataTest do
  use ExUnit.Case, async: true

  alias Scrypath.Composition

  defmodule TenantSchema do
    def __scrypath__(:tenant_field), do: :account_id
    def __scrypath__(:faceting), do: []
    def __scrypath__(:filterable), do: []
    def __scrypath__(:sortable), do: []
  end

  test "schema_capabilities/1 reflects tenant_field when declared" do
    capabilities = Scrypath.schema_capabilities(TenantSchema)

    assert capabilities.tenant == :account_id
  end

  test "schema_capabilities/1 reflects declaration-backed filter sort facet and paging support" do
    capabilities = Scrypath.schema_capabilities(FacetableMovie)

    assert capabilities.tenant == nil

    assert capabilities.filters == %{
             supported: true,
             fields: [:genre, :year, :rating, :director]
           }

    assert capabilities.sorts == %{supported: false, fields: []}

    assert capabilities.facets == %{
             supported: true,
             fields: [:genre, :year, :rating, :director],
             max_values_per_facet: 100,
             sort_facet_values_by: []
           }

    assert capabilities.paging == %{supported: true, fields: [:number, :size]}

    assert capabilities.limits.per_query_keys == [
             :ranking_score_threshold,
             :show_ranking_score,
             :show_ranking_score_details
           ]
  end

  test "reflect_search/2 keeps defaulted and fixed distinct for composition output" do
    {:ok, composition} =
      Composition.compose(
        %{
          defaults: %{text: "movies", filter: [genre: "Sci-Fi"], page: [size: 10]},
          fixed: %{filter: [director: "Villeneuve"]}
        },
        %{facet_filter: [year: 2024]}
      )

    reflection = Scrypath.reflect_search(FacetableMovie, composition)

    assert reflection.resolved.applied == %{
             text: "movies",
             filter: [director: "Villeneuve", genre: "Sci-Fi"],
             page: [size: 10],
             facet_filter: [year: 2024]
           }

    assert reflection.resolved.defaulted == %{
             text: "movies",
             filter: [genre: "Sci-Fi"],
             page: [size: 10]
           }

    assert reflection.resolved.fixed == %{filter: [director: "Villeneuve"]}
    assert reflection.resolved.unsupported == %{}
  end

  test "reflect_search/2 reports field-scoped unsupported capabilities from plain data" do
    reflection =
      Scrypath.reflect_search(SearchablePost, %{
        text: "ecto",
        filter: [status: "published", genre: "fiction"],
        facets: [:status],
        facet_filter: [genre: "fiction"],
        sort: [asc: :title],
        page: [size: 5]
      })

    assert reflection.resolved.applied == %{
             text: "ecto",
             filter: [status: "published"],
             page: [size: 5]
           }

    assert reflection.resolved.unsupported == %{
             filter: [genre: "fiction"],
             facets: [:status],
             facet_filter: [genre: "fiction"],
             sort: [asc: :title]
           }
  end

  test "reflect_search_many/2 stays entry-scoped and keeps host-owned concerns explicit" do
    {:ok, many} =
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
          },
          %{schema: :all, text: "ecto"}
        ],
        shared: %{defaults: %{per_query: %{show_ranking_score: true}}}
      )

    reflection = Scrypath.reflect_search_many(many)

    assert [
             %{
               entry: %{schema: SearchablePost},
               resolved: %{defaulted: %{filter: [status: "published"]}}
             },
             %{
               entry: %{schema: FacetableMovie},
               resolved: %{
                 applied: %{
                   facets: [:genre],
                   facet_filter: [genre: ["Sci-Fi"]],
                   per_query: %{show_ranking_score: true},
                   text: "ecto"
                 }
               }
             },
             %{
               entry: %{schema: :all},
               capabilities: %{status: :deferred, reason: :all_expands_at_runtime}
             }
           ] = reflection.entries

    assert reflection.host_owned == %{
             tenant_policy: :host_owned,
             authorization: :host_owned,
             related_data: :host_owned
           }
  end
end
