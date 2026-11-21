defmodule Scrypath.LoaderBackfillGeneratorTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Scrypath.TestSupport.LoaderBackfillCases

  # The composite-key paging property (`LoaderBackfillCases`) used to draw its keys with
  # `uniq_list_of/2`, which raised `StreamData.TooManyDuplicatesError` on about 0.2 percent of ExUnit
  # seeds (`--seed 229` among them) and failed a required lane on unrelated pull requests. These
  # cases pin the replacement generator's contract without a database.

  property "membership_keys draws distinct keys from the 3 x 20 grid, at most 30 of them" do
    check all(keys <- LoaderBackfillCases.membership_keys(), max_runs: 200) do
      assert keys == Enum.uniq(keys)
      assert length(keys) <= 30
      assert Enum.all?(keys, fn {org_id, seq} -> org_id in 1..3 and seq in 1..20 end)
    end
  end

  test "membership_keys covers the empty table, a full 30-key table and every org" do
    # A fixed seed makes this sample the same on every run.
    :rand.seed(:exsss, {7, 11, 13})
    samples = LoaderBackfillCases.membership_keys() |> StreamData.resize(100) |> Enum.take(600)

    lengths = Enum.map(samples, &length/1)
    assert 0 in lengths
    assert 30 in lengths

    assert samples |> List.flatten() |> Enum.map(&elem(&1, 0)) |> Enum.uniq() |> Enum.sort() == [
             1,
             2,
             3
           ]
  end

  test "seeds that made the old uniq_list_of generator raise draw cleanly now" do
    for seed <- [229, 2319, 2513, 2529, 2708, 2752, 2803, 2961, 3343, 3857, 6035, 6383] do
      check all(
              keys <- LoaderBackfillCases.membership_keys(),
              batch_size <- integer(1..12),
              max_runs: 40,
              initial_seed: seed
            ) do
        assert keys == Enum.uniq(keys)
        assert batch_size in 1..12
      end
    end
  end
end
