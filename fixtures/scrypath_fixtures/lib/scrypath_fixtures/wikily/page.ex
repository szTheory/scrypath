defmodule ScrypathFixtures.Wikily.Page do
  @moduledoc """
  Wikily's searchable page schema. Wikily is a fictional team-wiki product; the data is for
  development and tests only, Scrypath-owned, and no record is copied from a real product.
  """

  use Ecto.Schema

  use Scrypath,
    fields: [:title, :slug, :excerpt],
    filterable: [:space]

  embedded_schema do
    field(:title, :string)
    field(:slug, :string)
    field(:excerpt, :string)
    field(:space, :string)
  end
end
