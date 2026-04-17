defmodule Scrypath.BackendTest do
  use ExUnit.Case, async: false

  alias Scrypath.Document
  alias Scrypath.Query
  alias Scrypath.TestSupport.FakeBackend

  setup do
    original_defaults = Application.get_env(:scrypath, :defaults)

    on_exit(fn ->
      if original_defaults == nil do
        Application.delete_env(:scrypath, :defaults)
      else
        Application.put_env(:scrypath, :defaults, original_defaults)
      end
    end)

    :ok
  end

  test "Scrypath.Config.resolve! prefers explicit backend over app defaults" do
    Application.put_env(:scrypath, :defaults,
      backend: FakeBackend,
      index_prefix: "default",
      sync_mode: :manual
    )

    config =
      Scrypath.Config.resolve!(
        backend: Scrypath.TestSupport.FakeBackend,
        index_prefix: "explicit",
        sync_mode: :inline
      )

    assert config[:backend] == Scrypath.TestSupport.FakeBackend
    assert config[:index_prefix] == "explicit"
    assert config[:sync_mode] == :inline
    assert Scrypath.Config.fetch_backend!(config) == Scrypath.TestSupport.FakeBackend
  end

  test "fake backend satisfies the behaviour contract" do
    documents = [
      %Document{id: 1, data: %{title: "Hello"}, source: :fields},
      %Document{id: 2, data: %{title: "World"}, source: :custom}
    ]

    assert FakeBackend.name() == :fake

    assert FakeBackend.index_name(SearchablePost, index_prefix: "tenant") ==
             "tenant_searchable_post"

    assert FakeBackend.upsert_documents(SearchablePost, documents, []) == {:ok, [1, 2]}
    assert FakeBackend.delete_documents(SearchablePost, [1, 2], []) == {:ok, [1, 2]}

    query = %Query{text: "hello", filter: [], sort: [], page: %{}, facets: [], facet_filter: []}

    assert {:ok,
            %{
              query: ^query,
              hits: [],
              page: 1,
              hitsPerPage: 20,
              totalHits: 0,
              normalized_query?: true
            }} = FakeBackend.search(SearchablePost, query, [])
  end
end
