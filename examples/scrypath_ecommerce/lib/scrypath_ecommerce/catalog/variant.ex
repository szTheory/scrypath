defmodule ScrypathEcommerce.Catalog.Variant do
  use Ecto.Schema
  import Ecto.Changeset

  schema "variants" do
    field :sku, :string
    field :price_cents, :integer
    field :currency, :string, default: "USD"
    field :inventory_count, :integer, default: 0
    field :options, :map, default: %{}
    belongs_to :tenant, ScrypathEcommerce.Catalog.Tenant
    belongs_to :product, ScrypathEcommerce.Catalog.Product
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(variant, attrs) do
    variant
    |> cast(attrs, [:sku, :price_cents, :currency, :inventory_count, :options, :tenant_id, :product_id])
    |> validate_required([:sku, :price_cents, :currency, :inventory_count, :tenant_id, :product_id])
    |> unique_constraint(:sku, name: :variants_tenant_id_sku_index)
  end
end
