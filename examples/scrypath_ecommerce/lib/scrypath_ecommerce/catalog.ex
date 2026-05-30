defmodule ScrypathEcommerce.Catalog do
  @moduledoc """
  The Catalog context.
  Enforces multi-tenancy. All operations require a tenant except those on Tenant itself.
  """

  import Ecto.Query, warn: false
  alias ScrypathEcommerce.Repo
  alias ScrypathEcommerce.Catalog.{Tenant, Category, Product, Variant}

  defp tenant_opts(%Tenant{id: id}), do: [tenant_id: id]
  defp tenant_opts(tenant_id) when is_integer(tenant_id), do: [tenant_id: tenant_id]
  defp tenant_opts(tenant_id) when is_binary(tenant_id), do: [tenant_id: String.to_integer(tenant_id)]

  # --- Tenant ---

  def list_tenants do
    Repo.all(Tenant, skip_tenant_id: true)
  end

  def get_tenant!(id), do: Repo.get!(Tenant, id, skip_tenant_id: true)

  def create_tenant(attrs) do
    %Tenant{}
    |> Tenant.changeset(attrs)
    |> Repo.insert(skip_tenant_id: true)
  end

  # --- Category ---

  def list_categories(tenant) do
    Repo.all(Category, tenant_opts(tenant))
  end

  def get_category!(tenant, id) do
    Repo.get!(Category, id, tenant_opts(tenant))
  end

  def create_category(tenant, attrs) do
    opts = tenant_opts(tenant)
    
    %Category{}
    |> Category.changeset(Map.put(attrs, "tenant_id", opts[:tenant_id]))
    |> Repo.insert(opts)
  end

  def update_category(tenant, %Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Repo.update(tenant_opts(tenant))
  end

  def delete_category(tenant, %Category{} = category) do
    Repo.delete(category, tenant_opts(tenant))
  end

  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end

  # --- Product ---

  def list_products(tenant) do
    Repo.all(Product, tenant_opts(tenant))
  end

  def get_product!(tenant, id) do
    Repo.get!(Product, id, tenant_opts(tenant))
  end

  def create_product(tenant, attrs) do
    opts = tenant_opts(tenant)
    
    %Product{}
    |> Product.changeset(Map.put(attrs, "tenant_id", opts[:tenant_id]))
    |> Repo.insert(opts)
  end

  def update_product(tenant, %Product{} = product, attrs) do
    product
    |> Product.changeset(attrs)
    |> Repo.update(tenant_opts(tenant))
  end

  def delete_product(tenant, %Product{} = product) do
    Repo.delete(product, tenant_opts(tenant))
  end

  def change_product(%Product{} = product, attrs \\ %{}) do
    Product.changeset(product, attrs)
  end

  # --- Variant ---

  def list_variants(tenant) do
    Repo.all(Variant, tenant_opts(tenant))
  end

  def get_variant!(tenant, id) do
    Repo.get!(Variant, id, tenant_opts(tenant))
  end

  def create_variant(tenant, attrs) do
    opts = tenant_opts(tenant)
    
    %Variant{}
    |> Variant.changeset(Map.put(attrs, "tenant_id", opts[:tenant_id]))
    |> Repo.insert(opts)
  end

  def update_variant(tenant, %Variant{} = variant, attrs) do
    variant
    |> Variant.changeset(attrs)
    |> Repo.update(tenant_opts(tenant))
  end

  def delete_variant(tenant, %Variant{} = variant) do
    Repo.delete(variant, tenant_opts(tenant))
  end

  def change_variant(%Variant{} = variant, attrs \\ %{}) do
    Variant.changeset(variant, attrs)
  end
end
