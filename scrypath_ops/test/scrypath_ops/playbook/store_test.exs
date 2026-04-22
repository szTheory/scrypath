defmodule ScrypathOps.Playbook.StoreTest do
  use ExUnit.Case, async: true

  alias ScrypathOps.Playbook.Store

  setup do
    dir =
      Path.join(
        System.tmp_dir!(),
        "scrypath_ops_store_test_#{:erlang.unique_integer([:positive])}"
      )

    :ok = File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf(dir) end)
    %{dir: dir}
  end

  test "safe_basename?/1 accepts json basenames and rejects traversal", %{dir: dir} do
    assert Store.safe_basename?("hello.json")
    refute Store.safe_basename?("../x.json")
    refute Store.safe_basename?("a/b.json")

    assert {:error, :outside_workspace} = Store.read_workspace_file(dir, "../x.json")
  end

  test "list_workspace_json/1 lists only direct json children", %{dir: dir} do
    nested = Path.join(dir, "nested")
    :ok = File.mkdir_p!(nested)
    :ok = File.write!(Path.join(dir, "a.json"), "{}")
    :ok = File.write!(Path.join(dir, "z.json"), "{}")
    :ok = File.write!(Path.join(nested, "inner.json"), "{}")

    assert {:ok, names} = Store.list_workspace_json(dir)
    assert names == ["a.json", "z.json"]
  end

  test "save and read round-trip", %{dir: dir} do
    assert :ok = Store.save_workspace_file(dir, "p.json", ~s({"x":1}))
    assert {:ok, body} = Store.read_workspace_file(dir, "p.json")
    assert body == ~s({"x":1})
  end

  test "delete_workspace_file/2 removes file", %{dir: dir} do
    :ok = File.write!(Path.join(dir, "gone.json"), "{}")
    assert :ok = Store.delete_workspace_file(dir, "gone.json")
    refute File.exists?(Path.join(dir, "gone.json"))
  end
end
