defmodule ScrypathEcommerce.CatalogFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ScrypathEcommerce.Catalog` context.
  """

  alias ScrypathEcommerce.Catalog

  @doc """
  Generate a tenant.
  """
  def tenant_fixture(attrs \\ %{}) do
    {:ok, tenant} =
      attrs
      |> Enum.into(%{
        name: "some name #{System.unique_integer([:positive])}"
      })
      |> Catalog.create_tenant()

    tenant
  end

  @doc """
  Generate a category.
  """
  def category_fixture(tenant, attrs \\ %{}) do
    {:ok, category} =
      attrs
      |> Enum.into(%{
        name: "some category #{System.unique_integer([:positive])}"
      })
      |> then(&Catalog.create_category(tenant, &1))

    category
  end

  @doc """
  Generate a product.
  """
  def product_fixture(tenant, attrs \\ %{}) do
    {:ok, product} =
      attrs
      |> Enum.into(%{
        name: "some product #{System.unique_integer([:positive])}",
        description: "some description"
      })
      |> then(&Catalog.create_product(tenant, &1))

    product
  end

  @doc """
  Generate a variant.
  """
  def variant_fixture(tenant, attrs \\ %{}) do
    {:ok, variant} =
      attrs
      |> Enum.into(%{
        sku: "sku-#{System.unique_integer([:positive])}",
        price_cents: 1000,
        currency: "USD",
        inventory_count: 10,
        options: %{}
      })
      |> then(&Catalog.create_variant(tenant, &1))

    variant
  end

  @doc """
  Generates a standard catalog graph:
  - 1 Tenant
  - 2 Categories
  - 3 Products (spread over categories)
  - 2 Variants per Product

  Returns a map with the created entities.
  """
  def scenario_standard_catalog(attrs \\ %{}) do
    tenant = tenant_fixture(attrs)

    cat1 = category_fixture(tenant, %{name: "Electronics"})
    cat2 = category_fixture(tenant, %{name: "Apparel"})

    prod1 = product_fixture(tenant, %{name: "Laptop", category_id: cat1.id})
    prod2 = product_fixture(tenant, %{name: "Smartphone", category_id: cat1.id})
    prod3 = product_fixture(tenant, %{name: "T-Shirt", category_id: cat2.id})

    v1_1 = variant_fixture(tenant, %{product_id: prod1.id, sku: "LAP-8GB-#{System.unique_integer([:positive])}", price_cents: 100000})
    v1_2 = variant_fixture(tenant, %{product_id: prod1.id, sku: "LAP-16GB-#{System.unique_integer([:positive])}", price_cents: 120000})

    v2_1 = variant_fixture(tenant, %{product_id: prod2.id, sku: "PHONE-64GB-#{System.unique_integer([:positive])}", price_cents: 80000})
    v2_2 = variant_fixture(tenant, %{product_id: prod2.id, sku: "PHONE-128GB-#{System.unique_integer([:positive])}", price_cents: 90000})

    v3_1 = variant_fixture(tenant, %{product_id: prod3.id, sku: "TSHIRT-S-#{System.unique_integer([:positive])}", price_cents: 2000, options: %{"size" => "S"}})
    v3_2 = variant_fixture(tenant, %{product_id: prod3.id, sku: "TSHIRT-M-#{System.unique_integer([:positive])}", price_cents: 2000, options: %{"size" => "M"}})

    %{
      tenant: tenant,
      categories: [cat1, cat2],
      products: [prod1, prod2, prod3],
      variants: [v1_1, v1_2, v2_1, v2_2, v3_1, v3_2]
    }
  end
end
