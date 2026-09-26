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

  defmodule NonTenantPost do
    use Ecto.Schema

    use Scrypath,
      fields: [:title, :status, :category],
      filterable: [:status, :category],
      faceting: [attributes: [:category], max_values_per_facet: 100]

    embedded_schema do
      field(:title, :string)
      field(:status, :string)
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

  test "search_many/2 applies shared tenant scope with an ordinary filter" do
    assert {:ok,
            %Scrypath.MultiSearchResult{
              ordered: [{TenantPost, %SearchResult{query: %Query{filter: filter}}}],
              failures: []
            }} =
             Scrypath.search_many([{TenantPost, "ecto"}],
               backend: RecordingBackend,
               tenant_scope: 123,
               filter: [status: "published"]
             )

    expected = [tenant_id: 123, status: "published"]
    assert MapSet.new(filter) == MapSet.new(expected)
    assert_receive {:tenant_search, TenantPost, %Query{filter: recorded_filter}}
    assert MapSet.new(recorded_filter) == MapSet.new(expected)
  end

  test "search_many/2 applies tenant scope from an entry while preserving shared options" do
    assert {:ok,
            %Scrypath.MultiSearchResult{
              ordered: [{TenantPost, %SearchResult{query: %Query{filter: filter}}}],
              failures: []
            }} =
             Scrypath.search_many(
               [{TenantPost, "ecto", [tenant_scope: 123, filter: [status: "published"]]}],
               backend: RecordingBackend
             )

    expected = [tenant_id: 123, status: "published"]
    assert MapSet.new(filter) == MapSet.new(expected)
    assert_receive {:tenant_search, TenantPost, %Query{filter: recorded_filter}}
    assert MapSet.new(recorded_filter) == MapSet.new(expected)
  end

  test "search_facet_values/4 composes tenant scope with an ordinary filter" do
    assert {:ok,
            %Scrypath.FacetSearchResult{
              facet_query: "pho",
              hits: []
            }} =
             Scrypath.search_facet_values(TenantPost, "category", "pho",
               backend: RecordingBackend,
               tenant_scope: 123,
               filter: [status: "published"]
             )

    assert_receive {:tenant_facet_search, TenantPost, "category", "pho", opts}

    assert MapSet.new(Keyword.fetch!(opts, :filter)) ==
             MapSet.new(tenant_id: 123, status: "published")
  end

  test "all public search paths preserve tenant scope with omitted and empty filters" do
    for path <- [:single, :many, :facet], filter_option <- [:omitted, []] do
      opts = [backend: RecordingBackend, tenant_scope: 123]

      opts =
        if filter_option == :omitted, do: opts, else: Keyword.put(opts, :filter, filter_option)

      expected = [tenant_id: 123]

      result = call_public_path(path, opts)
      assert_public_filter(path, result, expected)
      assert_recorded_filter(path, expected)
    end
  end

  test "single and facet search reject equal and conflicting tenant filter collisions before dispatch" do
    for path <- [:single, :facet], tenant_value <- [123, 456] do
      assert_raise ArgumentError, ~r/already contains the tenant_field/, fn ->
        call_public_path(path,
          backend: RecordingBackend,
          tenant_scope: 123,
          filter: [tenant_id: tenant_value]
        )
      end
    end

    refute_receive {:tenant_search, _, _}
    refute_receive {:tenant_facet_search, _, _, _, _}
  end

  test "single and facet search reject undeclared tenant scope before dispatch" do
    for path <- [:single, :facet] do
      assert_raise ArgumentError, ~r/does not declare a tenant_field:/, fn ->
        call_public_path(path,
          backend: RecordingBackend,
          tenant_scope: 123,
          schema: NonTenantPost
        )
      end
    end

    refute_receive {:tenant_search, _, _}
    refute_receive {:tenant_facet_search, _, _, _, _}
  end

  test "search_many/2 rejects collisions and undeclared scope before dispatch" do
    for tenant_value <- [123, 456] do
      assert {:error, {:validation_failed, TenantPost, {:validation, message}}} =
               Scrypath.search_many(
                 [{TenantPost, "ecto", [tenant_scope: 123, filter: [tenant_id: tenant_value]]}],
                 backend: RecordingBackend
               )

      assert message =~ "already contains the tenant_field"
    end

    assert {:error, {:validation_failed, NonTenantPost, {:validation, message}}} =
             Scrypath.search_many([{NonTenantPost, "ecto", [tenant_scope: 123]}],
               backend: RecordingBackend
             )

    assert message =~ "does not declare a tenant_field:"
    refute_receive {:tenant_search, _, _}
  end

  test "search_many/2 preflights every entry before dispatching any search" do
    assert {:error, {:validation_failed, TenantPost, {:validation, message}}} =
             Scrypath.search_many(
               [
                 {TenantPost, "valid"},
                 {TenantPost, "invalid", [tenant_scope: 123, filter: [tenant_id: 456]]}
               ],
               backend: RecordingBackend
             )

    assert message =~ "already contains the tenant_field"
    refute_receive {:tenant_search, _, _}
  end

  defp call_public_path(:single, opts) do
    schema = Keyword.get(opts, :schema, TenantPost)
    opts = Keyword.delete(opts, :schema)
    Scrypath.search(schema, "ecto", opts)
  end

  defp call_public_path(:many, opts) do
    Scrypath.search_many([{TenantPost, "ecto"}], opts)
  end

  defp call_public_path(:facet, opts) do
    schema = Keyword.get(opts, :schema, TenantPost)
    opts = Keyword.delete(opts, :schema)
    Scrypath.search_facet_values(schema, "category", "pho", opts)
  end

  defp assert_public_filter(
         :single,
         {:ok, %SearchResult{query: %Query{filter: filter}}},
         expected
       ),
       do: assert(MapSet.new(filter) == MapSet.new(expected))

  defp assert_public_filter(
         :many,
         {:ok,
          %Scrypath.MultiSearchResult{
            ordered: [{TenantPost, %SearchResult{query: %Query{filter: filter}}}]
          }},
         expected
       ),
       do: assert(MapSet.new(filter) == MapSet.new(expected))

  defp assert_public_filter(:facet, {:ok, %Scrypath.FacetSearchResult{}}, _expected), do: :ok

  defp assert_recorded_filter(:single, expected) do
    assert_receive {:tenant_search, TenantPost, %Query{filter: filter}}
    assert MapSet.new(filter) == MapSet.new(expected)
  end

  defp assert_recorded_filter(:many, expected) do
    assert_receive {:tenant_search, TenantPost, %Query{filter: filter}}
    assert MapSet.new(filter) == MapSet.new(expected)
  end

  defp assert_recorded_filter(:facet, expected) do
    assert_receive {:tenant_facet_search, TenantPost, "category", "pho", opts}
    assert MapSet.new(Keyword.fetch!(opts, :filter)) == MapSet.new(expected)
  end
end
