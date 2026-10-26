defmodule Scrypath.SchemaTest do
  use ExUnit.Case, async: true

  def resolve_fan_out(_records), do: []

  describe "__scrypath__/1" do
    test "returns normalized schema metadata" do
      assert SearchablePost.__scrypath__(:config) == %{
               fields: [:title, :body],
               filterable: [:status],
               faceting: [],
               sortable: [:inserted_at],
               fan_outs: [],
               settings: %{__unrecognized__: %{}},
               document_id: :id,
               document_source: :fields,
               index_prefix: nil,
               backend: nil,
               tenant_field: nil,
               preload: []
             }

      assert SearchablePost.__scrypath__(:fields) == [:title, :body]
      assert SearchablePost.__scrypath__(:faceting) == []
      assert SearchablePost.__scrypath__(:fan_outs) == []
      assert SearchablePost.__scrypath__(:document_id) == :id
      assert Scrypath.schema_config(SearchablePost) == SearchablePost.__scrypath__(:config)
      assert Scrypath.schema_fields(SearchablePost) == [:title, :body]
      assert Scrypath.schema_settings(SearchablePost) == %{__unrecognized__: %{}}
      assert Scrypath.document_source(SearchablePost) == :fields
      assert Scrypath.document_id_field(SearchablePost) == :id
    end

    test "reflects tenant_field if declared" do
      [{mod, _}] =
        Code.compile_string("""
        defmodule TenantFieldSchemaTest do
          use Scrypath, fields: [:title], tenant_field: :account_id
        end
        """)

      assert mod.__scrypath__(:tenant_field) == :account_id
    end

    test "returns nil for tenant_field if omitted" do
      assert SearchablePost.__scrypath__(:tenant_field) == nil
    end

    test "reflects declared fan_outs metadata" do
      [{mod, _}] =
        Code.compile_string("""
        defmodule FanOutSchemaTest.Source do
          use Scrypath,
            fields: [:name],
            fan_outs: [
              comments: [
                target: SearchablePost,
                resolver: {Scrypath.SchemaTest, :resolve_fan_out, []}
              ]
            ]
        end
        """)

      assert mod.__scrypath__(:fan_outs) == [
               comments: [
                 target: SearchablePost,
                 resolver: {Scrypath.SchemaTest, :resolve_fan_out, []}
               ]
             ]
    end

    test "stores and reflects declared settings metadata" do
      assert ConfiguredSearchablePost.__scrypath__(:settings) == %{
               searchable_attributes: ["title", "body"],
               typo_tolerance: [enabled: true],
               __unrecognized__: %{}
             }

      assert ConfiguredSearchablePost.__scrypath__(:config).settings == %{
               searchable_attributes: ["title", "body"],
               typo_tolerance: [enabled: true],
               __unrecognized__: %{}
             }

      assert Scrypath.schema_settings(ConfiguredSearchablePost) == %{
               searchable_attributes: ["title", "body"],
               typo_tolerance: [enabled: true],
               __unrecognized__: %{}
             }
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

    test "rejects invalid settings declarations during compilation" do
      assert_raise ArgumentError, ~r/settings/, fn ->
        Code.compile_string("""
        defmodule InvalidSearchablePostSettings do
          use Ecto.Schema
          use Scrypath, fields: [:title], settings: [:invalid]

          embedded_schema do
            field :title, :string
          end
        end
        """)
      end
    end
  end

  describe "hook contract" do
    @hooks [search_document: 1, search_document_id: 1, search_records: 2]

    test "declares the three hooks as optional callbacks" do
      assert Enum.sort(Scrypath.Schema.behaviour_info(:optional_callbacks)) == @hooks
      assert Enum.sort(Scrypath.Schema.behaviour_info(:callbacks)) == @hooks
    end

    test "use Scrypath injects @behaviour Scrypath.Schema" do
      behaviours =
        SearchablePost.module_info(:attributes)
        |> Keyword.get_values(:behaviour)
        |> List.flatten()

      assert Scrypath.Schema in behaviours
    end

    test "documents every hook callback" do
      {:docs_v1, _, _, _, _, _, entries} = Code.fetch_docs(Scrypath.Schema)

      for {name, arity} <- @hooks do
        assert {{:callback, ^name, ^arity}, _anno, _sig, %{"en" => doc}, _meta} =
                 List.keyfind(entries, {:callback, name, arity}, 0),
               "missing callback docs for #{name}/#{arity}"

        assert String.trim(doc) != ""
      end
    end

    test "warns at the def line when a hook has the wrong arity" do
      {_result, diagnostics} =
        Code.with_diagnostics(fn ->
          Code.compile_string("""
          defmodule Scrypath.SchemaHookArityFixture do
            use Scrypath, fields: [:title]

            def search_records(ids), do: ids
          end
          """)
        end)

      assert [diagnostic] = diagnostics
      assert diagnostic.severity == :warning
      assert diagnostic.message =~ "search_records/1"
      assert diagnostic.message =~ "search_records/2"
      assert position_line(diagnostic.position) == 4
    end

    test "stays silent when a hook has the expected arity" do
      {_result, diagnostics} =
        Code.with_diagnostics(fn ->
          Code.compile_string("""
          defmodule Scrypath.SchemaHookOkFixture do
            use Scrypath, fields: [:title]

            def search_records(ids, _context), do: ids
          end
          """)
        end)

      assert diagnostics == []
    end
  end

  defp position_line({line, _column}), do: line
  defp position_line(line) when is_integer(line), do: line
end
