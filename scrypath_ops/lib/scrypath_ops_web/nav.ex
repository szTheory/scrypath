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
        path: "#{mount_path}/posture",
        label: "Posture",
        title: "Posture / health",
        group: :triage
      },
      %{
        path: "#{mount_path}/failed-sync",
        label: "Failed Sync",
        title: "Failed sync work",
        group: :triage
      },
      %{
        path: "#{mount_path}/sync-drift",
        label: "Sync Drift",
        title: "Sync / drift",
        group: :triage
      },
      %{
        path: "#{mount_path}/search",
        label: "Search",
        title: "Search & federation",
        group: :probes
      },
      %{
        path: "#{mount_path}/playbooks",
        label: "Playbooks",
        title: "Saved playbooks",
        group: :probes
      }
    ]
  end
end
