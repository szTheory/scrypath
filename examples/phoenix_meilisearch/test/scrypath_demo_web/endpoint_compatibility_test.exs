defmodule ScrypathDemoWeb.EndpointCompatibilityTest do
  use ScrypathDemoWeb.ConnCase, async: false

  test "unmatched JSON paths return the existing error shape", %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> get("/api/phase-145-compatibility")

    assert %{"errors" => %{"detail" => "Not Found"}} = json_response(conn, 404)
  end

  test "malformed signed-session cookies do not crash unmatched JSON paths", %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_cookie("_scrypath_demo_key", "malformed-session-cookie")
      |> get("/api/phase-145-compatibility")

    assert %{"errors" => %{"detail" => "Not Found"}} = json_response(conn, 404)
  end

  test "a supervised loopback Bandit listener serves the endpoint and emits request telemetry" do
    handler_id = {__MODULE__, System.unique_integer([:positive])}

    assert :ok =
             :telemetry.attach(
               handler_id,
               [:bandit, :request, :stop],
               &handle_bandit_stop/4,
               self()
             )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    listener =
      start_supervised!(
        {Bandit,
         plug: ScrypathDemoWeb.Endpoint,
         ip: {127, 0, 0, 1},
         port: 0,
         http_2_options: [enabled: false],
         startup_log: false}
      )

    assert {:ok, {{127, 0, 0, 1}, port}} = ThousandIsland.listener_info(listener)

    assert {:ok, %Req.Response{status: 404, body: %{"errors" => %{"detail" => "Not Found"}}}} =
             Req.get("http://127.0.0.1:#{port}/api/phase-145-compatibility")

    assert_receive {:bandit_request_stop, %{duration: duration},
                    %{conn: %Plug.Conn{status: 404}, plug: {ScrypathDemoWeb.Endpoint, []}}},
                   1_000

    assert duration >= 0
  end

  defp handle_bandit_stop(_event, measurements, metadata, test_pid) do
    send(test_pid, {:bandit_request_stop, measurements, metadata})
  end
end
