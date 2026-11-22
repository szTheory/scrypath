defmodule ScrypathOpsWeb.Live.OnMount do
  @moduledoc """
  Shared `on_mount` hooks for the `/ops` `live_session`.

  Extracts configuration injected by the `scrypath_ops_routes` macro.
  """
  import Phoenix.Component
  import Phoenix.LiveView, only: [attach_hook: 4]

  @ops_child_route_suffixes %{
    ScrypathOpsWeb.PostureLive => "/health",
    ScrypathOpsWeb.FailedSyncLive => "/failed-sync",
    ScrypathOpsWeb.SyncDriftLive => "/sync-and-index",
    ScrypathOpsWeb.SearchLive => "/search",
    ScrypathOpsWeb.HelpLive => "/help"
  }

  def on_mount(:default, _params, session, socket) do
    opts = Map.get(session, "scrypath_ops_opts", [])

    repo = Keyword.get(opts, :repo)
    prefix = Keyword.get(opts, :prefix)
    mount_path = Keyword.get(opts, :mount_path, "/ops")

    socket =
      socket
      |> assign(:shell, :ops)
      |> assign(:scrypath_repo, repo)
      |> assign(:scrypath_ops_prefix, prefix)
      |> assign(:mount_path, mount_path)
      |> attach_hook(:scrypath_ops_mount_path, :handle_params, fn _params, uri, socket ->
        mount_path = derive_mount_path(uri, socket.view, socket.assigns.mount_path)
        socket = assign(socket, :mount_path, mount_path)

        # Where a sensitive action sends the operator back to after a security confirmation
        # (`Gating` reads it). A view that assigns its own `:return_to` in `handle_params` still
        # wins, because this hook runs before the view's callback.
        case return_to_path(uri) do
          nil -> {:cont, socket}
          return_to -> {:cont, assign(socket, :return_to, return_to)}
        end
      end)

    {:cont, socket}
  end

  @doc """
  The path and query of a request URL, to use as the page an operator returns to after a security
  confirmation, or `nil` when the URL has no safe one.

  Only the path and the query are kept; the host is never part of the result. A path that could
  leave this host (it starts with `//`, holds a backslash or holds a control character) gives
  `nil`, so the redirect cannot become an open redirect.
  """
  @spec return_to_path(term()) :: String.t() | nil
  def return_to_path("//" <> _), do: nil

  def return_to_path(uri) when is_binary(uri) do
    case URI.parse(uri) do
      %URI{path: "/" <> _ = path, query: query} ->
        if safe_return_path?(path), do: with_query(path, query)

      _ ->
        nil
    end
  end

  def return_to_path(_), do: nil

  defp safe_return_path?("//" <> _), do: false
  defp safe_return_path?(path), do: not String.contains?(path, "\\") and not control?(path)

  defp control?(string),
    do: string |> :binary.bin_to_list() |> Enum.any?(&(&1 < 0x20 or &1 == 0x7F))

  defp with_query(path, query) when query in [nil, ""], do: path
  defp with_query(path, query), do: path <> "?" <> query

  defp derive_mount_path(uri, view, fallback) do
    path = uri |> URI.parse() |> Map.get(:path) |> normalize_path(fallback)

    case route_suffix(view) do
      :root -> path
      {:child, suffix} -> strip_route_suffix(path, suffix, fallback)
      :unknown -> strip_known_child_suffix(path, fallback)
    end
  end

  defp route_suffix(ScrypathOpsWeb.ControlRoomLive), do: :root

  defp route_suffix(view) do
    case Map.fetch(@ops_child_route_suffixes, view) do
      {:ok, suffix} -> {:child, suffix}
      :error -> :unknown
    end
  end

  defp strip_known_child_suffix(path, fallback) do
    @ops_child_route_suffixes
    |> Map.values()
    |> Enum.find_value(fallback, &strip_route_suffix(path, &1, nil))
  end

  defp strip_route_suffix(path, suffix, fallback) do
    if String.ends_with?(path, suffix) do
      path
      |> String.replace_suffix(suffix, "")
      |> mount_root()
    else
      fallback
    end
  end

  defp normalize_path(nil, fallback), do: normalize_path(fallback, "/ops")

  defp normalize_path(path, _fallback) do
    path
    |> String.trim_trailing("/")
    |> mount_root()
  end

  defp mount_root(""), do: "/"
  defp mount_root(path), do: path
end
