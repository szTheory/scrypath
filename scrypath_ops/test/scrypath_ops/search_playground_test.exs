defmodule ScrypathOps.SearchPlaygroundTest do
  use ExUnit.Case, async: true

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
