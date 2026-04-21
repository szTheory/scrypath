defmodule ScrypathOpsWeb.PageController do
  use ScrypathOpsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
