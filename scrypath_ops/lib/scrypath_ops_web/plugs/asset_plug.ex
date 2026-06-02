defmodule ScrypathOpsWeb.AssetPlug do
  @moduledoc """
  Serves internal static assets (CSS, JS, logo) when `scrypath_ops` is mounted as an engine.
  """
  @behaviour Plug

  import Plug.Conn

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, opts) do
    path_segments = path_segments(conn.path_info, opts)

    if Enum.any?(path_segments, &(&1 in ["..", ".", ""])) do
      send_resp(conn, 404, "Not found")
    else
      priv_dir = Application.app_dir(:scrypath_ops, "priv/static") |> Path.expand()
      full_path = Path.join([priv_dir | path_segments]) |> Path.expand()

      # Prevent directory traversal
      if String.starts_with?(full_path, priv_dir) do
        case File.read(full_path) do
          {:ok, content} ->
            content_type = MIME.from_path(full_path)

            conn
            |> put_resp_content_type(content_type)
            |> put_resp_header("cache-control", "public, max-age=31536000")
            |> send_resp(200, content)

          {:error, _} ->
            send_resp(conn, 404, "Not found")
        end
      else
        send_resp(conn, 404, "Not found")
      end
    end
  end

  defp path_segments(path_info, opts) do
    case Keyword.get(opts, :path_prefix) do
      prefix when is_binary(prefix) and prefix != "" -> [prefix | path_info]
      _ -> path_info
    end
  end
end
