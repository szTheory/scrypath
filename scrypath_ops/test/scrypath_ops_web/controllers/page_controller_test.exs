defmodule ScrypathOpsWeb.PageControllerTest do
  use ScrypathOpsWeb.ConnCase

  test "GET / redirects to /ops without accepting a destination param", %{conn: conn} do
    conn = get(conn, "/?to=https%3A%2F%2Fevil.example")

    assert conn.status == 302
    assert get_resp_header(conn, "location") == ["/ops"]
  end
end
