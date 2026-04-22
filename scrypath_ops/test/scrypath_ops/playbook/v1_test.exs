defmodule ScrypathOps.Playbook.V1Test do
  use ExUnit.Case, async: true

  import ExUnit.DocTest

  alias ScrypathOps.Playbook.V1

  doctest ScrypathOps.Playbook.V1

  @minimal_search ~s"""
  {"playbook_format":1,"mode":"search","schema":"MyApp.Post","q":"hello","opts":{}}
  """

  test "search minimal JSON decodes and validates" do
    assert {:ok, map} = V1.decode(@minimal_search)
    assert {:ok, validated} = V1.validate(map)
    assert validated["mode"] == "search"
    assert validated["schema"] == "MyApp.Post"
  end

  test "unknown top-level key fails validation" do
    map = Jason.decode!(@minimal_search)
    bad = Map.put(map, "extra_field", true)

    assert {:error, {:invalid_playbook, {:unknown_top_level_keys, ["extra_field"]}}} =
             V1.validate(bad)
  end

  test "page.size 0 and 51 fail with page_size_out_of_range consistent with SearchPlayground" do
    prev = Application.get_env(:scrypath_ops, :search_playground_max_page_size)

    on_exit(fn ->
      if prev == nil,
        do: Application.delete_env(:scrypath_ops, :search_playground_max_page_size),
        else: Application.put_env(:scrypath_ops, :search_playground_max_page_size, prev)
    end)

    Application.put_env(:scrypath_ops, :search_playground_max_page_size, 50)

    for size <- [0, 51] do
      map = %{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "MyApp.Post",
        "q" => "x",
        "opts" => %{"page" => %{"size" => size}}
      }

      assert {:error, {:invalid_playbook, {:page_size_out_of_range, ^size, 50}}} =
               V1.validate(map)
    end
  end

  test "search_many with more entries than max_schemas_allowed fails without truncation" do
    prev = Application.get_env(:scrypath_ops, :search_playground_max_schemas)

    on_exit(fn ->
      if prev == nil,
        do: Application.delete_env(:scrypath_ops, :search_playground_max_schemas),
        else: Application.put_env(:scrypath_ops, :search_playground_max_schemas, prev)
    end)

    Application.put_env(:scrypath_ops, :search_playground_max_schemas, 10)

    entries =
      for i <- 1..11 do
        ["MyApp.Post", "q#{i}", %{}]
      end

    map = %{
      "playbook_format" => 1,
      "mode" => "search_many",
      "entries" => entries,
      "opts" => %{}
    }

    assert {:error, {:invalid_playbook, {:too_many_entries, 11, 10}}} = V1.validate(map)
  end

  test "nested meilisearch_api_key under opts is rejected" do
    map = %{
      "playbook_format" => 1,
      "mode" => "search",
      "schema" => "MyApp.Post",
      "q" => "x",
      "opts" => %{"filter" => %{"meilisearch_api_key" => "secret"}}
    }

    assert {:error, {:invalid_playbook, {:banned_key, "meilisearch_api_key", _}}} =
             V1.validate(map)
  end

  test "encode after validate round-trips through Jason and decode" do
    {:ok, map} = V1.decode(@minimal_search)
    {:ok, validated} = V1.validate(map)
    {:ok, json} = V1.encode(validated)
    assert {:ok, again} = V1.decode(json)
    assert {:ok, ^validated} = V1.validate(again)
  end

  test "search_many fixture validates" do
    json = ~s"""
    {"playbook_format":1,"mode":"search_many","entries":[["MyApp.Post","one",{}],["MyApp.Comment","two",{}]],"opts":{"federation_limit":200}}
    """

    assert {:ok, m} = V1.decode(json)
    assert {:ok, _} = V1.validate(m)
  end
end
