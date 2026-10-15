defmodule ScrypathOps.Test.CustomDocument do
  use Ecto.Schema
  use Scrypath, fields: [:title, :description], document_id: :uuid
  @primary_key {:uuid, :string, autogenerate: false}
  embedded_schema do
    field(:title, :string)
    field(:description, :string)
  end
end
