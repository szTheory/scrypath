defmodule Mix.Tasks.Verify.PhoenixExample.LockGraphTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Verify.PhoenixExample.LockGraph

  @phoenix_lock File.read!("examples/phoenix_meilisearch/mix.lock")

  test "normalizes dependency keys and ignores map-entry ordering" do
    string_keys = ~S|%{"mint" => {:hex, :mint, "1.11.0", "m", [:mix], [], "hexpm", "r"}, "hpax" => {:hex, :hpax, "1.1.0", "h", [:mix], [], "hexpm", "s"}}|
    atom_keys = ~S|%{hpax: {:hex, :hpax, "1.1.0", "h", [:mix], [], "hexpm", "s"}, mint: {:hex, :mint, "1.11.0", "m", [:mix], [], "hexpm", "r"}}|

    assert LockGraph.parse!(string_keys) == LockGraph.parse!(atom_keys)
  end

  test "rejects empty, malformed, executable, and duplicate normalized keys" do
    assert_raise ArgumentError, ~r/empty/i, fn -> LockGraph.parse!("%{}") end
    assert_raise ArgumentError, ~r/syntax/i, fn -> LockGraph.parse!("%{broken") end

    assert_raise ArgumentError, ~r/literal/i, fn ->
      LockGraph.parse!(~S|%{"mint" => System.cmd("touch", ["/tmp/should-not-execute"])}|)
    end

    assert_raise ArgumentError, ~r/duplicate/i, fn ->
      LockGraph.parse!(~S|%{"mint" => {:hex, :mint, "1.11.0", "m", [:mix], [], "hexpm", "r"}, mint: {:hex, :mint, "1.11.0", "m", [:mix], [], "hexpm", "r"}}|)
    end
  end

  test "rejects a non-package effective graph without Mint and HPAX" do
    incomplete = ~S|%{"mint" => {:hex, :mint, "1.11.0", "m", [:mix], [], "hexpm", "r"}}|

    assert_raise ArgumentError, ~r/hpax/i, fn -> LockGraph.identity!(incomplete) end
  end

  test "package comparison permits only the expected Scrypath artifact substitution" do
    artifact_url = "file:///tmp/scrypath-artifact"
    tag = "v0.3.13"
    resolved = insert_scrypath(@phoenix_lock, artifact_url, tag)

    assert :ok = LockGraph.assert_package!(@phoenix_lock, resolved, artifact_url, tag)
  end

  test "package comparison rejects key, checksum, version, and source drift" do
    artifact_url = "file:///tmp/scrypath-artifact"
    tag = "v0.3.13"

    resolved = insert_scrypath(@phoenix_lock, artifact_url, tag)

    mutations = [
      String.replace(resolved, "  \"heroicons\":", "  \"unexpected\": {:hex, :unexpected, \"1.0.0\", \"x\", [:mix], [], \"hexpm\", \"y\"},\n  \"heroicons\":", global: false),
      String.replace(resolved, "\"1.1.0\", \"782931867cc23217c68fb5f68fe1a11f5e7544c7fda82c8a7019a5df5a4a1cdf\"", "\"1.1.0\", \"changed-checksum\"", global: false),
      String.replace(resolved, "\"hpax\": {:hex, :hpax, \"1.1.0\"", "\"hpax\": {:hex, :hpax, \"1.0.4\"", global: false),
      String.replace(resolved, "\"hpax\": {:hex, :hpax, \"1.1.0\"", "\"hpax\": {:git, :hpax, \"1.1.0\"", global: false)
    ]

    Enum.each(mutations, fn mutated ->
      assert_raise ArgumentError, ~r/graph|lock/i, fn ->
        LockGraph.assert_package!(@phoenix_lock, mutated, artifact_url, tag)
      end
    end)
  end

  test "rejects a wrong artifact tag or URL" do
    resolved = insert_scrypath(@phoenix_lock, "file:///tmp/scrypath-artifact", "v0.3.13")

    assert_raise ArgumentError, ~r/Scrypath|artifact/i, fn ->
      LockGraph.assert_package!(@phoenix_lock, resolved, "file:///tmp/other", "v0.3.13")
    end

    assert_raise ArgumentError, ~r/Scrypath|artifact/i, fn ->
      LockGraph.assert_package!(@phoenix_lock, resolved, "file:///tmp/scrypath-artifact", "v9.9.9")
    end
  end

  test "identity is sorted, includes Mint and HPAX, and omits lock source details" do
    identity = LockGraph.identity!(@phoenix_lock)
    package_names = Enum.map(identity.packages, &elem(&1, 0))

    assert package_names == Enum.sort(package_names)
    assert {"mint", "1.11.0"} in identity.packages
    assert {"hpax", "1.1.0"} in identity.packages
    assert String.length(identity.sha256) == 64
    refute inspect(identity.packages) =~ "hexpm"
  end

  test "assert_unchanged checks exact lock bytes" do
    assert :ok = LockGraph.assert_unchanged!("source lock", "source lock")

    assert_raise ArgumentError, ~r/changed/i, fn ->
      LockGraph.assert_unchanged!("source lock", "changed lock")
    end
  end

  defp insert_scrypath(lock, url, tag) do
    entry = ~s|  "scrypath" => {:git, "#{url}", "abc123", [tag: "#{tag}"]},\n|
    String.replace(lock, "%{\n", "%{\n" <> entry, global: false)
  end
end
