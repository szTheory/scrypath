defmodule Scrypath.Operator.IndexContractDriftTest do
  use ExUnit.Case, async: true

  alias Scrypath.Meilisearch.Settings
  alias Scrypath.Operator.IndexContractDrift.Report

  defmodule Product do
    use Ecto.Schema

    use Scrypath,
      fields: [:name, :description, :tenant_id, :category_id],
      filterable: [:category_id, :tenant_id],
      faceting: [attributes: [:category_id]]

    embedded_schema do
      field(:name, :string)
      field(:description, :string)
      field(:tenant_id, :integer)
      field(:category_id, :integer)
    end
  end

  defmodule CustomFaceting do
    use Ecto.Schema

    use Scrypath,
      fields: [:name, :category],
      filterable: [:category],
      faceting: [
        attributes: [:category],
        max_values_per_facet: 25,
        sort_facet_values_by: [category: :count]
      ]

    embedded_schema do
      field(:name, :string)
      field(:category, :string)
    end
  end

  defmodule StubClient do
    @moduledoc false
    def get_settings(_index, _config) do
      case Process.get(:icd_stub_get_settings) do
        nil -> {:error, :stub_not_configured}
        resp -> resp
      end
    end
  end

  defp base_opts do
    [
      backend: Scrypath.Meilisearch,
      sync_mode: :manual,
      index_prefix: "tenant",
      meilisearch_url: "http://localhost:7700",
      meilisearch_client: StubClient
    ]
  end

  defp put_stub(response) do
    Process.put(:icd_stub_get_settings, response)

    on_exit(fn ->
      Process.delete(:icd_stub_get_settings)
    end)
  end

  defp applied_settings(schema_module) do
    declared =
      schema_module
      |> Settings.resolve(Scrypath.Config.resolve!(base_opts()))
      |> Settings.translate_settings()

    Map.merge(
      %{
        "searchableAttributes" => ["*"],
        "filterableAttributes" => [],
        "sortableAttributes" =>
          schema_module.__scrypath__(:sortable) |> Enum.map(&Atom.to_string/1),
        "faceting" => %{
          "maxValuesPerFacet" => 100,
          "sortFacetValuesBy" => %{"*" => "alpha"}
        }
      },
      declared
    )
  end

  describe "index_contract_drift/2 (DRIFT15, OPS15-01)" do
    test "parity: backend defaults satisfy projected fields and undeclared faceting" do
      put_stub({:ok, applied_settings(SearchablePost)})

      assert {:ok, %Report{version: 1, schema: SearchablePost, dimensions: dims}} =
               Scrypath.index_contract_drift(SearchablePost, base_opts())

      assert dims.fields.match
      assert dims.filterable_attributes.match
      assert dims.sortable_attributes.match
      assert dims.faceting.match
      assert dims.settings.match
    end

    test "an explicit applied field list still matches the projected fields" do
      applied =
        applied_settings(SearchablePost)
        |> Map.put("searchableAttributes", ["title", "body"])

      put_stub({:ok, applied})

      assert {:ok, %Report{dimensions: dims}} =
               Scrypath.index_contract_drift(SearchablePost, base_opts())

      assert dims.fields.match
    end

    test "a restricted applied field list still reports missing projected fields" do
      applied =
        applied_settings(SearchablePost)
        |> Map.put("searchableAttributes", ["title"])

      put_stub({:ok, applied})

      assert {:ok, %Report{dimensions: dims}} =
               Scrypath.index_contract_drift(SearchablePost, base_opts())

      refute dims.fields.match
      assert {:only_declared, "body"} in dims.fields.details
    end

    test "fields use the resolved explicit restriction including config overrides" do
      config =
        base_opts()
        |> Scrypath.Config.resolve!()
        |> Keyword.put(:settings, %{searchable_attributes: ["title"]})

      applied =
        applied_settings(ConfiguredSearchablePost)
        |> Map.put("searchableAttributes", ["title"])

      put_stub({:ok, applied})

      assert {:ok, %Report{dimensions: dims}} =
               Scrypath.Operator.IndexContractDrift.build(ConfiguredSearchablePost, config)

      assert dims.fields.match
      assert dims.settings.match
    end

    test "an explicit empty searchable list can disable searching every projected field" do
      config =
        base_opts()
        |> Scrypath.Config.resolve!()
        |> Keyword.put(:settings, %{searchable_attributes: []})

      applied = applied_settings(SearchablePost) |> Map.put("searchableAttributes", [])
      put_stub({:ok, applied})

      assert {:ok, %Report{dimensions: dims}} =
               Scrypath.Operator.IndexContractDrift.build(SearchablePost, config)

      assert dims.fields.match
      assert dims.settings.match
    end

    test "wildcard does not hide a mismatched explicit searchable restriction" do
      applied =
        applied_settings(ConfiguredSearchablePost)
        |> Map.put("searchableAttributes", ["*"])

      put_stub({:ok, applied})

      assert {:ok, %Report{dimensions: dims}} =
               Scrypath.index_contract_drift(ConfiguredSearchablePost, base_opts())

      refute dims.fields.match
      refute dims.settings.match
    end

    test "settings preserve the ranking order of explicitly searchable fields" do
      applied =
        applied_settings(ConfiguredSearchablePost)
        |> Map.put("searchableAttributes", ["body", "title"])

      put_stub({:ok, applied})

      assert {:ok, %Report{dimensions: dims}} =
               Scrypath.index_contract_drift(ConfiguredSearchablePost, base_opts())

      assert dims.fields.match
      refute dims.settings.match

      assert %{
               key: "searchableAttributes",
               declared: ["title", "body"],
               applied: ["body", "title"]
             } in dims.settings.details
    end

    test "settings drift surfaces structured details" do
      config = Scrypath.Config.resolve!(base_opts())

      declared_wire =
        Settings.resolve(ConfiguredSearchablePost, config)
        |> Settings.translate_settings()

      applied = Map.delete(declared_wire, "typoTolerance")
      put_stub({:ok, applied})

      assert {:ok, %Report{dimensions: dims}} =
               Scrypath.index_contract_drift(ConfiguredSearchablePost, base_opts())

      refute dims.settings.match
      assert [%{key: "typoTolerance"} | _] = dims.settings.details
    end

    test "404 from get_settings maps to :index_not_found" do
      put_stub({:error, {:http_error, 404, %{}}})

      assert {:error, :index_not_found} =
               Scrypath.index_contract_drift(SearchablePost, base_opts())
    end

    test "faceting dimension matches for hierarchical dotted facet attributes" do
      put_stub({:ok, applied_settings(FacetableHierarchy)})

      assert {:ok, %Report{dimensions: dims}} =
               Scrypath.index_contract_drift(FacetableHierarchy, base_opts())

      assert dims.faceting.match
      assert dims.settings.match
    end

    test "facet membership uses filterables while allowing a tenant-only filterable" do
      put_stub({:ok, applied_settings(Product)})

      assert {:ok, %Report{dimensions: dims}} =
               Scrypath.index_contract_drift(Product, base_opts())

      assert Enum.all?(dims, fn {_name, dimension} -> dimension.match end)
    end

    test "a missing declared facet remains drift even when faceting defaults match" do
      applied = applied_settings(Product) |> Map.put("filterableAttributes", ["tenant_id"])
      put_stub({:ok, applied})

      assert {:ok, %Report{dimensions: dims}} =
               Scrypath.index_contract_drift(Product, base_opts())

      refute dims.faceting.match
      refute dims.filterable_attributes.match
      refute dims.settings.match

      assert [%{declared: %{"attributes" => ["category_id"]}, applied: %{"attributes" => []}}] =
               dims.faceting.details
    end

    test "filterable feature differences remain settings drift" do
      applied =
        applied_settings(Product)
        |> update_in(["filterableAttributes"], fn entries ->
          Enum.map(entries, fn
            %{} = entry -> put_in(entry, ["features", "facetSearch"], false)
            entry -> entry
          end)
        end)

      put_stub({:ok, applied})

      assert {:ok, %Report{dimensions: dims}} =
               Scrypath.index_contract_drift(Product, base_opts())

      assert dims.filterable_attributes.match
      refute dims.settings.match
      assert [%{key: "filterableAttributes"}] = dims.settings.details
    end

    test "nondefault faceting limits and ordering remain drift" do
      for {key, value} <- [
            {"maxValuesPerFacet", 25},
            {"sortFacetValuesBy", %{"*" => "count"}}
          ] do
        applied = applied_settings(Product) |> put_in(["faceting", key], value)
        put_stub({:ok, applied})

        assert {:ok, %Report{dimensions: dims}} =
                 Scrypath.index_contract_drift(Product, base_opts())

        refute dims.faceting.match
      end
    end

    test "nondefault faceting also remains visible without a facet declaration" do
      applied = applied_settings(SearchablePost) |> put_in(["faceting", "maxValuesPerFacet"], 25)
      put_stub({:ok, applied})

      assert {:ok, %Report{dimensions: dims}} =
               Scrypath.index_contract_drift(SearchablePost, base_opts())

      refute dims.faceting.match
    end

    test "custom declared faceting matches with the backend default wildcard ordering" do
      applied =
        applied_settings(CustomFaceting)
        |> Map.put("faceting", %{
          "maxValuesPerFacet" => 25,
          "sortFacetValuesBy" => %{"*" => "alpha", "category" => "count"}
        })

      put_stub({:ok, applied})

      assert {:ok, %Report{dimensions: dims}} =
               Scrypath.index_contract_drift(CustomFaceting, base_opts())

      assert dims.faceting.match
    end

    test "JSON round-trip preserves top-level keys" do
      put_stub({:ok, applied_settings(SearchablePost)})

      assert {:ok, report} = Scrypath.index_contract_drift(SearchablePost, base_opts())
      json = Jason.encode!(report)
      decoded = Jason.decode!(json)
      assert Map.has_key?(decoded, "version")
      assert Map.has_key?(decoded, "dimensions")
      assert decoded["version"] == 1
    end
  end
end
