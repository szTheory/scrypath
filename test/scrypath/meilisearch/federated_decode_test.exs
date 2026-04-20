defmodule Scrypath.Meilisearch.FederatedDecodeTest do
  use ExUnit.Case, async: true

  alias Scrypath.Meilisearch.FederatedDecode

  defmodule SlugDoc do
    @moduledoc false
    use Ecto.Schema

    use Scrypath,
      fields: [:title],
      document_id: :slug

    embedded_schema do
      field(:title, :string)
      field(:slug, :string)
    end
  end

  @posts_uid "scrypath_searchable_post"
  @movies_uid "scrypath_facetable_movie"
  @slug_uid "scrypath_slug_doc"

  test "merge_hit_order preserves flat hits and resolves schemas" do
    indexed = [{SearchablePost, @posts_uid}, {FacetableMovie, @movies_uid}]

    raw = %{
      "hits" => [
        %{"id" => 9, "_federation" => %{"indexUid" => @movies_uid}},
        %{"id" => 2, "_federation" => %{"indexUid" => @posts_uid}}
      ]
    }

    assert {:ok, [{FacetableMovie, 9}, {SearchablePost, 2}]} ==
             FederatedDecode.merge_hit_order(raw, indexed)
  end

  test "merge_hit_order falls back to configured document_id field" do
    indexed = [{SlugDoc, @slug_uid}]

    raw = %{
      "hits" => [
        %{
          "slug" => "abc-1",
          "title" => "Hi",
          "_federation" => %{"indexUid" => @slug_uid}
        }
      ]
    }

    assert {:ok, [{SlugDoc, "abc-1"}]} == FederatedDecode.merge_hit_order(raw, indexed)
  end

  test "merge_hit_order rejects results-array shape" do
    indexed = [{SearchablePost, @posts_uid}]

    raw = %{
      "results" => [%{"hits" => []}]
    }

    assert {:error, {:federated_decode, :not_flat_federated}} ==
             FederatedDecode.merge_hit_order(raw, indexed)
  end

  test "merge_hit_order errors on unknown index uid" do
    indexed = [{SearchablePost, @posts_uid}]

    raw = %{
      "hits" => [
        %{"id" => 1, "_federation" => %{"indexUid" => "unknown_idx"}}
      ]
    }

    assert {:error, {:federated_decode, {:unknown_index_uid, "unknown_idx"}}} ==
             FederatedDecode.merge_hit_order(raw, indexed)
  end
end
