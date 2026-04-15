defmodule Scrypath.SchemaTest do
  use ExUnit.Case, async: true

  describe "__scrypath__/1" do
    test "returns normalized schema metadata" do
      assert SearchablePost.__scrypath__(:config) == %{
               fields: [:title, :body],
               filterable: [:status],
               sortable: [:inserted_at],
               document_id: :id,
               document_source: :fields,
               index_prefix: nil,
               backend: nil
             }

      assert SearchablePost.__scrypath__(:fields) == [:title, :body]
      assert SearchablePost.__scrypath__(:document_id) == :id
      assert Scrypath.schema_config(SearchablePost) == SearchablePost.__scrypath__(:config)
      assert Scrypath.schema_fields(SearchablePost) == [:title, :body]
      assert Scrypath.document_source(SearchablePost) == :fields
      assert Scrypath.document_id_field(SearchablePost) == :id
    end

    test "does not generate runtime search APIs on the schema" do
      assert function_exported?(SearchablePost, :search, 2) == false
    end

    test "rejects unknown declaration options" do
      assert_raise ArgumentError, ~r/unknown options/, fn ->
        Code.compile_string("""
        defmodule InvalidSearchablePostUnknown do
          use Ecto.Schema
          use Scrypath, fields: [:title], mystery: true

          embedded_schema do
            field :title, :string
          end
        end
        """)
      end
    end

    test "rejects invalid declaration values" do
      assert_raise ArgumentError, ~r/fields must contain at least one field/, fn ->
        Code.compile_string("""
        defmodule InvalidSearchablePostFields do
          use Ecto.Schema
          use Scrypath, fields: []

          embedded_schema do
            field :title, :string
          end
        end
        """)
      end
    end
  end
end
