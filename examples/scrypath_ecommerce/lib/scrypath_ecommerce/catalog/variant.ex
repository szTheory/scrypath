defmodule ScrypathEcommerce.Catalog.Variant do
  use Ecto.Schema

  use Scrypath,
    fields: [:sku, :product_id, :tenant_id],
    filterable: [:product_id, :tenant_id],
    tenant_field: :tenant_id

  import Ecto.Changeset

  schema "variants" do
    field(:sku, :string)
    field(:price_cents, :integer)
    field(:currency, :string, default: "USD")
    field(:inventory_count, :integer, default: 0)
    field(:options, :map, default: %{})
    belongs_to(:tenant, ScrypathEcommerce.Catalog.Tenant)
    belongs_to(:product, ScrypathEcommerce.Catalog.Product)
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(variant, attrs) do
    variant
    |> cast(attrs, [
      :sku,
      :price_cents,
      :currency,
      :inventory_count,
      :options,
      :tenant_id,
      :product_id
    ])
    |> validate_required([
      :sku,
      :price_cents,
      :currency,
      :inventory_count,
      :tenant_id,
      :product_id
    ])
    |> unique_constraint(:sku, name: :variants_tenant_id_sku_index)
  end

  @doc """
  Search document for a variant.

  The product name is denormalized so a federated query (e.g. "Quantum") matches both
  the Product index and this Variant/SKU index — the merge that the federation demo and
  the bundled `federated-catalog-probe` playbook show. Requires `:product` preloaded.
  """
  def search_document(variant) do
    %{
      sku: variant.sku,
      product_id: variant.product_id,
      tenant_id: variant.tenant_id,
      product_name: product_name(variant.product),
      options: options_text(variant.options)
    }
  end

  defp product_name(%ScrypathEcommerce.Catalog.Product{name: name}), do: name
  defp product_name(_), do: nil

  defp options_text(options) when is_map(options) do
    options
    |> Enum.map(fn {key, value} -> "#{key}: #{value}" end)
    |> Enum.join(", ")
  end

  defp options_text(_), do: ""
end
