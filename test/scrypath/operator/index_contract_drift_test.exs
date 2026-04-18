defmodule Scrypath.Operator.IndexContractDriftTest do
  use ExUnit.Case, async: true

  alias Scrypath.Meilisearch.Settings
  alias Scrypath.Operator.IndexContractDrift.Report

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

  describe "index_contract_drift/2 (DRIFT15, OPS15-01)" do
    test "parity: dimensions and settings match when live mirrors declared projection" do
      config = Scrypath.Config.resolve!(base_opts())

      declared_wire =
        Settings.resolve(SearchablePost, config)
        |> Settings.translate_settings()

      applied =
        Map.merge(declared_wire, %{
          "searchableAttributes" =>
            SearchablePost |> Scrypath.schema_fields() |> Enum.map(&Atom.to_string/1),
          "filterableAttributes" =>
            SearchablePost.__scrypath__(:filterable) |> Enum.map(&Atom.to_string/1),
          "sortableAttributes" =>
            SearchablePost.__scrypath__(:sortable) |> Enum.map(&Atom.to_string/1),
          "faceting" => %{}
        })

      put_stub({:ok, applied})

      assert {:ok, %Report{version: 1, schema: SearchablePost, dimensions: dims}} =
               Scrypath.index_contract_drift(SearchablePost, base_opts())

      assert dims.fields.match
      assert dims.filterable_attributes.match
      assert dims.sortable_attributes.match
      assert dims.faceting.match
      assert dims.settings.match
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

    test "JSON round-trip preserves top-level keys" do
      config = Scrypath.Config.resolve!(base_opts())

      declared_wire =
        Settings.resolve(SearchablePost, config)
        |> Settings.translate_settings()

      applied =
        Map.merge(declared_wire, %{
          "searchableAttributes" =>
            SearchablePost |> Scrypath.schema_fields() |> Enum.map(&Atom.to_string/1),
          "filterableAttributes" =>
            SearchablePost.__scrypath__(:filterable) |> Enum.map(&Atom.to_string/1),
          "sortableAttributes" =>
            SearchablePost.__scrypath__(:sortable) |> Enum.map(&Atom.to_string/1),
          "faceting" => %{}
        })

      put_stub({:ok, applied})

      assert {:ok, report} = Scrypath.index_contract_drift(SearchablePost, base_opts())
      json = Jason.encode!(report)
      decoded = Jason.decode!(json)
      assert Map.has_key?(decoded, "version")
      assert Map.has_key?(decoded, "dimensions")
      assert decoded["version"] == 1
    end
  end
end
