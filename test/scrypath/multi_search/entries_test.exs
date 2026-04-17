defmodule Scrypath.MultiSearch.EntriesTest do
  use ExUnit.Case, async: true

  alias Scrypath.MultiSearch.Entries

  defmodule Post do
  end

  defmodule User do
  end

  test "empty list" do
    assert Entries.normalize([], []) == {:error, :empty_schema_list}
  end

  test "too_many_schemas rail" do
    entries = for _ <- 1..11, do: {Post, "q"}

    assert {:error, {:too_many_schemas, 11, 10}} =
             Entries.normalize(entries, [])
  end

  test "max_schemas can be raised in shared opts" do
    entries = for _ <- 1..11, do: {Post, "q"}

    assert {:ok, list} = Entries.normalize(entries, max_schemas: 20)
    assert length(list) == 11
  end

  test "page size above ceiling is rejected" do
    assert {:error, {:invalid_options, {:page_size, 51, 50}}} =
             Entries.normalize([{Post, "q", page: [size: 51]}], [])
  end

  test "shared page size above ceiling is rejected" do
    assert {:error, {:invalid_options, {:page_size, 60, 50}}} =
             Entries.normalize([{Post, "q"}], page: [size: 60])
  end

  test "federation key in entry opts is rejected" do
    assert {:error, {:invalid_options, {:federation_key_in_entry, :federation_limit}}} =
             Entries.normalize([{Post, "q", federation_limit: 1}], [])
  end

  test "merge precedence: entry page wins over shared" do
    assert {:ok, triples} =
             Entries.normalize(
               [{Post, "q", page: [size: 5]}],
               page: [size: 10]
             )

    assert [{schema, "q", merged}] = triples
    assert schema == Post
    assert Keyword.get(merged, :page) == [size: 5]
  end

  test "duplicate schema modules are allowed" do
    assert {:ok, triples} =
             Entries.normalize(
               [{Post, "a", filter: [x: 1]}, {Post, "b", filter: [y: 2]}],
               []
             )

    assert [{s1, "a", _}, {s2, "b", _}] = triples
    assert s1 == Post and s2 == Post
  end

  test "two-tuple form" do
    assert {:ok, [{Post, "hi", opts}]} = Entries.normalize([{Post, "hi"}], [])
    assert opts[:repo] == nil
  end

  test "malformed entry" do
    assert {:error, {:invalid_options, :malformed_entry}} =
             Entries.normalize([{Post, "q", %{}}], [])
  end
end
