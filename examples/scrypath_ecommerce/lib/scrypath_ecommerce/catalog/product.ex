defmodule ScrypathEcommerce.Catalog.Product do
  use Ecto.Schema

  use Scrypath,
    fields: [:name, :description, :tenant_id, :category_id],
    filterable: [:category_id, :tenant_id],
    tenant_field: :tenant_id,
    faceting: [attributes: [:category_id]]

  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

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

  @doc """
  Loads current products for Oban sync jobs, which carry only document ids.

  The demo Repo rejects queries without a tenant, so this loader states its
  scope explicitly: the ids come from Scrypath's own jobs, and each document
  carries its row's `tenant_id` through `tenant_field`.
  """
  def search_records(ids, _context) do
    from(product in __MODULE__, where: product.id in ^ids, preload: :category)
    |> ScrypathEcommerce.Repo.all(skip_tenant_id: true)
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :description, :tenant_id, :category_id])
    |> validate_required([:name, :tenant_id, :category_id])
  end
end
