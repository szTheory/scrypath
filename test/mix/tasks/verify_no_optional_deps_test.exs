defmodule Mix.Tasks.Verify.NoOptionalDepsTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Verify.NoOptionalDeps

  describe "isolated_build_path/0" do
    test "is a directory under the _build root, separate from the current build path" do
      path = NoOptionalDeps.isolated_build_path()
      build_root = Path.dirname(Mix.Project.build_path())

      assert Path.dirname(path) == build_root
      refute path == Mix.Project.build_path()
    end
  end

  describe "compile_env/1" do
    test "compiles under prod into the given build path" do
      env = NoOptionalDeps.compile_env("/tmp/isolated-build")

      assert {"MIX_ENV", "prod"} in env
      assert {"MIX_BUILD_PATH", "/tmp/isolated-build"} in env
    end
  end

  describe "optional_deps/0" do
    test "lists the optional dependencies declared in mix.exs" do
      assert NoOptionalDeps.optional_deps() == [:oban]
    end
  end

  describe "assert_optional_deps_absent!/2" do
    test "raises when an optional dependency was built into the isolated build" do
      root = fixture_build_dir()
      File.mkdir_p!(Path.join([root, "lib", "oban"]))

      assert_raise Mix.Error, ~r/lib\/oban/, fn ->
        NoOptionalDeps.assert_optional_deps_absent!(root, [:oban])
      end
    end

    test "raises when the Oban-only worker module was compiled" do
      root = fixture_build_dir()
      beam = Path.join(root, "lib/scrypath/ebin/Elixir.Scrypath.Oban.UpsertWorker.beam")
      File.mkdir_p!(Path.dirname(beam))
      File.write!(beam, "")

      assert_raise Mix.Error, ~r/Elixir\.Scrypath\.Oban\.UpsertWorker\.beam/, fn ->
        NoOptionalDeps.assert_optional_deps_absent!(root, [:oban])
      end
    end

    test "returns :ok when no optional dependency reached the build" do
      root = fixture_build_dir()
      File.mkdir_p!(Path.join([root, "lib", "scrypath", "ebin"]))
      File.mkdir_p!(Path.join([root, "lib", "ecto"]))

      assert NoOptionalDeps.assert_optional_deps_absent!(root, [:oban]) == :ok
    end
  end

  describe "run/1 arg guard" do
    test "raises Mix.Error when an argument is passed" do
      assert_raise Mix.Error, ~r/does not accept arguments/, fn ->
        Mix.Task.reenable("verify.no_optional_deps")
        Mix.Task.run("verify.no_optional_deps", ["stray"])
      end
    end
  end

  defp fixture_build_dir do
    root =
      Path.join(
        System.tmp_dir!(),
        "scrypath-no-optional-deps-test-#{System.unique_integer([:positive, :monotonic])}"
      )

    File.mkdir_p!(root)
    on_exit(fn -> File.rm_rf!(root) end)
    root
  end
end
