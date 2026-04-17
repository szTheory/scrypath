defmodule FacetableMovie do
  @moduledoc false

  use Ecto.Schema

  use Scrypath,
    fields: [:title, :genre, :year, :rating, :director],
    filterable: [:genre, :year, :rating, :director],
    faceting: [
      attributes: [:genre, :year, :rating, :director],
      max_values_per_facet: 100
    ]

  embedded_schema do
    field(:title, :string)
    field(:genre, :string)
    field(:year, :integer)
    field(:rating, :float)
    field(:director, :string)
  end
end
