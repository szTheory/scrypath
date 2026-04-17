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
      System.cmd("git", ["status", "--porcelain", "--" | pathspecs],
        stderr_to_stdout: true
      )

    case {output, exit_status} do
      {"", 0} ->
        Mix.shell().info("Workspace clean across #{length(pathspecs)} pathspecs")
        :ok

      {dirty_output, 0} ->
        raise_dirty!(dirty_output)

      {err, _nonzero} ->
        Mix.raise("git status failed:\n\n#{err}")
    end
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
    Mix.raise(
      "verify.workspace_clean does not accept arguments, got: #{Enum.join(args, " ")}"
    )
  end

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
