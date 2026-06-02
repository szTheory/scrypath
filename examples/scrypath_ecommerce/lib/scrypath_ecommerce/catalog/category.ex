defmodule ScrypathEcommerce.Catalog.Category do
  use Ecto.Schema
  import Ecto.Changeset

  schema "categories" do
    field(:name, :string)
    belongs_to(:tenant, ScrypathEcommerce.Catalog.Tenant)
    timestamps(type: :utc_datetime)
  end

  def __scrypath__(:fan_outs) do
    [
      products: [
        target: ScrypathEcommerce.Catalog.Product,
        resolver: {ScrypathEcommerce.Catalog, :resolve_products_for_categories, []}
      ]
    ]
  end

  def __scrypath__(:document_id), do: :id

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :tenant_id])
    |> validate_required([:name, :tenant_id])
  end
end
