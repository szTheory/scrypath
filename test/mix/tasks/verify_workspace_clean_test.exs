defmodule Mix.Tasks.Verify.WorkspaceCleanTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  describe "build_pathspecs/0" do
    test "derives pathspecs from mix.exs package.files + test" do
      pathspecs = Mix.Tasks.Verify.WorkspaceClean.build_pathspecs()

      # From mix.exs package.files: lib, .formatter.exs, mix.exs, README.md,
      # ARCHITECTURE.md, CHANGELOG.md, guides, docs (D-01)
      assert "lib" in pathspecs
      assert ".formatter.exs" in pathspecs
      assert "mix.exs" in pathspecs
      assert "README.md" in pathspecs
      assert "ARCHITECTURE.md" in pathspecs
      assert "CHANGELOG.md" in pathspecs
      assert "guides" in pathspecs
      assert "docs" in pathspecs

      # D-05: test/** included even though not in package.files
      assert "test" in pathspecs
    end
  end

  describe "run/1 arg guard" do
    test "raises Mix.Error when argument is passed" do
      assert_raise Mix.Error, ~r/verify\.workspace_clean does not accept arguments/, fn ->
        Mix.Task.reenable("verify.workspace_clean")
        Mix.Task.run("verify.workspace_clean", ["stray-arg"])
      end
    end
  end

  describe "run/1 clean path" do
    @tag :requires_clean_workspace
    test "passes on clean workspace and emits progress marker" do
      output =
        capture_io(fn ->
          Mix.Task.reenable("verify.workspace_clean")
          Mix.Task.run("verify.workspace_clean", [])
        end)

      # Tolerant match: any of the progress-marker / success phrases emitted by run/1
      assert output =~ ~r/(Checking workspace cleanliness|Workspace clean|verify\.workspace_clean)/
    end
  end
end
