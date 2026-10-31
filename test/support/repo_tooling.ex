defmodule Scrypath.RepoTooling do
  @moduledoc false

  # Single location of the repository-only verifier tree. Tests that pin verifier
  # behavior by reading its source go through this module so they never hold a
  # literal path. The verifier tree lives under dev/mix/tasks, outside the Hex package.
  @tasks_root "dev/mix/tasks"

  def tasks_root, do: @tasks_root

  def task_path(relative), do: Path.join(@tasks_root, relative)

  # File.read!/1 raises File.Error on a missing file, so a wrong root fails loudly.
  def task_source!(relative), do: File.read!(task_path(relative))
end
