defmodule ScrypathEcommerce.CatalogTest do
  use ScrypathEcommerce.DataCase

  alias ScrypathEcommerce.Catalog

  describe "tenancy" do
    @tag :skip
    test "Repo tenancy enforcement via prepare_query/3" do
      flunk("Not implemented: Queries should automatically filter by tenant_id")
    end

    @tag :skip
    test "Tenant management functions" do
      flunk("Not implemented: Functions to create and manage tenants")
    end

    @tag :skip
    test "Tenant-scoped CRUD" do
      flunk("Not implemented: CRUD operations should require a tenant scope")
    end
  end

  describe "brands" do
    alias ScrypathEcommerce.Catalog.Brand

    import ScrypathEcommerce.CatalogFixtures

    @invalid_attrs %{name: nil}

    test "list_brands/0 returns all brands" do
      brand = brand_fixture()
      assert Catalog.list_brands() == [brand]
    end

    test "get_brand!/1 returns the brand with given id" do
      brand = brand_fixture()
      assert Catalog.get_brand!(brand.id) == brand
    end

    test "create_brand/1 with valid data creates a brand" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Brand{} = brand} = Catalog.create_brand(valid_attrs)
      assert brand.name == "some name"
    end

    test "create_brand/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Catalog.create_brand(@invalid_attrs)
    end

    test "update_brand/2 with valid data updates the brand" do
      brand = brand_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Brand{} = brand} = Catalog.update_brand(brand, update_attrs)
      assert brand.name == "some updated name"
    end

    test "update_brand/2 with invalid data returns error changeset" do
      brand = brand_fixture()
      assert {:error, %Ecto.Changeset{}} = Catalog.update_brand(brand, @invalid_attrs)
      assert brand == Catalog.get_brand!(brand.id)
    end

    test "delete_brand/1 deletes the brand" do
      brand = brand_fixture()
      assert {:ok, %Brand{}} = Catalog.delete_brand(brand)
      assert_raise Ecto.NoResultsError, fn -> Catalog.get_brand!(brand.id) end
    end

    test "change_brand/1 returns a brand changeset" do
      brand = brand_fixture()
      assert %Ecto.Changeset{} = Catalog.change_brand(brand)
    end
  end

  describe "categories" do
    alias ScrypathEcommerce.Catalog.Category

    import ScrypathEcommerce.CatalogFixtures

    @invalid_attrs %{name: nil, slug: nil}

    test "list_categories/0 returns all categories" do
      category = category_fixture()
      assert Catalog.list_categories() == [category]
    end

    test "get_category!/1 returns the category with given id" do
      category = category_fixture()
      assert Catalog.get_category!(category.id) == category
    end

    test "create_category/1 with valid data creates a category" do
      valid_attrs = %{name: "some name", slug: "some slug"}

      assert {:ok, %Category{} = category} = Catalog.create_category(valid_attrs)
      assert category.name == "some name"
      assert category.slug == "some slug"
    end

    test "create_category/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Catalog.create_category(@invalid_attrs)
    end

    test "update_category/2 with valid data updates the category" do
      category = category_fixture()
      update_attrs = %{name: "some updated name", slug: "some updated slug"}

      assert {:ok, %Category{} = category} = Catalog.update_category(category, update_attrs)
      assert category.name == "some updated name"
      assert category.slug == "some updated slug"
    end

    test "update_category/2 with invalid data returns error changeset" do
      category = category_fixture()
      assert {:error, %Ecto.Changeset{}} = Catalog.update_category(category, @invalid_attrs)
      assert category == Catalog.get_category!(category.id)
    end

    test "delete_category/1 deletes the category" do
      category = category_fixture()
      assert {:ok, %Category{}} = Catalog.delete_category(category)
      assert_raise Ecto.NoResultsError, fn -> Catalog.get_category!(category.id) end
    end

    test "change_category/1 returns a category changeset" do
      category = category_fixture()
      assert %Ecto.Changeset{} = Catalog.change_category(category)
    end
  end

  describe "products" do
    alias ScrypathEcommerce.Catalog.Product

    import ScrypathEcommerce.CatalogFixtures

    @invalid_attrs %{name: nil, description: nil, price_cents: nil, sku: nil}

    test "list_products/0 returns all products" do
      product = product_fixture()
      assert Catalog.list_products() == [product]
    end

    test "get_product!/1 returns the product with given id" do
      product = product_fixture()
      assert Catalog.get_product!(product.id) == product
    end

    test "create_product/1 with valid data creates a product" do
      valid_attrs = %{name: "some name", description: "some description", price_cents: 42, sku: "some sku"}

      assert {:ok, %Product{} = product} = Catalog.create_product(valid_attrs)
      assert product.name == "some name"
      assert product.description == "some description"
      assert product.price_cents == 42
      assert product.sku == "some sku"
    end

    test "create_product/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Catalog.create_product(@invalid_attrs)
    end

    test "update_product/2 with valid data updates the product" do
      product = product_fixture()
      update_attrs = %{name: "some updated name", description: "some updated description", price_cents: 43, sku: "some updated sku"}

      assert {:ok, %Product{} = product} = Catalog.update_product(product, update_attrs)
      assert product.name == "some updated name"
      assert product.description == "some updated description"
      assert product.price_cents == 43
      assert product.sku == "some updated sku"
    end

    test "update_product/2 with invalid data returns error changeset" do
      product = product_fixture()
      assert {:error, %Ecto.Changeset{}} = Catalog.update_product(product, @invalid_attrs)
      assert product == Catalog.get_product!(product.id)
    end

    test "delete_product/1 deletes the product" do
      product = product_fixture()
      assert {:ok, %Product{}} = Catalog.delete_product(product)
      assert_raise Ecto.NoResultsError, fn -> Catalog.get_product!(product.id) end
    end

    test "change_product/1 returns a product changeset" do
      product = product_fixture()
      assert %Ecto.Changeset{} = Catalog.change_product(product)
    end
  end
end
