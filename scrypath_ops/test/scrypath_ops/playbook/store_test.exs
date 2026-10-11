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

  test "workspace operations reject symlinks without reading or changing their targets", %{
    dir: dir
  } do
    outside = dir <> "_outside.json"
    linked = Path.join(dir, "linked.json")
    :ok = File.write!(outside, "original")
    :ok = File.ln_s(outside, linked)

    assert {:error, :outside_workspace} = Store.read_workspace_file(dir, "linked.json")
    assert {:error, :outside_workspace} = Store.save_workspace_file(dir, "linked.json", "changed")
    assert {:ok, []} = Store.list_workspace_json(dir)
    assert File.read!(outside) == "original"
  after
    File.rm(dir <> "_outside.json")
  end

  test "workspace root symlinks are rejected", %{dir: dir} do
    outside_root = dir <> "_outside_root"
    root_link = dir <> "_root_link"
    :ok = File.mkdir_p(outside_root)
    :ok = File.write!(Path.join(outside_root, "secret.json"), "outside")
    :ok = File.ln_s(outside_root, root_link)

    assert {:error, :outside_workspace} = Store.read_workspace_file(root_link, "secret.json")

    assert {:error, :outside_workspace} =
             Store.save_workspace_file(root_link, "secret.json", "changed")

    assert {:error, :outside_workspace} = Store.list_workspace_json(root_link)
    assert File.read!(Path.join(outside_root, "secret.json")) == "outside"
  after
    File.rm_rf(dir <> "_outside_root")
    File.rm(dir <> "_root_link")
  end

  test "workspace roots with untrusted writable ancestors are rejected", %{dir: dir} do
    parent = Path.join(dir, "unsafe-parent")
    root = Path.join(parent, "workspace")
    :ok = File.mkdir_p(root)
    :ok = File.chmod(parent, 0o777)

    assert {:error, :outside_workspace} = Store.list_workspace_json(root)
    assert {:error, :outside_workspace} = Store.save_workspace_file(root, "new.json", "{}")
  end

  test "workspace roots below a static ancestor symlink use the resolved directory", %{dir: dir} do
    physical_parent = Path.join(dir, "physical-parent")
    physical_root = Path.join(physical_parent, "workspace")
    linked_parent = Path.join(dir, "linked-parent")
    :ok = File.mkdir_p(physical_root)
    :ok = File.write!(Path.join(physical_root, "safe.json"), "inside")
    :ok = File.ln_s(physical_parent, linked_parent)

    assert {:ok, "inside"} =
             Store.read_workspace_file(Path.join(linked_parent, "workspace"), "safe.json")
  end

  test "workspace operations reject hard links without reading or changing their targets", %{
    dir: dir
  } do
    outside = dir <> "_outside.json"
    linked = Path.join(dir, "linked.json")
    :ok = File.write!(outside, "original")
    :ok = File.ln(outside, linked)

    assert {:error, :outside_workspace} = Store.read_workspace_file(dir, "linked.json")
    assert {:error, :outside_workspace} = Store.save_workspace_file(dir, "linked.json", "changed")
    assert {:error, :outside_workspace} = Store.delete_workspace_file(dir, "linked.json")

    assert {:error, :outside_workspace} =
             Store.rename_workspace_file(dir, "linked.json", "renamed.json")

    assert {:ok, []} = Store.list_workspace_json(dir)
    assert File.read!(outside) == "original"
  after
    File.rm(dir <> "_outside.json")
  end

  test "save and read round-trip", %{dir: dir} do
    assert :ok = Store.save_workspace_file(dir, "p.json", ~s({"x":1}))
    assert {:ok, body} = Store.read_workspace_file(dir, "p.json")
    assert body == ~s({"x":1})
  end

  test "saving an existing file replaces its inode", %{dir: dir} do
    path = Path.join(dir, "p.json")
    :ok = File.write(path, "before")
    :ok = File.chmod(path, 0o600)
    before = File.stat!(path)

    assert :ok = Store.save_workspace_file(dir, "p.json", "after")

    after_save = File.stat!(path)
    assert File.read!(path) == "after"
    assert {after_save.major_device, after_save.inode} != {before.major_device, before.inode}
    assert Bitwise.band(after_save.mode, 0o777) == 0o600
  end

  test "create_workspace_file/3 never replaces a file created concurrently", %{dir: dir} do
    writes = ["first", "second"]

    results =
      writes
      |> Enum.map(fn body ->
        Task.async(fn -> {body, Store.create_workspace_file(dir, "shared.json", body)} end)
      end)
      |> Enum.map(&Task.await(&1, 5_000))

    assert Enum.count(results, fn {_body, result} -> result == :ok end) == 1

    assert Enum.count(results, fn {_body, result} -> result == {:error, :target_exists} end) ==
             1

    {winner, :ok} = Enum.find(results, fn {_body, result} -> result == :ok end)
    assert {:ok, ^winner} = Store.read_workspace_file(dir, "shared.json")
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

  test "concurrent renames never replace the destination winner", %{dir: dir} do
    for iteration <- 1..10 do
      target = "shared-#{iteration}.json"
      parent = self()

      tasks =
        for source_index <- 1..16 do
          source = "source-#{iteration}-#{source_index}.json"
          :ok = File.write!(Path.join(dir, source), "#{source_index}")

          Task.async(fn ->
            send(parent, :ready)

            receive do
              :rename -> Store.rename_workspace_file(dir, source, target)
            end
          end)
        end

      Enum.each(tasks, fn _ -> assert_receive :ready, 5_000 end)
      Enum.each(tasks, &send(&1.pid, :rename))
      results = Enum.map(tasks, &Task.await(&1, 5_000))

      assert Enum.count(results, &(&1 == :ok)) == 1

      assert Enum.count(results, &(&1 == {:error, :target_exists})) == 15

      {:ok, winner} = File.read(Path.join(dir, target))
      assert winner in Enum.map(1..16, &Integer.to_string/1)

      for source_index <- 1..16 do
        source = Path.join(dir, "source-#{iteration}-#{source_index}.json")

        if Integer.to_string(source_index) == winner do
          refute File.exists?(source)
        else
          assert File.read!(source) == Integer.to_string(source_index)
        end
      end
    end
  end

  test "concurrent renames of one source leave only the winning destination", %{dir: dir} do
    source = Path.join(dir, "source.json")
    :ok = File.write!(source, "keep this playbook")
    parent = self()

    tasks =
      ["first.json", "second.json"]
      |> Enum.map(fn target ->
        Task.async(fn ->
          send(parent, :ready)

          receive do
            :rename -> {target, Store.rename_workspace_file(dir, "source.json", target)}
          end
        end)
      end)

    Enum.each(tasks, fn _ -> assert_receive :ready, 5_000 end)
    Enum.each(tasks, &send(&1.pid, :rename))
    results = Enum.map(tasks, &Task.await(&1, 5_000))

    assert Enum.count(results, fn {_target, result} -> result == :ok end) == 1

    assert Enum.count(results, fn {_target, result} -> result == {:error, :rename_failed} end) ==
             1

    refute File.exists?(source)

    winning_target =
      Enum.find_value(results, fn {target, result} -> if result == :ok, do: target end)

    losing_target =
      Enum.find_value(results, fn {target, result} -> if result != :ok, do: target end)

    assert File.read!(Path.join(dir, winning_target)) == "keep this playbook"
    refute File.exists?(Path.join(dir, losing_target))
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
