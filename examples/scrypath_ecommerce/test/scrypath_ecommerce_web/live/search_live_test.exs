defmodule ScrypathEcommerceWeb.SearchLiveTest do
  use ScrypathEcommerceWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import ScrypathEcommerce.CatalogFixtures

  alias Scrypath.Query
  alias ScrypathEcommerce.Catalog.Product

  defmodule SearchBackend do
    @behaviour Scrypath.Backend

    @impl true
    def name, do: :search_live_test

    @impl true
    def index_name(_schema_module, _config), do: "search_live_test_products"

    @impl true
    def upsert_documents(_schema_module, documents, _config) do
      {:ok, Enum.map(documents, & &1.id)}
    end

    @impl true
    def delete_documents(_schema_module, document_ids, _config), do: {:ok, document_ids}

    @impl true
    def search(schema_module, %Query{} = query, _config) do
      if pid = Process.whereis(:search_live_test) do
        send(pid, {:search, schema_module, query})
      end

      {:ok,
       %{
         "hits" => [
           %{
             "id" => 101,
             "name" => "Quantum CyberPhone X",
             "description" => "Pocket quantum processor",
             "category_id" => "1",
             "category_name" => "Smartphones"
           }
         ],
         "facetDistribution" => %{
           "category_id" => %{
             to_string(Application.fetch_env!(:scrypath_ecommerce, :search_live_test_category_id)) =>
               2
           }
         },
         "totalHits" => 1
       }}
    end

    @impl true
    def search_facet_values(_schema_module, _facet_name, facet_query, _opts, _config) do
      {:ok, %{"facetQuery" => facet_query, "facetHits" => []}}
    end
  end

  setup do
    Process.register(self(), :search_live_test)

    defaults = Application.get_env(:scrypath, :defaults, [])
    Application.put_env(:scrypath, :defaults, Keyword.put(defaults, :backend, SearchBackend))

    on_exit(fn ->
      Application.put_env(:scrypath, :defaults, defaults)
      Application.delete_env(:scrypath_ecommerce, :search_live_test_category_id)

      if Process.whereis(:search_live_test) do
        Process.unregister(:search_live_test)
      end
    end)

    tenant = tenant_fixture(name: "Storefront Tenant")
    category = category_fixture(tenant, name: "Smartphones")
    Application.put_env(:scrypath_ecommerce, :search_live_test_category_id, category.id)

    %{tenant: tenant, category: category}
  end

  test "hydrates URL params into tenant-scoped Scrypath search", %{
    conn: conn,
    tenant: tenant,
    category: category
  } do
    assert {:ok, _view, html} = live(conn, ~p"/?q=cyber&category_id=#{category.id}")

    assert html =~ "Quantum CyberPhone X"

    assert_receive {:search, Product,
                    %Query{
                      text: "cyber",
                      filter: [tenant_id: tenant_id, category_id: category_id],
                      facets: [:category_id]
                    }}

    assert tenant_id == tenant.id
    assert category_id == category.id
  end

  test "search form pushes URL patches instead of searching directly", %{
    conn: conn,
    tenant: tenant,
    category: category
  } do
    assert {:ok, view, _html} = live(conn, ~p"/")
    assert_receive {:search, Product, %Query{text: ""}}

    view
    |> form("form[phx-change='search']",
      search: %{q: "nebula", category_id: to_string(category.id)}
    )
    |> render_change()

    assert_patch(view, "/?category_id=#{category.id}&q=nebula&tenant_id=#{tenant.id}")
  end

  test "renders a unified search form, debounced input, facets, and hits", %{conn: conn} do
    assert {:ok, _view, html} = live(conn, ~p"/?q=quantum")

    assert html =~ ~s(<form)
    assert html =~ ~s(phx-change="search")
    assert html =~ ~s(name="search[tenant_id]")
    assert html =~ ~s(name="search[q]")
    assert html =~ ~s(phx-debounce="300")
    assert html =~ ~s(name="search[category_id]")
    assert html =~ ~s(type="checkbox")
    assert html =~ "Storefront Tenant"
    assert html =~ "Smartphones"
    assert html =~ "2 products"
    assert html =~ "Quantum CyberPhone X"
    assert html =~ "Operator posture"
    assert html =~ ~s(data-testid="storefront-results")
    assert html =~ ~s(data-testid="storefront-result")
    assert html =~ "Category"
  end
end
