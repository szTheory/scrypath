defmodule Mix.Tasks.Verify.WorkspaceCleanTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  describe "build_pathspecs/0" do
    test "derives pathspecs from mix.exs package.files + test" do
      pathspecs = Mix.Tasks.Verify.WorkspaceClean.build_pathspecs()

      # From mix.exs package.files plus test/**.
      assert "lib" in pathspecs
      assert ".formatter.exs" in pathspecs
      assert "mix.exs" in pathspecs
      assert "README.md" in pathspecs
      assert "ARCHITECTURE.md" in pathspecs
      assert "CHANGELOG.md" in pathspecs
      assert "LICENSE" in pathspecs
      assert "SECURITY.md" in pathspecs
      assert "guides" in pathspecs
      assert "docs/releasing.md" in pathspecs
      assert "docs/operator-support.md" in pathspecs
      assert "docs/search-backend-sre.md" in pathspecs

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
      assert output =~
               ~r/(Checking workspace cleanliness|Workspace clean|verify\.workspace_clean)/
    end
  end

  describe "classify/3 (pure testability seam)" do
    # Shift-left coverage for UAT-02 (dirty tree raises with offending paths) —
    # exercises each branch without a real git subprocess. Mirrors the
    # Mix.Tasks.Verify.ReleaseParity.compute/2 Pitfall-11 split.

    test "reports clean when output is empty and exit status is 0" do
      assert {:ok, message} = Mix.Tasks.Verify.WorkspaceClean.classify("", 0, 9)
      assert message == "Workspace clean across 9 pathspecs"
    end

    test "reports dirty and passes offending paths through verbatim when exit 0 + non-empty output" do
      porcelain = "M lib/foo.ex\n?? bar\n"

      assert Mix.Tasks.Verify.WorkspaceClean.classify(porcelain, 0, 9) ==
               {:dirty, porcelain}
    end

    test "reports git_error when exit status is non-zero regardless of output" do
      assert Mix.Tasks.Verify.WorkspaceClean.classify("fatal: not a git repo", 128, 9) ==
               {:git_error, "fatal: not a git repo"}
    end
  end
end
