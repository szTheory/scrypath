defmodule ScrypathOpsWeb.PageController do
  use ScrypathOpsWeb, :controller

  def home(conn, _params), do: redirect(conn, to: "/ops")
end
