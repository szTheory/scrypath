defmodule ScrypathOpsWeb.AssetPlug do
  @moduledoc """
  Serves internal static assets (CSS, JS, logo) when `scrypath_ops` is mounted as an engine.
  """
  @behaviour Plug

  import Plug.Conn

  @cache_long "public, max-age=31536000, immutable"
  @cache_revalidate "public, max-age=0, must-revalidate"

  @impl true
  def init(opts), do: opts

  @doc "Returns the current SHA-256 content version for a mounted static asset."
  def asset_version(relative_path) when is_binary(relative_path) do
    path = static_path(relative_path)
    File.read!(path) |> digest()
  end

  @impl true
  def call(conn, opts) do
    path_segments = path_segments(conn.path_info, opts)

    if Enum.any?(path_segments, &(&1 in ["..", ".", ""])) do
      send_resp(conn, 404, "Not found")
    else
      priv_dir = Application.app_dir(:scrypath_ops, "priv/static") |> Path.expand()
      full_path = Path.join([priv_dir | path_segments]) |> Path.expand()

      # Prevent directory traversal
      relative_path = Path.relative_to(full_path, priv_dir)

      if inside_static_dir?(relative_path) do
        case File.read(full_path) do
          {:ok, content} ->
            send_asset(conn, full_path, content)

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

  defp send_asset(conn, full_path, content) do
    content_type = MIME.from_path(full_path)
    version = digest(content)
    etag = "\"#{version}\""
    immutable? = request_version(conn) == version

    conn =
      conn
      |> put_resp_content_type(content_type)
      |> put_resp_header("etag", etag)
      |> put_resp_header(
        "cache-control",
        if(immutable?, do: @cache_long, else: @cache_revalidate)
      )

    if etag_matches?(get_req_header(conn, "if-none-match"), etag) do
      send_resp(conn, 304, "")
    else
      send_resp(conn, 200, content)
    end
  end

  defp request_version(conn) do
    conn.query_string
    |> URI.decode_query()
    |> Map.get("v")
  rescue
    ArgumentError -> nil
  end

  defp etag_matches?(headers, etag) do
    headers
    |> Enum.flat_map(&String.split(&1, ","))
    |> Enum.map(&String.trim/1)
    |> Enum.any?(&(&1 == "*" or &1 == etag))
  end

  defp digest(content), do: :crypto.hash(:sha256, content) |> Base.encode16(case: :lower)

  defp static_path(relative_path) do
    priv_dir = Application.app_dir(:scrypath_ops, "priv/static") |> Path.expand()
    full_path = Path.join(priv_dir, relative_path) |> Path.expand()
    relative_to_static = Path.relative_to(full_path, priv_dir)

    if inside_static_dir?(relative_to_static) do
      full_path
    else
      raise ArgumentError, "asset path must be inside priv/static"
    end
  end

  defp inside_static_dir?(relative_path) do
    Path.type(relative_path) == :relative and relative_path not in ["", "."] and
      Enum.all?(Path.split(relative_path), &(&1 != ".."))
  end
end
