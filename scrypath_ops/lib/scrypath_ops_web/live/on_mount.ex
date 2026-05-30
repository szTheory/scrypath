defmodule ScrypathOpsWeb.Live.OnMount do
  @moduledoc """
  Shared `on_mount` hooks for the `/ops` `live_session`.

  Extracts configuration injected by the `scrypath_ops_routes` macro.
  """
  import Phoenix.Component

  def on_mount(:default, _params, session, socket) do
    opts = Map.get(session, "scrypath_ops_opts", [])
    
    repo = Keyword.get(opts, :repo)
    mount_path = Keyword.get(opts, :mount_path, "/ops")

    socket =
      socket
      |> assign(:shell, :ops)
      |> assign(:scrypath_repo, repo)
      |> assign(:scrypath_mount_path, mount_path)

    {:cont, socket}
  end
end
