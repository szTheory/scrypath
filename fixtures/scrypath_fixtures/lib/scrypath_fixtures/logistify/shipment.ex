defmodule ScrypathFixtures.Logistify.Shipment do
  @moduledoc """
  Logistify's searchable shipment schema. Logistify is a fictional freight-tracking product; the
  data is for development and tests only.

  Fictional adopter: Scrypath-owned data, no records copied from any other project.
  """

  use Ecto.Schema

  use Scrypath,
    fields: [:reference, :lane],
    filterable: [:status],
    sortable: [:updated_at]

  embedded_schema do
    field(:reference, :string)
    field(:lane, :string)
    field(:status, :string)
    field(:updated_at, :utc_datetime)
  end
end
