defmodule Scrypath.MultiSearch.AllExpansionTest do
  use ExUnit.Case, async: true

  alias Scrypath.MultiSearch.AllExpansion

  test "happy: :all splices global_schemas with per-entry opts" do
    entries = [{:all, "q", federation_weight: 1.0}]

    assert {:ok,
            [
              {SearchablePost, "q", [federation_weight: 1.0]},
              {FacetableMovie, "q", [federation_weight: 1.0]}
            ]} =
             AllExpansion.expand(
               entries,
               global_schemas: [SearchablePost, FacetableMovie],
               otp_app: :irrelevant_here
             )
  end

  test "empty registry returns :all_expansion error" do
    assert {:error, {:invalid_options, {:all_expansion, :empty_registry}}} =
             AllExpansion.expand(
               [{:all, "q"}],
               global_schemas: []
             )
  end

  test "missing otp_app when global_schemas absent" do
    assert {:error, {:invalid_options, {:all_expansion, :missing_otp_app}}} =
             AllExpansion.expand([{:all, "x"}], [])
  end

  test "malformed :all text type" do
    assert {:error, {:invalid_options, :malformed_entry}} =
             AllExpansion.expand([{:all, 1}], [])
  end

  test "malformed :all third element" do
    assert {:error, {:invalid_options, :malformed_entry}} =
             AllExpansion.expand(
               [{:all, "t", :not_a_kw_list}],
               global_schemas: [SearchablePost]
             )
  end

  test "entries without :all pass through unchanged" do
    entries = [{SearchablePost, "z"}]
    assert {:ok, ^entries} = AllExpansion.expand(entries, [])
  end
end
