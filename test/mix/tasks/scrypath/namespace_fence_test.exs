defmodule Mix.Tasks.Scrypath.NamespaceFenceTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Scrypath.NamespaceFence

  describe "check/1" do
    test "flags planted Sigra references under lib/scrypath/" do
      root = tmp_root()

      write!(root, "lib/scrypath/forbidden.ex", "defmodule Sample do\n  # Sigra. should be fenced\nend\n")
      write!(root, "scrypath_ops/lib/scrypath_ops/integrations/sigra/allowed.ex", "defmodule Allowed do\n  # Sigra. is allowed here\nend\n")

      assert {:error, violations} = NamespaceFence.check(root)
      assert Enum.any?(violations, &String.contains?(&1, "lib/scrypath/forbidden.ex:2"))
      assert Enum.any?(violations, &String.contains?(&1, "Sigra. should be fenced"))
    end

    test "allows the Sigra integration namespace" do
      root = tmp_root()

      write!(root, "scrypath_ops/lib/scrypath_ops/integrations/sigra/allowed.ex", "defmodule Allowed do\n  # Sigra. is allowed here\nend\n")
      write!(root, "scrypath_ops/test/scrypath_ops/integrations/sigra/allowed_test.exs", "defmodule AllowedTest do\n  # Sigra. is allowed here too\nend\n")

      assert {:ok, summary} = NamespaceFence.check(root)
      assert summary.scanned_dirs == ["lib/scrypath/", "scrypath_ops/lib/", "scrypath_ops/test/"]
    end

    test "live repository still passes as a canary" do
      assert {:ok, _summary} = NamespaceFence.check(File.cwd!())
    end
  end

  defp tmp_root do
    path = Path.join(System.tmp_dir!(), "scrypath-namespace-fence-#{System.unique_integer([:positive])}")
    File.rm_rf!(path)
    File.mkdir_p!(path)
    path
  end

  defp write!(root, relative_path, contents) do
    path = Path.join(root, relative_path)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, contents)
    path
  end
end
