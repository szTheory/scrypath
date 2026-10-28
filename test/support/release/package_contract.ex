defmodule Scrypath.Release.PackageContract do
  @moduledoc false

  # RED stub: deliberately wrong so the classifier tests fail on their assertions.
  def public_tasks, do: []
  def public_task_entries, do: []
  def allowed_top_level, do: []
  def check(_unpacked_dir), do: :ok
  def classify(_top_level, _task_modules), do: :ok
  def collect_task_modules(_sources), do: []
end
