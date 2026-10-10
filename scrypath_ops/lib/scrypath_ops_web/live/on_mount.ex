defmodule ScrypathOpsWeb.Live.OnMount do
  @moduledoc """
  Shared `on_mount` hooks for the `/ops` `live_session`.

  Extracts configuration injected by the `scrypath_ops_routes` macro.
  """
  import Phoenix.Component
  import Phoenix.LiveView, only: [attach_hook: 4]

  alias ScrypathOps.OperatorSelection

  @ops_child_route_suffixes %{
    ScrypathOpsWeb.PostureLive => "/health",
    ScrypathOpsWeb.FailedSyncLive => "/failed-sync",
    ScrypathOpsWeb.SyncDriftLive => "/sync-drift",
    ScrypathOpsWeb.SearchLive => "/search",
    ScrypathOpsWeb.PlaybookLive => "/playbooks"
  }

  def on_mount(:default, _params, session, socket) do
    opts = Map.get(session, "scrypath_ops_opts", [])

    repo = Keyword.get(opts, :repo)
    mount_path = Keyword.get(opts, :mount_path, "/ops")

    socket =
      socket
      |> assign(:shell, :ops)
      |> assign(:scrypath_repo, repo)
      |> assign(:mount_path, mount_path)
      |> attach_hook(:scrypath_ops_mount_path, :handle_params, fn params, uri, socket ->
        mount_path = derive_mount_path(uri, socket.view, socket.assigns.mount_path)

        socket =
          socket
          |> assign(:mount_path, mount_path)
          |> assign(:return_to, URI.parse(uri).path)
          |> assign(:recovery_target, recovery_target(params, socket.view, socket.assigns))

        {:cont, socket}
      end)

    {:cont, socket}
  end

  defp recovery_target(_params, view, _assigns)
       when view in [ScrypathOpsWeb.ControlRoomLive, ScrypathOpsWeb.PostureLive],
       do: nil

  defp recovery_target(params, view, assigns) do
    allowlist = current_allowlist(params, assigns)

    case {Map.has_key?(params, "schema"), OperatorSelection.resolve(params, allowlist)} do
      {true, {:ok, schema}} ->
        schema

      {false, {:ok, schema}}
      when view in [ScrypathOpsWeb.FailedSyncLive, ScrypathOpsWeb.SyncDriftLive] ->
        schema

      _ ->
        nil
    end
  end

  defp current_allowlist(params, %{live_action: :phase175}) do
    if Mix.env() == :test do
      source = Module.concat(["ScrypathOps.Test.Phase175FixtureSource"])
      scenario = Map.get(params, "scenario", "accepted-processing")

      if Code.ensure_loaded?(source) and function_exported?(source, :allowlist, 1) do
        source.allowlist(scenario)
      else
        []
      end
    else
      ScrypathOps.Schemas.allowlist()
    end
  end

  defp current_allowlist(params, %{live_action: :phase174}) do
    source = Application.get_env(:scrypath_ops, :phase174_fixture_source)

    if Mix.env() == :test and is_atom(source) and Code.ensure_loaded?(source) and
         function_exported?(source, :allowlist, 1) do
      source.allowlist(Map.get(params, "scenario", "a-selected-b-worse"))
    else
      ScrypathOps.Schemas.allowlist()
    end
  end

  defp current_allowlist(_params, _assigns), do: ScrypathOps.Schemas.allowlist()

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
