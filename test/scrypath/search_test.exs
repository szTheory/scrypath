defmodule Scrypath.SearchTest do
  use ExUnit.Case, async: true

  alias Scrypath.Query

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

  test "Scrypath.search/3 delegates through the common search path" do
    assert {:ok, %{hits: [], query: %Query{text: "ecto", filter: [], sort: [], page: %{}}}} =
             Scrypath.search(SearchablePost, "ecto", backend: Scrypath.TestSupport.FakeBackend)
  end

  test "Scrypath.search!/3 returns successful results and raises on backend errors" do
    assert %{hits: [], query: %Query{text: "ecto"}} =
             Scrypath.search!(SearchablePost, "ecto", backend: Scrypath.TestSupport.FakeBackend)

    assert_raise RuntimeError, "search failed: :search_failed", fn ->
      Scrypath.search!(SearchablePost, "ecto", backend: ErrorBackend)
    end
  end

  test "the common path normalizes text and public options into one query struct" do
    assert {:ok,
            %{
              query: %Query{
                text: "phoenix",
                filter: [status: "published"],
                sort: [desc: :inserted_at],
                page: %{number: 2, size: 20}
              }
            }} =
             Scrypath.search(SearchablePost, "phoenix",
               backend: Scrypath.TestSupport.FakeBackend,
               filter: [status: "published"],
               sort: [desc: :inserted_at],
               page: [number: 2, size: 20]
             )
  end
end
