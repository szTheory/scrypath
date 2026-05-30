defmodule ScrypathEcommerce.CatalogFixturesTest do
  use ScrypathEcommerce.DataCase, async: true

  alias ScrypathEcommerce.CatalogFixtures
  alias ScrypathEcommerce.Catalog.{Tenant, Category, Product, Variant}

  describe "tenant_fixture/1" do
    test "creates a tenant" do
      tenant = CatalogFixtures.tenant_fixture(%{name: "Test Tenant"})
      assert %Tenant{} = tenant
      assert tenant.name == "Test Tenant"
      assert tenant.id != nil
    end
  end

  describe "scenario_standard_catalog/1" do
    test "creates a standard catalog graph" do
      graph = CatalogFixtures.scenario_standard_catalog(%{name: "Scenario Tenant"})

      assert %{
               tenant: %Tenant{} = tenant,
               categories: [%Category{} = cat1, %Category{} = cat2],
               products: [%Product{} = prod1, %Product{} = prod2, %Product{} = prod3],
               variants: [%Variant{}, %Variant{}, %Variant{}, %Variant{}, %Variant{}, %Variant{}] = variants
             } = graph

      assert tenant.name == "Scenario Tenant"

      # Verify relationships
      assert cat1.tenant_id == tenant.id
      assert cat2.tenant_id == tenant.id

      assert prod1.category_id == cat1.id
      assert prod2.category_id == cat1.id
      assert prod3.category_id == cat2.id

      assert Enum.all?(variants, fn v -> v.tenant_id == tenant.id end)
      
      # Variant 1 and 2 belong to product 1
      assert Enum.count(variants, fn v -> v.product_id == prod1.id end) == 2
      # Variant 3 and 4 belong to product 2
      assert Enum.count(variants, fn v -> v.product_id == prod2.id end) == 2
      # Variant 5 and 6 belong to product 3
      assert Enum.count(variants, fn v -> v.product_id == prod3.id end) == 2
    end
  end
end
