defmodule Mix.Tasks.Verify.WorkspaceClean do
  @moduledoc """
  Verifies that `git status` is clean for all pathspecs that ship in the Hex
  tarball plus `test/**`.

  Runs as the first step of every publish path (canonical release-please flow,
  manual-recovery workflow, and per-push CI) so a release cannot ship files
  that were not reviewed and merged.

  This gate exists because v1.2 shipped a partial tarball when uncommitted
  files did not travel to the release tag. See
  `.planning/milestones/v1.2-MILESTONE-AUDIT.md` for the incident narrative.

  ## Usage

      mix verify.workspace_clean

  The task takes no arguments. Per decision D-04, there is no escape-hatch
  flag or environment variable — the friction is the feature. Real
  emergencies require commenting out the workflow step in a PR.
  """

  @shortdoc "Fails if the working tree has uncommitted changes in packaged paths"

  use Mix.Task

  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    ensure_no_args!(args)

    pathspecs = build_pathspecs()

    Mix.shell().info("==> Checking workspace cleanliness for packaged paths")

    {output, exit_status} =
      System.cmd("git", ["status", "--porcelain", "--" | pathspecs], stderr_to_stdout: true)

    case classify(output, exit_status, length(pathspecs)) do
      {:ok, message} ->
        Mix.shell().info(message)
        :ok

      {:dirty, dirty_output} ->
        raise_dirty!(dirty_output)

      {:git_error, err} ->
        Mix.raise("git status failed:\n\n#{err}")
    end
  end

  @doc """
  Pure classifier for `git status --porcelain` output.

  Split out of `run/1` so tests can exercise each branch without a real git
  subprocess (mirrors the `Mix.Tasks.Verify.ReleaseParity.compute/2` seam).

  Returns one of:

  - `{:ok, message}` — clean tree (empty output, exit 0)
  - `{:dirty, paths}` — uncommitted or untracked files present (non-empty output, exit 0)
  - `{:git_error, err}` — `git status` itself failed (non-zero exit)
  """
  @spec classify(String.t(), integer(), non_neg_integer()) ::
          {:ok, String.t()} | {:dirty, String.t()} | {:git_error, String.t()}
  def classify("", 0, pathspec_count) do
    {:ok, "Workspace clean across #{pathspec_count} pathspecs"}
  end

  def classify(dirty_output, 0, _pathspec_count) when dirty_output != "" do
    {:dirty, dirty_output}
  end

  def classify(err, exit_status, _pathspec_count) when exit_status != 0 do
    {:git_error, err}
  end

  @doc """
  Returns the pathspec list used by `run/1` — derived from
  `mix.exs` `package.files` (D-01) plus `"test"` (D-05).

  Exposed publicly for testability.
  """
  @spec build_pathspecs() :: [String.t()]
  def build_pathspecs do
    project = Mix.Project.config()

    package_files =
      project
      |> Keyword.get(:package, [])
      |> Keyword.get(:files, [])

    # D-05: test/** included even though not packaged — uncommitted tests
    # mean "the lib/ state being published was not tested as it will ship."
    package_files ++ ["test"]
  end

  defp ensure_no_args!([]), do: :ok

  defp ensure_no_args!(args) do
    Mix.raise("verify.workspace_clean does not accept arguments, got: #{Enum.join(args, " ")}")
  end

  @spec raise_dirty!(String.t()) :: no_return()
  defp raise_dirty!(output) do
    Mix.raise("""
    Workspace is not clean. Uncommitted or untracked files exist in packaged paths:

    #{output}
    Resolve with:
      git add <path>           # stage
      git stash -u             # shelve uncommitted changes + untracked
      git checkout -- <path>   # discard working-tree changes

    This gate exists because v1.2 shipped a partial tarball when uncommitted
    files did not travel to the release tag. See
    .planning/milestones/v1.2-MILESTONE-AUDIT.md for background.
    """)
  end
end
