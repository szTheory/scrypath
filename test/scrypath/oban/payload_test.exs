defmodule Scrypath.Oban.PayloadTest do
  use ExUnit.Case, async: true

  alias Scrypath.Document
  alias Scrypath.Oban.Payload

  defmodule RecordingBackend do
    @behaviour Scrypath.Backend

    @impl true
    def name, do: :recording

    @impl true
    def index_name(schema_module, config) do
      prefix = Keyword.get(config, :index_prefix, "scrypath")
      schema_name = schema_module |> Module.split() |> List.last() |> Macro.underscore()

      "#{prefix}_#{schema_name}"
    end

    @impl true
    def upsert_documents(_schema_module, _documents, _config), do: {:ok, %{}}

    @impl true
    def delete_documents(_schema_module, _document_ids, _config), do: {:ok, %{}}

    @impl true
    def search(_schema_module, _query, _config), do: {:ok, %{hits: []}}

    @impl true
    def search_facet_values(_schema, _facet, _query, _opts, _config) do
      {:error, :not_implemented}
    end
  end

  defmodule CustomProjectedPost do
    use Ecto.Schema

    use Scrypath, fields: [:title], document_id: :external_id

    embedded_schema do
      field(:external_id, :string)
      field(:title, :string)
    end

    def search_document(%__MODULE__{} = post) do
      %{
        id: post.external_id,
        title: post.title,
        metadata: %{
          state: :published,
          counts: %{"comments" => 3}
        }
      }
    end
  end

  test "build_upsert/3 serializes projected batches into JSON-safe worker args" do
    documents = [
      %Document{
        id: 1,
        data: %{title: "One", metadata: %{state: :published, counts: %{"comments" => 3}}},
        source: :fields
      },
      %Document{
        id: 2,
        data: %{title: "Two", metadata: %{state: :draft, counts: %{"comments" => 1}}},
        source: :custom
      }
    ]

    payload =
      Payload.build_upsert(SearchablePost, documents,
        backend: RecordingBackend,
        index_prefix: "tenant",
        sync_mode: :oban
      )

    assert payload == %{
             "operation" => "upsert",
             "schema" => "Elixir.SearchablePost",
             "backend" => "Elixir.Scrypath.Oban.PayloadTest.RecordingBackend",
             "index" => "tenant_searchable_post",
             "index_prefix" => "tenant",
             "sync_mode" => "oban",
             "document_count" => 2,
             "document_ids" => [1, 2],
             "documents" => [
               %{
                 "id" => 1,
                 "data" => %{
                   "title" => "One",
                   "metadata" => %{"state" => "published", "counts" => %{"comments" => 3}}
                 },
                 "source" => "fields"
               },
               %{
                 "id" => 2,
                 "data" => %{
                   "title" => "Two",
                   "metadata" => %{"state" => "draft", "counts" => %{"comments" => 1}}
                 },
                 "source" => "custom"
               }
             ]
           }
  end

  test "build_delete/3 serializes resolved ids and preserves caller batch boundaries" do
    payload =
      Payload.build_delete(SearchablePost, ["post:1", "post:2", "post:3"],
        backend: RecordingBackend,
        index_prefix: "tenant",
        sync_mode: :oban
      )

    assert payload == %{
             "operation" => "delete",
             "schema" => "Elixir.SearchablePost",
             "backend" => "Elixir.Scrypath.Oban.PayloadTest.RecordingBackend",
             "index" => "tenant_searchable_post",
             "index_prefix" => "tenant",
             "sync_mode" => "oban",
             "document_count" => 3,
             "document_ids" => ["post:1", "post:2", "post:3"]
           }

    refute Map.has_key?(payload, "documents")
  end

  test "build_upsert/3 never persists the Meilisearch API key" do
    payload =
      Payload.build_upsert(SearchablePost, [],
        backend: RecordingBackend,
        sync_mode: :oban,
        meilisearch_url: "https://search.example.test",
        meilisearch_api_key: "secret-key"
      )

    assert payload["meilisearch_url"] == "https://search.example.test"
    refute Map.has_key?(payload, "meilisearch_api_key")
    refute inspect(payload) =~ "secret-key"
  end

  test "build_upsert/3 rejects structs and unsupported nested values" do
    bad_documents = [
      %Document{
        id: "post-1",
        data: %{title: "Bad", author: %CustomProjectedPost{external_id: "post-1", title: "Bad"}},
        source: :custom
      }
    ]

    assert_raise ArgumentError,
                 "oban payloads only support JSON-safe values, got struct Scrypath.Oban.PayloadTest.CustomProjectedPost",
                 fn ->
                   Payload.build_upsert(CustomProjectedPost, bad_documents,
                     backend: RecordingBackend,
                     sync_mode: :oban
                   )
                 end
  end
end
