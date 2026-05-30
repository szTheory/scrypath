defmodule ScrypathEcommerce.CatalogTest do
  use ScrypathEcommerce.DataCase

  alias ScrypathEcommerce.Catalog

  describe "tenancy" do
    test "Repo tenancy enforcement via prepare_query/3" do
      # Query without tenant_id or skip_tenant_id raises ArgumentError
      assert_raise ArgumentError, ~r/expected :tenant_id or :skip_tenant_id/, fn ->
        ScrypathEcommerce.Repo.all(Catalog.Category)
      end
    end

    test "Tenant management functions bypass tenant scoping" do
      assert {:ok, tenant} = Catalog.create_tenant(%{name: "Test Tenant"})
      assert [fetched_tenant] = Catalog.list_tenants()
      assert fetched_tenant.id == tenant.id
      assert Catalog.get_tenant!(tenant.id).id == tenant.id
    end

    test "cross-tenant leakage is prevented" do
      {:ok, tenant1} = Catalog.create_tenant(%{name: "Tenant 1"})
      {:ok, tenant2} = Catalog.create_tenant(%{name: "Tenant 2"})

      {:ok, cat1} = Catalog.create_category(tenant1, %{name: "Cat 1"})
      {:ok, cat2} = Catalog.create_category(tenant2, %{name: "Cat 2"})

      # tenant1 should only see cat1
      assert [fetched_cat1] = Catalog.list_categories(tenant1)
      assert fetched_cat1.id == cat1.id

      # tenant2 should only see cat2
      assert [fetched_cat2] = Catalog.list_categories(tenant2)
      assert fetched_cat2.id == cat2.id

      # getting cat2 with tenant1 should fail
      assert_raise Ecto.NoResultsError, fn ->
        Catalog.get_category!(tenant1, cat2.id)
      end
    end
  end

  describe "products and variants" do
    setup do
      {:ok, tenant} = Catalog.create_tenant(%{name: "Test Tenant"})
      {:ok, category} = Catalog.create_category(tenant, %{name: "Electronics"})

      {:ok, product} =
        Catalog.create_product(tenant, %{
          name: "Laptop",
          description: "Fast",
          category_id: category.id
        })

      %{tenant: tenant, category: category, product: product}
    end

    test "list_products/1 returns products for tenant", %{tenant: tenant, product: product} do
      assert [fetched] = Catalog.list_products(tenant)
      assert fetched.id == product.id
    end

    test "create_variant/2 creates a variant", %{tenant: tenant, product: product} do
      assert {:ok, variant} =
               Catalog.create_variant(tenant, %{
                 sku: "LAP-01",
                 price_cents: 100_000,
                 currency: "USD",
                 inventory_count: 50,
                 product_id: product.id
               })

      assert variant.sku == "LAP-01"
      assert variant.tenant_id == tenant.id
    end
  end
end
