defmodule ScrypathFixtures.Shopadelic.Product do
  @moduledoc """
  Shopadelic's searchable product schema. Shopadelic is a fictional online-shop product; the data
  is for development and tests only.

  Fictional adopter: Scrypath-owned data, no records copied from any other project.

  `:storeId` is a filterable attribute next to `:status`, which is what the `:settings_drift`
  scenario leaves out of the applied settings.
  """

  use Ecto.Schema

  use Scrypath,
    fields: [:title, :status, :storeId],
    filterable: [:status, :storeId]

  embedded_schema do
    field(:title, :string)
    field(:status, :string)
    field(:storeId, :string)
  end
end
