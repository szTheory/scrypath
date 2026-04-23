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

  test "rename_workspace_file/3 renames when target is free", %{dir: dir} do
    :ok = File.write!(Path.join(dir, "a.json"), "{}")
    assert :ok = Store.rename_workspace_file(dir, "a.json", "b.json")
    refute File.exists?(Path.join(dir, "a.json"))
    assert File.exists?(Path.join(dir, "b.json"))
  end

  test "rename_workspace_file/3 returns target_exists when destination exists", %{dir: dir} do
    :ok = File.write!(Path.join(dir, "a.json"), "{}")
    :ok = File.write!(Path.join(dir, "b.json"), "{}")
    assert {:error, :target_exists} = Store.rename_workspace_file(dir, "a.json", "b.json")
    assert File.exists?(Path.join(dir, "a.json"))
  end

  test "duplicate_workspace_file/3 copies payload when target is free", %{dir: dir} do
    :ok = File.write!(Path.join(dir, "src.json"), ~s({"x":1}))
    assert :ok = Store.duplicate_workspace_file(dir, "src.json", "copy.json")
    assert {:ok, body} = Store.read_workspace_file(dir, "copy.json")
    assert body == ~s({"x":1})
  end

  test "duplicate_workspace_file/3 returns target_exists when destination exists", %{dir: dir} do
    :ok = File.write!(Path.join(dir, "src.json"), "{}")
    :ok = File.write!(Path.join(dir, "dst.json"), "{}")
    assert {:error, :target_exists} = Store.duplicate_workspace_file(dir, "src.json", "dst.json")
  end

  test "rename and duplicate reject unsafe basenames", %{dir: dir} do
    assert {:error, :outside_workspace} = Store.rename_workspace_file(dir, "../x.json", "y.json")

    assert {:error, :outside_workspace} =
             Store.duplicate_workspace_file(dir, "a.json", "../y.json")
  end

  test "suggest_duplicate_basename/2 returns first free stem-n name", %{dir: dir} do
    :ok = File.write!(Path.join(dir, "foo.json"), "{}")
    :ok = File.write!(Path.join(dir, "foo-1.json"), "{}")
    assert {:ok, "foo-2.json"} = Store.suggest_duplicate_basename(dir, "foo.json")
  end
end
