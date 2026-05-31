defmodule ScrypathEcommerce.Catalog.Product do
  use Ecto.Schema

  use Scrypath,
    fields: [:name, :description, :tenant_id, :category_id],
    filterable: [:category_id, :tenant_id],
    tenant_field: :tenant_id,
    faceting: [attributes: [:category_id]]

  import Ecto.Changeset

  schema "products" do
    field(:name, :string)
    field(:description, :string)
    belongs_to(:tenant, ScrypathEcommerce.Catalog.Tenant)
    belongs_to(:category, ScrypathEcommerce.Catalog.Category)
    has_many(:variants, ScrypathEcommerce.Catalog.Variant)
    timestamps(type: :utc_datetime)
  end

  def search_document(product) do
    %{
      name: product.name,
      description: product.description,
      tenant_id: product.tenant_id,
      category_id: product.category_id,
      category_name: product.category.name
    }
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :description, :tenant_id, :category_id])
    |> validate_required([:name, :tenant_id, :category_id])
  end
end
