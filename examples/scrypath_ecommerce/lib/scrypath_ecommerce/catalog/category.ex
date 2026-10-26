defmodule ScrypathEcommerce.Catalog.Category do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

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

  # Lets Scrypath's Oban fan-out reload categories by id across tenants.
  @doc false
  def search_records(ids, _context) do
    query = from(c in __MODULE__, where: c.id in ^ids)
    ScrypathEcommerce.Repo.all(query, skip_tenant_id: true)
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :tenant_id])
    |> validate_required([:name, :tenant_id])
  end
end
