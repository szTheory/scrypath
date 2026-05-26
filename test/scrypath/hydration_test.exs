defmodule Scrypath.HydrationTest do
  use ExUnit.Case, async: true

  alias Scrypath.SearchResult
  alias Scrypath.TestSupport.FakeRepo

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
    def search(_schema_module, _query, _config) do
      {:ok,
       %{
         "hits" => [
           %{"id" => 2, "title" => "Second"},
           %{"id" => 1, "title" => "First"},
           %{"id" => 3, "title" => "Missing"}
         ],
         "page" => 1,
         "hitsPerPage" => 3,
         "totalHits" => 3
       }}
    end

    @impl true
    def search_facet_values(_schema, _facet, _query, _opts, _config) do
      {:error, :not_implemented}
    end
  end

  setup do
    FakeRepo.reset()
    :ok
  end

  test "one batch query hydrates records, restores hit order, and preserves missing ids" do
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

    assert_received {:fake_repo_all, %Ecto.Query{} = query}
    assert query.preloads == []
  end

  test "explicit preload is applied only to the hydration query" do
    FakeRepo.put_records([
      %QueryablePost{id: 2, title: "Second", author: %QueryableAuthor{id: 10, name: "Ada"}},
      %QueryablePost{id: 1, title: "First", author: %QueryableAuthor{id: 11, name: "Grace"}}
    ])

    assert {:ok, %SearchResult{records: [%QueryablePost{id: 2}, %QueryablePost{id: 1}]}} =
             Scrypath.search(QueryablePost, "ecto",
               backend: HydrationBackend,
               repo: FakeRepo,
               preload: [:author]
             )

    assert_received {:fake_repo_all, %Ecto.Query{} = query}
    assert query.preloads == [:author]
  end
end
