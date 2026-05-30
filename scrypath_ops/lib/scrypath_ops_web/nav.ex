defmodule ScrypathOpsWeb.Nav do
  @moduledoc """
  Curated primary navigation for the `/ops` operator shell.

  The router owns route existence and compile-time verification; this module is
  the ordered subset of paths and labels rendered in the ops layout.
  """

  @doc """
  Returns the ordered primary nav items for `/ops` LiveViews.

  Each entry is `%{path: path, label: binary}`.
  """
  def primary(mount_path \\ "/ops") do
    [
      %{path: "#{mount_path}/posture", label: "Posture / health"},
      %{path: "#{mount_path}/failed-sync", label: "Failed sync work"},
      %{path: "#{mount_path}/sync-drift", label: "Sync / drift"},
      %{path: "#{mount_path}/search", label: "Search & federation"},
      %{path: "#{mount_path}/playbooks", label: "Saved playbooks"}
    ]
  end
end
