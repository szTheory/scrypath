defmodule Scrypath.ChunksTest do
  use ExUnit.Case, async: true

  alias Scrypath.Chunks

  test "max_ids is 1000" do
    assert Chunks.max_ids() == 1000
  end

  describe "ids/1" do
    test "exactly 1000 ids make one chunk and 1001 ids make two" do
      assert [chunk] = Chunks.ids(Enum.to_list(1..1000))
      assert length(chunk) == 1000

      assert Enum.map(Chunks.ids(Enum.to_list(1..1001)), &length/1) == [1000, 1]
    end

    test "empty input makes no chunks and a single id makes one chunk" do
      assert Chunks.ids([]) == []
      assert Chunks.ids([42]) == [[42]]
    end

    test "dedupes by raw value, keeps 1 and \"1\" distinct, and sorts by string form" do
      assert Chunks.ids([2, 1, 2, "1"]) == [[1, "1", 2]]
      assert Chunks.ids([7, 7, 7]) == [[7]]
    end

    test "an atom id and its string name are one id; booleans and nil stay distinct (IN-01)" do
      assert Chunks.ids([:a, "a", :b]) == [[:a, :b]]
      assert Chunks.ids(["a", :a]) == [["a"]]
      assert Chunks.ids([true, "true", nil, "nil"]) == [[nil, "nil", true, "true"]]
      assert Chunks.distinct_count([:a, "a", 1, "1", 1]) == 3
    end

    test "the same id set in any order yields identical chunks" do
      ids = Enum.to_list(1..2500)

      chunks = Chunks.ids(ids)

      assert Enum.map(chunks, &length/1) == [1000, 1000, 500]
      assert Chunks.ids(Enum.shuffle(ids)) == chunks
      assert Chunks.ids(Enum.reverse(ids)) == chunks
    end

    test "non-scalar ids still sort deterministically" do
      ids = [{:b, 1}, {:a, 2}, {:a, 2}]

      assert Chunks.ids(ids) == Chunks.ids(Enum.reverse(ids))
      assert [[_, _]] = Chunks.ids(ids)
    end
  end

  describe "by_id/2" do
    test "keeps the last occurrence of a duplicate id" do
      items = [%{id: 1, v: :first}, %{id: 2, v: :only}, %{id: 1, v: :last}]

      assert Chunks.by_id(items, & &1.id) == [[%{id: 1, v: :last}, %{id: 2, v: :only}]]
    end

    test "collapses items whose ids differ only as atom and string (IN-01)" do
      items = [%{id: :a, v: :first}, %{id: "a", v: :last}]

      assert Chunks.by_id(items, & &1.id) == [[%{id: "a", v: :last}]]
    end

    test "chunks by at most 1000 items in a stable order" do
      items = Enum.map(1..2500, &%{id: &1})

      chunks = Chunks.by_id(Enum.shuffle(items), & &1.id)

      assert Enum.map(chunks, &length/1) == [1000, 1000, 500]
      assert chunks == Chunks.by_id(items, & &1.id)
      assert Chunks.by_id([], & &1.id) == []
    end
  end

  describe "reduce_ok/2" do
    test "returns results in order" do
      assert Chunks.reduce_ok([1, 2, 3], &{:ok, &1 * 10}) == {:ok, [10, 20, 30]}
      assert Chunks.reduce_ok([], &{:ok, &1}) == {:ok, []}
    end

    test "halts at the first error and never calls later chunks" do
      fun = fn chunk ->
        send(self(), {:called, chunk})
        if chunk == 2, do: {:error, :boom}, else: {:ok, chunk}
      end

      assert Chunks.reduce_ok([1, 2, 3], fun) == {:error, :boom}
      assert_received {:called, 1}
      assert_received {:called, 2}
      refute_received {:called, 3}
    end
  end

  describe "each_ok/2" do
    test "returns :ok when every chunk succeeds" do
      assert Chunks.each_ok([1, 2], fn _ -> :ok end) == :ok
      assert Chunks.each_ok([], fn _ -> :ok end) == :ok
    end

    test "halts at the first error and never calls later chunks" do
      fun = fn chunk ->
        send(self(), {:called, chunk})
        if chunk == 2, do: {:error, :boom}, else: :ok
      end

      assert Chunks.each_ok([1, 2, 3], fun) == {:error, :boom}
      assert_received {:called, 2}
      refute_received {:called, 3}
    end
  end
end
