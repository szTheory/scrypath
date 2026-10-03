defmodule ScrypathOpsWeb.AssetPlugTest do
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScrypathOpsWeb.AssetPlug

  defp digest(path) do
    path
    |> File.read!()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp asset_conn(query) do
    Plug.Test.conn(:get, "/css/app.css#{query}")
    |> Map.put(:path_info, ["css", "app.css"])
  end

  test "mounted layout uses content-sensitive asset URLs", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/ops/playbooks")

    assert html =~ ~r|href="/ops/assets/css/app\.css\?v=[a-f0-9]{64}"|
    assert html =~ ~r|src="/ops/assets/js/app\.js\?v=[a-f0-9]{64}"|
  end

  test "unversioned and mismatched assets revalidate against the current content" do
    path = Application.app_dir(:scrypath_ops, "priv/static/assets/css/app.css")
    current_digest = digest(path)

    unversioned = AssetPlug.call(asset_conn(""), AssetPlug.init(path_prefix: "assets"))
    assert unversioned.status == 200

    assert Plug.Conn.get_resp_header(unversioned, "cache-control") == [
             "public, max-age=0, must-revalidate"
           ]

    assert Plug.Conn.get_resp_header(unversioned, "etag") == ["\"#{current_digest}\""]

    mismatched =
      AssetPlug.call(asset_conn("?v=old-content"), AssetPlug.init(path_prefix: "assets"))

    assert Plug.Conn.get_resp_header(mismatched, "cache-control") == [
             "public, max-age=0, must-revalidate"
           ]

    assert mismatched.resp_body == unversioned.resp_body

    versioned =
      AssetPlug.call(asset_conn("?v=#{current_digest}"), AssetPlug.init(path_prefix: "assets"))

    assert Plug.Conn.get_resp_header(versioned, "cache-control") == [
             "public, max-age=31536000, immutable"
           ]

    assert versioned.resp_body == unversioned.resp_body
  end

  test "matching validators return not modified and traversal remains rejected" do
    path = Application.app_dir(:scrypath_ops, "priv/static/assets/css/app.css")
    current_digest = digest(path)

    not_modified =
      asset_conn("?v=#{current_digest}")
      |> Plug.Conn.put_req_header("if-none-match", "\"#{current_digest}\"")
      |> AssetPlug.call(AssetPlug.init(path_prefix: "assets"))

    assert not_modified.status == 304
    assert not_modified.resp_body in [nil, ""]

    traversal =
      Plug.Test.conn(:get, "/secret")
      |> Map.put(:path_info, ["assets", "..", "secret"])
      |> AssetPlug.call([])

    assert traversal.status == 404
  end
end
