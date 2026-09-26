defmodule Scrypath.TenantScopeContractTest do
  use ExUnit.Case, async: false

  alias Scrypath.Query
  alias Scrypath.SearchResult

  defmodule TenantPost do
    use Ecto.Schema

    use Scrypath,
      fields: [:title, :status, :tenant_id, :category],
      filterable: [:status, :tenant_id, :category],
      faceting: [attributes: [:category], max_values_per_facet: 100],
      tenant_field: :tenant_id

    embedded_schema do
      field(:title, :string)
      field(:status, :string)
      field(:tenant_id, :integer)
      field(:category, :string)
    end
  end

  defmodule RecordingBackend do
    @behaviour Scrypath.Backend

    @impl true
    def name, do: :tenant_scope_contract

    @impl true
    def index_name(_schema_module, _config), do: "tenant_scope_contract"

    @impl true
    def upsert_documents(_schema_module, _documents, _config), do: {:ok, []}

    @impl true
    def delete_documents(_schema_module, _document_ids, _config), do: {:ok, []}

    @impl true
    def search(schema_module, %Query{} = query, _config) do
      send(self(), {:tenant_search, schema_module, query})

      {:ok,
       %{
         "hits" => [],
         "page" => 1,
         "hitsPerPage" => 20,
         "totalHits" => 0
       }}
    end

    @impl true
    def search_facet_values(schema_module, facet_name, facet_query, opts, _config) do
      send(self(), {:tenant_facet_search, schema_module, facet_name, facet_query, opts})
      {:ok, %{"facetHits" => [], "facetQuery" => facet_query}}
    end
  end

  @tag :tenant_tracer
  test "search/3 composes tenant scope with an ordinary filter before backend dispatch" do
    assert {:ok,
            %SearchResult{
              query: %Query{text: "ecto", filter: filter},
              hits: []
            }} =
             Scrypath.search(TenantPost, "ecto",
               backend: RecordingBackend,
               tenant_scope: 123,
               filter: [status: "published"]
             )

    assert MapSet.new(filter) == MapSet.new(tenant_id: 123, status: "published")
    assert_receive {:tenant_search, TenantPost, %Query{text: "ecto", filter: recorded_filter}}
    assert MapSet.new(recorded_filter) == MapSet.new(tenant_id: 123, status: "published")
  end
end
