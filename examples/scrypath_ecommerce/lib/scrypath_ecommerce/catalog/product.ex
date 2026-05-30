defmodule ScrypathEcommerce.Catalog.Product do
  use Ecto.Schema
  use Scrypath.Schema,
    fields: [
      :name,
      :description
    ]
  import Ecto.Changeset

  schema "products" do
    field :name, :string
    field :description, :string
    belongs_to :tenant, ScrypathEcommerce.Catalog.Tenant
    belongs_to :category, ScrypathEcommerce.Catalog.Category
    has_many :variants, ScrypathEcommerce.Catalog.Variant
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :description, :tenant_id, :category_id])
    |> validate_required([:name, :tenant_id, :category_id])
  end
end
