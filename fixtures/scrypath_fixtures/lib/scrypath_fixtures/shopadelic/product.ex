defmodule ScrypathFixtures.Shopadelic.Product do
  @moduledoc """
  Shopadelic's searchable product schema. Shopadelic is a fictional online-shop product; the data
  is for development and tests only, Scrypath-owned, and no record is copied from a real product.

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
