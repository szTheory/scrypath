defmodule Scrypath.IdentityTest do
  use ExUnit.Case, async: true

  defmodule CustomIdentityPost do
    use Ecto.Schema

    use Scrypath, fields: [:title], document_id: :external_id

    embedded_schema do
      field(:external_id, :string)
      field(:legacy_id, :string)
      field(:title, :string)
    end

    def search_document_id(%__MODULE__{legacy_id: legacy_id}) when is_binary(legacy_id), do: legacy_id
  end

  defmodule MissingIdentityPost do
    use Ecto.Schema

    use Scrypath, fields: [:title], document_id: :external_id

    embedded_schema do
      field(:title, :string)
    end
  end

  test "document_id/2 returns configured document_id field when no custom hook exists" do
    assert Scrypath.Identity.document_id(SearchablePost, %SearchablePost{id: 123}) == 123
    assert Scrypath.Identity.supports_custom_document_id?(SearchablePost) == false
  end

  test "search_document_id/1 overrides default field resolution" do
    record = %CustomIdentityPost{external_id: "db-123", legacy_id: "legacy-123"}

    assert Scrypath.Identity.document_id(CustomIdentityPost, record) == "legacy-123"
    assert Scrypath.Identity.document_ids(CustomIdentityPost, [record]) == ["legacy-123"]
    assert Scrypath.Identity.supports_custom_document_id?(CustomIdentityPost) == true
  end

  test "raises when the document id cannot be resolved from local input" do
    assert_raise ArgumentError, ~r/external_id/, fn ->
      Scrypath.Identity.document_id(MissingIdentityPost, %MissingIdentityPost{title: "missing"})
    end
  end
end
