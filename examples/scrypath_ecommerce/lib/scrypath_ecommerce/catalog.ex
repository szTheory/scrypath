defmodule ScrypathEcommerce.Catalog do
  @moduledoc """
  The Catalog context.
  Enforces multi-tenancy. All operations require a tenant except those on Tenant itself.
  """

  alias Ecto.Multi
  import Ecto.Query, warn: false
  alias ScrypathEcommerce.Repo
  alias ScrypathEcommerce.Catalog.{Tenant, Category, Product, Variant}

  defp tenant_opts(%Tenant{id: id}), do: [tenant_id: id]
  defp tenant_opts(tenant_id) when is_integer(tenant_id), do: [tenant_id: tenant_id]

  defp tenant_opts(tenant_id) when is_binary(tenant_id),
    do: [tenant_id: String.to_integer(tenant_id)]

  defp put_tenant_id(attrs, tenant_id) do
    cond do
      is_map(attrs) and Enum.any?(Map.keys(attrs), &is_atom/1) ->
        Map.put(attrs, :tenant_id, tenant_id)

      is_map(attrs) ->
        Map.put(attrs, "tenant_id", tenant_id)

      true ->
        Keyword.put(attrs, :tenant_id, tenant_id)
    end
  end

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
    |> Category.changeset(put_tenant_id(attrs, opts[:tenant_id]))
    |> Repo.insert(opts)
  end

  def update_category(tenant, %Category{} = category, attrs) do
    opts = tenant_opts(tenant)

    Multi.new()
    |> Multi.update(:category, Category.changeset(category, attrs), opts)
    |> Multi.run(:sync_related_products, fn _repo, %{category: category} ->
      Scrypath.sync_related(Category, category, fan_out: :products)
    end)
    |> Repo.transaction(opts)
    |> case do
      {:ok, %{category: category}} -> {:ok, category}
      {:error, :category, changeset, _changes} -> {:error, changeset}
      {:error, :sync_related_products, reason, _changes} -> {:error, reason}
    end
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

  def resolve_products_for_categories([%Category{} | _] = categories) do
    category_ids = Enum.map(categories, & &1.id)
    tenant_ids = Enum.map(categories, & &1.tenant_id)

    Product
    |> where([product], product.category_id in ^category_ids and product.tenant_id in ^tenant_ids)
    |> preload(:category)
    |> Repo.all(skip_tenant_id: true)
  end

  def resolve_products_for_categories([_id | _] = category_ids) do
    Product
    |> where([product], product.category_id in ^category_ids)
    |> preload(:category)
    |> Repo.all(skip_tenant_id: true)
  end

  def resolve_products_for_categories([]), do: []

  def get_product!(tenant, id) do
    Repo.get!(Product, id, tenant_opts(tenant))
  end

  def create_product(tenant, attrs) do
    opts = tenant_opts(tenant)

    %Product{}
    |> Product.changeset(put_tenant_id(attrs, opts[:tenant_id]))
    |> Repo.insert(opts)
    |> case do
      {:ok, product} ->
        product = Repo.preload(product, :category, opts)
        Scrypath.sync_record(Product, product)
        {:ok, product}

      error ->
        error
    end
  end

  def update_product(tenant, %Product{} = product, attrs) do
    product
    |> Product.changeset(attrs)
    |> Repo.update(tenant_opts(tenant))
    |> case do
      {:ok, product} ->
        product = Repo.preload(product, :category, tenant_opts(tenant))
        Scrypath.sync_record(Product, product)
        {:ok, product}

      error ->
        error
    end
  end

  def delete_product(tenant, %Product{} = product) do
    Repo.delete(product, tenant_opts(tenant))
    |> case do
      {:ok, product} ->
        Scrypath.delete_record(Product, product)
        {:ok, product}

      error ->
        error
    end
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
    |> Variant.changeset(put_tenant_id(attrs, opts[:tenant_id]))
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
