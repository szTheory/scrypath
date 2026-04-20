defmodule Scrypath.Facets.DisjunctiveTest do
  use ExUnit.Case, async: true

  alias Scrypath.Facets.Disjunctive

  test "merge_distributions replaces one disjunctive field and leaves others unchanged" do
    main = %{"genre" => %{"a" => 1}, "year" => %{"1999" => 2}}
    overrides = %{genre: %{"a" => 10, "b" => 5}}

    merged = Disjunctive.merge_distributions(main, overrides)

    assert merged["genre"] == %{"a" => 10, "b" => 5}
    assert merged["year"] == %{"1999" => 2}
  end

  test "merge_distributions with empty overrides is a normalized deep copy of main" do
    main = %{"genre" => %{"a" => 1}, "year" => %{"1999" => 2}}

    merged = Disjunctive.merge_distributions(main, %{})

    assert merged == Map.new(main)

    merged = update_in(merged, ["genre"], &Map.put(&1, "probe", 0))
    assert main["genre"] == %{"a" => 1}
    assert merged["genre"]["probe"] == 0
  end

  test "merge_distributions inserts outer key from overrides when main omits that attribute" do
    main = %{}
    overrides = %{rating: %{"4" => 7}}

    merged = Disjunctive.merge_distributions(main, overrides)

    assert merged["rating"] == %{"4" => 7}
  end

  test "merge_distributions treats string override keys like atom keys" do
    main = %{"genre" => %{"a" => 1}}
    via_atom = Disjunctive.merge_distributions(main, %{genre: %{"a" => 9}})
    via_string = Disjunctive.merge_distributions(main, %{"genre" => %{"a" => 9}})

    assert via_atom == via_string
    assert via_atom["genre"] == %{"a" => 9}
  end
end
