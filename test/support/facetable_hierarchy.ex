defmodule FacetableHierarchy do
  @moduledoc false

  use Ecto.Schema

  use Scrypath,
    fields: [:title, :categories_l0, :categories_l1],
    filterable: [:"categories.lvl0", :"categories.lvl1"],
    faceting: [
      nested_facet_paths: true,
      attributes: [:"categories.lvl0", :"categories.lvl1"],
      max_values_per_facet: 100
    ]

  embedded_schema do
    field(:title, :string)
    field(:categories_l0, :string)
    field(:categories_l1, :string)
  end
end
