defmodule ScrypathEcommerce.CatalogTest do
  use ScrypathEcommerce.DataCase
  use Oban.Testing, repo: ScrypathEcommerce.Repo

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

      %{tenant: tenant, category: category}
    end

    test "create_product/2 enqueues a sync job", %{tenant: tenant, category: category} do
      assert {:ok, product} =
               Catalog.create_product(tenant, %{
                 name: "Laptop",
                 description: "Fast",
                 category_id: category.id
               })

      assert_enqueued(worker: Scrypath.Oban.UpsertWorker, args: %{"document_ids" => [product.id]})

      assert Scrypath.Projection.document(Catalog.Product, product).data.category_name ==
               "Electronics"
    end

    test "update_product/3 enqueues a sync job", %{tenant: tenant, category: category} do
      {:ok, product} =
        Catalog.create_product(tenant, %{
          name: "Laptop",
          description: "Fast",
          category_id: category.id
        })

      assert {:ok, product} = Catalog.update_product(tenant, product, %{name: "Gaming Laptop"})
      assert_enqueued(worker: Scrypath.Oban.UpsertWorker, args: %{"document_ids" => [product.id]})

      assert Scrypath.Projection.document(Catalog.Product, product).data.category_name ==
               "Electronics"
    end

    test "update_category/3 enqueues related product sync", %{tenant: tenant, category: category} do
      {:ok, _product} =
        Catalog.create_product(tenant, %{
          name: "Laptop",
          description: "Fast",
          category_id: category.id
        })

      assert {:ok, category} = Catalog.update_category(tenant, category, %{name: "Computers"})

      assert_enqueued(
        worker: Scrypath.Sync.RelatedWorker,
        args: %{
          "schema" => to_string(Catalog.Category),
          "document_ids" => [category.id],
          "fan_out" => "products"
        }
      )
    end

    test "resolve_products_for_categories/1 reloads category products with category names", %{
      tenant: tenant,
      category: category
    } do
      {:ok, product} =
        Catalog.create_product(tenant, %{
          name: "Laptop",
          description: "Fast",
          category_id: category.id
        })

      [resolved] = Catalog.resolve_products_for_categories([category.id])

      assert resolved.id == product.id
      assert resolved.category.name == "Electronics"

      assert Scrypath.Projection.document(Catalog.Product, resolved).data.category_name ==
               "Electronics"

      [resolved_from_struct] = Catalog.resolve_products_for_categories([category])

      assert resolved_from_struct.id == product.id
    end

    test "delete_product/2 enqueues a sync job", %{tenant: tenant, category: category} do
      {:ok, product} =
        Catalog.create_product(tenant, %{
          name: "Laptop",
          description: "Fast",
          category_id: category.id
        })

      assert {:ok, product} = Catalog.delete_product(tenant, product)
      assert_enqueued(worker: Scrypath.Oban.DeleteWorker, args: %{"document_ids" => [product.id]})
    end

    test "list_products/1 returns products for tenant", %{tenant: tenant, category: category} do
      {:ok, product} =
        Catalog.create_product(tenant, %{
          name: "Laptop",
          description: "Fast",
          category_id: category.id
        })

      assert [fetched] = Catalog.list_products(tenant)
      assert fetched.id == product.id
    end

    test "create_variant/2 creates a variant", %{tenant: tenant, category: category} do
      {:ok, product} =
        Catalog.create_product(tenant, %{
          name: "Laptop",
          description: "Fast",
          category_id: category.id
        })

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
