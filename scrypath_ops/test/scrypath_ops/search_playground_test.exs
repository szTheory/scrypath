defmodule ScrypathOps.SearchPlaygroundTest do
  use ExUnit.Case, async: false

  alias ScrypathOps.SearchPlayground
  alias ScrypathOps.SearchPlayground.Adapter.Scrypath, as: ScrypathAdapter

  test "validate_page_size/1 rejects 51 with error mentioning 50" do
    prev = Application.get_env(:scrypath_ops, :search_playground_max_page_size)

    on_exit(fn ->
      if prev == nil,
        do: Application.delete_env(:scrypath_ops, :search_playground_max_page_size),
        else: Application.put_env(:scrypath_ops, :search_playground_max_page_size, prev)
    end)

    Application.put_env(:scrypath_ops, :search_playground_max_page_size, 50)
    result = SearchPlayground.validate_page_size(51)
    assert inspect(result) =~ "50"
  end

  test "host can raise the response budget independently of the per-query library page guard" do
    prev = Application.get_env(:scrypath_ops, :search_playground_max_page_size)
    on_exit(fn -> Application.put_env(:scrypath_ops, :search_playground_max_page_size, prev) end)
    Application.put_env(:scrypath_ops, :search_playground_max_page_size, 200)
    assert SearchPlayground.max_page_size_allowed() == 200
    assert SearchPlayground.validate_page_size(150) == :ok

    assert {:error, {:invalid_saved_search, {:page_size_out_of_range, 51, 50}}} =
             ScrypathOps.SavedSearches.V1.validate(%{
               "playbook_format" => 1,
               "mode" => "search_many",
               "entries" => [["MyApp.Product", "", %{"page" => %{"size" => 51}}]],
               "opts" => %{}
             })
  end

  test "adapter/0 defaults to Scrypath adapter module" do
    prev = Application.get_env(:scrypath_ops, :search_playground_adapter)

    on_exit(fn ->
      if prev == nil,
        do: Application.delete_env(:scrypath_ops, :search_playground_adapter),
        else: Application.put_env(:scrypath_ops, :search_playground_adapter, prev)
    end)

    Application.delete_env(:scrypath_ops, :search_playground_adapter)
    assert SearchPlayground.adapter() == ScrypathAdapter
  end
end
