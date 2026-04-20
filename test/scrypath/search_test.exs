defmodule Scrypath.SearchTest do
  use ExUnit.Case, async: true

  alias Scrypath.Query
  alias Scrypath.SearchResult
  alias Scrypath.TestSupport.FakeRepo

  defmodule ErrorBackend do
    @behaviour Scrypath.Backend

    @impl true
    def name, do: :error

    @impl true
    def index_name(_schema_module, _config), do: "error_backend"

    @impl true
    def upsert_documents(_schema_module, _documents, _config), do: {:ok, []}

    @impl true
    def delete_documents(_schema_module, _document_ids, _config), do: {:ok, []}

    @impl true
    def search(_schema_module, _query, _config), do: {:error, :search_failed}
  end

  defmodule HydrationBackend do
    @behaviour Scrypath.Backend

    @impl true
    def name, do: :hydration

    @impl true
    def index_name(_schema_module, _config), do: "hydration_backend"

    @impl true
    def upsert_documents(_schema_module, _documents, _config), do: {:ok, []}

    @impl true
    def delete_documents(_schema_module, _document_ids, _config), do: {:ok, []}

    @impl true
    def search(_schema_module, query, _config) do
      {:ok,
       %{
         "hits" => [
           %{"id" => 2, "title" => "Second"},
           %{"id" => 1, "title" => "First"},
           %{"id" => 3, "title" => "Missing"}
         ],
         "query" => query,
         "page" => 2,
         "hitsPerPage" => 3,
         "totalHits" => 3
       }}
    end
  end

  setup do
    FakeRepo.reset()
    :ok
  end

  test "Scrypath.search/3 delegates through the common search path" do
    assert {:ok,
            %SearchResult{
              hits: [],
              query: %Query{
                text: "ecto",
                filter: [],
                sort: [],
                page: %{},
                facets: [],
                facet_filter: [],
                per_query: %{}
              },
              facets: %Scrypath.SearchResult.Facets{}
            }} =
             Scrypath.search(SearchablePost, "ecto", backend: Scrypath.TestSupport.FakeBackend)
  end

  test "Scrypath.search!/3 returns successful results and raises on backend errors" do
    assert %SearchResult{
             hits: [],
             query: %Query{text: "ecto", facets: [], facet_filter: [], per_query: %{}}
           } =
             Scrypath.search!(SearchablePost, "ecto", backend: Scrypath.TestSupport.FakeBackend)

    assert_raise RuntimeError, "search failed: :search_failed", fn ->
      Scrypath.search!(SearchablePost, "ecto", backend: ErrorBackend)
    end
  end

  test "the common path normalizes text and public options into one query struct" do
    assert {:ok,
            %SearchResult{
              query: %Query{
                text: "phoenix",
                filter: [status: "published"],
                sort: [desc: :inserted_at],
                page: %{number: 2, size: 20},
                facets: [],
                facet_filter: [],
                per_query: %{}
              }
            }} =
             Scrypath.search(SearchablePost, "phoenix",
               backend: Scrypath.TestSupport.FakeBackend,
               filter: [status: "published"],
               sort: [desc: :inserted_at],
               page: [number: 2, size: 20]
             )
  end

  test "structured filters accept only declared filterable fields" do
    assert_raise ArgumentError, ~r/filterable/, fn ->
      Scrypath.search(SearchablePost, "ecto",
        backend: Scrypath.TestSupport.FakeBackend,
        filter: [title: "ecto"]
      )
    end
  end

  test "structured sort accepts only declared sortable fields and preserves ecto-style input" do
    assert {:ok,
            %SearchResult{
              query: %Query{
                sort: [desc: :inserted_at],
                facets: [],
                facet_filter: [],
                per_query: %{}
              }
            }} =
             Scrypath.search(SearchablePost, "ecto",
               backend: Scrypath.TestSupport.FakeBackend,
               sort: [desc: :inserted_at]
             )

    assert_raise ArgumentError, ~r/sortable/, fn ->
      Scrypath.search(SearchablePost, "ecto",
        backend: Scrypath.TestSupport.FakeBackend,
        sort: [asc: :title]
      )
    end
  end

  test "page validates nested number and size and rejects loose top-level pagination options" do
    assert_raise ArgumentError, ~r/page number/, fn ->
      Scrypath.search(SearchablePost, "ecto",
        backend: Scrypath.TestSupport.FakeBackend,
        page: [number: 0, size: 20]
      )
    end

    assert_raise ArgumentError, ~r/page size/, fn ->
      Scrypath.search(SearchablePost, "ecto",
        backend: Scrypath.TestSupport.FakeBackend,
        page: [number: 1, size: 0]
      )
    end

    assert_raise ArgumentError, ~r/unknown options \[:number, :size\]/, fn ->
      Scrypath.search(SearchablePost, "ecto",
        backend: Scrypath.TestSupport.FakeBackend,
        number: 2,
        size: 20
      )
    end
  end

  test "unsupported boolean composition is rejected on the common path" do
    assert_raise ArgumentError, ~r/boolean composition/, fn ->
      Scrypath.search(SearchablePost, "ecto",
        backend: Scrypath.TestSupport.FakeBackend,
        filter: [or: [[status: "draft"], [status: "published"]]]
      )
    end
  end

  test "common search returns one stable result struct with raw hits and pagination metadata" do
    assert {:ok,
            %SearchResult{
              hits: [%{"id" => 2}, %{"id" => 1}, %{"id" => 3}],
              raw: %{"query" => %Query{text: "ecto", per_query: %{}}},
              page: %{number: 2, size: 3, total_hits: 3}
            }} =
             Scrypath.search(QueryablePost, "ecto", backend: HydrationBackend)
  end

  test "hydration requires explicit repo input on the common path" do
    assert {:ok, %SearchResult{records: [], missing_ids: []}} =
             Scrypath.search(QueryablePost, "ecto", backend: HydrationBackend)

    refute_received {:fake_repo_all, _query}
  end

  test "common search hydrates records in hit order and surfaces missing ids" do
    FakeRepo.put_records([
      %QueryablePost{id: 1, title: "First"},
      %QueryablePost{id: 2, title: "Second"}
    ])

    assert {:ok,
            %SearchResult{
              records: [%QueryablePost{id: 2}, %QueryablePost{id: 1}],
              missing_ids: [3]
            }} =
             Scrypath.search(QueryablePost, "ecto",
               backend: HydrationBackend,
               repo: FakeRepo
             )
  end

  test "common path rejects backend-native filter strings and raw payloads" do
    assert_raise ArgumentError, ~r/filter to be a keyword list/, fn ->
      Scrypath.search(SearchablePost, "ecto",
        backend: Scrypath.TestSupport.FakeBackend,
        filter: "status = published"
      )
    end

    assert_raise ArgumentError, ~r/sort to be a keyword list/, fn ->
      Scrypath.search(SearchablePost, "ecto",
        backend: Scrypath.TestSupport.FakeBackend,
        sort: ["inserted_at:desc"]
      )
    end
  end

  test "non-declared facet request returns unknown_facet error tuple" do
    assert {:error, {:unknown_facet, :not_declared}} =
             Scrypath.search(FacetableMovie, "x",
               backend: Scrypath.TestSupport.FakeBackend,
               facets: [:not_declared]
             )
  end

  test "facetDistribution and facetStats decode into SearchResult.facets" do
    assert {:ok, %SearchResult{facets: facets}} =
             Scrypath.search(FacetableMovie, "x",
               backend: Scrypath.TestSupport.FakeBackend,
               facets: [:genre]
             )

    assert facets.declared_order == [:genre]
    assert [%Scrypath.SearchResult.Facets.Bucket{} | _] = facets.distribution[:genre]
    assert facets.stats[:genre][:min] == 1
    assert facets.stats[:genre][:max] == 10
  end

  test "facetDistribution decodes hierarchical dotted facet attribute keys" do
    assert {:ok, %SearchResult{facets: facets}} =
             Scrypath.search(FacetableHierarchy, "x",
               backend: Scrypath.TestSupport.FakeBackend,
               facets: [:"categories.lvl0", :"categories.lvl1"]
             )

    assert facets.declared_order == [:"categories.lvl0", :"categories.lvl1"]
    assert [%Scrypath.SearchResult.Facets.Bucket{} | _] = facets.distribution[:"categories.lvl0"]
    assert [%Scrypath.SearchResult.Facets.Bucket{} | _] = facets.distribution[:"categories.lvl1"]
    assert facets.stats[:"categories.lvl0"][:min] == 1
  end
end
