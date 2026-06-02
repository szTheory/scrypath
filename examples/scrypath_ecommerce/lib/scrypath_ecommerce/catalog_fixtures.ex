defmodule ScrypathEcommerce.CatalogFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ScrypathEcommerce.Catalog` context.
  """

  alias ScrypathEcommerce.Catalog

  @demo_catalog [
    {"Smartphones",
     [
       {"Quantum CyberPhone X",
        "Flagship phone with private-device AI, titanium rails, and satellite failover.",
        [
          {"QCP-X-256", 99900, %{"finish" => "graphite", "storage" => "256GB"}},
          {"QCP-X-512", 109_900, %{"finish" => "silver", "storage" => "512GB"}}
        ]},
       {"Quantum CyberPhone Pro",
        "Pro field handset for merchandisers who need low-light scanning and long battery life.",
        [{"QCP-PRO-1TB", 129_900, %{"finish" => "black", "storage" => "1TB"}}]},
       {"Lumen Pocket Fold",
        "Compact foldable for buyers reviewing live assortment changes on the floor.",
        [{"LPF-512", 119_900, %{"finish" => "copper", "storage" => "512GB"}}]}
     ]},
    {"Laptops",
     [
       {"Nebula Ultrabook",
        "Lightweight catalog workstation with calibrated display and all-day battery.",
        [{"NEB-ULTRA", 149_900, %{"memory" => "32GB", "color" => "midnight"}}]},
       {"Atlas Studio 14",
        "Portable creative laptop for product photography and launch planning.",
        [{"ATL-ST14", 189_900, %{"memory" => "64GB", "color" => "graphite"}}]},
       {"Dockside Chromebook Fleet", "Low-cost checkout companion for temporary retail teams.",
        [{"DOCK-CB-128", 42900, %{"memory" => "8GB", "color" => "chalk"}}]}
     ]},
    {"Audio",
     [
       {"Signal Studio Headphones",
        "Closed-back headphones for noisy stockrooms and video walkthroughs.",
        [{"SIG-STUDIO", 34900, %{"color" => "oxide"}}]},
       {"Beacon Clip Mic", "Clip-on microphone kit for showroom livestreams and support calls.",
        [{"BCN-MIC-DUO", 15900, %{"kit" => "dual"}}]},
       {"Harbor ANC Earbuds", "Travel earbuds tuned for long buying trips and show floors.",
        [{"HBR-ANC", 21900, %{"color" => "pearl"}}]}
     ]},
    {"Cameras",
     [
       {"Aperture Mini Rig",
        "Compact camera rig for daily product drops and social catalog shots.",
        [{"APR-MINI", 79900, %{"lens" => "35mm"}}]},
       {"Northstar Product Scanner", "High-detail tabletop scanner for SKU archive photography.",
        [{"NTH-SCAN", 219_900, %{"mount" => "tabletop"}}]},
       {"Fieldlight Softbox Kit", "Two-light kit for clean product imagery in temporary spaces.",
        [{"FLD-SOFT-2", 28900, %{"kit" => "two-light"}}]}
     ]},
    {"Accessories",
     [
       {"Transit Cable Folio", "Organizer for demo-day chargers, adapters, and secure keys.",
        [{"TRN-FOLIO", 4900, %{"color" => "moss"}}]},
       {"Index Label Printer", "Compact printer for shelf labels and return-bin workflows.",
        [{"IDX-LABEL", 17900, %{"roll_width" => "2in"}}]},
       {"Slate Stand Trio", "Countertop stands for tablets, scanners, and payment devices.",
        [{"SLT-STAND-3", 9900, %{"pack" => "3"}}]}
     ]}
  ]

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

    v1_1 =
      variant_fixture(tenant, %{
        product_id: prod1.id,
        sku: "LAP-8GB-#{System.unique_integer([:positive])}",
        price_cents: 100_000
      })

    v1_2 =
      variant_fixture(tenant, %{
        product_id: prod1.id,
        sku: "LAP-16GB-#{System.unique_integer([:positive])}",
        price_cents: 120_000
      })

    v2_1 =
      variant_fixture(tenant, %{
        product_id: prod2.id,
        sku: "PHONE-64GB-#{System.unique_integer([:positive])}",
        price_cents: 80000
      })

    v2_2 =
      variant_fixture(tenant, %{
        product_id: prod2.id,
        sku: "PHONE-128GB-#{System.unique_integer([:positive])}",
        price_cents: 90000
      })

    v3_1 =
      variant_fixture(tenant, %{
        product_id: prod3.id,
        sku: "TSHIRT-S-#{System.unique_integer([:positive])}",
        price_cents: 2000,
        options: %{"size" => "S"}
      })

    v3_2 =
      variant_fixture(tenant, %{
        product_id: prod3.id,
        sku: "TSHIRT-M-#{System.unique_integer([:positive])}",
        price_cents: 2000,
        options: %{"size" => "M"}
      })

    %{
      tenant: tenant,
      categories: [cat1, cat2],
      products: [prod1, prod2, prod3],
      variants: [v1_1, v1_2, v2_1, v2_2, v3_1, v3_2]
    }
  end

  @doc """
  Generates a specific product hierarchy for deterministic E2E search assertions.
  - 1 Tenant
  - 2 Categories ("Smartphones", "Laptops")
  - 3 Products (with specific names like "Quantum CyberPhone X")
  - 4 Variants
  """
  def scenario_e2e_search_catalog(attrs \\ %{}) do
    tenant = tenant_fixture(attrs |> Map.put_new(:name, "E2E Tech Global"))

    cat1 = category_fixture(tenant, %{name: "Smartphones"})
    cat2 = category_fixture(tenant, %{name: "Laptops"})

    # Highly specific product names and descriptions for search assertions
    prod1 =
      product_fixture(tenant, %{
        name: "Quantum CyberPhone X",
        description:
          "The ultimate quantum computing powered smartphone with cybernetic features.",
        category_id: cat1.id
      })

    prod2 =
      product_fixture(tenant, %{
        name: "Quantum CyberPhone Pro",
        description: "Pro version of the cyberphone.",
        category_id: cat1.id
      })

    prod3 =
      product_fixture(tenant, %{
        name: "Nebula Ultrabook",
        description: "A lightweight laptop for stargazers.",
        category_id: cat2.id
      })

    v1_1 =
      variant_fixture(tenant, %{
        product_id: prod1.id,
        sku: "QCP-X-256-#{System.unique_integer([:positive])}",
        price_cents: 99900
      })

    v1_2 =
      variant_fixture(tenant, %{
        product_id: prod1.id,
        sku: "QCP-X-512-#{System.unique_integer([:positive])}",
        price_cents: 109_900
      })

    v2_1 =
      variant_fixture(tenant, %{
        product_id: prod2.id,
        sku: "QCP-PRO-1TB-#{System.unique_integer([:positive])}",
        price_cents: 129_900
      })

    v3_1 =
      variant_fixture(tenant, %{
        product_id: prod3.id,
        sku: "NEB-ULTRA-#{System.unique_integer([:positive])}",
        price_cents: 149_900
      })

    %{
      tenant: tenant,
      categories: [cat1, cat2],
      products: [prod1, prod2, prod3],
      variants: [v1_1, v1_2, v2_1, v3_1]
    }
  end

  @doc """
  Generates a richer click-around demo catalog while preserving the deterministic
  product names used by the E2E lane.
  """
  def scenario_demo_showcase(attrs \\ %{}) do
    tenant = tenant_fixture(attrs |> Map.put_new(:name, "Nova Outfitters"))

    {categories, products, variants} =
      Enum.reduce(@demo_catalog, {[], [], []}, fn {category_name, product_specs},
                                                  {categories, products, variants} ->
        category = category_fixture(tenant, %{name: category_name})

        {category_products, category_variants} =
          Enum.reduce(product_specs, {[], []}, fn {name, description, variant_specs},
                                                  {products_acc, variants_acc} ->
            product =
              product_fixture(tenant, %{
                name: name,
                description: description,
                category_id: category.id
              })

            created_variants =
              Enum.map(variant_specs, fn {sku, price_cents, options} ->
                variant_fixture(tenant, %{
                  product_id: product.id,
                  sku: "#{sku}-#{tenant.id}",
                  price_cents: price_cents,
                  inventory_count: inventory_count_for(price_cents),
                  options: options
                })
              end)

            {[product | products_acc], variants_acc ++ created_variants}
          end)

        {[category | categories], products ++ Enum.reverse(category_products),
         variants ++ category_variants}
      end)

    %{
      tenant: tenant,
      categories: Enum.reverse(categories),
      products: products,
      variants: variants
    }
  end

  def scenario_demo_sparse(attrs \\ %{}) do
    tenant = tenant_fixture(attrs |> Map.put_new(:name, "Quiet Branch Supply"))
    category = category_fixture(tenant, %{name: "Backroom"})

    product =
      product_fixture(tenant, %{
        name: "Archive Barcode Wand",
        description: "A single low-volume product for empty-state and small-tenant checks.",
        category_id: category.id
      })

    variant =
      variant_fixture(tenant, %{
        product_id: product.id,
        sku: "ARCH-WAND-#{tenant.id}",
        price_cents: 6900,
        inventory_count: 2,
        options: %{"condition" => "refurbished"}
      })

    %{tenant: tenant, categories: [category], products: [product], variants: [variant]}
  end

  defp inventory_count_for(price_cents) when price_cents >= 1_000_00, do: 6
  defp inventory_count_for(price_cents) when price_cents >= 300_00, do: 14
  defp inventory_count_for(_price_cents), do: 42
end
