defmodule ScrypathOpsWeb.PageController do
  use ScrypathOpsWeb, :controller

  def home(conn, _params) do
    conn
    |> assign(:mount_path, "/ops")
    |> render(:home)
  end
end
