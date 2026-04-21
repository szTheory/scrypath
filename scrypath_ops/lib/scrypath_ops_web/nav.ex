defmodule ScrypathOpsWeb.Nav do
  @moduledoc """
  Curated primary navigation for the `/ops` operator shell.

  The router owns route existence and compile-time verification; this module is
  the ordered subset of paths and labels rendered in the ops layout.
  """

  use Phoenix.VerifiedRoutes,
    endpoint: ScrypathOpsWeb.Endpoint,
    router: ScrypathOpsWeb.Router,
    statics: ScrypathOpsWeb.static_paths()

  @doc """
  Returns the ordered primary nav items for `/ops` LiveViews.

  Each entry is `%{path: verified_path, label: binary}`.
  """
  def primary do
    [
      %{path: ~p"/ops/posture", label: "Posture / health"},
      %{path: ~p"/ops/failed-sync", label: "Failed sync work"},
      %{path: ~p"/ops/sync-drift", label: "Sync / drift"},
      %{path: ~p"/ops/search", label: "Search & federation"}
    ]
  end
end
