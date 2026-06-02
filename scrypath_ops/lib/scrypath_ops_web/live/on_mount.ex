defmodule ScrypathOpsWeb.Live.OnMount do
  @moduledoc """
  Shared `on_mount` hooks for the `/ops` `live_session`.

  Extracts configuration injected by the `scrypath_ops_routes` macro.
  """
  import Phoenix.Component
  import Phoenix.LiveView, only: [attach_hook: 4]

  @ops_route_suffixes ~w(/posture /failed-sync /sync-drift /search /playbooks)

  def on_mount(:default, _params, session, socket) do
    opts = Map.get(session, "scrypath_ops_opts", [])

    repo = Keyword.get(opts, :repo)
    mount_path = Keyword.get(opts, :mount_path, "/ops")

    socket =
      socket
      |> assign(:shell, :ops)
      |> assign(:scrypath_repo, repo)
      |> assign(:mount_path, mount_path)
      |> attach_hook(:scrypath_ops_mount_path, :handle_params, fn _params, uri, socket ->
        {:cont, assign(socket, :mount_path, derive_mount_path(uri, socket.assigns.mount_path))}
      end)

    {:cont, socket}
  end

  defp derive_mount_path(uri, fallback) do
    path = URI.parse(uri).path || fallback

    Enum.find_value(@ops_route_suffixes, fallback, fn suffix ->
      if String.ends_with?(path, suffix) do
        case String.replace_suffix(path, suffix, "") do
          "" -> "/"
          mount_path -> mount_path
        end
      end
    end)
  end
end
