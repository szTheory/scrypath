defmodule ScrypathOpsWeb.Nav do
  @moduledoc """
  Curated primary navigation for the `/ops` operator shell.

  The router owns route existence and compile-time verification; this module is
  the ordered subset of paths and labels rendered in the ops layout.
  """

  @doc """
  Returns the ordered primary nav items for `/ops` LiveViews.

  Each entry is `%{path: path, label: binary, title: binary, group: atom}`.
  """
  def primary(mount_path \\ "/ops") do
    [
      %{
        path: "#{mount_path}/health",
        label: "Search health",
        title: "Search health",
        group: :recover
      },
      %{
        path: "#{mount_path}/failed-sync",
        label: "Failed sync work",
        title: "Failed sync work",
        group: :recover
      },
      %{
        path: "#{mount_path}/sync-drift",
        label: "Sync and drift",
        title: "Sync and drift",
        group: :recover
      },
      %{
        path: "#{mount_path}/search",
        label: "Search",
        title: "Search",
        group: :explore
      },
      %{
        path: "#{mount_path}/playbooks",
        label: "Playbooks",
        title: "Saved playbooks",
        group: :explore
      }
    ]
  end
end
